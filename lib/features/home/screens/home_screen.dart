import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../auth/services/auth_service.dart';
import '../../location/models/delivery_location.dart';
import '../data/sample_menu.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../services/customer_data_service.dart';
import '../widgets/home_hero_carousel.dart';
import '../widgets/profile_tab.dart';
import '../widgets/restaurant_menu_tab.dart';
import 'cart_screen.dart';
import 'menu_details_screen.dart';
import 'profile_address_screen.dart';
import 'profile_details_screen.dart';
import 'profile_orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.showNewAccountWelcome = false,
    this.welcomeName,
    super.key,
  });

  final bool showNewAccountWelcome;
  final String? welcomeName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _authService = AuthService();
  final _customerDataService = CustomerDataService();
  final Set<String> _favourites = {};

  List<CartItem> _cartItems = [];
  Future<void> _cartWriteQueue = Future<void>.value();
  Future<void> _favouritesWriteQueue = Future<void>.value();
  String _searchText = '';
  String _selectedMenuCategory = 'Burgers';
  DeliveryLocation? _deliveryLocation;
  String _address = 'Set your delivery address';
  int _selectedTab = 0;
  bool _restoringCustomerState = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDeliveryLocation());
    unawaited(_restoreCustomerState());
    if (widget.showNewAccountWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final firstName = (widget.welcomeName ?? '').trim().split(' ').first;
        showGeneralDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierLabel: 'Welcome to Hungry Spot',
          barrierColor: Colors.black.withValues(alpha: .58),
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, _, _) =>
              _NewCustomerWelcomeDialog(firstName: firstName),
          transitionBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curved, child: child),
            );
          },
        );
      });
    }
  }

  Future<void> _loadDeliveryLocation() async {
    try {
      final location = await _authService.getDeliveryLocation();
      if (!mounted || location == null) return;
      setState(() {
        _deliveryLocation = location;
        _address = location.formattedAddress;
      });
    } catch (_) {
      // The home screen remains usable if the saved address cannot be loaded.
    }
  }

  Future<void> _restoreCustomerState() async {
    try {
      final customerState = await _customerDataService.loadState();
      if (!mounted) return;
      setState(() {
        _cartItems = List.of(customerState.cartItems);
        _favourites
          ..clear()
          ..addAll(customerState.favouriteIds);
      });
    } catch (_) {
      // A cached or temporary empty state keeps the menu usable. Future cart
      // changes will retry the Firestore write automatically.
    } finally {
      if (mounted) setState(() => _restoringCustomerState = false);
    }
  }

  int get _cartCount =>
      _cartItems.fold(0, (totalCount, item) => totalCount + item.quantity);

  List<MenuItem> get _filteredItems {
    final query = _searchText.toLowerCase();
    return sampleMenu.where((item) {
      final searchable = '${item.name} ${item.description} ${item.category}'
          .toLowerCase();

      if (query == 'popular') return item.isPopular;
      if (query == 'spicy') {
        return const [
          'spicy',
          'jalapeno',
          'pepper',
          'fajita',
          'krunch',
        ].any(searchable.contains);
      }
      if (query == 'cheesy') {
        return const [
          'cheese',
          'cheddar',
          'mozzarella',
          'creamy',
        ].any(searchable.contains);
      }
      if (query == 'veg') {
        return const {
              'cheese-pizza',
              'fries',
              'cola',
              'sprite',
              'oreo-shake',
              'vanilla-frappe',
              'chocolate-frappe',
              'strawberry-frappe',
              'brownie',
              'cheesecake',
              'loaded-cake',
              'tiramisu',
            }.contains(item.id) ||
            item.category == 'Desserts';
      }

      final searchMatches = query.isEmpty || searchable.contains(query);
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

  void _addDealAndOpenCart(MenuItem item) {
    _addCartItem(
      CartItem(
        menuItem: item,
        quantity: 1,
        unitPrice: item.price,
        size: 'Bundle',
      ),
    );
    unawaited(_openCart());
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
    _queueCartSave();
  }

  void _replaceCart(List<CartItem> items) {
    setState(() => _cartItems = List.of(items));
    _queueCartSave();
  }

  void _queueCartSave() {
    final snapshot = List<CartItem>.of(_cartItems);
    _cartWriteQueue = _cartWriteQueue.then<void>((_) async {
      try {
        await _customerDataService.saveCart(snapshot);
      } catch (_) {
        // Keep the local UI responsive. Firestore's next write/load retries
        // synchronization for the signed-in customer.
      }
    });
  }

  void _queueFavouritesSave() {
    final snapshot = Set<String>.of(_favourites);
    _favouritesWriteQueue = _favouritesWriteQueue.then<void>((_) async {
      try {
        await _customerDataService.saveFavourites(snapshot);
      } catch (_) {
        // The current session remains usable during a temporary network issue.
      }
    });
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
          onCartChanged: _replaceCart,
        ),
      ),
    );
  }

  Future<void> _openProfileDetails() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()),
    );
    if (updated == true && mounted) setState(() {});
  }

  Future<void> _openProfileAddress() {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileAddressScreen(
          initialLocation: _deliveryLocation,
          onLocationChanged: (location) {
            if (!mounted) return;
            setState(() {
              _deliveryLocation = location;
              _address = location.formattedAddress;
            });
          },
        ),
      ),
    );
  }

  Future<void> _openProfileOrders() {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileOrdersScreen()),
    );
  }

  void _toggleFavourite(MenuItem item) {
    setState(() {
      if (!_favourites.add(item.id)) _favourites.remove(item.id);
    });
    _queueFavouritesSave();
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
    final homeDeals = sampleMenu
        .where(
          (item) => item.id == 'wow-pizza-deal' || item.id == 'wow-burger-deal',
        )
        .toList(growable: false);
    final homePizzas = sampleMenu
        .where((item) => item.category == 'Pizzas')
        .toList(growable: false);
    final pages = <int, Widget>{
      0: HomeHeroCarousel(
        deals: homeDeals,
        onDealSelected: _addDealAndOpenCart,
        pizzas: homePizzas,
        favourites: _favourites,
        onPizzaSelected: _openDetails,
        onFavourite: _toggleFavourite,
      ),
      2: RestaurantMenuTab(
        controller: _searchController,
        searchText: _searchText,
        selectedCategory: _selectedMenuCategory,
        items: _filteredItems,
        favourites: _favourites,
        onChanged: (value) => setState(() => _searchText = value.trim()),
        onClear: () {
          _searchController.clear();
          setState(() => _searchText = '');
        },
        onCategorySelected: (category) =>
            setState(() => _selectedMenuCategory = category),
        onOpenItem: _openDetails,
        onFavourite: _toggleFavourite,
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
      4: ProfileTab(
        onDetails: _openProfileDetails,
        onAddress: _openProfileAddress,
        onOrders: _openProfileOrders,
      ),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: _restoringCustomerState
            ? const _CustomerStateLoading()
            : pages[_selectedTab] ?? pages[0]!,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedTab == 4) ProfileLogoutBar(onSignOut: _signOut),
          _MinimalBottomBar(
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
        ],
      ),
    );
  }
}

class _NewCustomerWelcomeDialog extends StatelessWidget {
  const _NewCustomerWelcomeDialog({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 340,
            margin: const EdgeInsets.symmetric(horizontal: 22),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 42,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE8D5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 78,
                      height: 78,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF9A43), AppColors.orange],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x4DFF6B00),
                            blurRadius: 20,
                            offset: Offset(0, 9),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: Colors.white,
                        size: 39,
                      ),
                    ),
                    const Positioned(
                      right: -7,
                      top: -5,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFFB000),
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  firstName.isEmpty
                      ? 'Welcome to Hungry Spot!'
                      : 'Welcome, $firstName!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 25,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your account is ready. Fresh burgers, exclusive deals and easy ordering are waiting for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'START ORDERING',
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.arrow_forward_rounded,
                  borderRadius: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerStateLoading extends StatelessWidget {
  const _CustomerStateLoading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF4FAFE),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1247657A),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: AppColors.red,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'RESTORING YOUR HUNGRY SPOT',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
      ),
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
      return _SavedEmptyState(onBrowse: onBrowse);
    }

    return ColoredBox(
      color: const Color(0xFFF4FAFE),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dark,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${items.length} favourite ${items.length == 1 ? 'meal' : 'meals'} ready for you',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final item = items[index];
                return _SavedFoodCard(
                  item: item,
                  favourite: favourites.contains(item.id),
                  onTap: () => onOpenItem(item),
                  onFavourite: () => onFavourite(item),
                  onAdd: () => onAdd(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedEmptyState extends StatelessWidget {
  const _SavedEmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF4FAFE),
      child: Column(
        children: [
          const SizedBox(
            height: 76,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageSize = (constraints.maxWidth * .61)
                    .clamp(200.0, 260.0)
                    .toDouble();
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 62)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/empty_saved_illustration.png',
                          key: const ValueKey('empty-saved-illustration'),
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'No favourites yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Save the meals you love and find them here anytime.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 25),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: AppPrimaryButton(
                            label: 'Explore Menu',
                            onPressed: onBrowse,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedFoodCard extends StatelessWidget {
  const _SavedFoodCard({
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 146,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EEF2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10233A).withValues(alpha: .07),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 118,
                height: 126,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Hero(
                  tag: 'saved-${item.id}',
                  child: Image.asset(
                    item.displayAssetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 54),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.dark,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onFavourite,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              favourite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: favourite
                                  ? AppColors.red
                                  : AppColors.muted,
                              size: 21,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.category,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB400),
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatUsd(item.price),
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppPrimaryButton(
                      label: 'Add to cart',
                      onPressed: onAdd,
                      height: 34,
                      borderRadius: 10,
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
            icon: Icons.restaurant_menu_outlined,
            selectedIcon: Icons.restaurant_menu_rounded,
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
