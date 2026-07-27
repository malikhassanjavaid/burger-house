enum FulfillmentMethod { delivery, pickup }

extension FulfillmentMethodDetails on FulfillmentMethod {
  bool get isPickup => this == FulfillmentMethod.pickup;

  String get firestoreValue => switch (this) {
    FulfillmentMethod.delivery => 'delivery',
    FulfillmentMethod.pickup => 'pickup',
  };

  String get label => switch (this) {
    FulfillmentMethod.delivery => 'Delivery',
    FulfillmentMethod.pickup => 'Pickup',
  };
}

abstract final class HungrySpotPickup {
  static const storeName = 'Civil Lines';
  static const address = 'Hungry Spot Civil Lines pickup counter';
  static const menuHours = 'Serving Regular Menu: 11:00 - 23:59';
  static const instructions =
      'Show your order number at the counter when your meal is ready.';
}
