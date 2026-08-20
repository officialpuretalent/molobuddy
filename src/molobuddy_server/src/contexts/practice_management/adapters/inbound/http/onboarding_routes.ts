import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';

import type { ControlApiContainer } from '../../../../../bootstrap/container.js';
import type { VerifiedActor } from '../../../../identity_access/index.js';
import { sendProblem } from '../../../../../platform/http/problems.js';
import type { ProblemPointer } from '../../../../../platform/http/problems.js';
import { responseMeta } from '../../../../../platform/http/request_context.js';
import {
  createPracticeResponseSchema,
  onboardingPatchBodySchema,
  onboardingResponseSchema,
  problemResponses,
} from '../../../../../platform/http/schemas.js';

export function registerOnboardingRoutes(
  app: FastifyInstance,
  container: ControlApiContainer,
): void {
  app.get(
    '/v1/onboarding',
    {
      schema: {
        response: { 200: onboardingResponseSchema, ...problemResponses },
      },
    },
    async (request, reply) => {
      const actor = await verified(container, request, reply);
      if (actor === undefined) {
        return reply;
      }
      return reply.code(200).send({
        data: await container.getOnboarding.execute(actor.uid),
        meta: responseMeta(request),
      });
    },
  );

  app.patch(
    '/v1/onboarding',
    {
      schema: {
        body: onboardingPatchBodySchema,
        response: { 200: onboardingResponseSchema, ...problemResponses },
      },
    },
    async (request, reply) => {
      const actor = await verified(container, request, reply);
      if (actor === undefined) {
        return reply;
      }

      const result = await container.saveOnboardingAnswers.execute({
        uid: actor.uid,
        answers: (request.body as { answers?: unknown }).answers,
        expectedVersion: readIfMatch(request),
      });
      if (!result.ok) {
        return sendProblem(
          reply,
          request,
          result.code,
          result.code === 'validation_error'
            ? [pointerFor(result.pointer, 'validation_error')]
            : [],
        );
      }

      return reply
        .code(200)
        .send({ data: result.view, meta: responseMeta(request) });
    },
  );

  app.post(
    '/v1/onboarding:complete',
    {
      schema: {
        response: {
          200: createPracticeResponseSchema,
          201: createPracticeResponseSchema,
          ...problemResponses,
        },
      },
    },
    async (request, reply) => {
      const actor = await verified(container, request, reply);
      if (actor === undefined) {
        return reply;
      }

      const key = request.headers['idempotency-key'];
      const result = await container.completeOnboarding.execute({
        actor,
        idempotencyKey: typeof key === 'string' ? key : '',
        correlationId: responseMeta(request).correlationId,
      });
      if (!result.ok) {
        return sendProblem(
          reply,
          request,
          result.code,
          result.code === 'validation_error'
            ? [pointerFor(result.pointer, 'validation_error')]
            : result.missing.map((pointer) =>
                pointerFor(pointer, 'answer_required'),
              ),
        );
      }

      // A replay is answered 200 so a client can tell it from a creation.
      return reply
        .code(result.replayed ? 200 : 201)
        .send({ data: result.practiceRef, meta: responseMeta(request) });
    },
  );
}

/**
 * The verified caller, or undefined once a problem has been sent.
 *
 * Returning undefined rather than throwing keeps the three handlers reading
 * the same way, and keeps verification ahead of every read of the body.
 */
async function verified(
  container: ControlApiContainer,
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<VerifiedActor | undefined> {
  const verification = await container.verifier.verify(readTokens(request));
  if (!verification.ok) {
    await sendProblem(reply, request, verification.code);
    return undefined;
  }
  return verification.actor;
}

function pointerFor(pointer: string, code: string): ProblemPointer {
  // The pointer names the field. The message never repeats the value, so
  // nothing the caller submitted is echoed back.
  return { pointer, code, message: 'This answer is not acceptable.' };
}

/** The entity tag from `If-Match`, unquoted, or undefined when absent. */
function readIfMatch(request: FastifyRequest): string | undefined {
  const header = request.headers['if-match'];
  if (typeof header !== 'string' || header.length === 0) {
    return undefined;
  }
  const match = /^(?:W\/)?"?([^"]+)"?$/.exec(header.trim());
  return match?.[1];
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
