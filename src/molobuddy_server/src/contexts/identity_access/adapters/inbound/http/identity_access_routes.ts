import type { FastifyInstance, FastifyRequest } from 'fastify';

import type { ControlApiContainer } from '../../../../../bootstrap/container.js';
import {
  authProvidersQuerySchema,
  authProvidersResponseSchema,
  problemResponses,
  sessionResponseSchema,
} from '../../../../../platform/http/schemas.js';
import { sendProblem } from '../../../../../platform/http/problems.js';
import { responseMeta } from '../../../../../platform/http/request_context.js';

export function registerIdentityAccessRoutes(
  app: FastifyInstance,
  container: ControlApiContainer,
): void {
  app.get(
    '/v1/auth/providers',
    {
      schema: {
        querystring: authProvidersQuerySchema,
        response: {
          200: authProvidersResponseSchema,
          ...problemResponses,
        },
      },
    },
    (request) => ({
      data: container.listAuthProviders.execute(),
      meta: responseMeta(request),
    }),
  );

  app.get(
    '/v1/session',
    {
      schema: {
        response: {
          200: sessionResponseSchema,
          ...problemResponses,
        },
      },
    },
    async (request, reply) => {
      const result = await container.getSession.execute(readTokens(request));
      if (!result.ok) {
        return sendProblem(reply, request, result.code);
      }

      return {
        data: result.session,
        meta: responseMeta(request),
      };
    },
  );
}

function readTokens(request: FastifyRequest): Readonly<{
  idToken?: string;
  appCheckToken?: string;
}> {
  const authorization = request.headers.authorization;
  const appCheck = request.headers['x-firebase-appcheck'];
  const idToken = parseBearerToken(authorization);

  return {
    ...(idToken === undefined ? {} : { idToken }),
    ...(typeof appCheck === 'string' && appCheck.length > 0
      ? { appCheckToken: appCheck }
      : {}),
  };
}

function parseBearerToken(header: string | undefined): string | undefined {
  if (header === undefined) {
    return undefined;
  }
  const match = /^Bearer ([^\s]+)$/i.exec(header);
  return match?.[1];
}
