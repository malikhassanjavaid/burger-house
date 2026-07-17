import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class MenuDetailsScreen extends StatefulWidget {
  const MenuDetailsScreen({
    super.key,
    required this.item,
    required this.onAddToCart,
  });

  final MenuItem item;
  final ValueChanged<CartItem> onAddToCart;

  @override
  State<MenuDetailsScreen> createState() => _MenuDetailsScreenState();
}

class _MenuDetailsScreenState extends State<MenuDetailsScreen> {
  final _instructionsController = TextEditingController();
  final Set<String> _selectedAddOns = {};
  late String _selectedSize;
  int _quantity = 1;

  Map<String, double> get _sizes => switch (widget.item.category) {
    'Pizzas' => const {'Regular 10"': 0.0, 'Large 14"': 4.00},
    'Drinks' => const {'Regular': 0.0, 'Large': 1.00},
    'Deals' => const {'Standard bundle': 0.0},
    'Desserts' => const {'Single serving': 0.0},
    _ => const {'Regular': 0.0, 'Large': 1.50},
  };

  Map<String, double> get _addOns => switch (widget.item.category) {
    'Burgers' || 'Wraps' => const {
      'Extra cheese': 1.00,
      'Jalapenos': .60,
      'House sauce': .80,
    },
    'Pizzas' => const {
      'Extra mozzarella': 1.50,
      'Jalapenos': .75,
      'Extra chicken': 2.00,
    },
    'Chicken' => const {
      'Garlic dip': .75,
      'Cheese sauce': 1.00,
      'Spicy glaze': .75,
    },
    'Sides' => const {
      'Cheese sauce': 1.00,
      'Jalapenos': .60,
      'House sauce': .80,
    },
    'Drinks' => const {
      'Whipped cream': .60,
      'Chocolate drizzle': .50,
    },
    'Desserts' => const {
      'Vanilla ice cream': 1.25,
      'Chocolate sauce': .60,
      'Fresh strawberries': 1.00,
    },
    _ => const <String, double>{},
  };

  double get _unitPrice =>
      widget.item.price +
      (_sizes[_selectedSize] ?? 0) +
      _selectedAddOns.fold<double>(
        0,
        (total, addOn) => total + (_addOns[addOn] ?? 0),
      );

  @override
  void initState() {
    super.initState();
    _selectedSize = _sizes.keys.first;
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  void _addToCart() {
    widget.onAddToCart(
      CartItem(
        menuItem: widget.item,
        quantity: _quantity,
        unitPrice: _unitPrice,
        size: _selectedSize,
        addOns: _selectedAddOns.toList(),
        instructions: _instructionsController.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Item details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FoodPreview(item: widget.item),
                        const SizedBox(height: 24),
                        _ItemIntroduction(item: widget.item),
                        const SizedBox(height: 30),
                        const _OptionHeading(
                          title: 'Choose a size',
                          label: 'Required',
                        ),
                        const SizedBox(height: 12),
                        ..._sizes.entries.map(
                          (size) => _ChoiceTile(
                            title: size.key,
                            price: size.value == 0
                                ? 'Included'
                                : '+ ${formatUsd(size.value)}',
                            selected: _selectedSize == size.key,
                            onTap: () =>
                                setState(() => _selectedSize = size.key),
                          ),
                        ),
                        if (_addOns.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const _OptionHeading(
                            title: 'Make it yours',
                            label: 'Optional',
                          ),
                          const SizedBox(height: 12),
                          ..._addOns.entries.map(
                            (addOn) => _ChoiceTile(
                              title: addOn.key,
                              price: '+ ${formatUsd(addOn.value)}',
                              selected: _selectedAddOns.contains(addOn.key),
                              checkbox: true,
                              onTap: () => setState(() {
                                if (!_selectedAddOns.add(addOn.key)) {
                                  _selectedAddOns.remove(addOn.key);
                                }
                              }),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const _OptionHeading(
                          title: 'Special instructions',
                          label: 'Optional',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _instructionsController,
                          maxLines: 3,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            hintText: 'No onions, sauce on the side...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _CartBar(
              quantity: _quantity,
              total: _unitPrice * _quantity,
              onDecrease: _quantity == 1
                  ? null
                  : () => setState(() => _quantity--),
              onIncrease: () => setState(() => _quantity++),
              onAdd: _addToCart,
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodPreview extends StatelessWidget {
  const _FoodPreview({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEAD8), Color(0xFFFFC995)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .24),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Hero(
                tag: 'menu-art-${item.id}',
                child: Image.asset(
                  item.displayAssetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 115),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (item.oldPrice != null)
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'SAVE ${formatUsd(item.oldPrice! - item.price)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemIntroduction extends StatelessWidget {
  const _ItemIntroduction({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text(
              formatUsd(item.price),
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFB000), size: 20),
            const SizedBox(width: 3),
            Text(
              '${item.rating}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 10),
            Text(item.category, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 14),
        Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _OptionHeading extends StatelessWidget {
  const _OptionHeading({required this.title, required this.label});
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5CE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.checkbox = false,
  });
  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  final bool checkbox;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected ? const Color(0xFFFFF0E4) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected ? AppColors.orange : const Color(0xFFE9DED5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  checkbox
                      ? (selected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded)
                      : (selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off),
                  color: selected ? AppColors.orange : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.quantity,
    required this.total,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAdd,
  });
  final int quantity;
  final double total;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onDecrease,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: onIncrease,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onAdd,
                child: Text('Add • ${formatUsd(total)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
