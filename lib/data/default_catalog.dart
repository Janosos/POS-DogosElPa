import '../models/pos_models.dart';

class DefaultCatalog {
  static const List<ProductCategory> defaultCategories = [
    ProductCategory(id: 'todos', name: 'TODOS', emoji: '🔥'),
    ProductCategory(id: 'dogos', name: 'DOGOS', emoji: '🌭'),
    ProductCategory(id: 'papas', name: 'PAPAS', emoji: '🍟'),
    ProductCategory(id: 'combos', name: 'COMBOS', emoji: '⚡'),
  ];

  static const List<Product> defaultProducts = [
    // DOGOS
    Product(
      id: 'prod_dogo_especial',
      name: 'DOGO ESPECIAL EL PA',
      description: 'Salchicha jumbo con tocino, queso fundido y cebolla asada',
      price: 55.00,
      categoryId: 'dogos',
      sku: 'DOGO-001',
      badgeText: '★ ¡TOP VENTAS!',
      badgeColorHex: '#ff5a1f',
      imageUrl:
          'https://images.unsplash.com/photo-1619740455993-9e612b1af08a?auto=format&fit=crop&w=600&q=80',
    ),
    Product(
      id: 'prod_dogo_clasico',
      name: 'DOGO CLÁSICO CON TOCINO',
      description: 'Pan artesanal suave, salchicha con tocino, tomate, cebolla y mayo',
      price: 45.00,
      categoryId: 'dogos',
      sku: 'DOGO-002',
      badgeText: '🌭 CLÁSICO',
      badgeColorHex: '#ffcb11',
      imageUrl:
          'https://images.unsplash.com/photo-1541214113241-21578d2d9b62?auto=format&fit=crop&w=600&q=80',
    ),
    Product(
      id: 'prod_dogo_doble_queso',
      name: 'DOGO CHILI & CHEDDAR',
      description: 'Doble queso cheddar, carne chili, jalapeños y tocino crujiente',
      price: 65.00,
      categoryId: 'dogos',
      sku: 'DOGO-003',
      badgeText: '🔥 ESPECIAL',
      badgeColorHex: '#00b4d8',
      imageUrl:
          'https://images.unsplash.com/photo-1627054235743-2711f11d1178?auto=format&fit=crop&w=600&q=80',
    ),
    // PAPAS
    Product(
      id: 'prod_papas_clasicas',
      name: 'PAPAS FRANCESAS CLÁSICAS',
      description: 'Papas crujientes recién hechas con sal de la casa y aderezos',
      price: 40.00,
      categoryId: 'papas',
      sku: 'PAP-001',
      imageUrl:
          'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=600&q=80',
    ),
    Product(
      id: 'prod_papas_con_tocino',
      name: 'PAPAS CON QUESO Y TOCINO',
      description: 'Bañadas en queso cheddar caliente y trozos de tocino',
      price: 60.00,
      categoryId: 'papas',
      sku: 'PAP-002',
      badgeText: '★ FAVORITAS',
      badgeColorHex: '#ffcb11',
      imageUrl:
          'https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=600&q=80',
    ),
    // COMBOS
    Product(
      id: 'prod_combo_pa_dos',
      name: 'COMBO 2 DOGOS + PAPAS',
      description: '2 Dogos Especiales + Orden de Papas Francesas + Refresco',
      price: 135.00,
      categoryId: 'combos',
      sku: 'CMB-001',
      badgeText: '💥 AHORRO',
      badgeColorHex: '#85f8c4',
      imageUrl:
          'https://images.unsplash.com/photo-1619740455993-9e612b1af08a?auto=format&fit=crop&w=600&q=80',
    ),
    Product(
      id: 'prod_combo_individual',
      name: 'COMBO DOGO + PAPAS',
      description: '1 Dogo Especial El Pa + Papas Francesas + Bebida',
      price: 95.00,
      categoryId: 'combos',
      sku: 'CMB-002',
      badgeText: '⚡ COMBO FLASH',
      badgeColorHex: '#00b4d8',
      imageUrl:
          'https://images.unsplash.com/photo-1541214113241-21578d2d9b62?auto=format&fit=crop&w=600&q=80',
    ),
  ];
}
