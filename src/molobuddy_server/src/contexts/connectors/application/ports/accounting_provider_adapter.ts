import type {
  AccountingProviderDefinition,
  AccountingRecordKind,
  ProviderApiRequest,
  ProviderTokenExchange,
  StartProviderAuthorisation,
} from '../../domain/accounting_provider.js';

/**
 * A documented provider contract. Implementations only create request plans;
 * the future transport adapter performs network I/O and credential injection.
 */
export interface AccountingProviderAdapter {
  readonly definition: AccountingProviderDefinition;

  buildAuthorisationUrl(input: StartProviderAuthorisation): URL;

  tokenExchange(
    grantType: ProviderTokenExchange['grantType'],
    redirectUri?: string,
  ): ProviderTokenExchange;

  buildReadRequest(
    recordKind: AccountingRecordKind,
    dataSourceId: string,
  ): ProviderApiRequest;
}
