import type { ServerConfig } from '../../src/bootstrap/config.js';

export function testConfig(
  overrides: Partial<ServerConfig> = {},
): ServerConfig {
  return {
    environment: 'test',
    host: '127.0.0.1',
    port: 8080,
    regionKey: 'za1',
    releaseId: 'test-release',
    logLevel: 'error',
    corsAllowedOrigins: ['http://localhost:3000'],
    auth: {
      mode: 'local',
      environment: 'test',
      idToken: 'known-id-token',
      appCheckToken: 'known-app-check-token',
      actor: {
        uid: 'user_123',
        displayName: 'Molo Tester',
        email: 'tester@example.com',
        emailVerified: true,
      },
    },
    ...overrides,
  };
}
