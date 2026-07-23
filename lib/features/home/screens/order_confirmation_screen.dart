import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../services/order_service.dart';
import 'profile_orders_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FC),
        body: SafeArea(
          child: Column(
            children: [
              _ConfirmationHeader(onClose: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    children: [
                      _SuccessPanel(orderNumber: order.orderNumber),
                      const SizedBox(height: 14),
                      _EtaCard(
                        minimumMinutes: order.etaMinMinutes,
                        maximumMinutes: order.etaMaxMinutes,
                      ),
                      const SizedBox(height: 14),
                      const _OrderJourneyCard(),
                      const SizedBox(height: 14),
                      _OrderSummaryCard(order: order),
                    ],
                  ),
                ),
              ),
              _ConfirmationActions(
                onViewOrders: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileOrdersScreen(),
                    ),
                  );
                },
                onBackHome: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationHeader extends StatelessWidget {
  const _ConfirmationHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 14, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'ORDER CONFIRMATION',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Back to home',
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.dark,
              fixedSize: const Size(42, 42),
              side: const BorderSide(color: Color(0xFFE2E9EE)),
              shadowColor: const Color(0x18304A5C),
              elevation: 2,
            ),
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('confirmation-success-panel'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF4A55), AppColors.redDark],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -32,
            top: -40,
            child: _DecorativeCircle(size: 132, opacity: .08),
          ),
          const Positioned(
            left: -52,
            bottom: -72,
            child: _DecorativeCircle(size: 150, opacity: .06),
          ),
          Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.redDark.withValues(alpha: .22),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your meal is now with the Hungry Spot kitchen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFE9EC),
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .25),
                  ),
                ),
                child: Text(
                  'ORDER  $orderNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .65,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EtaCard extends StatelessWidget {
  const _EtaCard({required this.minimumMinutes, required this.maximumMinutes});

  final int minimumMinutes;
  final int maximumMinutes;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.red,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTIMATED DELIVERY',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .65,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$minimumMinutes-$maximumMinutes min',
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF27A85C), size: 7),
                SizedBox(width: 5),
                Text(
                  'ON TIME',
                  style: TextStyle(
                    color: Color(0xFF20884B),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderJourneyCard extends StatelessWidget {
  const _OrderJourneyCard();

  @override
  Widget build(BuildContext context) {
    return const _ConfirmationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your order journey',
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'We will keep each stage updated for you.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
          SizedBox(height: 19),
          _OrderProgress(),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery details',
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _ConfirmationDetail(
            icon: Icons.location_on_outlined,
            label: 'DELIVERING TO',
            value: order.deliveryAddress,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, color: Color(0xFFE8EDF1)),
          ),
          _ConfirmationDetail(
            icon: Icons.payments_outlined,
            label: 'PAYMENT ON DELIVERY',
            value: formatUsd(order.total),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE2E9EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D304A5C),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ConfirmationDetail extends StatelessWidget {
  const _ConfirmationDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.blush,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.red, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 42,
          right: 42,
          top: 20,
          child: Row(
            children: [
              Expanded(child: Container(height: 2, color: AppColors.red)),
              Expanded(
                child: Container(height: 2, color: const Color(0xFFE0E6EA)),
              ),
            ],
          ),
        ),
        const Row(
          children: [
            Expanded(
              child: _ProgressStep(
                icon: Icons.receipt_long_rounded,
                label: 'Placed',
                active: true,
              ),
            ),
            Expanded(
              child: _ProgressStep(
                icon: Icons.restaurant_rounded,
                label: 'Preparing',
              ),
            ),
            Expanded(
              child: _ProgressStep(
                icon: Icons.delivery_dining_rounded,
                label: 'On the way',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.red : const Color(0xFFABB6BE);
    return Column(
      children: [
        Container(
          width: 41,
          height: 41,
          decoration: BoxDecoration(
            color: active ? AppColors.red : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppColors.red : const Color(0xFFD9E0E5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12304A5C),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: active ? Colors.white : color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.dark : AppColors.muted,
            fontSize: 9.5,
            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ConfirmationActions extends StatelessWidget {
  const _ConfirmationActions({
    required this.onViewOrders,
    required this.onBackHome,
  });

  final VoidCallback onViewOrders;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E9ED))),
        boxShadow: [
          BoxShadow(
            color: Color(0x12304A5C),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPrimaryButton(
            label: 'VIEW MY ORDERS',
            icon: Icons.receipt_long_outlined,
            height: 50,
            onPressed: onViewOrders,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onBackHome,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.dark,
              minimumSize: const Size.fromHeight(38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'BACK TO HOME',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
