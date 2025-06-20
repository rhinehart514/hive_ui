// File generated by FlutterFire CLI.
// Contains Firebase configuration for your 'hive-9265c' project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
          'Linux platform is not supported - manually configure your Firebase app',
        );
      default:
        throw UnsupportedError(
          'Unknown platform $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMDHXJ8LcWGXz05ipPTNvA-fRi9nfdzbQ',
    appId: '1:573191826528:web:3f69854745f8ec41c1a705',
    messagingSenderId: '573191826528',
    projectId: 'hive-9265c',
    authDomain: 'hive-9265c.firebaseapp.com',
    databaseURL: 'https://hive-9265c-default-rtdb.firebaseio.com',
    storageBucket: 'hive-9265c.appspot.com',
    measurementId: 'G-57E3NBLRPQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYuRfRG-Ni3wCulwzQIhm8lh5MMWROh0U',
    appId: '1:573191826528:android:142a6b53108029ebc1a705',
    messagingSenderId: '573191826528',
    projectId: 'hive-9265c',
    databaseURL: 'https://hive-9265c-default-rtdb.firebaseio.com',
    storageBucket: 'hive-9265c.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAGzxEaW_MkPnN3DAvwW7MOfY8V0GNRn24',
    appId: '1:573191826528:ios:9fb3df22f15321d5c1a705',
    messagingSenderId: '573191826528',
    projectId: 'hive-9265c',
    databaseURL: 'https://hive-9265c-default-rtdb.firebaseio.com',
    storageBucket: 'hive-9265c.appspot.com',
    androidClientId: '573191826528-e815gk6bh55k1nfirmfcoahu5vpnbl48.apps.googleusercontent.com',
    iosClientId: '573191826528-0lbugjqjf7baf66qpq0ktl32altvkcji.apps.googleusercontent.com',
    iosBundleId: 'com.example.hiveUi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAGzxEaW_MkPnN3DAvwW7MOfY8V0GNRn24',
    appId: '1:573191826528:ios:9fb3df22f15321d5c1a705',
    messagingSenderId: '573191826528',
    projectId: 'hive-9265c',
    databaseURL: 'https://hive-9265c-default-rtdb.firebaseio.com',
    storageBucket: 'hive-9265c.appspot.com',
    androidClientId: '573191826528-e815gk6bh55k1nfirmfcoahu5vpnbl48.apps.googleusercontent.com',
    iosClientId: '573191826528-0lbugjqjf7baf66qpq0ktl32altvkcji.apps.googleusercontent.com',
    iosBundleId: 'com.example.hiveUi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDMDHXJ8LcWGXz05ipPTNvA-fRi9nfdzbQ',
    appId: '1:573191826528:web:9a45d24d1c19e2abc1a705',
    messagingSenderId: '573191826528',
    projectId: 'hive-9265c',
    authDomain: 'hive-9265c.firebaseapp.com',
    databaseURL: 'https://hive-9265c-default-rtdb.firebaseio.com',
    storageBucket: 'hive-9265c.appspot.com',
    measurementId: 'G-XLRQEW08TF',
  );

}