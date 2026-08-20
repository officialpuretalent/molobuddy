/**
 * Whether this user has finished setting up.
 *
 * One boolean, deliberately. The resume step is practice_management domain
 * logic, and that context already imports this one, so computing it here would
 * be a cycle and duplicating it would drift. A client that needs the step
 * fetches GET /v1/onboarding, which the wizard does when it opens anyway.
 */
export interface OnboardingStatusReader {
  isComplete(uid: string): Promise<boolean>;
}
