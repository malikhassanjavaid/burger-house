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
    'assets/images/beefburger.webp' => 'assets/images/beefburger-cutout.webp',
    'assets/images/firehouse_burger.webp' =>
      'assets/images/firehouse_burger-cutout.webp',
    'assets/images/grilled_burger.webp' =>
      'assets/images/grilled_burger-cutout.webp',
    'assets/images/krunch_burger.webp' =>
      'assets/images/krunch_burger-cutout.webp',
    'assets/images/Spicy_glazed_wings.webp' =>
      'assets/images/Spicy_glazed_wings-cutout.webp',
    'assets/images/loaded_fries.webp' =>
      'assets/images/loaded_fries-cutout.webp',
    'assets/images/sprite.webp' => 'assets/images/sprite-cutout.webp',
    'assets/images/vanilla_frappe.webp' =>
      'assets/images/vanilla_frappe-cutout.webp',
    'assets/images/strawberry_frappe.webp' =>
      'assets/images/strawberry_frappe-cutout.webp',
    'assets/images/brownie.webp' => 'assets/images/brownie-cutout.webp',
    'assets/images/beef_wrap.webp' => 'assets/images/beef_wrap-cutout.webp',
    'assets/images/cheese_burger.webp' =>
      'assets/images/cheese_burger-cutout.webp',
    'assets/images/cheese_pizza.webp' =>
      'assets/images/cheese_pizza-cutout.webp',
    'assets/images/cheesecake_slice.webp' =>
      'assets/images/cheesecake_slice-cutout.webp',
    'assets/images/chefspecial_pizza.webp' =>
      'assets/images/chefspecial_pizza-cutout.webp',
    'assets/images/chicked_fajita_pizza.webp' =>
      'assets/images/chicked_fajita_pizza-cutout.webp',
    'assets/images/chicken_bite.webp' =>
      'assets/images/chicken_bite-cutout.webp',
    'assets/images/chicken_wrap.webp' =>
      'assets/images/chicken_wrap-cutout.webp',
    'assets/images/chocolate_frappe.webp' =>
      'assets/images/chocolate_frappe-cutout.webp',
    'assets/images/coke.webp' => 'assets/images/coke-cutout.webp',
    'assets/images/crispy_wings.webp' =>
      'assets/images/crispy_wings-cutout.webp',
    'assets/images/duo_deal.webp' => 'assets/images/duo_deal-cutout.webp',
    'assets/images/family_feast.webp' =>
      'assets/images/family_feast-cutout.webp',
    'assets/images/fries.webp' => 'assets/images/fries-cutout.webp',
    'assets/images/kabab_pizza.webp' => 'assets/images/kabab_pizza-cutout.webp',
    'assets/images/loadedcake_slice.webp' =>
      'assets/images/loadedcake_slice-cutout.webp',
    'assets/images/nuggets.webp' => 'assets/images/nuggets-cutout.webp',
    'assets/images/oreo_shake.webp' => 'assets/images/oreo_shake-cutout.webp',
    'assets/images/pepperoni_pizza.webp' =>
      'assets/images/pepperoni_pizza-cutout.webp',
    'assets/images/superduper_pizza.webp' =>
      'assets/images/superduper_pizza-cutout.webp',
    'assets/images/tiramisucake_slice.webp' =>
      'assets/images/tiramisucake_slice-cutout.webp',
    _ => assetPath,
  };
}
