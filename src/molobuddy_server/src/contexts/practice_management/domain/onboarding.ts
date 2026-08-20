import { normalisePracticeName } from './practice.js';

export const practiceSizes = ['solo', 'small_team', 'growing_team'] as const;
export type PracticeSize = (typeof practiceSizes)[number];

export const onboardingPriorities = [
  'deadlines',
  'documents',
  'teamwork',
  'visibility',
] as const;
export type OnboardingPriority = (typeof onboardingPriorities)[number];

export const startingPoints = [
  'import_clients',
  'add_first_client',
  'sample_workspace',
] as const;
export type StartingPoint = (typeof startingPoints)[number];

export type OnboardingAnswers = Readonly<{
  practiceName?: string;
  practiceSize?: PracticeSize;
  priorities?: readonly OnboardingPriority[];
  startingPoint?: StartingPoint;
}>;

/**
 * Where a returning user picks up.
 *
 * Derived from which answers are present, never stored. A stored step enum
 * would weld this contract to the wizard's current shape, so reordering two
 * screens would need a migration of every in-flight record.
 */
export type OnboardingStep =
  'practice' | 'priorities' | 'starting_point' | 'ready_to_complete';

export function resumeStepFor(answers: OnboardingAnswers): OnboardingStep {
  if (
    answers.practiceName === undefined ||
    answers.practiceSize === undefined
  ) {
    return 'practice';
  }
  if (answers.priorities === undefined || answers.priorities.length === 0) {
    return 'priorities';
  }
  if (answers.startingPoint === undefined) {
    return 'starting_point';
  }
  return 'ready_to_complete';
}

/**
 * JSON pointers for every required answer still missing.
 *
 * This is the completion invariant. The server enforces it rather than
 * policing transitions, so a client that answers everything in one request is
 * behaving correctly rather than circumventing anything.
 */
export function missingAnswerPointers(
  answers: OnboardingAnswers,
): readonly string[] {
  const missing: string[] = [];
  if (answers.practiceName === undefined) {
    missing.push('/answers/practiceName');
  }
  if (answers.practiceSize === undefined) {
    missing.push('/answers/practiceSize');
  }
  if (answers.priorities === undefined || answers.priorities.length === 0) {
    missing.push('/answers/priorities');
  }
  if (answers.startingPoint === undefined) {
    missing.push('/answers/startingPoint');
  }
  return missing;
}

export type AnswerPatchResult =
  | Readonly<{ ok: true; answers: OnboardingAnswers }>
  | Readonly<{ ok: false; pointer: string }>;

const knownAnswers = new Set([
  'practiceName',
  'practiceSize',
  'priorities',
  'startingPoint',
]);

/**
 * Validates one step's answers.
 *
 * Every value here is client-supplied and untrusted, so each is checked
 * against its enumeration rather than stored as given. An unknown field is
 * refused rather than dropped: silently ignoring it would let a client believe
 * it had set something and be wrong until somebody checked.
 */
export function parseAnswerPatch(value: unknown): AnswerPatchResult {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    return { ok: false, pointer: '/answers' };
  }

  const source = value as Record<string, unknown>;
  for (const field of Object.keys(source)) {
    if (!knownAnswers.has(field)) {
      return { ok: false, pointer: `/answers/${field}` };
    }
  }

  const answers: {
    practiceName?: string;
    practiceSize?: PracticeSize;
    priorities?: readonly OnboardingPriority[];
    startingPoint?: StartingPoint;
  } = {};

  const rawName = source['practiceName'];
  if (rawName !== undefined) {
    // The same rule the practice itself uses. Two rules for one name is how an
    // answer onboarding accepted becomes a practice that cannot be created.
    const name = normalisePracticeName(rawName);
    if (name === undefined) {
      return { ok: false, pointer: '/answers/practiceName' };
    }
    answers.practiceName = name;
  }

  const rawSize = source['practiceSize'];
  if (rawSize !== undefined) {
    if (!isMember(practiceSizes, rawSize)) {
      return { ok: false, pointer: '/answers/practiceSize' };
    }
    answers.practiceSize = rawSize;
  }

  const rawPriorities = source['priorities'];
  if (rawPriorities !== undefined) {
    if (!Array.isArray(rawPriorities) || rawPriorities.length === 0) {
      return { ok: false, pointer: '/answers/priorities' };
    }
    const chosen: OnboardingPriority[] = [];
    for (const entry of rawPriorities) {
      if (!isMember(onboardingPriorities, entry) || chosen.includes(entry)) {
        return { ok: false, pointer: '/answers/priorities' };
      }
      chosen.push(entry);
    }
    answers.priorities = chosen;
  }

  const rawStartingPoint = source['startingPoint'];
  if (rawStartingPoint !== undefined) {
    if (!isMember(startingPoints, rawStartingPoint)) {
      return { ok: false, pointer: '/answers/startingPoint' };
    }
    answers.startingPoint = rawStartingPoint;
  }

  return { ok: true, answers };
}

/** Applies a patch over stored answers, leaving anything it does not carry. */
export function mergeAnswers(
  stored: OnboardingAnswers,
  patch: OnboardingAnswers,
): OnboardingAnswers {
  return { ...stored, ...patch };
}

function isMember<T extends string>(
  allowed: readonly T[],
  value: unknown,
): value is T {
  return (
    typeof value === 'string' && (allowed as readonly string[]).includes(value)
  );
}
