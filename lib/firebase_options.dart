import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options currently configured for Android.
/// Run `flutterfire configure` to add options for other platforms.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBJIAJYfql1o4JLqo_4ZkTdK2Gxm85jKJ8',
    appId: '1:407096058536:android:7cb240366d67aff366d89d',
    messagingSenderId: '407096058536',
    projectId: 'mylifeplanner-8dea6',
    storageBucket: 'mylifeplanner-8dea6.firebasestorage.app',
  );

  static FirebaseOptions get ios => _unsupportedPlatform('iOS');
  static FirebaseOptions get macos => _unsupportedPlatform('macOS');
  static FirebaseOptions get web => _unsupportedPlatform('web');
  static FirebaseOptions get windows => _unsupportedPlatform('Windows');
  static FirebaseOptions get linux => _unsupportedPlatform('Linux');

  static Never _unsupportedPlatform(String platform) {
    throw UnsupportedError(
      'Firebase is not configured for $platform. Run flutterfire configure.',
    );
  }
}
