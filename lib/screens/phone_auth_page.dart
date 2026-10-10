import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/firebase_auth_status.dart';
import '../l10n/app_localizations.dart';

const _forest = Color(0xFF173B35);
const _sand = Color(0xFFF6F4EF);

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  ConfirmationResult? _webConfirmation;
  String? _verificationId;
  String? _error;
  int? _resendToken;
  int _resendSeconds = 0;
  bool _consentGiven = false;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _isSigningInWithGoogle = false;
  bool _googleSignInPendingPhone = false;
  bool _codeWasSent = false;
  bool _completed = false;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _googleSignInPendingPhone = _requiresPhoneLink(
      FirebaseAuth.instance.currentUser,
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? _normalizedPhoneNumber() {
    var value = _phoneController.text.trim().replaceAll(RegExp(r'[\s()-]'), '');
    if (value.startsWith('00')) value = '+${value.substring(2)}';
    if (RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(value)) return value;

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (RegExp(r'^01[0125][0-9]{8}$').hasMatch(digits)) {
      return '+20${digits.substring(1)}';
    }
    return null;
  }

  Future<void> _sendCode({bool resend = false}) async {
    final strings = AppLocalizations.of(context);
    if (!_phoneFormKey.currentState!.validate()) return;
    if (!_consentGiven) {
      setState(() => _error = strings.text('وافق على استخدام رقمك للتحقق'));
      return;
    }
    final phoneNumber = _normalizedPhoneNumber();
    if (phoneNumber == null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      if (kIsWeb) {
        final currentUser = FirebaseAuth.instance.currentUser;
        _webConfirmation = _requiresPhoneLink(currentUser)
            ? await currentUser!.linkWithPhoneNumber(phoneNumber)
            : await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);
        _startResendCountdown();
        if (mounted) {
          setState(() {
            _codeWasSent = true;
            _isSending = false;
          });
        }
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (credential) {
          unawaited(_signInWithCredential(credential));
        },
        verificationFailed: (exception) {
          if (!mounted) return;
          setState(() {
            _isSending = false;
            _error = _friendlyAuthError(exception, strings);
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          _verificationId = verificationId;
          _resendToken = resendToken;
          _startResendCountdown();
          setState(() {
            _codeWasSent = true;
            _isSending = false;
            _error = null;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (exception) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = _friendlyAuthError(exception, strings);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = strings.text('تعذر إرسال رمز التحقق، حاول مرة أخرى');
      });
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _verifyCode() async {
    final strings = AppLocalizations.of(context);
    if (!_codeFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      if (kIsWeb) {
        final credential = await _webConfirmation!.confirm(
          _codeController.text.trim(),
        );
        await _finishSignIn(credential.user);
        return;
      }
      final verificationId = _verificationId;
      if (verificationId == null) {
        setState(() {
          _isVerifying = false;
          _error = strings.text('أعد إرسال رمز التحقق');
        });
        return;
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: _codeController.text.trim(),
      );
      final currentUser = FirebaseAuth.instance.currentUser;
      final result = _requiresPhoneLink(currentUser)
          ? await currentUser!.linkWithCredential(credential)
          : await FirebaseAuth.instance.signInWithCredential(credential);
      await _finishSignIn(result.user);
    } on FirebaseAuthException catch (exception) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = _friendlyAuthError(exception, strings);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = strings.text('تعذر التحقق من الرمز، حاول مرة أخرى');
      });
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final result = _requiresPhoneLink(currentUser)
          ? await currentUser!.linkWithCredential(credential)
          : await FirebaseAuth.instance.signInWithCredential(credential);
      await _finishSignIn(result.user);
    } on FirebaseAuthException catch (exception) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _isVerifying = false;
        _error = _friendlyAuthError(exception, AppLocalizations.of(context));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _isVerifying = false;
        _error =
            '${AppLocalizations.of(context).text('تعذر إكمال تسجيل الدخول')}: $error';
      });
    }
  }

  Future<void> _finishSignIn(User? user) async {
    if (!mounted || _completed || user == null) return;
    if (user.phoneNumber == null) {
      setState(() {
        _isSending = false;
        _isVerifying = false;
        _isSigningInWithGoogle = false;
        _googleSignInPendingPhone = true;
        _error = AppLocalizations.of(
          context,
        ).text('اربط رقم هاتف موثق بحسابك لإكمال تسجيل الدخول.');
      });
      return;
    }
    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Firebase did not return an ID token.');
    }
    if (!mounted) return;
    _completed = true;
    Navigator.of(context).pop(true);
  }

  bool _requiresPhoneLink(User? user) =>
      user != null &&
      user.phoneNumber == null &&
      user.providerData.any((provider) => provider.providerId == 'google.com');

  Future<void> _signInWithGoogle() async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _isSigningInWithGoogle = true;
      _error = null;
    });

    try {
      final provider = GoogleAuthProvider();
      final result = kIsWeb
          ? await FirebaseAuth.instance.signInWithPopup(provider)
          : await FirebaseAuth.instance.signInWithProvider(provider);
      await _finishSignIn(result.user);
    } on FirebaseAuthException catch (exception) {
      if (!mounted) return;
      final cancelled =
          exception.code == 'popup-closed-by-user' ||
          exception.code == 'web-context-canceled' ||
          exception.code == 'canceled';
      setState(() {
        _isSigningInWithGoogle = false;
        if (!cancelled) _error = _friendlyAuthError(exception, strings);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSigningInWithGoogle = false;
        _error = '${strings.text('تعذر تسجيل الدخول باستخدام Google')}: $error';
      });
    }
  }

  String _friendlyAuthError(
    FirebaseAuthException exception,
    AppLocalizations strings,
  ) {
    final key = switch (exception.code) {
      'invalid-phone-number' => 'رقم الهاتف غير صحيح',
      'invalid-verification-code' => 'رمز التحقق غير صحيح',
      'session-expired' => 'انتهت صلاحية الرمز، أرسل رمزاً جديداً',
      'too-many-requests' ||
      'quota-exceeded' => 'طلبات كثيرة، انتظر قليلاً ثم حاول مجدداً',
      'network-request-failed' => 'تحقق من اتصال الإنترنت وحاول مرة أخرى',
      'captcha-check-failed' => 'تعذر التحقق الأمني، حاول مرة أخرى',
      'account-exists-with-different-credential' ||
      'credential-already-in-use' =>
        'هذا الرقم أو البريد مرتبط بحساب آخر. سجّل الدخول بالطريقة المرتبط بها الحساب أولاً.',
      _ => 'تعذر تسجيل الدخول، تحقق من بياناتك وحاول مرة أخرى',
    };
    return strings.text(key);
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
              ? _setupRequired(strings)
              : _authForm(strings),
        ),
      ),
    );
  }

  Widget _setupRequired(AppLocalizations strings) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phonelink_lock, size: 58, color: _forest),
          const SizedBox(height: 18),
          Text(
            strings.text('إعداد Firebase مطلوب'),
            style: const TextStyle(
              color: _forest,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.text(
              'لم يتم إعداد Firebase لهذا التطبيق بعد. أضف بيانات Firebase الخاصة بتطبيق Android أو iOS إلى خيارات البناء ثم أعد تشغيل التطبيق.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5, color: Colors.black54),
          ),
        ],
      ),
    ),
  );

  Widget _authForm(AppLocalizations strings) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
    children: [
      const Icon(Icons.mark_email_read_outlined, size: 56, color: _forest),
      const SizedBox(height: 16),
      Text(
        strings.text(
          _googleSignInPendingPhone
              ? 'وثّق رقم هاتفك لإكمال تسجيل Google'
              : 'تحقق من رقم هاتفك',
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _forest,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        strings.text(
          _googleSignInPendingPhone
              ? 'اربط رقم هاتف موثّق بحساب Google حتى تتمكن من استخدام خدمات التطبيق.'
              : 'أرسل رمزاً لمرة واحدة إلى هاتفك لتسجيل الدخول بأمان.',
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54, height: 1.45),
      ),
      const SizedBox(height: 28),
      if (!_codeWasSent && !_googleSignInPendingPhone) ...[
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isSigningInWithGoogle || _isSending
                ? null
                : _signInWithGoogle,
            icon: _isSigningInWithGoogle
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.g_mobiledata, size: 28),
            label: Text(strings.text('المتابعة باستخدام Google')),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(strings.text('أو برقم الهاتف')),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
      ],
      if (!_codeWasSent) ...[
        Form(
          key: _phoneFormKey,
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(
              labelText: strings.text('رقم الهاتف'),
              hintText: '01012345678',
              prefixIcon: const Icon(Icons.phone_android),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (_) => _normalizedPhoneNumber() == null
                ? strings.text(
                    'أدخل رقم مصر بصيغة 01XXXXXXXXX أو الرقم الدولي بصيغة +',
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _consentGiven,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: _isSending || _isSigningInWithGoogle
              ? null
              : (value) => setState(() => _consentGiven = value ?? false),
          title: Text(
            strings.text('أوافق على استخدام رقم الهاتف للتحقق'),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          subtitle: Text(
            strings.text(
              'تُرسل أرقام الهاتف إلى Google وتُخزّن لديها للمساعدة في منع الرسائل المزعجة وإساءة الاستخدام.',
            ),
            style: const TextStyle(fontSize: 11, height: 1.4),
          ),
        ),
        if (_error != null) _errorMessage(_error!),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _isSending || _isSigningInWithGoogle
                ? null
                : () => _sendCode(),
            style: FilledButton.styleFrom(backgroundColor: _forest),
            child: _isSending
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(strings.text('إرسال رمز التحقق')),
          ),
        ),
      ] else ...[
        Text(
          strings.text('أدخل رمز التحقق المكوّن من ٦ أرقام'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Form(
          key: _codeFormKey,
          child: TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              hintText: '••••••',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) => (value?.trim().length ?? 0) != 6
                ? strings.text('أدخل رمز التحقق المكوّن من ٦ أرقام')
                : null,
          ),
        ),
        if (_error != null) _errorMessage(_error!),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _isVerifying ? null : _verifyCode,
            style: FilledButton.styleFrom(backgroundColor: _forest),
            child: _isVerifying
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(strings.text('تأكيد الرمز')),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _resendSeconds == 0 && !_isSending
              ? () => _sendCode(resend: true)
              : null,
          child: Text(
            _resendSeconds == 0
                ? strings.text('إعادة إرسال الرمز')
                : "${strings.text('يمكنك إعادة الإرسال بعد')} ${strings.digits(_resendSeconds)} ${strings.text('ثانية')}",
          ),
        ),
        TextButton(
          onPressed: _isVerifying
              ? null
              : () => setState(() {
                  _codeWasSent = false;
                  _error = null;
                  _codeController.clear();
                }),
          child: Text(strings.text('تغيير رقم الهاتف')),
        ),
      ],
    ],
  );

  Widget _errorMessage(String message) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      message,
      style: const TextStyle(color: Colors.red, fontSize: 13),
    ),
  );
}
