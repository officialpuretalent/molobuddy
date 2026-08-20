const opaqueIdSchema = {
  type: 'string',
  minLength: 5,
  maxLength: 160,
} as const;

export const responseMetaSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['apiVersion', 'requestId', 'correlationId'],
  properties: {
    apiVersion: { const: 'v1' },
    requestId: opaqueIdSchema,
    correlationId: opaqueIdSchema,
  },
} as const;

export const problemSchema = {
  $id: 'problem',
  type: 'object',
  additionalProperties: false,
  required: [
    'type',
    'title',
    'status',
    'detail',
    'instance',
    'code',
    'correlationId',
  ],
  properties: {
    type: { type: 'string', format: 'uri' },
    title: { type: 'string', minLength: 1, maxLength: 200 },
    status: { type: 'integer', minimum: 400, maximum: 599 },
    detail: { type: 'string', minLength: 1, maxLength: 500 },
    instance: { type: 'string', pattern: '^/v1/problems/prb_[A-Za-z0-9]+$' },
    code: { type: 'string', pattern: '^[a-z][a-z0-9_]*$' },
    correlationId: opaqueIdSchema,
    errors: {
      type: 'array',
      maxItems: 32,
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['pointer', 'code', 'message'],
        properties: {
          pointer: { type: 'string', maxLength: 200 },
          code: { type: 'string', pattern: '^[a-z][a-z0-9_]*$' },
          message: { type: 'string', maxLength: 300 },
        },
      },
    },
  },
} as const;

export const healthResponseSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['status', 'regionKey', 'release'],
  properties: {
    status: { const: 'ok' },
    regionKey: { type: 'string', minLength: 1, maxLength: 64 },
    release: { type: 'string', minLength: 1, maxLength: 64 },
  },
} as const;

const authProviderSchema = {
  type: 'object',
  additionalProperties: false,
  required: [
    'providerId',
    'kind',
    'displayNameKey',
    'availability',
    'enabledPlatforms',
    'supportsLinking',
    'sortOrder',
  ],
  properties: {
    providerId: { type: 'string', minLength: 1, maxLength: 100 },
    kind: { enum: ['email_password', 'federated'] },
    displayNameKey: { type: 'string', minLength: 1, maxLength: 100 },
    availability: { enum: ['available', 'coming_soon', 'unavailable'] },
    enabledPlatforms: {
      type: 'array',
      uniqueItems: true,
      maxItems: 3,
      items: { enum: ['android', 'ios', 'web'] },
    },
    supportsLinking: { type: 'boolean' },
    sortOrder: { type: 'integer', minimum: 0, maximum: 10_000 },
  },
} as const;

export const authProvidersQuerySchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    platform: { enum: ['android', 'ios', 'web'] },
    appVersion: { type: 'string', minLength: 1, maxLength: 64 },
    invitationToken: { type: 'string', minLength: 1, maxLength: 2048 },
  },
} as const;

export const authProvidersResponseSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['data', 'meta'],
  properties: {
    data: {
      type: 'object',
      additionalProperties: false,
      required: ['providers'],
      properties: {
        providers: {
          type: 'array',
          maxItems: 32,
          items: authProviderSchema,
        },
      },
    },
    meta: responseMetaSchema,
  },
} as const;

/**
 * The routing projection.
 *
 * One definition serves both the session list and the practice creation
 * response. The stored record has the same shape deliberately, so a second
 * declaration here would be the seam the two contracts drift apart at.
 */
export const practiceRefSchema = {
  type: 'object',
  additionalProperties: false,
  required: [
    'practiceId',
    'displayLabel',
    'homeRegionKey',
    'routeVersion',
    'accessStatus',
  ],
  properties: {
    practiceId: { type: 'string', minLength: 1, maxLength: 128 },
    displayLabel: { type: 'string', minLength: 1, maxLength: 200 },
    homeRegionKey: { type: 'string', minLength: 1, maxLength: 64 },
    routeVersion: { type: 'integer', minimum: 1 },
    accessStatus: { enum: ['active', 'invited', 'suspended'] },
  },
} as const;

export const createPracticeBodySchema = {
  type: 'object',
  additionalProperties: false,
  required: ['displayName'],
  properties: {
    displayName: { type: 'string', minLength: 1, maxLength: 120 },
  },
} as const;

export const createPracticeResponseSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['data', 'meta'],
  properties: {
    data: practiceRefSchema,
    meta: responseMetaSchema,
  },
} as const;

export const sessionResponseSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['data', 'meta'],
  properties: {
    data: {
      type: 'object',
      additionalProperties: false,
      required: ['user', 'practiceRefs'],
      properties: {
        user: {
          type: 'object',
          additionalProperties: false,
          required: ['uid'],
          properties: {
            uid: { type: 'string', minLength: 1, maxLength: 128 },
            displayName: { type: 'string', minLength: 1, maxLength: 200 },
            emailMasked: { type: 'string', minLength: 1, maxLength: 320 },
            preferredLocale: { type: 'string', minLength: 2, maxLength: 35 },
          },
        },
        practiceRefs: {
          type: 'array',
          maxItems: 500,
          items: practiceRefSchema,
        },
      },
    },
    meta: responseMetaSchema,
  },
} as const;

export const problemResponses = {
  400: problemSchema,
  401: problemSchema,
  403: problemSchema,
  404: problemSchema,
  426: problemSchema,
  500: problemSchema,
} as const;
