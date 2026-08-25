import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/data/sample_menu.dart';
import 'package:flutter_application_1/features/home/models/cart_item.dart';
import 'package:flutter_application_1/features/home/screens/cart_screen.dart';
import 'package:flutter_application_1/features/home/widgets/restaurant_menu_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menu header and cart summary expose the ordering flow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = TextEditingController();
    final searchFocusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(searchFocusNode.dispose);
    var returnedHome = false;
    var openedCart = false;
    final pizza = sampleMenu.firstWhere((item) => item.id == 'pepperoni-pizza');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SafeArea(
            bottom: false,
            child: RestaurantMenuTab(
              controller: controller,
              searchFocusNode: searchFocusNode,
              searchText: '',
              selectedCategory: 'Pizzas',
              items: sampleMenu,
              favourites: const {},
              cartItems: [
                CartItem(menuItem: pizza, quantity: 2, unitPrice: pizza.price),
              ],
              onBack: () => returnedHome = true,
              onViewCart: () => openedCart = true,
              onChanged: (_) {},
              onClear: () {},
              onCategorySelected: (_) {},
              onOpenItem: (_) {},
              onFavourite: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Explore Menu'), findsOneWidget);
    expect(find.byTooltip('Back to home'), findsOneWidget);
    expect(find.byTooltip('Search menu'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-cart-summary')), findsOneWidget);
    expect(find.text('2 ITEMS'), findsOneWidget);
    expect(find.text(r'$24.98'), findsOneWidget);
    expect(find.text('View Cart'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to home'));
    expect(returnedHome, isTrue);

    await tester.tap(find.byTooltip('Search menu'));
    await tester.pump();
    expect(searchFocusNode.hasFocus, isTrue);

    await tester.tap(find.text('View Cart'));
    expect(openedCart, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty menu cart does not reserve summary space', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = TextEditingController();
    final searchFocusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(searchFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SafeArea(
            bottom: false,
            child: RestaurantMenuTab(
              controller: controller,
              searchFocusNode: searchFocusNode,
              searchText: '',
              selectedCategory: 'Burgers',
              items: sampleMenu,
              favourites: const {},
              cartItems: const [],
              onBack: () {},
              onViewCart: () {},
              onChanged: (_) {},
              onClear: () {},
              onCategorySelected: (_) {},
              onOpenItem: (_) {},
              onFavourite: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('menu-cart-summary')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explore Menu from an empty cart requests the menu page', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    CartScreenExit? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  result = await Navigator.push<CartScreenExit>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(
                        items: const [],
                        deliveryAddress: 'Test address',
                        onCartChanged: (_) {},
                      ),
                    ),
                  );
                },
                child: const Text('Open cart'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore Menu'));
    await tester.pumpAndSettle();

    expect(result, CartScreenExit.exploreMenu);
    expect(find.text('Open cart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
