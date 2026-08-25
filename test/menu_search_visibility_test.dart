import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/data/sample_menu.dart';
import 'package:flutter_application_1/features/home/widgets/restaurant_menu_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menu search stays hidden until the header action is tapped', (
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

    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byTooltip('Search menu'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(searchFocusNode.hasFocus, isTrue);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(searchFocusNode.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });
}
