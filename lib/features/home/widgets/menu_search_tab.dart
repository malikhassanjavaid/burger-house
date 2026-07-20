import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../models/menu_item.dart';

const _searchBackground = Color(0xFFF4F8FC);
const _searchFieldBackground = Color(0xFFF0F5FA);
const _searchMuted = Color(0xFF677283);

class MenuSearchTab extends StatelessWidget {
  const MenuSearchTab({
    super.key,
    required this.controller,
    required this.searchText,
    required this.items,
    required this.favourites,
    required this.onChanged,
    required this.onClear,
    required this.onBack,
    required this.onOpenItem,
    required this.onFavourite,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String searchText;
  final List<MenuItem> items;
  final Set<String> favourites;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final ValueChanged<MenuItem> onOpenItem;
  final ValueChanged<MenuItem> onFavourite;
  final ValueChanged<MenuItem> onAdd;

  static const _filters = [
    _SearchFilter(
      label: 'Popular',
      icon: Icons.trending_up_rounded,
      background: Color(0xFFE8FAEF),
      iconColor: Color(0xFF18B45B),
    ),
    _SearchFilter(
      label: 'Spicy',
      icon: Icons.local_fire_department_rounded,
      background: Color(0xFFFFEDF0),
      iconColor: Color(0xFFF42F43),
    ),
    _SearchFilter(
      label: 'Cheesy',
      icon: Icons.breakfast_dining_rounded,
      background: Color(0xFFFFFAE9),
      iconColor: Color(0xFFFFB800),
    ),
    _SearchFilter(
      label: 'Veg',
      icon: Icons.eco_rounded,
      background: Color(0xFFF0FBDD),
      iconColor: Color(0xFF27BF68),
    ),
  ];

  void _selectFilter(String value) {
    if (searchText.toLowerCase() == value.toLowerCase()) {
      controller.clear();
      onClear();
      return;
    }
    controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _searchBackground,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: _SearchHeader(
              controller: controller,
              searchText: searchText,
              filters: _filters,
              onChanged: onChanged,
              onBack: () {
                FocusScope.of(context).unfocus();
                onBack();
              },
              onSubmit: () => FocusScope.of(context).unfocus(),
              onFilter: _selectFilter,
            ),
          ),
          if (searchText.isEmpty)
            const SliverToBoxAdapter(child: _SearchPrompt())
          else if (items.isEmpty)
            SliverToBoxAdapter(
              child: _NoSearchResults(
                searchText: searchText,
                onClear: () {
                  controller.clear();
                  onClear();
                },
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 19, 20, 13),
                child: Row(
                  children: [
                    const Text(
                      'Your picks',
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        color: _searchMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 112),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((_, index) {
                  if (index.isOdd) return const SizedBox(height: 12);
                  final item = items[index ~/ 2];
                  return _SearchResultCard(
                    item: item,
                    favourite: favourites.contains(item.id),
                    onTap: () => onOpenItem(item),
                    onFavourite: () => onFavourite(item),
                    onAdd: () => onAdd(item),
                  );
                }, childCount: items.length * 2 - 1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.searchText,
    required this.filters,
    required this.onChanged,
    required this.onBack,
    required this.onSubmit,
    required this.onFilter,
  });

  final TextEditingController controller;
  final String searchText;
  final List<_SearchFilter> filters;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Container(
            height: 62,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: _searchFieldBackground,
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: false,
                    onChanged: onChanged,
                    onSubmitted: (_) => onSubmit(),
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      filled: false,
                      hintText: 'Ex. Chicken Fajita, Wingstreet',
                      hintStyle: TextStyle(
                        color: Color(0xFF7398A4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSubmit,
                  padding: const EdgeInsets.only(left: 8, right: 16),
                  icon: const Icon(
                    Icons.search_rounded,
                    color: Colors.black,
                    size: 29,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (_, index) {
                final filter = filters[index];
                final selected =
                    searchText.toLowerCase() == filter.label.toLowerCase();
                return _FilterPill(
                  filter: filter,
                  selected: selected,
                  onTap: () => onFilter(filter.label),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _SearchFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filter.background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? filter.iconColor.withValues(alpha: .65)
                  : const Color(0xFFDCE4E9),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(filter.icon, color: filter.iconColor, size: 19),
              const SizedBox(width: 8),
              Text(
                filter.label,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 57, 22, 118),
      child: Column(
        children: [
          _SearchCardsIllustration(),
          SizedBox(height: 35),
          Text(
            "What's your pick?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.45,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Now discover our menu based on your search\npreferences!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _searchMuted,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchCardsIllustration extends StatelessWidget {
  const _SearchCardsIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 255,
      height: 205,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 15,
            top: 12,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                color: Color(0xFFECF2FB),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 29,
            top: 18,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFFAB22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: 61,
            top: 89,
            child: _MiniResultCard(front: false),
          ),
          const Positioned(
            left: 39,
            top: 61,
            child: _MiniResultCard(front: true),
          ),
        ],
      ),
    );
  }
}

class _MiniResultCard extends StatelessWidget {
  const _MiniResultCard({required this.front});

  final bool front;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 184,
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: front ? .92 : .78),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9D4E4).withValues(alpha: .26),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 51,
            height: 51,
            decoration: BoxDecoration(
              color: front ? const Color(0xFFDCE7F5) : const Color(0xFFD2DEEE),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 88, height: 8, color: const Color(0xFFF0F4F9)),
                const SizedBox(height: 8),
                Container(width: 58, height: 6, color: const Color(0xFFF3F6FA)),
              ],
            ),
          ),
          const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFF03D52),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.searchText, required this.onClear});

  final String searchText;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 54, 22, 118),
      child: Column(
        children: [
          const _SearchCardsIllustration(),
          const SizedBox(height: 30),
          const Text(
            'Nothing matched your pick',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We could not find "$searchText". Try a different meal or filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _searchMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text(
              'Clear search',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.item,
    required this.favourite,
    required this.onTap,
    required this.onFavourite,
    required this.onAdd,
  });

  final MenuItem item;
  final bool favourite;
  final VoidCallback onTap;
  final VoidCallback onFavourite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 146,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E8EF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCAD5E2).withValues(alpha: .2),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 105,
                height: 124,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  item.displayAssetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 46),
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
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.dark,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onFavourite,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: Icon(
                            favourite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: const Color(0xFFF03D52),
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          item.category,
                          style: const TextStyle(
                            color: _searchMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAC22),
                          size: 14,
                        ),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                            color: _searchMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _searchMuted,
                        fontSize: 10.5,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          formatUsd(item.price),
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 34,
                          child: FilledButton(
                            onPressed: onAdd,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: const Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchFilter {
  const _SearchFilter({
    required this.label,
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color iconColor;
}
