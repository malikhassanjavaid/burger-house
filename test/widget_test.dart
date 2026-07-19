import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app.dart';

void main() {
  testWidgets('Feast Station starts on splash screen', (tester) async {
    await tester.pumpWidget(const FeastStationApp());
    expect(find.text('Your next feast starts here'), findsOneWidget);
    expect(find.text('FEAST STATION'), findsOneWidget);
  });
}
