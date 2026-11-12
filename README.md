# Kawula POS Mobile

Kawula POS Mobile is a Flutter application for Kawula POS cashiers and administrators. It supports point-of-sale transactions, shift management, product and category management, and finance and transaction reports.

It uses the following technologies:

- Flutter
- Dart
- FVM (Flutter Version Management)

The Flutter version is managed with FVM using the version in `.fvmrc`. Before running the app, configure the mobile API:

- Copy `.env.example` to `.env`.
- The default API is production: `https://kawula-api.example/api`.
- For the Android emulator with a backend running on the development host, run with `--dart-define=API_BASE_URL=http://10.0.2.2:3001/api`.
- For a physical device, use the production API or set `API_BASE_URL_ANDROID` to a backend address reachable from that device (for example, a LAN address during development).
- `API_BASE_URL` supplied as a Dart define overrides `.env`. Platform-specific `.env` values override the generic `API_BASE_URL` value.
- For a production release build, pass `--dart-define=API_BASE_URL=https://kawula-api.example/api` so a local development `.env` cannot redirect the app to an emulator or LAN server.

To install dependencies and run the app, run these commands from the project directory:

```sh
fvm install
fvm flutter pub get
fvm flutter run
```

To build an Android debug APK:

```sh
fvm flutter build apk --debug
```

To build an Android release APK, configure Android release signing before distributing the APK:

```sh
fvm flutter build apk
```

The app version is `1.0.0` (build `1`).
