import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/data/sample_menu.dart';
import 'package:flutter_application_1/features/home/models/cart_item.dart';
import 'package:flutter_application_1/features/home/models/menu_item.dart';
import 'package:flutter_application_1/features/home/screens/menu_details_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy featured deals match their new default configuration', () {
    final pizzaDeal = sampleMenu.firstWhere(
      (item) => item.id == 'wow-pizza-deal',
    );
    final burgerDeal = sampleMenu.firstWhere(
      (item) => item.id == 'wow-burger-deal',
    );

    final legacyPizza = CartItem(
      menuItem: pizzaDeal,
      quantity: 1,
      unitPrice: pizzaDeal.price,
      size: 'Bundle',
    );
    final configuredPizza = CartItem(
      menuItem: pizzaDeal,
      quantity: 1,
      unitPrice: pizzaDeal.price,
      size: 'Meal Deal',
      addOns: const [
        '2 Medium Pizzas',
        '3 Chilled Drinks',
        'Pizza: Classic Cheese Pizza',
        'Drink: Coke',
      ],
    );
    final legacyBurger = CartItem(
      menuItem: burgerDeal,
      quantity: 1,
      unitPrice: burgerDeal.price,
      size: 'Bundle',
    );
    final configuredBurger = CartItem(
      menuItem: burgerDeal,
      quantity: 1,
      unitPrice: burgerDeal.price,
      size: 'Meal Deal',
      addOns: const [
        '4 Crispy Chicken Burgers',
        '4 Chilled Drinks',
        'Burger: Crispy Chicken Burger',
        'Drink: Coke',
      ],
    );

    expect(legacyPizza.configurationKey, configuredPizza.configurationKey);
    expect(legacyBurger.configurationKey, configuredBurger.configurationKey);
  });

  testWidgets('pizza deal adds the selected pizza flavour and drink', (
    tester,
  ) async {
    final pizzaDeal = sampleMenu.firstWhere(
      (item) => item.id == 'wow-pizza-deal',
    );
    CartItem? addedItem;

    await _openDealDetails(
      tester,
      pizzaDeal,
      onAddToCart: (item) => addedItem = item,
    );

    await _revealDealContents(tester);
    expect(find.text('Choose your pizza flavour'), findsOneWidget);
    if (find.text('Choose your pizza flavour').evaluate().isEmpty) return;
    expect(find.text('Classic Cheese Pizza'), findsOneWidget);
    expect(find.text('Pepperoni Pizza'), findsOneWidget);
    await tester.ensureVisible(find.text('Pepperoni Pizza'));
    await tester.tap(find.text('Pepperoni Pizza'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Choose your drink'));
    expect(find.text('Coke'), findsOneWidget);
    expect(find.text('Sprite'), findsOneWidget);
    if (find.text('Sprite').evaluate().isEmpty) return;
    await tester.ensureVisible(find.text('Sprite'));
    await tester.tap(find.text('Sprite'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ADD TO CART'));
    await tester.pumpAndSettle();

    expect(addedItem?.menuItem.id, 'wow-pizza-deal');
    expect(addedItem?.addOns, [
      '2 Medium Pizzas',
      '3 Chilled Drinks',
      'Pizza: Pepperoni Pizza',
      'Drink: Sprite',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('burger deal keeps Crispy Chicken Burger fixed', (tester) async {
    final burgerDeal = sampleMenu.firstWhere(
      (item) => item.id == 'wow-burger-deal',
    );

    await _openDealDetails(tester, burgerDeal, onAddToCart: (_) {});

    await _revealDealContents(tester);

    expect(find.text('Included burger'), findsOneWidget);
    expect(find.text('Crispy Chicken Burger'), findsOneWidget);
    expect(find.text('Choose your burger'), findsNothing);
    expect(find.text('Included in all 4 burgers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('burger deal adds the selected drink with its fixed burger', (
    tester,
  ) async {
    final burgerDeal = sampleMenu.firstWhere(
      (item) => item.id == 'wow-burger-deal',
    );
    CartItem? addedItem;

    await _openDealDetails(
      tester,
      burgerDeal,
      onAddToCart: (item) => addedItem = item,
    );

    await _revealDealContents(tester);
    expect(find.text('Sprite'), findsOneWidget);
    if (find.text('Sprite').evaluate().isEmpty) return;
    await tester.ensureVisible(find.text('Sprite'));
    await tester.tap(find.text('Sprite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ADD TO CART'));
    await tester.pumpAndSettle();

    expect(addedItem?.addOns, [
      '4 Crispy Chicken Burgers',
      '4 Chilled Drinks',
      'Burger: Crispy Chicken Burger',
      'Drink: Sprite',
    ]);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openDealDetails(
  WidgetTester tester,
  MenuItem deal, {
  required ValueChanged<CartItem> onAddToCart,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(0.8)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MenuDetailsScreen(item: deal, onAddToCart: onAddToCart),
                ),
              ),
              child: const Text('Open deal'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open deal'));
  await tester.pumpAndSettle();
}

Future<void> _revealDealContents(WidgetTester tester) async {
  final details = find.byType(CustomScrollView);
  await tester.drag(details, const Offset(0, -520));
  await tester.pumpAndSettle();
}
