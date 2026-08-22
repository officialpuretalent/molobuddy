export { StaticAccountingProviderRegistry } from './adapters/outbound/providers/accounting_provider_registry.js';
export {
  documentedAccountingProviderAdapters,
  quickBooksOnlineDefinition,
  sageBusinessCloudAccountingDefinition,
  xeroDefinition,
  zohoBooksDefinition,
} from './adapters/outbound/providers/provider_definitions.js';

export type { AccountingProviderAdapter } from './application/ports/accounting_provider_adapter.js';
export type { AccountingProviderRegistry } from './application/ports/accounting_provider_registry.js';
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
