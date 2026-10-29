import 'dart:convert';

enum AppMode {
  unselected,
  server,
  client,
}

enum OrderType {
  dineIn,
  takeaway,
  delivery;

  String get label {
    switch (this) {
      case OrderType.dineIn:
        return 'COMER AQUÍ';
      case OrderType.takeaway:
        return 'LLEVAR';
      case OrderType.delivery:
        return 'DELIVERY';
    }
  }

  static OrderType fromString(String? value) {
    switch (value) {
      case 'takeaway':
        return OrderType.takeaway;
      case 'delivery':
        return OrderType.delivery;
      case 'dineIn':
      default:
        return OrderType.dineIn;
    }
  }
}

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'NUEVA ORDEN';
      case OrderStatus.preparing:
        return 'EN PREPARACIÓN';
      case OrderStatus.ready:
        return '¡LISTA!';
      case OrderStatus.completed:
        return 'ENTREGADA';
      case OrderStatus.cancelled:
        return 'ANULADA';
    }
  }

  static OrderStatus fromString(String? value) {
    switch (value) {
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}

enum PaymentMethod {
  cash,
  card,
  qr,
  account;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'EFECTIVO';
      case PaymentMethod.card:
        return 'TARJETA / NFC';
      case PaymentMethod.qr:
        return 'QR / CODI';
      case PaymentMethod.account:
        return 'CUENTA CLIENTE';
    }
  }

  static PaymentMethod fromString(String? value) {
    switch (value) {
      case 'card':
        return PaymentMethod.card;
      case 'qr':
        return PaymentMethod.qr;
      case 'account':
        return PaymentMethod.account;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }
}

class ProductCategory {
  final String id;
  final String name;
  final String emoji;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.emoji,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
      };

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id']?.toString() ?? 'todos',
      name: json['name']?.toString() ?? 'GENERAL',
      emoji: json['emoji']?.toString() ?? '🔥',
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String sku;
  final String? badgeText;
  final String? badgeColorHex;
  final String? imageUrl;
  final String? localImagePath;
  final String? imageBase64;
  final bool isFavorite;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.sku = '',
    this.badgeText,
    this.badgeColorHex,
    this.imageUrl,
    this.localImagePath,
    this.imageBase64,
    this.isFavorite = false,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? sku,
    String? badgeText,
    bool clearBadge = false,
    String? badgeColorHex,
    String? imageUrl,
    String? localImagePath,
    String? imageBase64,
    bool clearLocalImage = false,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      sku: sku ?? this.sku,
      badgeText: clearBadge ? null : (badgeText ?? this.badgeText),
      badgeColorHex: clearBadge ? null : (badgeColorHex ?? this.badgeColorHex),
      imageUrl: clearLocalImage ? null : (imageUrl ?? this.imageUrl),
      localImagePath:
          clearLocalImage ? null : (localImagePath ?? this.localImagePath),
      imageBase64: clearLocalImage ? null : (imageBase64 ?? this.imageBase64),
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'sku': sku,
        'badgeText': badgeText,
        'badgeColorHex': badgeColorHex,
        'imageUrl': imageUrl,
        'localImagePath': localImagePath,
        if (includeBase64) 'imageBase64': imageBase64,
        'isFavorite': isFavorite,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'Producto',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId']?.toString() ?? 'hotdogs',
      sku: json['sku']?.toString() ?? '',
      badgeText: json['badgeText']?.toString(),
      badgeColorHex: json['badgeColorHex']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      localImagePath: json['localImagePath']?.toString(),
      imageBase64: json['imageBase64']?.toString(),
      isFavorite: json['isFavorite'] == true,
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String name;
  final String description;
  final String notes;
  final double unitPrice;
  final int quantity;
  final bool isPrepared;
  final String? imageUrl;
  final String? localImagePath;
  final String? imageBase64;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.description,
    this.notes = '',
    required this.unitPrice,
    required this.quantity,
    this.isPrepared = false,
    this.imageUrl,
    this.localImagePath,
    this.imageBase64,
  });

  double get total => unitPrice * quantity;

  OrderItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? description,
    String? notes,
    double? unitPrice,
    int? quantity,
    bool? isPrepared,
    String? imageUrl,
    String? localImagePath,
    String? imageBase64,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      isPrepared: isPrepared ?? this.isPrepared,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        'id': id,
        'productId': productId,
        'name': name,
        'description': description,
        'notes': notes,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'isPrepared': isPrepared,
        'imageUrl': imageUrl,
        'localImagePath': localImagePath,
        if (includeBase64) 'imageBase64': imageBase64,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isPrepared: json['isPrepared'] == true,
      imageUrl: json['imageUrl']?.toString(),
      localImagePath: json['localImagePath']?.toString(),
      imageBase64: json['imageBase64']?.toString(),
    );
  }
}

class PosOrder {
  final String id;
  final int orderNumber;
  final String tableOrLocation;
  final String customerName;
  final String cashierName;
  final OrderType orderType;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final String discountLabel;
  final double tax;
  final double total;
  final double amountTendered;
  final double changeAmount;
  final DateTime createdAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;
  final DateTime? completedAt;

  const PosOrder({
    required this.id,
    required this.orderNumber,
    required this.tableOrLocation,
    required this.customerName,
    required this.cashierName,
    required this.orderType,
    required this.status,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.discount,
    this.discountLabel = 'DESCUENTO COMIC PROMO',
    required this.tax,
    required this.total,
    this.amountTendered = 0.0,
    this.changeAmount = 0.0,
    required this.createdAt,
    this.preparingAt,
    this.readyAt,
    this.completedAt,
  });

  int get totalItemsCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  PosOrder copyWith({
    String? id,
    int? orderNumber,
    String? tableOrLocation,
    String? customerName,
    String? cashierName,
    OrderType? orderType,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    List<OrderItem>? items,
    double? subtotal,
    double? discount,
    String? discountLabel,
    double? tax,
    double? total,
    double? amountTendered,
    double? changeAmount,
    DateTime? createdAt,
    DateTime? preparingAt,
    DateTime? readyAt,
    DateTime? completedAt,
  }) {
    return PosOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      tableOrLocation: tableOrLocation ?? this.tableOrLocation,
      customerName: customerName ?? this.customerName,
      cashierName: cashierName ?? this.cashierName,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      discountLabel: discountLabel ?? this.discountLabel,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      amountTendered: amountTendered ?? this.amountTendered,
      changeAmount: changeAmount ?? this.changeAmount,
      createdAt: createdAt ?? this.createdAt,
      preparingAt: preparingAt ?? this.preparingAt,
      readyAt: readyAt ?? this.readyAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        'id': id,
        'orderNumber': orderNumber,
        'tableOrLocation': tableOrLocation,
        'customerName': customerName,
        'cashierName': cashierName,
        'orderType': orderType.name,
        'status': status.name,
        'paymentMethod': paymentMethod.name,
        'items':
            items.map((e) => e.toJson(includeBase64: includeBase64)).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'discountLabel': discountLabel,
        'tax': tax,
        'total': total,
        'amountTendered': amountTendered,
        'changeAmount': changeAmount,
        'createdAt': createdAt.toIso8601String(),
        'preparingAt': preparingAt?.toIso8601String(),
        'readyAt': readyAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory PosOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? [];
    return PosOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: (json['orderNumber'] as num?)?.toInt() ?? 1001,
      tableOrLocation:
          json['tableOrLocation']?.toString() ?? 'MESA 08 · SALÓN PRINCIPAL',
      customerName: json['customerName']?.toString() ?? 'CLIENTE GENERAL',
      cashierName: json['cashierName']?.toString() ?? 'CARLOS R.',
      orderType: OrderType.fromString(json['orderType']?.toString()),
      status: OrderStatus.fromString(json['status']?.toString()),
      paymentMethod:
          PaymentMethod.fromString(json['paymentMethod']?.toString()),
      items: rawItems
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountLabel:
          json['discountLabel']?.toString() ?? 'DESCUENTO COMIC PROMO',
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      amountTendered: (json['amountTendered'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      preparingAt: json['preparingAt'] != null
          ? DateTime.tryParse(json['preparingAt'].toString())
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.tryParse(json['readyAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

