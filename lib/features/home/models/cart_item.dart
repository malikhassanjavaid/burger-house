import 'menu_item.dart';

class CartItem {
  const CartItem({
    required this.menuItem,
    required this.quantity,
    required this.unitPrice,
    this.size = 'Regular',
    this.addOns = const [],
    this.instructions = '',
  });

  final MenuItem menuItem;
  final int quantity;
  final double unitPrice;
  final String size;
  final List<String> addOns;
  final String instructions;

  double get totalPrice => unitPrice * quantity;

  bool get _isFeaturedDeal =>
      menuItem.id == 'wow-pizza-deal' || menuItem.id == 'wow-burger-deal';

  String get _configurationSize =>
      _isFeaturedDeal && (size == 'Bundle' || size == 'Meal Deal')
      ? 'Meal Deal'
      : size;

  Iterable<String> get _configurationAddOns {
    if (addOns.isNotEmpty || !_isFeaturedDeal) return addOns;

    return switch (menuItem.id) {
      'wow-pizza-deal' => const [
        '2 Medium Pizzas',
        '3 Chilled Drinks',
        'Pizza: Classic Cheese Pizza',
        'Drink: Coke',
      ],
      'wow-burger-deal' => const [
        '4 Crispy Chicken Burgers',
        '4 Chilled Drinks',
        'Burger: Crispy Chicken Burger',
        'Drink: Coke',
      ],
      _ => addOns,
    };
  }

  String get configurationKey => [
    menuItem.id,
    _configurationSize,
    ..._configurationAddOns.toList()..sort(),
    instructions.trim(),
  ].join('|');

  CartItem copyWith({int? quantity}) {
    return CartItem(
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      size: size,
      addOns: addOns,
      instructions: instructions,
    );
  }
}
