enum BookingStatus { pending, confirmed, rejected, checkedIn, cancelled, done }

enum BookingType { service, modif }

class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.bookingDate,
    required this.bookingTime,
    required this.complaint,
    required this.status,
    required this.type,
    this.serviceTypeId,
    this.serviceSubtypeId,
    required this.modifPayload,
    required this.createdAtMs,
    this.confirmedBy,
    this.confirmedAtMs,
  });

  final String id;
  final String customerId;
  final String? vehicleId;
  final DateTime bookingDate;
  final String bookingTime;
  final String complaint;
  final BookingStatus status;
  final BookingType type;
  final String? serviceTypeId;
  final String? serviceSubtypeId;
  final Map<String, Object?>? modifPayload;
  final int createdAtMs;
  final String? confirmedBy;
  final int? confirmedAtMs;

  bool get countsForQuota =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  Booking copyWith({
    String? id,
    String? customerId,
    String? vehicleId,
    DateTime? bookingDate,
    String? bookingTime,
    String? complaint,
    BookingStatus? status,
    BookingType? type,
    String? serviceTypeId,
    String? serviceSubtypeId,
    Map<String, Object?>? modifPayload,
    int? createdAtMs,
    String? confirmedBy,
    int? confirmedAtMs,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      complaint: complaint ?? this.complaint,
      status: status ?? this.status,
      type: type ?? this.type,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      serviceSubtypeId: serviceSubtypeId ?? this.serviceSubtypeId,
      modifPayload: modifPayload ?? this.modifPayload,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAtMs: confirmedAtMs ?? this.confirmedAtMs,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'booking_date': bookingDate.toIso8601String(),
      'booking_time': bookingTime,
      'complaint': complaint,
      'status': status.name,
      'type': type.name,
      'service_type_id': serviceTypeId,
      'service_subtype_id': serviceSubtypeId,
      'modif_payload': modifPayload,
      'created_at_ms': createdAtMs,
      'confirmed_by': confirmedBy,
      'confirmed_at_ms': confirmedAtMs,
    };
  }

  static Booking fromJson(Map<String, Object?> json) {
    final statusStr = json['status']?.toString() ?? BookingStatus.pending.name;
    final typeStr = json['type']?.toString() ?? BookingType.service.name;
    return Booking(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString(),
      bookingDate: DateTime.parse(
        json['booking_date']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      bookingTime: json['booking_time']?.toString() ?? '08:00',
      complaint: json['complaint']?.toString() ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => BookingStatus.pending,
      ),
      type: BookingType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => BookingType.service,
      ),
      serviceTypeId: json['service_type_id']?.toString(),
      serviceSubtypeId: json['service_subtype_id']?.toString(),
      modifPayload: (json['modif_payload'] as Map?)?.cast<String, Object?>(),
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? 0,
      confirmedBy: json['confirmed_by']?.toString(),
      confirmedAtMs: (json['confirmed_at_ms'] as num?)?.toInt(),
    );
  }
}

class ServiceType {
  const ServiceType({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final bool isActive;

  static ServiceType fromRow(Map<String, Object?> json) {
    return ServiceType(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

class ServiceSubtype {
  const ServiceSubtype({
    required this.id,
    required this.serviceTypeId,
    required this.code,
    required this.name,
    required this.description,
    required this.baseLaborPrice,
    required this.defaultEtaMinutes,
    required this.isActive,
  });

  final String id;
  final String serviceTypeId;
  final String code;
  final String name;
  final String description;
  final num baseLaborPrice;
  final int? defaultEtaMinutes;
  final bool isActive;

  static ServiceSubtype fromRow(Map<String, Object?> json) {
    return ServiceSubtype(
      id: json['id']?.toString() ?? '',
      serviceTypeId: json['service_type_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      baseLaborPrice: (json['base_labor_price'] as num?) ?? 0,
      defaultEtaMinutes: (json['default_eta_minutes'] as num?)?.toInt(),
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

class ServiceSubtypePart {
  const ServiceSubtypePart({
    required this.id,
    required this.serviceSubtypeId,
    required this.partId,
    required this.qty,
    required this.isOptional,
  });

  final String id;
  final String serviceSubtypeId;
  final String partId;
  final int qty;
  final bool isOptional;

  static ServiceSubtypePart fromRow(Map<String, Object?> json) {
    return ServiceSubtypePart(
      id: json['id']?.toString() ?? '',
      serviceSubtypeId: json['service_subtype_id']?.toString() ?? '',
      partId: json['part_id']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      isOptional: (json['is_optional'] as bool?) ?? false,
    );
  }
}

extension BookingStatusX on BookingStatus {
  String get label {
    return switch (this) {
      BookingStatus.pending => 'Pending',
      BookingStatus.confirmed => 'Confirmed',
      BookingStatus.rejected => 'Rejected',
      BookingStatus.checkedIn => 'Checked-in',
      BookingStatus.cancelled => 'Cancelled',
      BookingStatus.done => 'Done',
    };
  }
}

extension BookingTypeX on BookingType {
  String get label {
    return switch (this) {
      BookingType.service => 'Service',
      BookingType.modif => 'Upgrade Mesin',
    };
  }
}

class BookingRules {
  static const openSlots = <String>['08:00', '10:00', '13:00', '15:00'];
  static const maxPerSlot = 4;

  static void validateSlot({required DateTime date, required String time}) {
    final isFriday = date.weekday == DateTime.friday;
    if (isFriday) {
      throw Exception('Bengkel tutup hari Jumat');
    }
    final ok = openSlots.contains(time);
    if (!ok) {
      throw Exception('Slot tidak valid');
    }
  }

  static bool canRescheduleCustomer(Booking b) =>
      b.status == BookingStatus.pending;
  static bool canRescheduleAdmin(Booking b) =>
      b.status == BookingStatus.pending || b.status == BookingStatus.confirmed;
  static bool canCancelCustomer(Booking b) => b.status == BookingStatus.pending;
  static bool canConfirmAdmin(Booking b) => b.status == BookingStatus.pending;
  static bool canRejectAdmin(Booking b) => b.status == BookingStatus.pending;
  static bool canCheckInAdmin(Booking b) => b.status == BookingStatus.confirmed;
}
