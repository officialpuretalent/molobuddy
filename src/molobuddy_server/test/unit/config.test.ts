import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { loadConfig } from '../../src/bootstrap/config.js';

const localEnvironment = {
  NODE_ENV: 'development',
  AUTH_VERIFIER: 'local',
  LOCAL_AUTH_ID_TOKEN: 'id-token',
  LOCAL_APP_CHECK_TOKEN: 'app-check-token',
  LOCAL_AUTH_UID: 'developer_user',
  LOCAL_AUTH_EMAIL_VERIFIED: 'true',
};

describe('server configuration', () => {
  it('loads an explicit development-only local verifier', () => {
    const config = loadConfig({
      ...localEnvironment,
      CORS_ALLOWED_ORIGINS:
        'http://localhost:3000,http://127.0.0.1:3000,http://localhost:3000',
    });

    assert.equal(config.auth.mode, 'local');
    assert.deepEqual(config.corsAllowedOrigins, [
      'http://localhost:3000',
      'http://127.0.0.1:3000',
    ]);
  });

  it('fails closed when local verification is selected in production', () => {
    assert.throws(
      () => loadConfig({ ...localEnvironment, NODE_ENV: 'production' }),
      /forbidden in production/,
    );
  });

  it('requires the Firebase project in Firebase mode', () => {
    assert.throws(
      () =>
        loadConfig({
          NODE_ENV: 'production',
          AUTH_VERIFIER: 'firebase',
        }),
      /FIREBASE_PROJECT_ID is required/,
    );
  });

  it('rejects unsafe CORS origins and wildcards', () => {
    assert.throws(
      () =>
        loadConfig({
          ...localEnvironment,
          CORS_ALLOWED_ORIGINS: '*',
        }),
      /must not contain a wildcard/,
    );

    assert.throws(
      () =>
        loadConfig({
          ...localEnvironment,
          CORS_ALLOWED_ORIGINS: 'http://localhost:3000/path',
        }),
      /only absolute HTTP\(S\) origins/,
    );
  });
});
