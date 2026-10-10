import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const _baytForest = Color(0xFF173B35);

class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A lightweight Liquid Glass-style navigation bar built with Flutter widgets.
/// It works on web and native platforms without requiring Impeller or shaders.
class LiquidGlassBottomNavBar extends StatelessWidget {
  const LiquidGlassBottomNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<GlassNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 420);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _baytForest.withValues(alpha: .12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFCF9).withValues(alpha: .82),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .76),
                        width: 1.2,
                      ),
                    ),
                    child: SizedBox(
                      height: 72,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth =
                              constraints.maxWidth / destinations.length;
                          return Stack(
                            children: [
                              AnimatedPositionedDirectional(
                                duration: duration,
                                curve: Curves.easeInOutCubic,
                                start: itemWidth * selectedIndex,
                                top: 6,
                                bottom: 6,
                                width: itemWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: _baytForest.withValues(alpha: .09),
                                      borderRadius: BorderRadius.circular(21),
                                      border: Border.all(
                                        color: _baytForest.withValues(
                                          alpha: .07,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  for (
                                    var index = 0;
                                    index < destinations.length;
                                    index++
                                  )
                                    Expanded(
                                      child: _GlassNavButton(
                                        destination: destinations[index],
                                        selected: index == selectedIndex,
                                        animationDuration: duration,
                                        onTap: () =>
                                            onDestinationSelected(index),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatelessWidget {
  const _GlassNavButton({
    required this.destination,
    required this.selected,
    required this.animationDuration,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final Duration animationDuration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: destination.label,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.12 : 1,
                  duration: animationDuration,
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: animationDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      key: ValueKey(selected),
                      color: selected ? _baytForest : const Color(0xFF59635F),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: animationDuration,
                  curve: Curves.easeInOutCubic,
                  style: TextStyle(
                    color: selected ? _baytForest : const Color(0xFF59635F),
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: AnimatedSlide(
                    duration: animationDuration,
                    curve: Curves.easeOutCubic,
                    offset: selected ? Offset.zero : const Offset(0, .08),
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : .82,
                      duration: animationDuration,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(destination.label, maxLines: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
