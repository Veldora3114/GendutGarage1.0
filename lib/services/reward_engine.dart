import 'package:gendut_garage/models/invoice.dart';
import 'package:gendut_garage/models/job.dart';

class RewardTier {
  const RewardTier({
    required this.key,
    required this.label,
    required this.minPoints,
  });

  final String key;
  final String label;
  final int minPoints;
}

class RewardServiceStats {
  const RewardServiceStats({
    required this.jobsDone,
    required this.totalPaid,
    required this.totalEtaMinutes,
    required this.serviceActionsDone,
    required this.rendahDone,
    required this.menengahDone,
    required this.daruratDone,
  });

  final int jobsDone;
  final num totalPaid;
  final int totalEtaMinutes;
  final int serviceActionsDone;
  final int rendahDone;
  final int menengahDone;
  final int daruratDone;
}

class RewardProgress {
  const RewardProgress({
    required this.points,
    required this.tier,
    required this.nextTier,
    required this.progressToNext,
    required this.badges,
    required this.stats,
  });

  final int points;
  final RewardTier tier;
  final RewardTier? nextTier;
  final double progressToNext;
  final List<String> badges;
  final RewardServiceStats stats;
}

class RewardEngine {
  static const tiers = <RewardTier>[
    RewardTier(key: 'bronze', label: 'Bronze', minPoints: 0),
    RewardTier(key: 'silver', label: 'Silver', minPoints: 100),
    RewardTier(key: 'gold', label: 'Gold', minPoints: 250),
    RewardTier(key: 'platinum', label: 'Platinum', minPoints: 500),
  ];

  static int computePoints({
    required int jobsDone,
    required num totalPaid,
    required bool gmapsReviewed,
    int totalEtaMinutes = 0,
    int serviceActionsDone = 0,
    int rendahDone = 0,
    int menengahDone = 0,
    int daruratDone = 0,
  }) {
    final safeJobsDone = jobsDone.clamp(0, 999999);
    final jobsPoints = safeJobsDone * 10;
    final paidPoints = (totalPaid / 100000).floor().clamp(0, 999999);
    final etaPoints = (totalEtaMinutes.clamp(0, 999999999) / 30).floor().clamp(
      0,
      999999,
    );
    final actionPoints = (serviceActionsDone.clamp(0, 999999)) * 2;
    final priPoints =
        (menengahDone.clamp(0, 999999) * 3) +
        (daruratDone.clamp(0, 999999) * 6);
    final reviewBonus = gmapsReviewed ? 50 : 0;
    return jobsPoints +
        paidPoints +
        etaPoints +
        actionPoints +
        priPoints +
        reviewBonus;
  }

  static RewardServiceStats computeServiceStats({
    required String customerId,
    required Iterable<Job> jobs,
    required Iterable<InvoiceSummary> invoices,
  }) {
    if (customerId.isEmpty) {
      return const RewardServiceStats(
        jobsDone: 0,
        totalPaid: 0,
        totalEtaMinutes: 0,
        serviceActionsDone: 0,
        rendahDone: 0,
        menengahDone: 0,
        daruratDone: 0,
      );
    }

    final jobById = {for (final j in jobs) j.id: j};
    final doneJobs = jobs.where(
      (j) => j.customerId == customerId && j.status == JobStatus.done,
    );

    var jobsDone = 0;
    var totalEtaMinutes = 0;
    var serviceActionsDone = 0;
    var rendahDone = 0;
    var menengahDone = 0;
    var daruratDone = 0;

    for (final j in doneJobs) {
      jobsDone += 1;
      totalEtaMinutes += (j.etaMinutes ?? 0).clamp(0, 999999999);
      serviceActionsDone += j.serviceActions.length.clamp(0, 999999);
      final pri = j.priority ?? ServicePriority.rendah;
      switch (pri) {
        case ServicePriority.rendah:
          rendahDone += 1;
          break;
        case ServicePriority.menengah:
          menengahDone += 1;
          break;
        case ServicePriority.darurat:
          daruratDone += 1;
          break;
      }
    }

    num totalPaid = 0;
    for (final s in invoices) {
      final job = jobById[s.invoice.jobId];
      if (job == null || job.customerId != customerId) continue;
      if (s.computedPaymentStatus() == PaymentStatus.paid) {
        totalPaid += s.paidAmount;
      }
    }

    return RewardServiceStats(
      jobsDone: jobsDone,
      totalPaid: totalPaid,
      totalEtaMinutes: totalEtaMinutes,
      serviceActionsDone: serviceActionsDone,
      rendahDone: rendahDone,
      menengahDone: menengahDone,
      daruratDone: daruratDone,
    );
  }

  static RewardProgress buildProgress({
    required int jobsDone,
    required num totalPaid,
    required bool gmapsReviewed,
    int totalEtaMinutes = 0,
    int serviceActionsDone = 0,
    int rendahDone = 0,
    int menengahDone = 0,
    int daruratDone = 0,
  }) {
    final points = computePoints(
      jobsDone: jobsDone,
      totalPaid: totalPaid,
      gmapsReviewed: gmapsReviewed,
      totalEtaMinutes: totalEtaMinutes,
      serviceActionsDone: serviceActionsDone,
      rendahDone: rendahDone,
      menengahDone: menengahDone,
      daruratDone: daruratDone,
    );

    RewardTier current = tiers.first;
    RewardTier? next;
    for (var i = 0; i < tiers.length; i++) {
      final t = tiers[i];
      if (points >= t.minPoints) {
        current = t;
        next = i + 1 < tiers.length ? tiers[i + 1] : null;
      }
    }

    double progressToNext() {
      final n = next;
      if (n == null) return 1.0;
      final span = (n.minPoints - current.minPoints).clamp(1, 999999999);
      final got = (points - current.minPoints).clamp(0, span);
      return (got / span).clamp(0.0, 1.0);
    }

    final badges = <String>[];
    if (jobsDone >= 1) badges.add('Servis Pertama');
    if (jobsDone >= 5) badges.add('Rutin');
    if (jobsDone >= 10) badges.add('Loyal');
    if (serviceActionsDone >= 10) badges.add('Perawatan Aktif');
    if (serviceActionsDone >= 25) badges.add('Perawatan Pro');
    if (daruratDone >= 1) badges.add('Tanggap Darurat');
    if (gmapsReviewed) badges.add('Reviewer');
    if (totalPaid >= 2000000) badges.add('Big Spender');

    return RewardProgress(
      points: points,
      tier: current,
      nextTier: next,
      progressToNext: progressToNext(),
      badges: badges,
      stats: RewardServiceStats(
        jobsDone: jobsDone,
        totalPaid: totalPaid,
        totalEtaMinutes: totalEtaMinutes,
        serviceActionsDone: serviceActionsDone,
        rendahDone: rendahDone,
        menengahDone: menengahDone,
        daruratDone: daruratDone,
      ),
    );
  }

  static RewardProgress buildProgressFromServiceHistory({
    required String customerId,
    required Iterable<Job> jobs,
    required Iterable<InvoiceSummary> invoices,
    required bool gmapsReviewed,
  }) {
    final stats = computeServiceStats(
      customerId: customerId,
      jobs: jobs,
      invoices: invoices,
    );
    return buildProgress(
      jobsDone: stats.jobsDone,
      totalPaid: stats.totalPaid,
      gmapsReviewed: gmapsReviewed,
      totalEtaMinutes: stats.totalEtaMinutes,
      serviceActionsDone: stats.serviceActionsDone,
      rendahDone: stats.rendahDone,
      menengahDone: stats.menengahDone,
      daruratDone: stats.daruratDone,
    );
  }
}
