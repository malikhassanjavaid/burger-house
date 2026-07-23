import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/sample_menu.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CustomerState {
  const CustomerState({
    this.cartItems = const [],
    this.favouriteIds = const {},
  });

  final List<CartItem> cartItems;
  final Set<String> favouriteIds;
}

/// Stores the signed-in customer's unfinished shopping state.
///
/// Cart and favourite data live on that customer's own Firestore user
/// document. This keeps one user's draft completely separate from every other
/// account on the device and allows Firebase's native offline cache to restore
/// the last known state even during a temporary connection problem.
class CustomerDataService {
  CustomerDataService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<CustomerState> loadState() async {
    final user = _requireUser();
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final menuById = <String, MenuItem>{
      for (final item in sampleMenu) item.id: item,
    };

    final cartItems = <CartItem>[];
    final rawCart = data['cartItems'];
    if (rawCart is List) {
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
    }

    final favouriteIds =
        (data['favouriteIds'] as List?)
            ?.whereType<String>()
            .where(menuById.containsKey)
            .toSet() ??
        <String>{};

    return CustomerState(cartItems: cartItems, favouriteIds: favouriteIds);
  }

  Future<void> saveCart(List<CartItem> items) async {
    final user = _requireUser();
    await _firestore.collection('users').doc(user.uid).set({
      'cartItems': items.map(_cartItemToMap).toList(growable: false),
      'cartUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

Map<String, dynamic> _cartItemToMap(CartItem item) => {
  'menuItemId': item.menuItem.id,
  'quantity': item.quantity,
  'unitPrice': item.unitPrice,
  'size': item.size,
  'addOns': item.addOns,
  'instructions': item.instructions,
};
