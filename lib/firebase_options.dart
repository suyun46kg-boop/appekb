import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _placeholder = 'REPLACE_ME';

  static bool _isPlatformConfigured(FirebaseOptions options) =>
      options.apiKey != _placeholder &&
      options.appId != _placeholder &&
      options.projectId != _placeholder;

  /// True only when Firebase is configured for the current platform.
  static bool get isConfigured {
    if (kIsWeb) {
      return false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _isPlatformConfigured(android);
      case TargetPlatform.iOS:
        return _isPlatformConfigured(ios);
      default:
        return false;
    }
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Push notifications are not configured for web.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Push notifications are not supported on this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZEx3xUG411F00-TguAcPxtXc3aW_aWzE',
    appId: '1:283106418601:android:15a38c2ba479971f60eeb8',
    messagingSenderId: '283106418601',
    projectId: 'ekbkyrgyzdar',
    storageBucket: 'ekbkyrgyzdar.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    storageBucket: _placeholder,
    iosBundleId: 'mycompany.ekbkyrgyzdar',
  );
}
