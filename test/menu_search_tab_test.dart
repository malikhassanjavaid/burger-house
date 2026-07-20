import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/home/data/sample_menu.dart';
import 'package:flutter_application_1/features/home/widgets/menu_search_tab.dart';

void main() {
  testWidgets('search tab renders empty and result states on a phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    Widget buildSearch({required String query}) {
      controller.text = query;
      final items = query.isEmpty
          ? sampleMenu
          : sampleMenu
                .where(
                  (item) => item.category.toLowerCase() == query.toLowerCase(),
                )
                .toList();
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: MenuSearchTab(
              controller: controller,
              searchText: query,
              items: items,
              favourites: const {},
              onChanged: (_) {},
              onClear: () {},
              onBack: () {},
              onOpenItem: (_) {},
              onFavourite: (_) {},
              onAdd: (_) {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSearch(query: ''));
    expect(find.text("What's your pick?"), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(buildSearch(query: 'Burgers'));
    await tester.pump();
    expect(find.text('Your picks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
