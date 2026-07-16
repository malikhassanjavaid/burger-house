class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.emoji,
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
  final double price;
  final double? oldPrice;
  final double rating;
  final bool isPopular;
  final bool isRecommended;
  final bool isDeal;
}
