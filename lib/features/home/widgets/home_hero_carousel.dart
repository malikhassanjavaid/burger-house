import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/fulfillment_method.dart';
import '../models/menu_item.dart';
import 'restaurant_menu_tab.dart';

const _homePosterAspectRatio = 942 / 1672;
const _bestSellerViewportHeight = 252.0;

double _compactHomeCardWidth(double availableWidth) {
  final targetWidth = math.min(availableWidth * .37, 140.0);
  final availableHeight = _bestSellerViewportHeight - 20;
  return math.min(targetWidth, availableHeight * _homePosterAspectRatio);
}

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({
    required this.deals,
    required this.onDealSelected,
    required this.bestSellerBurgers,
    required this.pizzas,
    this.topPicks = const [],
    this.fulfillmentMethod = FulfillmentMethod.delivery,
    this.onFulfillmentChanged,
    required this.favourites,
    required this.onPizzaSelected,
    required this.onFavourite,
    this.customerName = 'Customer',
    this.deliveryLabel = 'Deliver to Home',
    this.onNotificationTap,
    this.onLocationTap,
    super.key,
  });

  final List<MenuItem> deals;
  final ValueChanged<MenuItem> onDealSelected;

  final List<MenuItem> bestSellerBurgers;
  final List<MenuItem> pizzas;
  final List<MenuItem> topPicks;
  final Set<String> favourites;
  final FulfillmentMethod fulfillmentMethod;
  final ValueChanged<FulfillmentMethod>? onFulfillmentChanged;
  final ValueChanged<MenuItem> onPizzaSelected;
  final ValueChanged<MenuItem> onFavourite;
  final String customerName;
  final String deliveryLabel;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;
  static const bannerAssets = [
    'assets/images/home_hero_1_mobile_v2.png',
    'assets/images/home_hero_2_mobile_v2.png',
    'assets/images/home_hero_3_mobile_v2.png',
  ];
  static const bannerBackgroundColors = [
    Color(0xFF180506),
    Color(0xFFFFCB08),
    Color(0xFFE20702),
  ];

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  @override
  Widget build(BuildContext context) {
    final imageCacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return ColoredBox(
      color: Colors.white,
      child: ListView(
        key: const PageStorageKey('home-content'),
        padding: const EdgeInsets.only(bottom: 116),
        physics: const ClampingScrollPhysics(),
        children: [
          _HomeHeader(
            customerName: widget.customerName,
            deliveryLabel: widget.deliveryLabel,
            onNotificationTap: widget.onNotificationTap,
            onLocationTap: widget.onLocationTap,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _FulfillmentSelector(
              selected: widget.fulfillmentMethod,
              onChanged: widget.onFulfillmentChanged,
            ),
          ),
          const SizedBox(height: 16),
          _AutoRotatingHeroBanner(imageCacheWidth: imageCacheWidth),
          const SizedBox(height: 22),
          if (widget.deals.isNotEmpty) ...[
            const _HomeSectionHeading(
              'Featured Deals',
              key: ValueKey('home-featured-deals-heading'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _bestSellerViewportHeight,
              child: _BestSellerPosters(
                deals: widget.deals,
                onDealSelected: widget.onDealSelected,
              ),
            ),
            const SizedBox(height: 26),
          ],
          if (widget.bestSellerBurgers.isNotEmpty) ...[
            const _HomeSectionHeading(
              'Best Seller',
              key: ValueKey('home-best-seller-heading'),
            ),
            const SizedBox(height: 12),
            _HomeMenuRow(
              items: widget.bestSellerBurgers,
              keyPrefix: 'home-best-seller',
              favourites: widget.favourites,
              onItemSelected: widget.onPizzaSelected,
              onFavourite: widget.onFavourite,
            ),
            const SizedBox(height: 26),
          ],
          const _HomeSectionHeading(
            'Pickup from Store',
            key: ValueKey('home-pickup-store-heading'),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Semantics(
              image: true,
              label: 'Order ahead and pick up from a Hungry Spot store',
              child: Container(
                key: const ValueKey('home-pickup-store-poster'),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF0ECEC)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dark.withValues(alpha: .08),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 1983 / 793,
                  child: Image.asset(
                    'assets/images/pickup_store.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    cacheWidth: imageCacheWidth,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          if (widget.pizzas.isNotEmpty) ...[
            const _HomeSectionHeading(
              'For the Love of Pizza \u{2764}\u{FE0F}',
              key: ValueKey('home-pizza-heading'),
            ),
            const SizedBox(height: 12),
            _HomeMenuRow(
              items: widget.pizzas,
              favourites: widget.favourites,
              onItemSelected: widget.onPizzaSelected,
              onFavourite: widget.onFavourite,
            ),
          ],
          if (widget.topPicks.isNotEmpty) ...[
            const SizedBox(height: 26),
            const _HomeSectionHeading(
              'Top Picks',
              key: ValueKey('home-top-picks-heading'),
            ),
            const SizedBox(height: 12),
            _HomeMenuRow(
              items: widget.topPicks,
              keyPrefix: 'home-top-pick',
              favourites: widget.favourites,
              onItemSelected: widget.onPizzaSelected,
              onFavourite: widget.onFavourite,
            ),
          ],
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Semantics(
              image: true,
              label: 'Hungry Spot fast delivery banner',
              child: AspectRatio(
                key: const ValueKey('home-bottom-banner'),
                aspectRatio: 2048 / 683,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/homepage_footer.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    cacheWidth: imageCacheWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.customerName,
    required this.deliveryLabel,
    required this.onNotificationTap,
    required this.onLocationTap,
  });

  final String customerName;
  final String deliveryLabel;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 18, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, $customerName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onLocationTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 1,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.red,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              deliveryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.dark,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (onLocationTap != null) ...[
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Color(0xFF7A7E87),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: 'Open first order offer',
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: AppColors.dark.withValues(alpha: .15),
              child: InkWell(
                key: const ValueKey('home-notification-button'),
                customBorder: const CircleBorder(),
                onTap: onNotificationTap,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: AppColors.dark,
                      ),
                      Positioned(
                        right: 9,
                        top: 8,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoRotatingHeroBanner extends StatefulWidget {
  const _AutoRotatingHeroBanner({required this.imageCacheWidth});

  final int imageCacheWidth;

  @override
  State<_AutoRotatingHeroBanner> createState() =>
      _AutoRotatingHeroBannerState();
}

class _AutoRotatingHeroBannerState extends State<_AutoRotatingHeroBanner>
    with WidgetsBindingObserver {
  static const _initialPage = 900;
  static const _displayDuration = Duration(seconds: 3);
  static const _transitionDuration = Duration(milliseconds: 650);

  late final PageController _controller;
  Timer? _autoSlideTimer;
  int _page = _initialPage;

  int get _visibleIndex => _page % HomeHeroCarousel.bannerAssets.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PageController(initialPage: _initialPage);
    _scheduleNextSlide();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleNextSlide();
    } else {
      _autoSlideTimer?.cancel();
    }
  }

  void _scheduleNextSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(_displayDuration, _showNextBanner);
  }

  void _showNextBanner() {
    if (!mounted || !_controller.hasClients) {
      _scheduleNextSlide();
      return;
    }
    _controller.animateToPage(
      _page + 1,
      duration: _transitionDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  void _handlePageChanged(int page) {
    setState(() => _page = page);
    _scheduleNextSlide();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: AspectRatio(
            aspectRatio: 1.8,
            child: PageView.builder(
              controller: _controller,
              physics: const ClampingScrollPhysics(),
              onPageChanged: _handlePageChanged,
              itemBuilder: (context, page) {
                final bannerIndex = page % HomeHeroCarousel.bannerAssets.length;
                final asset = HomeHeroCarousel.bannerAssets[bannerIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    image: true,
                    label: 'Hungry Spot promotion ${bannerIndex + 1}',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: HomeHeroCarousel
                            .bannerBackgroundColors[bannerIndex],
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.dark.withValues(alpha: .11),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: RepaintBoundary(
                          child: Image.asset(
                            asset,
                            key: ValueKey('home-hero-banner-$bannerIndex'),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.high,
                            gaplessPlayback: true,
                            cacheWidth: widget.imageCacheWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        _HeroPageIndicator(selectedIndex: _visibleIndex),
      ],
    );
  }
}

class _FulfillmentSelector extends StatelessWidget {
  const _FulfillmentSelector({required this.selected, required this.onChanged});

  final FulfillmentMethod selected;
  final ValueChanged<FulfillmentMethod>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('home-fulfillment-selector'),
      width: double.infinity,
      height: 46,
      child: Row(
        children: [
          for (
            var index = 0;
            index < FulfillmentMethod.values.length;
            index++
          ) ...[
            if (index > 0) const SizedBox(width: 10),
            Expanded(
              child: _FulfillmentOption(
                key: ValueKey(
                  'home-${FulfillmentMethod.values[index].firestoreValue}-option',
                ),
                method: FulfillmentMethod.values[index],
                selected: selected == FulfillmentMethod.values[index],
                onTap: selected == FulfillmentMethod.values[index]
                    ? null
                    : () => onChanged?.call(FulfillmentMethod.values[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FulfillmentOption extends StatelessWidget {
  const _FulfillmentOption({
    required this.method,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final FulfillmentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '${method.label} order mode',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.red : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? AppColors.red : const Color(0xFFEDE7E8),
              ),
              boxShadow: [
                BoxShadow(
                  color: (selected ? AppColors.red : AppColors.dark).withValues(
                    alpha: selected ? .18 : .07,
                  ),
                  blurRadius: selected ? 12 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  method.isPickup
                      ? Icons.shopping_bag_outlined
                      : Icons.delivery_dining_rounded,
                  size: 17,
                  color: selected ? Colors.white : AppColors.dark,
                ),
                const SizedBox(width: 7),
                Text(
                  method.label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.dark,
                    fontSize: 11.5,
                    height: 1,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSectionHeading extends StatelessWidget {
  const _HomeSectionHeading(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.dark,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
      ),
    );
  }
}

class _BestSellerPosters extends StatelessWidget {
  const _BestSellerPosters({required this.deals, required this.onDealSelected});

  final List<MenuItem> deals;
  final ValueChanged<MenuItem> onDealSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final posterWidth = _compactHomeCardWidth(constraints.maxWidth);
        final posterHeight = posterWidth / _homePosterAspectRatio;

        return ListView.separated(
          key: const PageStorageKey<String>('home-featured-deals-list'),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          scrollDirection: Axis.horizontal,
          primary: false,
          physics: const ClampingScrollPhysics(),
          itemCount: deals.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final deal = deals[index];
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: posterWidth,
                height: posterHeight,
                child: Semantics(
                  button: true,
                  label: 'Order ${deal.name}',
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.dark.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('deal-poster-${deal.id}'),
                      onTap: () => onDealSelected(deal),
                      child: Image.asset(
                        deal.assetPath,
                        width: posterWidth,
                        height: posterHeight,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeMenuRow extends StatelessWidget {
  const _HomeMenuRow({
    required this.items,
    this.keyPrefix = 'home-pizza',
    required this.favourites,
    required this.onItemSelected,
    required this.onFavourite,
  });

  final List<MenuItem> items;
  final String keyPrefix;
  final Set<String> favourites;
  final ValueChanged<MenuItem> onItemSelected;
  final ValueChanged<MenuItem> onFavourite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = _compactHomeCardWidth(constraints.maxWidth);
        final cardHeight = cardWidth / .68;

        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            key: PageStorageKey<String>('$keyPrefix-list'),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return RepaintBoundary(
                child: SizedBox(
                  key: ValueKey('$keyPrefix-${item.id}'),
                  width: cardWidth,
                  child: RestaurantMenuCard(
                    item: item,
                    favourite: favourites.contains(item.id),
                    onTap: () => onItemSelected(item),
                    onFavourite: () => onFavourite(item),
                    compact: true,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HeroPageIndicator extends StatelessWidget {
  const _HeroPageIndicator({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Promotion ${selectedIndex + 1} of ${HomeHeroCarousel.bannerAssets.length}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(HomeHeroCarousel.bannerAssets.length, (index) {
          final selected = index == selectedIndex;
          return Container(
            width: selected ? 24 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: selected ? AppColors.red : const Color(0xFFD9DDE3),
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}
