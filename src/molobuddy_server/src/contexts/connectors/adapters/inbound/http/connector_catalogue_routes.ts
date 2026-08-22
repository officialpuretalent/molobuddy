import type { FastifyInstance } from 'fastify';

import type { ControlApiContainer } from '../../../../../bootstrap/container.js';
import {
  connectorCatalogueResponseSchema,
  problemResponses,
} from '../../../../../platform/http/schemas.js';
import { responseMeta } from '../../../../../platform/http/request_context.js';

export function registerConnectorCatalogueRoutes(
  app: FastifyInstance,
  container: ControlApiContainer,
): void {
  app.get(
    '/v1/connectors',
    {
      schema: {
        response: {
          200: connectorCatalogueResponseSchema,
          ...problemResponses,
        },
      },
    },
    (request) => ({
      data: { connectors: container.listConnectorDefinitions.execute() },
      meta: responseMeta(request),
    }),
  );
}
