import 'package:flutter/material.dart';
import '../controllers/pos_controller.dart';
import '../theme/manga_theme.dart';
import '../widgets/manga_widgets.dart';

class ModeSelectionScreen extends StatefulWidget {
  final PosController controller;

  const ModeSelectionScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  late TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(
      text: widget.controller.lastServerIp,
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ips = widget.controller.localIps.join(' · ');

    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Clean Header: Only "DOGOS EL PA" on the left + IP on the right
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: MangaColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black, width: 3.5),
                        boxShadow: MangaShadows.lg,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          Text(
                            'DOGOS EL PA',
                            style: MangaFonts.comic(
                              fontSize: 36,
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
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: MangaColors.accentYellow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: MangaShadows.sm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi_tethering_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'IP LOCAL DE ESTE DISPOSITIVO',
                                        style: MangaFonts.sans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '$ips : ${widget.controller.configuredPort}',
                                          style: MangaFonts.sans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Dual Role Cards: SERVIDOR (Landscape) vs CLIENTE (Portrait)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 680;
                        final serverCard = _buildServerModeCard();
                        final clientCard = _buildClientModeCard();

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: serverCard),
                              const SizedBox(width: 18),
                              Expanded(child: clientCard),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            serverCard,
                            const SizedBox(height: 16),
                            clientCard,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerModeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MangaColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: MangaShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: MangaColors.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: MangaShadows.sm,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '★ OPCIÓN 1 · MODO HORIZONTAL',
                      style: MangaFonts.comic(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: MangaColors.accentYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: MangaShadows.sm,
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  size: 24,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'SERVIDOR (PUNTO DE VENTA)',
            style: MangaFonts.comic(
              fontSize: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Optimizado en modo horizontal (Landscape) para llevar el POS completo:',
            style: MangaFonts.sans(
              fontSize: 12.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureBullet(
            Icons.bolt_rounded,
            MangaColors.primaryOrange,
            'Ventas de Dogos, Papas y Combos con envío instantáneo al Cliente.',
          ),
          _buildFeatureBullet(
            Icons.add_photo_alternate_rounded,
            MangaColors.accentCyan,
            'Crear, editar o eliminar productos con fotos locales de tu galería.',
          ),
          _buildFeatureBullet(
            Icons.settings_backup_restore_rounded,
            MangaColors.accentMintDark,
            'Importar / Exportar respaldo de productos en Ajustes y reportes de caja.',
          ),
          const SizedBox(height: 14),
          MangaPressButton(
            onTap: () => widget.controller.selectServerMode(),
            height: 56,
            width: double.infinity,
            backgroundColor: MangaColors.primaryOrange,
            hoverColor: MangaColors.primaryOrangeHover,
            borderWidth: 3,
            borderRadius: 12,
            shadow: MangaShadows.md,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: MangaColors.accentYellow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    '¡ENTRAR!',
                    style: MangaFonts.comic(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'INICIAR COMO SERVIDOR',
                      style: MangaFonts.comic(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.screen_rotation_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientModeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MangaColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: MangaShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: MangaColors.accentCyan,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: MangaShadows.sm,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '⚡ OPCIÓN 2 · CELULAR VERTICAL',
                      style: MangaFonts.comic(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: MangaColors.accentMint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: MangaShadows.sm,
                ),
                child: const Icon(
                  Icons.smartphone_rounded,
                  size: 24,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'CLIENTE (RECEPCIÓN DE ÓRDENES)',
            style: MangaFonts.comic(
              fontSize: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Optimizado para celulares en modo vertical. Recibe cada pedido en vivo:',
            style: MangaFonts.sans(
              fontSize: 12.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureBullet(
            Icons.notifications_active_rounded,
            MangaColors.accentCyan,
            'Recibe al instante las órdenes del Servidor por red local Wi-Fi.',
          ),
          _buildFeatureBullet(
            Icons.checklist_rounded,
            MangaColors.primaryOrange,
            'Visualiza notas de preparación, marca productos listos y entrega.',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MangaColors.ticketFooterBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IP DEL SERVIDOR (DEJA EN BLANCO PARA AUTO-DETECTAR EN LA RED):',
                  style: MangaFonts.sans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _ipController,
                  style: MangaFonts.sans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Ej. 192.168.1.50',
                    prefixIcon: const Icon(
                      Icons.lan_rounded,
                      color: Colors.black,
                      size: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.black, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MangaPressButton(
            onTap: () {
              final ip = _ipController.text.trim();
              widget.controller.selectClientMode(
                autoConnectIp: ip.isNotEmpty ? ip : null,
              );
            },
            height: 56,
            width: double.infinity,
            backgroundColor: MangaColors.accentCyan,
            hoverColor: MangaColors.accentCyanDark,
            borderWidth: 3,
            borderRadius: 12,
            shadow: MangaShadows.md,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: MangaColors.accentYellow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    '¡CONECTAR!',
                    style: MangaFonts.comic(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'INICIAR COMO CLIENTE',
                      style: MangaFonts.comic(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.wifi_find_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, Color badgeColor, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, size: 14, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: MangaFonts.sans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
