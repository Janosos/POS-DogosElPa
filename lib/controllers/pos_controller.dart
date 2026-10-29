import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/default_catalog.dart';
import '../models/pos_models.dart';
import '../services/lan_sync_service.dart';

class PosController extends ChangeNotifier {
  static const String _prefsProductsKey = 'pos_products_dogos_v2';
  static const String _prefsCategoriesKey = 'pos_categories_dogos_v2';
  static const String _prefsOrdersKey = 'pos_orders_dogos_v2';
  static const String _prefsNextOrderNumKey = 'pos_next_order_num_v2';
  static const String _prefsStoreNameKey = 'pos_store_name_v2';
  static const String _prefsCashierNameKey = 'pos_cashier_name_v2';
  static const String _prefsLastServerIpKey = 'pos_last_server_ip_v2';
  static const String _prefsServerPortKey = 'pos_server_port_v2';

  final LanSyncService lanService = LanSyncService();
  final Uuid _uuid = const Uuid();
  final ImagePicker _imagePicker = ImagePicker();

  AppMode _appMode = AppMode.unselected;
  // Navigation indices (without Mesas):
  // 0: Venta, 1: Productos, 2: Tickets, 3: Cierre, 4: Ajustes
  int _serverNavIndex = 0;

  // Business / Terminal info
  String _storeName = 'DOGOS EL PA';
  String _cashierName = 'CAJA PRINCIPAL';
  String _shiftLabel = 'TURNO ACTIVO';
  int _nextOrderNumber = 1042;
  int _configuredPort = LanSyncService.defaultHttpPort;
  String _lastServerIp = '127.0.0.1';
  List<String> _localIps = ['127.0.0.1'];

  // Catalog state (only TODOS, DOGOS, PAPAS, COMBOS)
  List<ProductCategory> _categories =
      List.from(DefaultCatalog.defaultCategories);
  List<Product> _products = List.from(DefaultCatalog.defaultProducts);
  String _selectedCategoryId = 'todos';
  String _searchQuery = '';

  // Current Ticket / Cart state
  List<OrderItem> _ticketItems = [];
  OrderType _currentOrderType = OrderType.dineIn;
  String _currentTableOrLocation = 'COMER AQUÍ';
  String _currentCustomerName = 'CLIENTE GENERAL';
  double _discountPercent = 0.0;
  double _fixedDiscount = 0.0;
  String _discountLabel = 'DESCUENTO PROMO';
  double? _selectedCashTendered;

  // Orders & Saved Drafts
  List<PosOrder> _orders = [];
  final List<PosOrder> _savedDrafts = [];

  // Client / Kitchen Notification state
  PosOrder? _latestIncomingOrderAlert;
  bool _isScanningLan = false;
  List<DiscoveredServer> _discoveredServers = [];

  // Getters
  AppMode get appMode => _appMode;
  int get serverNavIndex => _serverNavIndex;
  String get storeName => _storeName;
  String get cashierName => _cashierName;
  String get shiftLabel => _shiftLabel;
  int get nextOrderNumber => _nextOrderNumber;
  int get configuredPort => _configuredPort;
  String get lastServerIp => _lastServerIp;
  List<String> get localIps => _localIps;

  List<ProductCategory> get categories => _categories;
  List<Product> get allProducts => _products;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesCategory =
          _selectedCategoryId == 'todos' || p.categoryId == _selectedCategoryId;
      if (!matchesCategory) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  List<OrderItem> get ticketItems => _ticketItems;
  OrderType get currentOrderType => _currentOrderType;
  String get currentTableOrLocation => _currentTableOrLocation;
  String get currentCustomerName => _currentCustomerName;
  String get discountLabel => _discountLabel;
  double? get selectedCashTendered => _selectedCashTendered;

  int get ticketTotalItemsCount =>
      _ticketItems.fold<int>(0, (sum, item) => sum + item.quantity);

  double get ticketSubtotal =>
      _ticketItems.fold<double>(0.0, (sum, item) => sum + item.total);

  double get ticketDiscount {
    final pctDisc = ticketSubtotal * (_discountPercent / 100.0);
    final totalDisc = pctDisc + _fixedDiscount;
    return totalDisc > ticketSubtotal ? ticketSubtotal : totalDisc;
  }

  double get ticketPayableAfterDiscount =>
      (ticketSubtotal - ticketDiscount).clamp(0.0, double.infinity);

  // Sin IVA (0%)
  double get ticketTaxIncluded => 0.0;

  double get ticketGrandTotal => ticketPayableAfterDiscount;

  List<PosOrder> get orders => _orders;
  List<PosOrder> get savedDrafts => _savedDrafts;

  List<PosOrder> get activeKitchenOrders => _orders
      .where((o) =>
          o.status == OrderStatus.pending ||
          o.status == OrderStatus.preparing ||
          o.status == OrderStatus.ready)
      .toList();

  PosOrder? get latestIncomingOrderAlert => _latestIncomingOrderAlert;
  bool get isScanningLan => _isScanningLan;
  List<DiscoveredServer> get discoveredServers => _discoveredServers;

  PosController() {
    _setupLanCallbacks();
    _initData();
  }

  void _setupLanCallbacks() {
    lanService.onGetOrdersSnapshot = () => _orders;
    lanService.onGetProductsSnapshot = () => _products;
    lanService.onStatusChanged = () {
      notifyListeners();
    };
    lanService.onFullSyncReceived = (List<PosOrder> syncedOrders) {
      _orders = syncedOrders;
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    };
    lanService.onOrderReceivedOrUpdated =
        (PosOrder incomingOrder, {required bool isNew}) {
      final index = _orders.indexWhere((o) => o.id == incomingOrder.id);
      final wasAlreadyPresent = index >= 0;
      if (wasAlreadyPresent) {
        _orders[index] = incomingOrder;
      } else {
        _orders.insert(0, incomingOrder);
      }
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (isNew || !wasAlreadyPresent) {
        _latestIncomingOrderAlert = incomingOrder;
      }
      if (_appMode == AppMode.server) {
        _saveOrdersToStorage();
      }
      notifyListeners();
    };
  }

  Future<void> _initData() async {
    _localIps = await lanService.getLocalIps();
    final prefs = await SharedPreferences.getInstance();

    _storeName = prefs.getString(_prefsStoreNameKey) ?? 'DOGOS EL PA';
    _cashierName = prefs.getString(_prefsCashierNameKey) ?? 'CAJA PRINCIPAL';
    _nextOrderNumber = prefs.getInt(_prefsNextOrderNumKey) ?? 1042;
    _configuredPort =
        prefs.getInt(_prefsServerPortKey) ?? LanSyncService.defaultHttpPort;
    _lastServerIp = prefs.getString(_prefsLastServerIpKey) ??
        (_localIps.isNotEmpty ? _localIps.first : '127.0.0.1');

    // Always enforce only the allowed Dogos categories: TODOS, DOGOS, PAPAS, COMBOS
    _categories = List.from(DefaultCatalog.defaultCategories);

    // Load products
    final rawProds = prefs.getString(_prefsProductsKey);
    if (rawProds != null && rawProds.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawProds) as List;
        _products = decoded
            .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    } else {
      await _saveCatalogToStorage();
    }

    // Load orders
    final rawOrders = prefs.getString(_prefsOrdersKey);
    if (rawOrders != null && rawOrders.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawOrders) as List;
        _orders = decoded
            .map((e) => PosOrder.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }

    // Seed initial sample ticket items matching user's Dogos example if empty
    if (_ticketItems.isEmpty && _products.isNotEmpty) {
      final dogo = _products.firstWhere(
        (p) => p.categoryId == 'dogos',
        orElse: () => _products.first,
      );
      final papas = _products.firstWhere(
        (p) => p.categoryId == 'papas',
        orElse: () => _products.last,
      );
      _ticketItems = [
        OrderItem(
          id: _uuid.v4(),
          productId: dogo.id,
          name: dogo.name,
          description: dogo.description,
          notes: 'Con todo · Cebolla asada y tocino',
          unitPrice: dogo.price,
          quantity: 2,
          imageUrl: dogo.imageUrl,
          localImagePath: dogo.localImagePath,
          imageBase64: dogo.imageBase64,
        ),
        OrderItem(
          id: _uuid.v4(),
          productId: papas.id,
          name: papas.name,
          description: papas.description,
          notes: 'Bien crujientes',
          unitPrice: papas.price,
          quantity: 1,
          imageUrl: papas.imageUrl,
          localImagePath: papas.localImagePath,
          imageBase64: papas.imageBase64,
        ),
      ];
    }

    notifyListeners();
  }

  // ==================== MODE SELECTION & ORIENTATION CONTROL ====================

  /// Server Mode: Locks orientation to Landscape (Horizontal) on Android/mobile
  Future<void> selectServerMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await lanService.disconnectClient();
    _appMode = AppMode.server;
    _localIps = await lanService.getLocalIps();
    await lanService.startServer(
      port: _configuredPort,
      serverName: _storeName,
    );
    notifyListeners();
  }

  /// Client Mode: Locks orientation to Portrait (Vertical) for mobile phones
  Future<void> selectClientMode({String? autoConnectIp}) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _appMode = AppMode.client;
    _localIps = await lanService.getLocalIps();
    notifyListeners();

    if (autoConnectIp != null && autoConnectIp.isNotEmpty) {
      await connectClientToServer(autoConnectIp, port: _configuredPort);
    } else {
      await scanForServersOnLan();
    }
  }

  Future<void> returnToModeSelection() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _appMode = AppMode.unselected;
    notifyListeners();
  }

  void setServerNavIndex(int index) {
    _serverNavIndex = index;
    notifyListeners();
  }

  void dismissIncomingOrderAlert() {
    _latestIncomingOrderAlert = null;
    notifyListeners();
  }

  // ==================== CLIENT LAN DISCOVERY & CONNECTION ====================

  Future<void> scanForServersOnLan() async {
    _isScanningLan = true;
    notifyListeners();
    try {
      final results =
          await lanService.discoverServers(port: _configuredPort);
      _discoveredServers = results;
      if (!lanService.isClientConnected && results.isNotEmpty) {
        await connectClientToServer(
          results.first.ip,
          port: results.first.port,
        );
      }
    } finally {
      _isScanningLan = false;
      notifyListeners();
    }
  }

  Future<bool> connectClientToServer(String ip, {int? port}) async {
    final targetPort = port ?? _configuredPort;
    _lastServerIp = ip.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLastServerIpKey, _lastServerIp);
    await prefs.setInt(_prefsServerPortKey, targetPort);

    final ok = await lanService.connectToServer(_lastServerIp, port: targetPort);
    notifyListeners();
    return ok;
  }

  // ==================== CATALOG & TICKET ACTIONS ====================

  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setOrderType(OrderType type) {
    _currentOrderType = type;
    _currentTableOrLocation = type.label;
    notifyListeners();
  }

  void updateTicketHeaderInfo({
    String? customerName,
  }) {
    if (customerName != null && customerName.trim().isNotEmpty) {
      _currentCustomerName = customerName.trim().toUpperCase();
    }
    notifyListeners();
  }

  void addProductToTicket(Product product, {String? customNotes}) {
    final existingIndex = _ticketItems.indexWhere(
      (item) =>
          item.productId == product.id &&
          (customNotes == null || item.notes == customNotes),
    );

    if (existingIndex >= 0) {
      final current = _ticketItems[existingIndex];
      _ticketItems[existingIndex] = current.copyWith(
        quantity: current.quantity + 1,
      );
    } else {
      _ticketItems.insert(
        0,
        OrderItem(
          id: _uuid.v4(),
          productId: product.id,
          name: product.name,
          description: product.description,
          notes: customNotes ?? product.description,
          unitPrice: product.price,
          quantity: 1,
          imageUrl: product.imageUrl,
          localImagePath: product.localImagePath,
          imageBase64: product.imageBase64,
        ),
      );
    }
    notifyListeners();
  }

  void addFreeSaleItem({
    required String name,
    required double price,
    String notes = 'Preparación especial',
    int quantity = 1,
  }) {
    _ticketItems.insert(
      0,
      OrderItem(
        id: _uuid.v4(),
        productId: 'free_${DateTime.now().millisecondsSinceEpoch}',
        name: name.toUpperCase(),
        description: notes,
        notes: notes,
        unitPrice: price,
        quantity: quantity,
      ),
    );
    notifyListeners();
  }

  void incrementTicketItem(String itemId) {
    final idx = _ticketItems.indexWhere((e) => e.id == itemId);
    if (idx < 0) return;
    final item = _ticketItems[idx];
    _ticketItems[idx] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
  }

  void decrementTicketItem(String itemId) {
    final idx = _ticketItems.indexWhere((e) => e.id == itemId);
    if (idx < 0) return;
    final item = _ticketItems[idx];
    if (item.quantity <= 1) {
      _ticketItems.removeAt(idx);
    } else {
      _ticketItems[idx] = item.copyWith(quantity: item.quantity - 1);
    }
    notifyListeners();
  }

  void updateTicketItemNotes(String itemId, String notes) {
    final idx = _ticketItems.indexWhere((e) => e.id == itemId);
    if (idx < 0) return;
    _ticketItems[idx] = _ticketItems[idx].copyWith(notes: notes.trim());
    notifyListeners();
  }

  void removeTicketItem(String itemId) {
    _ticketItems.removeWhere((e) => e.id == itemId);
    notifyListeners();
  }

  void clearTicket() {
    _ticketItems.clear();
    _discountPercent = 0.0;
    _fixedDiscount = 0.0;
    _selectedCashTendered = null;
    notifyListeners();
  }

  void applyDiscount({
    double percent = 0.0,
    double fixedAmount = 0.0,
    String label = 'DESCUENTO PROMO',
  }) {
    _discountPercent = percent;
    _fixedDiscount = fixedAmount;
    _discountLabel = label.toUpperCase();
    notifyListeners();
  }

  void selectQuickCash(double? amount) {
    _selectedCashTendered = amount;
    notifyListeners();
  }

  void saveCurrentTicketAsDraft() {
    if (_ticketItems.isEmpty) return;
    final draft = PosOrder(
      id: _uuid.v4(),
      orderNumber: _nextOrderNumber,
      tableOrLocation: _currentOrderType.label,
      customerName: _currentCustomerName,
      cashierName: _cashierName,
      orderType: _currentOrderType,
      status: OrderStatus.pending,
      paymentMethod: PaymentMethod.cash,
      items: List.from(_ticketItems),
      subtotal: ticketSubtotal,
      discount: ticketDiscount,
      discountLabel: _discountLabel,
      tax: 0.0,
      total: ticketGrandTotal,
      createdAt: DateTime.now(),
    );
    _savedDrafts.insert(0, draft);
    clearTicket();
    notifyListeners();
  }

  void restoreDraftToTicket(PosOrder draft) {
    _ticketItems = List.from(draft.items);
    _currentOrderType = draft.orderType;
    _currentTableOrLocation = draft.orderType.label;
    _currentCustomerName = draft.customerName;
    _savedDrafts.removeWhere((d) => d.id == draft.id);
    notifyListeners();
  }

  // ==================== CHECKOUT & SEND ORDER TO CLIENT ====================

  Future<PosOrder?> completeCheckout({
    required PaymentMethod paymentMethod,
    double? amountTendered,
  }) async {
    if (_ticketItems.isEmpty) return null;

    final total = ticketGrandTotal;
    final tendered = amountTendered ?? _selectedCashTendered ?? total;
    final change = (tendered - total).clamp(0.0, double.infinity);

    final newOrder = PosOrder(
      id: _uuid.v4(),
      orderNumber: _nextOrderNumber,
      tableOrLocation: _currentOrderType.label,
      customerName: _currentCustomerName,
      cashierName: _cashierName,
      orderType: _currentOrderType,
      status: OrderStatus.pending,
      paymentMethod: paymentMethod,
      items: List.from(_ticketItems),
      subtotal: ticketSubtotal,
      discount: ticketDiscount,
      discountLabel: _discountLabel,
      tax: 0.0,
      total: total,
      amountTendered: tendered,
      changeAmount: change,
      createdAt: DateTime.now(),
    );

    _orders.insert(0, newOrder);
    _nextOrderNumber++;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsNextOrderNumKey, _nextOrderNumber);
    await _saveOrdersToStorage();

    // Broadcast immediately to all connected Kitchen / Client screens on LAN!
    lanService.broadcastNewOrder(newOrder);

    clearTicket();
    notifyListeners();
    return newOrder;
  }

  // ==================== ORDER STATUS & ITEM PREPARATION SYNC ====================

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;

    final current = _orders[idx];
    final now = DateTime.now();

    final updatedItems = (newStatus == OrderStatus.ready ||
            newStatus == OrderStatus.completed)
        ? current.items.map((i) => i.copyWith(isPrepared: true)).toList()
        : current.items;

    final updated = current.copyWith(
      status: newStatus,
      items: updatedItems,
      preparingAt: newStatus == OrderStatus.preparing
          ? (current.preparingAt ?? now)
          : current.preparingAt,
      readyAt: newStatus == OrderStatus.ready
          ? (current.readyAt ?? now)
          : current.readyAt,
      completedAt: newStatus == OrderStatus.completed
          ? (current.completedAt ?? now)
          : current.completedAt,
    );

    _orders[idx] = updated;
    if (_latestIncomingOrderAlert?.id == orderId) {
      _latestIncomingOrderAlert = null;
    }

    if (_appMode == AppMode.server) {
      await _saveOrdersToStorage();
      lanService.broadcastOrderUpdate(updated);
    } else if (_appMode == AppMode.client) {
      await lanService.sendOrderUpdateFromClient(updated);
    }

    notifyListeners();
  }

  Future<void> toggleOrderItemPrepared(String orderId, String itemId) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;

    final current = _orders[idx];
    final updatedItems = current.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isPrepared: !item.isPrepared);
      }
      return item;
    }).toList();

    OrderStatus nextStatus = current.status;
    DateTime? prepTime = current.preparingAt;
    if (current.status == OrderStatus.pending &&
        updatedItems.any((i) => i.isPrepared)) {
      nextStatus = OrderStatus.preparing;
      prepTime = DateTime.now();
    }

    final updated = current.copyWith(
      items: updatedItems,
      status: nextStatus,
      preparingAt: prepTime,
    );

    _orders[idx] = updated;

    if (_appMode == AppMode.server) {
      await _saveOrdersToStorage();
      lanService.broadcastOrderUpdate(updated);
    } else if (_appMode == AppMode.client) {
      await lanService.sendOrderUpdateFromClient(updated);
    }

    notifyListeners();
  }

  // ==================== PRODUCT CRUD & LOCAL IMAGES (ANDROID + DESKTOP) ====================

  /// Picks an image from the device (using native Android Photo Picker / Gallery or FilePicker),
  /// saves a local copy in the app's persistent directory, and encodes it in Base64.
  Future<({String localPath, String base64Data})?>
      pickAndSaveLocalProductImage() async {
    try {
      Uint8List? bytes;
      String ext = 'jpg';

      // On Android / iOS, use ImagePicker for native gallery photo selection & automatic resizing
      if (Platform.isAndroid || Platform.isIOS) {
        final XFile? pickedImage = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 900,
          maxHeight: 900,
          imageQuality: 82,
        );
        if (pickedImage != null) {
          bytes = await pickedImage.readAsBytes();
          final pathParts = pickedImage.path.split('.');
          if (pathParts.length > 1) {
            ext = pathParts.last.toLowerCase();
          }
        }
      }

      // Fallback or Desktop FilePicker
      if (bytes == null || bytes.isEmpty) {
        final files = await FilePicker.pickFiles(
          type: FileType.image,
        );
        if (files.isEmpty) return null;
        final pickedFile = files.first;
        bytes = await pickedFile.xFile.readAsBytes();
        if (bytes.isEmpty && pickedFile.path != null) {
          bytes = await File(pickedFile.path!).readAsBytes();
        }
        ext = (pickedFile.extension ?? 'png').toLowerCase();
      }

      if (bytes.isEmpty) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/pos_product_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedFile = File('${imagesDir.path}/$fileName');
      await savedFile.writeAsBytes(bytes, flush: true);

      final base64Str = base64Encode(bytes);
      return (localPath: savedFile.path, base64Data: base64Str);
    } catch (e) {
      debugPrint('Error picking local image: $e');
      return null;
    }
  }

  Future<void> addOrUpdateProduct(Product product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _products[idx] = product;
    } else {
      _products.insert(0, product);
    }
    await _saveCatalogToStorage();
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
    await _saveCatalogToStorage();
    notifyListeners();
  }

  Future<void> clearAllProducts() async {
    _products.clear();
    await _saveCatalogToStorage();
    notifyListeners();
  }

  Future<void> restoreDefaultCatalog() async {
    _categories = List.from(DefaultCatalog.defaultCategories);
    _products = List.from(DefaultCatalog.defaultProducts);
    await _saveCatalogToStorage();
    notifyListeners();
  }

  // ==================== EXPORT / IMPORT BACKUP (ANDROID SAF + DESKTOP SAFE) ====================

  /// Exports all products and embedded Base64 local images to a JSON file
  Future<String?> exportCatalogBackup() async {
    try {
      final exportedProducts = <Map<String, dynamic>>[];
      for (final p in _products) {
        String? b64 = p.imageBase64;
        if ((b64 == null || b64.isEmpty) &&
            p.localImagePath != null &&
            p.localImagePath!.isNotEmpty) {
          final file = File(p.localImagePath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            b64 = base64Encode(bytes);
          }
        }
        exportedProducts
            .add(p.copyWith(imageBase64: b64).toJson(includeBase64: true));
      }

      final backupPayload = {
        'app': 'DOGOS_EL_PA_POS',
        'version': '2.4',
        'exportedAt': DateTime.now().toIso8601String(),
        'storeName': _storeName,
        'categories': _categories.map((c) => c.toJson()).toList(),
        'products': exportedProducts,
      };

      final jsonString =
          const JsonEncoder.withIndent('  ').convert(backupPayload);

      final defaultFileName =
          'respaldo_dogos_el_pa_${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}_${DateTime.now().day.toString().padLeft(2, '0')}.json';

      final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));
      final Uri? outputUri = await FilePicker.saveFile(
        dialogTitle: 'Exportar Respaldo de Productos (JSON con Imágenes)',
        fileName: defaultFileName,
        bytes: jsonBytes,
      );

      if (outputUri == null) {
        return null;
      }

      // On Android, FilePicker.saveFile writes bytes directly to the content:// URI!
      if (outputUri.scheme == 'file') {
        String outputPath = outputUri.toFilePath();
        if (!outputPath.toLowerCase().endsWith('.json')) {
          outputPath = '$outputPath.json';
        }
        final outFile = File(outputPath);
        if (!await outFile.exists()) {
          await outFile.writeAsBytes(jsonBytes, flush: true);
        }
        return outFile.path;
      }

      return defaultFileName;
    } catch (e) {
      debugPrint('Error exporting catalog: $e');
      return null;
    }
  }

  /// Imports products from a backup JSON file, reconstructing local image files
  Future<({bool success, int count, String message})> importCatalogBackup({
    bool replaceExisting = false,
  }) async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Seleccionar Archivo de Respaldo (.json)',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isEmpty) {
        return (
          success: false,
          count: 0,
          message: 'Importación cancelada.',
        );
      }

      final picked = files.first;
      String rawContent = await picked.xFile.readAsString();
      if (rawContent.isEmpty && picked.path != null) {
        rawContent = await File(picked.path!).readAsString();
      }
      if (rawContent.isEmpty) {
        return (
          success: false,
          count: 0,
          message: 'No se pudo leer el archivo seleccionado.',
        );
      }

      final decoded = jsonDecode(rawContent) as Map<String, dynamic>;
      final rawProducts = decoded['products'] as List?;
      if (rawProducts == null) {
        return (
          success: false,
          count: 0,
          message: 'El archivo JSON no contiene una lista válida de productos.',
        );
      }

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/pos_product_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final allowedCatIds = {'dogos', 'papas', 'combos'};
      final importedProducts = <Product>[];

      for (final item in rawProducts) {
        var prod = Product.fromJson(Map<String, dynamic>.from(item as Map));
        // Normalize category to dogos, papas, or combos
        if (!allowedCatIds.contains(prod.categoryId)) {
          prod = prod.copyWith(categoryId: 'dogos');
        }

        if (prod.imageBase64 != null && prod.imageBase64!.isNotEmpty) {
          try {
            final bytes = base64Decode(prod.imageBase64!);
            final restoredFile = File(
              '${imagesDir.path}/restored_${prod.id}_${DateTime.now().millisecondsSinceEpoch}.png',
            );
            await restoredFile.writeAsBytes(bytes, flush: true);
            prod = prod.copyWith(localImagePath: restoredFile.path);
          } catch (_) {}
        }
        importedProducts.add(prod);
      }

      if (replaceExisting) {
        _products = importedProducts;
      } else {
        for (final imp in importedProducts) {
          final existingIdx = _products.indexWhere((p) => p.id == imp.id);
          if (existingIdx >= 0) {
            _products[existingIdx] = imp;
          } else {
            _products.add(imp);
          }
        }
      }

      await _saveCatalogToStorage();
      notifyListeners();
      return (
        success: true,
        count: importedProducts.length,
        message:
            '¡Se importaron ${importedProducts.length} productos exitosamente con sus imágenes!',
      );
    } catch (e) {
      debugPrint('Error importing catalog: $e');
      return (
        success: false,
        count: 0,
        message: 'Error al importar el archivo: $e',
      );
    }
  }

  // ==================== SETTINGS & STORAGE PERSISTENCE ====================

  Future<void> updateTerminalSettings({
    String? storeName,
    String? cashierName,
    String? shiftLabel,
    int? port,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (storeName != null && storeName.trim().isNotEmpty) {
      _storeName = storeName.trim().toUpperCase();
      await prefs.setString(_prefsStoreNameKey, _storeName);
    }
    if (cashierName != null && cashierName.trim().isNotEmpty) {
      _cashierName = cashierName.trim().toUpperCase();
      await prefs.setString(_prefsCashierNameKey, _cashierName);
    }
    if (shiftLabel != null && shiftLabel.trim().isNotEmpty) {
      _shiftLabel = shiftLabel.trim().toUpperCase();
    }
    if (port != null &&
        port > 1024 &&
        port < 65535 &&
        port != _configuredPort) {
      _configuredPort = port;
      await prefs.setInt(_prefsServerPortKey, _configuredPort);
      if (_appMode == AppMode.server) {
        await lanService.startServer(
          port: _configuredPort,
          serverName: _storeName,
        );
      }
    }
    notifyListeners();
  }

  Future<void> clearCompletedOrdersHistory() async {
    _orders.removeWhere(
      (o) =>
          o.status == OrderStatus.completed ||
          o.status == OrderStatus.cancelled,
    );
    await _saveOrdersToStorage();
    lanService.broadcastFullSync(_orders);
    notifyListeners();
  }

  Future<void> _saveCatalogToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsCategoriesKey,
        jsonEncode(_categories.map((c) => c.toJson()).toList()),
      );
      await prefs.setString(
        _prefsProductsKey,
        jsonEncode(_products.map((p) => p.toJson(includeBase64: true)).toList()),
      );
    } catch (e) {
      debugPrint('Error saving catalog to prefs: $e');
    }
  }

  Future<void> _saveOrdersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = _orders.take(150).toList();
      await prefs.setString(
        _prefsOrdersKey,
        jsonEncode(trimmed.map((o) => o.toJson(includeBase64: false)).toList()),
      );
    } catch (e) {
      debugPrint('Error saving orders to prefs: $e');
    }
  }

  @override
  void dispose() {
    lanService.dispose();
    super.dispose();
  }
}
