import type { AccountingProviderKey } from '../../domain/accounting_provider.js';
import type { AccountingProviderAdapter } from './accounting_provider_adapter.js';

export interface AccountingProviderRegistry {
  get(providerKey: AccountingProviderKey): AccountingProviderAdapter;

  list(): readonly AccountingProviderAdapter[];
}
