import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../location/models/delivery_location.dart';
import '../models/cart_item.dart';
import '../services/order_service.dart';
import 'order_confirmation_screen.dart';

enum PaymentMethod { cashOnDelivery, card, wallet }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    required this.initialAddress,
    this.initialLocation,
    required this.deliveryFee,
    required this.onOrderPlaced,
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
  final _landmarkController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressFocusNode = FocusNode();
  final _orderService = OrderService();

  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  bool _isPlacingOrder = false;

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
    _notesController.text = widget.initialDeliveryNotes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _notesController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _selectPayment(PaymentMethod method, bool available) {
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Online payments require a secure payment gateway integration.',
          ),
        ),
      );
      return;
    }
    setState(() => _paymentMethod = method);
  }

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isPlacingOrder) return;

    setState(() => _isPlacingOrder = true);
    try {
      final order = await _orderService.placeOrder(
        PlaceOrderRequest(
          items: widget.items,
          receiverName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
          landmark: _landmarkController.text.trim(),
          deliveryNotes: _notesController.text.trim(),
          paymentMethod: 'cash_on_delivery',
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
          ? 'Firestore rules do not allow creating orders yet.'
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w800),
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    const Text(
                      'Almost there',
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Confirm the details below and we will start preparing your order.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _CheckoutHeading(
                      number: '1',
                      title: 'Delivery details',
                      subtitle: 'Your saved location and contact information',
                    ),
                    const SizedBox(height: 14),
                    _CheckoutLocationCard(
                      location: widget.initialLocation,
                      addressController: _addressController,
                      onEdit: () => _addressFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 14),
                    _AddressForm(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                      landmarkController: _landmarkController,
                      notesController: _notesController,
                      addressFocusNode: _addressFocusNode,
                    ),
                    const SizedBox(height: 30),
                    const _CheckoutHeading(
                      number: '2',
                      title: 'Payment',
                      subtitle: 'Choose how you want to pay',
                    ),
                    const SizedBox(height: 14),
                    _PaymentOption(
                      title: 'Cash on delivery',
                      subtitle: 'Pay the rider when your order arrives',
                      icon: Icons.payments_outlined,
                      selected: _paymentMethod == PaymentMethod.cashOnDelivery,
                      available: true,
                      onTap: () =>
                          _selectPayment(PaymentMethod.cashOnDelivery, true),
                    ),
                    const SizedBox(height: 10),
                    _PaymentOption(
                      title: 'Credit or debit card',
                      subtitle: 'Secure gateway not connected yet',
                      icon: Icons.credit_card,
                      selected: _paymentMethod == PaymentMethod.card,
                      available: false,
                      onTap: () => _selectPayment(PaymentMethod.card, false),
                    ),
                    const SizedBox(height: 10),
                    _PaymentOption(
                      title: 'Mobile wallet',
                      subtitle: 'Easypaisa/JazzCash integration coming later',
                      icon: Icons.account_balance_wallet_outlined,
                      selected: _paymentMethod == PaymentMethod.wallet,
                      available: false,
                      onTap: () => _selectPayment(PaymentMethod.wallet, false),
                    ),
                    const SizedBox(height: 30),
                    const _CheckoutHeading(
                      number: '3',
                      title: 'Order summary',
                      subtitle: 'Review before placing your order',
                    ),
                    const SizedBox(height: 14),
                    _CheckoutSummary(
                      items: widget.items,
                      subtotal: _subtotal,
                      deliveryFee: widget.deliveryFee,
                      serviceFee: widget.serviceFee,
                      discount: widget.discount,
                      total: _total,
                    ),
                  ],
                ),
              ),
              _PlaceOrderBar(
                total: _total,
                loading: _isPlacingOrder,
                onPlaceOrder: _placeOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutLocationCard extends StatelessWidget {
  const _CheckoutLocationCard({
    required this.location,
    required this.addressController,
    required this.onEdit,
  });

  final DeliveryLocation? location;
  final TextEditingController addressController;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final latitude = location?.latitude;
    final longitude = location?.longitude;
    final point = latitude != null && longitude != null
        ? LatLng(latitude, longitude)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E5E6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: .06),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            child: SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (point != null)
                    IgnorePointer(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: point,
                          initialZoom: 15.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.hungryspot.customer',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: point,
                                width: 54,
                                height: 64,
                                alignment: Alignment.topCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.red.withValues(
                                          alpha: .28,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.home_rounded,
                                    color: Colors.white,
                                    size: 23,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    const _CheckoutMapPlaceholder(),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            color: AppColors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            point == null
                                ? 'DELIVERY LOCATION'
                                : 'PIN CONFIRMED',
                            style: const TextStyle(
                              color: AppColors.dark,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 12, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.red,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: addressController,
                    builder: (context, value, _) {
                      final address = value.text.trim();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location?.label.trim().isNotEmpty == true
                                ? location!.label
                                : 'Delivery address',
                            style: const TextStyle(
                              color: AppColors.dark,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            address.isEmpty
                                ? 'Add a complete address for your rider'
                                : address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 17),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
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

class _CheckoutMapPlaceholder extends StatelessWidget {
  const _CheckoutMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF1F2),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -26,
            child: Icon(
              Icons.route_rounded,
              size: 150,
              color: AppColors.red.withValues(alpha: .07),
            ),
          ),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withValues(alpha: .13),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_searching_rounded,
                color: AppColors.red,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressForm extends StatelessWidget {
  const _AddressForm({
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.landmarkController,
    required this.notesController,
    required this.addressFocusNode,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController landmarkController;
  final TextEditingController notesController;
  final FocusNode addressFocusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Receiver name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) => (value ?? '').trim().length < 2
                ? 'Enter the receiver’s full name'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '03XX XXXXXXX',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 10 || digits.length > 13
                  ? 'Enter a valid phone number'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: addressController,
            focusNode: addressFocusNode,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Complete delivery address',
              prefixIcon: Icon(Icons.location_on_outlined),
              alignLabelWithHint: true,
            ),
            validator: (value) => (value ?? '').trim().length < 8
                ? 'Enter a complete delivery address'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: landmarkController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nearby landmark (optional)',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notesController,
            maxLength: 150,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Delivery instructions (optional)',
              hintText: 'Gate colour, floor, or rider instructions',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutHeading extends StatelessWidget {
  const _CheckoutHeading({
    required this.number,
    required this.title,
    required this.subtitle,
  });
  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dark,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.available,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF0E4) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.orange : const Color(0xFFE9DED5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5CE),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!available)
                const Text(
                  'SOON',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.orange,
                ),
            ],
          ),
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
  });
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}×',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.menuItem.name} (${item.size})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatUsd(item.totalPrice),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          _SummaryRow(label: 'Subtotal', value: subtotal),
          const SizedBox(height: 9),
          _SummaryRow(label: 'Delivery fee', value: deliveryFee),
          if (serviceFee > 0) ...[
            const SizedBox(height: 9),
            _SummaryRow(label: 'Service fee', value: serviceFee),
          ],
          if (discount > 0) ...[
            const SizedBox(height: 9),
            _SummaryRow(label: 'Coupon discount', value: -discount),
          ],
          const Divider(height: 24),
          _SummaryRow(label: 'Total', value: total, emphasized: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });
  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? AppColors.dark : AppColors.muted,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value < 0 ? '− ${formatUsd(value.abs())}' : formatUsd(value),
          style: TextStyle(
            color: value < 0
                ? const Color(0xFF58A72E)
                : emphasized
                ? AppColors.orange
                : AppColors.dark,
            fontSize: emphasized ? 18 : 14,
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
    required this.onPlaceOrder,
  });
  final double total;
  final bool loading;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: AppPrimaryButton(
          label: 'PLACE ORDER • ${formatUsd(total)}',
          onPressed: onPlaceOrder,
          isLoading: loading,
        ),
      ),
    );
  }
}
