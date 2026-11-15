import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase options for the BYBHUB app.
/// Replace with real values from: https://console.firebase.google.com
/// Run: flutterfire configure  (after: dart pub global activate flutterfire_cli)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  // ── PLACEHOLDER — replace with flutterfire configure output ──────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'bybhub-mobile',
    storageBucket: 'bybhub-mobile.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLACEHOLDER_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'bybhub-mobile',
    storageBucket: 'bybhub-mobile.appspot.com',
    iosBundleId: 'com.bybimport.bybhub',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'bybhub-mobile',
    storageBucket: 'bybhub-mobile.appspot.com',
    authDomain: 'bybhub-mobile.firebaseapp.com',
  );
}
