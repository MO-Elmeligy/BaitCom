import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/firebase_auth_status.dart';
import 'l10n/app_localizations.dart';
import 'screens/launch_splash.dart';

const forest = Color(0xFF173B35);
const sand = Color(0xFFF6F4EF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseAuth();
  runApp(const BaytCoApp());
}

class BaytCoApp extends StatelessWidget {
  const BaytCoApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale?>(
    valueListenable: appLocale,
    builder: (context, locale, _) => MaterialApp(
      title: 'بيت كو',
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: forest),
        scaffoldBackgroundColor: sand,
      ),
      home: const LaunchFlow(),
    ),
  );
}
