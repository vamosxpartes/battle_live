// File generated based on Firebase CLI settings
// This is a placeholder file - replace with your actual firebase_options.dart
// generated using Firebase CLI or the Firebase console

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de configuración predeterminadas para Firebase
///
/// Ejemplo de configuración para el desarrollo.
/// Reemplaza estos valores con los de tu proyecto real.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están disponibles para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBattleLiveAppKey',
    appId: '1:123456789012:web:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'battle-live',
    authDomain: 'battle-live.firebaseapp.com',
    storageBucket: 'battle-live.appspot.com',
    measurementId: 'G-ABCDEFGHIJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAndroidAppKey',
    appId: '1:123456789012:android:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'battle-live',
    storageBucket: 'battle-live.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyIOSAppKey',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'battle-live',
    storageBucket: 'battle-live.appspot.com',
    iosBundleId: 'com.example.battleLive',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyMacOSAppKey',
    appId: '1:123456789012:macos:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'battle-live',
    storageBucket: 'battle-live.appspot.com',
    iosBundleId: 'com.example.battleLive',
  );
} 