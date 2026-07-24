import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/menu_item.dart';
import 'restaurant_menu_tab.dart';

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({
    required this.deals,
    required this.onDealSelected,
    required this.pizzas,
    required this.favourites,
    required this.onPizzaSelected,
    required this.onFavourite,
    super.key,
  });

  final List<MenuItem> deals;
  final ValueChanged<MenuItem> onDealSelected;

  final List<MenuItem> pizzas;
  final Set<String> favourites;
  final ValueChanged<MenuItem> onPizzaSelected;
  final ValueChanged<MenuItem> onFavourite;
  static const bannerAssets = [
    'assets/images/home_hero_1.png',
    'assets/images/home_hero_2.png',
    'assets/images/home_hero_3.png',
  ];

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel>
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
    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AspectRatio(
                  aspectRatio: 2.25,
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: _handlePageChanged,
                    itemBuilder: (context, page) {
                      final asset =
                          HomeHeroCarousel.bannerAssets[page %
                              HomeHeroCarousel.bannerAssets.length];
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final currentPage =
                              _controller.hasClients &&
                                  _controller.position.hasContentDimensions
                              ? (_controller.page ?? _page.toDouble())
                              : _page.toDouble();
                          final distance = (currentPage - page).abs().clamp(
                            0.0,
                            1.0,
                          );
                          return Opacity(
                            opacity: 1 - (distance * .2),
                            child: Transform.scale(
                              scale: 1 - (distance * .035),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Semantics(
                            image: true,
                            label:
                                'Hungry Spot promotion ${page % HomeHeroCarousel.bannerAssets.length + 1}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: RepaintBoundary(
                                child: Image.asset(
                                  asset,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  gaplessPlayback: true,
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
              const SizedBox(height: 13),
              _HeroPageIndicator(selectedIndex: _visibleIndex),
              Expanded(
                child: ListView(
                  key: const PageStorageKey('home-content'),
                  padding: const EdgeInsets.only(top: 22, bottom: 116),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (widget.deals.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          'Best Sellers \u{1F4A5}',
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 252,
                        child: _BestSellerPosters(
                          deals: widget.deals,
                          onDealSelected: widget.onDealSelected,
                        ),
                      ),
                      const SizedBox(height: 26),
                    ],
                    if (widget.pizzas.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          'For the Love of Pizza \u{2764}\u{FE0F}',
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HomePizzaRow(
                        pizzas: widget.pizzas,
                        favourites: widget.favourites,
                        onPizzaSelected: widget.onPizzaSelected,
                        onFavourite: widget.onFavourite,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
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
        const posterAspectRatio = 942 / 1672;
        final targetWidth = math.min(constraints.maxWidth * .37, 140.0);
        final availableHeight = math.max(0.0, constraints.maxHeight - 20);
        final posterWidth = math.min(
          targetWidth,
          availableHeight * posterAspectRatio,
        );
        final posterHeight = posterWidth / posterAspectRatio;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
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

class _HomePizzaRow extends StatelessWidget {
  const _HomePizzaRow({
    required this.pizzas,
    required this.favourites,
    required this.onPizzaSelected,
    required this.onFavourite,
  });

  final List<MenuItem> pizzas;
  final Set<String> favourites;
  final ValueChanged<MenuItem> onPizzaSelected;
  final ValueChanged<MenuItem> onFavourite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 2;
        final cardHeight = cardWidth / .57;

        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: pizzas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final pizza = pizzas[index];
              return SizedBox(
                key: ValueKey('home-pizza-${pizza.id}'),
                width: cardWidth,
                child: RestaurantMenuCard(
                  item: pizza,
                  favourite: favourites.contains(pizza.id),
                  onTap: () => onPizzaSelected(pizza),
                  onFavourite: () => onFavourite(pizza),
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
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
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
