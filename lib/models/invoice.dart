enum InvoiceStatus { draft, finalStatus, voidStatus }

class Invoice {
  const Invoice({
    required this.id,
    required this.jobId,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.createdBy,
    required this.createdAtMs,
    this.finalizedBy,
    this.finalizedAtMs,
    this.requestedPaymentMethod,
  });

  final String id;
  final String jobId;
  final InvoiceStatus status;
  final num subtotal;
  final num discount;
  final num total;
  final String createdBy;
  final int createdAtMs;
  final String? finalizedBy;
  final int? finalizedAtMs;
  final PaymentMethod? requestedPaymentMethod;

  Invoice copyWith({
    InvoiceStatus? status,
    num? subtotal,
    num? discount,
    num? total,
    String? finalizedBy,
    int? finalizedAtMs,
    PaymentMethod? requestedPaymentMethod,
  }) {
    return Invoice(
      id: id,
      jobId: jobId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      createdBy: createdBy,
      createdAtMs: createdAtMs,
      finalizedBy: finalizedBy ?? this.finalizedBy,
      finalizedAtMs: finalizedAtMs ?? this.finalizedAtMs,
      requestedPaymentMethod:
          requestedPaymentMethod ?? this.requestedPaymentMethod,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'status': status.name,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'created_by': createdBy,
      'created_at_ms': createdAtMs,
      'finalized_by': finalizedBy,
      'finalized_at_ms': finalizedAtMs,
      'requested_payment_method': requestedPaymentMethod?.name,
    };
  }

  static Invoice fromJson(Map<String, Object?> json) {
    final s = json['status']?.toString() ?? InvoiceStatus.draft.name;
    final pm = json['requested_payment_method']?.toString();
    return Invoice(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => InvoiceStatus.draft,
      ),
      subtotal: (json['subtotal'] as num?) ?? 0,
      discount: (json['discount'] as num?) ?? 0,
      total: (json['total'] as num?) ?? 0,
      createdBy: json['created_by']?.toString() ?? '',
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? 0,
      finalizedBy: json['finalized_by']?.toString(),
      finalizedAtMs: (json['finalized_at_ms'] as num?)?.toInt(),
      requestedPaymentMethod: PaymentMethod.values.cast<PaymentMethod?>().firstWhere(
        (e) => e?.name == pm,
        orElse: () => null,
      ),
    );
  }
}

enum InvoiceItemType { service, part }

class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.type,
    required this.description,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    this.partId,
  });

  final String id;
  final String invoiceId;
  final InvoiceItemType type;
  final String description;
  final int qty;
  final num unitPrice;
  final num lineTotal;
  final String? partId;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'type': type.name,
      'description': description,
      'qty': qty,
      'unit_price': unitPrice,
      'line_total': lineTotal,
      'part_id': partId,
    };
  }

  static InvoiceItem fromJson(Map<String, Object?> json) {
    final t = json['type']?.toString() ?? InvoiceItemType.service.name;
    return InvoiceItem(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoice_id']?.toString() ?? '',
      type: InvoiceItemType.values.firstWhere(
        (e) => e.name == t,
        orElse: () => InvoiceItemType.service,
      ),
      description: json['description']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?) ?? 0,
      lineTotal: (json['line_total'] as num?) ?? 0,
      partId: json['part_id']?.toString(),
    );
  }
}

enum PaymentMethod { cash, transfer }

enum PaymentStatus { unpaid, pending, paid, rejected }

class PaymentAccount {
  const PaymentAccount({
    required this.id,
    required this.label,
    required this.accountName,
    required this.accountNumber,
    this.bankName,
    this.isActive = true,
  });

  final String id;
  final String label;
  final String accountName;
  final String accountNumber;
  final String? bankName;
  final bool isActive;

  static PaymentAccount fromJson(Map<String, Object?> json) {
    final bankName = json['bank_name']?.toString().trim() ?? '';
    return PaymentAccount(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      bankName: bankName.isEmpty ? 'BANK BRI' : bankName,
      accountName: json['account_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

class InvoicePayment {
  const InvoicePayment({
    required this.id,
    required this.invoiceId,
    required this.method,
    required this.status,
    required this.amount,
    required this.createdBy,
    required this.createdAtMs,
    this.transferRef,
    this.proofNote,
    this.proofPath,
    this.proofMime,
    this.accountId,
    this.cashReceived,
    this.cashChange,
    this.verifiedBy,
    this.verifiedAtMs,
    this.paidAtMs,
  });

  final String id;
  final String invoiceId;
  final PaymentMethod method;
  final PaymentStatus status;
  final num amount;
  final String createdBy;
  final int createdAtMs;
  final String? transferRef;
  final String? proofNote;
  final String? proofPath;
  final String? proofMime;
  final String? accountId;
  final num? cashReceived;
  final num? cashChange;
  final String? verifiedBy;
  final int? verifiedAtMs;
  final int? paidAtMs;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'method': method.name,
      'status': status.name,
      'amount': amount,
      'created_by': createdBy,
      'created_at_ms': createdAtMs,
      'transfer_ref': transferRef,
      'proof_note': proofNote,
      'proof_path': proofPath,
      'proof_mime': proofMime,
      'account_id': accountId,
      'cash_received': cashReceived,
      'cash_change': cashChange,
      'verified_by': verifiedBy,
      'verified_at_ms': verifiedAtMs,
      'paid_at_ms': paidAtMs,
    };
  }

  static InvoicePayment fromJson(Map<String, Object?> json) {
    final m = json['method']?.toString() ?? PaymentMethod.cash.name;
    final s = json['status']?.toString() ?? PaymentStatus.unpaid.name;
    return InvoicePayment(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoice_id']?.toString() ?? '',
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == m,
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => PaymentStatus.unpaid,
      ),
      amount: (json['amount'] as num?) ?? 0,
      createdBy: json['created_by']?.toString() ?? '',
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? 0,
      transferRef: json['transfer_ref']?.toString(),
      proofNote: json['proof_note']?.toString(),
      proofPath: json['proof_path']?.toString(),
      proofMime: json['proof_mime']?.toString(),
      accountId: json['account_id']?.toString(),
      cashReceived: json['cash_received'] as num?,
      cashChange: json['cash_change'] as num?,
      verifiedBy: json['verified_by']?.toString(),
      verifiedAtMs: (json['verified_at_ms'] as num?)?.toInt(),
      paidAtMs: (json['paid_at_ms'] as num?)?.toInt(),
    );
  }
}

class InvoiceSummary {
  const InvoiceSummary({
    required this.invoice,
    required this.items,
    required this.payments,
  });

  final Invoice invoice;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;

  num get paidAmount {
    return payments
        .where((p) => p.status == PaymentStatus.paid)
        .fold<num>(0, (a, b) => a + b.amount);
  }

  bool get hasPendingTransfer {
    return payments.any(
      (p) =>
          p.method == PaymentMethod.transfer &&
          p.status == PaymentStatus.pending,
    );
  }

  bool get isPaid => paidAmount >= invoice.total && invoice.total > 0;

  PaymentStatus computedPaymentStatus() {
    if (isPaid) return PaymentStatus.paid;
    if (hasPendingTransfer) return PaymentStatus.pending;
    if (payments.any((p) => p.status == PaymentStatus.rejected)) {
      return PaymentStatus.rejected;
    }
    return PaymentStatus.unpaid;
  }
}

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    return switch (this) {
      InvoiceStatus.draft => 'Draft',
      InvoiceStatus.finalStatus => 'Final',
      InvoiceStatus.voidStatus => 'Void',
    };
  }
}
