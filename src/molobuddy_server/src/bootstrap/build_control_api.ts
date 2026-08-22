import cors from '@fastify/cors';
import Fastify, { LogController, type FastifyInstance } from 'fastify';

import type { ServerConfig } from './config.js';
import {
  createControlApiContainer,
  type ControlApiDependencies,
} from './container.js';
import { registerIdentityAccessRoutes } from '../contexts/identity_access/adapters/inbound/http/identity_access_routes.js';
import { registerConnectorCatalogueRoutes } from '../contexts/connectors/adapters/inbound/http/connector_catalogue_routes.js';
import { registerOnboardingRoutes } from '../contexts/practice_management/adapters/inbound/http/onboarding_routes.js';
import { registerPracticeRoutes } from '../contexts/practice_management/adapters/inbound/http/practice_routes.js';
import { createOpaqueId } from '../platform/http/identifiers.js';
import { registerHealthRoute } from '../platform/http/health_route.js';
import { registerProblemHandlers } from '../platform/http/problems.js';
import { registerRequestContext } from '../platform/http/request_context.js';

export async function buildControlApi(
  config: ServerConfig,
  dependencies: ControlApiDependencies = {},
): Promise<FastifyInstance> {
  const app = Fastify({
    ajv: {
      customOptions: {
        removeAdditional: false,
      },
    },
    genReqId: () => createOpaqueId('req'),
    logController: new LogController({ disableRequestLogging: true }),
    logger: {
      level: config.logLevel,
      redact: {
        paths: [
          'req.headers.authorization',
          'req.headers.x-firebase-appcheck',
          'req.headers.cookie',
          'request.headers.authorization',
          'request.headers.x-firebase-appcheck',
          'request.headers.cookie',
          'authorization',
          'appCheckToken',
          'idToken',
          'email',
        ],
        censor: '[REDACTED]',
      },
    },
  });

  await app.register(cors, {
    origin:
      config.corsAllowedOrigins.length === 0
        ? false
        : [...config.corsAllowedOrigins],
    credentials: false,
    methods: ['GET', 'POST', 'PATCH', 'OPTIONS'],
    allowedHeaders: [
      'Accept',
      'Content-Type',
      'Authorization',
      'X-Firebase-AppCheck',
      'X-Correlation-Id',
      'Idempotency-Key',
      'If-Match',
    ],
    exposedHeaders: ['X-Request-Id', 'X-Correlation-Id'],
    maxAge: 600,
    strictPreflight: true,
  });

  registerRequestContext(app);
  registerProblemHandlers(app);

  const container = createControlApiContainer(config, dependencies);
  registerHealthRoute(app, config);
  registerConnectorCatalogueRoutes(app, container);
  registerIdentityAccessRoutes(app, container);
  registerPracticeRoutes(app, container);
  registerOnboardingRoutes(app, container);

  await app.ready();
  return app;
}
