export { StaticAccountingProviderRegistry } from './adapters/outbound/providers/accounting_provider_registry.js';
export { ListConnectorDefinitions } from './application/queries/list_connector_definitions.js';
export {
  documentedAccountingProviderAdapters,
  quickBooksOnlineDefinition,
  sageBusinessCloudAccountingDefinition,
  xeroDefinition,
  zohoBooksDefinition,
} from './adapters/outbound/providers/provider_definitions.js';

export type { AccountingProviderAdapter } from './application/ports/accounting_provider_adapter.js';
export type { AccountingProviderRegistry } from './application/ports/accounting_provider_registry.js';
export type { ConnectorDefinitionView } from './application/queries/list_connector_definitions.js';
export type {
  ExternalRecordNormaliser,
  ProviderRecordForNormalisation,
} from './application/ports/external_record_normaliser.js';
export type {
  ProviderCredentialReference,
  ProviderCredentials,
  ProviderCredentialVault,
  ProviderCredentialWrite,
} from './application/ports/provider_credential_vault.js';
export type {
  ProviderTransport,
  ProviderTransportRequest,
  ProviderTransportResponse,
} from './application/ports/provider_transport.js';
export type {
  ProviderWebhookRequest,
  ProviderWebhookVerification,
  ProviderWebhookVerifier,
} from './application/ports/provider_webhook_verifier.js';
export type {
  AccountingDataSourceKind,
  AccountingProviderDefinition,
  AccountingProviderKey,
  AccountingRecordKind,
  ConnectorCapability,
  ProviderApiRequest,
  ProviderTokenExchange,
  StartProviderAuthorisation,
} from './domain/accounting_provider.js';
export {
  externalRecordIdentity,
  type NormalisedExternalRecord,
} from './domain/external_record.js';
