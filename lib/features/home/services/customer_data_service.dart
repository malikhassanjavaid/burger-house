import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/sample_menu.dart';
import '../models/cart_item.dart';
import '../models/fulfillment_method.dart';
import '../models/menu_item.dart';

class CustomerState {
  const CustomerState({
    this.deliveryCartItems = const [],
    this.pickupCartItems = const [],
    this.favouriteIds = const {},
  });

  final List<CartItem> deliveryCartItems;
  final List<CartItem> pickupCartItems;
  final Set<String> favouriteIds;
}

/// Stores the signed-in customer's unfinished shopping state.
///
/// Delivery and pickup have independent carts on the customer's Firestore
/// document. Switching fulfillment mode therefore never moves items between
/// orders, while Firebase's offline cache can restore both drafts.
class CustomerDataService {
  CustomerDataService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<bool> hasOrderHistory() async {
    final user = _requireUser();
    final snapshot = await _firestore
        .collection('orders')
        .where('customerId', isEqualTo: user.uid)
        .limit(1)
        .get(const GetOptions(source: Source.server));
    return snapshot.docs.isNotEmpty;
  }

  Future<CustomerState> loadState() async {
    final user = _requireUser();
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final menuById = <String, MenuItem>{
      for (final item in sampleMenu) item.id: item,
    };

    // `cartItems` was the original single delivery cart. Reading it as a
    // fallback migrates existing users without losing their unfinished order.
    final deliveryCartItems = _cartItemsFromRaw(
      data.containsKey('deliveryCartItems')
          ? data['deliveryCartItems']
          : data['cartItems'],
      menuById,
    );
    final pickupCartItems = _cartItemsFromRaw(
      data['pickupCartItems'],
      menuById,
    );
    final favouriteIds =
        (data['favouriteIds'] as List?)
            ?.whereType<String>()
            .where(menuById.containsKey)
            .toSet() ??
        <String>{};

    return CustomerState(
      deliveryCartItems: deliveryCartItems,
      pickupCartItems: pickupCartItems,
      favouriteIds: favouriteIds,
    );
  }

  Future<void> saveCart(
    FulfillmentMethod fulfillmentMethod,
    List<CartItem> items,
  ) async {
    final user = _requireUser();
    final serialized = items.map(_cartItemToMap).toList(growable: false);
    final update = <String, dynamic>{
      fulfillmentMethod.isPickup ? 'pickupCartItems' : 'deliveryCartItems':
          serialized,
      fulfillmentMethod.isPickup
              ? 'pickupCartUpdatedAt'
              : 'deliveryCartUpdatedAt':
          FieldValue.serverTimestamp(),
    };
    if (!fulfillmentMethod.isPickup) {
      // Keep the legacy field synchronized during the migration window.
      update['cartItems'] = serialized;
      update['cartUpdatedAt'] = FieldValue.serverTimestamp();
    }
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(update, SetOptions(merge: true));
  }

  Future<void> saveFavourites(Set<String> favouriteIds) async {
    final user = _requireUser();
    final sortedIds = favouriteIds.toList()..sort();
    await _firestore.collection('users').doc(user.uid).set({
      'favouriteIds': sortedIds,
      'favouritesUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Sign in before loading customer data.',
      );
    }
    return user;
  }
}

List<CartItem> _cartItemsFromRaw(
  dynamic rawCart,
  Map<String, MenuItem> menuById,
) {
  final cartItems = <CartItem>[];
  if (rawCart is! List) return cartItems;

  for (final rawItem in rawCart) {
    if (rawItem is! Map) continue;
    final map = Map<String, dynamic>.from(rawItem);
    final menuItem = menuById[map['menuItemId']];
    if (menuItem == null) continue;
    final quantity = (map['quantity'] as num?)?.toInt() ?? 0;
    final unitPrice = (map['unitPrice'] as num?)?.toDouble();
    if (quantity < 1 || unitPrice == null || unitPrice < 0) continue;
    cartItems.add(
      CartItem(
        menuItem: menuItem,
        quantity: quantity,
        unitPrice: unitPrice,
        size: (map['size'] as String?)?.trim().isNotEmpty == true
            ? (map['size'] as String).trim()
            : 'Regular',
        addOns:
            (map['addOns'] as List?)
                ?.whereType<String>()
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList() ??
            const [],
        instructions: (map['instructions'] as String?)?.trim() ?? '',
      ),
    );
  }
  return cartItems;
}

Map<String, dynamic> _cartItemToMap(CartItem item) => {
  'menuItemId': item.menuItem.id,
  'quantity': item.quantity,
  'unitPrice': item.unitPrice,
  'size': item.size,
  'addOns': item.addOns,
  'instructions': item.instructions,
};
