import type { ProviderApiRequest } from '../../domain/accounting_provider.js';
import type { ProviderCredentialReference } from './provider_credential_vault.js';

/**
 * The only future port permitted to execute a provider API request. A concrete
 * HTTP adapter will be added with timeout, retry and redaction policies.
 */
export interface ProviderTransport {
  execute(input: ProviderTransportRequest): Promise<ProviderTransportResponse>;
}

export type ProviderTransportRequest = Readonly<{
  request: ProviderApiRequest;
  credentialReference: ProviderCredentialReference;
  correlationId: string;
}>;

export type ProviderTransportResponse = Readonly<{
  statusCode: number;
  headers: Readonly<Record<string, string>>;
  body: Uint8Array;
}>;
