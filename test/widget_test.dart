import 'package:flutter_test/flutter_test.dart';

import 'package:real_estate_app/main.dart';

void main() {
  testWidgets('Home shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(const BaytCoApp());
    expect(find.text('بيت كو'), findsWidgets);
    expect(find.text('عقارات مميزة'), findsOneWidget);
  });
}
