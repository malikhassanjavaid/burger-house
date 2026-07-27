import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../location/models/delivery_location.dart';
import '../../location/screens/location_setup_screen.dart';
import '../models/cart_item.dart';
import '../models/fulfillment_method.dart';
import '../services/order_service.dart';
import 'order_confirmation_screen.dart';

enum PaymentMethod { cashOnDelivery, card }

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

  double get _subtotal =>
      widget.items.fold(0, (total, item) => total + item.totalPrice);
  double get _total =>
      _subtotal + widget.deliveryFee + widget.serviceFee - widget.discount;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
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
        final savedPhone = (data['phone'] as String?)?.trim() ?? '';
        if (savedName.isNotEmpty) _nameController.text = savedName;
        if (savedPhone.isNotEmpty) _phoneController.text = savedPhone;
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
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': name,
      'phone': phone,
      'profileUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (user.displayName != name) await user.updateDisplayName(name);
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
          receiverName: _nameController.text.trim(),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 2,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  children: [
                    _CheckoutLocationSection(
                      fulfillmentMethod: widget.fulfillmentMethod,
                      location: _deliveryLocation,
                      addressController: _addressController,
                      onEdit: isPickup
                          ? _showPickupLocations
                          : _editDeliveryLocation,
                    ),
                    const SizedBox(height: 30),
                    const _SectionTitle(title: 'Contact details'),
                    const SizedBox(height: 12),
                    _ContactDetailsSection(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      loading: _isLoadingProfile,
                    ),
                    const SizedBox(height: 30),
                    const _SectionTitle(title: 'Payment method'),
                    const SizedBox(height: 11),
                    _PaymentMethodSelector(
                      fulfillmentMethod: widget.fulfillmentMethod,
                      value: _paymentMethod,
                      onChanged: (method) =>
                          setState(() => _paymentMethod = method),
                    ),
                    const SizedBox(height: 30),
                    const _SectionTitle(title: 'Order summary'),
                    const SizedBox(height: 13),
                    _CheckoutSummary(
                      items: widget.items,
                      subtotal: _subtotal,
                      deliveryFee: widget.deliveryFee,
                      serviceFee: widget.serviceFee,
                      discount: widget.discount,
                      total: _total,
                      isPickup: isPickup,
                    ),
                  ],
                ),
              ),
              _PlaceOrderBar(
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.dark,
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: -.15,
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
        title: HungrySpotPickup.storeName,
        subtitle: HungrySpotPickup.menuHours,
        icon: Icons.restaurant_rounded,
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
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.semanticsLabel,
    required this.onChangeLocation,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback? onChangeLocation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CheckoutLocationPin(icon: icon, size: 64),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 16,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6F7379),
                      fontSize: 10.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onChangeLocation,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0077A8),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Change location',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF0077A8),
                  decorationThickness: 1,
                ),
              ),
            ),
          ],
        ),
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
    required this.nameController,
    required this.phoneController,
    required this.loading,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          enabled: !loading,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          decoration: _contactDecoration(label: 'Name*', loading: loading),
          validator: (value) =>
              (value ?? '').trim().length < 2 ? 'Enter your full name' : null,
        ),
        const SizedBox(height: 11),
        TextFormField(
          controller: phoneController,
          enabled: !loading,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          decoration: _contactDecoration(
            label: 'Phone number*',
            loading: loading,
          ),
          validator: (value) {
            final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
            return digits.length < 10 || digits.length > 13
                ? 'Enter a valid phone number'
                : null;
          },
        ),
      ],
    );
  }

  InputDecoration _contactDecoration({
    required String label,
    required bool loading,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF9AA2AC),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      suffixIcon: loading
          ? const Padding(
              padding: EdgeInsets.all(15),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              ),
            )
          : const Icon(Icons.edit_rounded, size: 17, color: AppColors.muted),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
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

  String _assetFor(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cashOnDelivery => 'assets/images/payment_cash_option.png',
      PaymentMethod.card => 'assets/images/payment_card_option.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PaymentMethod>(
      key: ValueKey('payment-method-${fulfillmentMethod.firestoreValue}'),
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.dark,
        size: 24,
      ),
      hint: const Text(
        'Select method',
        style: TextStyle(
          color: Color(0xFF9299A3),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.red, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.red, width: 1.2),
        ),
        errorStyle: const TextStyle(
          color: AppColors.red,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
      validator: (method) =>
          method == null ? 'Please select a payment method' : null,
      selectedItemBuilder: (context) => PaymentMethod.values
          .map(
            (method) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _labelFor(method),
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(growable: false),
      items: PaymentMethod.values
          .map(
            (method) => DropdownMenuItem<PaymentMethod>(
              value: method,
              child: Row(
                children: [
                  _PaymentOptionArtwork(assetPath: _assetFor(method)),
                  const SizedBox(width: 12),
                  Text(
                    _labelFor(method),
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _PaymentOptionArtwork extends StatelessWidget {
  const _PaymentOptionArtwork({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 44,
        height: 36,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          cacheWidth: (88 * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      ),
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
    required this.isPickup,
  });

  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;
  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${item.quantity}×',
                    style: const TextStyle(
                      color: AppColors.red,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.menuItem.name,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.size.trim().isNotEmpty)
                        Text(
                          item.size,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9.5,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  formatUsd(item.totalPrice),
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SummaryRow(label: 'Subtotal', value: subtotal),
        const SizedBox(height: 10),
        _SummaryRow(
          label: isPickup ? 'Pickup' : 'Delivery',
          value: deliveryFee,
          freeLabel: isPickup ? 'FREE' : null,
        ),
        if (serviceFee > 0) ...[
          const SizedBox(height: 10),
          _SummaryRow(label: 'Service fee', value: serviceFee),
        ],
        if (discount > 0) ...[
          const SizedBox(height: 10),
          _SummaryRow(label: 'Voucher discount', value: -discount),
        ],
        const SizedBox(height: 16),
        _SummaryRow(label: 'Total', value: total, emphasized: true),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.freeLabel,
  });

  final String label;
  final double value;
  final bool emphasized;
  final String? freeLabel;

  @override
  Widget build(BuildContext context) {
    final valueText =
        freeLabel ??
        (value < 0 ? '− ${formatUsd(value.abs())}' : formatUsd(value));
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? AppColors.dark : AppColors.muted,
              fontSize: emphasized ? 13 : 11,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          valueText,
          style: TextStyle(
            color: value < 0
                ? const Color(0xFF43A047)
                : emphasized
                ? AppColors.red
                : AppColors.dark,
            fontSize: emphasized ? 16 : 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({
    required this.total,
    required this.loading,
    required this.isPickup,
    required this.onPlaceOrder,
  });

  final double total;
  final bool loading;
  final bool isPickup;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 12),
          child: AppPrimaryButton(
            label:
                '${isPickup ? 'CONFIRM PICKUP' : 'PLACE ORDER'}  •  ${formatUsd(total)}',
            onPressed: onPlaceOrder,
            isLoading: loading,
            height: 52,
            borderRadius: 16,
          ),
        ),
      ),
    );
  }
}
