import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../models/cart_item.dart';

enum PaymentMethod { cashOnDelivery, card, wallet }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    required this.initialAddress,
    required this.deliveryFee,
  });

  final List<CartItem> items;
  final String initialAddress;
  final double deliveryFee;

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

  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  bool _isPlacingOrder = false;

  double get _subtotal =>
      widget.items.fold(0, (total, item) => total + item.totalPrice);
  double get _total => _subtotal + widget.deliveryFee;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _addressController.text = widget.initialAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _notesController.dispose();
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'Please sign in again before placing your order.',
        );
      }

      final order = await FirebaseFirestore.instance.collection('orders').add({
        'customerId': user.uid,
        'customerEmail': user.email,
        'receiverName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'deliveryAddress': _addressController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'deliveryNotes': _notesController.text.trim(),
        'paymentMethod': 'cash_on_delivery',
        'paymentStatus': 'pending',
        'status': 'placed',
        'subtotal': _subtotal,
        'deliveryFee': widget.deliveryFee,
        'total': _total,
        'items': widget.items
            .map(
              (item) => {
                'menuItemId': item.menuItem.id,
                'name': item.menuItem.name,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'totalPrice': item.totalPrice,
                'size': item.size,
                'addOns': item.addOns,
                'instructions': item.instructions,
              },
            )
            .toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      final shortId = order.id.length > 6
          ? order.id.substring(order.id.length - 6).toUpperCase()
          : order.id.toUpperCase();
      final orderNumber = 'BH-$shortId';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF26A269),
            size: 58,
          ),
          title: const Text('Order confirmed!'),
          content: Text(
            'Your order $orderNumber has been received. Payment will be collected on delivery.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context, true);
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
                    const _CheckoutHeading(
                      number: '1',
                      title: 'Delivery address',
                      subtitle: 'Where should we deliver your order?',
                    ),
                    const SizedBox(height: 14),
                    _AddressForm(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                      landmarkController: _landmarkController,
                      notesController: _notesController,
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

class _AddressForm extends StatelessWidget {
  const _AddressForm({
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.landmarkController,
    required this.notesController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController landmarkController;
  final TextEditingController notesController;

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
    required this.total,
  });
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
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
          formatUsd(value),
          style: TextStyle(
            color: emphasized ? AppColors.orange : AppColors.dark,
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
        child: ElevatedButton(
          onPressed: loading ? null : onPlaceOrder,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text('Place order • ${formatUsd(total)}'),
        ),
      ),
    );
  }
}
