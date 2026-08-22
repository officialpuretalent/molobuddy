import { createHash } from 'node:crypto';

import { createOpaqueId } from '../../../../platform/http/identifiers.js';
import type { VerifiedActor } from '../../../identity_access/index.js';
import type { ConnectorLifecycleStore } from '../ports/connector_lifecycle_store.js';
import {
  pauseConnection,
  revokeConnection,
  type ConnectorConnection,
} from '../../domain/connector_connection.js';

export type ChangeAccountingConnectionStatusInput = Readonly<{
  actor: VerifiedActor;
  practiceId: string;
  connectionId: string;
  action: 'pause' | 'resume' | 'revoke';
  expectedVersion: string;
  idempotencyKey: string;
  correlationId: string;
}>;

export type ChangeAccountingConnectionStatusResult =
  | Readonly<{
      ok: true;
      connection: ConnectorConnection;
      version: string;
      replayed: boolean;
    }>
  | Readonly<{
      ok: false;
      code:
        | 'idempotency_conflict'
        | 'invalid_connection_transition'
        | 'invalid_request'
        | 'resource_not_found'
        | 'version_mismatch';
    }>;

export class ChangeAccountingConnectionStatus {
  constructor(private readonly store: ConnectorLifecycleStore) {}

  async execute(
    input: ChangeAccountingConnectionStatusInput,
  ): Promise<ChangeAccountingConnectionStatusResult> {
    if (
      input.idempotencyKey.trim().length === 0 ||
      input.expectedVersion === ''
    ) {
      return { ok: false, code: 'invalid_request' };
    }
    const names = actionNames(input.action);
    const outcome = await this.store.transition({
      practiceId: input.practiceId,
      connectionId: input.connectionId,
      expectedVersion: input.expectedVersion,
      idempotency: {
        actorUid: input.actor.uid,
        command: `connector.${input.action}`,
        key: input.idempotencyKey.trim(),
        payloadHash: hash(input),
      },
      prepare: (current) => {
        if (current === undefined) {
          return { ok: false, code: 'resource_not_found' };
        }
        const connection = transition(current.connection, input.action);
        if (connection === undefined) {
          return { ok: false, code: 'invalid_connection_transition' };
        }
        return {
          ok: true,
          write: {
            connection,
            audit: {
              practiceId: input.practiceId,
              connectorKey: connection.providerKey,
              action: names.auditAction,
              actor: { kind: 'user', uid: input.actor.uid },
              correlationId: input.correlationId,
              target: { kind: 'connection', id: connection.connectionId },
              outcome: input.action === 'revoke' ? 'revoked' : 'completed',
              safeFacts: { statusCode: connection.status },
            },
            outbox: {
              eventId: createOpaqueId('evt'),
              type: names.outboxType,
              connectionId: connection.connectionId,
              connectorKey: connection.providerKey,
              correlationId: input.correlationId,
            },
          },
        };
      },
    });
    if (!outcome.ok) {
      return {
        ok: false,
        code:
          outcome.code === 'state_conflict'
            ? 'invalid_connection_transition'
            : outcome.code,
      };
    }
    return {
      ok: true,
      connection: outcome.value.connection,
      version: outcome.value.version,
      replayed: outcome.replayed,
    };
  }
}

function transition(
  connection: ConnectorConnection,
  action: ChangeAccountingConnectionStatusInput['action'],
): ConnectorConnection | undefined {
  if (action === 'pause') {
    const result = pauseConnection(connection);
    return result.ok ? result.connection : undefined;
  }
  if (action === 'revoke') {
    const result = revokeConnection(connection);
    return result.ok ? result.connection : undefined;
  }
  return connection.status === 'paused'
    ? { ...connection, status: 'active' }
    : undefined;
}

function actionNames(action: ChangeAccountingConnectionStatusInput['action']) {
  if (action === 'pause') {
    return {
      auditAction: 'accounting.connection_paused' as const,
      outboxType: 'connector.connection_paused.v1' as const,
    };
  }
  if (action === 'resume') {
    return {
      auditAction: 'accounting.connection_resumed' as const,
      outboxType: 'connector.connection_resumed.v1' as const,
    };
  }
  return {
    auditAction: 'accounting.connection_revoked' as const,
    outboxType: 'connector.connection_revoked.v1' as const,
  };
}

function hash(input: ChangeAccountingConnectionStatusInput): string {
  return createHash('sha256')
    .update(input.practiceId)
    .update('\n')
    .update(input.connectionId)
    .update('\n')
    .update(input.action)
    .digest('hex');
}
