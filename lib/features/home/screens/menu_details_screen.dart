import 'package:flutter/material.dart';

import '../../../core/utils/currency.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

const _pageBlue = Color(0xFFF4FAFE);
const _accentRed = Color(0xFFF23845);
const _accentBlue = Color(0xFF1597E5);
const _accentGold = Color(0xFFF5A313);
const _ink = Color(0xFF14151B);
const _softText = Color(0xFF7D8490);

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
  final int _quantity = 1;
  late String _size;
  late String _crust;
  final Set<String> _extras = {};
  final Set<String> _removedDefaults = {};

  Map<String, double> get _sizes => switch (widget.item.category) {
    'Pizzas' => const {'Small': 0, 'Medium': 4, 'Large': 7},
    'Drinks' => const {'Small': 0, 'Medium': 1, 'Large': 2},
    _ => const {'Regular': 0, 'Large': 1.5},
  };

  Map<String, double> get _crusts => widget.item.category == 'Pizzas'
      ? const {'Pan': 0, 'Thin & Crispy': 1, 'Cheese Stuffed': 3}
      : const {'Classic': 0, 'Toasted': .75};

  Map<String, double> get _toppings => switch (widget.item.category) {
    'Pizzas' => const {
      'Fresh Mushrooms': 1.25,
      'Mozzarella': 0,
      'Red Onion': 0,
      'Sliced Jalapeños': 1,
      'Green Capsicum': 0,
    },
    'Burgers' || 'Wraps' => const {
      'Fresh Cut Onions': 0,
      'Cheddar Cheese': 0,
      'Jalapenos': .75,
      'Extra Patty': 2.5,
    },
    _ => const {'Extra serving': 1, 'Fresh herbs': .5},
  };

  double get _unitPrice =>
      widget.item.price +
      (_sizes[_size] ?? 0) +
      (_crusts[_crust] ?? 0) +
      _extras.fold(0, (sum, name) {
        return sum + (_toppings[name] ?? 0);
      });

  @override
  void initState() {
    super.initState();
    _size = widget.item.category == 'Pizzas' && _sizes.containsKey('Medium')
        ? 'Medium'
        : _sizes.keys.first;
    _crust = _crusts.keys.first;
  }

  void _addToCart() {
    widget.onAddToCart(
      CartItem(
        menuItem: widget.item,
        quantity: _quantity,
        unitPrice: _unitPrice,
        size: _size,
        addOns: ['$_crust crust', ..._extras],
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBlue,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ProductHero(
                    item: widget.item,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ProductSummary(item: widget.item, price: _unitPrice),
                ),
                SliverToBoxAdapter(child: _buildCustomizationFlow()),
                const SliverToBoxAdapter(child: SizedBox(height: 34)),
              ],
            ),
          ),
          _ProductBottomBar(
            item: widget.item,
            quantity: _quantity,
            total: _unitPrice * _quantity,
            onAdd: _addToCart,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationFlow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 25, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SizeSection(
            entries: _sizes,
            selected: _size,
            basePrice: widget.item.price,
            pizzaStyle: widget.item.category == 'Pizzas',
            onSelected: (value) => setState(() => _size = value),
          ),
          const SizedBox(height: 38),
          _CrustSection(
            entries: _crusts,
            selected: _crust,
            onSelected: (value) => setState(() => _crust = value),
          ),
          const SizedBox(height: 38),
          _ExtrasSection(
            title: 'Choose Toppings',
            entries: _toppings,
            selected: _extras,
            removedDefaults: _removedDefaults,
            onToggle: _toggleExtra,
            onDefaultToggle: _toggleDefault,
          ),
        ],
      ),
    );
  }

  void _toggleExtra(String value) {
    setState(() {
      if (!_extras.add(value)) _extras.remove(value);
    });
  }

  void _toggleDefault(String value) {
    setState(() {
      if (!_removedDefaults.add(value)) _removedDefaults.remove(value);
    });
  }
}

class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.item, required this.onBack});

  final MenuItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(55, 32, 55, 12),
                child: Hero(
                  tag: 'menu-art-${item.id}',
                  child: Image.asset(
                    item.displayAssetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 130),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 12,
              child: _FloatingButton(
                icon: Icons.arrow_back_ios_new_rounded,
                color: _accentBlue,
                onTap: onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  const _FloatingButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 5,
      shadowColor: Colors.black12,
      child: IconButton(
        onPressed: onTap,
        color: color,
        icon: Icon(icon, size: 21),
      ),
    );
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.item, required this.price});
  final MenuItem item;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 19),
      decoration: const BoxDecoration(
        color: _pageBlue,
        border: Border(bottom: BorderSide(color: Color(0xFFDDE6EC))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 23,
              height: 1.08,
              letterSpacing: -.7,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            item.description,
            style: const TextStyle(
              color: Color(0xFF4F5660),
              fontSize: 13,
              height: 1.5,
              letterSpacing: .05,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            formatUsd(price),
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _accentGold,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _SizeSection extends StatelessWidget {
  const _SizeSection({
    required this.entries,
    required this.selected,
    required this.basePrice,
    required this.pizzaStyle,
    required this.onSelected,
  });
  final Map<String, double> entries;
  final String selected;
  final double basePrice;
  final bool pizzaStyle;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Choose Size'),
        const SizedBox(height: 26),
        Row(
          children: entries.entries.map((entry) {
            final active = entry.key == selected;
            final index = entries.keys.toList().indexOf(entry.key);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: entry.key == entries.keys.last ? 0 : 10,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => onSelected(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 192,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: active
                            ? const Color(0xFFFFA7AE)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x160C3955),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            active
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: active
                                ? _accentRed
                                : const Color(0xFF626873),
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 58,
                          height: 58,
                          child: pizzaStyle
                              ? Image.asset(
                                  switch (index) {
                                    0 =>
                                      'assets/images/pizza_size_4-cutout.png',
                                    1 =>
                                      'assets/images/pizza_size_6-cutout.png',
                                    _ =>
                                      'assets/images/pizza_size_8-cutout.png',
                                  },
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                )
                              : const Icon(
                                  Icons.lunch_dining_outlined,
                                  size: 48,
                                  color: _ink,
                                ),
                        ),
                        const SizedBox(height: 11),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          pizzaStyle
                              ? '(${switch (index) {
                                  0 => 4,
                                  1 => 6,
                                  _ => 8,
                                }} Pieces)'
                              : '(Serves ${index + 1})',
                          style: const TextStyle(
                            color: _accentRed,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatUsd(basePrice + entry.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CrustSection extends StatelessWidget {
  const _CrustSection({
    required this.entries,
    required this.selected,
    required this.onSelected,
  });
  final Map<String, double> entries;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionTitle('Choose Crust'),
      const SizedBox(height: 18),
      ...entries.entries.map(
        (entry) => _OptionRow(
          image: _crustImage(entry.key),
          title: entry.key,
          subtitle: entry.value == 0
              ? 'Included'
              : '+ ${formatUsd(entry.value)}',
          trailing: Icon(
            entry.key == selected
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: entry.key == selected ? _accentRed : _softText,
            size: 30,
          ),
          onTap: () => onSelected(entry.key),
        ),
      ),
    ],
  );

  static String _crustImage(String crust) {
    final value = crust.toLowerCase();
    if (value.contains('thin')) return 'assets/images/crust_thin.jpg';
    if (value.contains('pan')) return 'assets/images/crust_pan.jpg';
    if (value.contains('cheese')) return 'assets/images/crust_cheese.jpg';
    return 'assets/images/cheese_pizza.png';
  }
}

class _ExtrasSection extends StatelessWidget {
  const _ExtrasSection({
    required this.title,
    required this.entries,
    required this.selected,
    required this.removedDefaults,
    required this.onToggle,
    required this.onDefaultToggle,
  });
  final String title;
  final Map<String, double> entries;
  final Set<String> selected;
  final Set<String> removedDefaults;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onDefaultToggle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: _SectionTitle(title)),
          const CircleAvatar(
            radius: 17,
            backgroundColor: Colors.white,
            child: Icon(Icons.keyboard_arrow_up_rounded, color: _ink),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ...entries.entries.map((entry) {
        final included = entry.value == 0;
        final active = included
            ? !removedDefaults.contains(entry.key)
            : selected.contains(entry.key);
        return _OptionRow(
          image: _extraImage(entry.key),
          title: entry.key,
          subtitle: _toppingDescription(entry.key),
          badge: included ? 'DEFAULT' : null,
          trailing: included
              ? active
                    ? IconButton(
                        onPressed: () => onDefaultToggle(entry.key),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: _softText,
                        ),
                      )
                    : _ToppingActionButton(
                        label: 'Add',
                        onPressed: () => onDefaultToggle(entry.key),
                      )
              : _ToppingActionButton(
                  label: active ? 'Remove' : 'Add  +${formatUsd(entry.value)}',
                  onPressed: () => onToggle(entry.key),
                ),
          onTap: included
              ? () => onDefaultToggle(entry.key)
              : () => onToggle(entry.key),
        );
      }),
    ],
  );

  static String _extraImage(String name) {
    final value = name.toLowerCase();
    if (value.contains('mushroom')) {
      return 'assets/images/topping_mushrooms.jpg';
    }
    if (value.contains('mozzarella')) {
      return 'assets/images/topping_mozzarella.jpg';
    }
    if (value.contains('red onion')) {
      return 'assets/images/topping_red_onion.jpg';
    }
    if (value.contains('jalape')) {
      return 'assets/images/topping_jalapeno.jpg';
    }
    if (value.contains('capsicum')) {
      return 'assets/images/topping_green_capsicum.jpg';
    }
    if (value.contains('chicken')) return 'assets/images/chicken_bite.png';
    if (value.contains('cheese') || value.contains('mozzarella')) {
      return 'assets/images/cheese_pizza.png';
    }
    if (value.contains('sauce')) return 'assets/images/loaded_fries.png';
    if (value.contains('jalapeno') || value.contains('pepper')) {
      return 'assets/images/chicked_fajita_pizza.png';
    }
    return 'assets/images/superduper_pizza.png';
  }

  static String _toppingDescription(String name) {
    return switch (name) {
      'Fresh Mushrooms' => 'Earthy sliced mushrooms with a tender bite',
      'Mozzarella' => 'Creamy shredded mozzarella for a rich cheese pull',
      'Red Onion' => 'Crisp red onion rings with a mild, sweet flavour',
      'Sliced Jalapeños' => 'Tangy jalapeño slices with a spicy kick',
      'Green Capsicum' => 'Fresh green capsicum with a light crunch',
      'Cheddar Cheese' => 'A rich layer of melted cheddar cheese',
      'Extra Patty' => 'An extra juicy, flame-grilled patty',
      _ => 'Freshly prepared to customize your meal',
    };
  }
}

class _ToppingActionButton extends StatelessWidget {
  const _ToppingActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 3,
    shadowColor: const Color(0x220C3955),
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _accentRed,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.badge,
    this.onTap,
  });
  final String image;
  final String title;
  final String subtitle;
  final Widget trailing;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 82,
              height: 82,
              color: Colors.white,
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Colors.white,
                  child: Center(
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: _accentGold,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _accentGold,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _softText,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    ),
  );
}

class _ProductBottomBar extends StatelessWidget {
  const _ProductBottomBar({
    required this.item,
    required this.quantity,
    required this.total,
    required this.onAdd,
  });
  final MenuItem item;
  final int quantity;
  final double total;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    color: _pageBlue,
    padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
    child: SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _accentRed,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 46,
                height: 46,
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
                    '$quantity ITEM${quantity == 1 ? '' : 'S'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatUsd(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'inclusive of taxes',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _accentRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined, size: 17),
              label: const Text(
                'ADD TO CART',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
