export type RuntimeEnvironment = 'development' | 'test' | 'production';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export type FirebaseAuthVerifierConfig = Readonly<{
  mode: 'firebase';
  projectId: string;
}>;

export type LocalAuthVerifierConfig = Readonly<{
  mode: 'local';
  environment: RuntimeEnvironment;
  idToken: string;
  appCheckToken: string;
  actor: Readonly<{
    uid: string;
    displayName?: string;
    email?: string;
    emailVerified: boolean;
  }>;
}>;

export type AuthVerifierConfig =
  FirebaseAuthVerifierConfig | LocalAuthVerifierConfig;

export type ServerConfig = Readonly<{
  environment: RuntimeEnvironment;
  host: string;
  port: number;
  regionKey: string;
  releaseId: string;
  logLevel: LogLevel;
  corsAllowedOrigins: readonly string[];
  auth: AuthVerifierConfig;
}>;

const environments = new Set<RuntimeEnvironment>([
  'development',
  'test',
  'production',
]);
const logLevels = new Set<LogLevel>(['debug', 'info', 'warn', 'error']);

export function loadConfig(environment: NodeJS.ProcessEnv): ServerConfig {
  const runtimeEnvironment = parseEnvironment(environment['NODE_ENV']);
  const authMode = requireValue(environment, 'AUTH_VERIFIER');

  return {
    environment: runtimeEnvironment,
    host: valueOrDefault(environment['HOST'], '0.0.0.0'),
    port: parsePort(environment['PORT']),
    regionKey: parseSafeLabel(environment['REGION_KEY'] ?? 'za1', 'REGION_KEY'),
    releaseId: parseSafeLabel(
      environment['RELEASE_ID'] ?? 'development',
      'RELEASE_ID',
    ),
    logLevel: parseLogLevel(environment['LOG_LEVEL']),
    corsAllowedOrigins: parseAllowedOrigins(
      environment['CORS_ALLOWED_ORIGINS'],
    ),
    auth:
      authMode === 'firebase'
        ? {
            mode: 'firebase',
            projectId: requireValue(environment, 'FIREBASE_PROJECT_ID'),
          }
        : parseLocalAuthConfig(runtimeEnvironment, authMode, environment),
  };
}

function parseEnvironment(value: string | undefined): RuntimeEnvironment {
  const candidate = valueOrDefault(value, 'development');
  if (!environments.has(candidate as RuntimeEnvironment)) {
    throw new Error('NODE_ENV must be development, test or production.');
  }
  return candidate as RuntimeEnvironment;
}

function parseLogLevel(value: string | undefined): LogLevel {
  const candidate = valueOrDefault(value, 'info');
  if (!logLevels.has(candidate as LogLevel)) {
    throw new Error('LOG_LEVEL must be debug, info, warn or error.');
  }
  return candidate as LogLevel;
}

function parsePort(value: string | undefined): number {
  const candidate = valueOrDefault(value, '8080');
  if (!/^\d+$/.test(candidate)) {
    throw new Error('PORT must be an integer between 1 and 65535.');
  }

  const port = Number(candidate);
  if (!Number.isSafeInteger(port) || port < 1 || port > 65_535) {
    throw new Error('PORT must be an integer between 1 and 65535.');
  }
  return port;
}

function parseSafeLabel(value: string, name: string): string {
  const candidate = value.trim();
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/.test(candidate)) {
    throw new Error(`${name} must be a safe opaque label.`);
  }
  return candidate;
}

function parseAllowedOrigins(value: string | undefined): readonly string[] {
  if (value === undefined || value.trim() === '') {
    return [];
  }

  const origins = value
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);

  for (const origin of origins) {
    if (origin === '*') {
      throw new Error('CORS_ALLOWED_ORIGINS must not contain a wildcard.');
    }

    let parsed: URL;
    try {
      parsed = new URL(origin);
    } catch {
      throw new Error('CORS_ALLOWED_ORIGINS contains an invalid origin.');
    }

    if (
      (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') ||
      parsed.origin !== origin ||
      parsed.username !== '' ||
      parsed.password !== ''
    ) {
      throw new Error(
        'CORS_ALLOWED_ORIGINS must contain only absolute HTTP(S) origins.',
      );
    }
  }

  return [...new Set(origins)];
}

function parseLocalAuthConfig(
  runtimeEnvironment: RuntimeEnvironment,
  authMode: string,
  environment: NodeJS.ProcessEnv,
): LocalAuthVerifierConfig {
  if (authMode !== 'local') {
    throw new Error('AUTH_VERIFIER must be firebase or local.');
  }
  if (runtimeEnvironment === 'production') {
    throw new Error(
      'The local authentication verifier is forbidden in production.',
    );
  }

  const displayName = optionalValue(environment['LOCAL_AUTH_DISPLAY_NAME']);
  const email = optionalValue(environment['LOCAL_AUTH_EMAIL']);

  return {
    mode: 'local',
    environment: runtimeEnvironment,
    idToken: requireValue(environment, 'LOCAL_AUTH_ID_TOKEN'),
    appCheckToken: requireValue(environment, 'LOCAL_APP_CHECK_TOKEN'),
    actor: {
      uid: parseSafeLabel(
        requireValue(environment, 'LOCAL_AUTH_UID'),
        'LOCAL_AUTH_UID',
      ),
      ...(displayName === undefined ? {} : { displayName }),
      ...(email === undefined ? {} : { email }),
      emailVerified: parseBoolean(
        environment['LOCAL_AUTH_EMAIL_VERIFIED'],
        'LOCAL_AUTH_EMAIL_VERIFIED',
      ),
    },
  };
}

function parseBoolean(value: string | undefined, name: string): boolean {
  const candidate = value?.trim().toLowerCase();
  if (candidate === 'true') {
    return true;
  }
  if (candidate === 'false') {
    return false;
  }
  throw new Error(`${name} must be true or false.`);
}

function requireValue(environment: NodeJS.ProcessEnv, name: string): string {
  const value = environment[name]?.trim();
  if (value === undefined || value === '') {
    throw new Error(`${name} is required.`);
  }
  return value;
}

function optionalValue(value: string | undefined): string | undefined {
  const candidate = value?.trim();
  return candidate === undefined || candidate === '' ? undefined : candidate;
}

function valueOrDefault(value: string | undefined, fallback: string): string {
  const candidate = value?.trim();
  return candidate === undefined || candidate === '' ? fallback : candidate;
}
