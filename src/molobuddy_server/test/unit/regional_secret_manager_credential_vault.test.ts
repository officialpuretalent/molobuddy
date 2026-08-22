import assert from 'node:assert/strict';
import test from 'node:test';

import {
  ProviderCredentialVaultError,
  RegionalSecretManagerCredentialVault,
  type RegionalSecretManagerClient,
} from '../../src/contexts/connectors/index.js';

const projectId = 'molo-production';
const locationId = 'africa-south1';
const connectionId = 'con_0123456789abcdef0123456789abcdef';
const secretName = `projects/${projectId}/locations/${locationId}/secrets/molo-connector-${connectionId}`;

class RecordingSecretManager implements RegionalSecretManagerClient {
  secret:
    | {
        name: string;
        labels: Record<string, string>;
        etag: string;
      }
    | undefined;
  readonly versions = new Map<number, Uint8Array>();
  readonly accessedNames: string[] = [];
  readonly destroyedNames: string[] = [];
  rejectNextUpdate = false;
  deletedName: string | undefined;

  async getSecret({
    name,
  }: Readonly<{ name: string }>): ReturnType<
    RegionalSecretManagerClient['getSecret']
  > {
    const secret = this.secret;
    if (secret?.name !== name) {
      throw grpcError(5);
    }
    return [secret];
  }

  async createSecret({
    parent,
    secretId,
    secret,
  }: Parameters<RegionalSecretManagerClient['createSecret']>[0]): ReturnType<
    RegionalSecretManagerClient['createSecret']
  > {
    this.secret = {
      name: `${parent}/secrets/${secretId}`,
      labels: secret.labels,
      etag: 'etag_1',
    };
    return [this.secret];
  }

  async addSecretVersion({
    parent,
    payload,
  }: Parameters<
    RegionalSecretManagerClient['addSecretVersion']
  >[0]): ReturnType<RegionalSecretManagerClient['addSecretVersion']> {
    const generation = this.versions.size + 1;
    this.versions.set(generation, payload.data);
    return [{ name: `${parent}/versions/${generation.toString()}` }];
  }

  async accessSecretVersion({
    name,
  }: Readonly<{ name: string }>): ReturnType<
    RegionalSecretManagerClient['accessSecretVersion']
  > {
    this.accessedNames.push(name);
    const generation = Number(name.split('/').at(-1));
    const data = this.versions.get(generation);
    if (data === undefined) {
      throw grpcError(5);
    }
    return [{ payload: { data } }];
  }

  async updateSecret({
    secret,
  }: Parameters<RegionalSecretManagerClient['updateSecret']>[0]): ReturnType<
    RegionalSecretManagerClient['updateSecret']
  > {
    const existing = this.secret;
    if (this.rejectNextUpdate || secret.etag !== existing?.etag) {
      this.rejectNextUpdate = false;
      throw grpcError(10);
    }
    this.secret = { ...secret, etag: 'etag_2' };
    return [this.secret];
  }

  async deleteSecret({
    name,
  }: Readonly<{ name: string }>): ReturnType<
    RegionalSecretManagerClient['deleteSecret']
  > {
    const secret = this.secret;
    if (secret?.name !== name) {
      throw grpcError(5);
    }
    this.deletedName = name;
    this.secret = undefined;
    return [{}];
  }

  async destroySecretVersion({
    name,
  }: Readonly<{ name: string }>): ReturnType<
    RegionalSecretManagerClient['destroySecretVersion']
  > {
    this.destroyedNames.push(name);
    return [{}];
  }
}

function build(client = new RecordingSecretManager()) {
  return {
    client,
    vault: new RegionalSecretManagerCredentialVault(
      { projectId, locationId },
      client,
    ),
  };
}

function grpcError(code: number): Error & Readonly<{ code: number }> {
  return Object.assign(new Error('Secret Manager request failed'), { code });
}

test('writes and reads an explicit regional secret version', async () => {
  const { client, vault } = build();

  const reference = await vault.write({
    providerKey: 'xero',
    connectionId,
    credentials: {
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: '2026-08-22T12:00:00.000Z',
      providerApiDomain: 'https://api.xero.com',
    },
  });
  const credentials = await vault.read(reference);

  assert.deepEqual(reference, {
    secretResourceName: secretName,
    generation: 1,
  });
  assert.deepEqual(credentials, {
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: '2026-08-22T12:00:00.000Z',
    providerApiDomain: 'https://api.xero.com',
  });
  assert.deepEqual(client.accessedNames, [`${secretName}/versions/1`]);
  assert.equal(client.secret?.labels['molo_generation'], '1');
});

test('requires the current generation before replacing credentials', async () => {
  const { client, vault } = build();
  const first = await vault.write({
    providerKey: 'xero',
    connectionId,
    credentials: { refreshToken: 'first-token' },
  });
  const second = await vault.write({
    providerKey: 'xero',
    connectionId,
    expectedGeneration: first.generation,
    credentials: { refreshToken: 'rotated-token' },
  });

  await assert.rejects(
    vault.write({
      providerKey: 'xero',
      connectionId,
      expectedGeneration: first.generation,
      credentials: { refreshToken: 'stale-token' },
    }),
    (error: unknown) =>
      error instanceof ProviderCredentialVaultError &&
      error.code === 'conflict',
  );
  assert.equal(second.generation, 2);
  assert.equal(client.versions.size, 2);
});

test('destroys a credential version whose generation update loses a race', async () => {
  const { client, vault } = build();
  const first = await vault.write({
    providerKey: 'xero',
    connectionId,
    credentials: { refreshToken: 'first-token' },
  });
  client.rejectNextUpdate = true;

  await assert.rejects(
    vault.write({
      providerKey: 'xero',
      connectionId,
      expectedGeneration: first.generation,
      credentials: { refreshToken: 'candidate-token' },
    }),
    (error: unknown) =>
      error instanceof ProviderCredentialVaultError &&
      error.code === 'conflict',
  );
  assert.deepEqual(client.destroyedNames, [`${secretName}/versions/2`]);
});

test('deletes only a configured regional connector secret', async () => {
  const { client, vault } = build();
  const reference = await vault.write({
    providerKey: 'xero',
    connectionId,
    credentials: { refreshToken: 'refresh-token' },
  });

  await vault.delete(reference);
  assert.equal(client.deletedName, secretName);
  await vault.delete(reference);
});

test('rejects malformed credentials and cross-region references', async () => {
  const { vault } = build();
  await assert.rejects(
    vault.write({
      providerKey: 'xero',
      connectionId,
      credentials: {},
    }),
    (error: unknown) =>
      error instanceof ProviderCredentialVaultError &&
      error.code === 'invalid_credential',
  );
  await assert.rejects(
    vault.read({
      secretResourceName:
        'projects/molo-production/locations/europe-west1/secrets/molo-connector-con_0123456789abcdef0123456789abcdef',
      generation: 1,
    }),
    (error: unknown) =>
      error instanceof ProviderCredentialVaultError &&
      error.code === 'invalid_credential',
  );
});
