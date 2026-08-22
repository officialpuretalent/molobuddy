import assert from 'node:assert/strict';
import test from 'node:test';

import { buildControlApi } from '../../src/bootstrap/build_control_api.js';
import { testConfig } from '../fixtures/test_config.js';

type ConnectorCatalogueResponse = Readonly<{
  data: Readonly<{ connectors: readonly Record<string, unknown>[] }>;
}>;

test('connector catalogue publishes only safe private provider metadata', async () => {
  const app = await buildControlApi(testConfig());
  try {
    const response = await app.inject({ method: 'GET', url: '/v1/connectors' });

    assert.equal(response.statusCode, 200);
    const body = response.json<ConnectorCatalogueResponse>();
    assert.deepEqual(
      body.data.connectors.map((connector) => connector['key']),
      [
        'quickbooks_online',
        'sage_business_cloud_accounting',
        'xero',
        'zoho_books',
      ],
    );
    for (const connector of body.data.connectors) {
      assert.equal(connector['status'], 'private');
      assert.equal('oauth' in connector, false);
      assert.equal('api' in connector, false);
      assert.equal('credentials' in connector, false);
    }
  } finally {
    await app.close();
  }
});
