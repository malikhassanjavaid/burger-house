import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
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
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.red,
                          ),
                        );
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

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
                        itemCount: documents.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 13),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text(
                                'YOUR ORDERS',
                                style: TextStyle(
                                  color: profilePageInk,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );
                          }
                          final document = documents[index - 1];
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
    final status = (data['status'] as String?) ?? 'placed';
    final createdAt =
        (data['createdAt'] ?? data['createdAtClient']) as Timestamp?;
    final etaMin = (data['etaMinMinutes'] as num?)?.toInt() ?? 30;
    final etaMax = (data['etaMaxMinutes'] as num?)?.toInt() ?? 40;
    final itemCount = items.fold<int>(0, (total, rawItem) {
      if (rawItem is! Map) return total;
      return total + ((rawItem['quantity'] as num?)?.toInt() ?? 1);
    });
    final statusInfo = _OrderStatus.fromValue(status);

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1247657A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.blush,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.red,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _orderNumber,
                      style: const TextStyle(
                        color: profilePageInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'} • ${_formatDate(createdAt)}',
                      style: const TextStyle(
                        color: profilePageMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatUsd(total),
                style: const TextStyle(
                  color: profilePageInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFE3EAF0)),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusInfo.icon, color: statusInfo.color, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      statusInfo.label,
                      style: TextStyle(
                        color: statusInfo.color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!_isFinishedStatus(status)) ...[
                const Icon(
                  Icons.schedule_rounded,
                  color: profilePageMuted,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '$etaMin–$etaMax min',
                  style: const TextStyle(
                    color: profilePageMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              TextButton(
                onPressed: () =>
                    _showOrderDetails(context, id: _orderNumber, data: data),
                style: TextButton.styleFrom(
                  foregroundColor: profilePageBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'VIEW DETAILS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
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
  final address = (data['deliveryAddress'] as String?) ?? '';
  final statusValue = (data['status'] as String?) ?? 'placed';
  final etaMin = (data['etaMinMinutes'] as num?)?.toInt() ?? 30;
  final etaMax = (data['etaMaxMinutes'] as num?)?.toInt() ?? 40;
  final status = _OrderStatus.fromValue(statusValue);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: .62,
      minChildSize: .46,
      maxChildSize: .86,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: profilePageBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DEE5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 21),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ORDER DETAILS',
                        style: TextStyle(
                          color: profilePageInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        id,
                        style: const TextStyle(
                          color: profilePageMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
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
                    color: status.color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: status.color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_isFinishedStatus(statusValue))
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blush,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining_rounded,
                      color: AppColors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Estimated delivery in $etaMin–$etaMax minutes',
                        style: const TextStyle(
                          color: profilePageInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ...items.map((rawItem) {
              final item = Map<String, dynamic>.from(rawItem as Map);
              final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
              final itemTotal = (item['totalPrice'] as num?) ?? 0;
              final size = (item['size'] as String?) ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFDDE6EC)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: const BoxDecoration(
                        color: AppColors.blush,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$quantity×',
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
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
                            style: const TextStyle(
                              color: profilePageInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (size.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              size,
                              style: const TextStyle(
                                color: profilePageMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      formatUsd(itemTotal),
                      style: const TextStyle(
                        color: profilePageInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: profilePageBlue,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          color: profilePageMuted,
                          fontSize: 10.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: profilePageInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  formatUsd(total),
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

bool _isFinishedStatus(String status) {
  return const {
    'delivered',
    'completed',
    'cancelled',
  }.contains(status.toLowerCase());
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

class _OrderStatus {
  const _OrderStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  factory _OrderStatus.fromValue(String value) {
    return switch (value.toLowerCase()) {
      'preparing' => const _OrderStatus(
        'Preparing',
        Color(0xFFF5A313),
        Icons.restaurant_rounded,
      ),
      'packed' => const _OrderStatus(
        'Packed',
        profilePageBlue,
        Icons.inventory_2_outlined,
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
      'cancelled' => const _OrderStatus(
        'Cancelled',
        AppColors.red,
        Icons.cancel_outlined,
      ),
      _ => const _OrderStatus(
        'Order placed',
        AppColors.red,
        Icons.schedule_rounded,
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
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: profilePageMuted,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
