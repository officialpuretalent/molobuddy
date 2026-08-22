import type { AccountingProviderRegistry } from '../ports/accounting_provider_registry.js';

export type ConnectorDefinitionView = Readonly<{
  key: string;
  version: string;
  name: string;
  auth: 'oauth2';
  capabilities: readonly string[];
  scopes: readonly Readonly<{
    key: string;
    description: string;
    required: boolean;
  }>[];
  supportsDeltaSync: true;
  supportsWebhooks: boolean;
  status: 'private';
}>;

/**
 * The public catalogue is deliberately configuration-only. It publishes no
 * endpoint URLs, credentials, webhooks, data-source details or tenant state.
 */
export class ListConnectorDefinitions {
  public constructor(private readonly registry: AccountingProviderRegistry) {}

  public execute(): readonly ConnectorDefinitionView[] {
    return this.registry.list().map((adapter) => {
      const scopes = adapter.definition.scopeBundles.flatMap((bundle) =>
        bundle.scopes.map((scope) => ({
          key: scope,
          description: `Required for ${bundle.capability}.`,
          required: true,
        })),
      );

      return {
        key: adapter.definition.key,
        version: '0.1.0',
        name: adapter.definition.displayName,
        auth: 'oauth2',
        capabilities: adapter.definition.supportedCapabilities,
        scopes: uniqueScopes(scopes),
        supportsDeltaSync: true,
        supportsWebhooks: adapter.definition.supportsWebhooks,
        status: 'private',
      };
    });
  }
}

function uniqueScopes(
  scopes: readonly Readonly<{
    key: string;
    description: string;
    required: boolean;
  }>[],
): readonly Readonly<{
  key: string;
  description: string;
  required: boolean;
}>[] {
  const byKey = new Map<string, (typeof scopes)[number]>();
  for (const scope of scopes) {
    byKey.set(scope.key, scope);
  }
  return [...byKey.values()];
}
