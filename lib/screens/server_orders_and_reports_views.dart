import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_models.dart';
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
                      'Total de órdenes registradas: ${orders.length} · Clientes conectados: ${controller.lanService.connectedClientsCount}',
                      style: MangaFonts.sans(
                          fontSize: 11.5, color: Colors.black87),
                    ),
                  ],
                ),
                Row(
                  children: [
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
                    if (orders.any((o) =>
                        o.status == OrderStatus.completed ||
                        o.status == OrderStatus.cancelled)) ...[
                      const SizedBox(width: 8),
                      MangaPressButton(
                        onTap: () => controller.clearCompletedOrdersHistory(),
                        height: isCompactHeight ? 36 : 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: MangaColors.dangerSoftRed,
                        child: Center(
                          child: Text(
                            'LIMPIAR ENTREGADAS',
                            style: MangaFonts.comic(
                              fontSize: isCompactHeight ? 14 : 16,
                              color: MangaColors.dangerRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
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
                                MangaPressButton(
                                  onTap: () {
                                    controller.lanService
                                        .broadcastNewOrder(order);
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                  child: Center(
                                    child: Text(
                                      'RE-ENVIAR A CLIENTE',
                                      style: MangaFonts.comic(
                                          fontSize: 12, color: Colors.white),
                                    ),
                                  ),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
}

// ==================== SETTINGS, BACKUP IMPORT/EXPORT & LAN VIEW ====================

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
          // 1. IMPORTAR / EXPORTAR PRODUCTOS (EXCLUSIVAMENTE EN AJUSTES)
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
                        'IMPORTAR / EXPORTAR CATÁLOGO DE PRODUCTOS (CON IMÁGENES LOCALES)',
                        style: MangaFonts.comic(fontSize: 23),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Guarda una copia de seguridad (.json) de todos tus Dogos, Papas y Combos junto con sus fotografías locales por si tu dispositivo se daña o cambia.',
                  style: MangaFonts.sans(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    MangaPressButton(
                      onTap: () => _handleExportBackup(context),
                      height: 46,
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
                            '📤 EXPORTAR PRODUCTOS (.JSON)',
                            style: MangaFonts.comic(
                                fontSize: 18, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    MangaPressButton(
                      onTap: () => _showImportOptionsDialog(context),
                      height: 46,
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
                            '📥 IMPORTAR PRODUCTOS (.JSON)',
                            style: MangaFonts.comic(
                                fontSize: 18, color: Colors.white),
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
            '✅ Catálogo exportado con éxito (incluye imágenes locales): $savedPath',
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
            width: 440,
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
                  '📥 IMPORTAR RESPALDO DE PRODUCTOS',
                  style: MangaFonts.comic(fontSize: 25),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona tu archivo .json de respaldo. Se restaurarán los Dogos, Papas y Combos junto con sus imágenes locales.',
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
                      'COMBINAR CON PRODUCTOS ACTUALES',
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
                      'REEMPLAZAR TODO EL CATÁLOGO ACTUAL',
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
}
