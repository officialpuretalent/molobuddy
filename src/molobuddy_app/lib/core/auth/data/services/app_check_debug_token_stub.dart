/// Debug-token assignment for builds with no JavaScript global to assign to.
///
/// Android and iOS attest through the Play Integrity and App Attest debug
/// providers, which take their debug token from the platform SDK rather than
/// from a page-level variable. Keeping this a no-op lets the gateway call it
/// unconditionally instead of carrying a platform branch.
void assignAppCheckDebugToken(Object value) {}
