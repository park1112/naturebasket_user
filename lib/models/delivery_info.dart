class DeliveryInfo {
  final String name;
  final String phoneNumber;
  final String address;
  final String? request;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  DeliveryInfo({
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.request,
    this.shippedAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'request': request,
      'shippedAt': shippedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  factory DeliveryInfo.fromMap(Map<String, dynamic> map) {
    return DeliveryInfo(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      request: map['request'],
      shippedAt:
          map['shippedAt'] != null ? DateTime.parse(map['shippedAt']) : null,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) =>
      DeliveryInfo.fromMap(json);

  // ... existing code ...
}
