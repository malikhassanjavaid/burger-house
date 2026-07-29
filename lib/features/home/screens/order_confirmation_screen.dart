import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/fulfillment_method.dart';
import '../services/order_service.dart';
import 'profile_orders_screen.dart';

const _pageBackground = Color(0xFFF8F9FC);
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
                    const SizedBox(height: 6),
                    const _ConfirmationArtwork(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
                      child: Column(
                        children: [
                          Text(
                            isPickup ? 'Pickup confirmed!' : 'Order confirmed!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.dark,
                              fontSize: 28,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.7,
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'Thanks for your order. We’ve received it.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _secondaryText,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _OrderIdPill(orderNumber: order.orderNumber),
                          const SizedBox(height: 18),
                          _OrderStatusCard(isPickup: isPickup),
                          const SizedBox(height: 14),
                          _EstimatedTimeBanner(
                            minimumMinutes: order.etaMinMinutes,
                            maximumMinutes: order.etaMaxMinutes,
                            isPickup: isPickup,
                          ),
                          const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              const Text(
                'Hungry Spot Support',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Our team is ready to help with your order.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
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
                    style: TextStyle(fontWeight: FontWeight.w900),
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

  static const double _sourceWidth = 862;
  static const double _sourceHeight = 1825;
  static const double _cropTop = 74;
  static const double _cropBottom = 482;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Hungry Spot chef confirming the order',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final scale = width / _sourceWidth;
          final cropHeight = (_cropBottom - _cropTop) * scale;

          return SizedBox(
            width: width,
            height: cropHeight,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: 0,
                    top: -_cropTop * scale,
                    width: width,
                    height: _sourceHeight * scale,
                    child: Image.asset(
                      'assets/images/order_confirmed_reference.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => Clipboard.setData(ClipboardData(text: orderNumber)),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 9, 12, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Order ID: ',
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Flexible(
                child: Text(
                  orderNumber,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .15,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Icon(Icons.copy_rounded, color: _secondaryText, size: 16),
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
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C202B42),
            blurRadius: 24,
            offset: Offset(0, 9),
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
        height: 3,
        margin: const EdgeInsets.only(top: 21),
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
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.red : const Color(0xFFE6E7EA),
            shape: BoxShape.circle,
            border: active
                ? Border.all(
                    color: AppColors.red.withValues(alpha: .14),
                    width: 7,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: .24),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: active
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
              : Text(
                  '$number',
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(height: 13),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            helper,
            maxLines: 1,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F8E7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              footer!,
              style: const TextStyle(
                color: Color(0xFF2AA440),
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
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
      height: 132,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11192A), Color(0xFF080D18)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2410192A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -18,
            child: Opacity(
              opacity: .95,
              child: Image.asset(
                'assets/images/beefburger-cutout.png',
                width: 150,
                height: 125,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 28,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: .22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: Colors.white,
                size: 37,
              ),
            ),
          ),
          Positioned.fill(
            left: 98,
            right: 95,
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$minimumMinutes–$maximumMinutes min',
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPickup
                      ? 'We’ll notify you when your order is ready.'
                      : 'We’ll notify you when your order is on the way.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD7DAE1),
                    fontSize: 9.5,
                    height: 1.25,
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B202B42),
            blurRadius: 24,
            offset: Offset(0, 9),
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
      padding: EdgeInsets.symmetric(horizontal: 18),
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
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.red, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _secondaryText,
                size: 24,
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18202B42),
            blurRadius: 26,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 51,
              child: OutlinedButton.icon(
                onPressed: onHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dark,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _softBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                icon: const Icon(Icons.home_outlined, size: 22),
                label: const Text(
                  'Home',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 7,
            child: SizedBox(
              height: 51,
              child: FilledButton(
                onPressed: onTrackOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  elevation: 7,
                  shadowColor: AppColors.red.withValues(alpha: .35),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Track Order',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: 7),
                    Icon(Icons.arrow_forward_rounded, size: 21),
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
