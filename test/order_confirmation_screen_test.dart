import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/models/fulfillment_method.dart';
import 'package:flutter_application_1/features/home/screens/order_confirmation_screen.dart';
import 'package:flutter_application_1/features/home/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('confirmed order shows its number, ETA, and destination', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const order = PlacedOrder(
      id: 'order-id',
      orderNumber: 'HS-ABC1234',
      etaMinMinutes: 30,
      etaMaxMinutes: 40,
      deliveryAddress: 'Main Street, Test Area',
      total: 25.50,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const OrderConfirmationScreen(order: order),
      ),
    );
    await tester.pump();

    expect(find.text('Order confirmed!'), findsOneWidget);
    expect(find.textContaining('HS-ABC1234'), findsOneWidget);
    expect(find.textContaining('30'), findsOneWidget);
    expect(find.textContaining('40 min'), findsOneWidget);
    expect(find.text('Main Street, Test Area'), findsOneWidget);
    expect(find.text('VIEW MY ORDERS'), findsOneWidget);
    expect(find.text('BACK TO HOME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pickup confirmation shows ready-to-collect journey', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const order = PlacedOrder(
      id: 'pickup-order-id',
      orderNumber: 'HS-PICKUP1',
      etaMinMinutes: 30,
      etaMaxMinutes: 40,
      deliveryAddress: 'Hungry Spot Main Store, Main pickup counter',
      total: 18.50,
      fulfillmentMethod: FulfillmentMethod.pickup,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const OrderConfirmationScreen(order: order),
      ),
    );
    await tester.pump();

    expect(find.text('Pickup confirmed!'), findsOneWidget);
    expect(find.text('ESTIMATED READY TIME'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('PICKUP FROM'), findsOneWidget);
    expect(find.text('PAY AT PICKUP'), findsOneWidget);
    expect(find.textContaining('Main Store'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
