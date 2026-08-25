import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../models/cart_item.dart';

class MenuCartSummaryBar extends StatelessWidget {
  const MenuCartSummaryBar({
    required this.previewItem,
    required this.itemCount,
    required this.total,
    required this.onViewCart,
    super.key,
  });

  final CartItem previewItem;
  final int itemCount;
  final double total;
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('menu-cart-summary'),
      color: Colors.white,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Container(
          height: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withValues(alpha: .24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  previewItem.menuItem.displayAssetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.fastfood_rounded, color: AppColors.red),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$itemCount ${itemCount == 1 ? 'ITEM' : 'ITEMS'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatUsd(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Includes taxes',
                      style: TextStyle(
                        color: Color(0xFFFFD9DD),
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onViewCart,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                label: const Text(
                  'View Cart',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
