class Part {
  const Part({
    required this.id,
    required this.sku,
    required this.name,
    required this.unit,
    required this.sellPrice,
    required this.buyPrice,
    required this.stockOnHand,
    required this.minStock,
    required this.isActive,
    required this.createdAtMs,
  });

  final String id;
  final String sku;
  final String name;
  final String unit;
  final num sellPrice;
  final num buyPrice;
  final int stockOnHand;
  final int minStock;
  final bool isActive;
  final int createdAtMs;

  bool get isLowStock => stockOnHand <= minStock;

  Part copyWith({
    String? id,
    String? sku,
    String? name,
    String? unit,
    num? sellPrice,
    num? buyPrice,
    int? stockOnHand,
    int? minStock,
    bool? isActive,
    int? createdAtMs,
  }) {
    return Part(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      sellPrice: sellPrice ?? this.sellPrice,
      buyPrice: buyPrice ?? this.buyPrice,
      stockOnHand: stockOnHand ?? this.stockOnHand,
      minStock: minStock ?? this.minStock,
      isActive: isActive ?? this.isActive,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'unit': unit,
      'sell_price': sellPrice,
      'buy_price': buyPrice,
      'stock_on_hand': stockOnHand,
      'min_stock': minStock,
      'is_active': isActive,
      'created_at_ms': createdAtMs,
    };
  }

  static Part fromJson(Map<String, Object?> json) {
    return Part(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'pcs',
      sellPrice: (json['sell_price'] as num?) ?? 0,
      buyPrice: (json['buy_price'] as num?) ?? 0,
      stockOnHand: (json['stock_on_hand'] as num?)?.toInt() ?? 0,
      minStock: (json['min_stock'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

enum StockMovementType {
  inMove,
  outMove,
  adjust,
  refund,
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.partId,
    required this.type,
    required this.qty,
    required this.note,
    required this.refType,
    required this.refId,
    required this.createdBy,
    required this.createdAtMs,
  });

  final String id;
  final String partId;
  final StockMovementType type;
  final int qty;
  final String note;
  final String? refType;
  final String? refId;
  final String createdBy;
  final int createdAtMs;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'part_id': partId,
      'type': type.name,
      'qty': qty,
      'note': note,
      'ref_type': refType,
      'ref_id': refId,
      'created_by': createdBy,
      'created_at_ms': createdAtMs,
    };
  }

  static StockMovement fromJson(Map<String, Object?> json) {
    final t = json['type']?.toString() ?? StockMovementType.adjust.name;
    final mappedType = switch (t) {
      'in' => StockMovementType.inMove,
      'out' => StockMovementType.outMove,
      _ => StockMovementType.values.firstWhere(
          (e) => e.name == t,
          orElse: () => StockMovementType.adjust,
        ),
    };
    return StockMovement(
      id: json['id']?.toString() ?? '',
      partId: json['part_id']?.toString() ?? '',
      type: mappedType,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      note: json['note']?.toString() ?? '',
      refType: json['ref_type']?.toString(),
      refId: json['ref_id']?.toString(),
      createdBy: json['created_by']?.toString() ?? '',
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? 0,
    );
  }
}
