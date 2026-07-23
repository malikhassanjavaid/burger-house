import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';

class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.items,
    required this.receiverName,
    required this.phone,
    required this.deliveryAddress,
    required this.landmark,
    required this.deliveryNotes,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
    this.couponCode,
  });

  final List<CartItem> items;
  final String receiverName;
  final String phone;
  final String deliveryAddress;
  final String landmark;
  final String deliveryNotes;
  final String paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;
  final String? couponCode;
}

class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.orderNumber,
    required this.etaMinMinutes,
    required this.etaMaxMinutes,
    required this.deliveryAddress,
    required this.total,
  });

  final String id;
  final String orderNumber;
  final int etaMinMinutes;
  final int etaMaxMinutes;
  final String deliveryAddress;
  final double total;
}

/// Creates an order and clears the customer's draft cart in one batch.
class OrderService {
  OrderService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<PlacedOrder> placeOrder(PlaceOrderRequest request) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Please sign in again before placing your order.',
      );
    }
    if (request.items.isEmpty) {
      throw StateError('An order must contain at least one item.');
    }

    const etaMinMinutes = 30;
    const etaMaxMinutes = 40;
    final now = DateTime.now().toUtc();
    final orderReference = _firestore.collection('orders').doc();
    final shortId = orderReference.id.length > 7
        ? orderReference.id.substring(orderReference.id.length - 7)
        : orderReference.id;
    final orderNumber = 'HS-${shortId.toUpperCase()}';
    final batch = _firestore.batch();

    batch.set(orderReference, {
      'orderNumber': orderNumber,
      'customerId': user.uid,
      'customerEmail': user.email,
      'receiverName': request.receiverName,
      'phone': request.phone,
      'deliveryAddress': request.deliveryAddress,
      'landmark': request.landmark,
      'deliveryNotes': request.deliveryNotes,
      'paymentMethod': request.paymentMethod,
      'paymentStatus': 'pending',
      'status': 'placed',
      'subtotal': request.subtotal,
      'deliveryFee': request.deliveryFee,
      'serviceFee': request.serviceFee,
      'discount': request.discount,
      'couponCode': request.couponCode,
      'total': request.total,
      'etaMinMinutes': etaMinMinutes,
      'etaMaxMinutes': etaMaxMinutes,
      'estimatedDeliveryAt': Timestamp.fromDate(
        now.add(const Duration(minutes: 35)),
      ),
      'items': request.items
          .map(
            (item) => {
              'menuItemId': item.menuItem.id,
              'name': item.menuItem.name,
              'imageAsset': item.menuItem.displayAssetPath,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'totalPrice': item.totalPrice,
              'size': item.size,
              'addOns': item.addOns,
              'instructions': item.instructions,
            },
          )
          .toList(growable: false),
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(_firestore.collection('users').doc(user.uid), {
      'cartItems': const <Map<String, dynamic>>[],
      'cartUpdatedAt': FieldValue.serverTimestamp(),
      'lastOrderId': orderReference.id,
      'lastOrderAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    return PlacedOrder(
      id: orderReference.id,
      orderNumber: orderNumber,
      etaMinMinutes: etaMinMinutes,
      etaMaxMinutes: etaMaxMinutes,
      deliveryAddress: request.deliveryAddress,
      total: request.total,
    );
  }
}
