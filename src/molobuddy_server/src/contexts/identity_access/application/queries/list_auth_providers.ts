export type AuthProvider = Readonly<{
  providerId: string;
  kind: 'email_password' | 'federated';
  displayNameKey: string;
  availability: 'available' | 'coming_soon' | 'unavailable';
  enabledPlatforms: readonly ('android' | 'ios' | 'web')[];
  supportsLinking: boolean;
  sortOrder: number;
}>;

const enabledPlatforms = ['android', 'ios', 'web'] as const;

const providerCatalogue: readonly AuthProvider[] = [
  {
    providerId: 'password',
    kind: 'email_password',
    displayNameKey: 'auth.provider.emailPassword',
    availability: 'available',
    enabledPlatforms,
    supportsLinking: true,
    sortOrder: 10,
  },
  {
    providerId: 'google.com',
    kind: 'federated',
    displayNameKey: 'auth.provider.google',
    availability: 'coming_soon',
    enabledPlatforms,
    supportsLinking: true,
    sortOrder: 20,
  },
];

export class ListAuthProviders {
  execute(): Readonly<{ providers: readonly AuthProvider[] }> {
    return { providers: providerCatalogue };
  }
}
