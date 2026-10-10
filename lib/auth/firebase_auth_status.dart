import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

bool firebaseAuthReady = false;

Future<void> initializeFirebaseAuth() async {
  final options = BaytFirebaseOptions.currentPlatform;
  if (options == null) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await Firebase.initializeApp();
        firebaseAuthReady = true;
      } catch (error) {
        if (kReleaseMode) rethrow;
        debugPrint(
          'Firebase is not configured for this run (${error.runtimeType}).',
        );
      }
      return;
    }
    if (kReleaseMode &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      throw StateError(
        'Firebase options are required for Android and iOS release builds. '
        'Pass the FIREBASE_* dart-defines documented in README.md.',
      );
    }
    return;
  }

  try {
    await Firebase.initializeApp(options: options);
    firebaseAuthReady = true;
  } catch (error) {
    if (kReleaseMode && !kIsWeb) rethrow;
    final errorType = error.runtimeType;
    debugPrint('Firebase is not configured for this run ($errorType).');
  }
}

Future<String?> currentFirebaseIdToken() async {
  if (!firebaseAuthReady) return null;
  return FirebaseAuth.instance.currentUser?.getIdToken();
}
