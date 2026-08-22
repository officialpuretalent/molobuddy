import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_debug_token.dart';

/// The debug-token global decides whether local attestation is stable.
///
/// A pinned token is safelisted once and every browser profile then attests.
/// `true` asks the Firebase SDK to mint a fresh token per profile and print
/// it, which is what made "This device could not be verified." look
/// intermittent: the token followed the browser, not the build.
void main() {
  group('appCheckDebugTokenGlobal', () {
    test('pins a configured token so every profile presents the same one', () {
      expect(
        appCheckDebugTokenGlobal('3f6b1c9e-0b8d-4a71-9c2e-1d4f8a7b6c50'),
        '3f6b1c9e-0b8d-4a71-9c2e-1d4f8a7b6c50',
      );
    });

    test('trims surrounding whitespace a config file easily carries', () {
      expect(
        appCheckDebugTokenGlobal('  token-with-spaces  '),
        'token-with-spaces',
      );
    });

    test('falls back to SDK generation when no token is configured', () {
      // Keeps the previous behaviour for anyone who has not set the define,
      // rather than activating with a dummy site key and no debug mode, which
      // would fail attestation outright.
      expect(appCheckDebugTokenGlobal(null), isTrue);
    });

    test('treats an empty or blank value as not configured', () {
      expect(appCheckDebugTokenGlobal(''), isTrue);
      expect(appCheckDebugTokenGlobal('   '), isTrue);
    });
  });

  group('pinAppCheckDebugToken', () {
    test('is a harmless no-op off the web, where there is no JS global', () {
      // Android and iOS use the Apple/Android debug providers, which never
      // read this value. The call must stay safe so the gateway needs no
      // platform branch of its own.
      expect(() => pinAppCheckDebugToken('any-token'), returnsNormally);
      expect(() => pinAppCheckDebugToken(null), returnsNormally);
    });
  });
}
