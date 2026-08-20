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

    expect(find.text('This device could not be verified.'), findsOneWidget);
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

    expect(find.text('This device could not be verified.'), findsOneWidget);
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
    // Named card content, so deleting the card block cannot pass this test.
    expect(find.text('Next up'), findsWidgets);
    expect(
      find.text(
        'Connect the real Firebase project, then load your authorised '
        'practices from the Molo API.',
      ),
      findsOneWidget,
    );
    expect(find.text('Secure session'), findsWidgets);
    expect(
      find.text(
        "Firebase identity stays behind Molo's authentication boundary.",
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the masked address the server returned', (tester) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        session: MoloSession(
          uid: 'user_1',
          emailMasked: 't***@example.com',
          practiceRefs: [],
        ),
      ),
    );

    expect(find.text('Signed in as'), findsOneWidget);
    expect(find.text('t***@example.com'), findsOneWidget);
    // The address typed into the sign-in form must not be what is shown.
    expect(find.text('person@example.com'), findsNothing);
  });

  testWidgets('falls back to the local address before a session', (
    tester,
  ) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.loadingSession,
        methods: [],
        user: _user,
      ),
    );

    expect(find.text('Signed in as'), findsOneWidget);
    expect(find.text('person@example.com'), findsOneWidget);
  });

  testWidgets('reports a network failure instead of pretending it loaded', (
    tester,
  ) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        failure: AuthFailure(AuthFailureKind.networkUnavailable),
      ),
    );

    expect(
      find.text(
        'Molo cannot connect right now. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Next up'), findsNothing);
  });

  testWidgets('reports a build with no session service', (tester) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        failure: AuthFailure(AuthFailureKind.configurationMissing),
      ),
    );

    expect(
      find.text('Session details are not available in this build yet.'),
      findsOneWidget,
    );
  });

  testWidgets('offers a retry big enough to hit, and wires it', (tester) async {
    final viewModel = _StubAuthViewModel(
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        failure: AuthFailure(AuthFailureKind.networkUnavailable),
      ),
    );
    await _pumpWelcome(tester, null, viewModel: viewModel);

    final retry = find.byKey(const Key('retry_session_button'));
    expect(retry, findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    final size = tester.getSize(retry);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));

    await tester.tap(retry);
    await tester.pump();

    expect(viewModel.reloadCalls, 1);
  });

  testWidgets('a build with no session service offers no retry', (
    tester,
  ) async {
    // Nothing about pressing a button changes how this build was compiled, so
    // a retry here could only ever fail the same way.
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        failure: AuthFailure(AuthFailureKind.configurationMissing),
      ),
    );

    expect(
      find.text('Session details are not available in this build yet.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retry_session_button')), findsNothing);
  });

  testWidgets(
    'an ended session offers no retry, only the sign-in it asks for',
    (tester) async {
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
      expect(find.byKey(const Key('retry_session_button')), findsNothing);
    },
  );

  testWidgets('a provider outage offers a retry', (tester) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        failure: AuthFailure(AuthFailureKind.providerUnavailable),
      ),
    );

    expect(find.byKey(const Key('retry_session_button')), findsOneWidget);
  });

  testWidgets('an unexpected failure offers a retry', (tester) async {
    await _pumpWelcome(
      tester,
      const AuthViewState(
        status: AuthViewStatus.signedIn,
        methods: [],
        user: _user,
        failure: AuthFailure(AuthFailureKind.unexpected),
      ),
    );

    expect(find.byKey(const Key('retry_session_button')), findsOneWidget);
  });

  testWidgets('offers the retry at expanded width without overflowing', (
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

    expect(find.byKey(const Key('retry_session_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpWelcome(
  WidgetTester tester,
  AuthViewState? state, {
  Size size = const Size(390, 844),
  _StubAuthViewModel? viewModel,
}) async {
  final model = viewModel ?? _StubAuthViewModel(state!);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => model),
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
  int reloadCalls = 0;

  @override
  Future<AuthViewState> build() async => _state;

  @override
  Future<void> reloadSession() async {
    reloadCalls += 1;
  }
}
