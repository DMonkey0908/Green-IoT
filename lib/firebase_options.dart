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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  //Tùy biến Firebase trên Android

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_wiHWcoVlhiY6sm0g2KCDY3D5zNjEhIE',
    appId: '1:1021336165966:android:f50be3d63dd95922ae6d1f',
    messagingSenderId: '1021336165966',
    projectId: 'esp32-random',
    databaseURL: 'https://esp32-random-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'esp32-random.appspot.com',
  );

  //Tùy biến Firebase trên IOS

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAbiTujWcJ70JPiUC1-Kx-7hmbw-rZmZUs',
    appId: '1:1021336165966:ios:5f8d760242afc448ae6d1f',
    messagingSenderId: '1021336165966',
    projectId: 'esp32-random',
    databaseURL: 'https://esp32-random-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'esp32-random.appspot.com',
    androidClientId: '1021336165966-a77isdpkri8gp6jrcq18ght6i2mro7eb.apps.googleusercontent.com',
    iosClientId: '1021336165966-7nku5jq90169h9v32nrmkv6ce2jr39sq.apps.googleusercontent.com',
    iosBundleId: 'com.example.demo2',
  );

}