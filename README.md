# Kawula POS Mobile

Kawula POS Mobile is a Flutter application for Kawula POS cashiers and administrators. It supports point-of-sale transactions, shift management, product and category management, and finance and transaction reports.

It uses the following technologies:

- Flutter
- Dart
- FVM (Flutter Version Management)

The Flutter version is managed with FVM using the version in `.fvmrc`. Before running the app, make sure the Kawula POS API is available and configure the environment:

- Copy `.env.example` to `.env`.
- Set the `API_BASE_URL_ANDROID`, `API_BASE_URL_WEB`, and `API_BASE_URL_DEFAULT` values for your environment.
- The default Android emulator URL is `http://10.0.2.2:3001/api`; web and desktop default to `http://localhost:3001/api`.

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
