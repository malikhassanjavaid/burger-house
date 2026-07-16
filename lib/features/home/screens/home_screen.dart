import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../auth/services/auth_service.dart';
import '../data/sample_menu.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import 'cart_screen.dart';
import 'menu_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _authService = AuthService();
  final Set<String> _favourites = {};

  List<CartItem> _cartItems = [];
  String _searchText = '';
  String _selectedCategory = 'All';
  final String _address = 'House 24, Main Boulevard';
  int _selectedTab = 0;

  int get _cartCount =>
      _cartItems.fold(0, (totalCount, item) => totalCount + item.quantity);

  List<MenuItem> get _filteredItems {
    final query = _searchText.toLowerCase();
    return sampleMenu.where((item) {
      final searchMatches =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return searchMatches;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addQuickItem(MenuItem item) {
    _addCartItem(CartItem(menuItem: item, quantity: 1, unitPrice: item.price));
  }

  void _addCartItem(CartItem cartItem) {
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.configurationKey == cartItem.configurationKey,
      );
      if (index == -1) {
        _cartItems.add(cartItem);
      } else {
        final existing = _cartItems[index];
        _cartItems[index] = existing.copyWith(
          quantity: existing.quantity + cartItem.quantity,
        );
      }
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${cartItem.menuItem.name} added to cart'),
          action: SnackBarAction(label: 'VIEW', onPressed: _openCart),
        ),
      );
  }

  Future<void> _openDetails(MenuItem item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MenuDetailsScreen(item: item, onAddToCart: _addCartItem),
      ),
    );
  }

  Future<void> _openCart() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          items: _cartItems,
          deliveryAddress: _address,
          onCartChanged: (items) => setState(() => _cartItems = items),
        ),
      ),
    );
  }

  void _toggleFavourite(MenuItem item) {
    setState(() {
      if (!_favourites.add(item.id)) _favourites.remove(item.id);
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeItems = sampleMenu.where((item) {
      return _selectedCategory == 'All' || item.category == _selectedCategory;
    }).toList();

    final pages = <int, Widget>{
      0: _HomeTab(
        selectedCategory: _selectedCategory,
        items: homeItems,
        favourites: _favourites,
        onCategorySelected: (category) =>
            setState(() => _selectedCategory = category),
        onOpenItem: _openDetails,
        onFavourite: _toggleFavourite,
        onAdd: _addQuickItem,
      ),
      2: _SearchTab(
        controller: _searchController,
        searchText: _searchText,
        items: _filteredItems,
        favourites: _favourites,
        onChanged: (value) => setState(() => _searchText = value.trim()),
        onClear: () {
          _searchController.clear();
          setState(() => _searchText = '');
        },
        onOpenItem: _openDetails,
        onFavourite: _toggleFavourite,
        onAdd: _addQuickItem,
      ),
      3: _SavedTab(
        items: sampleMenu
            .where((item) => _favourites.contains(item.id))
            .toList(),
        favourites: _favourites,
        onOpenItem: _openDetails,
        onFavourite: _toggleFavourite,
        onAdd: _addQuickItem,
        onBrowse: () => setState(() => _selectedTab = 0),
      ),
      4: _AccountTab(onSignOut: _signOut),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(bottom: false, child: pages[_selectedTab] ?? pages[0]!),
      bottomNavigationBar: _MinimalBottomBar(
        selectedIndex: _selectedTab,
        cartCount: _cartCount,
        onSelected: (index) {
          if (index == 1) {
            _openCart();
          } else {
            setState(() => _selectedTab = index);
          }
        },
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.selectedCategory,
    required this.items,
    required this.favourites,
    required this.onCategorySelected,
    required this.onOpenItem,
    required this.onFavourite,
    required this.onAdd,
  });

  final String selectedCategory;
  final List<MenuItem> items;
  final Set<String> favourites;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<MenuItem> onOpenItem;
  final ValueChanged<MenuItem> onFavourite;
  final ValueChanged<MenuItem> onAdd;

  static const _categories = [
    'All',
    'Burgers',
    'Sides',
    'Drinks',
    'Desserts',
    'Deals',
  ];

  @override
  Widget build(BuildContext context) {
    final bestSellers = sampleMenu
        .where((item) => item.isPopular)
        .take(3)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Taste the Crunch\nof Happiness',
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 27,
                          height: 1.02,
                          letterSpacing: -.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFECE7E2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .05),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You have no new notifications.'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: bestSellers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, index) {
                      final item = bestSellers[index];
                      return _BestSellerCard(
                        item: item,
                        index: index,
                        onTap: () => onOpenItem(item),
                        onAdd: () => onAdd(item),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 66,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (_, index) {
                final category = _categories[index];
                final selected = category == selectedCategory;
                return _HomeCategory(
                  label: category,
                  selected: selected,
                  icon: _categoryIcon(category),
                  onTap: () => onCategorySelected(category),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Suggested Food',
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onCategorySelected('All'),
                  child: const Text(
                    'See All',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
          sliver: items.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoMenuResults(),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: .66,
                  ),
                  delegate: SliverChildBuilderDelegate((_, index) {
                    final item = items[index];
                    return _SuggestedFoodCard(
                      item: item,
                      favourite: favourites.contains(item.id),
                      onTap: () => onOpenItem(item),
                      onFavourite: () => onFavourite(item),
                      onAdd: () => onAdd(item),
                    );
                  }, childCount: items.length),
                ),
        ),
      ],
    );
  }

  static IconData _categoryIcon(String category) {
    return switch (category) {
      'Burgers' => Icons.lunch_dining_rounded,
      'Sides' => Icons.fastfood_rounded,
      'Drinks' => Icons.local_drink_rounded,
      'Desserts' => Icons.icecream_rounded,
      'Deals' => Icons.local_offer_rounded,
      _ => Icons.apps_rounded,
    };
  }
}

class _BestSellerCard extends StatelessWidget {
  const _BestSellerCard({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onAdd,
  });

  final MenuItem item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  static const _gradients = [
    [Color(0xFFFFD45A), Color(0xFFFFB62E)],
    [Color(0xFFFF765E), Color(0xFFF34A32)],
    [Color(0xFF9BE0B4), Color(0xFF54C984)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];
    final darkText = index != 1;
    final foreground = darkText ? AppColors.dark : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 270,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: .25),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -52,
                top: -48,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: -25,
                top: 43,
                child: Transform.rotate(
                  angle: -.04,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .20),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _FoodArtwork(item: item, width: 165, height: 165),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFA800),
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 118,
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        height: 1.08,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 112,
                    child: Text(
                      item.category,
                      style: TextStyle(
                        color: foreground.withValues(alpha: .68),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatUsd(item.price),
                    style: TextStyle(
                      color: darkText ? AppColors.dark : Colors.white,
                      fontSize: 29,
                      height: 1,
                      letterSpacing: -.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 40,
                      child: FilledButton(
                        onPressed: onAdd,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.dark,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Add Now',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCategory extends StatelessWidget {
  const _HomeCategory({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF53CF7C) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF53CF7C) : const Color(0xFFE8E3DE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: .22)
                    : const Color(0xFFF7F4F1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : AppColors.dark,
              ),
            ),
            if (!selected) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestedFoodCard extends StatelessWidget {
  const _SuggestedFoodCard({
    required this.item,
    required this.favourite,
    required this.onTap,
    required this.onFavourite,
    required this.onAdd,
  });

  final MenuItem item;
  final bool favourite;
  final VoidCallback onTap;
  final VoidCallback onFavourite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEE9E5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEE2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: _FoodArtwork(
                          item: item,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: InkWell(
                          onTap: onAdd,
                          child: Container(
                            width: 27,
                            height: 27,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 17),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 9, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB000),
                          size: 15,
                        ),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatUsd(item.price),
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onFavourite,
                          child: Icon(
                            favourite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: favourite
                                ? Colors.redAccent
                                : AppColors.dark,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodArtwork extends StatelessWidget {
  const _FoodArtwork({
    required this.item,
    required this.width,
    required this.height,
  });

  final MenuItem item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (item.category == 'Burgers') {
      return Image.asset(
        'assets/images/beefburger-cutout.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(item.emoji, style: const TextStyle(fontSize: 62)),
        ),
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab({
    required this.controller,
    required this.searchText,
    required this.items,
    required this.favourites,
    required this.onChanged,
    required this.onClear,
    required this.onOpenItem,
    required this.onFavourite,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String searchText;
  final List<MenuItem> items;
  final Set<String> favourites;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<MenuItem> onOpenItem;
  final ValueChanged<MenuItem> onFavourite;
  final ValueChanged<MenuItem> onAdd;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Find something delicious from BurgerHouse',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: searchText.isEmpty,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search burgers, sides and drinks',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchText.isEmpty
                        ? null
                        : IconButton(
                            onPressed: onClear,
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (searchText.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _SearchPrompt(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
            sliver: items.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoMenuResults(),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          childAspectRatio: .70,
                        ),
                    delegate: SliverChildBuilderDelegate((_, index) {
                      final item = items[index];
                      return _PremiumFoodCard(
                        item: item,
                        favourite: favourites.contains(item.id),
                        onTap: () => onOpenItem(item),
                        onFavourite: () => onFavourite(item),
                        onAdd: () => onAdd(item),
                      );
                    }, childCount: items.length),
                  ),
          ),
      ],
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 62, color: AppColors.muted),
            SizedBox(height: 12),
            Text(
              'Search the BurgerHouse menu',
              style: TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumFoodCard extends StatelessWidget {
  const _PremiumFoodCard({
    required this.item,
    required this.favourite,
    required this.onTap,
    required this.onFavourite,
    required this.onAdd,
  });

  final MenuItem item;
  final bool favourite;
  final VoidCallback onTap;
  final VoidCallback onFavourite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF0E9E4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .055),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF2E7), Color(0xFFFFDFC3)],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 67),
                        ),
                      ),
                      if (item.oldPrice != null)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dark,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Text(
                              'DEAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 4, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFA800),
                          size: 16,
                        ),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatUsd(item.price),
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: FilledButton(
                              onPressed: onAdd,
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Add',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        InkWell(
                          onTap: onFavourite,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              favourite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: favourite
                                  ? Colors.redAccent
                                  : AppColors.dark,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9A43), AppColors.orange],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              (user?.displayName?.isNotEmpty ?? false)
                  ? user!.displayName![0].toUpperCase()
                  : 'B',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          user?.displayName ?? 'BurgerHouse Customer',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 30),
        _AccountTile(
          icon: Icons.location_on_outlined,
          title: 'Delivery addresses',
          subtitle: 'Manage your saved locations',
          onTap: () {},
        ),
        _AccountTile(
          icon: Icons.support_agent_outlined,
          title: 'Help and support',
          subtitle: 'Get help with your orders',
          onTap: () {},
        ),
        _AccountTile(
          icon: Icons.logout_rounded,
          title: 'Sign out',
          subtitle: 'Sign out of your BurgerHouse account',
          onTap: onSignOut,
          destructive: true,
        ),
      ],
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab({
    required this.items,
    required this.favourites,
    required this.onOpenItem,
    required this.onFavourite,
    required this.onAdd,
    required this.onBrowse,
  });

  final List<MenuItem> items;
  final Set<String> favourites;
  final ValueChanged<MenuItem> onOpenItem;
  final ValueChanged<MenuItem> onFavourite;
  final ValueChanged<MenuItem> onAdd;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _MessagePage(
        icon: Icons.favorite_border_rounded,
        title: 'Nothing saved yet',
        message: 'Tap the heart on food you want to find quickly.',
        actionLabel: 'Browse menu',
        onAction: onBrowse,
      );
    }

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 24, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved items',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your BurgerHouse favourites',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: .70,
            ),
            delegate: SliverChildBuilderDelegate((_, index) {
              final item = items[index];
              return _PremiumFoodCard(
                item: item,
                favourite: favourites.contains(item.id),
                onTap: () => onOpenItem(item),
                onFavourite: () => onFavourite(item),
                onAdd: () => onAdd(item),
              );
            }, childCount: items.length),
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Icon(
            icon,
            color: destructive ? Colors.redAccent : AppColors.orange,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: destructive ? Colors.redAccent : AppColors.dark,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _MessagePage extends StatelessWidget {
  const _MessagePage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE5CE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.orange),
            ),
            const SizedBox(height: 22),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoMenuResults extends StatelessWidget {
  const _NoMenuResults();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.muted),
          SizedBox(height: 10),
          Text(
            'No food matched your search',
            style: TextStyle(
              color: AppColors.dark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalBottomBar extends StatelessWidget {
  const _MinimalBottomBar({
    required this.selectedIndex,
    required this.cartCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 72 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFECECEC))),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .07),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          _MinimalNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _MinimalNavItem(
            icon: Icons.shopping_cart_outlined,
            selectedIcon: Icons.shopping_cart_rounded,
            badgeCount: cartCount,
            selected: false,
            onTap: () => onSelected(1),
          ),
          _MinimalNavItem(
            icon: Icons.search_rounded,
            selectedIcon: Icons.search_rounded,
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          _MinimalNavItem(
            icon: Icons.favorite_border_rounded,
            selectedIcon: Icons.favorite_rounded,
            selected: selectedIndex == 3,
            onTap: () => onSelected(3),
          ),
          _MinimalNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            selected: selectedIndex == 4,
            onTap: () => onSelected(4),
          ),
        ],
      ),
    );
  }
}

class _MinimalNavItem extends StatelessWidget {
  const _MinimalNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .18),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Badge(
              isLabelVisible: badgeCount > 0,
              backgroundColor: AppColors.orange,
              label: Text('$badgeCount'),
              child: Icon(
                selected ? selectedIcon : icon,
                color: selected ? Colors.white : Colors.black87,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
