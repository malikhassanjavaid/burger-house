import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../models/cart_item.dart';
import 'checkout_screen.dart';

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
  static const _minimumOrder = 5.00;
  static const _deliveryFee = 1.50;
  late List<CartItem> _items;

  double get _subtotal =>
      _items.fold(0, (total, item) => total + item.totalPrice);
  double get _total => _subtotal + (_items.isEmpty ? 0 : _deliveryFee);
  bool get _meetsMinimum => _subtotal >= _minimumOrder;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  void _updateQuantity(int index, int change) {
    final nextQuantity = _items[index].quantity + change;
    if (nextQuantity <= 0) {
      _removeItem(index);
      return;
    }
    setState(
      () => _items[index] = _items[index].copyWith(quantity: nextQuantity),
    );
    _notifyHome();
  }

  void _removeItem(int index) {
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    _notifyHome();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${removed.menuItem.name} removed'),
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

  void _notifyHome() => widget.onCartChanged(List.of(_items));

  Future<void> _checkout() async {
    final orderPlaced = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          items: _items,
          initialAddress: widget.deliveryAddress,
          deliveryFee: _deliveryFee,
        ),
      ),
    );
    if (orderPlaced != true || !mounted) return;
    setState(() => _items.clear());
    _notifyHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Your cart',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _items.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    children: [
                      Text(
                        '${_items.fold<int>(0, (count, item) => count + item.quantity)} items from Burger House',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        _items.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CartItemCard(
                            cartItem: _items[index],
                            onDecrease: () => _updateQuantity(index, -1),
                            onIncrease: () => _updateQuantity(index, 1),
                            onRemove: () => _removeItem(index),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _OrderSummary(
                        subtotal: _subtotal,
                        deliveryFee: _deliveryFee,
                        total: _total,
                      ),
                      if (!_meetsMinimum) ...[
                        const SizedBox(height: 14),
                        _MinimumOrderNotice(
                          remaining: _minimumOrder - _subtotal,
                        ),
                      ],
                    ],
                  ),
                ),
                _CheckoutBar(
                  total: _total,
                  enabled: _meetsMinimum,
                  onCheckout: _checkout,
                ),
              ],
            ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.cartItem,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem cartItem;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final options = [cartItem.size, ...cartItem.addOns].join(' / ');

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E7E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9D5),
              borderRadius: BorderRadius.circular(17),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              cartItem.menuItem.displayAssetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  cartItem.menuItem.emoji,
                  style: const TextStyle(fontSize: 39),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cartItem.menuItem.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove item',
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.muted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Text(
                  options,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                if (cartItem.instructions.trim().isNotEmpty)
                  Text(
                    '“${cartItem.instructions.trim()}”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuantityButton(icon: Icons.remove, onPressed: onDecrease),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${cartItem.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    _QuantityButton(icon: Icons.add, onPressed: onIncrease),
                    const Spacer(),
                    Text(
                      formatUsd(cartItem.totalPrice),
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w900,
                      ),
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
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onPressed,
      child: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5CE),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: AppColors.orange, size: 17),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });
  final double subtotal;
  final double deliveryFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'Subtotal', amount: subtotal),
          const SizedBox(height: 11),
          _PriceRow(label: 'Delivery fee', amount: deliveryFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1),
          ),
          _PriceRow(label: 'Total', amount: total, emphasized: true),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });
  final String label;
  final double amount;
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
          formatUsd(amount),
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

class _MinimumOrderNotice extends StatelessWidget {
  const _MinimumOrderNotice({required this.remaining});
  final double remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5CE),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add ${formatUsd(remaining)} more to reach the minimum order.',
              style: const TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.enabled,
    required this.onCheckout,
  });
  final double total;
  final bool enabled;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: enabled ? onCheckout : null,
          child: Text('Checkout • ${formatUsd(total)}'),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE5CE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 54,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add something delicious from the Burger House menu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Browse menu'),
            ),
          ],
        ),
      ),
    );
  }
}
