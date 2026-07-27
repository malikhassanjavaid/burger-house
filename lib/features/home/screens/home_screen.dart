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
import '../models/fulfillment_method.dart';
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
  FulfillmentMethod _fulfillmentMethod = FulfillmentMethod.delivery;
  final Set<String> _favourites = {};

  List<CartItem> _deliveryCartItems = [];
  List<CartItem> _pickupCartItems = [];
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
        _deliveryCartItems = List.of(customerState.deliveryCartItems);
        _pickupCartItems = List.of(customerState.pickupCartItems);
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

  List<CartItem> get _activeCartItems =>
      _fulfillmentMethod.isPickup ? _pickupCartItems : _deliveryCartItems;

  int get _cartCount => _activeCartItems.fold(
    0,
    (totalCount, item) => totalCount + item.quantity,
  );

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
    final fulfillmentMethod = _fulfillmentMethod;
    setState(() {
      final cartItems = fulfillmentMethod.isPickup
          ? _pickupCartItems
          : _deliveryCartItems;
      final index = cartItems.indexWhere(
        (item) => item.configurationKey == cartItem.configurationKey,
      );
      if (index == -1) {
        cartItems.add(cartItem);
      } else {
        final existing = cartItems[index];
        cartItems[index] = existing.copyWith(
          quantity: existing.quantity + cartItem.quantity,
        );
      }
    });
    _queueCartSave(fulfillmentMethod);
  }

  void _replaceCart(List<CartItem> items) {
    final fulfillmentMethod = _fulfillmentMethod;
    setState(() {
      if (fulfillmentMethod.isPickup) {
        _pickupCartItems = List.of(items);
      } else {
        _deliveryCartItems = List.of(items);
      }
    });
    _queueCartSave(fulfillmentMethod);
  }

  void _queueCartSave(FulfillmentMethod fulfillmentMethod) {
    final snapshot = List<CartItem>.of(
      fulfillmentMethod.isPickup ? _pickupCartItems : _deliveryCartItems,
    );
    _cartWriteQueue = _cartWriteQueue.then<void>((_) async {
      try {
        await _customerDataService.saveCart(fulfillmentMethod, snapshot);
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
          items: List<CartItem>.of(_activeCartItems),
          deliveryAddress: _address,
          deliveryLocation: _deliveryLocation,
          onCartChanged: _replaceCart,
          fulfillmentMethod: _fulfillmentMethod,
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
    const bestSellerBurgerIds = [
      'classic-smash',
      'fish-burger',
      'cheese-burger',
      'grilled-burger',
    ];
    final homeBestSellerBurgers = bestSellerBurgerIds
        .map((id) => sampleMenu.firstWhere((item) => item.id == id))
        .toList(growable: false);
    final homePizzas = sampleMenu
        .where((item) => item.category == 'Pizzas')
        .toList(growable: false);
    final homeTopPicks = sampleMenu
        .where((item) => item.id == 'beef-wrap' || item.id == 'loaded-fries')
        .toList(growable: false);
    final pages = <int, Widget>{
      0: HomeHeroCarousel(
        deals: homeDeals,
        onDealSelected: _addDealAndOpenCart,
        bestSellerBurgers: homeBestSellerBurgers,
        pizzas: homePizzas,
        topPicks: homeTopPicks,
        favourites: _favourites,
        onPizzaSelected: _openDetails,
        fulfillmentMethod: _fulfillmentMethod,
        onFulfillmentChanged: (method) {
          setState(() => _fulfillmentMethod = method);
        },
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
      color: AppColors.cream,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _SavedHeader(count: items.length)),
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

class _SavedHeader extends StatelessWidget {
  const _SavedHeader({this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.bookmark_rounded,
              color: AppColors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved meals',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.35,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your Hungry Spot favourites',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (count != null)
            Container(
              key: const ValueKey('saved-count-chip'),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withValues(alpha: .2),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                '$count ${count == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
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
      color: AppColors.cream,
      child: Column(
        children: [
          const _SavedHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageSize = (constraints.maxWidth * .61)
                    .clamp(200.0, 260.0)
                    .toDouble();
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 62)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: imageSize,
                          height: imageSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: imageSize * .8,
                                height: imageSize * .8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [AppColors.blush, AppColors.cream],
                                  ),
                                ),
                              ),
                              Image.asset(
                                'assets/images/empty_saved_illustration.png',
                                key: const ValueKey('empty-saved-illustration'),
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Nothing saved yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap the bookmark on any meal to keep your favourites close.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 25),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: AppPrimaryButton(
                            label: 'Explore Menu',
                            height: 50,
                            borderRadius: 15,
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
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 164,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFDCE1)),
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withValues(alpha: .07),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 112,
                height: 142,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.blush,
                  borderRadius: BorderRadius.circular(17),
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
                          borderRadius: BorderRadius.circular(11),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.blush,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              favourite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: AppColors.red,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blush,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.redDark,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 1,
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
                            color: AppColors.red,
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
                      height: 36,
                      borderRadius: 12,
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
      height: 80 + bottomInset,
      padding: EdgeInsets.fromLTRB(8, 7, 8, bottomInset + 3),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1EAEC))),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: Row(
        children: [
          _MinimalNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _MinimalNavItem(
            icon: Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag_rounded,
            label: 'Cart',
            badgeCount: cartCount,
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          _MinimalNavItem(
            icon: Icons.fastfood_outlined,
            selectedIcon: Icons.fastfood_rounded,
            label: 'Menu',
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          _MinimalNavItem(
            icon: Icons.bookmark_border_rounded,
            selectedIcon: Icons.bookmark_rounded,
            label: 'Saved',
            selected: selectedIndex == 3,
            onTap: () => onSelected(3),
          ),
          _MinimalNavItem(
            icon: Icons.account_circle_outlined,
            selectedIcon: Icons.account_circle_rounded,
            label: 'Profile',
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
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final badgeLabel = badgeCount > 99 ? '99+' : '$badgeCount';

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('bottom-nav-${label.toLowerCase()}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blush : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        selected ? selectedIcon : icon,
                        color: selected
                            ? AppColors.red
                            : const Color(0xFF625B5E),
                        size: selected ? 24 : 23,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: -7,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                DefaultTextStyle(
                  style: TextStyle(
                    color: selected ? AppColors.red : const Color(0xFF746C70),
                    fontSize: 10.5,
                    height: 1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  child: Text(label, maxLines: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
