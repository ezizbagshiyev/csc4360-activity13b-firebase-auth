# Campus Access - Activity 13B

Flutter Android app for CSC 4360, by Eziz Bagshiyev, with AI assistance disclosed.

## Features
- Email/password registration and sign-in through AuthService.
- A stable authStateChanges stream controls signed-out/profile UI.
- Profile shows the current Firebase email and supports sign-out.
- Password updates handle requires-recent-login by requesting the current password, reauthenticating, and retrying.
- Local email and six-character password validation, progress feedback, disabled duplicate submissions, and safe error messages.
- No passwords are stored in Firestore or logs. This app does not use Firestore.

## Configure and run
1. Install Flutter and the Android SDK. This project was built with Flutter 3.47.2 / Dart 3.13.2, Java 21, and Android SDK 36.
2. In Firebase Console create/select your project, register Android package `edu.gsu.eziz.incl13b`, and enable Authentication > Email/Password.
3. Install the Firebase CLI and FlutterFire CLI following the official setup guide. Run `flutterfire configure --platforms=android` from this folder to generate `lib/firebase_options.dart`. The example file also documents the required fields.
4. Run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run` with an Android device selected.
5. Run `flutter build apk --release`. Output: `build/app/outputs/flutter-apk/app-release.apk`.

The main Android manifest includes INTERNET permission. The activity APK uses Flutter's debug signing configuration for classroom installation; it is not a Play Store production release. No signing secrets are included. Firebase configuration files are excluded from version control. Configure your own Firebase project before rebuilding.

The Android root build file aligns the Firebase libraries to installed compile SDK 36. FlutterFire currently emits a Kotlin migration warning under AGP 9; the resolved dependency versions are recorded in pubspec.lock.

## Verification and limits
`flutter analyze` passed. Four automated tests passed: email validation, password validation, privacy-safe error mapping, and one widget scenario exercising signed-out gating, invalid form input, pending-request loading/disabled submission, and simulated network feedback.

`test/evidence/*.png` are actual Flutter widget-test renders using a stub auth service. They do not demonstrate live Firebase sign-in, Android installation, registration, session persistence, sign-out, or password-update success. No completed live-auth tests are claimed. The available Pixel 7 emulator cannot access hardware acceleration in this execution environment, and no Android device is connected.

## Manual acceptance tests still required
Use fictional test data, keep passwords hidden, and install the exact release APK.
1. Register a fresh test account; expect signed-in profile/email and a corresponding Firebase Users entry.
2. Sign out; expect sign-in screen. Back must not expose the profile.
3. Sign in; expect the same email. Stop/reopen the app; expect restored session without a sign-in-screen flash.
4. Try malformed email/short password; expect local feedback and no request. Try wrong credentials; expect a generic sign-in error.
5. Update the password; expect success. Sign out, verify old password fails and new password succeeds.
6. For an aged session, update the password; if requires-recent-login appears, enter the current password and retry. Verify failed reauthentication keeps the action incomplete. If not triggered, report this as a plan, not a pass.
7. Disable connectivity during a request; expect loading/disabled controls then helpful feedback.

## AI disclosure
OpenAI Codex assisted with implementation, debugging, tests, documentation, and reflection preparation on November 5, 2026. The prediction/test-plan text is AI-assisted; no original pre-AI student prediction was supplied. The reflection distinguishes observed automated results from planned device/live-auth tests.

## Official references
- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/start
- https://firebase.google.com/docs/auth/flutter/manage-users
- https://docs.flutter.dev/cookbook/forms/validation
- https://docs.flutter.dev/deployment/android
