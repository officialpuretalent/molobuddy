import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// An App Check debug token is an attestation bypass.
///
/// It used to be set in `web/index.html`, a tracked file, with a comment asking
/// whoever deploys to remember to remove it. This test replaces that manual
/// step: the token now arrives as a build define from gitignored local config,
/// so no tracked file can carry one.
void main() {
  test('web/index.html sets no App Check debug token', () {
    final indexHtml = File('web/index.html');
    expect(
      indexHtml.existsSync(),
      isTrue,
      reason: 'web/index.html should exist; run this test from src/molobuddy_app',
    );

    final source = indexHtml.readAsStringSync();
    final assignment = RegExp(
      r'''FIREBASE_APPCHECK_DEBUG_TOKEN\s*=''',
    );

    expect(
      assignment.hasMatch(source),
      isFalse,
      reason:
          'web/index.html assigns FIREBASE_APPCHECK_DEBUG_TOKEN. Configure '
          'MOLO_APP_CHECK_DEBUG_TOKEN in config/firebase.development.json '
          'instead, which git ignores.',
    );
  });

  test('the committed config template carries no debug token value', () {
    final template = File('config/firebase.development.example.json');
    expect(template.existsSync(), isTrue);

    final source = template.readAsStringSync();
    final populated = RegExp(
      r'''"MOLO_APP_CHECK_DEBUG_TOKEN"\s*:\s*"(.+)"''',
    ).firstMatch(source);

    expect(
      populated,
      isNull,
      reason:
          'The template records the key name with an empty value. A real token '
          'in a committed file is a bypass anyone who clones can present.',
    );
  });
}
