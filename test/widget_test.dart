import 'package:flutter_test/flutter_test.dart';

import 'package:real_estate_app/main.dart';

void main() {
  testWidgets('Home shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(const RealEstateApp());
    expect(find.text('عقار كراود'), findsWidgets);
    expect(find.text('عقارات مميزة'), findsOneWidget);
  });
}
