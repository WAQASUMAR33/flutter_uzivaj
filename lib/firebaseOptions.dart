import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyAYv72aVNAV74kMFh4tb3SLZnkYJgZdQTQ',
    appId: '1:995140505639:web:34c16dda34de9287977e02',
    messagingSenderId: '995140505639',
    projectId: 'rapidtechpro-6e103',
    authDomain: 'rapidtechpro-6e103.firebaseapp.com',
    storageBucket: 'rapidtechpro-6e103.firebasestorage.app',
    measurementId: 'G-WRMDZ80LWF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYv72aVNAV74kMFh4tb3SLZnkYJgZdQTQ',
    appId: '1:995140505639:android:34c16dda34de9287977e02',
    messagingSenderId: '995140505639',
    projectId: 'rapidtechpro-6e103',
    storageBucket: 'rapidtechpro-6e103.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAYv72aVNAV74kMFh4tb3SLZnkYJgZdQTQ',
    appId: '1:995140505639:ios:f77d6209c0a69091977e02',
    messagingSenderId: '995140505639',
    projectId: 'rapidtechpro-6e103',
    storageBucket: 'rapidtechpro-6e103.firebasestorage.app',
    iosBundleId: 'com.example.juggaad',
  );
}
