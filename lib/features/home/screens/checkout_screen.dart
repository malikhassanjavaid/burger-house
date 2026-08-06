import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../location/models/delivery_location.dart';
import '../../location/screens/location_setup_screen.dart';
import '../models/cart_item.dart';
import '../models/fulfillment_method.dart';
import '../services/order_service.dart';
import '../services/stripe_payment_service.dart';
import 'order_confirmation_screen.dart';
import 'stripe_card_payment_screen.dart';

enum PaymentMethod { cashOnDelivery, card }

const _checkoutBg = Colors.white;
const _checkoutRed = Color(0xFFF23845);
const _checkoutInk = Color(0xFF15161C);
const _checkoutMuted = Color(0xFF858C98);
const _softBorder = Color(0xFFE5E7EB);
const _deliveryGreen = Color(0xFF53A92C);
const _deliveryTint = Color(0xFFF0F8E9);
const _phoneBlue = Color(0xFF2C86E5);
const _phoneTint = Color(0xFFEBF4FF);
const _paymentPurple = Color(0xFF9552E8);
const _paymentTint = Color(0xFFF5EEFF);

extension on PaymentMethod {
  String valueFor(FulfillmentMethod fulfillmentMethod) {
    return switch (this) {
      PaymentMethod.cashOnDelivery =>
        fulfillmentMethod.isPickup ? 'cash_at_pickup' : 'cash_on_delivery',
      PaymentMethod.card => 'card_payment',
    };
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    required this.initialAddress,
    this.initialLocation,
    required this.deliveryFee,
    required this.onOrderPlaced,
    this.fulfillmentMethod = FulfillmentMethod.delivery,
    this.initialDeliveryNotes = '',
    this.serviceFee = 0,
    this.discount = 0,
    this.couponCode,
  });

  final List<CartItem> items;
  final String initialAddress;
  final DeliveryLocation? initialLocation;
  final double deliveryFee;
  final VoidCallback onOrderPlaced;
  final FulfillmentMethod fulfillmentMethod;
  final String initialDeliveryNotes;
  final double serviceFee;
  final double discount;
  final String? couponCode;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _orderService = OrderService();

  PaymentMethod? _paymentMethod;
  StripePaymentResult? _completedCardPayment;
  DeliveryLocation? _deliveryLocation;
  bool _isPlacingOrder = false;
  bool _isLoadingProfile = true;
  bool _savePhoneToAccount = true;

  double get _subtotal =>
      widget.items.fold(0, (total, item) => total + item.totalPrice);
  double get _total =>
      _subtotal + widget.deliveryFee + widget.serviceFee - widget.discount;

  @override
  void initState() {
    super.initState();
    if (widget.fulfillmentMethod.isPickup) {
      _paymentMethod = PaymentMethod.card;
    }
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _addressController.text = widget.initialAddress;
    _deliveryLocation = widget.initialLocation;
    _loadProfileDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data();
      if (data != null) {
        final savedName = (data['name'] as String?)?.trim() ?? '';
        if (savedName.isNotEmpty) _nameController.text = savedName;
      }
    } catch (_) {
      // Authentication values remain available when the cached profile cannot
      // be loaded. Order placement will still surface any real Firebase error.
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _editDeliveryLocation() async {
    if (widget.fulfillmentMethod.isPickup) return;
    FocusScope.of(context).unfocus();
    final updatedLocation = await Navigator.of(context).push<DeliveryLocation>(
      MaterialPageRoute(
        builder: (_) => LocationSetupScreen(initialLocation: _deliveryLocation),
      ),
    );
    if (updatedLocation == null || !mounted) return;
    setState(() {
      _deliveryLocation = updatedLocation;
      _addressController.text = updatedLocation.formattedAddress;
    });
  }

  Future<void> _showPickupLocations() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pickup location',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Choose where you want to collect your order.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              const Row(
                children: [
                  _CheckoutLocationPin(
                    icon: Icons.restaurant_rounded,
                    size: 58,
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HungrySpotPickup.storeName,
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          HungrySpotPickup.menuHours,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.red,
                    size: 23,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'More Hungry Spot pickup locations are coming soon.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'USE THIS LOCATION',
                onPressed: () => Navigator.of(sheetContext).pop(),
                height: 50,
                borderRadius: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveContactDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final name = _receiverName;
    final phone = _phoneController.text.trim();
    final profileUpdate = <String, dynamic>{
      'name': name,
      'profileUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (_savePhoneToAccount) profileUpdate['phone'] = phone;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(profileUpdate, SetOptions(merge: true));
    if (user.displayName != name) await user.updateDisplayName(name);
  }

  String get _receiverName {
    final savedName = _nameController.text.trim();
    if (savedName.isNotEmpty) return savedName;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final emailName = email.split('@').first.trim();
    return emailName.isEmpty ? 'Customer' : emailName;
  }

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isPlacingOrder) return;

    if (_paymentMethod == PaymentMethod.card && _completedCardPayment == null) {
      final payment = await Navigator.of(context).push<StripePaymentResult>(
        MaterialPageRoute(
          builder: (_) => StripeCardPaymentScreen(
            amount: _total,
            fulfillmentMethod: widget.fulfillmentMethod,
          ),
        ),
      );
      if (payment == null || !mounted) return;
      setState(() => _completedCardPayment = payment);
    }

    setState(() => _isPlacingOrder = true);
    try {
      await _saveContactDetails();
      final order = await _orderService.placeOrder(
        PlaceOrderRequest(
          items: widget.items,
          receiverName: _receiverName,
          phone: _phoneController.text.trim(),
          fulfillmentMethod: widget.fulfillmentMethod,
          deliveryAddress: widget.fulfillmentMethod.isPickup
              ? '${HungrySpotPickup.storeName}, ${HungrySpotPickup.address}'
              : _addressController.text.trim(),
          landmark: '',
          deliveryNotes: '',
          paymentMethod: _paymentMethod!.valueFor(widget.fulfillmentMethod),
          paymentStatus: _paymentMethod == PaymentMethod.card
              ? 'paid'
              : 'pending',
          paymentIntentId: _completedCardPayment?.paymentIntentId,
          paymentAmountCents: _completedCardPayment?.amountCents,
          subtotal: _subtotal,
          deliveryFee: widget.deliveryFee,
          serviceFee: widget.serviceFee,
          discount: widget.discount,
          couponCode: widget.couponCode,
          total: _total,
        ),
      );

      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      widget.onOrderPlaced();
      await Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
        (route) => route.isFirst,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      final message = error.code == 'permission-denied'
          ? 'Firestore rules do not allow this order yet.'
          : error.message ?? 'Firebase could not place the order.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The order could not be placed. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.fulfillmentMethod.isPickup;
    final itemCount = widget.items.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    return Scaffold(
      backgroundColor: _checkoutBg,
      body: AppLoadingOverlay(
        loading: _isPlacingOrder,
        semanticsLabel: isPickup ? 'Confirming pickup' : 'Placing order',
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _CheckoutHeader(onBack: () => Navigator.pop(context)),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                  children: [
                    const _CheckoutHeroBanner(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _CheckoutLocationSection(
                        fulfillmentMethod: widget.fulfillmentMethod,
                        location: _deliveryLocation,
                        addressController: _addressController,
                        onEdit: isPickup
                            ? _showPickupLocations
                            : _editDeliveryLocation,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _ContactDetailsSection(
                        phoneController: _phoneController,
                        loading: _isLoadingProfile,
                        saveToAccount: _savePhoneToAccount,
                        onSavePreferenceChanged: (value) =>
                            setState(() => _savePhoneToAccount = value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _PaymentMethodSelector(
                        fulfillmentMethod: widget.fulfillmentMethod,
                        value: _paymentMethod,
                        onChanged: (method) => setState(() {
                          if (_paymentMethod != method) {
                            _completedCardPayment = null;
                          }
                          _paymentMethod = method;
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              _PlaceOrderBar(
                itemCount: itemCount,
                total: _total,
                loading: _isPlacingOrder,
                isPickup: isPickup,
                onPlaceOrder: _placeOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 5,
                shadowColor: const Color(0x1F304A5C),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox.square(
                    dimension: 42,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _checkoutRed,
                      size: 19,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Checkout',
                style: AppTypography.pageHeader.copyWith(
                  color: _checkoutInk,
                  letterSpacing: -.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutHeroBanner extends StatelessWidget {
  const _CheckoutHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Semantics(
        image: true,
        label: 'Almost there. Review your details and place your order.',
        child: Container(
          height: 142,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18304A5C),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                flex: 43,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 2, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Almost '),
                            TextSpan(
                              text: 'there!',
                              style: TextStyle(color: _checkoutRed),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: _checkoutInk,
                          fontSize: 19,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Review your details and place your order',
                        maxLines: 2,
                        style: TextStyle(
                          color: _checkoutInk,
                          fontSize: 10,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _HeroFeature(
                            icon: Icons.verified_user_outlined,
                            label: 'Secure',
                          ),
                          const SizedBox(width: 6),
                          _HeroFeature(icon: Icons.bolt_rounded, label: 'Fast'),
                          const SizedBox(width: 6),
                          _HeroFeature(
                            icon: Icons.workspace_premium_outlined,
                            label: 'Quality',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 57,
                child: SizedBox.expand(
                  child: Image.asset(
                    'assets/images/checkout_hero_hd.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    filterQuality: FilterQuality.high,
                    cacheWidth: (460 * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (accentColor, backgroundColor) = switch (icon) {
      Icons.verified_user_outlined => (_deliveryGreen, _deliveryTint),
      Icons.bolt_rounded => (_checkoutRed, const Color(0xFFFFF0F2)),
      _ => (_phoneBlue, _phoneTint),
    };
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 13),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: _checkoutInk,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLocationSection extends StatelessWidget {
  const _CheckoutLocationSection({
    required this.fulfillmentMethod,
    required this.location,
    required this.addressController,
    required this.onEdit,
  });

  final FulfillmentMethod fulfillmentMethod;
  final DeliveryLocation? location;
  final TextEditingController addressController;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (fulfillmentMethod.isPickup) {
      return _CheckoutLocationRow(
        key: const ValueKey('checkout-pickup-location'),
        eyebrow: 'PICKUP FROM',
        title: HungrySpotPickup.storeName,
        subtitle: HungrySpotPickup.address,
        icon: Icons.storefront_rounded,
        semanticsLabel: 'Change pickup location',
        onChangeLocation: onEdit,
      );
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: addressController,
      builder: (context, value, _) {
        final address = value.text.trim();
        final label = location?.label.trim();
        return _CheckoutLocationRow(
          key: const ValueKey('checkout-delivery-location'),
          eyebrow: 'DELIVER TO',
          title: label == null || label.isEmpty ? 'Home' : label,
          subtitle: address.isEmpty
              ? 'Tap to add your delivery location'
              : address,
          icon: Icons.home_rounded,
          semanticsLabel: 'Change delivery location',
          onChangeLocation: onEdit,
        );
      },
    );
  }
}

class _CheckoutLocationRow extends StatelessWidget {
  const _CheckoutLocationRow({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.semanticsLabel,
    required this.onChangeLocation,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback? onChangeLocation;

  @override
  Widget build(BuildContext context) {
    final actionLabel = eyebrow == 'DELIVER TO'
        ? 'Change address'
        : 'Change location';
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 5,
        shadowColor: const Color(0x1F304A5C),
        child: InkWell(
          onTap: onChangeLocation,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 102),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                _CheckoutIconTile(
                  icon: icon,
                  accentColor: _deliveryGreen,
                  backgroundColor: _deliveryTint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          color: _deliveryGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _checkoutInk,
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _checkoutMuted,
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _CheckoutActionPill(
                        label: actionLabel,
                        icon: Icons.location_on_outlined,
                        accentColor: _deliveryGreen,
                        backgroundColor: _deliveryTint,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _checkoutInk,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutIconTile extends StatelessWidget {
  const _CheckoutIconTile({
    required this.icon,
    this.child,
    this.accentColor = _checkoutRed,
    this.backgroundColor = const Color(0xFFFFF0F2),
  });

  final IconData icon;
  final Widget? child;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child ?? Icon(icon, color: accentColor, size: 25),
    );
  }
}

class _CheckoutActionPill extends StatelessWidget {
  const _CheckoutActionPill({
    required this.label,
    required this.icon,
    this.accentColor = _checkoutRed,
    this.backgroundColor = const Color(0xFFFFF0F2),
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLocationPin extends StatelessWidget {
  const _CheckoutLocationPin({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final circleSize = size * .76;
    final pointSize = size * .31;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: size * .48,
            child: Transform.rotate(
              angle: .785398,
              child: Container(
                width: pointSize,
                height: pointSize,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(size * .035),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 4,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 1,
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: circleSize * .55,
                  height: circleSize * .55,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.red,
                    size: circleSize * .34,
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

class _ContactDetailsSection extends StatelessWidget {
  const _ContactDetailsSection({
    required this.phoneController,
    required this.loading,
    required this.saveToAccount,
    required this.onSavePreferenceChanged,
  });

  final TextEditingController phoneController;
  final bool loading;
  final bool saveToAccount;
  final ValueChanged<bool> onSavePreferenceChanged;

  @override
  Widget build(BuildContext context) {
    return _PhoneNumberSelector(
      controller: phoneController,
      loading: loading,
      saveToAccount: saveToAccount,
      onSavePreferenceChanged: onSavePreferenceChanged,
    );
  }
}

class _PhoneEntryResult {
  const _PhoneEntryResult({required this.number, required this.saveToAccount});

  final String number;
  final bool saveToAccount;
}

class _PhoneNumberSelector extends StatelessWidget {
  const _PhoneNumberSelector({
    required this.controller,
    required this.loading,
    required this.saveToAccount,
    required this.onSavePreferenceChanged,
  });

  final TextEditingController controller;
  final bool loading;
  final bool saveToAccount;
  final ValueChanged<bool> onSavePreferenceChanged;

  static String _nationalDigits(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11 && digits.startsWith('1')) {
      return digits.substring(1);
    }
    return digits;
  }

  static bool _isValid(String value) => _nationalDigits(value).length == 10;

  static String _format(String value) {
    final digits = _nationalDigits(value);
    if (digits.length != 10) return value;
    return '+1 (${digits.substring(0, 3)}) '
        '${digits.substring(3, 6)}-${digits.substring(6)}';
  }

  Future<_PhoneEntryResult?> _showPhoneSheet(BuildContext context) async {
    final initialDigits = _nationalDigits(controller.text);
    var phoneDigits = initialDigits.length == 10 ? initialDigits : '';
    String? errorText;
    var shouldSave = saveToAccount;

    return showModalBottomSheet<_PhoneEntryResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          void save() {
            if (!_isValid(phoneDigits)) {
              setSheetState(
                () => errorText = 'Enter a valid 10-digit US number',
              );
              return;
            }
            Navigator.of(sheetContext).pop(
              _PhoneEntryResult(
                number: _format(phoneDigits),
                saveToAccount: shouldSave,
              ),
            );
          }

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: _CheckoutSheetHandle()),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone number',
                                  style: TextStyle(
                                    color: AppColors.dark,
                                    fontSize: 19,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -.3,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Add a number so the rider can contact you.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 10,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _CheckoutSheetCloseButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            accentColor: _phoneBlue,
                            backgroundColor: _phoneTint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 86, child: _DialCodeField()),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '* ',
                                        style: TextStyle(color: _phoneBlue),
                                      ),
                                      TextSpan(text: 'Phone number'),
                                    ],
                                  ),
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  initialValue: phoneDigits,
                                  autofocus: true,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  style: const TextStyle(
                                    color: AppColors.dark,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .25,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '5551234567',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFADB1B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    errorText: errorText,
                                    errorStyle: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    filled: true,
                                    fillColor: _phoneTint,
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 13,
                                    ),
                                    border: _phoneFieldBorder(_softBorder),
                                    enabledBorder: _phoneFieldBorder(
                                      _softBorder,
                                    ),
                                    focusedBorder: _phoneFieldBorder(
                                      _phoneBlue,
                                      width: 1.4,
                                    ),
                                    errorBorder: _phoneFieldBorder(
                                      AppColors.red,
                                    ),
                                    focusedErrorBorder: _phoneFieldBorder(
                                      AppColors.red,
                                      width: 1.4,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    phoneDigits = value;
                                    if (errorText != null) {
                                      setSheetState(() => errorText = null);
                                    }
                                  },
                                  onFieldSubmitted: (_) => save(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: _phoneTint,
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          onTap: () =>
                              setSheetState(() => shouldSave = !shouldSave),
                          borderRadius: BorderRadius.circular(13),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                            child: Row(
                              children: [
                                Transform.scale(
                                  scale: .86,
                                  child: Checkbox(
                                    value: shouldSave,
                                    onChanged: (value) => setSheetState(
                                      () => shouldSave = value ?? false,
                                    ),
                                    activeColor: _phoneBlue,
                                    checkColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFFADB1B8),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Save this number to my account',
                                    style: TextStyle(
                                      color: AppColors.dark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        label: 'SAVE NUMBER',
                        onPressed: save,
                        height: 46,
                        borderRadius: 14,
                        backgroundColor: _phoneBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static OutlineInputBorder _phoneFieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: (value) =>
          !_isValid(value ?? '') ? 'Please add a valid US phone number' : null,
      builder: (field) {
        final hasNumber = field.value?.isNotEmpty == true;
        final showError = field.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 5,
              shadowColor: const Color(0x1F304A5C),
              child: InkWell(
                onTap: loading
                    ? null
                    : () async {
                        final result = await _showPhoneSheet(context);
                        if (result == null) return;
                        controller.text = result.number;
                        field.didChange(result.number);
                        field.validate();
                        onSavePreferenceChanged(result.saveToAccount);
                      },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 92),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: showError
                        ? Border.all(color: _checkoutRed, width: 1.1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      _CheckoutIconTile(
                        icon: Icons.phone_android_rounded,
                        accentColor: _phoneBlue,
                        backgroundColor: _phoneTint,
                        child: loading
                            ? const AppLoader(
                                size: 21,
                                strokeWidth: 2.3,
                                color: _phoneBlue,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact phone number',
                              style: TextStyle(
                                color: _checkoutInk,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hasNumber
                                  ? field.value!
                                  : 'Add a phone number for rider to contact you',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _checkoutMuted,
                                fontSize: 10,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _CheckoutActionPill(
                              label: hasNumber
                                  ? 'Change phone number'
                                  : 'Add phone number',
                              icon: hasNumber
                                  ? Icons.edit_outlined
                                  : Icons.add_rounded,
                              accentColor: _phoneBlue,
                              backgroundColor: _phoneTint,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        showError
                            ? Icons.report_rounded
                            : Icons.arrow_forward_ios_rounded,
                        color: showError ? _checkoutRed : _checkoutInk,
                        size: showError ? 19 : 17,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.errorText != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: _checkoutRed,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DialCodeField extends StatelessWidget {
  const _DialCodeField();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dial code',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: _phoneTint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCFE4FA)),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  '+1',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _phoneBlue,
                size: 19,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckoutSheetHandle extends StatelessWidget {
  const _CheckoutSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD8DBE0),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _CheckoutSheetCloseButton extends StatelessWidget {
  const _CheckoutSheetCloseButton({
    required this.onPressed,
    this.accentColor = _checkoutRed,
    this.backgroundColor = const Color(0xFFFFF0F2),
  });

  final VoidCallback onPressed;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox.square(
          dimension: 34,
          child: Icon(Icons.close_rounded, color: accentColor, size: 19),
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.fulfillmentMethod,
    required this.value,
    required this.onChanged,
  });

  final FulfillmentMethod fulfillmentMethod;
  final PaymentMethod? value;
  final ValueChanged<PaymentMethod?> onChanged;

  String _labelFor(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cashOnDelivery =>
        fulfillmentMethod.isPickup ? 'Cash at pickup' : 'Cash on delivery',
      PaymentMethod.card => 'Card payment',
    };
  }

  String _subtitleFor(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cashOnDelivery =>
        fulfillmentMethod.isPickup
            ? 'Pay when you collect your order'
            : 'Pay the rider when your order arrives',
      PaymentMethod.card => 'Pay securely using your bank card',
    };
  }

  Future<PaymentMethod?> _showOptions(
    BuildContext context,
    PaymentMethod? current,
  ) {
    return showModalBottomSheet<PaymentMethod>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      useSafeArea: true,
      builder: (sheetContext) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _CheckoutSheetHandle()),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment method',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontSize: 19,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.3,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Choose how you would like to pay.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CheckoutSheetCloseButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      accentColor: _paymentPurple,
                      backgroundColor: _paymentTint,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                ...(fulfillmentMethod.isPickup
                        ? const [PaymentMethod.card]
                        : PaymentMethod.values)
                    .map(
                      (method) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PaymentMethodSheetOption(
                          method: method,
                          title: _labelFor(method),
                          subtitle: _subtitleFor(method),
                          selected: current == method,
                          onTap: () => Navigator.of(sheetContext).pop(method),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<PaymentMethod>(
      key: ValueKey('payment-method-${fulfillmentMethod.firestoreValue}'),
      initialValue: value,
      validator: (method) =>
          method == null ? 'Please select a payment method' : null,
      builder: (field) {
        final selectedMethod = field.value;
        final hasError = field.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 5,
              shadowColor: const Color(0x1F304A5C),
              child: InkWell(
                onTap: () async {
                  final selected = await _showOptions(context, selectedMethod);
                  if (selected == null) return;
                  field.didChange(selected);
                  onChanged(selected);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 92),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: hasError
                        ? Border.all(color: _checkoutRed, width: 1.1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      _CheckoutIconTile(
                        icon: Icons.account_balance_wallet_outlined,
                        accentColor: _paymentPurple,
                        backgroundColor: _paymentTint,
                        child: selectedMethod == null
                            ? null
                            : _PaymentMethodIcon(
                                method: selectedMethod,
                                compact: true,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment method',
                              style: TextStyle(
                                color: _checkoutInk,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              selectedMethod == null
                                  ? 'Select your preferred payment method'
                                  : _labelFor(selectedMethod),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _checkoutMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _CheckoutActionPill(
                              label: selectedMethod == null
                                  ? 'Select payment method'
                                  : 'Change payment method',
                              icon: selectedMethod == null
                                  ? Icons.add_rounded
                                  : Icons.edit_outlined,
                              accentColor: _paymentPurple,
                              backgroundColor: _paymentTint,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        hasError
                            ? Icons.report_rounded
                            : Icons.arrow_forward_ios_rounded,
                        color: hasError ? _checkoutRed : _checkoutInk,
                        size: hasError ? 19 : 17,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.errorText != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: _checkoutRed,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PaymentMethodSheetOption extends StatelessWidget {
  const _PaymentMethodSheetOption({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _paymentTint : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _paymentPurple : _softBorder,
              width: selected ? 1.35 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x269552E8),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _PaymentMethodIcon(method: method),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_off_rounded,
                  key: ValueKey(selected),
                  color: selected ? _paymentPurple : const Color(0xFFB9BEC6),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodIcon extends StatelessWidget {
  const _PaymentMethodIcon({required this.method, this.compact = false});

  final PaymentMethod method;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 42.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _paymentTint,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Icon(
        method == PaymentMethod.cashOnDelivery
            ? Icons.payments_outlined
            : Icons.credit_card_rounded,
        color: _paymentPurple,
        size: compact ? 18 : 22,
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({
    required this.itemCount,
    required this.total,
    required this.loading,
    required this.isPickup,
    required this.onPlaceOrder,
  });

  final int itemCount;
  final double total;
  final bool loading;
  final bool isPickup;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _checkoutBg,
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: 6,
          shadowColor: const Color(0x26304A5C),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const _CheckoutIconTile(icon: Icons.receipt_long_outlined),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$itemCount ITEM${itemCount == 1 ? '' : 'S'}',
                            style: const TextStyle(
                              color: _checkoutMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatUsd(total),
                            style: const TextStyle(
                              color: _checkoutInk,
                              fontSize: 18,
                              height: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Inclusive of taxes',
                            style: TextStyle(
                              color: _checkoutMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 42,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: const Color(0xFFE8EAED),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 116,
                        maxWidth: 142,
                      ),
                      child: SizedBox(
                        height: 46,
                        child: FilledButton(
                          onPressed: loading ? null : onPlaceOrder,
                          style: FilledButton.styleFrom(
                            backgroundColor: _checkoutRed,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFF7A0A7),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            elevation: 5,
                            shadowColor: const Color(0x55F23845),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: loading
                              ? const AppLoader(
                                  size: 17,
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                  trackColor: Color(0x4DFFFFFF),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        isPickup
                                            ? 'CONFIRM PICKUP'
                                            : 'PLACE ORDER',
                                        maxLines: 1,
                                        overflow: TextOverflow.fade,
                                        softWrap: false,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 19,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF68C965),
                      size: 13,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Safe & secure payments',
                      style: TextStyle(
                        color: _checkoutMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
