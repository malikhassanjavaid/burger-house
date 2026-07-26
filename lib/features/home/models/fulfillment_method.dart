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
  static const storeName = 'Hungry Spot Main Store';
  static const address = 'Main pickup counter';
  static const instructions =
      'Show your order number at the counter when your meal is ready.';
}
