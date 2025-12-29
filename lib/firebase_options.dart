import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAPD6aNthurcu_CKGMUvJAgj_gf82Zyo0k',
    appId: '1:911540992478:web:d959db301a38dc7fbfc54f',
    messagingSenderId: '911540992478',
    projectId: 'techmarathonapp',
    authDomain: 'techmarathonapp.firebaseapp.com',
    storageBucket: 'techmarathonapp.firebasestorage.app',
    measurementId: 'G-EQ0G29QHJN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2o7z_Am0VAJ44lH1fqLPPYmLbk9dS2SE',
    appId: '1:911540992478:android:94dd34aa4f1b2118bfc54f',
    messagingSenderId: '911540992478',
    projectId: 'techmarathonapp',
    storageBucket: 'techmarathonapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBy4aKIo_GlMSmjr_5JH9fU9ow2b9WcoGA',
    appId: '1:911540992478:ios:45068d4082a4f455bfc54f',
    messagingSenderId: '911540992478',
    projectId: 'techmarathonapp',
    storageBucket: 'techmarathonapp.firebasestorage.app',
    iosBundleId: 'com.techmarathon.app',
  );

}
