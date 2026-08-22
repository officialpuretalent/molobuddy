import assert from 'node:assert/strict';
import test from 'node:test';

import { externalRecordIdentity } from '../../src/contexts/connectors/index.js';

test('external record identity remains scoped to a provider data source', () => {
  const firstSource = externalRecordIdentity({
    providerKey: 'xero',
    dataSourceId: 'tenant-a',
    recordKind: 'invoice',
    providerRecordId: '42',
  });
  const secondSource = externalRecordIdentity({
    providerKey: 'xero',
    dataSourceId: 'tenant-b',
    recordKind: 'invoice',
    providerRecordId: '42',
  });

  assert.equal(firstSource, 'xero:tenant-a:invoice:42');
  assert.notEqual(firstSource, secondSource);
});
