import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_models.dart';
import '../theme/manga_theme.dart';
import '../widgets/manga_widgets.dart';

class ProductManagementView extends StatefulWidget {
  final PosController controller;

  const ProductManagementView({
    super.key,
    required this.controller,
  });

  @override
  State<ProductManagementView> createState() => _ProductManagementViewState();
}

class _ProductManagementViewState extends State<ProductManagementView> {
  String _searchFilter = '';
  String _categoryFilter = 'todos';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompactHeight = screenHeight < 500;

    final products = widget.controller.allProducts.where((p) {
      final matchesCat =
          _categoryFilter == 'todos' || p.categoryId == _categoryFilter;
      if (!matchesCat) return false;
      if (_searchFilter.trim().isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.all(isCompactHeight ? 8 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Bar (without Import/Export since those live exclusively in Ajustes)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: MangaColors.primaryOrange,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: MangaShadows.sm,
                        ),
                        child: Text(
                          'PRODUCTOS',
                          style: MangaFonts.comic(
                            fontSize: isCompactHeight ? 17 : 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CATÁLOGO DE DOGOS, PAPAS Y COMBOS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MangaFonts.comic(
                                fontSize: isCompactHeight ? 18 : 22,
                                color: Colors.black,
                              ),
                            ),
                            if (!isCompactHeight)
                              Text(
                                'Crea, edita o elimina productos con imágenes locales (${widget.controller.allProducts.length} registrados)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MangaFonts.sans(
                                  fontSize: 11.5,
                                  color: Colors.black87,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                MangaPressButton(
                  onTap: () => showProductEditorDialog(
                    context,
                    controller: widget.controller,
                  ),
                  height: isCompactHeight ? 36 : 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  backgroundColor: MangaColors.primaryOrange,
                  hoverColor: MangaColors.primaryOrangeHover,
                  shadow: MangaShadows.md,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '+ NUEVO PRODUCTO',
                        style: MangaFonts.comic(
                          fontSize: isCompactHeight ? 15 : 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompactHeight ? 8 : 10),

          // Filter & Search Row (Only TODOS, DOGOS, PAPAS, COMBOS)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: isCompactHeight ? 38 : 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: MangaShadows.sm,
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchFilter = v),
                    style: MangaFonts.sans(fontSize: 12.5),
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.black, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: isCompactHeight ? 38 : 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.controller.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = widget.controller.categories[index];
                      final isSelected = _categoryFilter == cat.id;
                      return MangaPressButton(
                        onTap: () => setState(() => _categoryFilter = cat.id),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        backgroundColor: isSelected
                            ? MangaColors.primaryOrange
                            : Colors.white,
                        hoverColor:
                            isSelected ? null : MangaColors.accentYellow,
                        child: Row(
                          children: [
                            Text(cat.emoji,
                                style: const TextStyle(fontSize: 15)),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: MangaFonts.comic(
                                fontSize: isCompactHeight ? 15 : 17,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompactHeight ? 8 : 10),

          // Products Grid
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: MangaShadows.md,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 44, color: MangaColors.primaryOrange),
                          const SizedBox(height: 8),
                          Text(
                            'NO HAY PRODUCTOS EN ESTA VISTA',
                            style: MangaFonts.comic(fontSize: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Toca "+ NUEVO PRODUCTO" para crear tus Dogos, Papas o Combos con imagen local.',
                            textAlign: TextAlign.center,
                            style: MangaFonts.sans(
                                fontSize: 12.5, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          MangaPressButton(
                            onTap: () => showProductEditorDialog(
                              context,
                              controller: widget.controller,
                            ),
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            backgroundColor: MangaColors.primaryOrange,
                            child: Center(
                              child: Text(
                                '+ CREAR PRODUCTO AHORA',
                                style: MangaFonts.comic(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 290,
                      mainAxisExtent: 235,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductAdminCard(context, product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductAdminCard(BuildContext context, Product product) {
    final hasLocalImg = (product.localImagePath != null &&
            product.localImagePath!.isNotEmpty) ||
        (product.imageBase64 != null && product.imageBase64!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: MangaShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Badges
          SizedBox(
            height: 100,
            width: double.infinity,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: MangaColors.cardImageBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ProductImageDisplay(
                    localImagePath: product.localImagePath,
                    imageBase64: product.imageBase64,
                    imageUrl: product.imageUrl,
                    fallbackLabel: product.name,
                  ),
                ),
                if (product.badgeText != null &&
                    product.badgeText!.trim().isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: MangaColors.fromHex(product.badgeColorHex),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: MangaShadows.sm,
                      ),
                      child: Text(
                        product.badgeText!,
                        style: MangaFonts.sans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: product.badgeColorHex == '#85f8c4' ||
                                  product.badgeColorHex == '#ffcb11'
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: hasLocalImg
                          ? MangaColors.accentMint
                          : Colors.black87,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Text(
                      hasLocalImg ? '📁 FOTO LOCAL' : '🌐 DEMO',
                      style: MangaFonts.sans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: hasLocalImg ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MangaFonts.comic(fontSize: 19),
          ),
          Text(
            product.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MangaFonts.sans(
              fontSize: 11,
              color: const Color(0xFF525252),
            ),
          ),
          const Spacer(),
          const MangaDashedDivider(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: MangaColors.accentYellow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: MangaShadows.sm,
                ),
                child: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: MangaFonts.comic(fontSize: 21),
                ),
              ),
              Row(
                children: [
                  MangaPressButton(
                    onTap: () => showProductEditorDialog(
                      context,
                      controller: widget.controller,
                      existingProduct: product,
                    ),
                    width: 34,
                    height: 34,
                    backgroundColor: MangaColors.accentCyan,
                    tooltip: 'Editar producto / cambiar foto local',
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  MangaPressButton(
                    onTap: () => _confirmDeleteProduct(context, product),
                    width: 34,
                    height: 34,
                    backgroundColor: MangaColors.dangerSoftRed,
                    tooltip: 'Eliminar producto',
                    child: const Icon(
                      Icons.delete_rounded,
                      size: 17,
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
  }

  Future<void> _confirmDeleteProduct(
      BuildContext context, Product product) async {
    final confirm = await showDialog<bool>(
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
              Text('¿ELIMINAR PRODUCTO?', style: MangaFonts.comic(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                'Se eliminará "${product.name}" del catálogo.',
                textAlign: TextAlign.center,
                style: MangaFonts.sans(fontSize: 12.5),
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
                      child:
                          Text('CANCELAR', style: MangaFonts.comic(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  MangaPressButton(
                    onTap: () => Navigator.of(ctx).pop(true),
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: MangaColors.dangerSoftRed,
                    child: Center(
                      child: Text(
                        'ELIMINAR',
                        style: MangaFonts.comic(
                            fontSize: 16, color: MangaColors.dangerRed),
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
      await widget.controller.deleteProduct(product.id);
    }
  }
}

/// Reusable dialog to Create or Edit a Product (Dogos, Papas, Combos) with Local Image Selection
Future<void> showProductEditorDialog(
  BuildContext context, {
  required PosController controller,
  Product? existingProduct,
}) async {
  final isEditing = existingProduct != null;
  final nameCtrl = TextEditingController(text: existingProduct?.name ?? '');
  final descCtrl =
      TextEditingController(text: existingProduct?.description ?? '');
  final priceCtrl = TextEditingController(
      text: existingProduct != null
          ? existingProduct.price.toStringAsFixed(2)
          : '');
  final badgeCtrl =
      TextEditingController(text: existingProduct?.badgeText ?? '');

  final availableCategories =
      controller.categories.where((c) => c.id != 'todos').toList();
  String selectedCatId = existingProduct?.categoryId ??
      (availableCategories.isNotEmpty ? availableCategories.first.id : 'dogos');
  if (!availableCategories.any((c) => c.id == selectedCatId) &&
      availableCategories.isNotEmpty) {
    selectedCatId = availableCategories.first.id;
  }

  String selectedBadgeColor = existingProduct?.badgeColorHex ?? '#ff5a1f';
  String? localImagePath = existingProduct?.localImagePath;
  String? imageBase64 = existingProduct?.imageBase64;
  String? imageUrl = existingProduct?.imageUrl;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              width: 540,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: MangaColors.primaryOrange,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              child: Text(
                                isEditing ? 'EDITAR' : 'NUEVO',
                                style: MangaFonts.comic(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isEditing
                                  ? 'MODIFICAR PRODUCTO'
                                  : 'CREAR PRODUCTO',
                              style: MangaFonts.comic(fontSize: 24),
                            ),
                          ],
                        ),
                        MangaPressButton(
                          onTap: () => Navigator.of(ctx).pop(),
                          width: 34,
                          height: 34,
                          backgroundColor: MangaColors.dangerSoftRed,
                          child: const Icon(Icons.close_rounded,
                              color: Colors.black, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Local Image Picker Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 100,
                          decoration: BoxDecoration(
                            color: MangaColors.cardImageBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: MangaShadows.sm,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ProductImageDisplay(
                            localImagePath: localImagePath,
                            imageBase64: imageBase64,
                            imageUrl: imageUrl,
                            fallbackLabel: nameCtrl.text.isEmpty
                                ? 'SIN IMAGEN'
                                : nameCtrl.text,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IMAGEN DEL PRODUCTO (GALERÍA / LOCAL)',
                                style: MangaFonts.sans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Selecciona una foto de tu dispositivo. Se guardará localmente y en tu respaldo.',
                                style: MangaFonts.sans(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  MangaPressButton(
                                    onTap: () async {
                                      final picked = await controller
                                          .pickAndSaveLocalProductImage();
                                      if (picked != null) {
                                        setModalState(() {
                                          localImagePath = picked.localPath;
                                          imageBase64 = picked.base64Data;
                                        });
                                      }
                                    },
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    backgroundColor: MangaColors.accentYellow,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.photo_library_rounded,
                                            size: 16, color: Colors.black),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ELEGIR IMAGEN LOCAL',
                                          style: MangaFonts.comic(fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (localImagePath != null ||
                                      imageBase64 != null ||
                                      imageUrl != null)
                                    MangaPressButton(
                                      onTap: () {
                                        setModalState(() {
                                          localImagePath = null;
                                          imageBase64 = null;
                                          imageUrl = null;
                                        });
                                      },
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      backgroundColor:
                                          MangaColors.dangerSoftRed,
                                      child: Center(
                                        child: Text(
                                          'QUITAR FOTO',
                                          style: MangaFonts.comic(
                                            fontSize: 14,
                                            color: MangaColors.dangerRed,
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
                    const SizedBox(height: 12),

                    // Name & Price
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildLabeledField(
                            label: 'NOMBRE DEL PRODUCTO *',
                            controller: nameCtrl,
                            hint: 'Ej. DOGO ESPECIAL EL PA',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: _buildLabeledField(
                            label: 'PRECIO (\$) *',
                            controller: priceCtrl,
                            hint: 'Ej. 55.00',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Description
                    _buildLabeledField(
                      label: 'DESCRIPCIÓN / INGREDIENTES',
                      controller: descCtrl,
                      hint: 'Ej. Salchicha con tocino, queso y cebolla asada',
                    ),
                    const SizedBox(height: 10),

                    // Category (Dogos, Papas, Combos) & Comic Badge
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CATEGORÍA',
                                style: MangaFonts.sans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 42,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.black, width: 2),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedCatId,
                                    isExpanded: true,
                                    items: availableCategories.map((c) {
                                      return DropdownMenuItem<String>(
                                        value: c.id,
                                        child: Text(
                                          '${c.emoji} ${c.name}',
                                          style: MangaFonts.sans(fontSize: 12.5),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setModalState(() => selectedCatId = v);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildLabeledField(
                            label: 'ETIQUETA (OPCIONAL)',
                            controller: badgeCtrl,
                            hint: 'Ej. ★ ¡TOP VENTAS!',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Save / Cancel Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        MangaPressButton(
                          onTap: () => Navigator.of(ctx).pop(),
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: Colors.white,
                          child: Center(
                            child: Text(
                              'CANCELAR',
                              style: MangaFonts.comic(fontSize: 17),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        MangaPressButton(
                          onTap: () async {
                            final name = nameCtrl.text.trim();
                            final price = double.tryParse(
                                    priceCtrl.text.replaceAll(',', '.').trim()) ??
                                0.0;
                            if (name.isEmpty || price <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: MangaColors.dangerRed,
                                  content: Text(
                                    'Por favor ingresa un nombre válido y un precio mayor a 0.',
                                    style: MangaFonts.sans(color: Colors.white),
                                  ),
                                ),
                              );
                              return;
                            }

                            final product = Product(
                              id: existingProduct?.id ??
                                  'prod_${const Uuid().v4()}',
                              name: name.toUpperCase(),
                              description: descCtrl.text.trim().isEmpty
                                  ? 'Especialidad Dogos El Pa'
                                  : descCtrl.text.trim(),
                              price: price,
                              categoryId: selectedCatId,
                              badgeText: badgeCtrl.text.trim().isEmpty
                                  ? null
                                  : badgeCtrl.text.trim().toUpperCase(),
                              badgeColorHex: badgeCtrl.text.trim().isEmpty
                                  ? null
                                  : selectedBadgeColor,
                              localImagePath: localImagePath,
                              imageBase64: imageBase64,
                              imageUrl: imageUrl,
                            );

                            await controller.addOrUpdateProduct(product);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          backgroundColor: MangaColors.primaryOrange,
                          hoverColor: MangaColors.primaryOrangeHover,
                          shadow: MangaShadows.md,
                          child: Center(
                            child: Text(
                              isEditing
                                  ? '💾 GUARDAR CAMBIOS'
                                  : '⚡ CREAR PRODUCTO',
                              style: MangaFonts.comic(
                                fontSize: 18,
                                color: Colors.white,
                              ),
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

Widget _buildLabeledField({
  required String label,
  required TextEditingController controller,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: MangaFonts.sans(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: MangaFonts.sans(fontSize: 12.5, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
      ),
    ],
  );
}
