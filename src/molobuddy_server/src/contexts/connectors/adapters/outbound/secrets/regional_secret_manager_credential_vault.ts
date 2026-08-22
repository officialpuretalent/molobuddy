import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

import type {
  ProviderCredentialReference,
  ProviderCredentials,
  ProviderCredentialVault,
  ProviderCredentialWrite,
} from '../../../application/ports/provider_credential_vault.js';

type SecretRecord = Readonly<{
  name?: string | null;
  labels?: Readonly<Record<string, string>> | null;
  etag?: string | null;
}>;

type SecretVersionRecord = Readonly<{ name?: string | null }>;

type AccessResponse = Readonly<{
  payload?: Readonly<{ data?: Uint8Array | null }> | null;
}>;

/** Narrow vendor boundary kept deliberately inside the Secret Manager adapter. */
export interface RegionalSecretManagerClient {
  getSecret(input: Readonly<{ name: string }>): Promise<[SecretRecord]>;
  createSecret(
    input: Readonly<{
      parent: string;
      secretId: string;
      secret: Readonly<{ labels: Record<string, string> }>;
    }>,
  ): Promise<[SecretRecord]>;
  addSecretVersion(
    input: Readonly<{
      parent: string;
      payload: Readonly<{ data: Uint8Array }>;
    }>,
  ): Promise<[SecretVersionRecord]>;
  accessSecretVersion(
    input: Readonly<{ name: string }>,
  ): Promise<[AccessResponse]>;
  updateSecret(
    input: Readonly<{
      secret: Readonly<{
        name: string;
        labels: Record<string, string>;
        etag: string;
      }>;
      updateMask: Readonly<{ paths: readonly string[] }>;
    }>,
  ): Promise<[SecretRecord]>;
  destroySecretVersion(input: Readonly<{ name: string }>): Promise<[unknown]>;
  deleteSecret(input: Readonly<{ name: string }>): Promise<[unknown]>;
}

export type RegionalSecretManagerCredentialVaultConfig = Readonly<{
  projectId: string;
  locationId: string;
}>;

export type ProviderCredentialVaultErrorCode =
  'conflict' | 'invalid_credential' | 'not_found' | 'unavailable';

/** A stable failure that never carries a provider credential or resource name. */
export class ProviderCredentialVaultError extends Error {
  constructor(readonly code: ProviderCredentialVaultErrorCode) {
    super(`Provider credential vault ${code}`);
    this.name = 'ProviderCredentialVaultError';
  }
}

/**
 * Stores each connection's credentials in a regional Secret Manager secret.
 * Firestore is deliberately never involved in this adapter: callers persist
 * only its returned opaque reference and version generation.
 */
export class RegionalSecretManagerCredentialVault implements ProviderCredentialVault {
  private readonly parent: string;
  private readonly client: RegionalSecretManagerClient;

  constructor(
    config: RegionalSecretManagerCredentialVaultConfig,
    client?: RegionalSecretManagerClient,
  ) {
    assertSafeLabel(config.projectId, 'projectId');
    assertSafeLabel(config.locationId, 'locationId');
    this.parent = `projects/${config.projectId}/locations/${config.locationId}`;
    this.client = client ?? createClient(config);
  }

  async write(
    input: ProviderCredentialWrite,
  ): Promise<ProviderCredentialReference> {
    assertCredentials(input.credentials);
    const secretResourceName = this.secretResourceName(input.connectionId);
    let secret = await this.findSecret(secretResourceName);

    if (secret === undefined) {
      if (input.expectedGeneration !== undefined) {
        throw new ProviderCredentialVaultError('conflict');
      }
      secret = await this.createSecret(input, secretResourceName);
    } else {
      const generation = currentGeneration(secret);
      if (
        input.expectedGeneration === undefined ||
        input.expectedGeneration !== generation
      ) {
        throw new ProviderCredentialVaultError('conflict');
      }
    }

    const etag = secret.etag;
    if (etag === undefined || etag === null || etag === '') {
      throw new ProviderCredentialVaultError('unavailable');
    }
    const [version] = await this.call(() =>
      this.client.addSecretVersion({
        parent: secretResourceName,
        payload: { data: Buffer.from(serialiseCredentials(input.credentials)) },
      }),
    );
    const versionResourceName = version.name;
    const generation = generationFromVersionName(
      versionResourceName,
      secretResourceName,
    );
    const labels = {
      ...secret.labels,
      molo_generation: String(generation),
    };
    try {
      await this.call(() =>
        this.client.updateSecret({
          secret: { name: secretResourceName, labels, etag },
          updateMask: { paths: ['labels'] },
        }),
      );
    } catch (error) {
      await this.destroyUnreferencedVersion(versionResourceName);
      throw error;
    }
    return { secretResourceName, generation };
  }

  async read(
    reference: ProviderCredentialReference,
  ): Promise<ProviderCredentials> {
    this.assertReference(reference);
    const [response] = await this.call(() =>
      this.client.accessSecretVersion({
        name: `${reference.secretResourceName}/versions/${reference.generation.toString()}`,
      }),
    );
    const data = response.payload?.data;
    if (data === undefined || data === null) {
      throw new ProviderCredentialVaultError('unavailable');
    }
    return deserialiseCredentials(Buffer.from(data).toString('utf8'));
  }

  async delete(reference: ProviderCredentialReference): Promise<void> {
    this.assertReference(reference);
    try {
      await this.client.deleteSecret({ name: reference.secretResourceName });
    } catch (error) {
      if (codeOf(error) !== 5) {
        throw mapError(error);
      }
    }
  }

  private async findSecret(name: string): Promise<SecretRecord | undefined> {
    try {
      const [secret] = await this.client.getSecret({ name });
      return secret;
    } catch (error) {
      if (codeOf(error) === 5) {
        return undefined;
      }
      throw mapError(error);
    }
  }

  private async createSecret(
    input: ProviderCredentialWrite,
    secretResourceName: string,
  ): Promise<SecretRecord> {
    try {
      const [secret] = await this.client.createSecret({
        parent: this.parent,
        secretId: secretId(input.connectionId),
        secret: {
          labels: {
            molo_connector: 'true',
            molo_generation: '0',
            provider: input.providerKey,
          },
        },
      });
      if (secret.name !== secretResourceName) {
        throw new ProviderCredentialVaultError('unavailable');
      }
      return secret;
    } catch (error) {
      if (codeOf(error) !== 6) {
        throw mapError(error);
      }
      const existing = await this.findSecret(secretResourceName);
      if (existing === undefined) {
        throw new ProviderCredentialVaultError('unavailable');
      }
      throw new ProviderCredentialVaultError('conflict');
    }
  }

  private assertReference(reference: ProviderCredentialReference): void {
    const name = secretName(reference.secretResourceName);
    if (
      reference.secretResourceName !== `${this.parent}/secrets/${name}` ||
      !/^molo-connector-con_[a-f0-9]{32}$/.test(name) ||
      !Number.isSafeInteger(reference.generation) ||
      reference.generation < 1
    ) {
      throw new ProviderCredentialVaultError('invalid_credential');
    }
  }

  private secretResourceName(connectionId: string): string {
    return `${this.parent}/secrets/${secretId(connectionId)}`;
  }

  private async call<T>(operation: () => Promise<T>): Promise<T> {
    try {
      return await operation();
    } catch (error) {
      throw mapError(error);
    }
  }

  private async destroyUnreferencedVersion(name: string | null | undefined) {
    if (name === undefined || name === null) {
      return;
    }
    try {
      await this.client.destroySecretVersion({ name });
    } catch {
      // The original write failure is more useful to the caller; cleanup is
      // best-effort and the version is never returned as a usable reference.
    }
  }
}

function createClient(
  config: RegionalSecretManagerCredentialVaultConfig,
): RegionalSecretManagerClient {
  return new SecretManagerServiceClient({
    apiEndpoint: `secretmanager.${config.locationId}.rep.googleapis.com`,
  }) as unknown as RegionalSecretManagerClient;
}

function secretId(connectionId: string): string {
  if (!/^con_[a-f0-9]{32}$/.test(connectionId)) {
    throw new ProviderCredentialVaultError('invalid_credential');
  }
  return `molo-connector-${connectionId}`;
}

function secretName(resourceName: string): string {
  const match =
    /^projects\/[^/]+\/locations\/[^/]+\/secrets\/([A-Za-z0-9_-]{1,255})$/.exec(
      resourceName,
    );
  if (match?.[1] === undefined) {
    throw new ProviderCredentialVaultError('invalid_credential');
  }
  return match[1];
}

function currentGeneration(secret: SecretRecord): number {
  const value = secret.labels?.['molo_generation'];
  if (value === undefined || !/^\d+$/.test(value)) {
    throw new ProviderCredentialVaultError('unavailable');
  }
  const generation = Number(value);
  if (!Number.isSafeInteger(generation) || generation < 0) {
    throw new ProviderCredentialVaultError('unavailable');
  }
  return generation;
}

function generationFromVersionName(
  versionName: string | null | undefined,
  secretResourceName: string,
): number {
  const prefix = `${secretResourceName}/versions/`;
  if (versionName?.startsWith(prefix) !== true) {
    throw new ProviderCredentialVaultError('unavailable');
  }
  const value = versionName.slice(prefix.length);
  if (!/^\d+$/.test(value)) {
    throw new ProviderCredentialVaultError('unavailable');
  }
  const generation = Number(value);
  if (!Number.isSafeInteger(generation) || generation < 1) {
    throw new ProviderCredentialVaultError('unavailable');
  }
  return generation;
}

function serialiseCredentials(credentials: ProviderCredentials): string {
  return JSON.stringify(credentials);
}

function deserialiseCredentials(value: string): ProviderCredentials {
  let parsed: unknown;
  try {
    parsed = JSON.parse(value);
  } catch {
    throw new ProviderCredentialVaultError('unavailable');
  }
  if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new ProviderCredentialVaultError('unavailable');
  }
  const record = parsed as Record<string, unknown>;
  const allowed = new Set([
    'accessToken',
    'refreshToken',
    'expiresAt',
    'providerApiDomain',
  ]);
  if (Object.keys(record).some((key) => !allowed.has(key))) {
    throw new ProviderCredentialVaultError('unavailable');
  }
  const credentials: ProviderCredentials = {
    ...stringValue(record['accessToken'], 'accessToken'),
    ...stringValue(record['refreshToken'], 'refreshToken'),
    ...stringValue(record['expiresAt'], 'expiresAt'),
    ...stringValue(record['providerApiDomain'], 'providerApiDomain'),
  };
  try {
    assertCredentials(credentials);
  } catch {
    throw new ProviderCredentialVaultError('unavailable');
  }
  return credentials;
}

function stringValue(
  value: unknown,
  name: keyof ProviderCredentials,
): Partial<ProviderCredentials> {
  if (value === undefined) {
    return {};
  }
  if (typeof value !== 'string') {
    throw new ProviderCredentialVaultError('unavailable');
  }
  return { [name]: value };
}

function assertCredentials(credentials: ProviderCredentials): void {
  if (
    (credentials.accessToken === undefined &&
      credentials.refreshToken === undefined) ||
    [
      credentials.accessToken,
      credentials.refreshToken,
      credentials.expiresAt,
      credentials.providerApiDomain,
    ].some((value) => value?.trim().length === 0)
  ) {
    throw new ProviderCredentialVaultError('invalid_credential');
  }
  if (
    credentials.expiresAt !== undefined &&
    !Number.isFinite(Date.parse(credentials.expiresAt))
  ) {
    throw new ProviderCredentialVaultError('invalid_credential');
  }
  if (credentials.providerApiDomain !== undefined) {
    let url: URL;
    try {
      url = new URL(credentials.providerApiDomain);
    } catch {
      throw new ProviderCredentialVaultError('invalid_credential');
    }
    if (
      url.protocol !== 'https:' ||
      url.username !== '' ||
      url.password !== '' ||
      url.pathname !== '/' ||
      url.search !== '' ||
      url.hash !== ''
    ) {
      throw new ProviderCredentialVaultError('invalid_credential');
    }
  }
}

function assertSafeLabel(value: string, name: string): void {
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/.test(value)) {
    throw new Error(`${name} must be a safe Google Cloud label.`);
  }
}

function codeOf(error: unknown): number | undefined {
  const candidate =
    typeof error === 'object' ? (error as { code?: unknown } | null) : null;
  return typeof candidate?.code === 'number' ? candidate.code : undefined;
}

function mapError(error: unknown): ProviderCredentialVaultError {
  const code = codeOf(error);
  if (code === 5) {
    return new ProviderCredentialVaultError('not_found');
  }
  if (code === 6 || code === 9 || code === 10) {
    return new ProviderCredentialVaultError('conflict');
  }
  return new ProviderCredentialVaultError('unavailable');
}
