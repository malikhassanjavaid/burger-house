import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/data/sample_menu.dart';
import 'package:flutter_application_1/features/home/models/menu_item.dart';
import 'package:flutter_application_1/features/home/widgets/home_hero_carousel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final deals = sampleMenu
      .where(
        (item) => item.id == 'wow-pizza-deal' || item.id == 'wow-burger-deal',
      )
      .toList(growable: false);
  final pizzas = sampleMenu
      .where((item) => item.category == 'Pizzas')
      .toList(growable: false);
  final topPicks = sampleMenu
      .where((item) => item.id == 'beef-wrap' || item.id == 'loaded-fries')
      .toList(growable: false);

  testWidgets('home hero carousel advances every three seconds', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: HomeHeroCarousel(
              deals: deals,
              onDealSelected: (_) {},
              pizzas: pizzas,
              favourites: const {},
              onPizzaSelected: (_) {},
              onFavourite: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Promotion 1 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final homeList = find.byKey(const PageStorageKey('home-content'));
    final hero = find.byType(PageView);
    final initialHeroTop = tester.getTopLeft(hero).dy;
    await tester.drag(homeList, const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(hero).dy, lessThanOrEqualTo(initialHeroTop - 80));

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.bySemanticsLabel('Promotion 2 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('best seller poster returns the selected deal', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    MenuItem? selectedDeal;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: HomeHeroCarousel(
              deals: deals,
              onDealSelected: (deal) => selectedDeal = deal,
              pizzas: pizzas,
              favourites: const {},
              onPizzaSelected: (_) {},
              onFavourite: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Best Sellers \u{1F4A5}'), findsOneWidget);
    expect(find.text('VIEW ALL'), findsNothing);

    final pizzaPoster = find.byKey(
      const ValueKey('deal-poster-wow-pizza-deal'),
    );
    expect(pizzaPoster, findsOneWidget);
    await tester.tap(pizzaPoster);
    await tester.pump();

    expect(selectedDeal?.id, 'wow-pizza-deal');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('home pizza row matches menu card sizing and opens details', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    MenuItem? selectedPizza;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: HomeHeroCarousel(
              deals: deals,
              onDealSelected: (_) {},
              pizzas: pizzas,
              topPicks: topPicks,
              favourites: const {},
              onPizzaSelected: (pizza) => selectedPizza = pizza,
              onFavourite: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('For the Love of Pizza \u{2764}\u{FE0F}'), findsOneWidget);
    final pizzaCard = find.byKey(const ValueKey('home-pizza-cheese-pizza'));
    expect(pizzaCard, findsOneWidget);
    final poster = find.byKey(const ValueKey('deal-poster-wow-pizza-deal'));
    expect(poster, findsOneWidget);
    final posterSize = tester.getSize(poster);
    final cardSize = tester.getSize(pizzaCard);
    expect(cardSize.width, closeTo(posterSize.width, .1));
    expect(cardSize.height, closeTo(cardSize.width / .68, .1));
    expect(cardSize.height, lessThan(posterSize.height));

    await tester.ensureVisible(pizzaCard);
    await tester.pumpAndSettle();
    await tester.tap(pizzaCard);
    await tester.pump();

    expect(selectedPizza?.id, 'cheese-pizza');
    expect(tester.takeException(), isNull);

    final topPicksHeading = find.text('Top Picks');
    await tester.ensureVisible(topPicksHeading);
    await tester.pumpAndSettle();
    expect(topPicksHeading, findsOneWidget);

    final wrapCard = find.byKey(const ValueKey('home-top-pick-beef-wrap'));
    final friesCard = find.byKey(const ValueKey('home-top-pick-loaded-fries'));
    expect(wrapCard, findsOneWidget);
    expect(friesCard, findsOneWidget);

    await tester.ensureVisible(wrapCard);
    await tester.pumpAndSettle();
    await tester.tap(wrapCard);
    await tester.pump();

    expect(selectedPizza?.id, 'beef-wrap');
    expect(tester.takeException(), isNull);

    final bottomBanner = find.byKey(const ValueKey('home-bottom-banner'));
    await tester.ensureVisible(bottomBanner);
    await tester.pumpAndSettle();
    expect(bottomBanner, findsOneWidget);
    expect(tester.getSize(bottomBanner).aspectRatio, closeTo(1776 / 887, .01));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
