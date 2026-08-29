import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/home/data/sample_menu.dart';
import 'package:flutter_application_1/features/home/widgets/restaurant_menu_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('food card compresses and gives selection feedback when opened', (
    tester,
  ) async {
    var opens = 0;
    final platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final item = sampleMenu.firstWhere((item) => item.id == 'classic-smash');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 190,
              height: 280,
              child: RestaurantMenuCard(
                item: item,
                favourite: false,
                onTap: () => opens++,
                onFavourite: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final card = find.byType(RestaurantMenuCard);
    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 100));

    final scale = find.descendant(
      of: card,
      matching: find.byType(AnimatedScale),
    );
    expect(scale, findsOneWidget);
    expect(tester.widget<AnimatedScale>(scale).scale, .97);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(opens, 1);
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
    final hapticCalls = platformCalls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .toList();
    expect(hapticCalls, hasLength(1));
    expect(hapticCalls.single.arguments, 'HapticFeedbackType.selectionClick');
  });

  testWidgets('menu groups all categories in homepage-sized rows', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = TextEditingController();
    final searchFocusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(searchFocusNode.dispose);
    var selectedCategory = 'Burgers';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: StatefulBuilder(
              builder: (context, setState) {
                return RestaurantMenuTab(
                  controller: controller,
                  searchFocusNode: searchFocusNode,
                  searchText: '',
                  selectedCategory: selectedCategory,
                  items: sampleMenu,
                  favourites: const {},
                  onChanged: (_) {},
                  onClear: () {},
                  onCategorySelected: (category) {
                    setState(() => selectedCategory = category);
                  },
                  onOpenItem: (_) {},
                  onFavourite: (_) {},
                  cartItems: const [],
                  onBack: () {},
                  onViewCart: () {},
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Burgers'), findsOneWidget);
    expect(find.text('Pizzas'), findsOneWidget);
    expect(find.text('Classic Smash'), findsOneWidget);
    expect(find.text('Classic Cheese Pizza'), findsOneWidget);

    final burgerCard = find.byKey(const ValueKey('menu-burgers-classic-smash'));
    final burgerCardSize = tester.getSize(burgerCard);
    expect(burgerCardSize.width / burgerCardSize.height, closeTo(.68, .01));

    await tester.tap(find.text('Pizza'));
    await tester.pumpAndSettle();

    final pizzaCard = find.byKey(const ValueKey('menu-pizzas-cheese-pizza'));
    expect(
      tester.getTopLeft(pizzaCard).dy,
      lessThan(tester.getTopLeft(burgerCard).dy),
    );
    expect(find.text('Classic Smash'), findsOneWidget);
    expect(find.text('Classic Cheese Pizza'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu search shows matching items across categories', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = TextEditingController();
    final searchFocusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(searchFocusNode.dispose);
    var query = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: StatefulBuilder(
              builder: (context, setState) {
                final matches = sampleMenu.where((item) {
                  final searchable =
                      '${item.name} ${item.description} ${item.category}'
                          .toLowerCase();
                  return query.isEmpty || searchable.contains(query);
                }).toList();
                return RestaurantMenuTab(
                  controller: controller,
                  searchFocusNode: searchFocusNode,
                  searchText: query,
                  selectedCategory: 'Burgers',
                  items: matches,
                  favourites: const {},
                  onChanged: (value) {
                    setState(() => query = value.trim().toLowerCase());
                  },
                  onClear: () => setState(() => query = ''),
                  onCategorySelected: (_) {},
                  onOpenItem: (_) {},
                  onFavourite: (_) {},
                  cartItems: const [],
                  onBack: () {},
                  onViewCart: () {},
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Search menu'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'oreo');
    await tester.pump();

    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('Oreo Shake'), findsOneWidget);
    expect(find.text('Classic Smash'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
