import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/widgets/liquid_glass_bottom_nav_bar.dart';

void main() {
  testWidgets('animates the selection and reports destination taps', (
    tester,
  ) async {
    var selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: LiquidGlassBottomNavBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => selectedIndex = index),
              destinations: const [
                GlassNavDestination(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Properties',
                ),
                GlassNavDestination(
                  icon: Icons.groups_outlined,
                  selectedIcon: Icons.groups,
                  label: 'Partnerships',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedPositionedDirectional), findsOneWidget);
    await tester.tap(find.text('Partnerships'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(AnimatedPositionedDirectional), findsOneWidget);
    expect(selectedIndex, 1);
  });

  testWidgets('respects the operating system reduced motion preference', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            bottomNavigationBar: LiquidGlassBottomNavBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: const [
                GlassNavDestination(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Properties',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final indicator = tester.widget<AnimatedPositionedDirectional>(
      find.byType(AnimatedPositionedDirectional),
    );
    expect(indicator.duration, Duration.zero);
  });
}
