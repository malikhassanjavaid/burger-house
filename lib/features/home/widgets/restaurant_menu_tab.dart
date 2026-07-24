import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../models/menu_item.dart';

const _menuBackground = Color(0xFFF4F8FC);
const _menuBorder = Color(0xFFE4EAF0);
const _menuMuted = Color(0xFF737D8B);

class RestaurantMenuTab extends StatelessWidget {
  const RestaurantMenuTab({
    super.key,
    required this.controller,
    required this.searchText,
    required this.selectedCategory,
    required this.items,
    required this.favourites,
    required this.onChanged,
    required this.onClear,
    required this.onCategorySelected,
    required this.onOpenItem,
    required this.onFavourite,
  });

  final TextEditingController controller;
  final String searchText;
  final String selectedCategory;
  final List<MenuItem> items;
  final Set<String> favourites;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<MenuItem> onOpenItem;
  final ValueChanged<MenuItem> onFavourite;

  static const categories = [
    'Burgers',
    'Pizzas',
    'Chicken',
    'Sides',
    'Wraps',
    'Drinks',
    'Desserts',
    'Deals',
  ];

  @override
  Widget build(BuildContext context) {
    final searching = searchText.trim().isNotEmpty;
    final visibleItems = searching
        ? items
        : items.where((item) => item.category == selectedCategory).toList();

    return ColoredBox(
      color: _menuBackground,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: _MenuSearchField(
                controller: controller,
                searchText: searchText,
                onChanged: onChanged,
                onClear: onClear,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                      ),
                    ),
                  ),
                  if (searching)
                    TextButton(
                      onPressed: () {
                        controller.clear();
                        onClear();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.red,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Clear search',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 96,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 13),
                itemBuilder: (_, index) {
                  final category = categories[index];
                  return _MenuCategory(
                    label: category,
                    selected: !searching && category == selectedCategory,
                    assetPath: _categoryAsset(category),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (searching) {
                        controller.clear();
                        onClear();
                      }
                      onCategorySelected(category);
                    },
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          searching ? 'Search results' : selectedCategory,
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          searching
                              ? 'Matches for "${searchText.trim()}"'
                              : _categoryDescription(selectedCategory),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _menuMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _menuBorder),
                    ),
                    child: Text(
                      '${visibleItems.length} '
                      '${visibleItems.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        color: _menuMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (visibleItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _NoMenuMatches(
                searchText: searchText,
                onClear: () {
                  controller.clear();
                  onClear();
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 112),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 15,
                  childAspectRatio: .57,
                ),
                delegate: SliverChildBuilderDelegate((_, index) {
                  final item = visibleItems[index];
                  return RestaurantMenuCard(
                    item: item,
                    favourite: favourites.contains(item.id),
                    onTap: () => onOpenItem(item),
                    onFavourite: () => onFavourite(item),
                  );
                }, childCount: visibleItems.length),
              ),
            ),
        ],
      ),
    );
  }

  static String _categoryAsset(String category) {
    return switch (category) {
      'Burgers' => 'assets/images/beefburger-cutout.png',
      'Pizzas' => 'assets/images/cheese_pizza-cutout.png',
      'Chicken' => 'assets/images/Spicy_glazed_wings-cutout.png',
      'Sides' => 'assets/images/fries-cutout.png',
      'Wraps' => 'assets/images/chicken_wrap-cutout.png',
      'Drinks' => 'assets/images/strawberry_frappe-cutout.png',
      'Desserts' => 'assets/images/cheesecake_slice-cutout.png',
      _ => 'assets/images/duo_deal-cutout.png',
    };
  }

  static String _categoryDescription(String category) {
    return switch (category) {
      'Burgers' => 'Juicy signatures stacked fresh for you',
      'Pizzas' => 'Oven-hot favourites with generous toppings',
      'Chicken' => 'Crispy, glazed and made to share',
      'Sides' => 'The perfect extras for every meal',
      'Wraps' => 'Freshly wrapped, filling and full of flavour',
      'Drinks' => 'Cold classics, shakes and frappes',
      'Desserts' => 'A sweet finish to your Hungry Spot order',
      _ => 'More food, more value, one easy order',
    };
  }
}

class _MenuSearchField extends StatelessWidget {
  const _MenuSearchField({
    required this.controller,
    required this.searchText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String searchText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _menuBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25344A).withValues(alpha: .07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: AppColors.dark,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Search burgers, pizza, drinks...',
          hintStyle: const TextStyle(
            color: Color(0xFF929BA7),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.dark,
            size: 23,
          ),
          suffixIcon: searchText.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

class _MenuCategory extends StatelessWidget {
  const _MenuCategory({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayLabel = switch (label) {
      'Burgers' => 'Burger',
      'Pizzas' => 'Pizza',
      'Desserts' => 'Dessert',
      _ => label,
    };

    return SizedBox(
      width: 66,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(34),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.red : const Color(0xFFE9E9E9),
                  width: selected ? 1.7 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? AppColors.red.withValues(alpha: .15)
                        : const Color(0x0F000000),
                    blurRadius: selected ? 12 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppColors.red : AppColors.dark,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantMenuCard extends StatelessWidget {
  const RestaurantMenuCard({
    required this.item,
    required this.favourite,
    required this.onTap,
    required this.onFavourite,
    super.key,
  });

  final MenuItem item;
  final bool favourite;
  final VoidCallback onTap;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: _menuBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25344A).withValues(alpha: .07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 12,
                child: Container(
                  margin: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(9),
                        child: Hero(
                          tag: 'menu-art-${item.id}',
                          child: Image.asset(
                            item.displayAssetPath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 66),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            onTap: onFavourite,
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                favourite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: favourite
                                    ? AppColors.red
                                    : AppColors.dark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 7, 13, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 15.5,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB313),
                            size: 15,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item.rating}',
                            style: const TextStyle(
                              color: _menuMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatUsd(item.price),
                              maxLines: 1,
                              style: const TextStyle(
                                color: AppColors.dark,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          OutlinedButton(
                            onPressed: onTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dark,
                              side: const BorderSide(
                                color: AppColors.red,
                                width: 1.5,
                              ),
                              minimumSize: const Size(64, 34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VIEW',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .25,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.arrow_forward_rounded, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMenuMatches extends StatelessWidget {
  const _NoMenuMatches({required this.searchText, required this.onClear});

  final String searchText;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 14, 30, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.red,
                size: 35,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'No menu items found',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'We could not find anything matching "${searchText.trim()}".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _menuMuted,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              child: const Text(
                'Browse burgers',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
