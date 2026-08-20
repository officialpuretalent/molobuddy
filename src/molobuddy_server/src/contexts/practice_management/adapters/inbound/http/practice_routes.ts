import type { FastifyInstance, FastifyRequest } from 'fastify';

import type { ControlApiContainer } from '../../../../../bootstrap/container.js';
import {
  createPracticeBodySchema,
  createPracticeResponseSchema,
  problemResponses,
} from '../../../../../platform/http/schemas.js';
import { sendProblem } from '../../../../../platform/http/problems.js';
import { responseMeta } from '../../../../../platform/http/request_context.js';

export function registerPracticeRoutes(
  app: FastifyInstance,
  container: ControlApiContainer,
): void {
  app.post(
    '/v1/practices',
    {
      schema: {
        body: createPracticeBodySchema,
        response: {
          200: createPracticeResponseSchema,
          201: createPracticeResponseSchema,
          ...problemResponses,
        },
      },
    },
    async (request, reply) => {
      const verification = await container.verifier.verify(readTokens(request));
      if (!verification.ok) {
        return sendProblem(reply, request, verification.code);
      }

      const idempotencyKey = request.headers['idempotency-key'];
      const result = await container.provisionPractice.execute({
        actor: verification.actor,
        displayName: (request.body as { displayName?: unknown }).displayName,
        idempotencyKey:
          typeof idempotencyKey === 'string' ? idempotencyKey : '',
        correlationId: responseMeta(request).correlationId,
      });

      if (!result.ok) {
        return sendProblem(reply, request, result.code);
      }

      // A replay is answered 200 so a client can tell it from a creation.
      return reply
        .code(result.replayed ? 200 : 201)
        .send({ data: result.practiceRef, meta: responseMeta(request) });
    },
  );
}

function readTokens(request: FastifyRequest): Readonly<{
  idToken?: string;
  appCheckToken?: string;
}> {
  const appCheck = request.headers['x-firebase-appcheck'];
  const match = /^Bearer ([^\s]+)$/i.exec(request.headers.authorization ?? '');
  const idToken = match?.[1];

  return {
    ...(idToken === undefined ? {} : { idToken }),
    ...(typeof appCheck === 'string' && appCheck.length > 0
      ? { appCheckToken: appCheck }
      : {}),
  };
}
