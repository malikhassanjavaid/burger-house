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
import 'order_confirmation_screen.dart';

enum PaymentMethod { cashOnDelivery, card }

const _checkoutBg = Color(0xFFF4FAFE);
const _checkoutRed = Color(0xFFF23845);
const _checkoutInk = Color(0xFF15161C);
const _checkoutMuted = Color(0xFF858C98);

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
                  fontWeight: FontWeight.w900,
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
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          HungrySpotPickup.menuHours,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
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
                  fontSize: 9.5,
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
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                  children: [
                    const _CheckoutHeroBanner(),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _CheckoutLocationSection(
                        fulfillmentMethod: widget.fulfillmentMethod,
                        location: _deliveryLocation,
                        addressController: _addressController,
                        onEdit: isPickup
                            ? _showPickupLocations
                            : _editDeliveryLocation,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _ContactDetailsSection(
                        phoneController: _phoneController,
                        loading: _isLoadingProfile,
                        saveToAccount: _savePhoneToAccount,
                        onSavePreferenceChanged: (value) =>
                            setState(() => _savePhoneToAccount = value),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _PaymentMethodSelector(
                        fulfillmentMethod: widget.fulfillmentMethod,
                        value: _paymentMethod,
                        onChanged: (method) =>
                            setState(() => _paymentMethod = method),
                      ),
                    ),
                    const SizedBox(height: 18),
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
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 13),
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                elevation: 7,
                shadowColor: const Color(0x1F304A5C),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(18),
                  child: const SizedBox.square(
                    dimension: 54,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _checkoutRed,
                      size: 23,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 22),
              const Text(
                'Checkout',
                style: TextStyle(
                  color: _checkoutInk,
                  fontSize: 27,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
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

  static const _sourceWidth = 851.0;
  static const _sourceHeight = 2048.0;
  static const _cropTop = 260.0;
  static const _cropBottom = 731.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / _sourceWidth;
        final cropHeight = (_cropBottom - _cropTop) * scale;
        return Semantics(
          image: true,
          label: 'Almost there. Review your details and place your order.',
          child: SizedBox(
            width: width,
            height: cropHeight,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: 0,
                    top: -_cropTop * scale,
                    width: width,
                    height: _sourceHeight * scale,
                    child: Image.asset(
                      'assets/images/checkout_reference.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
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
        borderRadius: BorderRadius.circular(24),
        elevation: 8,
        shadowColor: const Color(0x1F304A5C),
        child: InkWell(
          onTap: onChangeLocation,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 137),
            padding: const EdgeInsets.fromLTRB(16, 17, 15, 17),
            child: Row(
              children: [
                _CheckoutIconTile(icon: icon),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          color: _checkoutRed,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _checkoutInk,
                          fontSize: 16.5,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _checkoutMuted,
                          fontSize: 12.2,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CheckoutActionPill(
                        label: actionLabel,
                        icon: Icons.location_on_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _checkoutInk,
                  size: 20,
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
  const _CheckoutIconTile({required this.icon, this.child});

  final IconData icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child ?? Icon(icon, color: _checkoutRed, size: 31),
    );
  }
}

class _CheckoutActionPill extends StatelessWidget {
  const _CheckoutActionPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _checkoutRed, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: _checkoutRed,
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
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

    final result = await showModalBottomSheet<_PhoneEntryResult>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final screenHeight = MediaQuery.sizeOf(context).height;
          final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
          final sheetHeight = keyboardInset > 0
              ? (screenHeight * .55).clamp(390.0, 480.0)
              : (screenHeight * .76).clamp(520.0, 650.0);

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
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: SizedBox(
              height: sheetHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      iconSize: 32,
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.dark,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Phone number',
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Please supply a phone number so the courier can contact you.',
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 100, child: _DialCodeField()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '* ',
                                      style: TextStyle(color: AppColors.red),
                                    ),
                                    TextSpan(text: 'Phone number'),
                                  ],
                                ),
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 7),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .3,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Phone number',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9A9DA3),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  errorText: errorText,
                                  filled: true,
                                  fillColor: Colors.white,
                                  counterText: '',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF696C70),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF696C70),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                      color: AppColors.red,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                      color: AppColors.red,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                      color: AppColors.red,
                                      width: 1.5,
                                    ),
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
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () =>
                          setSheetState(() => shouldSave = !shouldSave),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Checkbox(
                              value: shouldSave,
                              onChanged: (value) => setSheetState(
                                () => shouldSave = value ?? false,
                              ),
                              activeColor: AppColors.red,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF898D93)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Expanded(
                              child: Text(
                                'Save this number to my account',
                                style: TextStyle(
                                  color: AppColors.dark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    AppPrimaryButton(
                      label: 'SAVE',
                      onPressed: save,
                      height: 54,
                      borderRadius: 27,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    return result;
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
              borderRadius: BorderRadius.circular(24),
              elevation: 8,
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
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 116),
                  padding: const EdgeInsets.fromLTRB(16, 17, 15, 17),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: showError
                        ? Border.all(color: _checkoutRed, width: 1.1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      _CheckoutIconTile(
                        icon: Icons.phone_android_rounded,
                        child: loading
                            ? const AppLoader(size: 25, strokeWidth: 2.3)
                            : null,
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact phone number',
                              style: TextStyle(
                                color: _checkoutInk,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasNumber
                                  ? field.value!
                                  : 'Add a phone number for rider to contact you',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _checkoutMuted,
                                fontSize: 11.8,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _CheckoutActionPill(
                              label: hasNumber
                                  ? 'Change phone number'
                                  : 'Add phone number',
                              icon: hasNumber
                                  ? Icons.edit_outlined
                                  : Icons.add_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        showError
                            ? Icons.report_rounded
                            : Icons.arrow_forward_ios_rounded,
                        color: showError ? _checkoutRed : _checkoutInk,
                        size: showError ? 23 : 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.errorText != null) ...[
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: _checkoutRed,
                    fontSize: 10.5,
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
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFF696C70)),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  '+1',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.dark,
                size: 23,
              ),
            ],
          ),
        ),
      ],
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

  String _assetFor(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cashOnDelivery => 'assets/images/payment_cash_option.png',
      PaymentMethod.card => 'assets/images/payment_card_option.png',
    };
  }

  Future<PaymentMethod?> _showOptions(
    BuildContext context,
    PaymentMethod? current,
  ) {
    return showModalBottomSheet<PaymentMethod>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select payment method',
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose how you would like to pay',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.dark,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...PaymentMethod.values.map(
              (method) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PaymentMethodSheetOption(
                  assetPath: _assetFor(method),
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
              borderRadius: BorderRadius.circular(24),
              elevation: 8,
              shadowColor: const Color(0x1F304A5C),
              child: InkWell(
                onTap: () async {
                  final selected = await _showOptions(context, selectedMethod);
                  if (selected == null) return;
                  field.didChange(selected);
                  onChanged(selected);
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 116),
                  padding: const EdgeInsets.fromLTRB(16, 17, 15, 17),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: hasError
                        ? Border.all(color: _checkoutRed, width: 1.1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      _CheckoutIconTile(
                        icon: Icons.account_balance_wallet_outlined,
                        child: selectedMethod == null
                            ? null
                            : Padding(
                                padding: const EdgeInsets.all(7),
                                child: Image.asset(
                                  _assetFor(selectedMethod),
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment method',
                              style: TextStyle(
                                color: _checkoutInk,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedMethod == null
                                  ? 'Select your preferred payment method'
                                  : _labelFor(selectedMethod),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _checkoutMuted,
                                fontSize: 11.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _CheckoutActionPill(
                              label: selectedMethod == null
                                  ? 'Select payment method'
                                  : 'Change payment method',
                              icon: selectedMethod == null
                                  ? Icons.add_rounded
                                  : Icons.edit_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        hasError
                            ? Icons.report_rounded
                            : Icons.arrow_forward_ios_rounded,
                        color: hasError ? _checkoutRed : _checkoutInk,
                        size: hasError ? 23 : 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.errorText != null) ...[
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: _checkoutRed,
                    fontSize: 10.5,
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
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String assetPath;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blush : const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFFF2B7BD) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              _PaymentOptionArtwork(
                assetPath: assetPath,
                width: 56,
                height: 46,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.red : const Color(0xFFB9BEC6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionArtwork extends StatelessWidget {
  const _PaymentOptionArtwork({
    required this.assetPath,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          cacheWidth: (width * 2 * MediaQuery.devicePixelRatioOf(context))
              .round(),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          elevation: 10,
          shadowColor: const Color(0x26304A5C),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const _CheckoutIconTile(icon: Icons.receipt_long_outlined),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$itemCount ITEM${itemCount == 1 ? '' : 'S'}',
                            style: const TextStyle(
                              color: _checkoutMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatUsd(total),
                            style: const TextStyle(
                              color: _checkoutInk,
                              fontSize: 21,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Inclusive of taxes',
                            style: TextStyle(
                              color: _checkoutMuted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: const Color(0xFFE8EAED),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 125,
                        maxWidth: 154,
                      ),
                      child: SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: loading ? null : onPlaceOrder,
                          style: FilledButton.styleFrom(
                            backgroundColor: _checkoutRed,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFF7A0A7),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            elevation: 5,
                            shadowColor: const Color(0x55F23845),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const AppLoader(
                                  size: 19,
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
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 22,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF68C965),
                      size: 16,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Safe & secure payments',
                      style: TextStyle(
                        color: _checkoutMuted,
                        fontSize: 10.5,
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
