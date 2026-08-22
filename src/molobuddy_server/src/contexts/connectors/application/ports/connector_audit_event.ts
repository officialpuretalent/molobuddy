/**
 * A connector-wide, allowlisted audit envelope. Connector-specific evidence
 * may use a new namespaced action, but cannot add arbitrary metadata that
 * might carry credentials, provider bodies or webhook bytes.
 */
export type ConnectorAuditEvent = Readonly<{
  practiceId: string;
  connectorKey: string;
  action: ConnectorAuditAction;
  actor:
    | Readonly<{ kind: 'user'; uid: string }>
    | Readonly<{ kind: 'system'; name: string }>
    | Readonly<{ kind: 'provider' }>;
  correlationId: string;
  target: Readonly<{
    kind: 'connection' | 'credential' | 'data_source' | 'sync_run' | 'webhook';
    id: string;
  }>;
  outcome: 'accepted' | 'completed' | 'failed' | 'rejected' | 'revoked';
  safeFacts?: Readonly<{
    statusCode?: string;
    affectedRecordCount?: number;
    credentialGeneration?: number;
  }>;
}>;

/** Connector-owned action names, for example `accounting.sync_completed`. */
export type ConnectorAuditAction = `${string}.${string}`;

/**
 * Validates the public, connector-agnostic envelope and returns only fields
 * that may enter the audit store. This is deliberately a projection rather
 * than a spread: untyped inbound values cannot smuggle extra fields through.
 */
export function safeConnectorAuditFields(
  event: ConnectorAuditEvent,
): Record<string, unknown> {
  assertIdentifier(event.practiceId, 'practice ID');
  assertIdentifier(event.connectorKey, 'connector key');
  const actionParts = event.action.split('.');
  if (actionParts.length !== 2) {
    throw new Error('Invalid connector audit action');
  }
  const [namespace, action] = actionParts;
  assertIdentifier(namespace, 'action namespace');
  assertIdentifier(action, 'action name');
  assertIdentifier(event.target.id, 'audit target ID');
  assertIdentifier(event.correlationId, 'correlation ID');

  if (event.actor.kind === 'system') {
    assertIdentifier(event.actor.name, 'system actor');
  }
  if (event.safeFacts?.statusCode !== undefined) {
    assertIdentifier(event.safeFacts.statusCode, 'status code');
  }
  for (const value of [
    event.safeFacts?.affectedRecordCount,
    event.safeFacts?.credentialGeneration,
  ]) {
    if (value !== undefined && (!Number.isSafeInteger(value) || value < 0)) {
      throw new Error('Connector audit counts must be non-negative integers');
    }
  }

  return {
    practiceId: event.practiceId,
    connectorKey: event.connectorKey,
    action: event.action,
    actor: event.actor,
    correlationId: event.correlationId,
    target: event.target,
    outcome: event.outcome,
    ...(event.safeFacts === undefined
      ? {}
      : { safeFacts: safeFacts(event.safeFacts) }),
  };
}

function safeFacts(
  facts: NonNullable<ConnectorAuditEvent['safeFacts']>,
): Record<string, unknown> {
  return {
    ...(facts.statusCode === undefined ? {} : { statusCode: facts.statusCode }),
    ...(facts.affectedRecordCount === undefined
      ? {}
      : { affectedRecordCount: facts.affectedRecordCount }),
    ...(facts.credentialGeneration === undefined
      ? {}
      : { credentialGeneration: facts.credentialGeneration }),
  };
}

function assertIdentifier(value: string | undefined, name: string): void {
  if (value === undefined || !/^[a-z][a-z0-9_-]{0,127}$/.test(value)) {
    throw new Error(`Invalid connector audit ${name}`);
  }
}
