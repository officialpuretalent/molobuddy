import type { PracticeRefReader } from '../ports/practice_ref_reader.js';
import type {
  PresentedRequestTokens,
  RequestTokenVerifier,
  TokenVerificationFailure,
} from '../ports/request_token_verifier.js';

export type Session = Readonly<{
  user: Readonly<{
    uid: string;
    displayName?: string;
    emailMasked?: string;
    preferredLocale?: string;
  }>;
  practiceRefs: readonly Readonly<{
    practiceId: string;
    displayLabel: string;
    homeRegionKey: string;
    routeVersion: number;
    accessStatus: 'active' | 'invited' | 'suspended';
  }>[];
}>;

export type GetSessionResult =
  Readonly<{ ok: true; session: Session }> | TokenVerificationFailure;

export class GetSession {
  constructor(
    private readonly verifier: RequestTokenVerifier,
    private readonly practiceRefs: PracticeRefReader,
  ) {}

  async execute(tokens: PresentedRequestTokens): Promise<GetSessionResult> {
    const verification = await this.verifier.verify(tokens);
    if (!verification.ok) {
      return verification;
    }

    const actor = verification.actor;
    const emailMasked =
      actor.email === undefined ? undefined : maskEmail(actor.email);
    // The uid comes from the verified token, never from the request, so one
    // user cannot read another's list.
    const practiceRefs = await this.practiceRefs.listForUser(actor.uid);

    return {
      ok: true,
      session: {
        user: {
          uid: actor.uid,
          ...(actor.displayName === undefined
            ? {}
            : { displayName: actor.displayName }),
          ...(emailMasked === undefined ? {} : { emailMasked }),
          ...(actor.preferredLocale === undefined
            ? {}
            : { preferredLocale: actor.preferredLocale }),
        },
        practiceRefs,
      },
    };
  }
}

export function maskEmail(email: string): string | undefined {
  const separator = email.lastIndexOf('@');
  if (separator <= 0 || separator === email.length - 1) {
    return undefined;
  }

  const local = email.slice(0, separator);
  const domain = email.slice(separator + 1);
  const visible = local.slice(0, Math.min(1, local.length));
  return `${visible}***@${domain}`;
}
