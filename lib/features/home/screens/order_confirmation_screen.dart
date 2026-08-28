import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/fulfillment_method.dart';
import '../services/order_service.dart';
import 'profile_orders_screen.dart';

const _pageBackground = Colors.white;
const _softBorder = Color(0xFFEBEDF2);
const _secondaryText = Color(0xFF777B88);

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final isPickup = order.fulfillmentMethod.isPickup;

    void openOrder() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileOrdersScreen()),
      );
    }

    void goHome() {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 2),
                    const _ConfirmationArtwork(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Column(
                        children: [
                          Text(
                            isPickup ? 'Pickup confirmed!' : 'Order confirmed!',
                            textAlign: TextAlign.center,
                            style: AppTypography.pageHeader.copyWith(
                              letterSpacing: -.45,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Thanks for your order. We’ve received it.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _secondaryText,
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          _OrderIdPill(orderNumber: order.orderNumber),
                          const SizedBox(height: 8),
                          _OrderStatusCard(isPickup: isPickup),
                          const SizedBox(height: 7),
                          _EstimatedTimeBanner(
                            minimumMinutes: order.etaMinMinutes,
                            maximumMinutes: order.etaMaxMinutes,
                            isPickup: isPickup,
                          ),
                          const SizedBox(height: 7),
                          _OrderLinksCard(
                            isPickup: isPickup,
                            onOpenOrder: openOrder,
                            onOpenSupport: () => _showSupportSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _BottomActions(onHome: goHome, onTrackOrder: openOrder),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showSupportSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Hungry Spot Support',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Our team is ready to help with your order.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'GOT IT',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

class _ConfirmationArtwork extends StatelessWidget {
  const _ConfirmationArtwork();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Hungry Spot chef confirming the order',
      child: SizedBox(
        width: double.infinity,
        height: 125,
        child: Image.asset(
          'assets/images/confirmed_order_chef.webp',
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.high,
          cacheWidth: (390 * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      ),
    );
  }
}

class _OrderIdPill extends StatelessWidget {
  const _OrderIdPill({required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F1F4),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Clipboard.setData(ClipboardData(text: orderNumber)),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Order ID: ',
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Flexible(
                child: Text(
                  orderNumber,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .15,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.copy_rounded, color: _secondaryText, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.isPickup});

  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    final currentTime = TimeOfDay.now().format(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C202B42),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _StatusStep(
              active: true,
              number: 1,
              label: 'Paid',
              helper: currentTime,
              footer: 'Completed',
            ),
          ),
          const _StatusConnector(active: true),
          const Expanded(
            child: _StatusStep(
              number: 2,
              label: 'Preparing',
              helper: 'Estimated',
            ),
          ),
          const _StatusConnector(),
          Expanded(
            child: _StatusStep(
              number: 3,
              label: isPickup ? 'Ready' : 'On the way',
              helper: 'Coming soon',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusConnector extends StatelessWidget {
  const _StatusConnector({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(top: 17),
        decoration: BoxDecoration(
          color: active ? AppColors.red : const Color(0xFFE0E2E6),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.number,
    required this.label,
    required this.helper,
    this.footer,
    this.active = false,
  });

  final int number;
  final String label;
  final String helper;
  final String? footer;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.red : const Color(0xFFE6E7EA),
            shape: BoxShape.circle,
            border: active
                ? Border.all(
                    color: AppColors.red.withValues(alpha: .14),
                    width: 5,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: .24),
                      blurRadius: 11,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: active
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 21)
              : Text(
                  '$number',
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            helper,
            maxLines: 1,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F8E7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              footer!,
              style: const TextStyle(
                color: Color(0xFF2AA440),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EstimatedTimeBanner extends StatelessWidget {
  const _EstimatedTimeBanner({
    required this.minimumMinutes,
    required this.maximumMinutes,
    required this.isPickup,
  });

  final int minimumMinutes;
  final int maximumMinutes;
  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 98,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11192A), Color(0xFF080D18)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2410192A),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -14,
            child: Opacity(
              opacity: .95,
              child: Image.asset(
                'assets/images/beefburger-cutout.webp',
                width: 112,
                height: 92,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned(
            left: 13,
            top: 25,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: .22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
          Positioned.fill(
            left: 72,
            right: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPickup
                      ? 'Estimated pickup time'
                      : 'Estimated delivery time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8BFCC),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$minimumMinutes–$maximumMinutes min',
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPickup
                      ? 'We’ll notify you when your order is ready.'
                      : 'We’ll notify you when your order is on the way.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD7DAE1),
                    fontSize: 9,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
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

class _OrderLinksCard extends StatelessWidget {
  const _OrderLinksCard({
    required this.isPickup,
    required this.onOpenOrder,
    required this.onOpenSupport,
  });

  final bool isPickup;
  final VoidCallback onOpenOrder;
  final VoidCallback onOpenSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B202B42),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _OrderLink(
            icon: Icons.shopping_bag_rounded,
            title: 'Order Details',
            subtitle: isPickup
                ? 'View items, pickup location & payment'
                : 'View items, delivery address & payment',
            onTap: onOpenOrder,
          ),
          const _CardDivider(),
          _OrderLink(
            icon: Icons.notifications_rounded,
            title: 'Order Updates',
            subtitle: 'Get notified on every update',
            onTap: onOpenOrder,
          ),
          const _CardDivider(),
          _OrderLink(
            icon: Icons.support_agent_rounded,
            title: 'Need Help?',
            subtitle: 'Contact our support team',
            onTap: onOpenSupport,
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, thickness: 1, color: _softBorder),
    );
  }
}

class _OrderLink extends StatelessWidget {
  const _OrderLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.red, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _secondaryText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onHome, required this.onTrackOrder});

  final VoidCallback onHome;
  final VoidCallback onTrackOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 7),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18202B42),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dark,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _softBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text(
                  'Home',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 7,
            child: SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: onTrackOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 7,
                  shadowColor: AppColors.red.withValues(alpha: .35),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 17),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Track Order',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
