import type { FastifyInstance } from 'fastify';

import type { ServerConfig } from '../../bootstrap/config.js';
import { healthResponseSchema } from './schemas.js';

export function registerHealthRoute(
  app: FastifyInstance,
  config: Pick<ServerConfig, 'regionKey' | 'releaseId'>,
): void {
  app.get(
    '/health',
    {
      schema: {
        response: {
          200: healthResponseSchema,
        },
      },
    },
    () => ({
      status: 'ok' as const,
      regionKey: config.regionKey,
      release: config.releaseId,
    }),
  );
}
