import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_models.dart';
import '../theme/manga_theme.dart';
import '../widgets/manga_widgets.dart';

class ClientKitchenScreen extends StatefulWidget {
  final PosController controller;

  const ClientKitchenScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ClientKitchenScreen> createState() => _ClientKitchenScreenState();
}

class _ClientKitchenScreenState extends State<ClientKitchenScreen> {
  String _selectedFilter = 'active';
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  List<PosOrder> get _filteredOrders {
    final all = widget.controller.orders;
    switch (_selectedFilter) {
      case 'pending':
        return all.where((o) => o.status == OrderStatus.pending).toList();
      case 'preparing':
        return all.where((o) => o.status == OrderStatus.preparing).toList();
      case 'ready':
        return all.where((o) => o.status == OrderStatus.ready).toList();
      case 'completed':
        return all.where((o) => o.status == OrderStatus.completed).toList();
      case 'active':
      default:
        return all
            .where((o) =>
                o.status == OrderStatus.pending ||
                o.status == OrderStatus.preparing ||
                o.status == OrderStatus.ready)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.controller.lanService.isClientConnected;
    final serverIp = widget.controller.lanService.connectedServerIp ??
        widget.controller.lastServerIp;
    final alertOrder = widget.controller.latestIncomingOrderAlert;

    final allOrders = widget.controller.orders;
    final pendingCount =
        allOrders.where((o) => o.status == OrderStatus.pending).length;
    final preparingCount =
        allOrders.where((o) => o.status == OrderStatus.preparing).length;
    final readyCount =
        allOrders.where((o) => o.status == OrderStatus.ready).length;
    final activeCount = pendingCount + preparingCount + readyCount;

    final ordersToShow = _filteredOrders;

    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ==================== MOBILE PORTRAIT TOP HEADER ====================
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: MangaColors.surfaceWhite,
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 3.5),
                  ),
                  boxShadow: MangaShadows.md,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Only "Dogos El Pa" + Cliente tag
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DOGOS EL PA',
                              style: MangaFonts.comic(
                                fontSize: 28,
                                color: Colors.black,
                                shadows: const [
                                  Shadow(
                                    color: MangaColors.primaryOrange,
                                    offset: Offset(1.5, 1.5),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: MangaColors.accentYellow,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: Colors.black, width: 1.2),
                              ),
                              child: Text(
                                'MODO CLIENTE · ÓRDENES EN VIVO',
                                style: MangaFonts.sans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Right: Connection Pill + Refresh + Mode Switch
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MangaPressButton(
                              onTap: () => _showConnectServerDialog(context),
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              backgroundColor: isConnected
                                  ? MangaColors.accentMint
                                  : MangaColors.dangerSoftRed,
                              borderRadius: 10,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isConnected
                                        ? Icons.wifi_rounded
                                        : Icons.wifi_off_rounded,
                                    size: 16,
                                    color: isConnected
                                        ? MangaColors.successGreen
                                        : MangaColors.dangerRed,
                                  ),
                                  const SizedBox(width: 5),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isConnected
                                            ? 'CONECTADO'
                                            : (widget.controller.isScanningLan
                                                ? 'BUSCANDO...'
                                                : 'CONECTAR IP'),
                                        style: MangaFonts.sans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        serverIp,
                                        style: MangaFonts.sans(
                                          fontSize: 8.5,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            MangaPressButton(
                              onTap: () => widget.controller.lanService
                                  .requestSyncFromServer(),
                              width: 38,
                              height: 38,
                              borderRadius: 10,
                              backgroundColor: Colors.white,
                              tooltip: 'Actualizar órdenes',
                              child: const Icon(Icons.refresh_rounded,
                                  size: 19, color: Colors.black),
                            ),
                            const SizedBox(width: 6),
                            MangaPressButton(
                              onTap: () =>
                                  widget.controller.returnToModeSelection(),
                              width: 38,
                              height: 38,
                              borderRadius: 10,
                              backgroundColor: MangaColors.primaryOrange,
                              tooltip: 'Cambiar Modo',
                              child: const Icon(Icons.swap_horiz_rounded,
                                  size: 19, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ==================== INCOMING NEW ORDER MOBILE ALERT ====================
              if (alertOrder != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MangaColors.primaryOrange,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: MangaColors.accentYellow,
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: Colors.black, width: 2),
                            ),
                            child: Text(
                              '💥 ¡NUEVA ORDEN #${alertOrder.orderNumber}!',
                              style: MangaFonts.comic(
                                  fontSize: 19, color: Colors.black),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                widget.controller.dismissIncomingOrderAlert(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.black, width: 1.5),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${alertOrder.orderType.label} · ${alertOrder.customerName}: '
                        '${alertOrder.items.map((i) => "${i.quantity}x ${i.name}").join(", ")}',
                        style: MangaFonts.sans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MangaPressButton(
                        onTap: () {
                          widget.controller.updateOrderStatus(
                            alertOrder.id,
                            OrderStatus.preparing,
                          );
                        },
                        height: 38,
                        width: double.infinity,
                        backgroundColor: MangaColors.accentYellow,
                        child: Center(
                          child: Text(
                            '🔥 EMPEZAR A PREPARAR AHORA',
                            style: MangaFonts.comic(
                                fontSize: 17, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ==================== MOBILE STATUS FILTER PILLS ====================
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterTab(
                        id: 'active',
                        label: '🔥 EN CURSO',
                        count: activeCount,
                        activeColor: MangaColors.primaryOrange,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        id: 'pending',
                        label: '🆕 NUEVAS',
                        count: pendingCount,
                        activeColor: MangaColors.primaryOrange,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        id: 'preparing',
                        label: '🍳 PREPARANDO',
                        count: preparingCount,
                        activeColor: MangaColors.accentYellow,
                        darkTextOnActive: true,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        id: 'ready',
                        label: '✅ LISTAS',
                        count: readyCount,
                        activeColor: MangaColors.accentMint,
                        darkTextOnActive: true,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        id: 'completed',
                        label: '🏁 ENTREGADAS',
                        count: allOrders
                            .where((o) => o.status == OrderStatus.completed)
                            .length,
                        activeColor: MangaColors.accentCyan,
                      ),
                    ],
                  ),
                ),
              ),

              // ==================== VERTICAL MOBILE ORDERS LIST ====================
              Expanded(
                child: ordersToShow.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: Colors.black, width: 3),
                              boxShadow: MangaShadows.lg,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: MangaColors.accentYellow,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.black, width: 2.5),
                                    boxShadow: MangaShadows.sm,
                                  ),
                                  child: const Icon(
                                    Icons.lunch_dining_rounded,
                                    size: 34,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ESPERANDO ÓRDENES DEL SERVIDOR...',
                                  textAlign: TextAlign.center,
                                  style: MangaFonts.comic(fontSize: 24),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cuando el Servidor genere una venta de Dogos, Papas o Combos, aparecerá inmediatamente aquí para empezar a preparar.',
                                  textAlign: TextAlign.center,
                                  style: MangaFonts.sans(
                                    fontSize: 12.5,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (!isConnected) ...[
                                  const SizedBox(height: 16),
                                  MangaPressButton(
                                    onTap: () =>
                                        _showConnectServerDialog(context),
                                    height: 44,
                                    width: double.infinity,
                                    backgroundColor: MangaColors.accentCyan,
                                    child: Center(
                                      child: Text(
                                        '📡 CONECTAR AL SERVIDOR EN LA RED',
                                        style: MangaFonts.comic(
                                            fontSize: 17, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                        itemCount: ordersToShow.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final order = ordersToShow[index];
                          return _buildMobileOrderCard(context, order);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String id,
    required String label,
    required int count,
    required Color activeColor,
    bool darkTextOnActive = false,
  }) {
    final isSelected = _selectedFilter == id;
    final textColor = isSelected
        ? (darkTextOnActive ? Colors.black : Colors.white)
        : Colors.black;

    return MangaPressButton(
      onTap: () => setState(() => _selectedFilter = id),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      borderRadius: 10,
      backgroundColor: isSelected ? activeColor : Colors.white,
      shadow: isSelected ? MangaShadows.md : MangaShadows.sm,
      child: Row(
        children: [
          Text(
            label,
            style: MangaFonts.comic(fontSize: 16, color: textColor),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '$count',
              style: MangaFonts.sans(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: MangaColors.accentYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width vertical card optimized for mobile phones in portrait mode
  Widget _buildMobileOrderCard(BuildContext context, PosOrder order) {
    final Color headerBg;
    final Color headerText;
    switch (order.status) {
      case OrderStatus.pending:
        headerBg = MangaColors.primaryOrange;
        headerText = Colors.white;
        break;
      case OrderStatus.preparing:
        headerBg = MangaColors.accentYellow;
        headerText = Colors.black;
        break;
      case OrderStatus.ready:
        headerBg = MangaColors.accentMint;
        headerText = Colors.black;
        break;
      default:
        headerBg = MangaColors.badgeSoftBlue;
        headerText = Colors.black;
    }

    final timeStr = DateFormat('HH:mm').format(order.createdAt);
    final elapsedMins =
        DateTime.now().difference(order.createdAt).inMinutes;
    final preparedCount = order.items.where((i) => i.isPrepared).length;

    return Container(
      decoration: BoxDecoration(
        color: MangaColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: MangaShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Order Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              border: const Border(
                bottom: BorderSide(color: Colors.black, width: 2.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '#${order.orderNumber}',
                          style: MangaFonts.comic(
                            fontSize: 24,
                            color: MangaColors.accentYellow,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderType.label,
                              style: MangaFonts.comic(
                                fontSize: 19,
                                color: headerText,
                              ),
                            ),
                            Text(
                              'CLIENTE: ${order.customerName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MangaFonts.sans(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: headerText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1.8),
                      ),
                      child: Text(
                        order.status.label,
                        style:
                            MangaFonts.comic(fontSize: 14, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '⏱️ $timeStr (${elapsedMins == 0 ? "Ahora" : "${elapsedMins}m"})',
                      style: MangaFonts.sans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: headerText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: const BoxDecoration(
              color: MangaColors.ticketFooterBg,
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOCA CADA PRODUCTO AL PREPARARLO',
                  style: MangaFonts.sans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$preparedCount / ${order.items.length} LISTOS',
                  style: MangaFonts.sans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: MangaColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          // 3. Items List (Auto-sizing for mobile vertical scroll)
          Container(
            color: MangaColors.ticketListBg,
            padding: const EdgeInsets.all(10),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => widget.controller
                        .toggleOrderItemPrepared(order.id, item.id),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.isPrepared
                            ? const Color(0xFFE6FAEE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: MangaShadows.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: item.isPrepared
                                  ? MangaColors.accentMint
                                  : MangaColors.accentYellow,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.black, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}x',
                              style: MangaFonts.comic(fontSize: 21),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: MangaFonts.comic(
                                    fontSize: 19,
                                    color: item.isPrepared
                                        ? Colors.black54
                                        : Colors.black,
                                  ),
                                ),
                                if (item.notes.isNotEmpty)
                                  Text(
                                    '📝 ${item.notes}',
                                    style: MangaFonts.sans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: item.isPrepared
                                          ? Colors.black45
                                          : MangaColors.primaryOrange,
                                      decoration: item.isPrepared
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            item.isPrepared
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 28,
                            color: item.isPrepared
                                ? MangaColors.successGreen
                                : Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 4. Bottom Action Button
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: MangaColors.surfaceWhite,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(13)),
              border: Border(
                top: BorderSide(color: Colors.black, width: 2.5),
              ),
            ),
            child: _buildOrderActionFooter(order),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActionFooter(PosOrder order) {
    if (order.status == OrderStatus.pending) {
      return MangaPressButton(
        onTap: () => widget.controller
            .updateOrderStatus(order.id, OrderStatus.preparing),
        height: 48,
        width: double.infinity,
        backgroundColor: MangaColors.primaryOrange,
        hoverColor: MangaColors.primaryOrangeHover,
        shadow: MangaShadows.md,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              '¡EMPEZAR A PREPARAR!',
              style: MangaFonts.comic(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      );
    } else if (order.status == OrderStatus.preparing) {
      return MangaPressButton(
        onTap: () =>
            widget.controller.updateOrderStatus(order.id, OrderStatus.ready),
        height: 48,
        width: double.infinity,
        backgroundColor: MangaColors.accentYellow,
        shadow: MangaShadows.md,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: Colors.black, size: 22),
            const SizedBox(width: 8),
            Text(
              '✅ ¡ORDEN LISTA PARA ENTREGAR!',
              style: MangaFonts.comic(fontSize: 20, color: Colors.black),
            ),
          ],
        ),
      );
    } else if (order.status == OrderStatus.ready) {
      return MangaPressButton(
        onTap: () => widget.controller
            .updateOrderStatus(order.id, OrderStatus.completed),
        height: 48,
        width: double.infinity,
        backgroundColor: MangaColors.accentMint,
        shadow: MangaShadows.md,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.black, size: 22),
            const SizedBox(width: 8),
            Text(
              '🏁 MARCAR COMO ENTREGADA',
              style: MangaFonts.comic(fontSize: 20, color: Colors.black),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: MangaColors.badgeSoftBlue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          '✔️ ORDEN ENTREGADA',
          style: MangaFonts.comic(fontSize: 18),
        ),
      );
    }
  }

  Future<void> _showConnectServerDialog(BuildContext context) async {
    final ipCtrl =
        TextEditingController(text: widget.controller.lastServerIp);
    final portCtrl = TextEditingController(
        text: widget.controller.configuredPort.toString());

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: MangaColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black, width: 3.5),
                  boxShadow: MangaShadows.xl,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📡 CONECTAR AL SERVIDOR POS',
                        style: MangaFonts.comic(fontSize: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ingresa la IP local que muestra el dispositivo Servidor (ej. 192.168.1.50):',
                        style: MangaFonts.sans(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: ipCtrl,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'IP del Servidor',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: portCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Puerto',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      MangaPressButton(
                        onTap: () async {
                          await widget.controller.scanForServersOnLan();
                          if (widget.controller.discoveredServers.isNotEmpty) {
                            ipCtrl.text =
                                widget.controller.discoveredServers.first.ip;
                          }
                          setModalState(() {});
                        },
                        height: 40,
                        width: double.infinity,
                        backgroundColor: MangaColors.accentYellow,
                        child: Center(
                          child: Text(
                            widget.controller.isScanningLan
                                ? '🔍 BUSCANDO EN LA RED...'
                                : '🔍 AUTO-DETECTAR SERVIDOR EN WI-FI',
                            style: MangaFonts.comic(fontSize: 16),
                          ),
                        ),
                      ),

                      if (widget.controller.discoveredServers.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'SERVIDOR ENCONTRADO:',
                          style: MangaFonts.sans(
                              fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        ...widget.controller.discoveredServers.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: MangaPressButton(
                              onTap: () async {
                                await widget.controller.connectClientToServer(
                                  s.ip,
                                  port: s.port,
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              },
                              height: 38,
                              width: double.infinity,
                              backgroundColor: MangaColors.accentMint,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${s.name} (${s.ip})',
                                      overflow: TextOverflow.ellipsis,
                                      style: MangaFonts.sans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  Text(
                                    'CONECTAR ➔',
                                    style: MangaFonts.comic(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MangaPressButton(
                            onTap: () => Navigator.of(ctx).pop(),
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              child: Text('CERRAR',
                                  style: MangaFonts.comic(fontSize: 15)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          MangaPressButton(
                            onTap: () async {
                              final ip = ipCtrl.text.trim();
                              final port = int.tryParse(portCtrl.text.trim()) ??
                                  widget.controller.configuredPort;
                              if (ip.isNotEmpty) {
                                await widget.controller
                                    .connectClientToServer(ip, port: port);
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              }
                            },
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            backgroundColor: MangaColors.accentCyan,
                            child: Center(
                              child: Text(
                                '⚡ CONECTAR',
                                style: MangaFonts.comic(
                                    fontSize: 17, color: Colors.white),
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
          },
        );
      },
    );
  }
}
