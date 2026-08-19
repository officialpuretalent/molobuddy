# Molo Flutter app

Molo is one responsive Flutter app for Web, Android and iOS. The first runnable slice contains email/password authentication, a catalogue-driven Google sign-in placeholder and a signed-in welcome workspace.

## Run the local preview

```sh
flutter pub get
flutter run -d chrome
```

In a debug build, enter any valid-looking email address and a password of at least eight characters. The local preview adapter keeps the session in memory only and saves no credentials or account data. Google is intentionally disabled and labelled **Coming soon**.

The preview adapter checks Flutter's compile-time debug mode internally. A release build using the default configuration fails closed and cannot authenticate.

## Use Firebase Authentication

Set the authentication mode and public configuration through compile-time definitions:

```sh
flutter run -d chrome \
  --dart-define=MOLO_AUTH_MODE=firebase \
  --dart-define=MOLO_API_BASE_URL=https://api.example.com \
  --dart-define=MOLO_FIREBASE_API_KEY=public-api-key \
  --dart-define=MOLO_FIREBASE_APP_ID=public-app-id \
  --dart-define=MOLO_FIREBASE_SENDER_ID=public-sender-id \
  --dart-define=MOLO_FIREBASE_PROJECT_ID=project-id \
  --dart-define=MOLO_FIREBASE_AUTH_DOMAIN=project.firebaseapp.com
```

These values are public Firebase client configuration, not secrets. Provider credentials, ID tokens and raw Firebase user types remain inside the authentication data layer.

The app loads provider availability from `GET /v1/auth/providers`. Only local debug preview mode may fall back to the bundled email/password and Google-coming-soon catalogue when the API is offline.

## Quality checks

```sh
dart format --output=none --set-exit-if-changed lib test
dart run build_runner build
flutter analyze
flutter test
flutter build web --release
```

Architecture and product sources of truth:

- [Flutter app design](../../docs/app_design/README.md)
- [Authentication design](../../docs/backend_design/authentication.md)
- [API contracts](../../docs/api_design/README.md)
- [Brand platform](../../docs/product/brand_platform.md)
