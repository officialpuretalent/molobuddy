# Founding Onboarding — Client Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Registration creates a real Firebase account, saves every answer to the server as it is given, resumes from server state on any device, and finishes by founding the practice and landing in the workspace.

**Architecture:** Account creation joins the existing `AuthService` contract, so no feature touches a vendor SDK. Onboarding becomes its own client feature under `lib/core/onboarding/`, reached through the one authenticated Dio that already attaches identity and attestation tokens. The wizard splits along the route boundary the spec draws: `/sign-up` owns the account step, `/onboarding` owns the rest and is where a resuming user lands.

**Tech Stack:** Flutter 3.44, Dart 3.12, Riverpod 3.3 with `riverpod_annotation` codegen, go_router 17.5, Dio 5.11, `firebase_auth` 6.5.

**Spec:** [`docs/plans/2026-08-20-founding-onboarding-design.md`](2026-08-20-founding-onboarding-design.md). This plan implements its sections 4.1 and 8. **It depends on the server slice** ([`2026-08-20-founding-onboarding-server.md`](2026-08-20-founding-onboarding-server.md)) being merged: every endpoint here must already exist.

## Global Constraints

- No feature imports a Firebase SDK outside `lib/core/auth/data/` and `lib/bootstrap/`. `test/unit/architecture/vendor_containment_test.dart` enforces it; run it after every task.
- Raw ID tokens and App Check tokens never leave `MoloAuthenticatedTransport`. Nothing in this plan reads a token.
- Every user-visible string is a localisation key, added to **both** `app_en.arb` and `app_en_ZA.arb`. The two files must keep identical key sets. Apostrophes are doubled: `use-escaping: true`.
- After adding or changing a provider, run `dart run build_runner build --delete-conflicting-outputs`. After changing an `.arb`, run `flutter gen-l10n`.
- Deprecation diagnostics are CI failures. `flutter analyze` must report **No issues found**.
- Preview mode must complete the entire flow with no backend. It is a supported way to demonstrate the product.
- Verification gates, green before each commit: `flutter analyze && flutter test` in `src/molobuddy_app`.

---

## The one thing this plan cannot verify itself

**Claude cannot create accounts.** Task 7's end-to-end run — register a genuinely new address, close the tab mid-wizard, sign back in, finish, land in the workspace — has to be driven by a person. Everything else is covered by unit and widget tests, and by preview mode, which exercises the same view models against in-memory services.

Plan accordingly: Tasks 1 to 6 and 8 are autonomous. Task 7 is a handoff.

---

## The enumeration-protection question, handled rather than blocked

Spec section 4.1 leaves open whether Firebase still returns `email-already-in-use` on sign-up when improved email-enumeration protection is enabled. The answer changes only which copy a user sees, so **Task 1 implements both branches** and nothing waits on it:

- a recognised `email-already-in-use` maps to `emailAlreadyRegistered` and the message points at the email field;
- anything unrecognised falls through to the neutral copy already used for an unexpected failure.

Task 1 also includes a probe to settle it. The probe is written so it cannot create an account: it signs up with an address **known to already exist**, so the call can only fail. Run it with an address you have just confirmed exists, or skip it and keep the neutral copy — the code is correct either way.

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/core/auth/data/models/auth_failure.dart` (modify) | Two new failure kinds |
| `lib/core/auth/data/services/auth_service.dart` (modify) | `createAccount` on the contract |
| `lib/core/auth/data/services/firebase_auth_service.dart` (modify) | Create, name, reload |
| `lib/core/auth/data/services/preview_auth_service.dart` (modify) | The same, in memory |
| `lib/core/auth/data/repositories/auth_repository.dart` (modify) | `createAccount` |
| `lib/core/auth/data/repositories/default_auth_repository.dart` (modify) | Delegate it |
| `lib/core/auth/data/models/molo_session.dart` (modify) | `onboardingComplete` on the session |
| `lib/core/auth/data/services/http_session_service.dart` (modify) | Parse it |
| `lib/core/auth/data/services/preview_session_service.dart` (modify) | Answer it |
| `lib/core/onboarding/data/models/onboarding_answers.dart` (create) | Answers and their enumerations |
| `lib/core/onboarding/data/models/onboarding_snapshot.dart` (create) | Status, next step, answers, version |
| `lib/core/onboarding/data/models/onboarding_failure.dart` (create) | What can go wrong, in Molo words |
| `lib/core/onboarding/data/services/onboarding_service.dart` (create) | The contract |
| `lib/core/onboarding/data/services/http_onboarding_service.dart` (create) | The three endpoints |
| `lib/core/onboarding/data/services/preview_onboarding_service.dart` (create) | In-memory equivalent |
| `lib/core/onboarding/onboarding_providers.dart` (create) | Wiring |
| `lib/core/onboarding/ui/view_models/onboarding_view_model.dart` (create) | The async state machine |
| `lib/core/onboarding/ui/views/onboarding_view.dart` (create) | Practice, priorities, starting point, complete |
| `lib/core/auth/ui/views/registration/registration_view.dart` (modify) | Account step only |
| `lib/core/auth/ui/views/registration/wizard_shell.dart` (create) | The shell both routes share |
| `lib/app/router/app_router.dart` (modify) | `/onboarding` and the gate |

---

### Task 1: Account creation in the auth contract

**Files:**
- Modify: `lib/core/auth/data/models/auth_failure.dart`
- Modify: `lib/core/auth/data/services/auth_service.dart`
- Modify: `lib/core/auth/data/services/firebase_auth_service.dart`
- Modify: `lib/core/auth/data/services/preview_auth_service.dart`
- Modify: `lib/core/auth/data/repositories/auth_repository.dart`
- Modify: `lib/core/auth/data/repositories/default_auth_repository.dart`
- Test: `test/unit/core/auth/preview_auth_service_test.dart` (create)
- Test: `test/unit/core/auth/auth_repository_test.dart` (modify)

**Interfaces:**
- Produces: `AuthFailureKind.emailAlreadyRegistered`, `AuthFailureKind.passwordRejected`; `AuthService.createAccount({email, password, displayName})` and the same on `AuthRepository`, both returning `Future<AuthResult<AuthUser>>`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/auth/preview_auth_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';

void main() {
  test('creating an account signs that person in under their own name', () async {
    final service = PreviewAuthService.forTesting(debugAllowed: true);

    final result = await service.createAccount(
      email: '  Thando.Mokoena@Example.com ',
      password: 'safe-preview-password',
      displayName: '  Thando Mokoena  ',
    );

    expect(result, isA<AuthSuccess<AuthUser>>());
    final user = (result as AuthSuccess<AuthUser>).value;
    expect(user.email, 'thando.mokoena@example.com');
    expect(user.displayName, 'Thando Mokoena');
    expect(service.currentUser, user);
  });

  test('refuses the same address twice', () async {
    final service = PreviewAuthService.forTesting(debugAllowed: true);
    await service.createAccount(
      email: 'thando@example.com',
      password: 'safe-preview-password',
      displayName: 'Thando Mokoena',
    );
    await service.signOut();

    final again = await service.createAccount(
      email: 'thando@example.com',
      password: 'safe-preview-password',
      displayName: 'Thando Mokoena',
    );

    expect(
      (again as AuthError<AuthUser>).failure.kind,
      AuthFailureKind.emailAlreadyRegistered,
    );
  });

  test('refuses a password the real provider would refuse', () async {
    final service = PreviewAuthService.forTesting(debugAllowed: true);

    final result = await service.createAccount(
      email: 'thando@example.com',
      password: 'short',
      displayName: 'Thando Mokoena',
    );

    expect(
      (result as AuthError<AuthUser>).failure.kind,
      AuthFailureKind.passwordRejected,
    );
  });

  test('refuses to create anything in a release build', () async {
    final service = PreviewAuthService.forTesting(debugAllowed: false);

    final result = await service.createAccount(
      email: 'thando@example.com',
      password: 'safe-preview-password',
      displayName: 'Thando Mokoena',
    );

    expect(
      (result as AuthError<AuthUser>).failure.kind,
      AuthFailureKind.configurationMissing,
    );
  });
}
```

Add to `test/unit/core/auth/auth_repository_test.dart` a case asserting `DefaultAuthRepository.createAccount` delegates to the service with the values it was given, following whatever fake that file already defines.

- [ ] **Step 2: Run the tests and watch them fail**

```bash
cd src/molobuddy_app && flutter test test/unit/core/auth/preview_auth_service_test.dart
```

Expected: FAIL. `createAccount` is not defined for `PreviewAuthService`.

- [ ] **Step 3: Add the failure kinds**

In `auth_failure.dart`, add to `AuthFailureKind`:

```dart
  /// The address already has an account. Only reported when the provider says
  /// so; enumeration protection may answer generically instead, which falls
  /// through to [unexpected] and neutral copy.
  emailAlreadyRegistered,

  /// The provider refused the password. Molo's own minimum is checked before
  /// this, so reaching it means the provider asked for more.
  passwordRejected,
```

- [ ] **Step 4: Add it to the contract**

In `auth_service.dart`:

```dart
  /// Creates an account and signs that person in.
  ///
  /// [displayName] is set on the created user rather than left for later. The
  /// welcome screen greets by name and deliberately refuses to fall back to an
  /// email address, so an account created without one is greeted anonymously
  /// forever.
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  });
```

Add the same to `AuthRepository`, and delegate in `DefaultAuthRepository`:

```dart
  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _authService.createAccount(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
```

- [ ] **Step 5: Implement it against Firebase**

In `firebase_auth_service.dart`:

```dart
  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final created = credential.user;
      if (created == null) {
        return const AuthError(AuthFailure(AuthFailureKind.unexpected));
      }

      // Set the name before anyone reads it, and reload so currentUser carries
      // it. Without the reload the first greeting after signup has no name,
      // and the app looks like it forgot what the user just typed.
      await created.updateDisplayName(displayName.trim());
      await created.reload();

      final user = _mapUser(_auth.currentUser) ?? _mapUser(created);
      if (user == null) {
        return const AuthError(AuthFailure(AuthFailureKind.unexpected));
      }
      return AuthSuccess(user);
    } on firebase.FirebaseAuthException catch (error) {
      return AuthError(AuthFailure(_mapSignUpFailure(error.code)));
    } on FirebaseException {
      return const AuthError(AuthFailure(AuthFailureKind.providerUnavailable));
    }
  }
```

and the mapping, kept separate from `_mapFailure` because sign-up and sign-in
answer differently to the same situation:

```dart
  static AuthFailureKind _mapSignUpFailure(String code) {
    return switch (code) {
      'email-already-in-use' => AuthFailureKind.emailAlreadyRegistered,
      'weak-password' => AuthFailureKind.passwordRejected,
      'invalid-email' => AuthFailureKind.invalidCredentials,
      'network-request-failed' => AuthFailureKind.networkUnavailable,
      'operation-not-allowed' ||
      'too-many-requests' => AuthFailureKind.providerUnavailable,
      // Email-enumeration protection may answer a taken address generically.
      // Neutral copy is correct then; guessing would tell the user something
      // the provider deliberately declined to.
      _ => AuthFailureKind.unexpected,
    };
  }
```

- [ ] **Step 6: Implement it in preview**

In `preview_auth_service.dart`, add a `_registered` map of lowercased email to `AuthUser`, and:

```dart
  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!_debugAllowed) {
      return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
    }

    await Future<void>.delayed(delay);
    final normalisedEmail = email.trim().toLowerCase();
    if (!_looksLikeEmail(normalisedEmail)) {
      return const AuthError(AuthFailure(AuthFailureKind.invalidCredentials));
    }
    if (password.length < 8) {
      return const AuthError(AuthFailure(AuthFailureKind.passwordRejected));
    }
    if (_registered.containsKey(normalisedEmail)) {
      return const AuthError(
        AuthFailure(AuthFailureKind.emailAlreadyRegistered),
      );
    }

    final trimmedName = displayName.trim();
    final user = AuthUser(
      id: 'preview-${normalisedEmail.hashCode.abs()}',
      email: normalisedEmail,
      displayName: trimmedName.isEmpty ? null : trimmedName,
    );
    _registered[normalisedEmail] = user;
    _currentUser = user;
    return AuthSuccess(user);
  }
```

- [ ] **Step 7: Run the tests and watch them pass**

```bash
flutter analyze && flutter test
```

Expected: PASS, 4 new tests plus the repository delegation case.

- [ ] **Step 8: Settle the enumeration question**

Optional, and it changes no code. Run it with an address you have **just confirmed already exists** in `molobuddy-development`, so the call can only fail:

```bash
curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$(python3 -c "import json;print(json.load(open('config/firebase.development.json'))['MOLO_FIREBASE_API_KEY'])")" -H 'content-type: application/json' -d '{"email":"<an-address-you-know-exists>","password":"not-a-real-password","returnSecureToken":true}'
```

If the response carries `EMAIL_EXISTS`, the provider does reveal it and Task 6 can point the message at the email field. Anything else means neutral copy stays. Record which you saw in the task report and in the spec's section 4.1.

**Do not run this with an address you have not confirmed exists** — that would create an account, which is the one thing this plan must not do casually.

- [ ] **Step 9: Commit**

```bash
git add src/molobuddy_app/lib src/molobuddy_app/test
git commit -m "feat: create accounts through the Molo auth contract"
```

---

### Task 2: The session carries the onboarding gate

**Files:**
- Modify: `lib/core/auth/data/models/molo_session.dart`
- Modify: `lib/core/auth/data/services/http_session_service.dart`
- Modify: `lib/core/auth/data/services/preview_session_service.dart`
- Test: `test/unit/core/auth/http_session_service_test.dart`
- Test: `test/unit/core/auth/preview_session_service_test.dart`
- Test: `test/unit/core/auth/molo_session_test.dart`

**Interfaces:**
- Produces: `MoloSession.onboardingComplete` (a `bool`).

- [ ] **Step 1: Write the failing test**

Add to `test/unit/core/auth/http_session_service_test.dart`:

```dart
  test('reads whether onboarding is still outstanding', () async {
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1"},"practiceRefs":[],
"onboarding":{"status":"in_progress"}}}''');

    final session =
        (await service.loadSession() as AuthSuccess<MoloSession>).value;

    expect(session.onboardingComplete, isFalse);
  });

  test('reads a finished onboarding', () async {
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1"},"practiceRefs":[],
"onboarding":{"status":"complete"}}}''');

    final session =
        (await service.loadSession() as AuthSuccess<MoloSession>).value;

    expect(session.onboardingComplete, isTrue);
  });

  test('treats an absent onboarding block as finished', () async {
    // A server that has not shipped the gate yet must not trap every user in
    // a wizard. Absence means "nothing outstanding", which is the safe reading
    // for a field that only ever adds a redirect.
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1"},"practiceRefs":[]}}''');

    final session =
        (await service.loadSession() as AuthSuccess<MoloSession>).value;

    expect(session.onboardingComplete, isTrue);
  });
```

Add to `test/unit/core/auth/preview_session_service_test.dart` a case asserting a preview session reports `onboardingComplete` as false until a preview practice exists, and true afterwards. Mirror whatever construction that file already uses.

- [ ] **Step 2: Run the tests and watch them fail**

```bash
flutter test test/unit/core/auth
```

Expected: FAIL. `onboardingComplete` is not defined for `MoloSession`.

- [ ] **Step 3: Add the field**

In `molo_session.dart`, add a required-with-default parameter and field:

```dart
    this.onboardingComplete = true,
```

```dart
  /// Whether the server considers this account finished setting up.
  ///
  /// Defaults to true so an older server, or any response without the block,
  /// never traps a user in a wizard. The field only ever adds a redirect, so
  /// the safe default is the one that adds none.
  final bool onboardingComplete;
```

- [ ] **Step 4: Parse it**

In `http_session_service.dart`, inside `_parseSession`, before building the session:

```dart
    final onboarding = data['onboarding'];
    final onboardingComplete =
        onboarding is! Map<String, dynamic> ||
        onboarding['status'] != 'in_progress';
```

and pass `onboardingComplete: onboardingComplete`.

Reading it as "anything that is not `in_progress` is complete" rather than
"`complete` means complete" keeps an unknown future status from locking a user
into the wizard.

- [ ] **Step 5: Answer it in preview**

In `preview_session_service.dart`, report the gate from whether preview has a
practice yet. Preview's practice list is empty today, so pass
`onboardingComplete: false` when it is empty and `true` once
`PreviewOnboardingService` has founded one. Task 3 introduces that service;
until then this reads from the same empty list and is therefore false.

Add a comment saying preview mirrors the server's rule from spec section 3.3:
having a practice settles it.

- [ ] **Step 6: Run the tests and watch them pass**

```bash
flutter analyze && flutter test
```

- [ ] **Step 7: Commit**

```bash
git add src/molobuddy_app/lib src/molobuddy_app/test
git commit -m "feat: carry the onboarding gate on the Molo session"
```

---

### Task 3: The onboarding client

Models, the service contract, its HTTP and preview implementations, and the providers.

**Files:**
- Create: `lib/core/onboarding/data/models/onboarding_answers.dart`
- Create: `lib/core/onboarding/data/models/onboarding_snapshot.dart`
- Create: `lib/core/onboarding/data/models/onboarding_failure.dart`
- Create: `lib/core/onboarding/data/services/onboarding_service.dart`
- Create: `lib/core/onboarding/data/services/http_onboarding_service.dart`
- Create: `lib/core/onboarding/data/services/preview_onboarding_service.dart`
- Create: `lib/core/onboarding/onboarding_providers.dart`
- Test: `test/unit/core/onboarding/http_onboarding_service_test.dart`
- Test: `test/unit/core/onboarding/preview_onboarding_service_test.dart`

**Interfaces:**
- Produces: `OnboardingAnswers`, `PracticeSize`, `OnboardingPriority`, `WorkspaceStartingPoint`, `OnboardingStep`, `OnboardingSnapshot`, `OnboardingFailure`, `OnboardingResult<T>`, `OnboardingService` with `load()`, `save(answers, expectedVersion)` and `complete(idempotencyKey)`, `HttpOnboardingService`, `PreviewOnboardingService`, `onboardingServiceProvider`.

- [ ] **Step 1: Write the models**

Create `data/models/onboarding_answers.dart`. The three enumerations move here from `registration_view_model.dart`, because they are now part of a wire contract rather than local wizard state.

**Between this task and Task 6 there are deliberately two declarations of `PracticeSize` and `WorkspaceStartingPoint`**, one in each file. Dart allows that as long as no single file imports both, and nothing does until Task 6 deletes the originals. If you hit an ambiguous-import error before then, the file causing it should be importing the new models, not the old view model.

```dart
enum PracticeSize { solo, smallTeam, growingTeam }

enum OnboardingPriority { deadlines, documents, teamwork, visibility }

enum WorkspaceStartingPoint { importClients, addFirstClient, sampleWorkspace }

/// Where a returning user picks up, as the server derived it.
///
/// Sent by the server on every read; never stored by the client. The client
/// does not compute this: two implementations of one rule is how a resumed
/// wizard opens on a question the user already answered.
enum OnboardingStep { practice, priorities, startingPoint, readyToComplete }

final class OnboardingAnswers {
  const OnboardingAnswers({
    this.practiceName,
    this.practiceSize,
    this.priorities = const {},
    this.startingPoint,
  });

  final String? practiceName;
  final PracticeSize? practiceSize;
  final Set<OnboardingPriority> priorities;
  final WorkspaceStartingPoint? startingPoint;

  OnboardingAnswers copyWith({
    String? practiceName,
    PracticeSize? practiceSize,
    Set<OnboardingPriority>? priorities,
    WorkspaceStartingPoint? startingPoint,
  }) {
    return OnboardingAnswers(
      practiceName: practiceName ?? this.practiceName,
      practiceSize: practiceSize ?? this.practiceSize,
      priorities: priorities ?? this.priorities,
      startingPoint: startingPoint ?? this.startingPoint,
    );
  }
}

String practiceSizeWireValue(PracticeSize value) => switch (value) {
  PracticeSize.solo => 'solo',
  PracticeSize.smallTeam => 'small_team',
  PracticeSize.growingTeam => 'growing_team',
};

PracticeSize? practiceSizeFromWire(Object? value) => switch (value) {
  'solo' => PracticeSize.solo,
  'small_team' => PracticeSize.smallTeam,
  'growing_team' => PracticeSize.growingTeam,
  _ => null,
};

String priorityWireValue(OnboardingPriority value) => switch (value) {
  OnboardingPriority.deadlines => 'deadlines',
  OnboardingPriority.documents => 'documents',
  OnboardingPriority.teamwork => 'teamwork',
  OnboardingPriority.visibility => 'visibility',
};

OnboardingPriority? priorityFromWire(Object? value) => switch (value) {
  'deadlines' => OnboardingPriority.deadlines,
  'documents' => OnboardingPriority.documents,
  'teamwork' => OnboardingPriority.teamwork,
  'visibility' => OnboardingPriority.visibility,
  _ => null,
};

String startingPointWireValue(WorkspaceStartingPoint value) => switch (value) {
  WorkspaceStartingPoint.importClients => 'import_clients',
  WorkspaceStartingPoint.addFirstClient => 'add_first_client',
  WorkspaceStartingPoint.sampleWorkspace => 'sample_workspace',
};

WorkspaceStartingPoint? startingPointFromWire(Object? value) => switch (value) {
  'import_clients' => WorkspaceStartingPoint.importClients,
  'add_first_client' => WorkspaceStartingPoint.addFirstClient,
  'sample_workspace' => WorkspaceStartingPoint.sampleWorkspace,
  _ => null,
};

OnboardingStep? onboardingStepFromWire(Object? value) => switch (value) {
  'practice' => OnboardingStep.practice,
  'priorities' => OnboardingStep.priorities,
  'starting_point' => OnboardingStep.startingPoint,
  'ready_to_complete' => OnboardingStep.readyToComplete,
  _ => null,
};
```

Create `data/models/onboarding_snapshot.dart`:

```dart
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';

final class OnboardingSnapshot {
  const OnboardingSnapshot({
    required this.complete,
    required this.answers,
    this.nextStep,
    this.version,
  });

  final bool complete;
  final OnboardingAnswers answers;

  /// Absent once onboarding is complete: there is nowhere left to resume.
  final OnboardingStep? nextStep;

  /// The concurrency token the next save must echo back as `If-Match`.
  /// Absent before anything has been stored, which is what a first save wants.
  final String? version;
}
```

Create `data/models/onboarding_failure.dart`:

```dart
enum OnboardingFailureKind {
  /// Somebody else saved first. The client must reload before writing again.
  versionConflict,

  /// An answer was refused. The pointer says which.
  answerRejected,

  /// Completion was asked for before every question was answered.
  incomplete,

  /// The session is not usable. Signing in again is the only recovery.
  sessionExpired,

  /// This device could not be verified.
  attestationRequired,

  networkUnavailable,

  /// This build has no API to call.
  configurationMissing,

  unexpected,
}

final class OnboardingFailure {
  const OnboardingFailure(this.kind, {this.pointer});

  final OnboardingFailureKind kind;

  /// The JSON pointer the server named, when it named one.
  final String? pointer;
}

sealed class OnboardingResult<T> {
  const OnboardingResult();
}

final class OnboardingSuccess<T> extends OnboardingResult<T> {
  const OnboardingSuccess(this.value);
  final T value;
}

final class OnboardingError<T> extends OnboardingResult<T> {
  const OnboardingError(this.failure);
  final OnboardingFailure failure;
}
```

Create `data/services/onboarding_service.dart`:

```dart
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_snapshot.dart';

abstract interface class OnboardingService {
  Future<OnboardingResult<OnboardingSnapshot>> load();

  /// Saves one step's answers. [expectedVersion] is the token from the last
  /// snapshot, and is null only before anything has been stored.
  Future<OnboardingResult<OnboardingSnapshot>> save({
    required OnboardingAnswers answers,
    required String? expectedVersion,
  });

  /// Founds the practice. [idempotencyKey] is minted once per wizard, so a
  /// retry after a timeout cannot create a second practice.
  Future<OnboardingResult<PracticeRef>> complete({
    required String idempotencyKey,
  });
}

/// Used when no API base URL is configured.
final class UnavailableOnboardingService implements OnboardingService {
  const UnavailableOnboardingService();

  @override
  Future<OnboardingResult<OnboardingSnapshot>> load() async => _unavailable();

  @override
  Future<OnboardingResult<OnboardingSnapshot>> save({
    required OnboardingAnswers answers,
    required String? expectedVersion,
  }) async => _unavailable();

  @override
  Future<OnboardingResult<PracticeRef>> complete({
    required String idempotencyKey,
  }) async => _unavailable();

  static OnboardingError<T> _unavailable<T>() {
    return const OnboardingError(
      OnboardingFailure(OnboardingFailureKind.configurationMissing),
    );
  }
}
```

- [ ] **Step 2: Write the failing test**

Create `test/unit/core/onboarding/http_onboarding_service_test.dart`, following `test/unit/core/auth/http_session_service_test.dart` for how it stubs Dio with a fixed status and body. Assert:

```dart
// 1.  load() reads status, nextStep, answers and version out of the envelope.
// 2.  load() with no version yields a snapshot whose version is null.
// 3.  save() sends If-Match when a version is given, and omits it when null.
// 4.  save() sends only the answers it was given, in wire form
//     (small_team, add_first_client), and never a null.
// 5.  A 412 becomes versionConflict.
// 6.  A 428 becomes versionConflict, because the recovery is identical:
//     reload and write again.
// 7.  A 400 validation_error becomes answerRejected carrying errors[0].pointer.
// 8.  A 409 onboarding_incomplete becomes incomplete carrying the pointer.
// 9.  A 403 app_check_required becomes attestationRequired.
// 10. A 401 becomes sessionExpired.
// 11. complete() sends the Idempotency-Key header and parses the PracticeRef.
// 12. A DioException becomes networkUnavailable.
```

Write each as a real test body. Case 4 written out, so the shape of the rest is not left to taste:

```dart
  test('sends only the answers it was given, in wire form', () async {
    final captured = <RequestOptions>[];
    final service = _serviceCapturing(captured, 200, '''
{"data":{"status":"in_progress","nextStep":"priorities","answers":{}}}''');

    await service.save(
      answers: const OnboardingAnswers(
        practiceSize: PracticeSize.smallTeam,
      ),
      expectedVersion: 'v-1',
    );

    final sent = captured.single;
    expect(sent.headers['if-match'], 'v-1');
    expect(sent.data, {
      'answers': {'practiceSize': 'small_team'},
    });
  });
```

- [ ] **Step 3: Run the tests and watch them fail**

```bash
flutter test test/unit/core/onboarding
```

Expected: FAIL, no such file `http_onboarding_service.dart`.

- [ ] **Step 4: Write the HTTP service**

Create `data/services/http_onboarding_service.dart`. It mirrors `HttpSessionService`: `validateStatus: (_) => true`, explicit timeouts, and problem-code mapping rather than exceptions. Send only the answers that are present, so a `PATCH` never clears an answer the user did not touch:

```dart
  Map<String, Object?> _answerPayload(OnboardingAnswers answers) {
    final practiceName = answers.practiceName;
    final practiceSize = answers.practiceSize;
    final startingPoint = answers.startingPoint;
    return {
      if (practiceName != null && practiceName.isNotEmpty)
        'practiceName': practiceName,
      if (practiceSize != null)
        'practiceSize': practiceSizeWireValue(practiceSize),
      if (answers.priorities.isNotEmpty)
        'priorities': answers.priorities.map(priorityWireValue).toList(),
      if (startingPoint != null)
        'startingPoint': startingPointWireValue(startingPoint),
    };
  }
```

and the failure mapping:

```dart
  static OnboardingFailure _failureFor(int status, Object? body) {
    final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final pointer = _firstPointer(map);
    return switch (map['code']) {
      // Both mean the same thing to a client: what you hold is not current.
      // The recovery is identical, so one kind keeps the view simpler.
      'version_mismatch' ||
      'version_required' => const OnboardingFailure(
        OnboardingFailureKind.versionConflict,
      ),
      'validation_error' => OnboardingFailure(
        OnboardingFailureKind.answerRejected,
        pointer: pointer,
      ),
      'onboarding_incomplete' => OnboardingFailure(
        OnboardingFailureKind.incomplete,
        pointer: pointer,
      ),
      'app_check_required' => const OnboardingFailure(
        OnboardingFailureKind.attestationRequired,
      ),
      'token_invalid' ||
      'authentication_required' => const OnboardingFailure(
        OnboardingFailureKind.sessionExpired,
      ),
      _ when status >= 500 => const OnboardingFailure(
        OnboardingFailureKind.unexpected,
      ),
      _ => const OnboardingFailure(OnboardingFailureKind.unexpected),
    };
  }
```

Reuse `HttpSessionService`'s practice-reference parsing for `complete()` by
extracting that parser into a shared function rather than writing a second one;
two parsers for one wire shape is how a field gets added to one and not the
other.

- [ ] **Step 5: Write the preview service**

Create `data/services/preview_onboarding_service.dart`: an in-memory snapshot with a version counter that enforces the same `If-Match` rule, and a `complete()` that mints a `PracticeRef` with a `prc_preview_` prefix. Preview must fail a stale version too, or a bug that only appears against the real server survives every preview demonstration.

- [ ] **Step 6: Wire the providers**

Create `onboarding_providers.dart`, following `sessionServiceProvider` in `lib/core/auth/auth_providers.dart` exactly: preview mode gets the preview service, a Firebase build with an API base URL gets the HTTP service over `authenticatedDioProvider`, anything else gets `UnavailableOnboardingService`.

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Run the tests and watch them pass**

```bash
flutter analyze && flutter test
```

- [ ] **Step 8: Commit**

```bash
git add src/molobuddy_app/lib src/molobuddy_app/test
git commit -m "feat: read, save and complete onboarding from the client"
```

---

### Task 4: The onboarding view model

**Files:**
- Create: `lib/core/onboarding/ui/view_models/onboarding_view_model.dart`
- Test: `test/unit/core/onboarding/onboarding_view_model_test.dart`

**Interfaces:**
- Consumes: `OnboardingService`, `AuthViewModel.reloadSession`.
- Produces: `OnboardingViewModel` (an `AsyncNotifier` over `OnboardingViewState`) with `saveAnswers(...)`, `goBack()`, `completeOnboarding()`; `OnboardingViewState` carrying `step`, `answers`, `version`, `busy`, `failure`, `completed`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/onboarding/onboarding_view_model_test.dart`. Assert, each as a real test body against a fake `OnboardingService`:

```dart
// 1.  Building loads the snapshot and opens at the server's nextStep.
// 2.  A resumed snapshot with two answers opens at startingPoint, not practice.
// 3.  saveAnswers sends the current version and adopts the returned one.
// 4.  saveAnswers advances the step to whatever the server derived, never to
//     a step the client guessed.
// 5.  A failed save does not advance the step and surfaces the failure.
// 6.  A versionConflict reloads the snapshot rather than retrying blind.
// 7.  goBack moves one step without calling the server.
// 8.  completeOnboarding sends one idempotency key, and the same key again on
//     a retry after failure.
// 9.  A completed onboarding sets completed and exposes the practice.
// 10. Nothing is dispatched while busy, so a double tap cannot double submit.
```

Case 8 written out, because it is the one that costs a duplicate practice if it
is wrong:

```dart
  test('reuses one idempotency key across a retry', () async {
    final service = FakeOnboardingService(readyToComplete)
      ..completeFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );
    final container = _containerWith(service);
    final model = container.read(onboardingViewModelProvider.notifier);
    await container.read(onboardingViewModelProvider.future);

    await model.completeOnboarding();
    service.completeFailure = null;
    await model.completeOnboarding();

    expect(service.idempotencyKeys, hasLength(2));
    expect(service.idempotencyKeys.first, service.idempotencyKeys.last);
  });
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
flutter test test/unit/core/onboarding/onboarding_view_model_test.dart
```

Expected: FAIL, no such file.

- [ ] **Step 3: Write the view model**

Create `ui/view_models/onboarding_view_model.dart` as `@Riverpod(keepAlive: true)`. It is keepAlive because the idempotency key must outlive a rebuild: an auto-disposed model would mint a new key when the widget tree rebuilt, and a retry would then found a second practice.

Key points the implementation must honour:

```dart
  /// Minted once for the life of this wizard.
  ///
  /// Held here rather than passed in per call so a retry after a timeout
  /// carries the same key the timed-out attempt did. That is the whole reason
  /// the server accepts a key at all.
  final String _idempotencyKey = 'onb_${_randomToken()}';
```

The step always comes from the server's `nextStep`:

```dart
      // The step is whatever the server derived from the answers it holds.
      // Computing it here as well would be a second copy of one rule, and a
      // resumed wizard would open on a question the user already answered.
      step: snapshot.nextStep ?? OnboardingStep.readyToComplete,
```

A version conflict reloads rather than retrying:

```dart
      // Someone else wrote first — another tab, most likely. Retrying with the
      // token we hold would fail identically forever, so reload and let the
      // user see what is actually stored.
      if (failure.kind == OnboardingFailureKind.versionConflict) {
        return _reload();
      }
```

And every mutating method returns early while `busy`, so a double tap cannot dispatch twice.

- [ ] **Step 4: Run the tests and watch them pass**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
```

- [ ] **Step 5: Commit**

```bash
git add src/molobuddy_app/lib src/molobuddy_app/test
git commit -m "feat: drive onboarding from server-derived state"
```

---

### Task 5: The route and the gate

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Test: `test/widget/app/onboarding_gate_test.dart`

**Interfaces:**
- Produces: `OnboardingRoute` at `/onboarding`.

- [ ] **Step 1: Write the failing test**

Create `test/widget/app/onboarding_gate_test.dart`, following `test/widget/app/not_found_test.dart` for how it pumps `MoloApp` in preview and navigates through `appRouterProvider`. Assert:

```dart
// 1.  A signed-out visitor at /onboarding is sent to /sign-in.
// 2.  A signed-in user whose session says onboarding is outstanding, going to
//     /home, arrives at /onboarding.
// 3.  The same user going to an unknown route arrives at /onboarding, not the
//     not-found page.
// 4.  A signed-in user whose onboarding is complete, going to /onboarding,
//     arrives at /home.
// 5.  While the session is still loading, nobody is redirected anywhere; the
//     app shows its loading state rather than guessing.
```

Case 5 matters: redirecting on incomplete information is what makes a signup flash through three screens on a slow connection.

- [ ] **Step 2: Run the test and watch it fail**

```bash
flutter test test/widget/app/onboarding_gate_test.dart
```

Expected: FAIL, `/onboarding` matches no route so the not-found page renders.

- [ ] **Step 3: Add the route**

In `app_router.dart`:

```dart
@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _moloPage(context, state, child: const OnboardingView());
  }
}
```

- [ ] **Step 4: Extend the redirect**

Replace the redirect body:

```dart
    redirect: (context, state) {
      final signedIn = ref.read(authRepositoryProvider).currentUser != null;
      final location = state.matchedLocation;
      final onSignIn = location == const SignInRoute().location;
      final onRegistration = location == const RegistrationRoute().location;
      final onOnboarding = location == const OnboardingRoute().location;
      final onPublicAuthRoute = onSignIn || onRegistration;

      if (!signedIn) {
        return onPublicAuthRoute ? null : const SignInRoute().location;
      }

      // Authentication does not tell us whether setup is finished; the session
      // does. Until it has answered, redirect nowhere: guessing is what makes
      // a signup flash through three screens on a slow connection.
      final session = switch (ref.read(authViewModelProvider)) {
        AsyncData(:final value) => value.session,
        _ => null,
      };
      if (session == null) {
        return null;
      }

      if (!session.onboardingComplete) {
        return onOnboarding ? null : const OnboardingRoute().location;
      }
      return onPublicAuthRoute || onOnboarding
          ? const WelcomeRoute().location
          : null;
    },
```

The router must also re-evaluate when the session settles, or a user who signs in stays on whatever page the first evaluation chose. Use `ref.listen` inside `appRouter`, because the provider is already in scope and it needs no extra `Listenable` to keep alive:

```dart
  final router = GoRouter(/* ... */);
  // The redirect above declines to guess while the session is loading, so
  // something has to ask it again once the answer arrives.
  ref.listen(authViewModelProvider, (_, _) => router.refresh());
  return router;
```

- [ ] **Step 5: Expect an existing test to break, and let it**

`sign_in_view_test.dart`'s "preview email sign-in reaches welcome and can sign out" signs in and expects `welcome_view`. From this task onward a preview user has no practice, so the gate correctly sends them to `/onboarding` instead. That test is now asserting the old behaviour.

Change it to expect the onboarding view, and move the sign-out half into a case that first completes onboarding. Do not weaken the gate to keep the old assertion green — the redirect is the feature.

- [ ] **Step 6: Run the tests and watch them pass**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
```

- [ ] **Step 7: Commit**

```bash
git add src/molobuddy_app/lib src/molobuddy_app/test
git commit -m "feat: route an unfinished account back to its onboarding"
```

---

### Task 6: Split the wizard and wire it

The account step stays at `/sign-up` and now creates an account. The rest moves to `/onboarding` and saves through the server. The completion screen stops lying.

**Files:**
- Create: `lib/core/auth/ui/views/registration/wizard_shell.dart`
- Modify: `lib/core/auth/ui/views/registration/registration_view.dart`
- Modify: `lib/core/auth/ui/view_models/registration_view_model.dart`
- Create: `lib/core/onboarding/ui/views/onboarding_view.dart`
- Modify: `lib/app/localisation/l10n/app_en.arb`, `app_en_ZA.arb`
- Test: `test/widget/core/auth/registration_view_test.dart`
- Test: `test/widget/core/onboarding/onboarding_view_test.dart`

- [ ] **Step 1: Extract the shell**

Move the progress panel, compact header, wordmark row and step-eyebrow widgets out of `registration_view.dart` into `wizard_shell.dart`, unchanged in behaviour. Both routes render the same shell, so the supporting-pane edge stays stable across the whole signup — which `sign_in_view_test.dart` already asserts for sign-in and registration and must keep asserting.

Take the existing `registration_progress_panel` key with it.

- [ ] **Step 2: Reduce the registration view model**

`RegistrationViewModel` keeps only the account step: `displayName`, `email`, the four validation flags, and a `submitting` flag. Delete `practiceName`, `practiceSize`, `priorities`, `startingPoint`, `continueFromPractice`, `selectPracticeSize`, `updatePracticeNamePreview`, `togglePriority`, `continueFromPriorities`, `selectStartingPoint` and `completePreview`. `RegistrationStep` reduces to `account` alone and can go entirely.

Their replacements live in `OnboardingViewModel`, and the three enumerations moved to `onboarding_answers.dart` in Task 3.

Add:

```dart
  /// Creates the account, then reports whether the caller may navigate on.
  ///
  /// Navigation is the view's job, not this model's; returning a bool keeps
  /// the model testable without a widget tree.
  Future<bool> createAccount({ ... }) async { ... }
```

mapping `emailAlreadyRegistered` to an error on the email field, `passwordRejected` to the password field, and everything else to a form-level message.

- [ ] **Step 3: Write the failing widget tests**

In `test/widget/core/auth/registration_view_test.dart`, keep every existing test that still applies and add:

```dart
// 1.  A valid account step calls createAccount and navigates to /onboarding.
// 2.  An address that is already registered shows the message on the email
//     field, not as a form-level error.
// 3.  A rejected password shows on the password field.
// 4.  An unexpected provider failure shows neutral copy and never the word
//     "Firebase".
// 5.  The button is disabled while the request is in flight, so a double tap
//     cannot create two accounts.
```

Create `test/widget/core/onboarding/onboarding_view_test.dart`:

```dart
// 1.  Opening at nextStep practice shows the practice-name field.
// 2.  Opening at nextStep startingPoint shows that step directly, with the
//     earlier answers already in state.
// 3.  Continuing from a step saves before it advances.
// 4.  A failed save keeps the user on the step and shows why.
// 5.  The final step calls complete and, on success, lands on the welcome view.
// 6.  A failed completion offers a retry.
// 7.  The completion copy no longer offers to go to sign-in.
```

- [ ] **Step 4: Run the tests and watch them fail**

```bash
flutter test test/widget/core/onboarding test/widget/core/auth/registration_view_test.dart
```

- [ ] **Step 5: Build the onboarding view**

Create `onboarding_view.dart` hosting the practice, priorities, starting-point and complete steps, moved from `registration_view.dart` with their existing keys preserved so no test loses its handle. Each step's continue button calls `saveAnswers`; the last calls `completeOnboarding`, then `reloadSession`, then navigates to `WelcomeRoute`.

- [ ] **Step 6: Correct the completion copy**

`registrationCompleteSummary` currently reads "…are ready for the real account flow", and the complete step's button goes to sign-in. Replace the summary with copy that describes a workspace that now exists, and point the button at the workspace. Update both `.arb` files and run `flutter gen-l10n`.

This is the contradiction flagged before the slice began: the screen claimed the workspace was ready and then sent the user to sign in. It is only allowed to claim it now because it is true.

- [ ] **Step 7: Run everything**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze && flutter test
```

- [ ] **Step 8: Commit**

```bash
git add src/molobuddy_app/lib src/molobuddy_app/test
git commit -m "feat: register an account and finish onboarding for real"
```

---

### Task 7: Prove it, twice

Preview mode first, because it is autonomous. Then the real run, which is not.

- [ ] **Step 1: Walk preview end to end**

```bash
cd src/molobuddy_app && flutter run -d web-server --web-hostname=127.0.0.1 --web-port=3000 --dart-define=MOLO_AUTH_MODE=preview
```

Create an account, answer all four screens, and land in the workspace with the practice you named. Then sign out, sign in again, and confirm you are not sent back to the wizard. Record what you saw.

- [ ] **Step 2: Add the preview regression test**

Whatever preview surfaced, encode it. At minimum, a widget test that drives `MoloApp` in preview from the sign-in screen through account creation, all four steps and into `welcome_view`, asserting the practice name appears. Preview is a supported product surface, so it deserves a test that fails when it breaks.

- [ ] **Step 3: Hand off the real run**

**This step needs a person.** Claude cannot create accounts.

Start the server with `AUTH_VERIFIER=firebase` and the app with `--dart-define-from-file=config/firebase.development.json`, then:

1. Register a genuinely new address. Confirm you land on `/onboarding`, not `/home`.
2. Answer the practice step, then **close the tab**.
3. Sign in again. Confirm you arrive at `/onboarding`, at the priorities step, with the practice name you already gave still stored.
4. Finish. Confirm the welcome screen shows the practice and never the no-practice state.
5. Reload. Confirm you go straight to `/home` and are not routed back into the wizard.

Step 3 is the one that matters most: it is the whole reason onboarding is persisted rather than held in memory, and no automated test in this repo can reach it.

- [ ] **Step 4: Record the result**

Write what happened into the task report, including anything that differed from the plan. If step 3 resumed at the wrong step, that is a defect in the server's resume derivation, not in the wizard — check `resumeStepFor` before changing any client code.

---

### Task 8: Fold the decisions back into the documents

**Files:**
- Modify: `docs/plans/2026-08-20-founding-onboarding-design.md`
- Modify: `docs/local_development.md`
- Modify: `docs/backend_design/authentication.md`

- [ ] **Step 1: Answer the open question**

Spec section 4.1 names the enumeration-protection question as open. Replace it with whatever Task 1 Step 8 observed, or state plainly that it was not run and the neutral copy stands.

- [ ] **Step 2: Record the client shape**

Update spec section 8 to describe what was built: two routes, the shell they share, the keepAlive view model holding one idempotency key for the wizard's life, and the step always coming from the server rather than being computed twice.

- [ ] **Step 3: Update the authentication design's status section**

`docs/backend_design/authentication.md` section 17 tracks what is implemented. Add that account creation now exists behind `AuthService`, and that a new account is signed in immediately and routed to onboarding rather than to the workspace.

- [ ] **Step 4: Update the runbook**

In `docs/local_development.md`, state that preview mode completes the whole signup with no backend, and that a real registration run needs a genuinely new address because an existing one cannot be reused.

- [ ] **Step 5: Commit**

```bash
git add docs
git commit -m "docs: record how registration and onboarding were wired"
```

---

## Out of Scope

Named so the plan cannot quietly grow:

- Acting on the answers. The workspace does not yet change shape because someone chose "deadlines".
- Accepting an invitation as an alternative way to finish onboarding.
- Editing answers after completion.
- Creating a second practice from inside the product.
- Email verification prompts. Founding a practice does not require a verified address, and nothing here should imply otherwise.
- Deleting or migrating the draft of an abandoned signup.
