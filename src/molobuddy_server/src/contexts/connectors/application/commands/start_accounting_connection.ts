import { createHash } from 'node:crypto';

import { createOpaqueId } from '../../../../platform/http/identifiers.js';
import type { VerifiedActor } from '../../../identity_access/index.js';
import type { AccountingProviderRegistry } from '../ports/accounting_provider_registry.js';
import type {
  ConnectorLifecycleCommitResult,
  ConnectorLifecycleStore,
  VersionedConnectorConnection,
} from '../ports/connector_lifecycle_store.js';
import { beginAuthorisation } from '../../domain/connector_connection.js';
import type {
  AccountingProviderKey,
  ConnectorCapability,
} from '../../domain/accounting_provider.js';

export type StartAccountingConnectionInput = Readonly<{
  actor: VerifiedActor;
  practiceId: string;
  providerKey: AccountingProviderKey;
  requestedCapabilities: readonly ConnectorCapability[];
  idempotencyKey: string;
  correlationId: string;
}>;

export type StartAccountingConnectionResult =
  | Readonly<{
      ok: true;
      connection: VersionedConnectorConnection;
      replayed: boolean;
    }>
  | Readonly<{
      ok: false;
      code:
        | 'idempotency_conflict'
        | 'invalid_request'
        | 'state_conflict'
        | 'unsupported_capability';
    }>;

/**
 * Creates a durable authorising connection. OAuth state and token exchange are
 * intentionally a following saga: no provider traffic occurs in this command.
 */
export class StartAccountingConnection {
  constructor(
    private readonly providers: AccountingProviderRegistry,
    private readonly store: ConnectorLifecycleStore,
  ) {}

  async execute(
    input: StartAccountingConnectionInput,
  ): Promise<StartAccountingConnectionResult> {
    if (
      input.idempotencyKey.trim().length === 0 ||
      input.requestedCapabilities.length === 0 ||
      new Set(input.requestedCapabilities).size !==
        input.requestedCapabilities.length
    ) {
      return { ok: false, code: 'invalid_request' };
    }
    const provider = this.providers.get(input.providerKey).definition;
    if (
      input.requestedCapabilities.some(
        (capability) => !provider.supportedCapabilities.includes(capability),
      )
    ) {
      return { ok: false, code: 'unsupported_capability' };
    }

    const connectionId = createOpaqueId('con');
    const connection = beginAuthorisation({
      connectionId,
      practiceId: input.practiceId,
      providerKey: input.providerKey,
      connectorVersion: '0.1.0',
      requestedCapabilities: input.requestedCapabilities,
      grantedCapabilities: [],
      grantedScopes: [],
      connectedByUid: input.actor.uid,
    });
    const result = await this.store.commit({
      connection,
      idempotency: {
        actorUid: input.actor.uid,
        command: 'connector.start',
        key: input.idempotencyKey.trim(),
        payloadHash: payloadHash(input),
      },
      audit: {
        practiceId: input.practiceId,
        connectorKey: input.providerKey,
        action: 'accounting.authorisation_started',
        actor: { kind: 'user', uid: input.actor.uid },
        correlationId: input.correlationId,
        target: { kind: 'connection', id: connectionId },
        outcome: 'accepted',
        safeFacts: { statusCode: connection.status },
      },
      outbox: {
        eventId: createOpaqueId('evt'),
        type: 'connector.connection_started.v1',
        connectionId,
        connectorKey: input.providerKey,
        correlationId: input.correlationId,
      },
    });
    return mapResult(result);
  }
}

function payloadHash(input: StartAccountingConnectionInput): string {
  return createHash('sha256')
    .update(input.practiceId)
    .update('\n')
    .update(input.providerKey)
    .update('\n')
    .update([...input.requestedCapabilities].sort().join(','))
    .digest('hex');
}

function mapResult(
  result: ConnectorLifecycleCommitResult,
): StartAccountingConnectionResult {
  if (result.ok) {
    return { ok: true, connection: result.value, replayed: result.replayed };
  }
  return {
    ok: false,
    code: result.code === 'version_mismatch' ? 'state_conflict' : result.code,
  };
}
