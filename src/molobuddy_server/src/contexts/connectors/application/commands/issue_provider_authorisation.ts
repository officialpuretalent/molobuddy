import { createHash, randomBytes } from 'node:crypto';

import { createOpaqueId } from '../../../../platform/http/identifiers.js';
import type { VerifiedActor } from '../../../identity_access/index.js';
import type { AccountingProviderRegistry } from '../ports/accounting_provider_registry.js';
import type { ConnectorLifecycleStore } from '../ports/connector_lifecycle_store.js';
import type { OAuthAuthorisationStateStore } from '../ports/oauth_authorisation_state_store.js';
import type { OAuthStateSigner } from '../ports/oauth_state_signer.js';
import type { ProviderOAuthClientRegistry } from '../ports/provider_oauth_client_registry.js';
import type { ConnectorCapability } from '../../domain/accounting_provider.js';

export type IssueProviderAuthorisationInput = Readonly<{
  actor: VerifiedActor;
  practiceId: string;
  connectionId: string;
  now: string;
}>;

export type IssueProviderAuthorisationResult =
  | Readonly<{
      ok: true;
      authorisationUrl: string;
      expiresAt: string;
    }>
  | Readonly<{
      ok: false;
      code: 'invalid_connection_state' | 'resource_not_found';
    }>;

/** Creates a signed, single-use OAuth request without exposing deployment credentials. */
export class IssueProviderAuthorisation {
  constructor(
    private readonly providers: AccountingProviderRegistry,
    private readonly oauthClients: ProviderOAuthClientRegistry,
    private readonly states: OAuthAuthorisationStateStore,
    private readonly signer: OAuthStateSigner,
    private readonly lifecycle: ConnectorLifecycleStore,
  ) {}

  async execute(
    input: IssueProviderAuthorisationInput,
  ): Promise<IssueProviderAuthorisationResult> {
    const current = await this.lifecycle.get(
      input.practiceId,
      input.connectionId,
    );
    if (current === undefined) {
      return { ok: false, code: 'resource_not_found' };
    }
    const connection = current.connection;
    if (
      connection.status !== 'authorising' ||
      connection.connectedByUid !== input.actor.uid
    ) {
      return { ok: false, code: 'invalid_connection_state' };
    }
    const provider = this.providers.get(connection.providerKey);
    const client = this.oauthClients.get(connection.providerKey);
    const stateId = createOpaqueId('oas');
    const codeVerifier = provider.definition.oauth.usesPkce
      ? randomBytes(48).toString('base64url')
      : undefined;
    const expiresAt = new Date(
      Date.parse(input.now) + 10 * 60 * 1000,
    ).toISOString();
    await this.states.create({
      stateId,
      practiceId: connection.practiceId,
      connectionId: connection.connectionId,
      providerKey: connection.providerKey,
      actorUid: input.actor.uid,
      returnUri: client.redirectUri,
      ...(codeVerifier === undefined ? {} : { codeVerifier }),
      expiresAt,
    });
    const authorisationUrl = provider.buildAuthorisationUrl({
      clientId: client.clientId,
      redirectUri: client.redirectUri,
      state: this.signer.sign(stateId),
      scopes: requestedScopes(
        provider.definition.scopeBundles,
        connection.requestedCapabilities,
      ),
      ...(codeVerifier === undefined
        ? {}
        : {
            codeChallenge: createHash('sha256')
              .update(codeVerifier)
              .digest('base64url'),
          }),
    });
    return {
      ok: true,
      authorisationUrl: authorisationUrl.toString(),
      expiresAt,
    };
  }
}

function requestedScopes(
  bundles: readonly Readonly<{
    capability: ConnectorCapability;
    scopes: readonly string[];
  }>[],
  capabilities: readonly ConnectorCapability[],
): readonly string[] {
  return [
    ...new Set(
      bundles
        .filter((bundle) => capabilities.includes(bundle.capability))
        .flatMap((bundle) => bundle.scopes),
    ),
  ];
}
