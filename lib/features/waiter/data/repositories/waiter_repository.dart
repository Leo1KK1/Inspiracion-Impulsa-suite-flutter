import '../models/waiter_models.dart';

abstract interface class WaiterRepository {
  Future<List<MenuProduct>> getMenu({String? branchId});
  Future<List<ComandaItem>> getOrderItems(String orderId);
}

class MockWaiterRepository implements WaiterRepository {
  @override
  Future<List<MenuProduct>> getMenu({String? branchId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return const [
      MenuProduct(
        id: 'm01',
        name: 'Guacamole con totopos',
        description: 'Aguacate, jitomate, cebolla morada y cilantro',
        price: 125,
        category: 'Entradas',
        prepMinutes: 5,
        popular: true,
      ),
      MenuProduct(
        id: 'm02',
        name: 'Tostadas de tinga',
        description: 'Pollo, queso cotija, crema y lechuga',
        price: 110,
        category: 'Entradas',
        prepMinutes: 8,
      ),
      MenuProduct(
        id: 'm04',
        name: 'Carpaccio de atún',
        description: 'Atún, alcaparras, limón y aceite de oliva',
        price: 195,
        category: 'Entradas',
        prepMinutes: 7,
        popular: true,
      ),
      MenuProduct(
        id: 'm05',
        name: 'Sopa de lima yucateca',
        description: 'Caldo de pollo, tortilla frita y aguacate',
        price: 95,
        category: 'Sopas',
        prepMinutes: 10,
        popular: true,
      ),
      MenuProduct(
        id: 'm08',
        name: 'Arrachera al carbón',
        description: 'Arrachera 300g, guacamole, tortillas y frijoles',
        price: 290,
        category: 'Platos fuertes',
        prepMinutes: 18,
        popular: true,
      ),
      MenuProduct(
        id: 'm09',
        name: 'Filete de res a la plancha',
        description: 'Filete 250g, puré y salsa chimichurri',
        price: 345,
        category: 'Platos fuertes',
        prepMinutes: 20,
        popular: true,
      ),
      MenuProduct(
        id: 'm10',
        name: 'Costilla BBQ',
        description: 'Costilla de res, elotes y papas gajo',
        price: 285,
        category: 'Platos fuertes',
        prepMinutes: 25,
      ),
      MenuProduct(
        id: 'm12',
        name: 'Mariscos al mojo de ajo',
        description: 'Camarones, pulpo, almeja y arroz',
        price: 320,
        category: 'Especiales',
        prepMinutes: 20,
        popular: true,
      ),
      MenuProduct(
        id: 'm13',
        name: 'Surf & Turf premium',
        description: 'Filete + camarones, papas y ensalada',
        price: 490,
        category: 'Especiales',
        prepMinutes: 22,
        popular: true,
      ),
      MenuProduct(
        id: 'm14',
        name: 'Pastel de tres leches',
        description: 'Pastel húmedo, crema y fresas',
        price: 85,
        category: 'Postres',
        prepMinutes: 3,
        popular: true,
      ),
      MenuProduct(
        id: 'm16',
        name: 'Agua de fruta 1L',
        description: 'Jamaica, horchata o tamarindo',
        price: 65,
        category: 'Bebidas',
        prepMinutes: 2,
      ),
      MenuProduct(
        id: 'm18',
        name: 'Cerveza artesanal',
        description: 'Selección del mes, fría en botella',
        price: 110,
        category: 'Bebidas',
        prepMinutes: 1,
        popular: true,
      ),
    ];
  }

  @override
  Future<List<ComandaItem>> getOrderItems(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const [
      ComandaItem(
        name: 'Filete de res a la plancha',
        quantity: 2,
        station: 'Cocina caliente',
        status: ComandaItemStatus.inPreparation,
        notes: 'Término tres cuartos',
      ),
      ComandaItem(
        name: 'Carpaccio de atún',
        quantity: 1,
        station: 'Cocina fría',
        status: ComandaItemStatus.ready,
      ),
      ComandaItem(
        name: 'Costilla BBQ',
        quantity: 1,
        station: 'Cocina caliente',
        status: ComandaItemStatus.inPreparation,
        notes: 'Sin guarnición',
      ),
      ComandaItem(
        name: 'Copa de vino tinto',
        quantity: 2,
        station: 'Barra',
        status: ComandaItemStatus.served,
        notes: 'Malbec si hay',
      ),
      ComandaItem(
        name: 'Agua mineral 500ml',
        quantity: 2,
        station: 'Barra',
        status: ComandaItemStatus.served,
      ),
    ];
  }
}
