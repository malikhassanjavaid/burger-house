import 'package:flutter/material.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/widgets/brand_logo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hungry Spot starts on a plain centered splash screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HungrySpotApp());
    await tester.pump(const Duration(milliseconds: 700));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final logoRect = tester.getRect(find.byType(HungrySpotLogo));

    expect(scaffold.backgroundColor, Colors.white);
    expect(find.byType(HungrySpotLogo), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(logoRect.center.dx, closeTo(195, .5));
    expect(logoRect.center.dy, closeTo(422, .5));
    expect(logoRect.width, inInclusiveRange(248, 292));
    expect(tester.takeException(), isNull);
  });
}
