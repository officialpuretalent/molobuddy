import type { AccountingProviderKey } from '../../domain/accounting_provider.js';

/**
 * State is server-owned, single-use and regional. The callback never trusts a
 * practice, region or return URI supplied in a provider redirect.
 */
export type OAuthAuthorisationState = Readonly<{
  stateId: string;
  practiceId: string;
  connectionId: string;
  providerKey: AccountingProviderKey;
  actorUid: string;
  returnUri: string;
  codeVerifier?: string;
  expiresAt: string;
}>;

export type ConsumeOAuthAuthorisationStateResult =
  | Readonly<{ ok: true; state: OAuthAuthorisationState }>
  | Readonly<{
      ok: false;
      code: 'oauth_state_expired' | 'oauth_state_invalid' | 'oauth_state_used';
    }>;

export interface OAuthAuthorisationStateStore {
  create(state: OAuthAuthorisationState): Promise<void>;

  consume(
    stateId: string,
    now: string,
  ): Promise<ConsumeOAuthAuthorisationStateResult>;
}
