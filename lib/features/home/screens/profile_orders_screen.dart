import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_loader.dart';
import '../widgets/profile_page_header.dart';

class ProfileOrdersScreen extends StatelessWidget {
  const ProfileOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: profilePageBackground,
      body: Column(
        children: [
          ProfilePageHeader(
            title: 'MY ORDERS',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: user == null
                ? const _OrdersMessage(
                    icon: Icons.lock_outline_rounded,
                    title: 'Please sign in again',
                    message: 'Your session ended before orders could load.',
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('customerId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const _OrdersMessage(
                          icon: Icons.cloud_off_outlined,
                          title: 'Orders could not load',
                          message:
                              'Check your connection and Firestore rules, then try again.',
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: AppLoader());
                      }

                      final documents = [...?snapshot.data?.docs]
                        ..sort((a, b) {
                          final aTime =
                              ((a.data()['createdAt'] ??
                                          a.data()['createdAtClient'])
                                      as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0;
                          final bTime =
                              ((b.data()['createdAt'] ??
                                          b.data()['createdAtClient'])
                                      as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0;
                          return bTime.compareTo(aTime);
                        });
                      if (documents.isEmpty) {
                        return const _OrdersMessage(
                          icon: Icons.receipt_long_outlined,
                          title: 'No orders yet',
                          message:
                              'Your Hungry Spot orders will appear here after checkout.',
                        );
                      }

                      final activeCount = documents.where((document) {
                        final status =
                            (document.data()['status'] as String?) ?? 'placed';
                        return !_isFinishedStatus(status);
                      }).length;

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
                        itemCount: documents.length + 2,
                        separatorBuilder: (_, _) => const SizedBox(height: 13),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _OrdersOverview(
                              totalCount: documents.length,
                              activeCount: activeCount,
                            );
                          }
                          if (index == 1) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 6, bottom: 1),
                              child: Text(
                                'RECENT ORDERS',
                                style: TextStyle(
                                  color: profilePageInk,
                                  fontSize: 13,
                                  letterSpacing: .3,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }
                          final document = documents[index - 2];
                          return _OrderCard(
                            id: document.id,
                            data: document.data(),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrdersOverview extends StatelessWidget {
  const _OrdersOverview({required this.totalCount, required this.activeCount});

  final int totalCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF191B24), Color(0xFF2D303D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28151925),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.local_mall_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your order history',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Track active meals and revisit past orders.',
                  style: TextStyle(
                    color: Color(0xFFBFC3CE),
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                activeCount == 1 ? '1 active' : '$activeCount active',
                style: const TextStyle(
                  color: Color(0xFFFF8A93),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String get _orderNumber {
    final savedNumber = (data['orderNumber'] as String?)?.trim();
    if (savedNumber?.isNotEmpty == true) return savedNumber!;
    final short = id.length > 7 ? id.substring(id.length - 7) : id;
    return 'HS-${short.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List?) ?? const [];
    final total = (data['total'] as num?) ?? 0;
    final statusValue = (data['status'] as String?) ?? 'placed';
    final isPickup = data['fulfillmentMethod'] == 'pickup';
    final createdAt = _timestampFrom(
      data['createdAt'] ?? data['createdAtClient'],
    );
    final etaMin = (data['etaMinMinutes'] as num?)?.toInt() ?? 30;
    final etaMax = (data['etaMaxMinutes'] as num?)?.toInt() ?? 40;
    final itemCount = _itemCount(items);
    final status = _OrderStatus.fromValue(statusValue);
    final finished = _isFinishedStatus(statusValue);
    final cancelled = statusValue.toLowerCase() == 'cancelled';
    final stage = _statusStage(statusValue, isPickup: isPickup);
    final progress = cancelled ? 1.0 : ((stage + 1) / 4).clamp(.25, 1.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showOrderDetails(context, id: _orderNumber, data: data),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDE6EC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1047657A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(status.icon, color: status.color, size: 21),
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
                                _orderNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: profilePageInk,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatUsd(total),
                              style: const TextStyle(
                                color: profilePageInk,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}  •  ${isPickup ? 'Pickup' : 'Delivery'}  •  ${_formatDate(createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: profilePageMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: .055),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            status.label,
                            style: TextStyle(
                              color: status.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          cancelled
                              ? 'Cancelled'
                              : finished
                              ? 'Completed'
                              : 'Step ${stage + 1} of 4',
                          style: const TextStyle(
                            color: profilePageMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE7EBEF),
                        valueColor: AlwaysStoppedAnimation(status.color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          finished
                              ? Icons.check_circle_outline_rounded
                              : isPickup
                              ? Icons.storefront_outlined
                              : Icons.schedule_rounded,
                          color: profilePageMuted,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _statusSummary(
                              statusValue,
                              isPickup: isPickup,
                              etaMin: etaMin,
                              etaMax: etaMax,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: profilePageMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'View details',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.red,
                          size: 14,
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

Future<void> _showOrderDetails(
  BuildContext context, {
  required String id,
  required Map<String, dynamic> data,
}) {
  final items = (data['items'] as List?) ?? const [];
  final total = (data['total'] as num?) ?? 0;
  final subtotal = (data['subtotal'] as num?) ?? total;
  final deliveryFee = (data['deliveryFee'] as num?) ?? 0;
  final serviceFee = (data['serviceFee'] as num?) ?? 0;
  final discount = (data['discount'] as num?) ?? 0;
  final isPickup = data['fulfillmentMethod'] == 'pickup';
  final savedAddress = (data['deliveryAddress'] as String?)?.trim() ?? '';
  final pickupStore = (data['pickupStoreName'] as String?)?.trim() ?? '';
  final pickupAddress = (data['pickupAddress'] as String?)?.trim() ?? '';
  final receiverName = (data['receiverName'] as String?)?.trim() ?? '';
  final phone = (data['phone'] as String?)?.trim() ?? '';
  final paymentMethod = (data['paymentMethod'] as String?)?.trim() ?? 'cash';
  final paymentStatus = (data['paymentStatus'] as String?)?.trim() ?? 'pending';
  final statusValue = (data['status'] as String?) ?? 'placed';
  final etaMin = (data['etaMinMinutes'] as num?)?.toInt() ?? 30;
  final etaMax = (data['etaMaxMinutes'] as num?)?.toInt() ?? 40;
  final createdAt = _timestampFrom(
    data['createdAt'] ?? data['createdAtClient'],
  );
  final address = isPickup
      ? [
          pickupStore,
          pickupAddress,
        ].where((value) => value.isNotEmpty).join(' • ')
      : savedAddress;
  final status = _OrderStatus.fromValue(statusValue);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xA1151820),
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: .9,
      minChildSize: .62,
      maxChildSize: .94,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: profilePageBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 11, 13, 7),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2DCE3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: profilePageInk,
                      fixedSize: const Size(38, 38),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  _OrderDetailHero(
                    orderNumber: id,
                    status: status,
                    statusValue: statusValue,
                    isPickup: isPickup,
                    etaMin: etaMin,
                    etaMax: etaMax,
                    createdAt: createdAt,
                  ),
                  const SizedBox(height: 14),
                  _OrderTimeline(statusValue: statusValue, isPickup: isPickup),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Your items',
                    trailing: '${_itemCount(items)} items',
                    child: Column(
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          _OrderItemTile(
                            item: Map<String, dynamic>.from(
                              items[index] as Map,
                            ),
                          ),
                          if (index != items.length - 1)
                            const Divider(height: 19, color: Color(0xFFE7EBEF)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: isPickup ? 'Pickup details' : 'Delivery details',
                    child: Column(
                      children: [
                        if (address.isNotEmpty)
                          _InfoRow(
                            icon: isPickup
                                ? Icons.storefront_outlined
                                : Icons.location_on_outlined,
                            label: isPickup ? 'Collect from' : 'Deliver to',
                            value: address,
                          ),
                        if (receiverName.isNotEmpty)
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Customer',
                            value: receiverName,
                          ),
                        if (phone.isNotEmpty)
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Contact',
                            value: phone,
                            isLast: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Payment summary',
                    trailing: _humanize(paymentStatus),
                    child: Column(
                      children: [
                        _PriceRow(label: 'Subtotal', value: subtotal),
                        if (deliveryFee > 0)
                          _PriceRow(label: 'Delivery', value: deliveryFee),
                        if (serviceFee > 0)
                          _PriceRow(label: 'Service fee', value: serviceFee),
                        if (discount > 0)
                          _PriceRow(
                            label: 'Discount',
                            value: -discount,
                            isDiscount: true,
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Color(0xFFE3E9EE)),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order total',
                                    style: TextStyle(
                                      color: profilePageInk,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _humanize(paymentMethod),
                                    style: const TextStyle(
                                      color: profilePageMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatUsd(total),
                              style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    ),
  );
}

class _OrderDetailHero extends StatelessWidget {
  const _OrderDetailHero({
    required this.orderNumber,
    required this.status,
    required this.statusValue,
    required this.isPickup,
    required this.etaMin,
    required this.etaMax,
    required this.createdAt,
  });

  final String orderNumber;
  final _OrderStatus status;
  final String statusValue;
  final bool isPickup;
  final int etaMin;
  final int etaMax;
  final Timestamp? createdAt;

  @override
  Widget build(BuildContext context) {
    final finished = _isFinishedStatus(statusValue);
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF181B24),
            status.color.withValues(alpha: .82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26151A23),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(status.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORDER TRACKING',
                      style: TextStyle(
                        color: Color(0xFFC9CDD5),
                        fontSize: 9,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPickup ? 'PICKUP' : 'DELIVERY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: .4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            _statusSummary(
              statusValue,
              isPickup: isPickup,
              etaMin: etaMin,
              etaMax: etaMax,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroMeta(label: 'ORDER', value: orderNumber),
              Container(
                width: 1,
                height: 29,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                color: Colors.white24,
              ),
              _HeroMeta(
                label: finished ? 'ORDERED' : 'ESTIMATED',
                value: finished
                    ? _formatDate(createdAt)
                    : '$etaMin–$etaMax min',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB9BEC9),
              fontSize: 8,
              letterSpacing: .55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.statusValue, required this.isPickup});

  final String statusValue;
  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    final currentStage = _statusStage(statusValue, isPickup: isPickup);
    final cancelled = statusValue.toLowerCase() == 'cancelled';
    final labels = isPickup
        ? const ['Placed', 'Preparing', 'Ready', 'Collected']
        : const ['Placed', 'Preparing', 'On the way', 'Delivered'];
    final icons = isPickup
        ? const [
            Icons.receipt_long_outlined,
            Icons.restaurant_rounded,
            Icons.notifications_active_outlined,
            Icons.shopping_bag_outlined,
          ]
        : const [
            Icons.receipt_long_outlined,
            Icons.restaurant_rounded,
            Icons.delivery_dining_outlined,
            Icons.home_outlined,
          ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0E8ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F4A6578),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order progress',
            style: TextStyle(
              color: profilePageInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < labels.length; index++) ...[
                Expanded(
                  child: _TimelineStep(
                    icon: icons[index],
                    label: labels[index],
                    isActive: !cancelled && index <= currentStage,
                    isCurrent: !cancelled && index == currentStage,
                  ),
                ),
                if (index != labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(top: 16),
                      color: !cancelled && index < currentStage
                          ? AppColors.red
                          : const Color(0xFFE0E4E8),
                    ),
                  ),
              ],
            ],
          ),
          if (cancelled) ...[
            const SizedBox(height: 13),
            const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.red,
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  'This order was cancelled.',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isCurrent,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive ? AppColors.red : const Color(0xFFF0F2F4),
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: const Color(0xFFFFD9DD), width: 4)
                : null,
          ),
          child: Icon(
            isActive ? Icons.check_rounded : icon,
            color: isActive ? Colors.white : profilePageMuted,
            size: 16,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            color: isActive ? profilePageInk : profilePageMuted,
            fontSize: 8,
            height: 1.2,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0E8ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D4A6578),
            blurRadius: 15,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: profilePageInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trailing!,
                    style: const TextStyle(
                      color: AppColors.red,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final itemTotal = (item['totalPrice'] as num?) ?? 0;
    final size = (item['size'] as String?)?.trim() ?? '';
    final imageAsset = (item['imageAsset'] as String?)?.trim() ?? '';
    final addOns = ((item['addOns'] as List?) ?? const [])
        .map((value) => value.toString())
        .where((value) => value.trim().isNotEmpty)
        .join(', ');
    final details = [
      size,
      addOns,
    ].where((value) => value.trim().isNotEmpty).join(' • ');

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 51,
            height: 51,
            color: const Color(0xFFF8F9FA),
            child: imageAsset.isEmpty
                ? const Icon(
                    Icons.fastfood_outlined,
                    color: profilePageMuted,
                    size: 22,
                  )
                : Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.fastfood_outlined,
                      color: profilePageMuted,
                      size: 22,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (item['name'] as String?) ?? 'Menu item',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: profilePageInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                details.isEmpty ? 'Standard' : details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: profilePageMuted,
                  fontSize: 9,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatUsd(itemTotal),
              style: const TextStyle(
                color: profilePageInk,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Qty $quantity',
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.red, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: profilePageMuted,
                    fontSize: 8,
                    letterSpacing: .45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: profilePageInk,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isDiscount = false,
  });

  final String label;
  final num value;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: profilePageMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            isDiscount ? '-${formatUsd(value.abs())}' : formatUsd(value),
            style: TextStyle(
              color: isDiscount ? const Color(0xFF24A765) : profilePageInk,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

int _itemCount(List items) {
  return items.fold<int>(0, (runningTotal, rawItem) {
    if (rawItem is! Map) return runningTotal;
    return runningTotal + ((rawItem['quantity'] as num?)?.toInt() ?? 1);
  });
}

Timestamp? _timestampFrom(Object? value) {
  return value is Timestamp ? value : null;
}

bool _isFinishedStatus(String status) {
  return const {
    'delivered',
    'completed',
    'collected',
    'cancelled',
  }.contains(status.toLowerCase());
}

int _statusStage(String status, {required bool isPickup}) {
  final normalized = status.toLowerCase();
  if (normalized == 'cancelled') return 0;
  if (const {'delivered', 'completed', 'collected'}.contains(normalized)) {
    return 3;
  }
  if (isPickup && const {'ready', 'ready_for_pickup'}.contains(normalized)) {
    return 2;
  }
  if (!isPickup &&
      const {'on_the_way', 'out_for_delivery'}.contains(normalized)) {
    return 2;
  }
  if (const {'preparing', 'accepted', 'packed'}.contains(normalized)) {
    return 1;
  }
  return 0;
}

String _statusSummary(
  String status, {
  required bool isPickup,
  required int etaMin,
  required int etaMax,
}) {
  return switch (status.toLowerCase()) {
    'preparing' ||
    'accepted' => 'The kitchen is preparing your food with care.',
    'packed' =>
      isPickup
          ? 'Your meal is packed and nearly ready to collect.'
          : 'Your meal is packed and waiting for a rider.',
    'ready' ||
    'ready_for_pickup' => 'Your order is ready. You can collect it now.',
    'on_the_way' ||
    'out_for_delivery' => 'Your rider is on the way to your address.',
    'delivered' || 'completed' =>
      isPickup ? 'Your order has been collected.' : 'Your order was delivered.',
    'collected' => 'Your order has been collected.',
    'cancelled' => 'This order was cancelled.',
    _ =>
      isPickup
          ? 'Estimated pickup in $etaMin–$etaMax minutes.'
          : 'Estimated delivery in $etaMin–$etaMax minutes.',
  };
}

String _formatDate(Timestamp? timestamp) {
  if (timestamp == null) return 'Just now';
  final date = timestamp.toDate().toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _humanize(String value) {
  if (value.trim().isEmpty) return 'Not available';
  return value
      .trim()
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _OrderStatus {
  const _OrderStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  factory _OrderStatus.fromValue(String value) {
    return switch (value.toLowerCase()) {
      'preparing' || 'accepted' => const _OrderStatus(
        'Preparing your order',
        Color(0xFFF5A313),
        Icons.restaurant_rounded,
      ),
      'packed' => const _OrderStatus(
        'Packed and ready',
        profilePageBlue,
        Icons.inventory_2_outlined,
      ),
      'ready' || 'ready_for_pickup' => const _OrderStatus(
        'Ready for pickup',
        Color(0xFF7357D8),
        Icons.notifications_active_outlined,
      ),
      'on_the_way' || 'out_for_delivery' => const _OrderStatus(
        'On the way',
        Color(0xFF7357D8),
        Icons.delivery_dining_rounded,
      ),
      'delivered' || 'completed' => const _OrderStatus(
        'Delivered',
        Color(0xFF24A765),
        Icons.check_circle_outline_rounded,
      ),
      'collected' => const _OrderStatus(
        'Collected',
        Color(0xFF24A765),
        Icons.shopping_bag_outlined,
      ),
      'cancelled' => const _OrderStatus(
        'Cancelled',
        AppColors.red,
        Icons.cancel_outlined,
      ),
      _ => const _OrderStatus(
        'Order placed',
        AppColors.red,
        Icons.receipt_long_outlined,
      ),
    };
  }
}

class _OrdersMessage extends StatelessWidget {
  const _OrdersMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: AppColors.blush,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.red, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: profilePageInk,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: profilePageMuted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
