class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.emoji,
    required this.assetPath,
    required this.price,
    this.oldPrice,
    this.rating = 4.5,
    this.isPopular = false,
    this.isRecommended = false,
    this.isDeal = false,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String emoji;
  final String assetPath;
  final double price;
  final double? oldPrice;
  final double rating;
  final bool isPopular;
  final bool isRecommended;
  final bool isDeal;

  String get displayAssetPath => switch (assetPath) {
    'assets/images/beefburger.png' =>
      'assets/images/beefburger-cutout.png',
    'assets/images/firehouse_burger.png' =>
      'assets/images/firehouse_burger-cutout.png',
    'assets/images/grilled_burger.png' =>
      'assets/images/grilled_burger-cutout.png',
    'assets/images/krunch_burger.png' =>
      'assets/images/krunch_burger-cutout.png',
    'assets/images/Spicy_glazed_wings.png' =>
      'assets/images/Spicy_glazed_wings-cutout.png',
    'assets/images/loaded_fries.png' =>
      'assets/images/loaded_fries-cutout.png',
    'assets/images/sprite.png' => 'assets/images/sprite-cutout.png',
    'assets/images/vanilla_frappe.png' =>
      'assets/images/vanilla_frappe-cutout.png',
    'assets/images/strawberry_frappe.png' =>
      'assets/images/strawberry_frappe-cutout.png',
    'assets/images/brownie.png' => 'assets/images/brownie-cutout.png',
    'assets/images/beef_wrap.png' => 'assets/images/beef_wrap-cutout.png',
    'assets/images/cheese_burger.png' =>
      'assets/images/cheese_burger-cutout.png',
    'assets/images/cheese_pizza.png' =>
      'assets/images/cheese_pizza-cutout.png',
    'assets/images/cheesecake_slice.png' =>
      'assets/images/cheesecake_slice-cutout.png',
    'assets/images/chefspecial_pizza.png' =>
      'assets/images/chefspecial_pizza-cutout.png',
    'assets/images/chicked_fajita_pizza.png' =>
      'assets/images/chicked_fajita_pizza-cutout.png',
    'assets/images/chicken_bite.png' =>
      'assets/images/chicken_bite-cutout.png',
    'assets/images/chicken_wrap.png' =>
      'assets/images/chicken_wrap-cutout.png',
    'assets/images/chocolate_frappe.png' =>
      'assets/images/chocolate_frappe-cutout.png',
    'assets/images/coke.png' => 'assets/images/coke-cutout.png',
    'assets/images/crispy_wings.png' =>
      'assets/images/crispy_wings-cutout.png',
    'assets/images/duo_deal.png' => 'assets/images/duo_deal-cutout.png',
    'assets/images/family_feast.png' =>
      'assets/images/family_feast-cutout.png',
    'assets/images/fries.png' => 'assets/images/fries-cutout.png',
    'assets/images/kabab_pizza.png' =>
      'assets/images/kabab_pizza-cutout.png',
    'assets/images/loadedcake_slice.png' =>
      'assets/images/loadedcake_slice-cutout.png',
    'assets/images/nuggets.png' => 'assets/images/nuggets-cutout.png',
    'assets/images/oreo_shake.png' => 'assets/images/oreo_shake-cutout.png',
    'assets/images/pepperoni_pizza.png' =>
      'assets/images/pepperoni_pizza-cutout.png',
    'assets/images/superduper_pizza.png' =>
      'assets/images/superduper_pizza-cutout.png',
    'assets/images/tiramisucake_slice.png' =>
      'assets/images/tiramisucake_slice-cutout.png',
    _ => assetPath,
  };
}
