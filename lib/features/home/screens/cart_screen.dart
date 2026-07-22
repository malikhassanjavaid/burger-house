import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/utils/currency.dart';
import '../data/sample_menu.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import 'checkout_screen.dart';
import 'menu_details_screen.dart';

const _cartBg = Color(0xFFF4FAFE);
const _cartRed = Color(0xFFF23845);
const _cartBlue = Color(0xFF1597E5);
const _cartInk = Color(0xFF15161C);
const _cartMuted = Color(0xFF858C98);

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.items,
    required this.deliveryAddress,
    required this.onCartChanged,
  });

  final List<CartItem> items;
  final String deliveryAddress;
  final ValueChanged<List<CartItem>> onCartChanged;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _minimumOrder = 5.0;
  static const _deliveryFee = 1.5;
  late List<CartItem> _items;
  late List<MenuItem> _recommendations;
  String _deliveryNotes = '';
  String? _couponCode;

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get _serviceFee => _items.isEmpty ? 0 : _subtotal * .05;
  double get _discount => _couponCode == null ? 0 : _subtotal * .10;
  double get _total =>
      _subtotal - _discount + (_items.isEmpty ? 0 : _deliveryFee) + _serviceFee;
  bool get _meetsMinimum => _subtotal >= _minimumOrder;
  int get _itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
    _refreshRecommendations();
  }

  void _refreshRecommendations() {
    final random = Random();
    final categories = <String>['Sides', 'Drinks', 'Chicken']..shuffle(random);
    final selected = <MenuItem>[];
    for (final category in categories) {
      final choices =
          sampleMenu
              .where(
                (item) =>
                    item.category == category &&
                    !_items.any((cart) => cart.menuItem.id == item.id),
              )
              .toList()
            ..shuffle(random);
      if (choices.isNotEmpty) selected.add(choices.first);
      if (selected.length == 2) break;
    }
    _recommendations = selected;
  }

  void _notifyHome() => widget.onCartChanged(List.of(_items));

  void _changeQuantity(int index, int change) {
    final next = _items[index].quantity + change;
    if (next <= 0) {
      _removeItem(index);
      return;
    }
    setState(() => _items[index] = _items[index].copyWith(quantity: next));
    _notifyHome();
  }

  void _removeItem(int index) {
    final removed = _items[index];
    setState(() {
      _items.removeAt(index);
      _refreshRecommendations();
    });
    _notifyHome();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.menuItem.name} removed'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _items.insert(index, removed);
              _refreshRecommendations();
            });
            _notifyHome();
          },
        ),
      ),
    );
  }

  void _addRecommendation(MenuItem item) {
    setState(() {
      _items.add(CartItem(menuItem: item, quantity: 1, unitPrice: item.price));
      _refreshRecommendations();
    });
    _notifyHome();
  }

  Future<void> _showItemDetails(int index) async {
    final item = _items[index];
    final shouldEdit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) => _CartItemDetailsSheet(item: item),
    );
    if (shouldEdit == true && mounted) await _editCartItem(index);
  }

  Future<void> _editCartItem(int index) async {
    if (index >= _items.length) return;
    final original = _items[index];
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MenuDetailsScreen(
          item: original.menuItem,
          initialCartItem: original,
          onAddToCart: (updated) {
            if (!mounted || index >= _items.length) return;
            setState(() => _items[index] = updated);
            _notifyHome();
          },
        ),
      ),
    );
  }

  Future<void> _editInstructions() async {
    final controller = TextEditingController(text: _deliveryNotes);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          10,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(width: 42, child: Divider(thickness: 4)),
            ),
            const SizedBox(height: 15),
            const Text(
              'Delivery instructions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Help your rider find you and deliver smoothly.',
              style: TextStyle(color: _cartMuted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 150,
              decoration: const InputDecoration(
                hintText: 'Gate colour, floor, or rider instructions...',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: FilledButton.styleFrom(backgroundColor: _cartRed),
                child: const Text('SAVE INSTRUCTIONS'),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result != null && mounted) setState(() => _deliveryNotes = result);
  }

  Future<void> _applyCoupon() async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          10,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(width: 42, child: Divider(thickness: 4)),
            ),
            const SizedBox(height: 15),
            const Text(
              'Apply coupon',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try BURGER10 for 10% off your food subtotal.',
              style: TextStyle(color: _cartMuted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Coupon code',
                prefixIcon: Icon(Icons.local_offer_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  controller.text.trim().toUpperCase(),
                ),
                style: FilledButton.styleFrom(backgroundColor: _cartRed),
                child: const Text('APPLY COUPON'),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;
    if (result == 'BURGER10') {
      setState(() => _couponCode = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('BURGER10 applied — you saved 10%!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That coupon code is not valid.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkout() async {
    final placed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          items: _items,
          initialAddress: widget.deliveryAddress,
          initialDeliveryNotes: _deliveryNotes,
          deliveryFee: _deliveryFee,
          serviceFee: _serviceFee,
          discount: _discount,
          couponCode: _couponCode,
        ),
      ),
    );
    if (placed != true || !mounted) return;
    setState(() => _items.clear());
    _notifyHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cartBg,
      body: _items.isEmpty
          ? _EmptyCart(onBack: () => Navigator.pop(context))
          : Column(
              children: [
                _CartHeader(
                  itemCount: _itemCount,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                    children: [
                      ...List.generate(
                        _items.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: _CartItemCard(
                            item: _items[index],
                            onRemove: () => _removeItem(index),
                            onIncrease: () => _changeQuantity(index, 1),
                            onViewDetails: () => _showItemDetails(index),
                          ),
                        ),
                      ),
                      _ActionCard(
                        icon: Icons.edit_note_rounded,
                        title: _deliveryNotes.isEmpty
                            ? 'Add Delivery Instructions (Optional)'
                            : _deliveryNotes,
                        onTap: _editInstructions,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Complete Your Meal',
                        style: TextStyle(
                          color: _cartInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_recommendations.length, (
                          index,
                        ) {
                          final item = _recommendations[index];
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index == _recommendations.length - 1
                                    ? 0
                                    : 10,
                              ),
                              child: _RecommendationCard(
                                item: item,
                                onAdd: () => _addRecommendation(item),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 27),
                      _ActionCard(
                        icon: Icons.menu_book_outlined,
                        title: 'Explore Menu',
                        subtitle: 'Add more items in your cart',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.local_offer_outlined,
                        iconColor: _cartRed,
                        title: _couponCode == null
                            ? 'Apply Coupon'
                            : 'Coupon $_couponCode applied',
                        subtitle: _couponCode == null
                            ? 'Apply coupon & view great offers available'
                            : '10% discount added',
                        onTap: _applyCoupon,
                      ),
                      const SizedBox(height: 12),
                      _TotalsCard(
                        subtotal: _subtotal,
                        delivery: _deliveryFee,
                        service: _serviceFee,
                        discount: _discount,
                        total: _total,
                      ),
                      if (!_meetsMinimum)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Add ${formatUsd(_minimumOrder - _subtotal)} more to reach the minimum order.',
                            style: const TextStyle(
                              color: _cartRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _CartBottomBar(
                  item: _items.first.menuItem,
                  itemCount: _itemCount,
                  total: _total,
                  enabled: _meetsMinimum,
                  onCheckout: _checkout,
                ),
              ],
            ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.itemCount, required this.onBack});
  final int itemCount;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: SizedBox(
      height: 82,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              elevation: 5,
              shadowColor: Colors.black12,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _cartBlue,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 15),
            const Text(
              'Cart',
              style: TextStyle(
                color: _cartInk,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              '($itemCount Item${itemCount == 1 ? '' : 's'})',
              style: const TextStyle(color: _cartInk, fontSize: 12),
            ),
            const Spacer(),
            const Text(
              'EDIT',
              style: TextStyle(
                color: _cartBlue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onIncrease,
    required this.onViewDetails,
  });
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onViewDetails;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      boxShadow: const [
        BoxShadow(
          color: Color(0x160C3955),
          blurRadius: 17,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            item.menuItem.displayAssetPath,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.menuItem.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _cartInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    formatUsd(item.totalPrice),
                    style: const TextStyle(
                      color: _cartInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                [item.size, ...item.addOns.take(1)].join(' | '),
                style: const TextStyle(color: _cartInk, fontSize: 11),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(
                    onTap: onViewDetails,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: _cartBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            color: _cartBlue,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _SquareButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFF435163),
                    onTap: onRemove,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _SquareButton(
                    icon: Icons.add_rounded,
                    color: _cartRed,
                    onTap: onIncrease,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CartItemDetailsSheet extends StatelessWidget {
  const _CartItemDetailsSheet({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final configuration = <String>[
      if (item.size.trim().isNotEmpty) item.size,
      ...item.addOns,
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
              decoration: const BoxDecoration(
                color: _cartBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2DBE1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.menuItem.name,
                    style: const TextStyle(
                      color: _cartInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatUsd(item.totalPrice),
                    style: const TextStyle(
                      color: _cartMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (configuration.isNotEmpty) ...[
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: configuration
                            .map(
                              (value) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F7FB),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    color: _cartInk,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 15),
                    ],
                    Text(
                      item.menuItem.description,
                      style: const TextStyle(
                        color: Color(0xFF4F5660),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(
                color: _cartBg,
                border: Border(top: BorderSide(color: Color(0xFFE3EBF0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cartInk,
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: FilledButton.styleFrom(
                        backgroundColor: _cartRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor = const Color(0xFF2F3B48),
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(13),
    elevation: 5,
    shadowColor: const Color(0x180C3955),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtitle == null ? _cartMuted : _cartInk,
                      fontSize: subtitle == null ? 13 : 15,
                      fontWeight: subtitle == null
                          ? FontWeight.w500
                          : FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(color: _cartMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (subtitle != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _cartInk,
                size: 17,
              ),
          ],
        ),
      ),
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onAdd});
  final MenuItem item;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 205,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      boxShadow: const [
        BoxShadow(
          color: Color(0x160C3955),
          blurRadius: 17,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: Image.asset(item.displayAssetPath, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _cartInk,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              formatUsd(item.price),
              style: const TextStyle(
                color: _cartInk,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Add', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: _cartRed,
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.subtotal,
    required this.delivery,
    required this.service,
    required this.discount,
    required this.total,
  });
  final double subtotal;
  final double delivery;
  final double service;
  final double discount;
  final double total;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
    color: Colors.white,
    child: Column(
      children: [
        _TotalRow(label: 'Sub Total', value: subtotal),
        const SizedBox(height: 13),
        _TotalRow(label: 'Delivery  ●', value: delivery),
        const SizedBox(height: 13),
        _TotalRow(label: 'Service Fee  ●', value: service),
        if (discount > 0) ...[
          const SizedBox(height: 13),
          _TotalRow(label: 'Coupon discount', value: -discount, discount: true),
        ],
        const SizedBox(height: 18),
        _TotalRow(label: 'Total', value: total, strong: true),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Inclusive of applicable taxes',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.discount = false,
  });
  final String label;
  final double value;
  final bool strong;
  final bool discount;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: strong ? _cartInk : _cartMuted,
            fontSize: strong ? 14 : 12,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
      Text(
        '${discount ? '− ' : ''}${formatUsd(value.abs())}',
        style: TextStyle(
          color: discount ? const Color(0xFF58A72E) : _cartInk,
          fontSize: strong ? 14 : 12,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );
}

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({
    required this.item,
    required this.itemCount,
    required this.total,
    required this.enabled,
    required this.onCheckout,
  });
  final MenuItem item;
  final int itemCount;
  final double total;
  final bool enabled;
  final VoidCallback onCheckout;
  @override
  Widget build(BuildContext context) => Container(
    color: _cartBg,
    padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
    child: SafeArea(
      top: false,
      child: Container(
        height: 76,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _cartRed,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 48,
                height: 48,
                color: Colors.white,
                child: Image.asset(item.displayAssetPath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemCount ITEM${itemCount == 1 ? '' : 'S'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatUsd(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'inclusive of taxes',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: enabled ? onCheckout : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _cartRed,
                disabledBackgroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CHECKOUT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 62,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.shopping_cart_outlined,
                color: _cartRed,
                size: 55,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                color: _cartInk,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add something delicious from the Hungry Spot menu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _cartMuted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(backgroundColor: _cartRed),
              child: const Text('EXPLORE MENU'),
            ),
          ],
        ),
      ),
    ),
  );
}
