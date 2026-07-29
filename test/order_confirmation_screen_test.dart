import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/models/fulfillment_method.dart';
import 'package:flutter_application_1/features/home/screens/order_confirmation_screen.dart';
import 'package:flutter_application_1/features/home/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('delivery confirmation shows clean status and ETA flow', (
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
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Estimated delivery time'), findsOneWidget);
    expect(find.text('30–40 min'), findsOneWidget);
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('confirmation-success-panel')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pickup confirmation ends with ready status', (tester) async {
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
    expect(find.text('Estimated pickup time'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('On the way'), findsNothing);
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
