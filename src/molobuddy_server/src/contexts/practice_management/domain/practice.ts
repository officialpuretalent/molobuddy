export type PracticeStatus = 'active' | 'suspended' | 'closed';

/**
 * A practice as the domain knows it.
 *
 * Deliberately carries no `version`. That field is the optimistic concurrency
 * token behind the API's ETag, it must change on every write, and it is
 * therefore owned by the repository rather than by a command. Putting it here
 * would invite a caller to pin it, which is exactly how lost-update protection
 * gets silently disabled.
 */
export type Practice = Readonly<{
  practiceId: string;
  displayName: string;
  homeRegionKey: string;
  routeVersion: number;
  status: PracticeStatus;
  createdByUid: string;
}>;

/**
 * The founding owner. Written exactly as the identity and access data design's
 * PracticeMember.
 */
export type PracticeMemberRecord = Readonly<{
  practiceId: string;
  uid: string;
  role: 'owner';
  status: 'active';
  displayName: string;
  emailLower: string;
}>;

/**
 * The control-plane routing projection.
 *
 * Deliberately identical to the shape GET /v1/session returns, so there is no
 * mapping layer between storage and contract that could drift.
 */
export type PracticeRefRecord = Readonly<{
  practiceId: string;
  displayLabel: string;
  homeRegionKey: string;
  routeVersion: number;
  accessStatus: 'active' | 'invited' | 'suspended';
}>;

const maximumNameLength = 120;

/**
 * Returns the storable practice name, or undefined when it is not acceptable.
 *
 * Returning undefined rather than throwing keeps the decision in the caller,
 * which owns how a rejection is reported.
 */
export function normalisePracticeName(value: unknown): string | undefined {
  if (typeof value !== 'string') {
    return undefined;
  }
  const trimmed = value.trim();
  if (trimmed.length === 0 || trimmed.length > maximumNameLength) {
    return undefined;
  }
  return trimmed;
}
