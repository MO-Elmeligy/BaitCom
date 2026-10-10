import 'package:flutter/material.dart';

/// Compact version of the shared Bayt Co brand mark.
class BaytCoLogo extends StatelessWidget {
  const BaytCoLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'شعار بيت كو',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .2),
      child: Image.asset(
        'assets/brand/bayt_co_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF173B35)),
            child: Icon(
              Icons.home_work_rounded,
              color: const Color(0xFFF6F4EF),
              size: size * .55,
            ),
          ),
        ),
      ),
    ),
  );
}
