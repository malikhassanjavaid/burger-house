import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app.dart';

void main() {
  testWidgets('Burger House starts on splash screen', (tester) async {
    await tester.pumpWidget(const BurgerHouseApp());
    expect(find.text('BURGER HOUSE'), findsOneWidget);
    expect(find.text('Fresh. Fast. Delicious.'), findsOneWidget);
  });
}
