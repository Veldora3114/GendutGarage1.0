class EnginePreset {
  const EnginePreset({
    required this.id,
    required this.category,
    required this.brand,
    required this.model,
    required this.stockBoreMm,
    required this.stockStrokeMm,
    required this.stockCc,
    required this.fuelDefault,
    required this.coolingDefault,
    required this.isActive,
  });

  final String id;
  final String category;
  final String brand;
  final String model;
  final double stockBoreMm;
  final double stockStrokeMm;
  final double stockCc;
  final String fuelDefault;
  final String coolingDefault;
  final bool isActive;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'category': category,
      'brand': brand,
      'model': model,
      'stock_bore_mm': stockBoreMm,
      'stock_stroke_mm': stockStrokeMm,
      'stock_cc': stockCc,
      'fuel_default': fuelDefault,
      'cooling_default': coolingDefault,
      'is_active': isActive,
    };
  }

  static EnginePreset fromJson(Map<String, Object?> json) {
    return EnginePreset(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      stockBoreMm: (json['stock_bore_mm'] as num?)?.toDouble() ?? 0,
      stockStrokeMm: (json['stock_stroke_mm'] as num?)?.toDouble() ?? 0,
      stockCc: (json['stock_cc'] as num?)?.toDouble() ?? 0,
      fuelDefault: json['fuel_default']?.toString() ?? 'injeksi',
      coolingDefault: json['cooling_default']?.toString() ?? 'udara',
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

