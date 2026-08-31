import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../auth/services/auth_service.dart';
import '../../account/screens/privacy_account_screen.dart';
import '../../location/models/delivery_location.dart';
import '../data/sample_menu.dart';
import '../models/cart_item.dart';
import '../models/fulfillment_method.dart';
import '../models/menu_item.dart';
import '../services/customer_data_service.dart';
import '../widgets/first_order_offer_dialog.dart';
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
    this.hasOrderHistoryLoader,
    super.key,
  });

  final bool showNewAccountWelcome;
  final String? welcomeName;
  final Future<bool> Function()? hasOrderHistoryLoader;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _menuSearchFocusNode = FocusNode();
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
  bool _firstOrderOfferFlowActive = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDeliveryLocation());
    unawaited(_restoreCustomerState());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showStartupDialogs());
    });
  }

  Future<void> _showStartupDialogs() async {
    if (!mounted) return;
    if (widget.showNewAccountWelcome) {
      final firstName = (widget.welcomeName ?? '').trim().split(' ').first;
      await showGeneralDialog<void>(
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
    }

    await _showFirstOrderOfferIfEligible();
  }

  Future<void> _showFirstOrderOfferIfEligible() async {
    if (!mounted || _firstOrderOfferFlowActive) return;
    _firstOrderOfferFlowActive = true;
    try {
      final hasOrderHistory =
          await (widget.hasOrderHistoryLoader ??
              _customerDataService.hasOrderHistory)();
      if (!mounted || hasOrderHistory) return;
      await _showFirstOrderOffer();
    } catch (_) {
      // The offer is only valid for accounts with confirmed zero-order
      // history. If that cannot be checked, keep the home screen usable and
      // avoid showing a potentially invalid promotion.
    } finally {
      _firstOrderOfferFlowActive = false;
    }
  }

  Future<void> _showFirstOrderOffer() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close first order offer',
      barrierColor: Colors.black.withValues(alpha: .64),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => const FirstOrderOfferDialog(),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
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

  String get _customerFirstName {
    final suppliedName = (widget.welcomeName ?? '').trim();
    final displayName = (_authService.currentUser?.displayName ?? '').trim();
    final emailName = (_authService.currentUser?.email ?? '')
        .split('@')
        .first
        .trim();
    final name = suppliedName.isNotEmpty
        ? suppliedName
        : displayName.isNotEmpty
        ? displayName
        : emailName;
    if (name.isEmpty) return 'Customer';
    return name.split(RegExp(r'\s+')).first;
  }

  String get _homeLocationLabel {
    if (_fulfillmentMethod.isPickup) return 'Pickup from Hungry Spot';
    final savedLabel = (_deliveryLocation?.label ?? '').trim();
    return 'Deliver to ${savedLabel.isEmpty ? 'Home' : savedLabel}';
  }

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
    _menuSearchFocusNode.dispose();
    super.dispose();
  }

  void _addQuickItem(MenuItem item) {
    _addCartItem(CartItem(menuItem: item, quantity: 1, unitPrice: item.price));
    _showMenuWithCart();
  }

  void _showMenuWithCart() {
    if (!mounted) return;
    _menuSearchFocusNode.unfocus();
    setState(() => _selectedTab = 2);
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
    var addedToCart = false;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MenuDetailsScreen(
          item: item,
          onAddToCart: (cartItem) {
            addedToCart = true;
            _addCartItem(cartItem);
          },
        ),
      ),
    );
    if (addedToCart) _showMenuWithCart();
  }

  Future<void> _openCart() async {
    final exit = await Navigator.push<CartScreenExit>(
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
    if (exit == CartScreenExit.exploreMenu && mounted) {
      setState(() => _selectedTab = 2);
      _menuSearchFocusNode.unfocus();
    }
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

  Future<void> _openPrivacyAccount() {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyAccountScreen()),
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
        onDealSelected: _openDetails,
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
        customerName: _customerFirstName,
        deliveryLabel: _homeLocationLabel,
        onNotificationTap: () => unawaited(_showFirstOrderOfferIfEligible()),
        onLocationTap: _fulfillmentMethod.isPickup
            ? null
            : () => unawaited(_openProfileAddress()),
      ),
      2: RestaurantMenuTab(
        controller: _searchController,
        searchFocusNode: _menuSearchFocusNode,
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
        cartItems: _activeCartItems,
        onBack: () {
          _menuSearchFocusNode.unfocus();
          setState(() => _selectedTab = 0);
        },
        onViewCart: _openCart,
      ),
      3: _SavedTab(
        items: sampleMenu
            .where((item) => _favourites.contains(item.id))
            .toList(),
        favourites: _favourites,
        onOpenItem: _openDetails,
        onFavourite: _toggleFavourite,
        onAdd: _addQuickItem,
        onBrowse: () => setState(() => _selectedTab = 2),
      ),
      4: ProfileTab(
        onDetails: _openProfileDetails,
        onAddress: _openProfileAddress,
        onOrders: _openProfileOrders,
        onPrivacy: _openPrivacyAccount,
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
      bottomNavigationBar: _selectedTab == 2
          ? null
          : Column(
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
      minimum: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 28)
              .clamp(0.0, 360.0)
              .toDouble();
          final cardHeight = constraints.maxHeight.clamp(0.0, 500.0).toDouble();
          final railWidth = cardWidth * .23;
          final logoSealSize = cardWidth < 330 ? 94.0 : 104.0;
          final contentLeft = railWidth + 49;

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                key: const ValueKey('new-account-welcome-card'),
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3D000000),
                      blurRadius: 34,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipPath(
                  clipper: _WelcomeTicketClipper(notchCenterX: railWidth),
                  child: ColoredBox(
                    color: const Color(0xFFFFFDF8),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: railWidth,
                          child: Container(
                            key: const ValueKey(
                              'new-account-welcome-ticket-rail',
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              border: Border(
                                right: BorderSide(
                                  color: Color(0x66FFFFFF),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  left: -47,
                                  bottom: 70,
                                  child: Opacity(
                                    opacity: .12,
                                    child: HungrySpotLogo(
                                      size: 155,
                                      contentScale: 1.08,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 31,
                                  right: 10,
                                  bottom: 31,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) => Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(
                                        (constraints.maxHeight / 13).floor(),
                                        (_) => Container(
                                          width: 1.4,
                                          height: 6,
                                          color: Colors.white.withValues(
                                            alpha: .48,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          key: const ValueKey(
                            'new-account-welcome-celebration',
                          ),
                          top: 44,
                          right: 28,
                          child: const Icon(
                            Icons.celebration_rounded,
                            color: Color(0xFFFFB800),
                            size: 44,
                          ),
                        ),
                        Positioned(
                          right: -14,
                          bottom: 32,
                          child: Icon(
                            Icons.blur_on_rounded,
                            color: const Color(
                              0xFFFFC436,
                            ).withValues(alpha: .28),
                            size: 96,
                          ),
                        ),
                        Positioned(
                          left: railWidth - (logoSealSize * .52),
                          top: 56,
                          child: Container(
                            key: const ValueKey(
                              'new-account-welcome-logo-seal',
                            ),
                            width: logoSealSize,
                            height: logoSealSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFEFA),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFB800),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 14,
                                  offset: Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                key: const ValueKey('new-account-welcome-logo'),
                                width: logoSealSize - 12,
                                height: logoSealSize - 12,
                                child: HungrySpotLogo(
                                  size: logoSealSize - 12,
                                  contentScale: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              contentLeft,
                              154,
                              22,
                              108,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(text: 'Welcome, '),
                                      TextSpan(
                                        text: firstName.isEmpty
                                            ? 'Friend!'
                                            : '$firstName!',
                                        style: const TextStyle(
                                          color: AppColors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    color: AppColors.dark,
                                    fontSize: 32,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.7,
                                  ),
                                ),
                                const SizedBox(height: 13),
                                Container(
                                  width: 34,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(height: 26),
                                const Text(
                                  'Your account is ready. Fresh burgers, '
                                  'exclusive deals and easy ordering are '
                                  'waiting for you.',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 14,
                                    height: 1.55,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: railWidth + 18,
                          right: 22,
                          bottom: 24,
                          child: Material(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(28),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: const ValueKey('new-account-start-ordering'),
                              onTap: () => Navigator.pop(context),
                              overlayColor: WidgetStatePropertyAll(
                                Colors.white.withValues(alpha: .14),
                              ),
                              child: const SizedBox(
                                height: 56,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 18),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Start Ordering',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeTicketClipper extends CustomClipper<Path> {
  const _WelcomeTicketClipper({required this.notchCenterX});

  final double notchCenterX;

  @override
  Path getClip(Size size) {
    const cornerRadius = 30.0;
    const notchRadius = 13.0;
    final topNotch = Rect.fromCircle(
      center: Offset(notchCenterX, 0),
      radius: notchRadius,
    );
    final bottomNotch = Rect.fromCircle(
      center: Offset(notchCenterX, size.height),
      radius: notchRadius,
    );

    return Path()
      ..moveTo(cornerRadius, 0)
      ..lineTo(notchCenterX - notchRadius, 0)
      ..arcTo(topNotch, math.pi, -math.pi, false)
      ..lineTo(size.width - cornerRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
      ..lineTo(size.width, size.height - cornerRadius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - cornerRadius,
        size.height,
      )
      ..lineTo(notchCenterX + notchRadius, size.height)
      ..arcTo(bottomNotch, 0, -math.pi, false)
      ..lineTo(cornerRadius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
      ..lineTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _WelcomeTicketClipper oldClipper) {
    return oldClipper.notchCenterX != notchCenterX;
  }
}

class _CustomerStateLoading extends StatelessWidget {
  const _CustomerStateLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Center(child: AppLoader(size: 42)),
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
      color: Colors.white,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _SavedHeader(count: items.length)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
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
          SliverToBoxAdapter(child: _SavedExploreBanner(onTap: onBrowse)),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF2F3), Color(0xFFFFE5E9)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.bookmark_rounded,
              color: AppColors.red,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved meals',
                  style: AppTypography.pageHeader.copyWith(
                    height: 1,
                    letterSpacing: -.4,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your Hungry Spot favourites',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFF50018), AppColors.red],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withValues(alpha: .18),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
      color: Colors.white,
      child: Column(
        children: [
          const _SavedHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageSize = (constraints.maxWidth * .56)
                    .clamp(180.0, 235.0)
                    .toDouble();
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 105),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 70)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: imageSize,
                          height: imageSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: imageSize * .78,
                                height: imageSize * .78,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.blush,
                                      Color(0xFFFFFBFB),
                                    ],
                                  ),
                                ),
                              ),
                              Image.asset(
                                'assets/images/empty_saved_illustration.webp',
                                key: const ValueKey('empty-saved-illustration'),
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nothing saved yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the bookmark on any meal to keep your favourites close.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: AppPrimaryButton(
                            label: 'Explore Menu',
                            icon: Icons.arrow_forward_rounded,
                            height: 46,
                            borderRadius: 14,
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

  int get _reviewCount {
    final seed = item.id.codeUnits.fold<int>(0, (sum, value) => sum + value);
    return 72 + seed % 79;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 350;
        final imageWidth = narrow ? 104.0 : 120.0;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: narrow ? 174 : 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFD9DE)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withValues(alpha: .065),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(21),
                        ),
                        child: Container(
                          width: imageWidth,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFF5F6), Color(0xFFFFE8EB)],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: -28,
                                left: -28,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.red.withValues(alpha: .84),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Hero(
                                  tag: 'saved-${item.id}',
                                  child: Image.asset(
                                    item.displayAssetPath,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, _, _) => Center(
                                      child: Text(
                                        item.emoji,
                                        style: const TextStyle(fontSize: 50),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            narrow ? 10 : 12,
                            11,
                            10,
                            10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 38),
                                child: Text(
                                  item.category.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.red,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .35,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Padding(
                                padding: const EdgeInsets.only(right: 34),
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.dark,
                                    fontSize: narrow ? 12.5 : 13.5,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: narrow ? 9.2 : 9.8,
                                  height: 1.32,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB800),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.rating}',
                                    style: const TextStyle(
                                      color: AppColors.dark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Container(
                                    width: 1,
                                    height: 13,
                                    color: const Color(0xFFD8D2D4),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      '$_reviewCount+ reviews',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    formatUsd(item.price),
                                    style: TextStyle(
                                      color: AppColors.red,
                                      fontSize: narrow ? 14 : 15.5,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -.25,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: AppPrimaryButton(
                                      label: narrow ? 'Add' : 'Add to cart',
                                      icon: Icons.shopping_cart_outlined,
                                      onPressed: onAdd,
                                      height: 35,
                                      borderRadius: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      shadowColor: AppColors.red,
                      child: InkWell(
                        onTap: onFavourite,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            favourite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: AppColors.red,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedExploreBanner extends StatelessWidget {
  const _SavedExploreBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFFF2F3), Color(0xFFFFE8EB)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD9DE)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 98,
                  child: Image.asset(
                    'assets/images/empty_saved_illustration.webp',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Craving something else?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Explore the menu and find your next favourite meal.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(right: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.red.withValues(alpha: .1),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.red,
                    size: 22,
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E8E8), width: .7)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 5, 8, bottomInset + 3),
        child: SizedBox(
          height: 61,
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
        ),
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
    final feedbackOnTap = AppPressable.withFeedback(
      onTap,
      haptic: AppHaptic.selection,
    );

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: AppPressable(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('bottom-nav-${label.toLowerCase()}'),
              onTap: feedbackOnTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: AppColors.red.withValues(alpha: .10),
              highlightColor: AppColors.red.withValues(alpha: .04),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 28,
                          child: Center(
                            child: Icon(
                              selected ? selectedIcon : icon,
                              color: selected
                                  ? const Color(0xFF111111)
                                  : const Color(0xFF777277),
                              size: 24,
                            ),
                          ),
                        ),
                        if (badgeCount > 0)
                          Positioned(
                            top: -5,
                            right: -7,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 18),
                              height: 18,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                badgeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: AppTypography.navLabel.copyWith(
                        color: selected
                            ? const Color(0xFF111111)
                            : const Color(0xFF777277),
                        fontSize: 9.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
