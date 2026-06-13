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

  // מגיע מ-google-services.json — יש להחליף בערכים האמיתיים
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBok0hLHN9nRflFEjZoiSg0GL8a90kAESU',
    appId: '1:493332319136:android:ee2268657dbf4b29b532c5',
    messagingSenderId: '493332319136',
    projectId: 'fll-manger',
    storageBucket: 'fll-manger.firebasestorage.app',
  );
}
