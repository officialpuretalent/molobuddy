import type {
  FastifyError,
  FastifyInstance,
  FastifyReply,
  FastifyRequest,
} from 'fastify';

import { createOpaqueId } from './identifiers.js';

export type ProblemCode =
  | 'invalid_json'
  | 'invalid_query'
  | 'validation_error'
  | 'authentication_required'
  | 'token_invalid'
  | 'app_check_required'
  | 'resource_not_found'
  | 'internal_error';

export type ProblemInput = Readonly<{
  status: number;
  code: ProblemCode;
  title: string;
  detail: string;
}>;

const problems: Readonly<Record<ProblemCode, ProblemInput>> = {
  invalid_json: {
    status: 400,
    code: 'invalid_json',
    title: 'The request could not be read.',
    detail: 'Check the request format and try again.',
  },
  invalid_query: {
    status: 400,
    code: 'invalid_query',
    title: 'The query is not valid.',
    detail: 'Check the supported query fields and try again.',
  },
  validation_error: {
    status: 400,
    code: 'validation_error',
    title: 'The request is not valid.',
    detail: 'Check the highlighted fields and try again.',
  },
  authentication_required: {
    status: 401,
    code: 'authentication_required',
    title: 'Sign-in is required.',
    detail: 'Sign in and try again.',
  },
  token_invalid: {
    status: 401,
    code: 'token_invalid',
    title: 'The session is not valid.',
    detail: 'Sign in again and retry the request.',
  },
  app_check_required: {
    status: 403,
    code: 'app_check_required',
    title: 'App verification is required.',
    detail: 'Use an approved Molo app and try again.',
  },
  resource_not_found: {
    status: 404,
    code: 'resource_not_found',
    title: 'The resource was not found.',
    detail: 'Check the request and try again.',
  },
  internal_error: {
    status: 500,
    code: 'internal_error',
    title: 'Something went wrong.',
    detail: 'Try again later.',
  },
};

/**
 * The catalogue entry for a code.
 *
 * Exported so the catalogue itself is testable without an HTTP round trip.
 */
export function problemForCode(code: ProblemCode): ProblemInput {
  return problems[code];
}

export function sendProblem(
  reply: FastifyReply,
  request: FastifyRequest,
  code: ProblemCode,
): FastifyReply {
  const definition = problems[code];
  return reply
    .code(definition.status)
    .type('application/problem+json')
    .send({
      type: `https://api.molo.example/problems/${code.replaceAll('_', '-')}`,
      title: definition.title,
      status: definition.status,
      detail: definition.detail,
      instance: `/v1/problems/${createOpaqueId('prb')}`,
      code: definition.code,
      correlationId: request.correlationId,
    });
}

export function registerProblemHandlers(app: FastifyInstance): void {
  app.setNotFoundHandler(async (request, reply) => {
    return sendProblem(reply, request, 'resource_not_found');
  });

  app.setErrorHandler(
    async (
      error: FastifyError,
      request: FastifyRequest,
      reply: FastifyReply,
    ) => {
      if (isJsonSyntaxError(error)) {
        return sendProblem(reply, request, 'invalid_json');
      }
      if (error.validation !== undefined) {
        // A rejected query field and a rejected body are different mistakes
        // and the API contract gives them different codes. Neither names the
        // offending value, so nothing the caller submitted is echoed back.
        return sendProblem(
          reply,
          request,
          error.validationContext === 'body'
            ? 'validation_error'
            : 'invalid_query',
        );
      }

      request.log.error(
        {
          event: 'http_request_failed',
          requestId: request.id,
          correlationId: request.correlationId,
          errorCode: error.code,
          errorName: error.name,
        },
        'Unexpected HTTP request failure',
      );
      return sendProblem(reply, request, 'internal_error');
    },
  );
}

function isJsonSyntaxError(error: FastifyError): boolean {
  return error.code === 'FST_ERR_CTP_INVALID_JSON_BODY';
}
