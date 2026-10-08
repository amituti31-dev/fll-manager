import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCgzCubW3e2D7Cqi1LDQI7_cMcdGC7O-AU',
    appId: '1:493332319136:android:4aaf6e0e9fdf769eb532c5',
    messagingSenderId: '493332319136',
    projectId: 'fll-manger',
    storageBucket: 'fll-manger.firebasestorage.app',
  );
}
