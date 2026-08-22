import type { AccountingProviderRegistry } from '../../../application/ports/accounting_provider_registry.js';
import type { AccountingProviderKey } from '../../../domain/accounting_provider.js';
import type { AccountingProviderAdapter } from '../../../application/ports/accounting_provider_adapter.js';

export class StaticAccountingProviderRegistry implements AccountingProviderRegistry {
  private readonly adaptersByKey: ReadonlyMap<
    AccountingProviderKey,
    AccountingProviderAdapter
  >;

  public constructor(
    private readonly adapters: readonly AccountingProviderAdapter[],
  ) {
    this.adaptersByKey = new Map(
      adapters.map((adapter) => [adapter.definition.key, adapter]),
    );
  }

  public get(providerKey: AccountingProviderKey): AccountingProviderAdapter {
    const adapter = this.adaptersByKey.get(providerKey);
    if (adapter === undefined) {
      throw new Error(
        `No accounting provider adapter is registered for ${providerKey}.`,
      );
    }
    return adapter;
  }

  public list(): readonly AccountingProviderAdapter[] {
    return this.adapters;
  }
}
