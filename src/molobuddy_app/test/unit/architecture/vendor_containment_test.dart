import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the containment rule in AGENTS.md and the authentication design:
/// vendor identity SDKs stay inside the approved auth data layer, and raw
/// tokens stay out of features.
void main() {
  const vendorPackages = <String>[
    'package:firebase_auth/',
    'package:firebase_app_check/',
    'package:firebase_core/',
  ];

  const allowedPrefixes = <String>['lib/core/auth/data/', 'lib/bootstrap/'];

  test('vendor identity SDKs stay inside the auth data layer', () {
    final offenders = <String>[];

    for (final file in _dartFilesUnder('lib')) {
      final path = file.path.replaceAll(r'\', '/');
      if (allowedPrefixes.any(path.startsWith)) {
        continue;
      }
      final source = file.readAsStringSync();
      for (final vendor in vendorPackages) {
        if (source.contains("import '$vendor")) {
          offenders.add('$path imports $vendor');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Vendor identity SDKs must be reached through Molo-owned interfaces. '
          'Move the usage into lib/core/auth/data/ and expose a Molo type.',
    );
  });

  test('only the transport reads raw tokens', () {
    final offenders = <String>[];

    for (final file in _dartFilesUnder('lib')) {
      final path = file.path.replaceAll(r'\', '/');
      final isTransport =
          path == 'lib/core/network/authenticated_transport.dart';
      final isAuthDataLayer = path.startsWith('lib/core/auth/data/');
      final isBootstrap = path.startsWith('lib/bootstrap/');
      // The auth module's provider surface names these types to declare the
      // providers. Declaring is not reading, and features still cannot import
      // it for a token because the provider throws outside bootstrap.
      final isAuthComposition = path == 'lib/core/auth/auth_providers.dart';
      if (isTransport || isAuthDataLayer || isBootstrap || isAuthComposition) {
        continue;
      }

      final source = file.readAsStringSync();
      if (source.contains('auth_token_broker.dart') ||
          source.contains('app_check_gateway.dart')) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Raw ID and App Check tokens belong to the authenticated transport. '
          'Features consume session models instead.',
    );
  });
}

Iterable<File> _dartFilesUnder(String directory) {
  return Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'));
}
