import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../auth/firebase_auth_status.dart';
import '../l10n/app_localizations.dart';

const _forest = Color(0xFF173B35);
const _sand = Color(0xFFF6F4EF);
Future<void>? _googleSignInInitialization;

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  State<GoogleSignInPage> createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  bool _isSigningIn = false;
  String? _error;

  Future<void> _signIn() async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _isSigningIn = true;
      _error = null;
    });

    try {
      final UserCredential result;
      if (kIsWeb) {
        result = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider(),
        );
      } else {
        await (_googleSignInInitialization ??= GoogleSignIn.instance
            .initialize());
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        final idToken = googleAuth.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw StateError('Google did not return an ID token.');
        }
        result = await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }

      final user = result.user;
      if (user == null) {
        throw StateError('Firebase did not return a signed-in user.');
      }
      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Firebase did not return an ID token.');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on GoogleSignInException catch (exception) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        if (exception.code != GoogleSignInExceptionCode.canceled) {
          _error =
              '${strings.text('تعذر تسجيل الدخول باستخدام Google')}: $exception';
        }
      });
    } on FirebaseAuthException catch (exception) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _error =
            '${strings.text('تعذر تسجيل الدخول باستخدام Google')} (${exception.code})';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _error = '${strings.text('تعذر تسجيل الدخول باستخدام Google')}: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Directionality(
      textDirection: strings.textDirection,
      child: Scaffold(
        backgroundColor: _sand,
        appBar: AppBar(
          backgroundColor: _sand,
          title: Text(strings.text('تسجيل الدخول')),
        ),
        body: SafeArea(
          child: !firebaseAuthReady
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      strings.text('إعداد Firebase مطلوب'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 62,
                      color: _forest,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      strings.text('تسجيل الدخول باستخدام Google'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _forest,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.text('سجّل الدخول بحساب Google للمتابعة.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.text(
                        'رقم الهاتف يُطلب عند نشر الإعلان للتواصل فقط، ولا يحتاج إلى توثيق.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isSigningIn ? null : _signIn,
                        icon: _isSigningIn
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.g_mobiledata, size: 28),
                        label: Text(strings.text('المتابعة باستخدام Google')),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
