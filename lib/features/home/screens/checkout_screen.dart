import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../location/models/delivery_location.dart';
import '../models/cart_item.dart';
import '../models/fulfillment_method.dart';
import '../services/order_service.dart';
import 'order_confirmation_screen.dart';

enum PaymentMethod { cashOnDelivery, card }

extension on PaymentMethod {
  String valueFor(FulfillmentMethod fulfillmentMethod) {
    if (fulfillmentMethod.isPickup) return 'card_at_pickup';
    return this == PaymentMethod.cashOnDelivery
        ? 'cash_on_delivery'
        : 'card_on_delivery';
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
    _phoneController.text = user?.phoneNumber ?? '';
    _addressController.text = widget.initialAddress;
    _notesController.text = widget.initialDeliveryNotes;
    if (widget.fulfillmentMethod.isPickup) {
      _paymentMethod = PaymentMethod.card;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
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
          fulfillmentMethod: widget.fulfillmentMethod,
          deliveryAddress: widget.fulfillmentMethod.isPickup
              ? '${HungrySpotPickup.storeName}, ${HungrySpotPickup.address}'
              : _addressController.text.trim(),
          landmark: '',
          deliveryNotes: _notesController.text.trim(),
          paymentMethod: _paymentMethod.valueFor(widget.fulfillmentMethod),
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
          ? 'Firestore rules do not allow this payment option yet.'
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
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 18),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: isPickup ? const Color(0xFFFFF3D5) : AppColors.blush,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  isPickup
                      ? Icons.storefront_rounded
                      : Icons.delivery_dining_rounded,
                  size: 15,
                  color: isPickup ? const Color(0xFFD68A00) : AppColors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.fulfillmentMethod.label,
                  style: TextStyle(
                    color: isPickup ? const Color(0xFFA86C00) : AppColors.red,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    _SectionTitle(
                      title: isPickup
                          ? 'Pickup this order at'
                          : 'Deliver this order to',
                    ),
                    const SizedBox(height: 10),
                    _FulfillmentLocationCard(
                      fulfillmentMethod: widget.fulfillmentMethod,
                      location: widget.initialLocation,
                      addressController: _addressController,
                      onEdit: isPickup
                          ? null
                          : () => _addressFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Contact details'),
                    const SizedBox(height: 10),
                    _ContactDetailsCard(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                      notesController: _notesController,
                      addressFocusNode: _addressFocusNode,
                      isPickup: isPickup,
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Payment'),
                    const SizedBox(height: 10),
                    if (!isPickup) ...[
                      _PaymentTile(
                        icon: Icons.payments_rounded,
                        title: 'Cash on delivery',
                        subtitle: 'Pay the rider when your food arrives',
                        selected:
                            _paymentMethod == PaymentMethod.cashOnDelivery,
                        onTap: () => setState(
                          () => _paymentMethod = PaymentMethod.cashOnDelivery,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _PaymentTile(
                        icon: Icons.credit_card_rounded,
                        title: 'Card on delivery',
                        subtitle: 'Pay using the rider’s card machine',
                        selected: _paymentMethod == PaymentMethod.card,
                        onTap: () =>
                            setState(() => _paymentMethod = PaymentMethod.card),
                      ),
                    ] else
                      _PaymentTile(
                        icon: Icons.credit_card_rounded,
                        title: 'Card at pickup',
                        subtitle: 'Pay by card at the Hungry Spot counter',
                        selected: true,
                        onTap: () {},
                      ),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Summary'),
                    const SizedBox(height: 10),
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

class _FulfillmentLocationCard extends StatelessWidget {
  const _FulfillmentLocationCard({
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
    final isPickup = fulfillmentMethod.isPickup;

    return Container(
      key: ValueKey(
        isPickup ? 'checkout-pickup-location' : 'checkout-delivery-location',
      ),
      height: 132,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E4E6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: .055),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 4, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          color: isPickup
                              ? const Color(0xFFFFF3D5)
                              : AppColors.blush,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPickup
                              ? Icons.storefront_rounded
                              : Icons.location_on_rounded,
                          color: isPickup
                              ? const Color(0xFFE09A00)
                              : AppColors.red,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isPickup
                              ? HungrySpotPickup.storeName
                              : (location?.label.trim().isNotEmpty == true
                                    ? location!.label
                                    : 'Delivery address'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: addressController,
                      builder: (context, value, _) {
                        final address = isPickup
                            ? HungrySpotPickup.address
                            : value.text.trim();
                        return Text(
                          address.isEmpty
                              ? 'Add your complete delivery address'
                              : address,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  if (onEdit != null)
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          'EDIT ADDRESS',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .25,
                          ),
                        ),
                      ),
                    )
                  else
                    const Text(
                      'MAIN PICKUP COUNTER',
                      style: TextStyle(
                        color: Color(0xFFD68A00),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .25,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 112,
            height: 112,
            child: _LocationPreview(
              location: isPickup ? null : location,
              isPickup: isPickup,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.location, required this.isPickup});

  final DeliveryLocation? location;
  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    final latitude = location?.latitude;
    final longitude = location?.longitude;
    final point = latitude != null && longitude != null
        ? LatLng(latitude, longitude)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (point != null)
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(initialCenter: point, initialZoom: 15.5),
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
                        width: 38,
                        height: 38,
                        child: const _MapPin(icon: Icons.home_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            const ColoredBox(
              color: Color(0xFFF8EEF0),
              child: Stack(
                children: [
                  Positioned(
                    left: -15,
                    top: 17,
                    child: Icon(
                      Icons.route_rounded,
                      color: Color(0x24F23845),
                      size: 94,
                    ),
                  ),
                ],
              ),
            ),
          if (point == null)
            Center(
              child: _MapPin(
                icon: isPickup
                    ? Icons.storefront_rounded
                    : Icons.location_on_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x33F23845), blurRadius: 10)],
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    );
  }
}

class _ContactDetailsCard extends StatelessWidget {
  const _ContactDetailsCard({
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.notesController,
    required this.addressFocusNode,
    required this.isPickup,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController notesController;
  final FocusNode addressFocusNode;
  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E4E6)),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Customer name',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
            validator: (value) =>
                (value ?? '').trim().length < 2 ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '03XX XXXXXXX',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 10 || digits.length > 13
                  ? 'Enter a valid phone number'
                  : null;
            },
          ),
          if (!isPickup) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: addressController,
              focusNode: addressFocusNode,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                labelText: 'Complete delivery address',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final address = (value ?? '').trim();
                if (address.length < 8 ||
                    address.toLowerCase().startsWith('set your')) {
                  return 'Enter a complete delivery address';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: notesController,
            maxLines: 2,
            maxLength: 150,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: isPickup
                  ? 'Kitchen note (optional)'
                  : 'Delivery note (optional)',
              prefixIcon: const Icon(Icons.notes_rounded, size: 20),
              alignLabelWithHint: true,
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blush : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.red : const Color(0xFFF0E4E6),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.red, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.8,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.red : AppColors.muted,
                size: 21,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E4E6)),
      ),
      child: Column(
        children: [
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 25),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blush,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${item.quantity}×',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
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
          const Divider(height: 20, color: Color(0xFFF0E4E6)),
          _SummaryRow(label: 'Subtotal', value: subtotal),
          const SizedBox(height: 9),
          _SummaryRow(
            label: isPickup ? 'Pickup' : 'Delivery',
            value: deliveryFee,
            freeLabel: isPickup ? 'FREE' : null,
          ),
          if (serviceFee > 0) ...[
            const SizedBox(height: 9),
            _SummaryRow(label: 'Service fee', value: serviceFee),
          ],
          if (discount > 0) ...[
            const SizedBox(height: 9),
            _SummaryRow(label: 'Voucher discount', value: -discount),
          ],
          const Divider(height: 22, color: Color(0xFFF0E4E6)),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0E4E6))),
      ),
      child: SafeArea(
        top: false,
        child: AppPrimaryButton(
          label:
              '${isPickup ? 'CONFIRM PICKUP' : 'PLACE ORDER'}  •  ${formatUsd(total)}',
          onPressed: onPlaceOrder,
          isLoading: loading,
          height: 52,
          borderRadius: 16,
        ),
      ),
    );
  }
}
