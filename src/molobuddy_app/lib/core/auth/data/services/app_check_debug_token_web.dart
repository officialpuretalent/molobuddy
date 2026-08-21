import 'dart:js_interop';

/// The global the Firebase JavaScript SDK reads when App Check initialises.
///
/// `initializeAppCheck` inspects it while starting up, which is what
/// `FirebaseAppCheck.activate()` calls. Assigning it any later has no effect,
/// so the gateway sets it immediately before activation.
@JS('FIREBASE_APPCHECK_DEBUG_TOKEN')
external set _firebaseAppCheckDebugToken(JSAny? value);

/// Publishes [value] as the SDK's debug token.
///
/// A `String` pins attestation to one safelisted token. `true` asks the SDK to
/// mint one per browser profile and print it to the console.
void assignAppCheckDebugToken(Object value) {
  _firebaseAppCheckDebugToken = switch (value) {
    final String token => token.toJS,
    final bool generate => generate.toJS,
    // Nothing else is a value the SDK understands, and guessing would put the
    // build into a debug mode nobody asked for.
    _ => null,
  };
}
