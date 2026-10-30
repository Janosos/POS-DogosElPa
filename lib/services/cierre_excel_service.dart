import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import '../models/pos_models.dart';

class CierreExcelReportService {
  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  static final DateFormat _dateTimeFormat =
      DateFormat('dd/MM/yyyy HH:mm:ss');
  static final DateFormat _fileDateFormat =
      DateFormat('yyyyMMdd_HHmmss');

  /// Generates a professional Excel file (.xlsx) with closing sales summary,
  /// order breakdown, and top-selling products.
  static Future<({String filePath, Uint8List bytes, String fileName})>
      generateCierreExcel({
    required String storeName,
    required String cashierName,
    required String shiftLabel,
    required List<PosOrder> orders,
  }) async {
    final workbook = Workbook();

    final validOrders = orders
        .where((o) => o.status != OrderStatus.cancelled)
        .toList();

    final totalSales =
        validOrders.fold<double>(0.0, (sum, o) => sum + o.total);
    final totalDiscounts =
        validOrders.fold<double>(0.0, (sum, o) => sum + o.discount);

    final cashOrders = validOrders
        .where((o) => o.paymentMethod == PaymentMethod.cash)
        .toList();
    final cardOrders = validOrders
        .where((o) => o.paymentMethod == PaymentMethod.card)
        .toList();
    final qrOrders = validOrders
        .where((o) => o.paymentMethod == PaymentMethod.qr)
        .toList();
    final accountOrders = validOrders
        .where((o) => o.paymentMethod == PaymentMethod.account)
        .toList();

    final cashSales =
        cashOrders.fold<double>(0.0, (sum, o) => sum + o.total);
    final cardSales =
        cardOrders.fold<double>(0.0, (sum, o) => sum + o.total);
    final qrSales =
        qrOrders.fold<double>(0.0, (sum, o) => sum + o.total);
    final accountSales =
        accountOrders.fold<double>(0.0, (sum, o) => sum + o.total);

    final dineInOrders = validOrders
        .where((o) => o.orderType == OrderType.dineIn)
        .toList();
    final takeawayOrders = validOrders
        .where((o) => o.orderType == OrderType.takeaway)
        .toList();
    final deliveryOrders = validOrders
        .where((o) => o.orderType == OrderType.delivery)
        .toList();

    final dineInSales =
        dineInOrders.fold<double>(0.0, (sum, o) => sum + o.total);
    final takeawaySales =
        takeawayOrders.fold<double>(0.0, (sum, o) => sum + o.total);
    final deliverySales =
        deliveryOrders.fold<double>(0.0, (sum, o) => sum + o.total);

    int totalItemsSold = 0;
    final Map<String, ({int count, double revenue, String categoryId})>
        productMap = {};

    for (final o in validOrders) {
      for (final item in o.items) {
        totalItemsSold += item.quantity;
        final existing = productMap[item.name];
        if (existing == null) {
          productMap[item.name] = (
            count: item.quantity,
            revenue: item.total,
            categoryId: _inferCategory(item.name),
          );
        } else {
          productMap[item.name] = (
            count: existing.count + item.quantity,
            revenue: existing.revenue + item.total,
            categoryId: existing.categoryId,
          );
        }
      }
    }

    // -------------------------------------------------------------
    // SHEET 1: RESUMEN DE CIERRE
    // -------------------------------------------------------------
    final Worksheet sheet1 = workbook.worksheets[0];
    sheet1.name = 'Resumen de Cierre';

    // Header Title Banner
    final Range titleRange = sheet1.getRangeByName('A1:F2');
    titleRange.merge();
    titleRange.setText('DOGOS EL PA · REPORTE OFICIAL DE CIERRE DE CAJA');
    titleRange.cellStyle.fontSize = 15;
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontColor = '#FFFFFF';
    titleRange.cellStyle.backColor = '#FF5A1F';
    titleRange.cellStyle.hAlign = HAlignType.center;
    titleRange.cellStyle.vAlign = VAlignType.center;

    // Subtitle Info Box
    sheet1.getRangeByName('A3').setText('INFORMACIÓN DEL TURNO');
    sheet1.getRangeByName('A3:F3').merge();
    sheet1.getRangeByName('A3:F3').cellStyle.bold = true;
    sheet1.getRangeByName('A3:F3').cellStyle.backColor = '#1E1E1E';
    sheet1.getRangeByName('A3:F3').cellStyle.fontColor = '#FFFFFF';
    sheet1.getRangeByName('A3:F3').cellStyle.hAlign = HAlignType.left;

    final generationDate = _dateTimeFormat.format(DateTime.now());
    _setRowPair(sheet1, 4, 'Fecha y Hora del Reporte:', generationDate);
    _setRowPair(sheet1, 5, 'Sucursal / Negocio:', storeName);
    _setRowPair(sheet1, 6, 'Cajero Responsable:', cashierName);
    _setRowPair(sheet1, 7, 'Turno Operativo:', shiftLabel);
    _setRowPair(sheet1, 8, 'Total de Órdenes Válidas:', '${validOrders.length} tickets');

    // Section 1: Desglose Financiero
    sheet1.getRangeByName('A10:F10').merge();
    sheet1.getRangeByName('A10').setText('1. RESUMEN FINANCIERO POR FORMA DE PAGO');
    sheet1.getRangeByName('A10:F10').cellStyle.bold = true;
    sheet1.getRangeByName('A10:F10').cellStyle.fontSize = 11;
    sheet1.getRangeByName('A10:F10').cellStyle.backColor = '#FFCB11';
    sheet1.getRangeByName('A10:F10').cellStyle.fontColor = '#000000';

    _setTableHeader(sheet1, 11, ['MÉTODO DE PAGO', 'TICKETS', 'TOTAL RECAUDADO', '% DE PARTICIPACIÓN']);

    _setDataRow(sheet1, 12, ['Efectivo en Caja', '${cashOrders.length}', cashSales, totalSales > 0 ? (cashSales / totalSales) : 0.0], isCurrencyCol2: true, isPercentCol3: true);
    _setDataRow(sheet1, 13, ['Tarjeta / Terminal NFC', '${cardOrders.length}', cardSales, totalSales > 0 ? (cardSales / totalSales) : 0.0], isCurrencyCol2: true, isPercentCol3: true);
    _setDataRow(sheet1, 14, ['QR / Transferencia Digital', '${qrOrders.length}', qrSales, totalSales > 0 ? (qrSales / totalSales) : 0.0], isCurrencyCol2: true, isPercentCol3: true);
    if (accountOrders.isNotEmpty) {
      _setDataRow(sheet1, 15, ['Cuenta / Convenio', '${accountOrders.length}', accountSales, totalSales > 0 ? (accountSales / totalSales) : 0.0], isCurrencyCol2: true, isPercentCol3: true);
    }

    final totalRowIdx = accountOrders.isNotEmpty ? 16 : 15;
    final Range totalRow = sheet1.getRangeByIndex(totalRowIdx, 1, totalRowIdx, 4);
    sheet1.getRangeByIndex(totalRowIdx, 1).setText('TOTAL VENTAS NETAS');
    sheet1.getRangeByIndex(totalRowIdx, 2).setText('${validOrders.length}');
    sheet1.getRangeByIndex(totalRowIdx, 3).setNumber(totalSales);
    sheet1.getRangeByIndex(totalRowIdx, 3).numberFormat = r'$#,##0.00';
    sheet1.getRangeByIndex(totalRowIdx, 4).setNumber(1.0);
    sheet1.getRangeByIndex(totalRowIdx, 4).numberFormat = '0.0%';

    totalRow.cellStyle.bold = true;
    totalRow.cellStyle.fontSize = 11;
    totalRow.cellStyle.backColor = '#85F8C4'; // Mint
    totalRow.cellStyle.borders.top.lineStyle = LineStyle.thin;
    totalRow.cellStyle.borders.bottom.lineStyle = LineStyle.double;

    // Section 2: Desglose por Tipo de Servicio
    final s2Row = totalRowIdx + 2;
    sheet1.getRangeByIndex(s2Row, 1, s2Row, 6).merge();
    sheet1.getRangeByIndex(s2Row, 1).setText('2. VENTAS POR TIPO DE SERVICIO');
    sheet1.getRangeByIndex(s2Row, 1, s2Row, 6).cellStyle.bold = true;
    sheet1.getRangeByIndex(s2Row, 1, s2Row, 6).cellStyle.fontSize = 11;
    sheet1.getRangeByIndex(s2Row, 1, s2Row, 6).cellStyle.backColor = '#00B4D8'; // Cyan
    sheet1.getRangeByIndex(s2Row, 1, s2Row, 6).cellStyle.fontColor = '#FFFFFF';

    _setTableHeader(sheet1, s2Row + 1, ['TIPO DE SERVICIO', 'TICKETS', 'TOTAL VENTA', '% DEL TOTAL']);
    _setDataRow(sheet1, s2Row + 2, ['Comer Aquí (Mesa)', '${dineInOrders.length}', dineInSales, totalSales > 0 ? (dineInSales / totalSales) : 0.0], isCurrencyCol2: true, isPercentCol3: true);
    _setDataRow(sheet1, s2Row + 3, ['Para Llevar (Mostrador)', '${takeawayOrders.length}', takeawaySales, totalSales > 0 ? (takeawaySales / totalSales) : 0.0], isCurrencyCol2: true, isPercentCol3: true);
    _setDataRow(sheet1, s2Row + 4, ['Servicio a Domicilio', '${deliveryOrders.length}', deliverySales, totalSales > 0 ? (deliverySales / totalSales) : 0.0], isCurrencyCol2: true, isPercentCol3: true);

    // Section 3: Indicadores Clave (KPIs)
    final s3Row = s2Row + 6;
    sheet1.getRangeByIndex(s3Row, 1, s3Row, 6).merge();
    sheet1.getRangeByIndex(s3Row, 1).setText('3. INDICADORES CLAVE DE RENDIMIENTO (KPIs)');
    sheet1.getRangeByIndex(s3Row, 1, s3Row, 6).cellStyle.bold = true;
    sheet1.getRangeByIndex(s3Row, 1, s3Row, 6).cellStyle.fontSize = 11;
    sheet1.getRangeByIndex(s3Row, 1, s3Row, 6).cellStyle.backColor = '#FAF5E9';
    sheet1.getRangeByIndex(s3Row, 1, s3Row, 6).cellStyle.fontColor = '#000000';

    final avgTicket = validOrders.isNotEmpty ? (totalSales / validOrders.length) : 0.0;
    _setRowPair(sheet1, s3Row + 1, 'Ticket Promedio por Venta:', _currencyFormat.format(avgTicket));
    _setRowPair(sheet1, s3Row + 2, 'Total de Artículos Vendidos:', '$totalItemsSold piezas');
    _setRowPair(sheet1, s3Row + 3, 'Total de Descuentos Otorgados:', _currencyFormat.format(totalDiscounts));
    _setRowPair(sheet1, s3Row + 4, 'Órdenes Canceladas / Anuladas:', '${orders.length - validOrders.length}');

    // Column Widths for Sheet 1
    sheet1.setColumnWidthInPixels(1, 230);
    sheet1.setColumnWidthInPixels(2, 130);
    sheet1.setColumnWidthInPixels(3, 170);
    sheet1.setColumnWidthInPixels(4, 150);
    sheet1.setColumnWidthInPixels(5, 120);
    sheet1.setColumnWidthInPixels(6, 120);

    // -------------------------------------------------------------
    // SHEET 2: DETALLE DE ÓRDENES
    // -------------------------------------------------------------
    final Worksheet sheet2 = workbook.worksheets.addWithName('Detalle de Órdenes');

    final Range titleRange2 = sheet2.getRangeByName('A1:J2');
    titleRange2.merge();
    titleRange2.setText('HISTORIAL Y DETALLE DE TICKETS DE VENTA');
    titleRange2.cellStyle.fontSize = 14;
    titleRange2.cellStyle.bold = true;
    titleRange2.cellStyle.fontColor = '#FFFFFF';
    titleRange2.cellStyle.backColor = '#1E1E1E';
    titleRange2.cellStyle.hAlign = HAlignType.center;
    titleRange2.cellStyle.vAlign = VAlignType.center;

    _setTableHeader(
      sheet2,
      4,
      [
        'FOLIO',
        'FECHA Y HORA',
        'CLIENTE',
        'UBICACIÓN',
        'TIPO',
        'MÉTODO PAGO',
        'PRODUCTOS',
        'SUBTOTAL',
        'DESCUENTO',
        'TOTAL (\$)',
      ],
      headerBg: '#FF5A1F',
    );

    int orderRow = 5;
    for (final o in orders) {
      final isEven = (orderRow % 2 == 0);
      final rowBg = isEven ? '#FDF9F0' : '#FFFFFF';

      final itemsSummary = o.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
      final dateStr = _dateTimeFormat.format(o.createdAt);

      sheet2.getRangeByIndex(orderRow, 1).setText(o.orderNumber.toString().padLeft(3, '0'));
      sheet2.getRangeByIndex(orderRow, 1).cellStyle.hAlign = HAlignType.center;

      sheet2.getRangeByIndex(orderRow, 2).setText(dateStr);
      sheet2.getRangeByIndex(orderRow, 2).cellStyle.hAlign = HAlignType.center;

      sheet2.getRangeByIndex(orderRow, 3).setText(o.customerName);
      sheet2.getRangeByIndex(orderRow, 4).setText(o.tableOrLocation);
      sheet2.getRangeByIndex(orderRow, 5).setText(o.orderType.label);
      sheet2.getRangeByIndex(orderRow, 6).setText(o.paymentMethod.label);
      sheet2.getRangeByIndex(orderRow, 7).setText(itemsSummary);

      sheet2.getRangeByIndex(orderRow, 8).setNumber(o.subtotal);
      sheet2.getRangeByIndex(orderRow, 8).numberFormat = r'$#,##0.00';

      sheet2.getRangeByIndex(orderRow, 9).setNumber(o.discount);
      sheet2.getRangeByIndex(orderRow, 9).numberFormat = r'$#,##0.00';

      sheet2.getRangeByIndex(orderRow, 10).setNumber(o.total);
      sheet2.getRangeByIndex(orderRow, 10).numberFormat = r'$#,##0.00';
      sheet2.getRangeByIndex(orderRow, 10).cellStyle.bold = true;

      final range = sheet2.getRangeByIndex(orderRow, 1, orderRow, 10);
      range.cellStyle.backColor = o.status == OrderStatus.cancelled ? '#FFDAD6' : rowBg;
      range.cellStyle.borders.all.lineStyle = LineStyle.thin;

      orderRow++;
    }

    // Orders Total Row
    if (orders.isNotEmpty) {
      final Range summaryRow = sheet2.getRangeByIndex(orderRow, 1, orderRow, 10);
      sheet2.getRangeByIndex(orderRow, 1).setText('TOTAL GENERAL');
      sheet2.getRangeByIndex(orderRow, 7).setText('${orders.length} órdenes');
      sheet2.getRangeByIndex(orderRow, 10).setNumber(totalSales);
      sheet2.getRangeByIndex(orderRow, 10).numberFormat = r'$#,##0.00';

      summaryRow.cellStyle.bold = true;
      summaryRow.cellStyle.backColor = '#FFCB11';
      summaryRow.cellStyle.borders.top.lineStyle = LineStyle.medium;
      summaryRow.cellStyle.borders.bottom.lineStyle = LineStyle.double;
    }

    sheet2.setColumnWidthInPixels(1, 80);
    sheet2.setColumnWidthInPixels(2, 160);
    sheet2.setColumnWidthInPixels(3, 160);
    sheet2.setColumnWidthInPixels(4, 140);
    sheet2.setColumnWidthInPixels(5, 120);
    sheet2.setColumnWidthInPixels(6, 150);
    sheet2.setColumnWidthInPixels(7, 300);
    sheet2.setColumnWidthInPixels(8, 110);
    sheet2.setColumnWidthInPixels(9, 110);
    sheet2.setColumnWidthInPixels(10, 130);

    // -------------------------------------------------------------
    // SHEET 3: VENTAS POR PRODUCTO
    // -------------------------------------------------------------
    final Worksheet sheet3 = workbook.worksheets.addWithName('Ventas por Producto');

    final Range titleRange3 = sheet3.getRangeByName('A1:F2');
    titleRange3.merge();
    titleRange3.setText('REPORTE DE VENTAS POR PRODUCTO Y CATEGORÍA');
    titleRange3.cellStyle.fontSize = 14;
    titleRange3.cellStyle.bold = true;
    titleRange3.cellStyle.fontColor = '#FFFFFF';
    titleRange3.cellStyle.backColor = '#00B4D8';
    titleRange3.cellStyle.hAlign = HAlignType.center;
    titleRange3.cellStyle.vAlign = VAlignType.center;

    _setTableHeader(
      sheet3,
      4,
      [
        'CATEGORÍA',
        'NOMBRE DEL PRODUCTO',
        'CANTIDAD VENDIDA (U)',
        'TOTAL GENERADO (\$)',
        'PRECIO PROMEDIO (\$)',
        '% DE VENTA',
      ],
      headerBg: '#1E1E1E',
    );

    final sortedProducts = productMap.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));

    int prodRow = 5;
    for (final entry in sortedProducts) {
      final isEven = (prodRow % 2 == 0);
      final rowBg = isEven ? '#FDF9F0' : '#FFFFFF';
      final count = entry.value.count;
      final revenue = entry.value.revenue;
      final unitPrice = count > 0 ? (revenue / count) : 0.0;
      final pct = totalSales > 0 ? (revenue / totalSales) : 0.0;

      sheet3.getRangeByIndex(prodRow, 1).setText(entry.value.categoryId.toUpperCase());
      sheet3.getRangeByIndex(prodRow, 2).setText(entry.key);
      sheet3.getRangeByIndex(prodRow, 3).setNumber(count.toDouble());
      sheet3.getRangeByIndex(prodRow, 3).cellStyle.hAlign = HAlignType.center;

      sheet3.getRangeByIndex(prodRow, 4).setNumber(revenue);
      sheet3.getRangeByIndex(prodRow, 4).numberFormat = r'$#,##0.00';
      sheet3.getRangeByIndex(prodRow, 4).cellStyle.bold = true;

      sheet3.getRangeByIndex(prodRow, 5).setNumber(unitPrice);
      sheet3.getRangeByIndex(prodRow, 5).numberFormat = r'$#,##0.00';

      sheet3.getRangeByIndex(prodRow, 6).setNumber(pct);
      sheet3.getRangeByIndex(prodRow, 6).numberFormat = '0.0%';
      sheet3.getRangeByIndex(prodRow, 6).cellStyle.hAlign = HAlignType.right;

      final rowRange = sheet3.getRangeByIndex(prodRow, 1, prodRow, 6);
      rowRange.cellStyle.backColor = rowBg;
      rowRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

      prodRow++;
    }

    if (sortedProducts.isNotEmpty) {
      final Range prodSummary = sheet3.getRangeByIndex(prodRow, 1, prodRow, 6);
      sheet3.getRangeByIndex(prodRow, 1).setText('TOTAL PRODUCTOS');
      sheet3.getRangeByIndex(prodRow, 3).setNumber(totalItemsSold.toDouble());
      sheet3.getRangeByIndex(prodRow, 3).cellStyle.hAlign = HAlignType.center;
      sheet3.getRangeByIndex(prodRow, 4).setNumber(totalSales);
      sheet3.getRangeByIndex(prodRow, 4).numberFormat = r'$#,##0.00';
      sheet3.getRangeByIndex(prodRow, 6).setNumber(1.0);
      sheet3.getRangeByIndex(prodRow, 6).numberFormat = '0.0%';

      prodSummary.cellStyle.bold = true;
      prodSummary.cellStyle.backColor = '#85F8C4';
      prodSummary.cellStyle.borders.top.lineStyle = LineStyle.medium;
      prodSummary.cellStyle.borders.bottom.lineStyle = LineStyle.double;
    }

    sheet3.setColumnWidthInPixels(1, 140);
    sheet3.setColumnWidthInPixels(2, 280);
    sheet3.setColumnWidthInPixels(3, 160);
    sheet3.setColumnWidthInPixels(4, 160);
    sheet3.setColumnWidthInPixels(5, 150);
    sheet3.setColumnWidthInPixels(6, 130);

    // -------------------------------------------------------------
    // SAVE TO FILE
    // -------------------------------------------------------------
    final List<int> excelBytes = workbook.saveAsStream();
    workbook.dispose();

    final uint8Bytes = Uint8List.fromList(excelBytes);
    final timestamp = _fileDateFormat.format(DateTime.now());
    final fileName = 'Reporte_Cierre_DogosElPa_$timestamp.xlsx';

    final tempDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${tempDir.path}/reportes_cierre');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    final file = File('${reportsDir.path}/$fileName');
    await file.writeAsBytes(uint8Bytes, flush: true);

    return (
      filePath: file.path,
      bytes: uint8Bytes,
      fileName: fileName,
    );
  }

  /// Exports the report by prompting the user to save it or share it
  static Future<void> shareOrSaveExcelReport({
    required String filePath,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(filePath,
                  mimeType:
                      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            ],
            text: 'Reporte de Cierre de Caja - Dogos El Pa',
            subject: fileName,
          ),
        );
      } else {
        await FilePicker.saveFile(
          dialogTitle: 'Guardar Reporte de Cierre en Excel (.xlsx)',
          fileName: fileName,
          bytes: bytes,
        );
      }
    } catch (e) {
      debugPrint('Error sharing/saving Excel report: $e');
    }
  }

  // --- Helper Layout Methods ---

  static void _setRowPair(Worksheet sheet, int row, String label, String value) {
    sheet.getRangeByIndex(row, 1).setText(label);
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 1).cellStyle.hAlign = HAlignType.left;

    sheet.getRangeByIndex(row, 2, row, 3).merge();
    sheet.getRangeByIndex(row, 2).setText(value);
    sheet.getRangeByIndex(row, 2).cellStyle.hAlign = HAlignType.left;

    final range = sheet.getRangeByIndex(row, 1, row, 3);
    range.cellStyle.borders.bottom.lineStyle = LineStyle.thin;
  }

  static void _setTableHeader(Worksheet sheet, int row, List<String> headers, {String headerBg = '#1E1E1E'}) {
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(row, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.backColor = headerBg;
      cell.cellStyle.hAlign = HAlignType.center;
      cell.cellStyle.vAlign = VAlignType.center;
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
  }

  static void _setDataRow(
    Worksheet sheet,
    int row,
    List<dynamic> values, {
    bool isCurrencyCol2 = false,
    bool isPercentCol3 = false,
  }) {
    for (int i = 0; i < values.length; i++) {
      final cell = sheet.getRangeByIndex(row, i + 1);
      final val = values[i];
      if (val is double) {
        cell.setNumber(val);
        if (i == 2 && isCurrencyCol2) {
          cell.numberFormat = r'$#,##0.00';
          cell.cellStyle.hAlign = HAlignType.right;
        } else if (i == 3 && isPercentCol3) {
          cell.numberFormat = '0.0%';
          cell.cellStyle.hAlign = HAlignType.right;
        }
      } else if (val is int) {
        cell.setNumber(val.toDouble());
        cell.cellStyle.hAlign = HAlignType.center;
      } else {
        cell.setText(val.toString());
        cell.cellStyle.hAlign = i == 0 ? HAlignType.left : HAlignType.center;
      }
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
  }

  static String _inferCategory(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('dogo') || lower.contains('hotdog') || lower.contains('salchicha')) {
      return 'DOGOS';
    }
    if (lower.contains('papa') || lower.contains('francesa')) {
      return 'PAPAS';
    }
    if (lower.contains('combo') || lower.contains('paquete')) {
      return 'COMBOS';
    }
    return 'GENERAL';
  }
}
