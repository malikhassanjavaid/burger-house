import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/data/sample_menu.dart';
import 'package:flutter_application_1/features/home/widgets/restaurant_menu_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menu defaults to burgers and switches categories', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var selectedCategory = 'Burgers';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: StatefulBuilder(
              builder: (context, setState) {
                return RestaurantMenuTab(
                  controller: controller,
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
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Burgers'), findsOneWidget);
    expect(find.text('Classic Smash'), findsOneWidget);
    expect(find.text('Classic Cheese Pizza'), findsNothing);

    await tester.tap(find.text('Pizza'));
    await tester.pumpAndSettle();

    expect(find.text('Pizzas'), findsOneWidget);
    expect(find.text('Classic Cheese Pizza'), findsOneWidget);
    expect(find.text('Classic Smash'), findsNothing);
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
    addTearDown(controller.dispose);
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
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'oreo');
    await tester.pump();

    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('Oreo Shake'), findsOneWidget);
    expect(find.text('Classic Smash'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
