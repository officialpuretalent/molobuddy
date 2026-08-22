import assert from 'node:assert/strict';
import test from 'node:test';

import {
  safeConnectorAuditFields,
  type ConnectorAuditEvent,
} from '../../src/contexts/connectors/index.js';

test('a future connector can emit the generic audit envelope', () => {
  const event: ConnectorAuditEvent = {
    practiceId: 'prc_123',
    connectorKey: 'document_store',
    action: 'documents.import_completed',
    actor: { kind: 'system', name: 'connector_worker' },
    correlationId: 'cor_123',
    target: { kind: 'connection', id: 'con_123' },
    outcome: 'completed',
    safeFacts: { affectedRecordCount: 4, statusCode: 'active' },
  };

  assert.deepEqual(safeConnectorAuditFields(event), event);
});

test('audit projection drops unexpected runtime fields', () => {
  const event = {
    practiceId: 'prc_123',
    connectorKey: 'xero',
    action: 'accounting.sync_completed',
    actor: { kind: 'provider' },
    correlationId: 'cor_123',
    target: { kind: 'sync_run', id: 'syn_123' },
    outcome: 'completed',
    accessToken: 'must-not-persist',
    rawBody: 'must-not-persist',
  } as unknown as ConnectorAuditEvent;

  const stored = safeConnectorAuditFields(event);
  assert.equal(stored['accessToken'], undefined);
  assert.equal(stored['rawBody'], undefined);
});

test('audit projection rejects free-form status text', () => {
  const event: ConnectorAuditEvent = {
    practiceId: 'prc_123',
    connectorKey: 'xero',
    action: 'accounting.sync_failed',
    actor: { kind: 'provider' },
    correlationId: 'cor_123',
    target: { kind: 'sync_run', id: 'syn_123' },
    outcome: 'failed',
    safeFacts: { statusCode: 'provider said: token=secret' },
  };

  assert.throws(
    () => safeConnectorAuditFields(event),
    /Invalid connector audit/,
  );
});
