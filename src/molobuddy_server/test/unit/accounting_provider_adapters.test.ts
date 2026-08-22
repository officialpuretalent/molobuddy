import assert from 'node:assert/strict';
import test from 'node:test';

import {
  documentedAccountingProviderAdapters,
  StaticAccountingProviderRegistry,
} from '../../src/contexts/connectors/index.js';

const registry = new StaticAccountingProviderRegistry(
  documentedAccountingProviderAdapters,
);

test('the documented registry exposes exactly the initial accounting providers', () => {
  assert.deepEqual(
    registry.list().map((adapter) => adapter.definition.key),
    [
      'quickbooks_online',
      'sage_business_cloud_accounting',
      'xero',
      'zoho_books',
    ],
  );
});

test('Xero authorisation plans use granular scopes and server-side OAuth endpoints', () => {
  const url = registry.get('xero').buildAuthorisationUrl({
    clientId: 'client-id',
    redirectUri: 'https://api.molo.example/v1/oauth/xero/callback',
    state: 'opaque-state',
    scopes: ['offline_access', 'accounting.invoices.read'],
  });

  assert.equal(url.origin, 'https://login.xero.com');
  assert.equal(
    url.searchParams.get('scope'),
    'offline_access accounting.invoices.read',
  );
  assert.equal(url.searchParams.get('state'), 'opaque-state');
  assert.deepEqual(registry.get('xero').tokenExchange('refresh_token'), {
    endpoint: 'https://identity.xero.com/connect/token',
    clientAuthentication: 'basic_authorization_header',
    grantType: 'refresh_token',
  });
});

test('Zoho Books keeps the organisation in the query and scopes comma-delimited', () => {
  const adapter = registry.get('zoho_books');
  const url = adapter.buildAuthorisationUrl({
    clientId: 'client-id',
    redirectUri: 'https://api.molo.example/v1/oauth/zoho/callback',
    state: 'opaque-state',
    scopes: ['ZohoBooks.contacts.READ', 'ZohoBooks.invoices.READ'],
  });
  const request = adapter.buildReadRequest('invoice', 'org-123');

  assert.equal(
    url.searchParams.get('scope'),
    'ZohoBooks.contacts.READ,ZohoBooks.invoices.READ',
  );
  assert.equal(
    request.url,
    'https://www.zohoapis.com/books/v3/invoices?organization_id=org-123',
  );
  assert.deepEqual(request.requiredHeaders, ['Authorization']);
});

test('QuickBooks Online places the realm ID in the API path', () => {
  const request = registry
    .get('quickbooks_online')
    .buildReadRequest('invoice', '9130352451234567');

  assert.equal(
    request.url,
    'https://quickbooks.api.intuit.com/v3/company/9130352451234567/query',
  );
  assert.equal(request.sourceContext.name, 'realmId');
  assert.equal(request.sourceContext.location, 'path');
});

test('Sage Business Cloud Accounting does not invent a public scope catalogue', () => {
  const adapter = registry.get('sage_business_cloud_accounting');
  const url = adapter.buildAuthorisationUrl({
    clientId: 'client-id',
    redirectUri: 'https://api.molo.example/v1/oauth/sage/callback',
    state: 'opaque-state',
    scopes: ['not-sent-until-provider-registration'],
  });

  assert.equal(url.searchParams.has('scope'), false);
  assert.equal(adapter.definition.scopeBundles.length, 0);
  assert.equal(adapter.definition.supportsWebhooks, false);
});
