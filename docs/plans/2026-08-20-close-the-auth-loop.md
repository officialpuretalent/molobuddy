# Close the Auth Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Carry an authenticated user from `authenticated` through `loading_session` to `ready`, so the Flutter application and the control API exchange verified tokens for the first time.

**Architecture:** App Check debug attestation makes the client able to attest, which unblocks `AUTH_VERIFIER=firebase` on the server. A new `SessionService` calls `GET /v1/session` through a Dio instance carrying `MoloAuthenticatedTransport`, so identity and attestation tokens are attached in one place. `AuthRepository` gains `loadSession`, the view model gains a `loadingSession` state, and the welcome view renders the real session rather than a local echo of the sign-in form.

**Tech Stack:** Flutter 3.44.0 / Dart 3.12.0, Riverpod 3.3.2 with `riverpod_annotation` 4.0.3, Dio 5.11.0, `firebase_app_check` 0.4.6, `firebase_auth` 6.5.7, `firebase_core` 4.13.0. Server is Node.js 24 with Fastify 5 and `firebase-admin` 14.2.0.

**Spec:** [`docs/backend_design/authentication.md`](../backend_design/authentication.md), sections 6 (state machine), 7 (token broker and API client), 13 (App Check), 15 (failure mapping) and 17 (implementation status). Operational context in [`docs/local_development.md`](../local_development.md).

## Global Constraints

- Sentence case for all interface copy. No all-caps labels.
- No em dashes in product copy. Use full stops, commas, colons or shorter sentences.
- Text contrast at least 4.5:1; interactive contrast at least 3:1.
- Interactive targets at least 48x48 logical pixels.
- Status must never be carried by colour alone.
- Every screen works on Web, Android and iOS. Verify compact (390x844) and expanded (1280x900).
- Visible keyboard focus, distinct from hover.
- Never introduce a deprecated API. Deprecation diagnostics are CI failures.
- No feature may import `firebase_auth`, `firebase_app_check` or `firebase_core`, or read a raw token, outside `lib/core/auth/data/` and `lib/bootstrap/`. Enforced by `test/unit/architecture/vendor_containment_test.dart`.
- Provider error strings are never shown raw and never drive control flow outside the adapter.
- Raw tokens never enter feature state, logs, analytics or URLs.
- Localised copy lives in `lib/app/localisation/l10n/app_en.arb` and `app_en_ZA.arb`. Never concatenate translated fragments.
- Verification gates: `flutter analyze` clean, `flutter test` green, `dart format --set-exit-if-changed lib test` clean, and `npm run check` green in `src/molobuddy_server`.

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/core/auth/data/models/molo_session.dart` (create) | `MoloSession` and `PracticeRef` value types |
| `lib/core/auth/data/models/auth_failure.dart` (modify) | Add `attestationRequired` and `sessionExpired` kinds |
| `lib/core/auth/data/services/session_service.dart` (create) | `SessionService` interface plus `UnavailableSessionService` |
| `lib/core/auth/data/services/http_session_service.dart` (create) | `GET /v1/session`, envelope parsing, problem-code mapping |
| `lib/core/network/network_providers.dart` (create) | Authenticated `Dio` provider carrying the transport |
| `lib/core/auth/data/repositories/auth_repository.dart` (modify) | Add `loadSession` |
| `lib/core/auth/data/repositories/default_auth_repository.dart` (modify) | Delegate `loadSession` |
| `lib/core/auth/ui/view_models/auth_view_state.dart` (modify) | Add `loadingSession` status and `session` field |
| `lib/core/auth/ui/view_models/auth_view_model.dart` (modify) | Load the session after sign-in and on restore |
| `lib/core/auth/ui/views/welcome/welcome_view.dart` (modify) | Render the real session, its loading and failure states |
| `lib/core/auth/auth_providers.dart` (modify) | Provide `SessionService` |
| `lib/bootstrap/app_bootstrap.dart` (modify) | Construct the authenticated Dio and session service |
| `web/index.html` (modify) | Uncomment the App Check debug flag |

---

### Task 1: Activate App Check debug attestation

Nothing downstream can be tested against `AUTH_VERIFIER=firebase` until the client produces an attestation token. This task is configuration and manual verification, so it has no unit test; its deliverable is an observed token.

**Files:**
- Modify: `src/molobuddy_app/web/index.html`
- Modify: `src/molobuddy_app/config/firebase.development.json` (gitignored)

**Interfaces:**
- Consumes: `FirebaseAppCheckGateway.activate` from the existing code.
- Produces: a working attestation path, so later tasks can call `/v1/session` with `AUTH_VERIFIER=firebase`.

- [ ] **Step 1: Enable the debug flag in the web host page**

In `web/index.html`, uncomment this line so it sits immediately before the `flutter_bootstrap.js` script tag:

```html
<script>self.FIREBASE_APPCHECK_DEBUG_TOKEN = true;</script>
```

- [ ] **Step 2: Turn on debug attestation in local config**

In `src/molobuddy_app/config/firebase.development.json` set:

```json
"MOLO_APP_CHECK_DEBUG": true
```

- [ ] **Step 3: Run the app and capture the debug token**

```bash
cd src/molobuddy_app && flutter run -d chrome --dart-define-from-file=config/firebase.development.json
```

Expected: the browser console prints a line containing `App Check debug token:` followed by a UUID.

If `activate` throws instead, the dummy site key in `FirebaseAppCheckGateway.activate` is being rejected. Fix by registering a free reCAPTCHA v3 key at <https://www.google.com/recaptcha/admin>, putting it in `MOLO_APP_CHECK_RECAPTCHA_SITE_KEY`, and leaving `MOLO_APP_CHECK_DEBUG` true; the debug global still takes precedence.

- [ ] **Step 4: Safelist the token (manual, console)**

Firebase console, `molobuddy-development`, then App Check, then Apps, then the Web app's overflow menu, then Manage debug tokens, then Add debug token. Paste the UUID and save.

- [ ] **Step 5: Prove the server accepts it**

Switch `src/molobuddy_server/.env.local` to `AUTH_VERIFIER=firebase`, restart the server, then in the running app's browser console confirm no `app_check_required` appears once Task 5 lands. For now assert only that the token exists.

- [ ] **Step 6: Commit**

Only `web/index.html` is tracked; the config file is ignored by design.

```bash
git add src/molobuddy_app/web/index.html
git commit -m "chore: enable App Check debug attestation for local development"
```

---

### Task 2: Session models and failure kinds

**Files:**
- Create: `src/molobuddy_app/lib/core/auth/data/models/molo_session.dart`
- Modify: `src/molobuddy_app/lib/core/auth/data/models/auth_failure.dart`
- Test: `src/molobuddy_app/test/unit/core/auth/molo_session_test.dart`

**Interfaces:**
- Produces: `MoloSession({required String uid, String? displayName, String? emailMasked, String? preferredLocale, required List<PracticeRef> practiceRefs})`; `PracticeRef({required String practiceId, required String displayLabel, required String homeRegionKey, required int routeVersion, required PracticeAccessStatus accessStatus})`; `enum PracticeAccessStatus { active, invited, suspended }`; new `AuthFailureKind.attestationRequired` and `AuthFailureKind.sessionExpired`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/auth/molo_session_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';

void main() {
  test('a session with no practices is not ready for practice work', () {
    const session = MoloSession(uid: 'user_1', practiceRefs: []);

    expect(session.hasPractices, isFalse);
  });

  test('a session exposes only active practices as selectable', () {
    const session = MoloSession(
      uid: 'user_1',
      practiceRefs: [
        PracticeRef(
          practiceId: 'p_1',
          displayLabel: 'Mokoena Media Tax',
          homeRegionKey: 'za1',
          routeVersion: 1,
          accessStatus: PracticeAccessStatus.active,
        ),
        PracticeRef(
          practiceId: 'p_2',
          displayLabel: 'Suspended Practice',
          homeRegionKey: 'za1',
          routeVersion: 1,
          accessStatus: PracticeAccessStatus.suspended,
        ),
      ],
    );

    expect(session.hasPractices, isTrue);
    expect(session.selectablePractices.map((p) => p.practiceId), ['p_1']);
  });
}
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
cd src/molobuddy_app && flutter test test/unit/core/auth/molo_session_test.dart
```

Expected: FAIL, `Error when reading 'lib/core/auth/data/models/molo_session.dart': No such file or directory`.

- [ ] **Step 3: Write the model**

Create `lib/core/auth/data/models/molo_session.dart`:

```dart
enum PracticeAccessStatus { active, invited, suspended }

final class PracticeRef {
  const PracticeRef({
    required this.practiceId,
    required this.displayLabel,
    required this.homeRegionKey,
    required this.routeVersion,
    required this.accessStatus,
  });

  final String practiceId;
  final String displayLabel;
  final String homeRegionKey;
  final int routeVersion;
  final PracticeAccessStatus accessStatus;
}

/// The server's answer to "who is this and what may they reach".
///
/// Authentication does not imply authorisation for a practice, so this is
/// reloaded even when a Firebase session is restored from persistence.
final class MoloSession {
  const MoloSession({
    required this.uid,
    required this.practiceRefs,
    this.displayName,
    this.emailMasked,
    this.preferredLocale,
  });

  final String uid;
  final List<PracticeRef> practiceRefs;
  final String? displayName;
  final String? emailMasked;
  final String? preferredLocale;

  bool get hasPractices => practiceRefs.isNotEmpty;

  Iterable<PracticeRef> get selectablePractices {
    return practiceRefs.where(
      (practice) => practice.accessStatus == PracticeAccessStatus.active,
    );
  }
}
```

- [ ] **Step 4: Add the two failure kinds**

In `lib/core/auth/data/models/auth_failure.dart`, extend the enum. Keep the existing members in place so no switch elsewhere changes meaning:

```dart
enum AuthFailureKind {
  invalidCredentials,
  networkUnavailable,
  providerUnavailable,
  configurationMissing,
  attestationRequired,
  sessionExpired,
  unexpected,
}
```

- [ ] **Step 5: Run the test and watch it pass**

```bash
flutter test test/unit/core/auth/molo_session_test.dart
```

Expected: PASS, 2 tests.

- [ ] **Step 6: Confirm nothing else broke**

```bash
flutter analyze && flutter test
```

Expected: analyzer clean. If a `switch` over `AuthFailureKind` is now non-exhaustive, the analyzer names the file; add the two new kinds to it mapping to the same copy as `unexpected` for now. Task 7 gives them real copy.

- [ ] **Step 7: Commit**

```bash
git add src/molobuddy_app/lib/core/auth/data/models src/molobuddy_app/test/unit/core/auth/molo_session_test.dart
git commit -m "feat: add Molo session models and session failure kinds"
```

---

### Task 3: HTTP session service

**Files:**
- Create: `src/molobuddy_app/lib/core/auth/data/services/session_service.dart`
- Create: `src/molobuddy_app/lib/core/auth/data/services/http_session_service.dart`
- Test: `src/molobuddy_app/test/unit/core/auth/http_session_service_test.dart`

**Interfaces:**
- Consumes: `MoloSession`, `PracticeRef`, `PracticeAccessStatus`, `AuthFailureKind` from Task 2.
- Produces: `abstract interface class SessionService { Future<AuthResult<MoloSession>> loadSession(); }`, `HttpSessionService({required Dio dio, required String baseUrl})`, and `const UnavailableSessionService()`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/auth/http_session_service_test.dart`:

```dart
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/http_session_service.dart';

void main() {
  test('reads the session out of the standard data envelope', () async {
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1","displayName":"Thando Mokoena",
"emailMasked":"t***@example.com"},"practiceRefs":[]},
"meta":{"apiVersion":"v1"}}''');

    final result = await service.loadSession();

    expect(result, isA<AuthSuccess<MoloSession>>());
    final session = (result as AuthSuccess<MoloSession>).value;
    expect(session.uid, 'user_1');
    expect(session.displayName, 'Thando Mokoena');
    expect(session.emailMasked, 't***@example.com');
    expect(session.practiceRefs, isEmpty);
  });

  test('maps a missing attestation to its own failure kind', () async {
    final service = _serviceReturning(403, '{"code":"app_check_required"}');

    final result = await service.loadSession();

    expect(
      (result as AuthError<MoloSession>).failure.kind,
      AuthFailureKind.attestationRequired,
    );
  });

  test('maps an invalid token to an expired session', () async {
    final service = _serviceReturning(401, '{"code":"token_invalid"}');

    final result = await service.loadSession();

    expect(
      (result as AuthError<MoloSession>).failure.kind,
      AuthFailureKind.sessionExpired,
    );
  });

  test('rejects a response that omits the data envelope', () async {
    final service = _serviceReturning(200, '{"user":{"uid":"user_1"}}');

    expect(
      (await service.loadSession() as AuthError<MoloSession>).failure.kind,
      AuthFailureKind.unexpected,
    );
  });
}

HttpSessionService _serviceReturning(int status, String body) {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  dio.httpClientAdapter = _StubAdapter(status, body);
  return HttpSessionService(dio: dio, baseUrl: 'https://api.molo.test');
}

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._status, this._body);

  final int _status;
  final String _body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      _body,
      _status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
flutter test test/unit/core/auth/http_session_service_test.dart
```

Expected: FAIL, `No such file or directory` for `http_session_service.dart`.

- [ ] **Step 3: Write the interface**

Create `lib/core/auth/data/services/session_service.dart`:

```dart
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';

abstract interface class SessionService {
  Future<AuthResult<MoloSession>> loadSession();
}

/// Used when no API base URL is configured, such as preview builds.
final class UnavailableSessionService implements SessionService {
  const UnavailableSessionService();

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
  }
}
```

- [ ] **Step 4: Write the HTTP implementation**

Create `lib/core/auth/data/services/http_session_service.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';

final class HttpSessionService implements SessionService {
  factory HttpSessionService({required Dio dio, required String baseUrl}) {
    return HttpSessionService._(dio, baseUrl.replaceFirst(RegExp(r'/$'), ''));
  }

  HttpSessionService._(this._dio, this._baseUrl);

  final Dio _dio;
  final String _baseUrl;

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    try {
      final response = await _dio.get<Object>(
        '$_baseUrl/v1/session',
        options: Options(
          validateStatus: (_) => true,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final status = response.statusCode ?? 0;
      if (status != 200) {
        return AuthError(AuthFailure(_failureForProblem(response.data)));
      }

      final session = _parseSession(response.data);
      if (session == null) {
        return const AuthError(AuthFailure(AuthFailureKind.unexpected));
      }
      return AuthSuccess(session);
    } on DioException {
      return const AuthError(AuthFailure(AuthFailureKind.networkUnavailable));
    } on FormatException {
      return const AuthError(AuthFailure(AuthFailureKind.unexpected));
    }
  }

  static AuthFailureKind _failureForProblem(Object? body) {
    final code = body is Map<String, dynamic> ? body['code'] : null;
    return switch (code) {
      'app_check_required' => AuthFailureKind.attestationRequired,
      'token_invalid' => AuthFailureKind.sessionExpired,
      'authentication_required' => AuthFailureKind.sessionExpired,
      _ => AuthFailureKind.unexpected,
    };
  }

  static MoloSession? _parseSession(Object? body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final user = data['user'];
    if (user is! Map<String, dynamic>) {
      return null;
    }
    final uid = user['uid'];
    if (uid is! String || uid.isEmpty) {
      return null;
    }

    final refs = data['practiceRefs'];
    return MoloSession(
      uid: uid,
      displayName: _optionalString(user['displayName']),
      emailMasked: _optionalString(user['emailMasked']),
      preferredLocale: _optionalString(user['preferredLocale']),
      practiceRefs: refs is List
          ? refs
                .whereType<Map<String, dynamic>>()
                .map(_parsePractice)
                .nonNulls
                .toList()
          : const [],
    );
  }

  static PracticeRef? _parsePractice(Map<String, dynamic> raw) {
    final practiceId = raw['practiceId'];
    final displayLabel = raw['displayLabel'];
    final homeRegionKey = raw['homeRegionKey'];
    if (practiceId is! String || displayLabel is! String ||
        homeRegionKey is! String) {
      return null;
    }
    return PracticeRef(
      practiceId: practiceId,
      displayLabel: displayLabel,
      homeRegionKey: homeRegionKey,
      routeVersion: raw['routeVersion'] is int ? raw['routeVersion'] as int : 1,
      accessStatus: switch (raw['accessStatus']) {
        'active' => PracticeAccessStatus.active,
        'invited' => PracticeAccessStatus.invited,
        _ => PracticeAccessStatus.suspended,
      },
    );
  }

  static String? _optionalString(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }
}
```

- [ ] **Step 5: Run the test and watch it pass**

```bash
flutter test test/unit/core/auth/http_session_service_test.dart
```

Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add src/molobuddy_app/lib/core/auth/data/services src/molobuddy_app/test/unit/core/auth/http_session_service_test.dart
git commit -m "feat: read the Molo session from the control API"
```

---

### Task 4: Authenticated Dio provider

**Files:**
- Create: `src/molobuddy_app/lib/core/network/network_providers.dart`
- Test: `src/molobuddy_app/test/unit/core/network/network_providers_test.dart`

**Interfaces:**
- Consumes: `MoloAuthenticatedTransport`, `authTokenBrokerProvider`, `appCheckGatewayProvider`.
- Produces: `authenticatedDioProvider`, a `Provider<Dio>` whose interceptors include `MoloAuthenticatedTransport`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/network/network_providers_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_gateway.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_token_broker.dart';
import 'package:molobuddy_app/core/network/authenticated_transport.dart';
import 'package:molobuddy_app/core/network/network_providers.dart';

void main() {
  test('the shared client carries the authenticated transport', () {
    final container = ProviderContainer(
      overrides: [
        authTokenBrokerProvider.overrideWithValue(
          const UnavailableAuthTokenBroker(),
        ),
        appCheckGatewayProvider.overrideWithValue(
          const UnavailableAppCheckGateway(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final dio = container.read(authenticatedDioProvider);

    expect(
      dio.interceptors.whereType<MoloAuthenticatedTransport>(),
      hasLength(1),
    );
  });
}
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
flutter test test/unit/core/network/network_providers_test.dart
```

Expected: FAIL, `No such file or directory` for `network_providers.dart`.

- [ ] **Step 3: Write the provider**

Create `lib/core/network/network_providers.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/network/authenticated_transport.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_providers.g.dart';

/// The one HTTP client that carries Molo's identity and attestation tokens.
///
/// Anything calling an authenticated Molo endpoint uses this, so tokens are
/// attached in exactly one place.
@Riverpod(keepAlive: true)
Dio authenticatedDio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      headers: const {'accept': 'application/json'},
      connectTimeout: const Duration(seconds: 5),
    ),
  );
  dio.interceptors.add(
    MoloAuthenticatedTransport(
      tokenBroker: ref.watch(authTokenBrokerProvider),
      appCheckGateway: ref.watch(appCheckGatewayProvider),
    ),
  );
  return dio;
}
```

- [ ] **Step 4: Generate the provider code**

```bash
cd src/molobuddy_app && dart run build_runner build --delete-conflicting-outputs
```

Expected: writes `lib/core/network/network_providers.g.dart`.

- [ ] **Step 5: Run the test and watch it pass**

```bash
flutter test test/unit/core/network/network_providers_test.dart
```

Expected: PASS, 1 test.

- [ ] **Step 6: Commit**

```bash
git add src/molobuddy_app/lib/core/network src/molobuddy_app/test/unit/core/network/network_providers_test.dart
git commit -m "feat: share one authenticated HTTP client"
```

---

### Task 5: Repository loads the session

**Files:**
- Modify: `src/molobuddy_app/lib/core/auth/data/repositories/auth_repository.dart`
- Modify: `src/molobuddy_app/lib/core/auth/data/repositories/default_auth_repository.dart`
- Modify: `src/molobuddy_app/lib/core/auth/auth_providers.dart`
- Test: `src/molobuddy_app/test/unit/core/auth/default_auth_repository_session_test.dart`

**Interfaces:**
- Consumes: `SessionService` from Task 3.
- Produces: `Future<AuthResult<MoloSession>> loadSession()` on `AuthRepository`; `sessionServiceProvider`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/auth/default_auth_repository_session_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/repositories/default_auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';

void main() {
  test('the repository passes the session straight through', () async {
    final repository = DefaultAuthRepository(
      _StubAuthService(),
      const BundledPreviewAuthProviderCatalogueService(),
      _StubSessionService(),
    );

    final result = await repository.loadSession();

    expect((result as AuthSuccess<MoloSession>).value.uid, 'user_1');
  });
}

final class _StubSessionService implements SessionService {
  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    return const AuthSuccess(MoloSession(uid: 'user_1', practiceRefs: []));
  }
}

final class _StubAuthService implements AuthService {
  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => const AuthError(AuthFailure(AuthFailureKind.unexpected));

  @override
  Future<AuthResult<void>> signOut() async => const AuthSuccess(null);
}
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
flutter test test/unit/core/auth/default_auth_repository_session_test.dart
```

Expected: FAIL, `DefaultAuthRepository` does not take a third argument.

- [ ] **Step 3: Extend the interface**

In `lib/core/auth/data/repositories/auth_repository.dart`, add the import for `molo_session.dart` and this member to `AuthRepository`:

```dart
  /// Reloads Molo's own session. Authentication does not imply authorisation,
  /// so this runs even when Firebase restored the user from persistence.
  Future<AuthResult<MoloSession>> loadSession();
```

- [ ] **Step 4: Implement it**

In `lib/core/auth/data/repositories/default_auth_repository.dart`, accept the service as a third constructor parameter, store it, and add:

```dart
  @override
  Future<AuthResult<MoloSession>> loadSession() => _sessionService.loadSession();
```

- [ ] **Step 5: Add the provider and update the repository wiring**

In `lib/core/auth/auth_providers.dart` add:

```dart
@Riverpod(keepAlive: true)
SessionService sessionService(Ref ref) {
  throw StateError('SessionService must be provided during bootstrap.');
}
```

and extend `authRepository` to pass `ref.watch(sessionServiceProvider)` as the third argument.

- [ ] **Step 6: Regenerate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/core/auth/default_auth_repository_session_test.dart
```

Expected: PASS, 1 test.

- [ ] **Step 7: Construct the real service in bootstrap**

In `lib/bootstrap/app_bootstrap.dart`, build the session service from the authenticated Dio and add `sessionServiceProvider.overrideWithValue(...)` to the `ProviderScope` overrides. Where `environment.apiBaseUrl` is null, use `const UnavailableSessionService()`.

Because the Dio lives in a provider, read it from a `ProviderContainer` created before `runApp`, or move construction into the `authRepository` provider. Prefer the latter: it keeps bootstrap free of container juggling.

- [ ] **Step 8: Full check and commit**

```bash
flutter analyze && flutter test && dart format --set-exit-if-changed lib test
git add src/molobuddy_app/lib src/molobuddy_app/test
git commit -m "feat: load the Molo session through the auth repository"
```

---

### Task 6: View model carries the loading state

**Files:**
- Modify: `src/molobuddy_app/lib/core/auth/ui/view_models/auth_view_state.dart`
- Modify: `src/molobuddy_app/lib/core/auth/ui/view_models/auth_view_model.dart`
- Test: `src/molobuddy_app/test/unit/core/auth/auth_view_model_session_test.dart`

**Interfaces:**
- Consumes: `AuthRepository.loadSession`, `MoloSession`.
- Produces: `AuthViewStatus.loadingSession`; `AuthViewState.session`; the view model loads a session after a successful sign-in.

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/auth/auth_view_model_session_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/repositories/auth_repository.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';

void main() {
  test('a successful sign-in loads the session before becoming ready', () async {
    final repository = _FakeSessionRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authViewModelProvider.future);

    final seen = <AuthViewStatus>[];
    container.listen(authViewModelProvider, (previous, next) {
      final value = next.value;
      if (value != null) {
        seen.add(value.status);
      }
    });

    await container
        .read(authViewModelProvider.notifier)
        .signInWithEmailAndPassword(
          email: 'person@example.com',
          password: 'safe-password',
        );

    final state = container.read(authViewModelProvider).requireValue;
    expect(seen, contains(AuthViewStatus.loadingSession));
    expect(state.status, AuthViewStatus.signedIn);
    expect(state.session?.uid, 'user_1');
    expect(repository.loadSessionCalls, 1);
  });

  test('an attestation failure surfaces without signing the user out', () async {
    final repository = _FakeSessionRepository(
      sessionResult: const AuthError(
        AuthFailure(AuthFailureKind.attestationRequired),
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authViewModelProvider.future);

    await container
        .read(authViewModelProvider.notifier)
        .signInWithEmailAndPassword(
          email: 'person@example.com',
          password: 'safe-password',
        );

    final state = container.read(authViewModelProvider).requireValue;
    expect(state.status, AuthViewStatus.signedIn);
    expect(state.session, isNull);
    expect(state.failure?.kind, AuthFailureKind.attestationRequired);
  });
}

final class _FakeSessionRepository implements AuthRepository {
  _FakeSessionRepository({
    this.sessionResult = const AuthSuccess(
      MoloSession(uid: 'user_1', practiceRefs: []),
    ),
  });

  final AuthResult<MoloSession> sessionResult;
  int loadSessionCalls = 0;
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthResult<List<AuthMethodDescriptor>>> loadMethods() async {
    return const AuthSuccess(<AuthMethodDescriptor>[]);
  }

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = AuthUser(id: 'user_1', email: email);
    return AuthSuccess(_currentUser!);
  }

  @override
  Future<AuthResult<void>> signOut() async {
    _currentUser = null;
    return const AuthSuccess(null);
  }

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    loadSessionCalls += 1;
    return sessionResult;
  }
}
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
flutter test test/unit/core/auth/auth_view_model_session_test.dart
```

Expected: FAIL, `loadingSession` is not defined on `AuthViewStatus`.

- [ ] **Step 3: Extend the state**

In `auth_view_state.dart` add `loadingSession` to `AuthViewStatus` after `authenticating`, add `final MoloSession? session;` to `AuthViewState`, thread it through the constructor and `copyWith`, and add a `bool clearSession = false` flag to `copyWith` mirroring `clearUser`.

- [ ] **Step 4: Load the session after sign-in**

In `auth_view_model.dart`, after the `AuthSuccess` branch of `signInWithEmailAndPassword`, set status to `AuthViewStatus.loadingSession`, await `loadSession()`, then settle to `signedIn` with the session on success or with the failure on error. Clear the session in `signOut`.

- [ ] **Step 5: Run the test and watch it pass**

```bash
flutter test test/unit/core/auth/auth_view_model_session_test.dart
```

Expected: PASS, 2 tests.

- [ ] **Step 6: Commit**

```bash
flutter analyze && flutter test
git add src/molobuddy_app/lib/core/auth/ui/view_models src/molobuddy_app/test/unit/core/auth/auth_view_model_session_test.dart
git commit -m "feat: carry the session load through the auth state machine"
```

---

### Task 7: Welcome view renders the real session

**Files:**
- Modify: `src/molobuddy_app/lib/core/auth/ui/views/welcome/welcome_view.dart`
- Modify: `src/molobuddy_app/lib/app/localisation/l10n/app_en.arb`
- Modify: `src/molobuddy_app/lib/app/localisation/l10n/app_en_ZA.arb`
- Test: `src/molobuddy_app/test/widget/core/auth/welcome_session_test.dart`

**Interfaces:**
- Consumes: `AuthViewState.session`, `AuthViewStatus.loadingSession`, the two new failure kinds.

- [ ] **Step 1: Add the copy**

Add to both ARB files, sentence case and no em dashes:

```json
"sessionLoading": "Checking what you can reach.",
"sessionAttestationRequired": "This device could not be verified. Reload to try again.",
"sessionExpired": "Your session ended. Sign in again to continue.",
"sessionNoPractices": "You are signed in. No practice has been connected to this account yet."
```

Add `@` description entries beside each, matching the file's existing style.

- [ ] **Step 2: Write the failing widget test**

Create `test/widget/core/auth/welcome_session_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
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
}

Future<void> _pumpWelcome(WidgetTester tester, AuthViewState state) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => _StubAuthViewModel(state)),
      ],
      child: MaterialApp(
        theme: MoloTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WelcomeView(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _StubAuthViewModel extends AuthViewModel {
  _StubAuthViewModel(this._state);

  final AuthViewState _state;

  @override
  Future<AuthViewState> build() async => _state;
}
```

If `AuthViewModel` cannot be subclassed this way under the generated Riverpod
code, override `authRepositoryProvider` with a fake returning the same values
instead, following `auth_view_model_test.dart`. Do not weaken the assertions.

- [ ] **Step 3: Run the test and watch it fail**

```bash
flutter test test/widget/core/auth/welcome_session_test.dart
```

Expected: FAIL, the strings are not found.

- [ ] **Step 4: Render the states**

In `welcome_view.dart`, replace the hardcoded email echo with the session. Show a progress indicator plus `sessionLoading` while `status == AuthViewStatus.loadingSession`; show `sessionNoPractices` when the session has no practices; show the mapped failure copy when `failure` is set. Keep the existing `Key('welcome_view')` and `Key('sign_out_button')` so current tests keep passing. Status must not rely on colour alone, so pair each state with an icon and text.

- [ ] **Step 5: Run the tests and watch them pass**

```bash
flutter test test/widget/core/auth/welcome_session_test.dart && flutter test
```

Expected: the new file passes and the whole suite stays green.

- [ ] **Step 6: Check both breakpoints**

Run the widget test at 390x844 and 1280x900 using the `_setViewport` helper already in the auth widget tests. Confirm no overflow.

- [ ] **Step 7: Commit**

```bash
flutter analyze && dart format --set-exit-if-changed lib test
git add src/molobuddy_app/lib src/molobuddy_app/test
git commit -m "feat: show the real Molo session on the welcome screen"
```

---

### Task 8: End-to-end verification and documentation

**Files:**
- Modify: `docs/backend_design/authentication.md`
- Modify: `docs/local_development.md`
- Modify: `src/molobuddy_server/.env.local` (gitignored)

- [ ] **Step 1: Run the server with the real verifier**

```bash
cd src/molobuddy_server && sed -i '' 's/^AUTH_VERIFIER=.*/AUTH_VERIFIER=firebase/' .env.local && npm run dev
```

Expected: the server starts and `curl -s localhost:8080/health` returns `{"status":"ok",...}`.

- [ ] **Step 2: Sign in and observe a real session**

Run the app with `--dart-define-from-file=config/firebase.development.json`, sign in with a real account, and confirm the welcome screen shows the masked email the server returned, not the address typed into the form. A masked value proves the data came from `/v1/session`.

- [ ] **Step 3: Prove attestation is actually required**

Remove the debug token from the Firebase console safelist, reload, and confirm the app shows the attestation copy rather than a crash or a raw error. Re-add the token afterwards.

- [ ] **Step 4: Full verification**

```bash
cd src/molobuddy_app && flutter analyze && flutter test && dart format --set-exit-if-changed lib test
cd ../molobuddy_server && npm run check
```

Expected: all green.

- [ ] **Step 5: Update the docs**

In `docs/backend_design/authentication.md` section 17, move App Check and the token broker to implemented, and replace the "one consequence is worth stating plainly" paragraph, which no longer applies once attestation works. In `docs/local_development.md`, change the "Until attestation is configured" section to record that `AUTH_VERIFIER=firebase` is now the working local default, and state the new default in the verifier list.

- [ ] **Step 6: Commit**

```bash
git add docs
git commit -m "docs: record the closed auth loop"
```

---

## Out of Scope

Named so nobody expands this plan midway:

- Practice provisioning, Firestore membership records and region routing. `practiceRefs` stays empty until a separate plan builds it.
- Real account creation in the registration flow. It remains a preview.
- reCAPTCHA Enterprise and App Check enforcement. Enforcement stays `UNENFORCED` until monitoring shows legitimate traffic passing.
- Federation adapters, MFA and account linking.
- The outstanding UI debt: the completion screen copy contradiction, the four overlapping progress indicators and the brand panel.
