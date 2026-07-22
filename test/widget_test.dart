import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/widgets/brand_logo.dart';

void main() {
  testWidgets('Hungry Spot starts on branded splash screen', (tester) async {
    await tester.pumpWidget(const HungrySpotApp());
    expect(find.byType(HungrySpotLogo), findsOneWidget);
  });
}
