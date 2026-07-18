import 'package:flutter/material.dart';

import '../../../core/utils/currency.dart';
import '../data/sample_menu.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import 'checkout_screen.dart';

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
  String _deliveryNotes = '';
  bool _noKetchup = true;
  bool _noCutlery = true;
  String? _couponCode;

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get _serviceFee => _items.isEmpty ? 0 : _subtotal * .05;
  double get _discount => _couponCode == null ? 0 : _subtotal * .10;
  double get _total =>
      _subtotal - _discount + (_items.isEmpty ? 0 : _deliveryFee) + _serviceFee;
  bool get _meetsMinimum => _subtotal >= _minimumOrder;
  int get _itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  MenuItem get _recommended => sampleMenu.firstWhere(
    (item) =>
        item.category == 'Sides' &&
        !_items.any((cart) => cart.menuItem.id == item.id),
    orElse: () => sampleMenu.firstWhere((item) => item.category == 'Drinks'),
  );

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
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
    setState(() => _items.removeAt(index));
    _notifyHome();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.menuItem.name} removed'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() => _items.insert(index, removed));
            _notifyHome();
          },
        ),
      ),
    );
  }

  void _addRecommendation() {
    final item = _recommended;
    setState(
      () => _items.add(
        CartItem(menuItem: item, quantity: 1, unitPrice: item.price),
      ),
    );
    _notifyHome();
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
                      const SizedBox(height: 13),
                      _EcoCard(
                        noKetchup: _noKetchup,
                        noCutlery: _noCutlery,
                        onKetchup: () =>
                            setState(() => _noKetchup = !_noKetchup),
                        onCutlery: () =>
                            setState(() => _noCutlery = !_noCutlery),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Complete Your Meal',
                        style: TextStyle(
                          color: _cartInk,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _RecommendationCard(
                        item: _recommended,
                        onAdd: _addRecommendation,
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
      height: 90,
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
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              '($itemCount Item${itemCount == 1 ? '' : 's'})',
              style: const TextStyle(color: _cartInk, fontSize: 14),
            ),
            const Spacer(),
            const Text(
              'EDIT',
              style: TextStyle(
                color: _cartBlue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
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
  });
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  @override
  Widget build(BuildContext context) => Container(
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 92,
          height: 92,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    formatUsd(item.totalPrice),
                    style: const TextStyle(
                      color: _cartInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                [item.size, ...item.addOns.take(1)].join(' | '),
                style: const TextStyle(color: _cartInk, fontSize: 13),
              ),
              const SizedBox(height: 21),
              Row(
                children: [
                  const Text(
                    'View Details',
                    style: TextStyle(
                      color: _cartBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    color: _cartBlue,
                    size: 19,
                  ),
                  const Spacer(),
                  _SquareButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFF435163),
                    onTap: onRemove,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
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
                      fontSize: subtitle == null ? 16 : 18,
                      fontWeight: subtitle == null
                          ? FontWeight.w500
                          : FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(color: _cartMuted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            if (subtitle != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _cartInk,
                size: 20,
              ),
          ],
        ),
      ),
    ),
  );
}

class _EcoCard extends StatelessWidget {
  const _EcoCard({
    required this.noKetchup,
    required this.noCutlery,
    required this.onKetchup,
    required this.onCutlery,
  });
  final bool noKetchup;
  final bool noCutlery;
  final VoidCallback onKetchup;
  final VoidCallback onCutlery;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
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
        const Icon(Icons.eco_rounded, color: Color(0xFF70BB35), size: 35),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    color: const Color(0xFF75B848),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    child: const Text(
                      'ACT GREEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Small acts, when multiplied by several people, can change the world',
                style: TextStyle(color: _cartMuted, height: 1.35, fontSize: 12),
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 8,
                runSpacing: 7,
                children: [
                  _EcoChip(
                    label: 'NO KETCHUP 🙏',
                    selected: noKetchup,
                    onTap: onKetchup,
                  ),
                  _EcoChip(
                    label: 'NO CUTLERY 🙏',
                    selected: noCutlery,
                    onTap: onCutlery,
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

class _EcoChip extends StatelessWidget {
  const _EcoChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: const Color(0xFF65BD35),
            size: 18,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4D5965),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    width: 210,
    height: 238,
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
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              formatUsd(item.price),
              style: const TextStyle(
                color: _cartInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: _cartRed),
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
              fontSize: 12,
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
            fontSize: strong ? 16 : 14,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
      ),
      Text(
        '${discount ? '− ' : ''}${formatUsd(value.abs())}',
        style: TextStyle(
          color: discount ? const Color(0xFF58A72E) : _cartInk,
          fontSize: strong ? 16 : 14,
          fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
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
        height: 86,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cartRed,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 55,
                height: 55,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CHECKOUT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
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
              'Add something delicious from the BurgerHouse menu.',
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
