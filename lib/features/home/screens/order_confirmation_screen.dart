import 'package:flutter/material.dart';

import '../models/fulfillment_method.dart';
import '../services/order_service.dart';
import 'profile_orders_screen.dart';

const _confirmationBg = Color(0xFFF4FAFE);
const _confirmationRed = Color(0xFFF23845);
const _confirmationInk = Color(0xFF15161C);
const _confirmationMuted = Color(0xFF858C98);
const _confirmationLine = Color(0xFFDDE7ED);

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final isPickup = order.fulfillmentMethod.isPickup;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: _confirmationBg,
        body: Column(
          children: [
            _OrderNumberHeader(
              orderNumber: order.orderNumber,
              isPickup: isPickup,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  children: [
                    _OrderPlacedCard(isPickup: isPickup),
                    const SizedBox(height: 14),
                    _OrderStatusCard(order: order),
                  ],
                ),
              ),
            ),
            _ConfirmationActions(
              onViewOrder: () {
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
    );
  }
}

class _OrderNumberHeader extends StatelessWidget {
  const _OrderNumberHeader({required this.orderNumber, required this.isPickup});

  final String orderNumber;
  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 88,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORDER NUMBER',
                      style: TextStyle(
                        color: _confirmationMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _confirmationInk,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.35,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9EB),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _confirmationRed,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPickup ? 'PICKUP PLACED' : 'ORDER PLACED',
                      style: const TextStyle(
                        color: _confirmationRed,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .35,
                      ),
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

class _OrderPlacedCard extends StatelessWidget {
  const _OrderPlacedCard({required this.isPickup});

  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('confirmation-success-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160C3955),
            blurRadius: 17,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const _StatusArtwork(
            assetPath: 'assets/images/order_status_receipt.png',
            size: 70,
            zoom: 1.65,
            active: true,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPickup ? 'Pickup confirmed!' : 'Order confirmed!',
                  style: const TextStyle(
                    color: _confirmationInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isPickup
                      ? 'Your order is with our kitchen. We will notify you when it is ready.'
                      : 'Your order is with our kitchen. We will keep every stage updated.',
                  style: const TextStyle(
                    color: _confirmationMuted,
                    fontSize: 11,
                    height: 1.4,
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

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final isPickup = order.fulfillmentMethod.isPickup;
    final steps = <_StatusData>[
      const _StatusData(
        title: 'Placed',
        subtitle: 'We received your order',
        assetPath: 'assets/images/order_status_receipt.png',
        zoom: 1.7,
        active: true,
      ),
      const _StatusData(
        title: 'Preparing',
        subtitle: 'The kitchen will prepare your meal',
        assetPath: 'assets/images/order_status_preparing.png',
        zoom: 1.7,
      ),
      _StatusData(
        title: 'Estimated time',
        subtitle: '${order.etaMinMinutes}-${order.etaMaxMinutes} min',
        assetPath: 'assets/images/order_status_clock.png',
        zoom: 1.65,
      ),
      _StatusData(
        title: isPickup ? 'Ready for pickup' : 'On the way',
        subtitle: isPickup
            ? 'Collect your meal from Hungry Spot'
            : 'Your rider will head to your location',
        assetPath: isPickup
            ? 'assets/images/order_status_receipt.png'
            : 'assets/images/order_status_rider.png',
        zoom: isPickup ? 1.7 : 1.75,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160C3955),
            blurRadius: 17,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order status',
            style: TextStyle(
              color: _confirmationInk,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track the progress of your meal',
            style: TextStyle(
              color: _confirmationMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(
            steps.length,
            (index) => _StatusStep(
              data: steps[index],
              isLast: index == steps.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusData {
  const _StatusData({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.zoom,
    this.active = false,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final double zoom;
  final bool active;
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({required this.data, required this.isLast});

  final _StatusData data;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                _StatusArtwork(
                  assetPath: data.assetPath,
                  size: 52,
                  zoom: data.zoom,
                  active: data.active,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: data.active ? _confirmationRed : _confirmationLine,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 7, bottom: isLast ? 9 : 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: TextStyle(
                            color: data.active
                                ? _confirmationInk
                                : const Color(0xFF6E7680),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          data.subtitle,
                          style: const TextStyle(
                            color: _confirmationMuted,
                            fontSize: 10.5,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (data.active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          color: _confirmationRed,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusArtwork extends StatelessWidget {
  const _StatusArtwork({
    required this.assetPath,
    required this.size,
    required this.zoom,
    required this.active,
  });

  final String assetPath;
  final double size;
  final double zoom;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .27),
        border: Border.all(
          color: active ? _confirmationRed : const Color(0xFFE0E7EC),
          width: active ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120C3955),
            blurRadius: 9,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .22),
        child: Transform.scale(
          scale: zoom,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            cacheWidth: 180,
          ),
        ),
      ),
    );
  }
}

class _ConfirmationActions extends StatelessWidget {
  const _ConfirmationActions({
    required this.onViewOrder,
    required this.onBackHome,
  });

  final VoidCallback onViewOrder;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _confirmationBg,
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: onBackHome,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _confirmationInk,
                    side: const BorderSide(color: Color(0xFFDCE5EA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'BACK HOME',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: onViewOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: _confirmationRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'VIEW MY ORDER',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
