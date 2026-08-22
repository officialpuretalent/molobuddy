import assert from 'node:assert/strict';
import { createHash, randomBytes } from 'node:crypto';
import test from 'node:test';

import {
  HmacOAuthStateSigner,
  IssueProviderAuthorisation,
  type AccountingProviderAdapter,
  type AccountingProviderRegistry,
  type ConnectorLifecycleCommitResult,
  type ConnectorLifecycleStore,
  type ConnectorLifecycleTransition,
  type ConnectorLifecycleTransitionResult,
  type OAuthAuthorisationState,
  type OAuthAuthorisationStateStore,
  type ProviderOAuthClientRegistry,
  type VersionedConnectorConnection,
} from '../../src/contexts/connectors/index.js';
import type { VerifiedActor } from '../../src/contexts/identity_access/index.js';

const actor: VerifiedActor = {
  uid: 'uid_123',
  firebaseProjectId: 'molobuddy-development',
  appId: 'app_123',
  providerIds: ['password'],
  emailVerified: true,
};

class RecordingStates implements OAuthAuthorisationStateStore {
  state: OAuthAuthorisationState | undefined;

  async create(state: OAuthAuthorisationState): Promise<void> {
    this.state = state;
  }

  async consume(): Promise<never> {
    throw new Error('Unexpected OAuth state consumption');
  }
}

class ReadOnlyLifecycleStore implements ConnectorLifecycleStore {
  constructor(private readonly current: VersionedConnectorConnection) {}

  async get(): Promise<VersionedConnectorConnection> {
    return this.current;
  }

  async commit(): Promise<ConnectorLifecycleCommitResult> {
    throw new Error('Unexpected lifecycle commit');
  }

  async transition(
    _transition: ConnectorLifecycleTransition,
  ): Promise<ConnectorLifecycleTransitionResult> {
    throw new Error('Unexpected lifecycle transition');
  }
}

const pkceAdapter: AccountingProviderAdapter = {
  definition: {
    key: 'xero',
    displayName: 'Xero test',
    dataSourceKind: 'tenant',
    documentationUrl: 'https://example.invalid',
    oauth: {
      authorizationEndpoint: 'https://example.invalid/authorise',
      tokenEndpoint: 'https://example.invalid/token',
      clientAuthentication: 'basic_authorization_header',
      scopeDelimiter: 'space',
      usesPkce: true,
    },
    api: {
      baseUrl: 'https://example.invalid/api/',
      sourceContext: {
        name: 'tenant',
        location: 'header',
        description: 'test',
      },
      endpoints:
        {} as AccountingProviderAdapter['definition']['api']['endpoints'],
    },
    scopeBundles: [{ capability: 'contacts.read', scopes: ['contacts.read'] }],
    supportedCapabilities: ['contacts.read'],
    supportsWebhooks: false,
    supportsScheduledReconciliation: true,
  },
  buildAuthorisationUrl(input) {
    const url = new URL('https://example.invalid/authorise');
    url.searchParams.set('client_id', input.clientId);
    url.searchParams.set('redirect_uri', input.redirectUri);
    url.searchParams.set('state', input.state);
    url.searchParams.set('scope', input.scopes.join(' '));
    url.searchParams.set('code_challenge', input.codeChallenge ?? 'missing');
    return url;
  },
  tokenExchange() {
    throw new Error('Unexpected token plan');
  },
  buildReadRequest() {
    throw new Error('Unexpected read plan');
  },
};

test('HMAC OAuth state verification rejects a changed state or signature', () => {
  const signer = new HmacOAuthStateSigner(randomBytes(32));
  const signed = signer.sign('oas_0123456789abcdef0123456789abcdef');

  assert.equal(signer.verify(signed), 'oas_0123456789abcdef0123456789abcdef');
  assert.equal(signer.verify(`${signed}x`), undefined);
  assert.equal(
    signer.verify('v1.oas_0123456789abcdef0123456789abcdef.invalid'),
    undefined,
  );
});

test('issues server-owned signed state and PKCE challenge with only requested scopes', async () => {
  const states = new RecordingStates();
  const signer = new HmacOAuthStateSigner(randomBytes(32));
  const lifecycle = new ReadOnlyLifecycleStore({
    connection: {
      connectionId: 'con_0123456789abcdef0123456789abcdef',
      practiceId: 'prc_123',
      providerKey: 'xero',
      connectorVersion: '0.1.0',
      status: 'authorising',
      requestedCapabilities: ['contacts.read'],
      grantedCapabilities: [],
      grantedScopes: [],
      connectedByUid: actor.uid,
    },
    version: 'version_123',
  });
  const providers: AccountingProviderRegistry = {
    get: () => pkceAdapter,
    list: () => [pkceAdapter],
  };
  const clients: ProviderOAuthClientRegistry = {
    get: () => ({
      clientId: 'deployment-client-id',
      redirectUri: 'https://api.molo.example/v1/oauth/callback/xero',
    }),
  };
  const command = new IssueProviderAuthorisation(
    providers,
    clients,
    states,
    signer,
    lifecycle,
  );

  const result = await command.execute({
    actor,
    practiceId: 'prc_123',
    connectionId: 'con_0123456789abcdef0123456789abcdef',
    now: '2026-08-22T10:00:00.000Z',
  });

  assert.equal(result.ok, true);
  const state = states.state;
  assert.ok(state);
  assert.ok(state.codeVerifier);
  assert.equal(
    signer.verify(
      new URL(result.authorisationUrl).searchParams.get('state') ?? '',
    ),
    state.stateId,
  );
  assert.equal(
    new URL(result.authorisationUrl).searchParams.get('scope'),
    'contacts.read',
  );
  assert.equal(
    new URL(result.authorisationUrl).searchParams.get('code_challenge'),
    createChallenge(state.codeVerifier),
  );
  assert.equal(state.expiresAt, '2026-08-22T10:10:00.000Z');
});

function createChallenge(verifier: string): string {
  return createHash('sha256').update(verifier).digest('base64url');
}
