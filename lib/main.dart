import 'package:flutter/material.dart';

import 'screens/home_page.dart';

const forest = Color(0xFF173B35);
const sand = Color(0xFFF6F4EF);

void main() => runApp(const BaytCoApp());

class BaytCoApp extends StatelessWidget {
  const BaytCoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'بيت كو',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: forest),
          scaffoldBackgroundColor: sand,
        ),
        home: const InteractiveHomePage(),
      );
}
