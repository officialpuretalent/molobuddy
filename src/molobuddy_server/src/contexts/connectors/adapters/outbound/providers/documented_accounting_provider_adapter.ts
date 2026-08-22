import type { AccountingProviderAdapter } from '../../../application/ports/accounting_provider_adapter.js';
import type {
  AccountingProviderDefinition,
  AccountingRecordKind,
  ProviderApiRequest,
  ProviderEndpointTemplate,
  ProviderTokenExchange,
  StartProviderAuthorisation,
} from '../../../domain/accounting_provider.js';

/**
 * A no-I/O adapter derived from public provider documentation. It lets the
 * application depend on explicit OAuth/API contracts today without giving an
 * unreviewed provider client permission to make network calls.
 */
export class DocumentedAccountingProviderAdapter implements AccountingProviderAdapter {
  public constructor(
    public readonly definition: AccountingProviderDefinition,
  ) {}

  public buildAuthorisationUrl(input: StartProviderAuthorisation): URL {
    const url = new URL(this.definition.oauth.authorizationEndpoint);
    url.searchParams.set('response_type', 'code');
    url.searchParams.set('client_id', input.clientId);
    url.searchParams.set('redirect_uri', input.redirectUri);
    url.searchParams.set('state', input.state);

    if (this.definition.oauth.scopeDelimiter !== 'provider_managed') {
      url.searchParams.set(
        'scope',
        input.scopes.join(
          this.definition.oauth.scopeDelimiter === 'space' ? ' ' : ',',
        ),
      );
    }

    if (this.definition.oauth.usesPkce) {
      if (input.codeChallenge === undefined) {
        throw new Error(
          `${this.definition.key} requires a PKCE code challenge.`,
        );
      }
      url.searchParams.set('code_challenge', input.codeChallenge);
      url.searchParams.set('code_challenge_method', 'S256');
    }

    return url;
  }

  public tokenExchange(
    grantType: ProviderTokenExchange['grantType'],
    redirectUri?: string,
  ): ProviderTokenExchange {
    return {
      endpoint: this.definition.oauth.tokenEndpoint,
      clientAuthentication: this.definition.oauth.clientAuthentication,
      grantType,
      ...(redirectUri === undefined ? {} : { redirectUri }),
    };
  }

  public buildReadRequest(
    recordKind: AccountingRecordKind,
    dataSourceId: string,
  ): ProviderApiRequest {
    const endpoint = this.definition.api.endpoints[recordKind];
    const requiredHeaders = [
      'Authorization',
      ...(this.definition.api.sourceContext.location === 'header'
        ? [this.definition.api.sourceContext.name]
        : []),
    ];

    return {
      method: endpoint.method,
      url: this.resolveUrl(endpoint, dataSourceId),
      requiredHeaders,
      sourceContext: {
        name: this.definition.api.sourceContext.name,
        value: dataSourceId,
        location: this.definition.api.sourceContext.location,
      },
    };
  }

  private resolveUrl(
    endpoint: ProviderEndpointTemplate,
    dataSourceId: string,
  ): string {
    const sourceContext = this.definition.api.sourceContext;
    const baseUrl =
      sourceContext.location === 'path'
        ? this.definition.api.baseUrl.replace(
            '{dataSourceId}',
            encodeURIComponent(dataSourceId),
          )
        : this.definition.api.baseUrl;
    const url = new URL(endpoint.url, baseUrl);

    if (sourceContext.location === 'path') {
      return url.toString();
    }
    if (sourceContext.location === 'query') {
      url.searchParams.set(sourceContext.name, dataSourceId);
    }
    return url.toString();
  }
}
