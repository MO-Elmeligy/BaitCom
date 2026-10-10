import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class BaytFirebaseOptions {
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );

  static const _webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _webAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
  );

  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );

  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.realestate.realEstateApp',
  );

  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      if (!_hasValues([
        _projectId,
        _messagingSenderId,
        _webApiKey,
        _webAppId,
      ])) {
        return null;
      }
      return FirebaseOptions(
        apiKey: _webApiKey,
        appId: _webAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _webAuthDomain.isEmpty
            ? '$_projectId.firebaseapp.com'
            : _webAuthDomain,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (!_hasValues([
          _projectId,
          _messagingSenderId,
          _androidApiKey,
          _androidAppId,
        ])) {
          return null;
        }
        return FirebaseOptions(
          apiKey: _androidApiKey,
          appId: _androidAppId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
        );
      case TargetPlatform.iOS:
        if (!_hasValues([
          _projectId,
          _messagingSenderId,
          _iosApiKey,
          _iosAppId,
          _iosBundleId,
        ])) {
          return null;
        }
        return FirebaseOptions(
          apiKey: _iosApiKey,
          appId: _iosAppId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          iosBundleId: _iosBundleId,
        );
      default:
        return null;
    }
  }

  static bool _hasValues(List<String> values) =>
      values.every((value) => value.trim().isNotEmpty);
}
