enum AttendanceState { notCheckedIn, working, breakTime, checkedOut }

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.staffId,
    required this.workDate,
    required this.checkInMs,
    this.breakStartMs,
    this.breakEndMs,
    this.checkOutMs,
    required this.autoCheckout,
    required this.createdAtMs,
  });

  final String id;
  final String staffId;
  final DateTime workDate;
  final int checkInMs;
  final int? breakStartMs;
  final int? breakEndMs;
  final int? checkOutMs;
  final bool autoCheckout;
  final int createdAtMs;

  AttendanceState get state {
    if (checkInMs <= 0) return AttendanceState.notCheckedIn;
    if (checkOutMs != null) return AttendanceState.checkedOut;
    if (breakStartMs != null && breakEndMs == null) {
      return AttendanceState.breakTime;
    }
    return AttendanceState.working;
  }

  static AttendanceRecord fromJson(Map<String, Object?> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? '',
      workDate: DateTime.parse(
        json['work_date']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      checkInMs: (json['check_in_ms'] as num?)?.toInt() ?? 0,
      breakStartMs: (json['break_start_ms'] as num?)?.toInt(),
      breakEndMs: (json['break_end_ms'] as num?)?.toInt(),
      checkOutMs: (json['check_out_ms'] as num?)?.toInt(),
      autoCheckout: (json['auto_checkout'] as bool?) ?? false,
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

