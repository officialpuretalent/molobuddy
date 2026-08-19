import type { FastifyInstance } from 'fastify';

import { resolveCorrelationId } from './identifiers.js';

declare module 'fastify' {
  interface FastifyRequest {
    correlationId: string;
  }
}

export function registerRequestContext(app: FastifyInstance): void {
  app.decorateRequest('correlationId', '');

  app.addHook('onRequest', async (request, reply) => {
    request.correlationId = resolveCorrelationId(
      request.headers['x-correlation-id'],
    );
    void reply.header('x-request-id', request.id);
    void reply.header('x-correlation-id', request.correlationId);
  });

  app.addHook('onResponse', async (request, reply) => {
    request.log.info(
      {
        event: 'http_request_completed',
        requestId: request.id,
        correlationId: request.correlationId,
        method: request.method,
        route: request.routeOptions.url,
        statusCode: reply.statusCode,
        durationMs: Math.round(reply.elapsedTime),
      },
      'HTTP request completed',
    );
  });
}

export type ResponseMeta = Readonly<{
  apiVersion: 'v1';
  requestId: string;
  correlationId: string;
}>;

export function responseMeta(
  request: Readonly<{ id: string; correlationId: string }>,
): ResponseMeta {
  return {
    apiVersion: 'v1',
    requestId: request.id,
    correlationId: request.correlationId,
  };
}
