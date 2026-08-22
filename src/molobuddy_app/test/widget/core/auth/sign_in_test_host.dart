import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';

/// A session for an account that has finished setting up, so the onboarding
/// gate lets it reach the workspace.
final class FinishedSession implements SessionService {
  const FinishedSession();

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    return const AuthSuccess(
      MoloSession(
        uid: 'user_preview',
        displayName: 'Thando Mokoena',
        emailMasked: 't***@example.com',
        practiceRefs: [],
      ),
    );
  }
}

Future<void> setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

/// Pumps the real application against preview services.
///
/// [persistenceChoosable] defaults to false, which is what the test host
/// actually is: not the web. A test that wants the remember-me row says so.
Future<void> pumpPreviewSignIn(
  WidgetTester tester, {
  bool finishedSetup = false,
  bool persistenceChoosable = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(
          const AppEnvironment(
            authMode: AuthRuntimeMode.preview,
            apiBaseUrl: null,
            firebaseConfiguration: null,
          ),
        ),
        authServiceProvider.overrideWithValue(
          PreviewAuthService.forTesting(debugAllowed: true),
        ),
        authProviderCatalogueProvider.overrideWithValue(
          const BundledPreviewAuthProviderCatalogueService(),
        ),
        sessionPersistenceChoosableProvider.overrideWithValue(
          persistenceChoosable,
        ),
        if (finishedSetup)
          sessionServiceProvider.overrideWithValue(const FinishedSession()),
      ],
      child: const MoloApp(),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> semanticsLabelsContaining(WidgetTester tester, String needle) {
  final labels = <String>[];
  void visit(SemanticsNode node) {
    if (node.label.contains(needle)) {
      labels.add(node.label);
    }
    node.visitChildren((SemanticsNode child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(MaterialApp)));
  return labels;
}
