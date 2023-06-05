// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBrWexqHiVXJ2s7ATx941EokjvDMLOFhJk',
    appId: '1:889608347825:web:45ea1fa8548d6502644290',
    messagingSenderId: '889608347825',
    projectId: 'whatsapp-clone-48e48',
    authDomain: 'whatsapp-clone-48e48.firebaseapp.com',
    storageBucket: 'whatsapp-clone-48e48.appspot.com',
    measurementId: 'G-5J72M0WK9M',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgoZvfidY_c1goiks_LhzC5vd_8B82Q5M',
    appId: '1:889608347825:android:67a9ade1b5fcd4ae644290',
    messagingSenderId: '889608347825',
    projectId: 'whatsapp-clone-48e48',
    storageBucket: 'whatsapp-clone-48e48.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCk7liXLNqwU9h42xSNbaDXTO23Ql9YxEo',
    appId: '1:889608347825:ios:393b276b01e0dd32644290',
    messagingSenderId: '889608347825',
    projectId: 'whatsapp-clone-48e48',
    storageBucket: 'whatsapp-clone-48e48.appspot.com',
    iosClientId: '889608347825-7839hq9sn4ts8ah46k8gbmms18ogqp2r.apps.googleusercontent.com',
    iosBundleId: 'com.example.whatsappClone',
  );
}
