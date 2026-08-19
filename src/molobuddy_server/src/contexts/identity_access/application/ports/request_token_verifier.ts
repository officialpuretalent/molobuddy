export type PresentedRequestTokens = Readonly<{
  idToken?: string;
  appCheckToken?: string;
}>;

export type VerifiedActor = Readonly<{
  uid: string;
  firebaseProjectId: string;
  appId: string;
  providerIds: readonly string[];
  emailVerified: boolean;
  displayName?: string;
  email?: string;
  preferredLocale?: string;
}>;

export type TokenVerificationFailure = Readonly<{
  ok: false;
  code: 'authentication_required' | 'token_invalid' | 'app_check_required';
}>;

export type TokenVerificationResult =
  Readonly<{ ok: true; actor: VerifiedActor }> | TokenVerificationFailure;

export interface RequestTokenVerifier {
  verify(tokens: PresentedRequestTokens): Promise<TokenVerificationResult>;
}
