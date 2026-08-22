/** Signs the browser-visible OAuth state while the durable state remains server-owned. */
export interface OAuthStateSigner {
  sign(stateId: string): string;

  verify(signedState: string): string | undefined;
}
