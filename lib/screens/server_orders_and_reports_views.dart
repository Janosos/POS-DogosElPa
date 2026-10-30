import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_models.dart';
import '../services/cierre_excel_service.dart';
import '../services/receipt_pdf_service.dart';
import '../theme/manga_theme.dart';
import '../widgets/manga_widgets.dart';

// ==================== TICKETS HISTORY VIEW ====================

class ServerTicketsHistoryView extends StatelessWidget {
  final PosController controller;

  const ServerTicketsHistoryView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final orders = controller.orders;
    final isCompactHeight = MediaQuery.of(context).size.height < 500;

    return Padding(
      padding: EdgeInsets.all(isCompactHeight ? 8 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isCompactHeight ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: MangaColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: MangaShadows.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORIAL DE TICKETS Y ÓRDENES',
                      style: MangaFonts.comic(
                        fontSize: isCompactHeight ? 20 : 25,
                      ),
                    ),
                    Text(
                      'Total de órdenes: ${orders.length} · Siguiente orden: #${controller.nextOrderNumber}',
                      style: MangaFonts.sans(
                          fontSize: 11.5, color: Colors.black87),
                    ),
                  ],
                ),
                MangaPressButton(
                  onTap: () => controller.lanService
                      .broadcastFullSync(controller.orders),
                  height: isCompactHeight ? 36 : 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: MangaColors.accentYellow,
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded,
                          size: 16, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        'SINCRONIZAR CLIENTES',
                        style: MangaFonts.comic(
                          fontSize: isCompactHeight ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompactHeight ? 8 : 12),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'AÚN NO HAY TICKETS REGISTRADOS',
                      style: MangaFonts.comic(fontSize: 26),
                    ),
                  )
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final dateStr = DateFormat('dd/MM/yyyy HH:mm')
                          .format(order.createdAt);
                      final itemsSummary = order.items
                          .map((i) => '${i.quantity}x ${i.name}')
                          .join(', ');

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 2.5),
                          boxShadow: MangaShadows.sm,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${order.orderNumber}',
                                style: MangaFonts.comic(
                                  fontSize: 22,
                                  color: MangaColors.accentYellow,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '${order.customerName} (${order.orderType.label})',
                                        style: MangaFonts.comic(fontSize: 18),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: MangaColors.badgeSoftBlue,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                              color: Colors.black, width: 1.5),
                                        ),
                                        child: Text(
                                          order.paymentMethod.label,
                                          style: MangaFonts.sans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: order.status ==
                                                  OrderStatus.completed
                                              ? MangaColors.accentMint
                                              : MangaColors.accentYellow,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                              color: Colors.black, width: 1.5),
                                        ),
                                        child: Text(
                                          order.status.label,
                                          style: MangaFonts.sans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    itemsSummary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: MangaFonts.sans(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Emitido: $dateStr',
                                    style: MangaFonts.sans(
                                      fontSize: 10.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MangaColors.accentYellow,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                  child: Text(
                                    '\$${order.total.toStringAsFixed(2)}',
                                    style: MangaFonts.comic(fontSize: 22),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    // Compartir PDF
                                    MangaPressButton(
                                      onTap: () async {
                                        try {
                                          await ReceiptPdfService.shareReceipt(
                                            order: order,
                                            storeName: controller.storeName,
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                    MangaColors.dangerRed,
                                                content: Text(
                                                    'Error al compartir PDF: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      height: 28,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      backgroundColor: MangaColors.accentMint,
                                      tooltip:
                                          'Generar y compartir nota de venta en PDF',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.share_rounded,
                                              size: 14, color: Colors.black),
                                          const SizedBox(width: 4),
                                          Text(
                                            'PDF NOTA',
                                            style: MangaFonts.comic(
                                                fontSize: 12,
                                                color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Re-enviar a Cocina / Cliente
                                    MangaPressButton(
                                      onTap: () {
                                        controller.lanService
                                            .broadcastNewOrder(order);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.black,
                                            content: Text(
                                              '📡 Orden #${order.orderNumber} re-enviada al Cliente.',
                                              style: MangaFonts.sans(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        );
                                      },
                                      height: 28,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      backgroundColor: MangaColors.accentCyan,
                                      tooltip: 'Re-enviar pedido al Cliente',
                                      child: Center(
                                        child: Text(
                                          'RE-ENVIAR',
                                          style: MangaFonts.comic(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    // Eliminar ticket individual
                                    MangaPressButton(
                                      onTap: () => _confirmDeleteSingleTicket(
                                          context, order),
                                      height: 28,
                                      width: 28,
                                      backgroundColor:
                                          MangaColors.dangerSoftRed,
                                      tooltip: 'Eliminar este ticket',
                                      child: const Icon(
                                        Icons.delete_forever_rounded,
                                        size: 16,
                                        color: MangaColors.dangerRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSingleTicket(
      BuildContext context, PosOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MangaColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: MangaShadows.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿ELIMINAR TICKET #${order.orderNumber}?',
                style: MangaFonts.comic(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Se eliminará este ticket específico por \$${order.total.toStringAsFixed(2)} del historial. Esta acción no se puede deshacer.',
                style: MangaFonts.sans(fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(false),
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: Text('CANCELAR',
                          style: MangaFonts.comic(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(true),
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: MangaColors.dangerSoftRed,
                    child: Center(
                      child: Text(
                        'ELIMINAR TICKET',
                        style: MangaFonts.comic(
                            fontSize: 15, color: MangaColors.dangerRed),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await controller.deleteSingleOrder(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            content: Text(
              '🗑️ Ticket #${order.orderNumber} eliminado.',
              style: MangaFonts.sans(color: Colors.white),
            ),
          ),
        );
      }
    }
  }
}

// ==================== REPORTS & CIERRE DE CAJA VIEW ====================

class ServerReportsView extends StatelessWidget {
  final PosController controller;

  const ServerReportsView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final validOrders = controller.orders
        .where((o) => o.status != OrderStatus.cancelled)
        .toList();

    final totalSales =
        validOrders.fold<double>(0.0, (sum, o) => sum + o.total);
    final cashSales = validOrders
        .where((o) => o.paymentMethod == PaymentMethod.cash)
        .fold<double>(0.0, (sum, o) => sum + o.total);
    final cardSales = validOrders
        .where((o) => o.paymentMethod == PaymentMethod.card)
        .fold<double>(0.0, (sum, o) => sum + o.total);
    final qrSales = validOrders
        .where((o) => o.paymentMethod == PaymentMethod.qr)
        .fold<double>(0.0, (sum, o) => sum + o.total);

    final Map<String, int> productCounts = {};
    final Map<String, double> productRevenue = {};
    for (final o in validOrders) {
      for (final item in o.items) {
        productCounts[item.name] =
            (productCounts[item.name] ?? 0) + item.quantity;
        productRevenue[item.name] =
            (productRevenue[item.name] ?? 0.0) + item.total;
      }
    }
    final sortedTopProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: MangaColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: MangaShadows.md,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REPORTES Y CORTE DE CAJA · ${controller.storeName}',
                      style: MangaFonts.comic(fontSize: 24),
                    ),
                    Text(
                      'Resumen de ventas de Dogos, Papas y Combos',
                      style:
                          MangaFonts.sans(fontSize: 11.5, color: Colors.black87),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MangaColors.accentYellow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: MangaShadows.sm,
                      ),
                      child: Text(
                        'TOTAL: \$${totalSales.toStringAsFixed(2)}',
                        style: MangaFonts.comic(fontSize: 22),
                      ),
                    ),
                    MangaPressButton(
                      onTap: () => _handleGenerateExcelReport(context),
                      height: 42,
                      backgroundColor: MangaColors.accentMint,
                      hoverColor: MangaColors.accentMintDark,
                      borderWidth: 2,
                      borderRadius: 10,
                      shadow: MangaShadows.sm,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.table_chart_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GENERAR REPORTE',
                            style: MangaFonts.comic(
                              fontSize: 17,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Excel Report Quick Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MangaColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: MangaShadows.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MangaColors.accentMint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REPORTE DE CORTE DE CAJA (EXCEL .XLSX)',
                        style: MangaFonts.comic(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Genera un archivo profesional con 3 hojas: Resumen Financiero por forma de pago, Detalle de tickets y Ventas por producto.',
                        style: MangaFonts.sans(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                MangaPressButton(
                  onTap: () => _handleGenerateExcelReport(context),
                  height: 44,
                  backgroundColor: MangaColors.primaryOrange,
                  hoverColor: MangaColors.primaryOrangeHover,
                  borderWidth: 2.5,
                  borderRadius: 10,
                  shadow: MangaShadows.sm,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GENERAR REPORTE',
                        style: MangaFonts.comic(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // KPI Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 36) / 4;
              final effectiveWidth = cardWidth < 180 ? 200.0 : cardWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildMetricCard(
                    width: effectiveWidth,
                    title: 'VENTAS TOTALES',
                    value: '\$${totalSales.toStringAsFixed(2)}',
                    subtitle: '${validOrders.length} órdenes',
                    bgColor: MangaColors.primaryOrange,
                    textColor: Colors.white,
                    icon: Icons.attach_money_rounded,
                  ),
                  _buildMetricCard(
                    width: effectiveWidth,
                    title: 'EFECTIVO',
                    value: '\$${cashSales.toStringAsFixed(2)}',
                    subtitle: 'En caja',
                    bgColor: MangaColors.accentMint,
                    textColor: Colors.black,
                    icon: Icons.payments_rounded,
                  ),
                  _buildMetricCard(
                    width: effectiveWidth,
                    title: 'TARJETA / NFC',
                    value: '\$${cardSales.toStringAsFixed(2)}',
                    subtitle: 'Terminal',
                    bgColor: MangaColors.accentCyan,
                    textColor: Colors.white,
                    icon: Icons.credit_card_rounded,
                  ),
                  _buildMetricCard(
                    width: effectiveWidth,
                    title: 'QR / TRANSFERENCIA',
                    value: '\$${qrSales.toStringAsFixed(2)}',
                    subtitle: 'Digital',
                    bgColor: MangaColors.accentYellow,
                    textColor: Colors.black,
                    icon: Icons.qr_code_2_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Top Products Table
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: MangaShadows.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆 PRODUCTOS MÁS VENDIDOS',
                  style: MangaFonts.comic(fontSize: 22),
                ),
                const SizedBox(height: 10),
                if (sortedTopProducts.isEmpty)
                  Text(
                    'Aún no se han registrado ventas.',
                    style: MangaFonts.sans(fontSize: 12.5, color: Colors.black54),
                  )
                else
                  ...sortedTopProducts.take(8).map((entry) {
                    final rev = productRevenue[entry.key] ?? 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: MangaColors.ticketListBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: MangaColors.primaryOrange,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.black, width: 1.5),
                                ),
                                child: Text(
                                  '${entry.value}x',
                                  style: MangaFonts.comic(
                                      fontSize: 15, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                entry.key,
                                style: MangaFonts.comic(fontSize: 18),
                              ),
                            ],
                          ),
                          Text(
                            '\$${rev.toStringAsFixed(2)}',
                            style: MangaFonts.comic(fontSize: 19),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: MangaShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: MangaFonts.sans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              Icon(icon, color: textColor, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: MangaFonts.comic(fontSize: 30, color: textColor),
          ),
          Text(
            subtitle,
            style: MangaFonts.sans(
              fontSize: 10.5,
              color: textColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGenerateExcelReport(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Generando reporte Excel profesional...',
                style: MangaFonts.comic(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
          backgroundColor: MangaColors.accentYellow,
          duration: const Duration(seconds: 1),
        ),
      );

      final result = await CierreExcelReportService.generateCierreExcel(
        storeName: controller.storeName,
        cashierName: controller.cashierName,
        shiftLabel: controller.shiftLabel,
        orders: controller.orders,
      );

      if (!context.mounted) return;

      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: MangaColors.surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.black, width: 3),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: MangaColors.accentMint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡REPORTE GENERADO CON ÉXITO!',
                    style: MangaFonts.comic(fontSize: 22),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El reporte en formato Excel (.xlsx) ha sido generado con diseño contable y listo para compartir o almacenar.',
                  style: MangaFonts.sans(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MangaColors.ticketFooterBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARCHIVO:',
                        style: MangaFonts.sans(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        result.fileName,
                        style: MangaFonts.sans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UBICACIÓN: ${result.filePath}',
                        style: MangaFonts.sans(
                          fontSize: 10.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              MangaPressButton(
                onTap: () => Navigator.of(ctx).pop(),
                height: 40,
                backgroundColor: Colors.white,
                borderWidth: 2,
                borderRadius: 8,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'CERRAR',
                  style: MangaFonts.comic(fontSize: 16),
                ),
              ),
              MangaPressButton(
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await CierreExcelReportService.shareOrSaveExcelReport(
                    filePath: result.filePath,
                    bytes: result.bytes,
                    fileName: result.fileName,
                  );
                },
                height: 40,
                backgroundColor: MangaColors.primaryOrange,
                hoverColor: MangaColors.primaryOrangeHover,
                borderWidth: 2,
                borderRadius: 8,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'COMPARTIR / GUARDAR',
                      style: MangaFonts.comic(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al generar el reporte Excel: $e',
            style: MangaFonts.comic(fontSize: 15, color: Colors.white),
          ),
          backgroundColor: MangaColors.dangerRed,
        ),
      );
    }
  }
}

// ==================== SETTINGS, BACKUP & DANGER ZONE VIEW ====================

class ServerSettingsView extends StatefulWidget {
  final PosController controller;

  const ServerSettingsView({
    super.key,
    required this.controller,
  });

  @override
  State<ServerSettingsView> createState() => _ServerSettingsViewState();
}

class _ServerSettingsViewState extends State<ServerSettingsView> {
  late TextEditingController _portCtrl;

  @override
  void initState() {
    super.initState();
    _portCtrl = TextEditingController(
        text: widget.controller.configuredPort.toString());
  }

  @override
  void dispose() {
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ips = widget.controller.localIps.join('  ·  ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. RESPALDO COMPLETO DEL SISTEMA (PRODUCTOS, FOTOS Y TICKETS)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: MangaColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 3.5),
              boxShadow: MangaShadows.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: MangaColors.primaryOrange,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Text(
                        'RESPALDO',
                        style:
                            MangaFonts.comic(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'RESPALDO COMPLETO DEL SISTEMA (PRODUCTOS, IMÁGENES Y TICKETS)',
                        style: MangaFonts.comic(fontSize: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Exporta o importa un archivo .json completo que incluye todos los Dogos, Papas, Combos, fotografías locales y el historial de ventas por si tu dispositivo se pierde o daña.',
                  style: MangaFonts.sans(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    MangaPressButton(
                      onTap: () => _handleExportBackup(context),
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      backgroundColor: MangaColors.accentYellow,
                      shadow: MangaShadows.md,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.upload_file_rounded,
                              size: 20, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            '📤 EXPORTAR RESPALDO COMPLETO (.JSON)',
                            style: MangaFonts.comic(
                                fontSize: 17, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    MangaPressButton(
                      onTap: () => _showImportOptionsDialog(context),
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      backgroundColor: MangaColors.accentCyan,
                      hoverColor: MangaColors.accentCyanDark,
                      shadow: MangaShadows.md,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded,
                              size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            '📥 IMPORTAR RESPALDO COMPLETO (.JSON)',
                            style: MangaFonts.comic(
                                fontSize: 17, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. LAN SERVER STATUS & MODE SWITCH
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: MangaColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: MangaShadows.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.controller.lanService.isServerRunning
                                ? MangaColors.accentMint
                                : MangaColors.dangerSoftRed,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Text(
                            widget.controller.lanService.isServerRunning
                                ? '🟢 SERVIDOR ACTIVO'
                                : '🔴 SERVIDOR INACTIVO',
                            style: MangaFonts.comic(fontSize: 17),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'RED LOCAL (CONEXIÓN CON CELULARES CLIENTE)',
                          style: MangaFonts.comic(fontSize: 22),
                        ),
                      ],
                    ),
                    MangaPressButton(
                      onTap: () => widget.controller.returnToModeSelection(),
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: MangaColors.primaryOrange,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_horiz_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'CAMBIAR MODO (SERVIDOR / CLIENTE)',
                            style: MangaFonts.comic(
                                fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MangaColors.ticketFooterBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IP LOCAL DE ESTE SERVIDOR PARA CONECTAR LOS CLIENTES:',
                        style: MangaFonts.sans(
                            fontSize: 10.5, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$ips   (Puerto: ${widget.controller.lanService.serverPort})',
                        style: MangaFonts.comic(
                            fontSize: 26, color: MangaColors.primaryOrange),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Celulares Cliente conectados ahora: ${widget.controller.lanService.connectedClientsCount} ${widget.controller.lanService.connectedClientIps.isNotEmpty ? "(${widget.controller.lanService.connectedClientIps.join(", ")})" : ""}',
                        style: MangaFonts.sans(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _portCtrl,
                        keyboardType: TextInputType.number,
                        style: MangaFonts.sans(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Puerto LAN',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    MangaPressButton(
                      onTap: () async {
                        await widget.controller.updateTerminalSettings(
                          port: int.tryParse(_portCtrl.text.trim()),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.black,
                              content: Text(
                                '✅ Puerto de red actualizado.',
                                style: MangaFonts.sans(color: Colors.white),
                              ),
                            ),
                          );
                        }
                      },
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: MangaColors.accentYellow,
                      child: Center(
                        child: Text(
                          'ACTUALIZAR PUERTO',
                          style: MangaFonts.comic(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. ZONA DE RESTABLECIMIENTO DEL SISTEMA (EXCLUSIVAMENTE EN AJUSTES)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MangaColors.dangerRed, width: 3.5),
              boxShadow: MangaShadows.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: MangaColors.dangerRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PELIGRO',
                        style:
                            MangaFonts.comic(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'ZONA DE RESTABLECIMIENTO Y REINICIO DEL SISTEMA',
                      style: MangaFonts.comic(
                        fontSize: 22,
                        color: MangaColors.dangerRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Opciones para restablecer o reiniciar datos de la aplicación. Usa estas opciones con precaución.',
                  style: MangaFonts.sans(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    // A. Reiniciar Folio de Órdenes a #1
                    MangaPressButton(
                      onTap: () => _showResetOrderNumberDialog(context),
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: MangaColors.accentYellow,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restart_alt_rounded,
                              size: 18, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            'REINICIAR ÓRDENES A LA #1',
                            style: MangaFonts.comic(
                                fontSize: 16, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    // B. Borrar Todos los Tickets con Doble Advertencia
                    MangaPressButton(
                      onTap: () => _showDoubleWarningResetOrdersDialog(context),
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: MangaColors.dangerSoftRed,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete_forever_rounded,
                              size: 18, color: MangaColors.dangerRed),
                          const SizedBox(width: 6),
                          Text(
                            'BORRAR TODOS LOS TICKETS (DOBLE ADVERTENCIA)',
                            style: MangaFonts.comic(
                                fontSize: 16, color: MangaColors.dangerRed),
                          ),
                        ],
                      ),
                    ),
                    // C. Opciones de Productos (Desde cero o restaurar iniciales)
                    MangaPressButton(
                      onTap: () => _showResetProductsOptionsDialog(context),
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.white,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_rounded,
                              size: 18, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            'RESTABLECER CATÁLOGO PRODUCTOS',
                            style: MangaFonts.comic(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportBackup(BuildContext context) async {
    final savedPath = await widget.controller.exportCatalogBackup();
    if (!context.mounted) return;
    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            '✅ Respaldo completo exportado con éxito (incluye productos, fotos y tickets): $savedPath',
            style: MangaFonts.sans(color: Colors.white, fontSize: 12.5),
          ),
        ),
      );
    }
  }

  Future<void> _showImportOptionsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MangaColors.surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 3.5),
              boxShadow: MangaShadows.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📥 IMPORTAR RESPALDO COMPLETO',
                  style: MangaFonts.comic(fontSize: 25),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona tu archivo .json de respaldo. Se restaurarán los Dogos, Papas, Combos, fotografías locales y el historial de tickets guardados.',
                  style: MangaFonts.sans(fontSize: 12.5, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                MangaPressButton(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final res = await widget.controller
                        .importCatalogBackup(replaceExisting: false);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor:
                            res.success ? Colors.black : MangaColors.dangerRed,
                        content: Text(
                          res.message,
                          style: MangaFonts.sans(
                              color: Colors.white, fontSize: 12.5),
                        ),
                      ),
                    );
                  },
                  height: 46,
                  width: double.infinity,
                  backgroundColor: MangaColors.accentMint,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child: Text(
                      'COMBINAR CON DATOS ACTUALES',
                      style: MangaFonts.comic(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                MangaPressButton(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final res = await widget.controller
                        .importCatalogBackup(replaceExisting: true);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor:
                            res.success ? Colors.black : MangaColors.dangerRed,
                        content: Text(
                          res.message,
                          style: MangaFonts.sans(
                              color: Colors.white, fontSize: 12.5),
                        ),
                      ),
                    );
                  },
                  height: 46,
                  width: double.infinity,
                  backgroundColor: MangaColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child: Text(
                      'REEMPLAZAR TODOS LOS DATOS ACTUALES',
                      style:
                          MangaFonts.comic(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(),
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: Text('CANCELAR',
                          style: MangaFonts.comic(fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Double Warning Dialog for Clearing All Tickets
  Future<void> _showDoubleWarningResetOrdersDialog(
      BuildContext context) async {
    // Warning 1
    final step1Confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: MangaColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: MangaShadows.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MangaColors.accentYellow,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'ADVERTENCIA 1 DE 2',
                  style: MangaFonts.comic(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '¿DESEAS BORRAR TODOS LOS TICKETS Y VENTAS?',
                style: MangaFonts.comic(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta acción eliminará el historial de todas las órdenes registradas hasta el momento y los reportes de ventas se reiniciarán a cero.',
                style: MangaFonts.sans(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(false),
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: Text('CANCELAR',
                          style: MangaFonts.comic(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(true),
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: MangaColors.primaryOrange,
                    child: Center(
                      child: Text(
                        'CONTINUAR AL PASO FINAL ➔',
                        style: MangaFonts.comic(
                            fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (step1Confirmed != true || !context.mounted) return;

    // Warning 2 (Definitive confirmation)
    final step2Confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MangaColors.dangerRed, width: 4),
            boxShadow: MangaShadows.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MangaColors.dangerRed,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '🛑 ADVERTENCIA DEFINITIVA (PASO 2 DE 2)',
                  style: MangaFonts.comic(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '¡ESTA ACCIÓN NO SE PUEDE DESHACER!',
                style: MangaFonts.comic(
                  fontSize: 24,
                  color: MangaColors.dangerRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se borrarán de forma definitiva todos los tickets (${widget.controller.orders.length} órdenes) y se perderá el acumulado de ventas. ¿Confirmas borrar definitivamente?',
                style: MangaFonts.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(false),
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: Text('NO, CANCELAR',
                          style: MangaFonts.comic(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(true),
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    backgroundColor: MangaColors.dangerRed,
                    child: Center(
                      child: Text(
                        'SÍ, BORRAR DEFINITIVAMENTE',
                        style: MangaFonts.comic(
                            fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (step2Confirmed == true) {
      await widget.controller.resetAllOrdersAndSales();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            content: Text(
              '🗑️ Historial de tickets y ventas borrado por completo.',
              style: MangaFonts.sans(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showResetOrderNumberDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MangaColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: MangaShadows.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REINICIAR ÓRDENES A LA #1',
                style: MangaFonts.comic(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'El próximo pedido que se cobre tendrá el folio #1 y aumentará correlativamente (#1, #2, #3...).',
                style: MangaFonts.sans(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(false),
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: Text('CANCELAR',
                          style: MangaFonts.comic(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(true),
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: MangaColors.primaryOrange,
                    child: Center(
                      child: Text(
                        'REINICIAR A #1',
                        style: MangaFonts.comic(
                            fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await widget.controller.resetOrderNumber(1);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            content: Text(
              '✅ Folio de órdenes reiniciado a la orden #1.',
              style: MangaFonts.sans(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showResetProductsOptionsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MangaColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: MangaShadows.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RESTABLECER CATÁLOGO PRODUCTOS',
                  style: MangaFonts.comic(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                '¿Deseas vaciar todos los productos para crear tu propio menú desde cero, o restaurar los Dogos de demostración?',
                style: MangaFonts.sans(fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              MangaPressButton(
                onTap: () async {
                  await widget.controller.clearAllProducts();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                height: 44,
                width: double.infinity,
                backgroundColor: MangaColors.dangerSoftRed,
                child: Center(
                  child: Text(
                    '🗑️ VACIAR TODO (EMPEZAR DESDE CERO)',
                    style: MangaFonts.comic(
                        fontSize: 17, color: MangaColors.dangerRed),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              MangaPressButton(
                onTap: () async {
                  await widget.controller.restoreDefaultCatalog();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                height: 44,
                width: double.infinity,
                backgroundColor: MangaColors.accentYellow,
                child: Center(
                  child: Text(
                    '🌭 RESTAURAR DOGOS DEMO INICIALES',
                    style: MangaFonts.comic(fontSize: 17, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: MangaPressButton(
                  onTap: () => Navigator.of(ctx).pop(),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child:
                        Text('CERRAR', style: MangaFonts.comic(fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
