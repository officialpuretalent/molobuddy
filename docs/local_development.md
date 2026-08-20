# Local Development

- **Status:** Active
- **Owner:** Engineering
- **Last updated:** 20 August 2026

How to run the Flutter application and the control API against the shared
development Firebase project. This is an operational runbook, not a design
contract. The identity design is in
[client-first authentication](backend_design/authentication.md).

## Firebase project

| Item | Value |
|---|---|
| Project ID | `molobuddy-development` |
| Project number | `340201216373` |
| Web app ID | `1:340201216373:web:048ae223e577ded7c0db3c` |
| Android app ID | `1:340201216373:android:d8e3dae29bcf585ec0db3c` |
| iOS app ID | `1:340201216373:ios:2cc9649fee68c026c0db3c` |
| Android package | `com.molobuddy.molobuddy_app` |
| iOS bundle | `com.molobuddy.molobuddyApp` |

Email/password sign-in and improved email-enumeration protection are enabled on
this project, which the authentication design requires. Multi-factor
authentication is disabled. Authorised domains are `localhost`,
`molobuddy-development.firebaseapp.com` and `molobuddy-development.web.app`.

`molobuddy-development` is a development project. Do not put real taxpayer
information in it, and do not reuse its configuration for staging or
production.

## Configuration files

Two files hold local configuration. Both are ignored by git; the committed
`.example` versions record the expected keys.

| Application | Real file (ignored) | Template (committed) |
|---|---|---|
| Flutter | `src/molobuddy_app/config/firebase.development.json` | `firebase.development.example.json` |
| Server | `src/molobuddy_server/.env.local` | `.env.example` |

Copy the template and fill it in on a new machine:

```bash
cp src/molobuddy_app/config/firebase.development.example.json src/molobuddy_app/config/firebase.development.json
```

Recover the Flutter values at any time with:

```bash
firebase apps:sdkconfig WEB --project molobuddy-development
```

A Firebase Web API key is a public client identifier, not a secret. It ships
inside every web bundle. These files are ignored to keep environment
configuration out of the repository, not because the key is confidential.
Client requests are protected by App Check, server-side token verification and
security rules, never by hiding this value.

## Running the Flutter application

Against the real Firebase project:

```bash
cd src/molobuddy_app && flutter run -d chrome --dart-define-from-file=config/firebase.development.json
```

Without Firebase, using the in-memory preview identity:

```bash
cd src/molobuddy_app && flutter run -d chrome --dart-define=MOLO_AUTH_MODE=preview
```

Preview mode shows a "Preview mode · Nothing is saved" banner. If you expect
Firebase and still see that banner, the defines did not reach the build.

VS Code users get both as launch configurations in `.vscode/launch.json`.

`AppEnvironment.fromCompilation()` reads these defines. Missing or incomplete
Firebase values leave the app in an `unavailable` state that refuses sign-in
rather than failing silently.

## Running the control API

```bash
cd src/molobuddy_server && npm run dev
```

The server selects its token verifier from `AUTH_VERIFIER` in `.env.local`:

- `firebase` — verifies real Firebase ID tokens and App Check tokens through
  the Admin SDK, using Application Default Credentials. Run
  `gcloud auth application-default login` once if `applicationDefault()` cannot
  find credentials. **This is the only mode the Flutter application can use.**
- `local` — compares the presented ID token against one hardcoded fake string
  from `LOCAL_AUTH_ID_TOKEN`. Useful for curl and contract tests that present
  that exact string. Forbidden in production.

**Do not run the application against `AUTH_VERIFIER=local`.** The client sends
a real Firebase ID token, the local verifier compares it against its fake, the
strings never match, and every `/v1/session` request fails with
`token_invalid` before App Check is even considered. The screen then reports
that the session ended and invites a fresh sign-in, which cannot help, because
nothing about the session expired. The two configurations are simply
incompatible.

## App Check

The client plumbing exists. `MoloAuthenticatedTransport` attaches the identity
token as `authorization: Bearer …` and the attestation token as
`x-firebase-appcheck`, which are the headers the control API reads. Both come
from Molo-owned interfaces, so no feature imports a vendor SDK or sees a raw
token. A test asserts that containment.

Attestation activates only when the build is configured for it. With neither
`MOLO_APP_CHECK_RECAPTCHA_SITE_KEY` nor `MOLO_APP_CHECK_DEBUG`, the app uses
`UnavailableAppCheckGateway` and simply sends no attestation header. A failed
or missing attestation never blocks a request; the server decides.

### Choosing a provider

Web attestation uses reCAPTCHA. Both options have a free path: reCAPTCHA v3 is
a no-cost service, and reCAPTCHA Enterprise covers 10,000 assessments a month
at no cost, which a development project will not approach. Google recommends
Enterprise for new integrations. Neither shows the user a challenge.

Android and iOS never use reCAPTCHA. They use Play Integrity and App Attest,
which need no extra account.

### Debug attestation for local work

Local development does not need reCAPTCHA at all.

1. Enable the `FIREBASE_APPCHECK_DEBUG_TOKEN` line in
   `src/molobuddy_app/web/index.html`. It is already enabled in this
   repository; a deployed build must comment it out again.
2. Set `"MOLO_APP_CHECK_DEBUG": true` in `config/firebase.development.json`.
3. Run the app and copy the debug token printed in the browser console. Look
   for the line beginning `App Check debug token:`.
4. Safelist it in Firebase console under App Check → Apps → the Web app →
   Manage debug tokens.

The debug token bypasses device verification. Never commit it, and never ship
it in a deployed build. `useAppCheckDebugProvider` is additionally gated on
`kDebugMode`, so a release build ignores the define.

### Enforcement

App Check is registered against Identity Platform and Firestore but both are
`UNENFORCED`, which is the state the authentication design asks for. Roll out
monitoring first and confirm that legitimate traffic is passing before
enforcing, or valid clients get locked out.

### Order matters when setting this up

The two settings are dependent, so do them in this order:

1. Safelist the debug token first, and confirm the
   `exchangeDebugToken` call stops returning 403. A token that is not
   safelisted fails attestation, and no server setting compensates for that.
2. Then set `AUTH_VERIFIER=firebase` and restart the server.

Doing it the other way round only moves the error from `token_invalid` to
`app_check_required`.

Debug tokens are per browser profile. Each browser generates its own the first
time it runs with the flag on, so every machine either safelists its own value
or the team pins one shared UUID by assigning it directly:
`self.FIREBASE_APPCHECK_DEBUG_TOKEN = '<uuid>'`. A debug token is an
attestation bypass. It belongs only to `molobuddy-development` and must never
reach a deployed build.

Do not "fix" an attestation failure by weakening the verifier. The App Check
requirement is a deliberate control, and App Check failures must stay
distinguishable from authentication failures.

## Verification

```bash
cd src/molobuddy_app && flutter analyze && flutter test
cd src/molobuddy_server && npm run check
```
