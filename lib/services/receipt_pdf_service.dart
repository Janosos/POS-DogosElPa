import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/pos_models.dart';

class ReceiptPdfService {
  static Future<Uint8List> generateReceiptPdfBytes({
    required PosOrder order,
    required String storeName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final formattedDate = dateFormat.format(order.createdAt);

    // Standard 80mm thermal receipt width (approx 226 pt) or compact vertical roll
    const pageFormat = PdfPageFormat(
      72 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Store Name Header
                pw.Text(
                  storeName.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'NOTA DE VENTA / TICKET',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'VENTA EN CAJA',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),

                // Order Metadata
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ORDEN: #${order.orderNumber}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      order.orderType.label,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'FECHA: $formattedDate',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'CLIENTE: ${order.customerName}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'ATENDIÓ: ${order.cashierName}',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),

                // Table Header
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'CANT',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'DESCRIPCIÓN',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'TOTAL',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),

                // Items List
                ...order.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                '${item.quantity}',
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ),
                            pw.Expanded(
                              flex: 4,
                              child: pw.Text(
                                item.name,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                textAlign: pw.TextAlign.right,
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ),
                          ],
                        ),
                        if (item.notes.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10),
                            child: pw.Text(
                              '(${item.notes})',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),

                // Financial Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SUBTOTAL:',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('\$${order.subtotal.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
                if (order.discount > 0) ...[
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        order.discountLabel,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        '-\$${order.discount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL A PAGAR:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('FORMA DE PAGO:',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(order.paymentMethod.label,
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                if (order.amountTendered > 0) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('PAGÓ CON:',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(
                          '\$${order.amountTendered.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('CAMBIO:',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(
                          '\$${order.changeAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],

                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 6),

                // Footer
                pw.Text(
                  '¡GRACIAS POR TU COMPRA!',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'DOGOS EL PA · LOS MEJORES DOGOS',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
                pw.SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Triggers standard Android / iOS / Desktop share sheet with the PDF file
  static Future<void> shareReceipt({
    required PosOrder order,
    required String storeName,
  }) async {
    final pdfBytes = await generateReceiptPdfBytes(
      order: order,
      storeName: storeName,
    );
    final filename = 'ticket_orden_${order.orderNumber}.pdf';
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }

  /// Direct printing or print preview
  static Future<void> printReceipt({
    required PosOrder order,
    required String storeName,
  }) async {
    final pdfBytes = await generateReceiptPdfBytes(
      order: order,
      storeName: storeName,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Ticket_Orden_${order.orderNumber}',
    );
  }
}

