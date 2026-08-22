import type { AccountingProviderKey } from '../../domain/accounting_provider.js';

/**
 * Secret values cross this port only. Firestore records retain the returned
 * opaque reference and credential generation, never a token value.
 */
export interface ProviderCredentialVault {
  write(input: ProviderCredentialWrite): Promise<ProviderCredentialReference>;

  read(reference: ProviderCredentialReference): Promise<ProviderCredentials>;

  delete(reference: ProviderCredentialReference): Promise<void>;
}

export type ProviderCredentialWrite = Readonly<{
  providerKey: AccountingProviderKey;
  connectionId: string;
  expectedGeneration?: number;
  credentials: ProviderCredentials;
}>;

export type ProviderCredentialReference = Readonly<{
  secretResourceName: string;
  generation: number;
}>;

export type ProviderCredentials = Readonly<{
  accessToken?: string;
  refreshToken?: string;
  expiresAt?: string;
  providerApiDomain?: string;
}>;
