import assert from 'node:assert/strict';
import test from 'node:test';

import {
  activateSelectedSources,
  beginAuthorisation,
  completeAuthorisation,
  pauseConnection,
  queueSyncRun,
  startSyncRun,
} from '../../src/contexts/connectors/index.js';

function authorisingConnection() {
  return beginAuthorisation({
    connectionId: 'con_123',
    practiceId: 'prc_123',
    providerKey: 'xero',
    connectorVersion: '0.1.0',
    requestedCapabilities: ['contacts.read'],
    grantedCapabilities: [],
    grantedScopes: [],
    connectedByUid: 'uid_123',
  });
}

test('a connection requires explicit data-source selection before activation', () => {
  const authorised = completeAuthorisation(
    authorisingConnection(),
    ['accounting.contacts.read'],
    ['contacts.read'],
  );
  assert.equal(authorised.ok, true);

  const noSelection = activateSelectedSources(authorised.connection, []);
  assert.deepEqual(noSelection, {
    ok: false,
    code: 'invalid_connection_transition',
  });

  const active = activateSelectedSources(authorised.connection, [
    {
      dataSourceId: 'src_123',
      practiceId: 'prc_123',
      connectionId: 'con_123',
      providerDataSourceId: 'tenant_123',
      displayName: 'Example organisation',
      selected: true,
    },
  ]);
  assert.equal(active.ok, true);
  assert.equal(active.connection.status, 'active');
});

test('only an active connection may be paused', () => {
  assert.deepEqual(pauseConnection(authorisingConnection()), {
    ok: false,
    code: 'invalid_connection_transition',
  });
});

test('a sync run starts exactly once from its queued state', () => {
  const queued = queueSyncRun({
    syncRunId: 'syn_123',
    practiceId: 'prc_123',
    connectionId: 'con_123',
    dataSourceId: 'src_123',
    mode: 'delta',
  });
  const running = startSyncRun(queued);

  assert.equal(running?.status, 'running');
  assert.equal(startSyncRun(running), undefined);
});
