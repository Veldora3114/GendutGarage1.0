enum JobStatus { draft, inProgress, done, cancelled }

enum ServicePriority { rendah, menengah, darurat }

extension ServicePriorityX on ServicePriority {
  String get label {
    return switch (this) {
      ServicePriority.rendah => 'Rendah',
      ServicePriority.menengah => 'Menengah',
      ServicePriority.darurat => 'Darurat',
    };
  }

  static ServicePriority tryParse(String value) {
    return switch (value) {
      'rendah' => ServicePriority.rendah,
      'menengah' => ServicePriority.menengah,
      'darurat' => ServicePriority.darurat,
      _ => ServicePriority.rendah,
    };
  }
}

class Job {
  const Job({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.complaint,
    required this.status,
    required this.createdBy,
    required this.createdAtMs,
    required this.bookingId,
    this.assignedMechanicId,
    this.note,
    this.priority,
    this.etaMinutes,
    this.serviceActions = const [],
  });

  final String id;
  final String customerId;
  final String? vehicleId;
  final String complaint;
  final JobStatus status;
  final String createdBy;
  final int createdAtMs;
  final String? bookingId;
  final String? assignedMechanicId;
  final String? note;
  final ServicePriority? priority;
  final int? etaMinutes;
  final List<String> serviceActions;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'complaint': complaint,
      'status': status.name,
      'created_by': createdBy,
      'created_at_ms': createdAtMs,
      'booking_id': bookingId,
      'assigned_mechanic_id': assignedMechanicId,
      'note': note,
      'priority': priority?.name,
      'eta_minutes': etaMinutes,
      'service_actions': serviceActions,
    };
  }

  static Job fromJson(Map<String, Object?> json) {
    final s = json['status']?.toString() ?? JobStatus.draft.name;
    final priStr = json['priority']?.toString();
    final actionsAny = json['service_actions'];
    final actions = actionsAny is List
        ? actionsAny.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];
    return Job(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString(),
      complaint: json['complaint']?.toString() ?? '',
      status: JobStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => JobStatus.draft,
      ),
      createdBy: json['created_by']?.toString() ?? '',
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? 0,
      bookingId: json['booking_id']?.toString(),
      assignedMechanicId: json['assigned_mechanic_id']?.toString(),
      note: json['note']?.toString(),
      priority: priStr == null || priStr.isEmpty
          ? null
          : ServicePriorityX.tryParse(priStr),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      serviceActions: actions,
    );
  }
}

class JobPart {
  const JobPart({
    required this.id,
    required this.jobId,
    required this.partId,
    required this.qty,
    required this.createdBy,
    required this.createdAtMs,
  });

  final String id;
  final String jobId;
  final String partId;
  final int qty;
  final String createdBy;
  final int createdAtMs;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'part_id': partId,
      'qty': qty,
      'created_by': createdBy,
      'created_at_ms': createdAtMs,
    };
  }

  static JobPart fromJson(Map<String, Object?> json) {
    return JobPart(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      partId: json['part_id']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      createdBy: json['created_by']?.toString() ?? '',
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

extension JobStatusX on JobStatus {
  String get label {
    return switch (this) {
      JobStatus.draft => 'Draft',
      JobStatus.inProgress => 'In Progress',
      JobStatus.done => 'Done',
      JobStatus.cancelled => 'Cancelled',
    };
  }
}
