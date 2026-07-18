class DeliveryLocation {
  const DeliveryLocation({
    required this.label,
    required this.area,
    required this.addressLine,
    this.landmark = '',
    this.latitude,
    this.longitude,
  });

  final String label;
  final String area;
  final String addressLine;
  final String landmark;
  final double? latitude;
  final double? longitude;

  String get formattedAddress {
    final parts = <String>[addressLine, area];
    if (landmark.trim().isNotEmpty) parts.add('Near $landmark');
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
    'label': label,
    'area': area,
    'addressLine': addressLine,
    'landmark': landmark,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory DeliveryLocation.fromMap(Map<String, dynamic> map) {
    return DeliveryLocation(
      label: (map['label'] as String?) ?? 'Home',
      area: (map['area'] as String?) ?? '',
      addressLine: (map['addressLine'] as String?) ?? '',
      landmark: (map['landmark'] as String?) ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
