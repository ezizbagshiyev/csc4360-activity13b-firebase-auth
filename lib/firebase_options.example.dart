import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
// Copy this to firebase_options.dart and supply your Android Firebase options,
// or generate the file using flutterfire configure --platforms=android.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) { return android; }
    throw UnsupportedError('Configure Firebase for this platform.');
  }
  static const android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY', appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_PROJECT_NUMBER', projectId: 'YOUR_PROJECT_ID',
  );
}
