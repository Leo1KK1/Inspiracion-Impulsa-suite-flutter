import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/inventory_models.dart';

abstract interface class InventoryRepository {
  Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
    String? status,
  });
  Future<Product> getProduct(String productId);
  Future<List<InventoryCategory>> getCategories();
  Future<List<InventoryItem>> getBranchInventory(String branchId);
  Future<List<InventoryItem>> getAlerts({String? branchId});
  Future<List<InventoryMovement>> getMovements(String branchId);
  Future<void> createCategory(Map<String, Object?> payload);
  Future<void> updateCategory(String id, Map<String, Object?> payload);
  Future<void> changeCategoryStatus(String id, bool isActive);
  Future<void> createProduct(Map<String, Object?> payload);
  Future<void> updateProduct(String id, Map<String, Object?> payload);
  Future<void> changeProductStatus(String id, String status);
  Future<void> deleteProductImage(String productId, String imageId);
  Future<void> adjustStock(String branchId, Map<String, Object?> payload);
  Future<void> updateMinStock(String branchId, Map<String, Object?> payload);
  Future<void> reserveStock(String branchId, Map<String, Object?> payload);
}

class HttpInventoryRepository implements InventoryRepository {
  HttpInventoryRepository(this._client);

  final DioClient _client;
  static const _catalog = '/api/v1/tenant/catalog';
  static const _inventory = '/api/v1/tenant/inventory';

  @override
  Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
    String? status,
  }) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_catalog/products',
        queryParameters: {
          if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
          if (categoryId?.isNotEmpty == true) 'categoryId': categoryId,
          if (status?.isNotEmpty == true) 'status': status,
        },
      ),
    ),
    Product.fromJson,
  );

  @override
  Future<Product> getProduct(String productId) async => Product.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>('$_catalog/products/$productId'),
    ),
  );

  @override
  Future<List<InventoryCategory>> getCategories() async => _objects(
    await _requestList(() => _client.dio.get<Object?>('$_catalog/categories')),
    InventoryCategory.fromJson,
  );

  @override
  Future<List<InventoryItem>> getBranchInventory(String branchId) async =>
      _objects(
        await _requestList(
          () =>
              _client.dio.get<Object?>('$_inventory/branches/$branchId/items'),
        ),
        InventoryItem.fromJson,
      );

  @override
  Future<List<InventoryItem>> getAlerts({String? branchId}) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_inventory/alerts/low-stock',
        queryParameters: {'branchId': ?branchId},
      ),
    ),
    InventoryItem.fromJson,
  );

  @override
  Future<List<InventoryMovement>> getMovements(String branchId) async =>
      _objects(
        await _requestList(
          () => _client.dio.get<Object?>(
            '$_inventory/movements',
            options: _branchOptions(branchId),
          ),
        ),
        InventoryMovement.fromJson,
      );

  @override
  Future<void> createCategory(Map<String, Object?> payload) => _requestVoid(
    () => _client.dio.post<Object?>('$_catalog/categories', data: payload),
  );

  @override
  Future<void> updateCategory(String id, Map<String, Object?> payload) =>
      _requestVoid(
        () => _client.dio.patch<Object?>(
          '$_catalog/categories/$id',
          data: payload,
        ),
      );

  @override
  Future<void> changeCategoryStatus(String id, bool isActive) => _requestVoid(
    () => _client.dio.patch<Object?>(
      '$_catalog/categories/$id/is-active',
      data: {'isActive': isActive},
    ),
  );

  @override
  Future<void> createProduct(Map<String, Object?> payload) => _requestVoid(
    () => _client.dio.post<Object?>('$_catalog/products', data: payload),
  );

  @override
  Future<void> updateProduct(String id, Map<String, Object?> payload) =>
      _requestVoid(
        () =>
            _client.dio.patch<Object?>('$_catalog/products/$id', data: payload),
      );

  @override
  Future<void> changeProductStatus(String id, String status) => _requestVoid(
    () => _client.dio.patch<Object?>(
      '$_catalog/products/$id/status',
      data: {'status': status},
    ),
  );

  @override
  Future<void> deleteProductImage(String productId, String imageId) =>
      _requestVoid(
        () => _client.dio.delete<Object?>(
          '$_catalog/products/$productId/images/$imageId',
        ),
      );

  @override
  Future<void> adjustStock(String branchId, Map<String, Object?> payload) =>
      _requestVoid(
        () => _client.dio.post<Object?>(
          '$_inventory/adjustments',
          data: payload,
          options: _branchOptions(branchId),
        ),
      );

  @override
  Future<void> updateMinStock(String branchId, Map<String, Object?> payload) =>
      _requestVoid(
        () => _client.dio.patch<Object?>(
          '$_inventory/min-stock',
          data: payload,
          options: _branchOptions(branchId),
        ),
      );

  @override
  Future<void> reserveStock(String branchId, Map<String, Object?> payload) =>
      _requestVoid(
        () => _client.dio.post<Object?>(
          '$_inventory/reservations',
          data: payload,
          options: _branchOptions(branchId),
        ),
      );

  Options _branchOptions(String branchId) =>
      Options(headers: {'x-branch-id': branchId});

  Future<Map<String, Object?>> _requestMap(
    Future<Response<Object?>> Function() request,
  ) async {
    final data = await _requestData(request);
    if (data is! Map) throw _invalidResponse;
    return data.cast<String, Object?>();
  }

  Future<List<Object?>> _requestList(
    Future<Response<Object?>> Function() request,
  ) async {
    final data = await _requestData(request);
    if (data is! List) throw _invalidResponse;
    return data.cast<Object?>();
  }

  Future<void> _requestVoid(
    Future<Response<Object?>> Function() request,
  ) async {
    await _requestData(request);
  }

  Future<Object?> _requestData(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      final envelope = response.data;
      if (envelope is! Map || envelope['success'] != true) {
        throw _invalidResponse;
      }
      return envelope['data'];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static List<T> _objects<T>(
    List<Object?> values,
    T Function(Map<String, Object?> json) factory,
  ) => values
      .whereType<Map>()
      .map((value) => factory(value.cast<String, Object?>()))
      .toList(growable: false);

  static const _invalidResponse = ApiException(
    'El servidor devolvió una respuesta no válida.',
  );
}
