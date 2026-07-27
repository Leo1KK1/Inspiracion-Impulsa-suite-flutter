import '../models/inventory_models.dart';

abstract interface class InventoryRepository {
  Future<List<Product>> getProducts({String? branchId});
  Future<List<InventoryCategory>> getCategories();
  Future<List<StockAlert>> getAlerts({String? branchId});
}

class MockInventoryRepository implements InventoryRepository {
  static const products = [
    Product(
      id: 'p001',
      sku: 'BEB-001',
      name: 'Coca-Cola 600ml',
      category: 'Bebidas',
      unit: 'pieza',
      cost: 8.50,
      price: 28,
      stock: 8,
      minStock: 50,
      status: ProductStatus.active,
    ),
    Product(
      id: 'p002',
      sku: 'BEB-002',
      name: 'Agua Ciel 1L',
      category: 'Bebidas',
      unit: 'pieza',
      cost: 5,
      price: 18,
      stock: 142,
      minStock: 80,
      status: ProductStatus.active,
    ),
    Product(
      id: 'p003',
      sku: 'ALI-001',
      name: 'Tomates cherry 1kg',
      category: 'Alimentos',
      unit: 'kg',
      cost: 32,
      price: 65,
      stock: 0,
      minStock: 20,
      status: ProductStatus.active,
    ),
    Product(
      id: 'p004',
      sku: 'ALI-002',
      name: 'Aceite vegetal 5L',
      category: 'Alimentos',
      unit: 'galón',
      cost: 145,
      price: 210,
      stock: 3,
      minStock: 15,
      status: ProductStatus.active,
    ),
    Product(
      id: 'p005',
      sku: 'DES-001',
      name: 'Servilletas 500 pzas',
      category: 'Desechables',
      unit: 'paquete',
      cost: 38,
      price: 65,
      stock: 84,
      minStock: 30,
      status: ProductStatus.active,
    ),
    Product(
      id: 'p006',
      sku: 'DES-002',
      name: 'Vasos desechables 16oz',
      category: 'Desechables',
      unit: 'paquete',
      cost: 55,
      price: 90,
      stock: 22,
      minStock: 40,
      status: ProductStatus.active,
    ),
    Product(
      id: 'p007',
      sku: 'LIM-001',
      name: 'Desinfectante 1L',
      category: 'Limpieza',
      unit: 'litro',
      cost: 18,
      price: 38,
      stock: 64,
      minStock: 20,
      status: ProductStatus.active,
    ),
    Product(
      id: 'p008',
      sku: 'BEB-003',
      name: 'Jugo de naranja 1L',
      category: 'Bebidas',
      unit: 'pieza',
      cost: 22,
      price: 45,
      stock: 38,
      minStock: 30,
      status: ProductStatus.active,
    ),
    Product(
      id: 'p009',
      sku: 'ALI-003',
      name: 'Pollo entero 1.5kg',
      category: 'Alimentos',
      unit: 'kg',
      cost: 68,
      price: 110,
      stock: 18,
      minStock: 25,
      status: ProductStatus.active,
    ),
    Product(
      id: 'p010',
      sku: 'DES-003',
      name: 'Contenedores 500ml',
      category: 'Desechables',
      unit: 'paquete',
      cost: 120,
      price: 185,
      stock: 48,
      minStock: 20,
      status: ProductStatus.inactive,
    ),
  ];

  @override
  Future<List<Product>> getProducts({String? branchId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return products;
  }

  @override
  Future<List<InventoryCategory>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return const [
      InventoryCategory(
        id: 'cat-001',
        name: 'Bebidas',
        description: 'Refrescos, aguas, jugos y bebidas alcohólicas',
        productCount: 184,
        colorValue: 0xFF3B82F6,
        subcategories: ['Refrescos', 'Aguas', 'Jugos', 'Alcohólicas'],
      ),
      InventoryCategory(
        id: 'cat-002',
        name: 'Alimentos',
        description: 'Ingredientes, proteínas, vegetales y abarrotes',
        productCount: 312,
        colorValue: 0xFFF97316,
        subcategories: ['Carnes', 'Verduras', 'Abarrotes', 'Lácteos'],
      ),
      InventoryCategory(
        id: 'cat-003',
        name: 'Desechables',
        description: 'Vasos, platos, cubiertos y empaques para llevar',
        productCount: 98,
        colorValue: 0xFF0D9488,
        subcategories: ['Vasos', 'Platos', 'Cubiertos', 'Empaques'],
      ),
      InventoryCategory(
        id: 'cat-004',
        name: 'Limpieza',
        description: 'Productos de higiene y sanitización del local',
        productCount: 67,
        colorValue: 0xFF8B5CF6,
        subcategories: ['Desinfectantes', 'Jabones', 'Trapos'],
      ),
      InventoryCategory(
        id: 'cat-005',
        name: 'Electrónicos',
        description: 'Equipos de cocina, POS y accesorios',
        productCount: 23,
        colorValue: 0xFF6B7280,
        subcategories: ['Equipos', 'POS', 'Periféricos'],
      ),
      InventoryCategory(
        id: 'cat-006',
        name: 'Uniformes',
        description: 'Ropa y accesorios de trabajo',
        productCount: 41,
        colorValue: 0xFFEC4899,
        subcategories: ['Camisas', 'Delantales', 'Gorras'],
      ),
    ];
  }

  @override
  Future<List<StockAlert>> getAlerts({String? branchId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    const source = products;
    return [
      StockAlert(
        id: 'a01',
        product: source[2],
        maxStock: 60,
        severity: StockSeverity.outOfStock,
        lastMovement: 'Hoy 09:15',
        suggestedOrder: 40,
      ),
      StockAlert(
        id: 'a03',
        product: source[0],
        maxStock: 150,
        severity: StockSeverity.critical,
        lastMovement: 'Hoy 13:22',
        suggestedOrder: 100,
      ),
      StockAlert(
        id: 'a04',
        product: source[3],
        maxStock: 40,
        severity: StockSeverity.critical,
        lastMovement: 'Hoy 11:05',
        suggestedOrder: 30,
      ),
      StockAlert(
        id: 'a05',
        product: source[5],
        maxStock: 120,
        severity: StockSeverity.low,
        lastMovement: 'Ayer 15:12',
        suggestedOrder: 80,
      ),
      StockAlert(
        id: 'a06',
        product: source[8],
        maxStock: 80,
        severity: StockSeverity.low,
        lastMovement: 'Hoy 08:40',
        suggestedOrder: 50,
      ),
    ];
  }
}
