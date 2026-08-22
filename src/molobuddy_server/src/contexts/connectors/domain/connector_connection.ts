import type {
  AccountingProviderKey,
  ConnectorCapability,
} from './accounting_provider.js';

export type ConnectorConnectionStatus =
  | 'active'
  | 'attention_required'
  | 'authorising'
  | 'awaiting_source_selection'
  | 'paused'
  | 'revoked';

export type ConnectorConnection = Readonly<{
  connectionId: string;
  practiceId: string;
  providerKey: AccountingProviderKey;
  connectorVersion: string;
  status: ConnectorConnectionStatus;
  requestedCapabilities: readonly ConnectorCapability[];
  grantedCapabilities: readonly ConnectorCapability[];
  grantedScopes: readonly string[];
  connectedByUid: string;
}>;

export type ConnectorDataSource = Readonly<{
  dataSourceId: string;
  connectionId: string;
  providerDataSourceId: string;
  displayName: string;
  providerApiDomain?: string;
  selected: boolean;
}>;

export type ConnectionTransitionResult =
  | Readonly<{ ok: true; connection: ConnectorConnection }>
  | Readonly<{ ok: false; code: 'invalid_connection_transition' }>;

export function beginAuthorisation(
  input: Omit<ConnectorConnection, 'status'>,
): ConnectorConnection {
  return { ...input, status: 'authorising' };
}

export function completeAuthorisation(
  connection: ConnectorConnection,
  grantedScopes: readonly string[],
  grantedCapabilities: readonly ConnectorCapability[],
): ConnectionTransitionResult {
  if (connection.status !== 'authorising') {
    return { ok: false, code: 'invalid_connection_transition' };
  }
  return {
    ok: true,
    connection: {
      ...connection,
      status: 'awaiting_source_selection',
      grantedScopes,
      grantedCapabilities,
    },
  };
}

export function activateSelectedSources(
  connection: ConnectorConnection,
  sources: readonly ConnectorDataSource[],
): ConnectionTransitionResult {
  if (
    connection.status !== 'awaiting_source_selection' ||
    !sources.some((source) => source.selected)
  ) {
    return { ok: false, code: 'invalid_connection_transition' };
  }
  return { ok: true, connection: { ...connection, status: 'active' } };
}

export function pauseConnection(
  connection: ConnectorConnection,
): ConnectionTransitionResult {
  if (connection.status !== 'active') {
    return { ok: false, code: 'invalid_connection_transition' };
  }
  return { ok: true, connection: { ...connection, status: 'paused' } };
}

export function requireAttention(
  connection: ConnectorConnection,
): ConnectionTransitionResult {
  if (connection.status === 'revoked') {
    return { ok: false, code: 'invalid_connection_transition' };
  }
  return {
    ok: true,
    connection: { ...connection, status: 'attention_required' },
  };
}

export function revokeConnection(
  connection: ConnectorConnection,
): ConnectionTransitionResult {
  if (connection.status === 'revoked') {
    return { ok: false, code: 'invalid_connection_transition' };
  }
  return { ok: true, connection: { ...connection, status: 'revoked' } };
}
