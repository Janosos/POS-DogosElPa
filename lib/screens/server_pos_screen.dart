import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_models.dart';
import '../theme/manga_theme.dart';
import '../widgets/manga_widgets.dart';
import 'product_management_view.dart';
import 'server_orders_and_reports_views.dart';

class ServerPosScreen extends StatefulWidget {
  final PosController controller;

  const ServerPosScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ServerPosScreen> createState() => _ServerPosScreenState();
}

class _ServerPosScreenState extends State<ServerPosScreen> {
  late TextEditingController _searchController;
  Timer? _clockTimer;
  String _currentTimeStr = '';

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.controller.searchQuery);
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updateClock();
    });
  }

  void _updateClock() {
    final nowStr = DateFormat('HH:mm').format(DateTime.now());
    if (mounted && nowStr != _currentTimeStr) {
      setState(() {
        _currentTimeStr = nowStr;
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ==================== TOP HEADER (RESPONSIVE LANDSCAPE) ====================
              _buildTopHeader(context),

              // ==================== MAIN BODY (SIDEBAR + CONTENT) ====================
              Expanded(
                child: Row(
                  children: [
                    _buildLeftSidebar(context),
                    Expanded(
                      child: _buildSelectedSection(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompactHeight = size.height < 500;
    final showQuickHeaderButtons = size.width > 820;
    final connectedCount = widget.controller.lanService.connectedClientsCount;

    return Container(
      height: isCompactHeight ? 56 : 70,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: MangaColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 3.5),
        ),
        boxShadow: MangaShadows.md,
      ),
      child: Row(
        children: [
          // Top-Left: Only "Dogos El Pa" as requested
          Text(
            'DOGOS EL PA',
            style: MangaFonts.comic(
              fontSize: isCompactHeight ? 26 : 32,
              color: Colors.black,
              shadows: const [
                Shadow(
                  color: MangaColors.primaryOrange,
                  offset: Offset(1.5, 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Center Search Input (without barcode/SKU reference)
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  height: isCompactHeight ? 38 : 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: MangaShadows.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      widget.controller.setSearchQuery(val);
                      if (widget.controller.serverNavIndex != 0) {
                        widget.controller.setServerNavIndex(0);
                      }
                    },
                    style: MangaFonts.sans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar Dogo, Papas o Combo...',
                      hintStyle: MangaFonts.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _searchController.clear();
                                widget.controller.setSearchQuery('');
                              },
                              icon: const Icon(Icons.clear_rounded,
                                  size: 16, color: Colors.black),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Quick Header Buttons (Descuentos, Cajón - without Importar/Exportar)
          if (showQuickHeaderButtons) ...[
            MangaPressButton(
              onTap: () => _showDiscountDialog(context),
              height: isCompactHeight ? 36 : 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              backgroundColor: Colors.white,
              hoverColor: const Color(0xFFFFF0EB),
              child: Row(
                children: [
                  const Icon(Icons.percent_rounded,
                      size: 16, color: MangaColors.primaryOrange),
                  const SizedBox(width: 4),
                  Text(
                    'DESCUENTOS',
                    style: MangaFonts.sans(
                        fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MangaPressButton(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.black,
                    content: Text(
                      '🔓 ¡Cajón de dinero abierto!',
                      style: MangaFonts.sans(color: Colors.white),
                    ),
                  ),
                );
              },
              height: isCompactHeight ? 36 : 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              backgroundColor: MangaColors.accentMint,
              hoverColor: MangaColors.accentMintDark,
              child: Row(
                children: [
                  const Icon(Icons.lock_open_rounded,
                      size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    'CAJÓN',
                    style: MangaFonts.sans(
                        fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Container(
              height: 26,
              width: 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.black,
            ),
          ],

          // LAN Wi-Fi Status + Connected Clients + Clock
          MangaPressButton(
            onTap: () => _showLanInfoPopup(context),
            height: isCompactHeight ? 36 : 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            backgroundColor: Colors.white,
            tooltip:
                'Servidor LAN Activo (${widget.controller.localIps.first}:${widget.controller.lanService.serverPort})',
            child: Row(
              children: [
                Icon(
                  Icons.wifi_rounded,
                  size: 18,
                  color: widget.controller.lanService.isServerRunning
                      ? MangaColors.successGreen
                      : MangaColors.dangerRed,
                ),
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: connectedCount > 0
                        ? MangaColors.accentMint
                        : MangaColors.accentYellow,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    '$connectedCount CLIENTE(S)',
                    style: MangaFonts.sans(
                        fontSize: 9.5, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _currentTimeStr,
                  style: MangaFonts.sans(
                      fontSize: 11.5, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Switch Mode Button
          MangaPressButton(
            onTap: () => widget.controller.returnToModeSelection(),
            width: isCompactHeight ? 36 : 40,
            height: isCompactHeight ? 36 : 40,
            backgroundColor: MangaColors.primaryOrange,
            hoverColor: MangaColors.primaryOrangeHover,
            tooltip: 'Cambiar Modo (Servidor / Cliente)',
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LEFT SIDEBAR (WITHOUT MESAS, RESPONSIVE LANDSCAPE) ====================

  Widget _buildLeftSidebar(BuildContext context) {
    final currentIdx = widget.controller.serverNavIndex;
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 500;
    final itemHeight = isCompact ? 50.0 : 62.0;

    return Container(
      width: isCompact ? 82 : 92,
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 6 : 12,
        horizontal: 6,
      ),
      decoration: const BoxDecoration(
        color: MangaColors.surfaceWhite,
        border: Border(
          right: BorderSide(color: Colors.black, width: 3.5),
        ),
        boxShadow: MangaShadows.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        _buildSidebarItem(
                          index: 0,
                          currentIndex: currentIdx,
                          icon: Icons.grid_view_rounded,
                          label: 'VENTA',
                          height: itemHeight,
                          isCompact: isCompact,
                        ),
                        SizedBox(height: isCompact ? 6 : 10),
                        _buildSidebarItem(
                          index: 1,
                          currentIndex: currentIdx,
                          icon: Icons.inventory_2_rounded,
                          label: 'PRODUCTOS',
                          height: itemHeight,
                          isCompact: isCompact,
                        ),
                        SizedBox(height: isCompact ? 6 : 10),
                        _buildSidebarItem(
                          index: 2,
                          currentIndex: currentIdx,
                          icon: Icons.receipt_long_rounded,
                          label: 'TICKETS',
                          height: itemHeight,
                          isCompact: isCompact,
                        ),
                        SizedBox(height: isCompact ? 6 : 10),
                        _buildSidebarItem(
                          index: 3,
                          currentIndex: currentIdx,
                          icon: Icons.query_stats_rounded,
                          label: 'CIERRE',
                          height: itemHeight,
                          isCompact: isCompact,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _buildSidebarItem(
                        index: 4,
                        currentIndex: currentIdx,
                        icon: Icons.settings_rounded,
                        label: 'AJUSTES',
                        height: isCompact ? 46 : 54,
                        isCompact: isCompact,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    required double height,
    required bool isCompact,
  }) {
    final isSelected = index == currentIndex;
    return MangaPressButton(
      onTap: () => widget.controller.setServerNavIndex(index),
      width: double.infinity,
      height: height,
      borderRadius: 10,
      backgroundColor: isSelected ? MangaColors.primaryOrange : Colors.white,
      hoverColor: isSelected ? null : MangaColors.accentYellow,
      shadow: isSelected ? MangaShadows.md : MangaShadows.sm,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isCompact ? 20 : 24,
            color: isSelected ? Colors.white : Colors.black,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: MangaFonts.comic(
              fontSize: isCompact ? 13 : 15,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSection(BuildContext context) {
    switch (widget.controller.serverNavIndex) {
      case 1:
        return ProductManagementView(controller: widget.controller);
      case 2:
        return ServerTicketsHistoryView(controller: widget.controller);
      case 3:
        return ServerReportsView(controller: widget.controller);
      case 4:
        return ServerSettingsView(controller: widget.controller);
      case 0:
      default:
        return _buildPosSaleSplitView(context);
    }
  }

  // ==================== VENTA DUAL LAYOUT: 63% CATALOG / 37% TICKET (LANDSCAPE RESPONSIVE) ====================

  Widget _buildPosSaleSplitView(BuildContext context) {
    final isCompactHeight = MediaQuery.of(context).size.height < 500;
    return Padding(
      padding: EdgeInsets.all(isCompactHeight ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==================== LEFT COLUMN: 63% CATALOG ====================
          Expanded(
            flex: 62,
            child: _buildCatalogColumn(context, isCompactHeight),
          ),
          SizedBox(width: isCompactHeight ? 8 : 12),
          // ==================== RIGHT COLUMN: 37% MANGA TICKET ====================
          Expanded(
            flex: 38,
            child: _buildTicketColumn(context, isCompactHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogColumn(BuildContext context, bool isCompactHeight) {
    final products = widget.controller.filteredProducts;
    final totalAllCount = widget.controller.allProducts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Category Carousel Strips (Only TODOS, DOGOS, PAPAS, COMBOS)
        SizedBox(
          height: isCompactHeight ? 38 : 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.controller.categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final cat = widget.controller.categories[idx];
              final isSelected =
                  widget.controller.selectedCategoryId == cat.id;
              return MangaPressButton(
                onTap: () => widget.controller.selectCategory(cat.id),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                borderRadius: 10,
                backgroundColor:
                    isSelected ? MangaColors.primaryOrange : Colors.white,
                hoverColor: isSelected ? null : MangaColors.accentYellow,
                shadow: isSelected ? MangaShadows.md : MangaShadows.sm,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.emoji,
                        style: TextStyle(fontSize: isCompactHeight ? 15 : 17)),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: MangaFonts.comic(
                        fontSize: isCompactHeight ? 16 : 19,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    if (cat.id == 'todos') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          '$totalAllCount',
                          style: MangaFonts.sans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: MangaColors.accentYellow,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: isCompactHeight ? 6 : 10),

        // 2. Manga Quick Actions Banner (without ESCANEAR)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isCompactHeight ? 5 : 8,
          ),
          decoration: BoxDecoration(
            color: MangaColors.accentYellow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: MangaShadows.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '¡EN SERVICIO!',
                        style: MangaFonts.comic(
                            fontSize: isCompactHeight ? 13 : 15,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'MENÚ DOGOS EL PA · ENVÍO INSTANTÁNEO AL CLIENTE',
                        overflow: TextOverflow.ellipsis,
                        style: MangaFonts.sans(
                          fontSize: isCompactHeight ? 10.5 : 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MangaPressButton(
                    onTap: () => showProductEditorDialog(
                      context,
                      controller: widget.controller,
                    ),
                    height: isCompactHeight ? 30 : 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: MangaColors.primaryOrange,
                    hoverColor: MangaColors.primaryOrangeHover,
                    borderRadius: 8,
                    child: Row(
                      children: [
                        const Icon(Icons.add_photo_alternate_rounded,
                            size: 15, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '+ PRODUCTO',
                          style: MangaFonts.sans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  MangaPressButton(
                    onTap: () => _showFreeSaleDialog(context),
                    height: isCompactHeight ? 30 : 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: Colors.white,
                    hoverColor: MangaColors.softCream,
                    borderRadius: 8,
                    child: Row(
                      children: [
                        const Icon(Icons.dialpad_rounded,
                            size: 15, color: MangaColors.primaryOrange),
                        const SizedBox(width: 4),
                        Text(
                          'VENTA LIBRE',
                          style: MangaFonts.sans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
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
        SizedBox(height: isCompactHeight ? 6 : 10),

        // 3. Product Grid (Responsive columns for Landscape tablets & phones)
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: MangaShadows.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NO HAY PRODUCTOS EN ESTA CATEGORÍA',
                          style: MangaFonts.comic(fontSize: 22),
                        ),
                        const SizedBox(height: 8),
                        MangaPressButton(
                          onTap: () => showProductEditorDialog(
                            context,
                            controller: widget.controller,
                          ),
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: MangaColors.primaryOrange,
                          child: Center(
                            child: Text(
                              '+ CREAR PRODUCTO',
                              style: MangaFonts.comic(
                                  fontSize: 17, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 620
                        ? 3
                        : (constraints.maxWidth > 360 ? 2 : 1);
                    final cardExtent = isCompactHeight ? 186.0 : 215.0;
                    return GridView.builder(
                      padding:
                          const EdgeInsets.only(top: 6, bottom: 10, right: 2),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisExtent: cardExtent,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildMangaProductCard(
                          context,
                          product,
                          index: index,
                          isCompactHeight: isCompactHeight,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMangaProductCard(
    BuildContext context,
    Product product, {
    required int index,
    required bool isCompactHeight,
  }) {
    final badgeRotation = (index % 2 == 0) ? -0.045 : 0.035;
    final badgeBg = MangaColors.fromHex(product.badgeColorHex);
    final isLightBadge = product.badgeColorHex == '#85f8c4' ||
        product.badgeColorHex == '#ffcb11';

    return GestureDetector(
      onTap: () => widget.controller.addProductToTicket(product),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(isCompactHeight ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: MangaShadows.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Box
                Container(
                  height: isCompactHeight ? 84 : 106,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: MangaColors.cardImageBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImageDisplay(
                        localImagePath: product.localImagePath,
                        imageBase64: product.imageBase64,
                        imageUrl: product.imageUrl,
                        fallbackLabel: product.name,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => showProductEditorDialog(
                            context,
                            controller: widget.controller,
                            existingProduct: product,
                          ),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                // Product Title & Description
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MangaFonts.comic(
                    fontSize: isCompactHeight ? 17 : 19,
                    color: Colors.black,
                  ),
                ),
                Text(
                  product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MangaFonts.sans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF525252),
                  ),
                ),
                const Spacer(),
                const MangaDashedDivider(),
                const SizedBox(height: 5),

                // Price & Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: MangaColors.accentYellow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1.8),
                        boxShadow: MangaShadows.sm,
                      ),
                      child: Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: MangaFonts.comic(
                          fontSize: isCompactHeight ? 19 : 22,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                    ),
                    MangaPressButton(
                      onTap: () =>
                          widget.controller.addProductToTicket(product),
                      width: isCompactHeight ? 30 : 34,
                      height: isCompactHeight ? 30 : 34,
                      borderRadius: 8,
                      backgroundColor: MangaColors.primaryOrange,
                      hoverColor: MangaColors.primaryOrangeHover,
                      tooltip: 'Agregar al ticket',
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: isCompactHeight ? 18 : 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rotated Comic Top Badge
          if (product.badgeText != null &&
              product.badgeText!.trim().isNotEmpty)
            Positioned(
              top: -8,
              left: 8,
              child: Transform.rotate(
                angle: badgeRotation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.black, width: 1.8),
                    boxShadow: MangaShadows.sm,
                  ),
                  child: Text(
                    product.badgeText!,
                    style: MangaFonts.sans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isLightBadge ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== RIGHT COLUMN: TICKET MANGA CLIPBOARD (NO IVA, NO MESAS, LANDSCAPE RESPONSIVE) ====================

  Widget _buildTicketColumn(BuildContext context, bool isCompactHeight) {
    final items = widget.controller.ticketItems;
    final subtotal = widget.controller.ticketSubtotal;
    final discount = widget.controller.ticketDiscount;
    final grandTotal = widget.controller.ticketGrandTotal;
    final selectedCash = widget.controller.selectedCashTendered;

    return Container(
      decoration: BoxDecoration(
        color: MangaColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: MangaShadows.xl,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Ticket Header (Order Number + Customer Name + Order Type Switch)
          Container(
            padding: EdgeInsets.all(isCompactHeight ? 8 : 10),
            decoration: const BoxDecoration(
              color: MangaColors.accentYellow,
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showEditCustomerDialog(context),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(7),
                                border:
                                    Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: Text(
                                '#${widget.controller.nextOrderNumber}',
                                style: MangaFonts.comic(
                                  fontSize: isCompactHeight ? 19 : 22,
                                  color: MangaColors.accentYellow,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'CLIENTE: ${widget.controller.currentCustomerName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: MangaFonts.sans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_rounded,
                                      size: 13, color: Colors.black),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    MangaPressButton(
                      onTap: () => widget.controller.clearTicket(),
                      width: isCompactHeight ? 30 : 34,
                      height: isCompactHeight ? 30 : 34,
                      backgroundColor: Colors.white,
                      hoverColor: MangaColors.dangerSoftRed,
                      tooltip: 'Vaciar orden',
                      child: Icon(
                        Icons.delete_sweep_rounded,
                        size: isCompactHeight ? 17 : 19,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompactHeight ? 5 : 7),

                // Order Type Switch (COMER AQUÍ / LLEVAR / DELIVERY)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: OrderType.values.map((type) {
                      final isSelected =
                          widget.controller.currentOrderType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => widget.controller.setOrderType(type),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: isCompactHeight ? 3 : 5),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MangaColors.primaryOrange
                                  : const Color(0xFF262626),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              type.label,
                              style: MangaFonts.comic(
                                fontSize: isCompactHeight ? 13.5 : 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 2. Ticket Item List
          Expanded(
            child: Container(
              color: MangaColors.ticketListBg,
              child: items.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'TICKET VACÍO.\n¡SELECCIONA TUS DOGOS DEL MENÚ!',
                          textAlign: TextAlign.center,
                          style: MangaFonts.sans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(isCompactHeight ? 6 : 8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildTicketItemRow(
                            context, item, isCompactHeight);
                      },
                    ),
            ),
          ),

          // 3. Summary Totals & Checkout Footer (WITHOUT 16% IVA)
          Container(
            padding: EdgeInsets.all(isCompactHeight ? 8 : 10),
            decoration: const BoxDecoration(
              color: MangaColors.ticketFooterBg,
              border: Border(
                top: BorderSide(color: Colors.black, width: 3.5),
              ),
            ),
            child: Column(
              children: [
                // Subtotal & Discount Breakdown (No IVA)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SUBTOTAL (${widget.controller.ticketTotalItemsCount} ITEMS)',
                      style: MangaFonts.sans(
                          fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '\$${subtotal.toStringAsFixed(2)}',
                      style: MangaFonts.sans(
                          fontSize: 11.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.controller.discountLabel,
                        style: MangaFonts.sans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: MangaColors.successGreen,
                        ),
                      ),
                      Text(
                        '-\$${discount.toStringAsFixed(2)}',
                        style: MangaFonts.sans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: MangaColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: isCompactHeight ? 4 : 6),

                // Giant Total Box
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: isCompactHeight ? 4 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: MangaShadows.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL A PAGAR',
                              style: MangaFonts.sans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF525252),
                              ),
                            ),
                            if (selectedCash != null &&
                                selectedCash >= grandTotal &&
                                grandTotal > 0)
                              Text(
                                'CAMBIO: \$${(selectedCash - grandTotal).toStringAsFixed(2)}',
                                style: MangaFonts.sans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: MangaColors.successGreen,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${grandTotal.toStringAsFixed(2)}',
                        style: MangaFonts.comic(
                          fontSize: isCompactHeight ? 28 : 34,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isCompactHeight ? 5 : 7),

                // Quick Cash Bills Row ($50, $100, $200, EXACTO)
                Row(
                  children: [
                    _buildQuickCashBtn('\$50', 50, isCompactHeight),
                    const SizedBox(width: 5),
                    _buildQuickCashBtn('\$100', 100, isCompactHeight),
                    const SizedBox(width: 5),
                    _buildQuickCashBtn('\$200', 200, isCompactHeight),
                    const SizedBox(width: 5),
                    Expanded(
                      child: MangaPressButton(
                        onTap: () =>
                            widget.controller.selectQuickCash(grandTotal),
                        height: isCompactHeight ? 30 : 34,
                        backgroundColor: MangaColors.accentCyan,
                        hoverColor: MangaColors.accentCyanDark,
                        borderRadius: 7,
                        child: Center(
                          child: Text(
                            'EXACTO',
                            style: MangaFonts.comic(
                                fontSize: isCompactHeight ? 14 : 16,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompactHeight ? 5 : 7),

                // HERO BUTTON: ¡COBRAR!
                MangaPressButton(
                  onTap: () => _showCheckoutModal(context),
                  height: isCompactHeight ? 44 : 54,
                  width: double.infinity,
                  backgroundColor: MangaColors.primaryOrange,
                  hoverColor: MangaColors.primaryOrangeHover,
                  borderWidth: 2.5,
                  borderRadius: 10,
                  shadow: MangaShadows.md,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: MangaColors.accentYellow,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.black, width: 1.8),
                        ),
                        child: Text(
                          '¡COBRAR!',
                          style: MangaFonts.comic(
                            fontSize: isCompactHeight ? 21 : 25,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '\$${grandTotal.toStringAsFixed(2)}',
                            style: MangaFonts.comic(
                              fontSize: isCompactHeight ? 24 : 30,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(1.5, 1.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: isCompactHeight ? 22 : 26,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isCompactHeight ? 5 : 7),

                // Secondary Buttons Row (GUARDAR, DIVIDIR, CUPÓN, ANULAR)
                Row(
                  children: [
                    Expanded(
                      child: MangaPressButton(
                        onTap: () => _handleSaveOrRestoreDraft(context),
                        height: isCompactHeight ? 28 : 32,
                        borderRadius: 7,
                        backgroundColor: Colors.white,
                        child: Center(
                          child: Text(
                            widget.controller.savedDrafts.isNotEmpty &&
                                    items.isEmpty
                                ? 'ABRIR (${widget.controller.savedDrafts.length})'
                                : 'GUARDAR',
                            style: MangaFonts.sans(
                                fontSize: 9.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: MangaPressButton(
                        onTap: () => _showSplitBillDialog(context),
                        height: isCompactHeight ? 28 : 32,
                        borderRadius: 7,
                        backgroundColor: Colors.white,
                        child: Center(
                          child: Text(
                            'DIVIDIR',
                            style: MangaFonts.sans(
                                fontSize: 9.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: MangaPressButton(
                        onTap: () => _showDiscountDialog(context),
                        height: isCompactHeight ? 28 : 32,
                        borderRadius: 7,
                        backgroundColor: Colors.white,
                        child: Center(
                          child: Text(
                            'CUPÓN',
                            style: MangaFonts.sans(
                                fontSize: 9.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: MangaPressButton(
                        onTap: () => widget.controller.clearTicket(),
                        height: isCompactHeight ? 28 : 32,
                        borderRadius: 7,
                        backgroundColor: MangaColors.dangerSoftRed,
                        child: Center(
                          child: Text(
                            'ANULAR',
                            style: MangaFonts.sans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: MangaColors.dangerRed,
                            ),
                          ),
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

  Widget _buildQuickCashBtn(String label, double value, bool isCompactHeight) {
    final isSelected = widget.controller.selectedCashTendered == value;
    return Expanded(
      child: MangaPressButton(
        onTap: () => widget.controller.selectQuickCash(value),
        height: isCompactHeight ? 30 : 34,
        borderRadius: 7,
        backgroundColor: isSelected ? MangaColors.accentYellow : Colors.white,
        hoverColor: MangaColors.accentYellow,
        child: Center(
          child: Text(
            label,
            style: MangaFonts.comic(
                fontSize: isCompactHeight ? 15 : 17, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketItemRow(
    BuildContext context,
    OrderItem item,
    bool isCompactHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompactHeight ? 7 : 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: MangaShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showEditItemNotesDialog(context, item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MangaFonts.comic(
                            fontSize: isCompactHeight ? 16 : 17.5,
                            color: Colors.black),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.notes.isEmpty
                                  ? 'Agregar nota...'
                                  : item.notes,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MangaFonts.sans(
                                fontSize: 10,
                                color: const Color(0xFF525252),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.edit_note_rounded,
                              size: 13, color: Colors.black54),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: MangaColors.accentYellow,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: MangaFonts.comic(
                      fontSize: isCompactHeight ? 16 : 18, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  MangaPressButton(
                    onTap: () =>
                        widget.controller.decrementTicketItem(item.id),
                    width: 26,
                    height: 26,
                    borderRadius: 6,
                    backgroundColor: MangaColors.softCream,
                    child: Center(
                      child: Text(
                        '-',
                        style: MangaFonts.sans(
                            fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.quantity}',
                      style: MangaFonts.comic(fontSize: 18),
                    ),
                  ),
                  MangaPressButton(
                    onTap: () =>
                        widget.controller.incrementTicketItem(item.id),
                    width: 26,
                    height: 26,
                    borderRadius: 6,
                    backgroundColor: MangaColors.softCream,
                    child: Center(
                      child: Text(
                        '+',
                        style: MangaFonts.sans(
                            fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: MangaColors.badgeSoftBlue,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Text(
                      '\$${item.unitPrice.toStringAsFixed(2)} c/u',
                      style: MangaFonts.sans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => widget.controller.removeTicketItem(item.id),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== MODALS & POPUPS ====================

  Future<void> _showCheckoutModal(BuildContext context) async {
    if (widget.controller.ticketItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: MangaColors.dangerRed,
          content: Text(
            '¡Agrega al menos un producto al ticket antes de cobrar!',
            style: MangaFonts.sans(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final total = widget.controller.ticketGrandTotal;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MangaColors.surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 3.5),
              boxShadow: MangaShadows.xl,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: MangaColors.primaryOrange,
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: Colors.black, width: 2),
                            ),
                            child: Text(
                              'PAGO',
                              style: MangaFonts.comic(
                                  fontSize: 24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'LIQUIDAR ORDEN',
                            style: MangaFonts.comic(fontSize: 24),
                          ),
                        ],
                      ),
                      MangaPressButton(
                        onTap: () => Navigator.of(ctx).pop(),
                        width: 34,
                        height: 34,
                        backgroundColor: Colors.white,
                        hoverColor: MangaColors.dangerSoftRed,
                        child: const Icon(Icons.close_rounded,
                            color: Colors.black, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: MangaColors.accentYellow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: MangaShadows.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL A COBRAR:',
                          style: MangaFonts.sans(
                              fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: MangaFonts.comic(fontSize: 34),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPaymentMethodButton(
                        ctx: ctx,
                        method: PaymentMethod.cash,
                        icon: Icons.payments_rounded,
                        iconColor: MangaColors.successGreen,
                        hoverColor: MangaColors.accentMint,
                      ),
                      _buildPaymentMethodButton(
                        ctx: ctx,
                        method: PaymentMethod.card,
                        icon: Icons.credit_card_rounded,
                        iconColor: MangaColors.accentCyan,
                        hoverColor: MangaColors.accentCyan,
                      ),
                      _buildPaymentMethodButton(
                        ctx: ctx,
                        method: PaymentMethod.qr,
                        icon: Icons.qr_code_scanner_rounded,
                        iconColor: MangaColors.primaryOrange,
                        hoverColor: MangaColors.primaryOrange,
                      ),
                      _buildPaymentMethodButton(
                        ctx: ctx,
                        method: PaymentMethod.account,
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: Colors.black,
                        hoverColor: MangaColors.accentYellow,
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
  }

  Widget _buildPaymentMethodButton({
    required BuildContext ctx,
    required PaymentMethod method,
    required IconData icon,
    required Color iconColor,
    required Color hoverColor,
  }) {
    return MangaPressButton(
      onTap: () async {
        Navigator.of(ctx).pop();
        final createdOrder = await widget.controller.completeCheckout(
          paymentMethod: method,
        );
        if (!mounted || createdOrder == null) return;
        final itemsText = createdOrder.items
            .map((i) => '${i.quantity}x ${i.name}')
            .join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 3),
            content: Text(
              '⚡ ¡Orden #${createdOrder.orderNumber} enviada al Cliente! ($itemsText)',
              style: MangaFonts.sans(color: Colors.white, fontSize: 12.5),
            ),
          ),
        );
      },
      backgroundColor: Colors.white,
      hoverColor: hoverColor,
      shadow: MangaShadows.sm,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 8),
          Text(
            method.label,
            style: MangaFonts.comic(fontSize: 17, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCustomerDialog(BuildContext context) async {
    final custCtrl =
        TextEditingController(text: widget.controller.currentCustomerName);

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(18),
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
              Text('NOMBRE DEL CLIENTE', style: MangaFonts.comic(fontSize: 24)),
              const SizedBox(height: 10),
              TextField(
                controller: custCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(),
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child:
                          Text('CANCELAR', style: MangaFonts.comic(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MangaPressButton(
                    onTap: () {
                      widget.controller.updateTicketHeaderInfo(
                        customerName: custCtrl.text,
                      );
                      Navigator.of(ctx).pop();
                    },
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: MangaColors.primaryOrange,
                    child: Center(
                      child: Text('GUARDAR',
                          style: MangaFonts.comic(
                              fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditItemNotesDialog(
      BuildContext context, OrderItem item) async {
    final notesCtrl = TextEditingController(text: item.notes);
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(18),
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
              Text('NOTA DE PREPARACIÓN: ${item.name}',
                  style: MangaFonts.comic(fontSize: 20)),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ej. Sin cebolla, extra tocino, sin tomate...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: MangaPressButton(
                  onTap: () {
                    widget.controller
                        .updateTicketItemNotes(item.id, notesCtrl.text);
                    Navigator.of(ctx).pop();
                  },
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: MangaColors.primaryOrange,
                  child: Center(
                    child: Text('GUARDAR NOTA',
                        style: MangaFonts.comic(
                            fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFreeSaleDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(text: 'DOGO ESPECIAL');
    final priceCtrl = TextEditingController();
    final notesCtrl = TextEditingController(text: 'Con todo');

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
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
                Text('VENTA LIBRE / CARGO RÁPIDO',
                    style: MangaFonts.comic(fontSize: 22)),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Concepto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Precio (\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Notas para preparación',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MangaPressButton(
                      onTap: () => Navigator.of(ctx).pop(),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: Text('CANCELAR',
                            style: MangaFonts.comic(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MangaPressButton(
                      onTap: () {
                        final p = double.tryParse(
                                priceCtrl.text.replaceAll(',', '.').trim()) ??
                            0.0;
                        if (p > 0) {
                          widget.controller.addFreeSaleItem(
                            name: nameCtrl.text.trim(),
                            price: p,
                            notes: notesCtrl.text.trim(),
                          );
                          Navigator.of(ctx).pop();
                        }
                      },
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: MangaColors.primaryOrange,
                      child: Center(
                        child: Text('AGREGAR',
                            style: MangaFonts.comic(
                                fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDiscountDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(18),
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
              Text('APLICAR DESCUENTO / CUPÓN',
                  style: MangaFonts.comic(fontSize: 23)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDiscountOptionBtn(ctx, '10% PROMO', percent: 10),
                  _buildDiscountOptionBtn(ctx, '15% PROMO', percent: 15),
                  _buildDiscountOptionBtn(ctx, '20% VIP', percent: 20),
                  _buildDiscountOptionBtn(ctx, '-\$10 CUPÓN', fixed: 10),
                  _buildDiscountOptionBtn(ctx, 'QUITAR DESCUENTO',
                      percent: 0, fixed: 0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountOptionBtn(
    BuildContext ctx,
    String title, {
    double percent = 0,
    double fixed = 0,
  }) {
    return MangaPressButton(
      onTap: () {
        widget.controller.applyDiscount(
          percent: percent,
          fixedAmount: fixed,
          label: title,
        );
        Navigator.of(ctx).pop();
      },
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      backgroundColor: MangaColors.accentYellow,
      child: Center(
        child: Text(title, style: MangaFonts.comic(fontSize: 16)),
      ),
    );
  }

  void _handleSaveOrRestoreDraft(BuildContext context) {
    if (widget.controller.ticketItems.isNotEmpty) {
      widget.controller.saveCurrentTicketAsDraft();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            '📌 Orden guardada en espera.',
            style: MangaFonts.sans(color: Colors.white),
          ),
        ),
      );
    } else if (widget.controller.savedDrafts.isNotEmpty) {
      widget.controller
          .restoreDraftToTicket(widget.controller.savedDrafts.first);
    }
  }

  Future<void> _showSplitBillDialog(BuildContext context) async {
    final total = widget.controller.ticketGrandTotal;
    if (total <= 0) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MangaColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: MangaShadows.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('DIVIDIR CUENTA (\$${total.toStringAsFixed(2)})',
                  style: MangaFonts.comic(fontSize: 23)),
              const SizedBox(height: 10),
              ...[2, 3, 4].map((parts) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MangaColors.ticketListBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ENTRE $parts PERSONAS:',
                          style: MangaFonts.sans(fontWeight: FontWeight.w800)),
                      Text(
                        '\$${(total / parts).toStringAsFixed(2)} c/u',
                        style: MangaFonts.comic(fontSize: 20),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              MangaPressButton(
                onTap: () => Navigator.of(ctx).pop(),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: MangaColors.accentYellow,
                child: Center(
                  child: Text('LISTO', style: MangaFonts.comic(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLanInfoPopup(BuildContext context) async {
    final ips = widget.controller.localIps.join(' / ');
    final port = widget.controller.lanService.serverPort;
    final clients = widget.controller.lanService.connectedClientsCount;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
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
              Text('📡 SERVIDOR DOGOS EL PA (RED LOCAL)',
                  style: MangaFonts.comic(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                'Conecta cualquier celular en la misma red Wi-Fi iniciando en MODO CLIENTE con esta IP:',
                style: MangaFonts.sans(fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MangaColors.accentYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Column(
                  children: [
                    Text('IP DEL SERVIDOR:',
                        style: MangaFonts.sans(
                            fontSize: 10.5, fontWeight: FontWeight.w900)),
                    Text(
                      '$ips : $port',
                      style: MangaFonts.comic(fontSize: 26),
                    ),
                    Text(
                      'Celulares Cliente conectados: $clients',
                      style: MangaFonts.sans(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: MangaPressButton(
                  onTap: () => Navigator.of(ctx).pop(),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child:
                        Text('CERRAR', style: MangaFonts.comic(fontSize: 16)),
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
