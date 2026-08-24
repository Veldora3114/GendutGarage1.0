// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:gendut_garage/app.dart';
import 'package:gendut_garage/models/invoice.dart';
import 'package:gendut_garage/models/job.dart';
import 'package:gendut_garage/services/reward_engine.dart';

void main() {
  testWidgets('Shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GendutGarageApp(enableSupabase: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();

    expect(find.text('GENDUT GARAGE'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });

  test('RewardEngine menghitung poin dari riwayat servis', () {
    const customerA = 'cust-a';
    const customerB = 'cust-b';

    final jobs = <Job>[
      Job(
        id: 'job-1',
        customerId: customerA,
        vehicleId: 'veh-1',
        complaint: 'C1',
        status: JobStatus.done,
        createdBy: 'u',
        createdAtMs: 1,
        bookingId: null,
        priority: ServicePriority.darurat,
        etaMinutes: 90,
        serviceActions: const ['a', 'b', 'c'],
      ),
      Job(
        id: 'job-2',
        customerId: customerA,
        vehicleId: 'veh-1',
        complaint: 'C2',
        status: JobStatus.done,
        createdBy: 'u',
        createdAtMs: 2,
        bookingId: null,
        priority: ServicePriority.rendah,
        etaMinutes: null,
        serviceActions: const [],
      ),
      Job(
        id: 'job-3',
        customerId: customerA,
        vehicleId: 'veh-1',
        complaint: 'C3',
        status: JobStatus.inProgress,
        createdBy: 'u',
        createdAtMs: 3,
        bookingId: null,
        priority: ServicePriority.menengah,
        etaMinutes: 60,
        serviceActions: const ['x'],
      ),
      Job(
        id: 'job-4',
        customerId: customerB,
        vehicleId: 'veh-2',
        complaint: 'C4',
        status: JobStatus.done,
        createdBy: 'u',
        createdAtMs: 4,
        bookingId: null,
        priority: ServicePriority.darurat,
        etaMinutes: 30,
        serviceActions: const ['z'],
      ),
    ];

    final invoices = <InvoiceSummary>[
      InvoiceSummary(
        invoice: Invoice(
          id: 'inv-1',
          jobId: 'job-1',
          status: InvoiceStatus.finalStatus,
          subtotal: 200000,
          discount: 0,
          total: 200000,
          createdBy: 'u',
          createdAtMs: 10,
        ),
        items: const [],
        payments: const [
          InvoicePayment(
            id: 'pay-1',
            invoiceId: 'inv-1',
            method: PaymentMethod.cash,
            status: PaymentStatus.paid,
            amount: 200000,
            createdBy: 'u',
            createdAtMs: 11,
          ),
        ],
      ),
      InvoiceSummary(
        invoice: Invoice(
          id: 'inv-2',
          jobId: 'job-2',
          status: InvoiceStatus.finalStatus,
          subtotal: 300000,
          discount: 0,
          total: 300000,
          createdBy: 'u',
          createdAtMs: 12,
        ),
        items: const [],
        payments: const [],
      ),
      InvoiceSummary(
        invoice: Invoice(
          id: 'inv-3',
          jobId: 'job-4',
          status: InvoiceStatus.finalStatus,
          subtotal: 100000,
          discount: 0,
          total: 100000,
          createdBy: 'u',
          createdAtMs: 13,
        ),
        items: const [],
        payments: const [
          InvoicePayment(
            id: 'pay-3',
            invoiceId: 'inv-3',
            method: PaymentMethod.cash,
            status: PaymentStatus.paid,
            amount: 100000,
            createdBy: 'u',
            createdAtMs: 14,
          ),
        ],
      ),
    ];

    final stats = RewardEngine.computeServiceStats(
      customerId: customerA,
      jobs: jobs,
      invoices: invoices,
    );

    expect(stats.jobsDone, 2);
    expect(stats.totalPaid, 200000);
    expect(stats.totalEtaMinutes, 90);
    expect(stats.serviceActionsDone, 3);
    expect(stats.rendahDone, 1);
    expect(stats.menengahDone, 0);
    expect(stats.daruratDone, 1);

    final progress = RewardEngine.buildProgressFromServiceHistory(
      customerId: customerA,
      jobs: jobs,
      invoices: invoices,
      gmapsReviewed: true,
    );

    expect(progress.points, 87);
    expect(progress.tier.key, 'bronze');
    expect(progress.stats.jobsDone, 2);
    expect(progress.badges.contains('Tanggap Darurat'), true);
    expect(progress.badges.contains('Reviewer'), true);
  });
}
