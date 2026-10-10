import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'home_page.dart';
import '../widgets/bayt_co_logo.dart';

class LaunchFlow extends StatefulWidget {
  const LaunchFlow({super.key});

  @override
  State<LaunchFlow> createState() => _LaunchFlowState();
}

class _LaunchFlowState extends State<LaunchFlow> {
  bool _showSplash = true;

  void _continueToApp() {
    if (!mounted || !_showSplash) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showSplash
            ? LaunchSplash(
                key: const ValueKey('splash'), onFinished: _continueToApp)
            : const InteractiveHomePage(key: ValueKey('home')),
      );
}

class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: .88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2300), widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF214B40), Color(0xFF102B27), Color(0xFF081B19)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              right: -100,
              child: _Glow(size: 330, opacity: .12),
            ),
            const Positioned(
              bottom: -160,
              left: -130,
              child: _Glow(size: 390, opacity: .08),
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFC9B98A)
                                  .withValues(alpha: .55),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .2),
                                blurRadius: 35,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: const BaytCoLogo(size: 132),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'BaitCo',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: Color(0xFFF6F4EF),
                            fontSize: 36,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'بيت كو',
                          style: TextStyle(
                            color: Color(0xFFF6F4EF),
                            fontSize: 34,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: 44,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9B98A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          strings.text('مفتاحك لبيت مستدام'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .78),
                            fontSize: 14,
                            letterSpacing: .2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Text(
                strings.text('العقارات تبدأ من هنا'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .52),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF8BAA83).withValues(alpha: opacity),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
}
