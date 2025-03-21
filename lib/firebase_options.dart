// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAHjBU_S76PjBdn56wG7kkRULfhiGTKI-Q',
    appId: '1:93869706966:web:9625adfb088053bf208377',
    messagingSenderId: '93869706966',
    projectId: 'kanji-sensei-720df',
    authDomain: 'kanji-sensei-720df.firebaseapp.com',
    storageBucket: 'kanji-sensei-720df.firebasestorage.app',
    measurementId: 'G-9JXNR90XJZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB5Zamp-YtG6qAHv3hN4HXWWFqdjY65ozs',
    appId: '1:93869706966:android:66a850051b24b628208377',
    messagingSenderId: '93869706966',
    projectId: 'kanji-sensei-720df',
    storageBucket: 'kanji-sensei-720df.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBFxBsTprPHLnRCwOdmOfY7fzd35zNiSuk',
    appId: '1:93869706966:ios:517f6dfcccde01b9208377',
    messagingSenderId: '93869706966',
    projectId: 'kanji-sensei-720df',
    storageBucket: 'kanji-sensei-720df.firebasestorage.app',
    iosBundleId: 'com.example.kanjiSensei',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBFxBsTprPHLnRCwOdmOfY7fzd35zNiSuk',
    appId: '1:93869706966:ios:517f6dfcccde01b9208377',
    messagingSenderId: '93869706966',
    projectId: 'kanji-sensei-720df',
    storageBucket: 'kanji-sensei-720df.firebasestorage.app',
    iosBundleId: 'com.example.kanjiSensei',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAHjBU_S76PjBdn56wG7kkRULfhiGTKI-Q',
    appId: '1:93869706966:web:4de60d123b6fe884208377',
    messagingSenderId: '93869706966',
    projectId: 'kanji-sensei-720df',
    authDomain: 'kanji-sensei-720df.firebaseapp.com',
    storageBucket: 'kanji-sensei-720df.firebasestorage.app',
    measurementId: 'G-J87RMJM2KZ',
  );
}
