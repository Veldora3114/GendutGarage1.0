import 'dart:typed_data';

import 'package:gendut_garage/models/invoice.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildInvoicePdfBytes({
  required InvoiceSummary summary,
  String shopName = 'Gendut Garage',
  String shopTagline = 'Bengkel Terpercaya Anda',
}) async {
  final doc = pw.Document();

  String rupiah(num v) => 'Rp ${v.toStringAsFixed(0)}';

  final paidAmount = summary.paidAmount;
  final change = paidAmount > summary.invoice.total
      ? paidAmount - summary.invoice.total
      : 0;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        shopTagline,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      summary.invoice.id,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.all(12),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _kv(
                      'Status Invoice',
                      summary.invoice.status.label.toUpperCase(),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _kv(
                      'Status Bayar',
                      summary
                          .computedPaymentStatus()
                          .name
                          .toUpperCase(),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Item',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: const {
                0: pw.FlexColumnWidth(6),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(3),
                3: pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Deskripsi'),
                    _th('Qty', align: pw.TextAlign.right),
                    _th('Harga', align: pw.TextAlign.right),
                    _th('Total', align: pw.TextAlign.right),
                  ],
                ),
                for (final it in summary.items)
                  pw.TableRow(
                    children: [
                      _td(it.description),
                      _td('${it.qty}', align: pw.TextAlign.right),
                      _td(rupiah(it.unitPrice), align: pw.TextAlign.right),
                      _td(rupiah(it.lineTotal), align: pw.TextAlign.right),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 260,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _kvMoney('Subtotal', summary.invoice.subtotal, rupiah),
                    _kvMoney('Diskon', summary.invoice.discount, rupiah),
                    pw.Divider(color: PdfColors.grey300),
                    _kvMoney(
                      'Total',
                      summary.invoice.total,
                      rupiah,
                      strong: true,
                    ),
                    pw.SizedBox(height: 10),
                    _kvMoney('Dibayar', paidAmount, rupiah),
                    if (change > 0) _kvMoney('Kembalian', change, rupiah),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Pembayaran',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (summary.payments.isEmpty)
              pw.Text(
                'Belum ada pembayaran.',
                style: const pw.TextStyle(fontSize: 10),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _th('Metode'),
                      _th('Status'),
                      _th('Nominal', align: pw.TextAlign.right),
                    ],
                  ),
                  for (final p in summary.payments)
                    pw.TableRow(
                      children: [
                        _td(p.method.name.toUpperCase()),
                        _td(p.status.name.toUpperCase()),
                        _td(rupiah(p.amount), align: pw.TextAlign.right),
                      ],
                    ),
                ],
              ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Text(
              'Terima kasih telah mempercayakan motor Anda kepada kami.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _kv(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        value,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );
}

pw.Widget _kvMoney(
  String label,
  num value,
  String Function(num) money, {
  bool strong = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Text(
          money(value),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
    ),
  );
}

pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text, textAlign: align, style: const pw.TextStyle(fontSize: 10)),
  );
}

