# Local Development

- **Status:** Active
- **Owner:** Engineering
- **Last updated:** 19 August 2026

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

- `local` — accepts one configured fake token pair. This is the default for
  local development and the only mode in which the Flutter application can
  currently reach `/v1/session`. Forbidden in production.
- `firebase` — verifies real Firebase ID tokens and App Check tokens through
  the Admin SDK, using Application Default Credentials. Run
  `gcloud auth application-default login` once if `applicationDefault()` cannot
  find credentials.

## Known gap: App Check blocks the real end-to-end path

`FirebaseAdminRequestTokenVerifier` rejects any request without an App Check
token, which the authentication design intends. The Flutter application does
not yet send one, because App Check is not set up.

So with `AUTH_VERIFIER=firebase`, every application request to `/v1/session`
fails with `app_check_required`, even when the user holds a valid Firebase ID
token. Local development therefore stays on `AUTH_VERIFIER=local`.

Closing this gap means adding App Check to the Flutter application and rolling
it out in monitoring mode before enforcement, per
[authentication](backend_design/authentication.md) section 13. Until then, do
not "fix" the failure by weakening the verifier: the App Check requirement is a
deliberate control, and authentication failures and App Check failures must
remain distinct.

## Verification

```bash
cd src/molobuddy_app && flutter analyze && flutter test
cd src/molobuddy_server && npm run check
```
