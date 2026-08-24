import 'dart:math' as math;

class ModCalcInput {
  const ModCalcInput({
    required this.boreMm,
    required this.strokeMm,
    required this.targetUsage,
    required this.fuelSystem,
    required this.cooling,
    required this.targetCc,
  });

  final double boreMm;
  final double strokeMm;
  final String targetUsage;
  final String fuelSystem;
  final String cooling;
  final double? targetCc;
}

class BomItem {
  const BomItem({
    required this.sku,
    required this.name,
    required this.spec,
    required this.qty,
  });

  final String? sku;
  final String name;
  final String spec;
  final int qty;

  Map<String, Object?> toJson() => {
    'sku': sku,
    'name': name,
    'spec': spec,
    'qty': qty,
  };
}

class ModCalcResult {
  const ModCalcResult({
    required this.cc,
    required this.ccDelta,
    required this.ccIncreasePct,
    required this.minRon,
    required this.compressionNote,
    required this.recommendationNote,
    required this.bom,
  });

  final double cc;
  final double ccDelta;
  final double ccIncreasePct;
  final int minRon;
  final String compressionNote;
  final String recommendationNote;
  final List<BomItem> bom;

  Map<String, Object?> toPayload() => {
    'cc': cc,
    'cc_delta': ccDelta,
    'cc_increase_pct': ccIncreasePct,
    'min_ron': minRon,
    'compression_note': compressionNote,
    'recommendation_note': recommendationNote,
    'bom': bom.map((e) => e.toJson()).toList(),
  };
}

class ModCalculator {
  static double calcCc({
    required double boreMm,
    required double strokeMm,
    int cylinders = 1,
  }) {
    final volumeMm3 = (math.pi / 4) * boreMm * boreMm * strokeMm * cylinders;
    return volumeMm3 / 1000.0;
  }

  static double requiredBoreForTargetCc({
    required double targetCc,
    required double strokeMm,
  }) {
    final bore2 = (targetCc * 1000.0 * 4) / (math.pi * strokeMm);
    return math.sqrt(bore2);
  }

  static ModCalcResult buildRecommendation({
    required double boreMm,
    required double strokeMm,
    required double stockCc,
    required String usage,
    required String fuelSystem,
    required String cooling,
  }) {
    final cc = calcCc(boreMm: boreMm, strokeMm: strokeMm);
    final delta = cc - stockCc;
    final pct = stockCc <= 0 ? 0.0 : (delta / stockCc) * 100.0;

    final minRon = switch (usage) {
      'Harian Irit' => 92,
      'Harian Kenceng' => 95,
      'Touring' => 95,
      'Race' => 98,
      _ => 92,
    };

    final compressionNote = switch (usage) {
      'Harian Irit' => 'Kompresi konservatif untuk awet & suhu aman.',
      'Harian Kenceng' => 'Kompresi naik moderat, masih aman harian.',
      'Touring' => 'Kompresi moderat, fokus torsi & ketahanan panas.',
      'Race' => 'Kompresi agresif, wajib setting pengapian & AFR.',
      _ => 'Kompresi konservatif.',
    };

    final coolingNote = cooling == 'udara'
        ? 'Pendingin udara lebih sensitif panas, rekomendasi BBM dibuat lebih aman.'
        : 'Pendingin cair lebih stabil suhu, tapi tetap wajib tuning.';

    final recommendationNote =
        '$coolingNote\nRekomendasi final tetap tergantung setting.';

    final boreInt = boreMm.round();
    final boreSpec = '${boreInt}mm';
    final pistonSku = 'PST-${boreInt}MM';
    final ringSku = 'RNG-${boreInt}MM';
    final gasketSku = 'GSK-SET';

    final bom = <BomItem>[
      BomItem(sku: pistonSku, name: 'Piston', spec: boreSpec, qty: 1),
      BomItem(sku: ringSku, name: 'Ring set', spec: boreSpec, qty: 1),
      BomItem(sku: gasketSku, name: 'Gasket set', spec: 'Top end', qty: 1),
    ];

    if (fuelSystem == 'injeksi') {
      final injector = switch (usage) {
        'Harian Irit' => 150,
        'Harian Kenceng' => 180,
        'Touring' => 180,
        'Race' => 220,
        _ => 150,
      };
      final tb = switch (usage) {
        'Harian Irit' => 24,
        'Harian Kenceng' => 26,
        'Touring' => 26,
        'Race' => 28,
        _ => 24,
      };
      bom.addAll([
        BomItem(
          sku: 'INJ-$injector',
          name: 'Injector',
          spec: '${injector}cc',
          qty: 1,
        ),
        BomItem(sku: 'TB-$tb', name: 'Throttle body', spec: '${tb}mm', qty: 1),
      ]);
    } else {
      final carb = switch (usage) {
        'Harian Irit' => 24,
        'Harian Kenceng' => 26,
        'Touring' => 26,
        'Race' => 28,
        _ => 24,
      };
      bom.add(
        BomItem(
          sku: 'CRB-$carb',
          name: 'Karburator',
          spec: '${carb}mm',
          qty: 1,
        ),
      );
    }

    return ModCalcResult(
      cc: cc,
      ccDelta: delta,
      ccIncreasePct: pct,
      minRon: minRon,
      compressionNote: compressionNote,
      recommendationNote: recommendationNote,
      bom: bom,
    );
  }
}
