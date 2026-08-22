/**
 * Provider-neutral accounting connector vocabulary.
 *
 * These types deliberately describe an integration boundary rather than a
 * lowest-common-denominator accounting model. Provider DTOs remain private to
 * their adapter and are mapped into external records only after retrieval.
 */
export const accountingProviderKeys = [
  'quickbooks_online',
  'sage_business_cloud_accounting',
  'xero',
  'zoho_books',
] as const;

export type AccountingProviderKey = (typeof accountingProviderKeys)[number];

export const accountingDataSourceKinds = [
  'company',
  'organisation',
  'tenant',
] as const;

export type AccountingDataSourceKind =
  (typeof accountingDataSourceKinds)[number];

export const accountingRecordKinds = [
  'account',
  'bank_transaction',
  'bill',
  'contact',
  'credit_note',
  'invoice',
  'payment',
  'tax_rate',
] as const;

export type AccountingRecordKind = (typeof accountingRecordKinds)[number];

export const connectorCapabilities = [
  'accounts.read',
  'bank_transactions.read',
  'bills.read',
  'contacts.read',
  'credit_notes.read',
  'invoices.read',
  'payments.read',
  'tax_rates.read',
] as const;

export type ConnectorCapability = (typeof connectorCapabilities)[number];

export type OAuthClientAuthentication =
  | 'basic_authorization_header'
  | 'client_id_and_secret_body'
  | 'provider_managed';

export type ProviderEndpointTemplate = Readonly<{
  method: 'GET' | 'POST';
  url: string;
  description: string;
}>;

export type ProviderScopeBundle = Readonly<{
  capability: ConnectorCapability;
  scopes: readonly string[];
}>;

export type AccountingProviderDefinition = Readonly<{
  key: AccountingProviderKey;
  displayName: string;
  dataSourceKind: AccountingDataSourceKind;
  documentationUrl: string;
  oauth: Readonly<{
    authorizationEndpoint: string;
    tokenEndpoint: string;
    revocationEndpoint?: string;
    clientAuthentication: OAuthClientAuthentication;
    scopeDelimiter: 'space' | 'comma' | 'provider_managed';
    usesPkce: boolean;
  }>;
  api: Readonly<{
    baseUrl: string;
    sourceContext: Readonly<{
      name: string;
      location: 'header' | 'path' | 'provider_managed' | 'query';
      description: string;
    }>;
    endpoints: Readonly<Record<AccountingRecordKind, ProviderEndpointTemplate>>;
  }>;
  scopeBundles: readonly ProviderScopeBundle[];
  supportedCapabilities: readonly ConnectorCapability[];
  supportsWebhooks: boolean;
  supportsScheduledReconciliation: true;
}>;

export type StartProviderAuthorisation = Readonly<{
  clientId: string;
  redirectUri: string;
  state: string;
  scopes: readonly string[];
  codeChallenge?: string;
}>;

export type ProviderTokenExchange = Readonly<{
  endpoint: string;
  clientAuthentication: OAuthClientAuthentication;
  grantType: 'authorization_code' | 'refresh_token';
  redirectUri?: string;
}>;

export type ProviderApiRequest = Readonly<{
  method: 'GET' | 'POST';
  url: string;
  requiredHeaders: readonly string[];
  sourceContext: Readonly<{
    name: string;
    value: string;
    location: 'header' | 'path' | 'provider_managed' | 'query';
  }>;
}>;
