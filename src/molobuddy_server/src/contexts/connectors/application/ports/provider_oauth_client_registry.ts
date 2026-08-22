import type { AccountingProviderKey } from '../../domain/accounting_provider.js';

/** Deployment-owned OAuth client configuration. It is never API input. */
export type ProviderOAuthClientConfiguration = Readonly<{
  clientId: string;
  redirectUri: string;
}>;

export interface ProviderOAuthClientRegistry {
  get(providerKey: AccountingProviderKey): ProviderOAuthClientConfiguration;
}
