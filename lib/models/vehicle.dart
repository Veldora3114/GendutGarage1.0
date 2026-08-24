class Vehicle {
  const Vehicle({
    required this.id,
    required this.customerId,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.createdAtMs,
  });

  final String id;
  final String customerId;
  final String plateNumber;
  final String brand;
  final String model;
  final int createdAtMs;

  Vehicle copyWith({
    String? id,
    String? customerId,
    String? plateNumber,
    String? brand,
    String? model,
    int? createdAtMs,
  }) {
    return Vehicle(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      plateNumber: plateNumber ?? this.plateNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'plate_number': plateNumber,
      'brand': brand,
      'model': model,
      'created_at_ms': createdAtMs,
    };
  }

  static Vehicle fromJson(Map<String, Object?> json) {
    return Vehicle(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      plateNumber: json['plate_number']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

