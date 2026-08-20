import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';
import 'package:molobuddy_app/core/auth/ui/views/welcome/welcome_view.dart';

const _user = AuthUser(id: 'user_1', email: 'person@example.com');

void main() {
  testWidgets('shows progress while the session loads', (tester) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.loadingSession,
        methods: [],
        user: _user,
      ),
    );

    expect(find.text('Checking what you can reach.'), findsOneWidget);
  });

  testWidgets('explains an account with no practice connected', (tester) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        session: MoloSession(uid: 'user_1', practiceRefs: []),
      ),
    );

    expect(
      find.text(
        'You are signed in. No practice has been connected to this account yet.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('reports a failed attestation in Molo words', (tester) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        failure: AuthFailure(AuthFailureKind.attestationRequired),
      ),
    );

    expect(
      find.text('This device could not be verified. Reload to try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('app_check'), findsNothing);
    expect(find.textContaining('FirebaseException'), findsNothing);
  });

  testWidgets('reports an expired session in Molo words', (tester) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        failure: AuthFailure(AuthFailureKind.sessionExpired),
      ),
    );

    expect(
      find.text('Your session ended. Sign in again to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('shows progress while the session loads at expanded width', (
    tester,
  ) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.loadingSession,
        methods: [],
        user: _user,
      ),
      size: const Size(1280, 900),
    );

    expect(find.text('Checking what you can reach.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'explains an account with no practice connected at expanded width',
    (tester) async {
      await _pumpWelcome(
        tester,
        const AuthViewState(
          status: AuthViewStatus.signedIn,
          methods: [],
          user: _user,
          session: MoloSession(uid: 'user_1', practiceRefs: []),
        ),
        size: const Size(1280, 900),
      );

      expect(
        find.text(
          'You are signed in. No practice has been connected to this account yet.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reports a failed attestation in Molo words at expanded width', (
    tester,
  ) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        failure: AuthFailure(AuthFailureKind.attestationRequired),
      ),
      size: const Size(1280, 900),
    );

    expect(
      find.text('This device could not be verified. Reload to try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the ordinary session cards at expanded width', (
    tester,
  ) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        session: MoloSession(
          uid: 'user_1',
          practiceRefs: [
            PracticeRef(
              practiceId: 'practice_1',
              displayLabel: 'Mokoena Tax Studio',
              homeRegionKey: 'za',
              routeVersion: 1,
              accessStatus: PracticeAccessStatus.active,
            ),
          ],
        ),
      ),
      size: const Size(1280, 900),
    );

    expect(find.text('Welcome, person@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpWelcome(
  WidgetTester tester,
  AuthViewState state, {
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => _StubAuthViewModel(state)),
        appEnvironmentProvider.overrideWithValue(
          const AppEnvironment(
            authMode: AuthRuntimeMode.preview,
            apiBaseUrl: null,
            firebaseConfiguration: null,
          ),
        ),
      ],
      child: MaterialApp(
        theme: MoloTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WelcomeView(),
      ),
    ),
  );
  // Not pumpAndSettle: the loadingSession state renders an indeterminate
  // CircularProgressIndicator that animates forever, so "settling" never
  // happens. A couple of plain pumps is enough for the stubbed view model's
  // async build to resolve and the frame to render.
  await tester.pump();
  await tester.pump();
}

final class _StubAuthViewModel extends AuthViewModel {
  _StubAuthViewModel(this._state);

  final AuthViewState _state;

  @override
  Future<AuthViewState> build() async => _state;
}
