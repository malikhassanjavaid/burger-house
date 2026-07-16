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

  String get configurationKey => [
    menuItem.id,
    size,
    ...addOns.toList()..sort(),
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
