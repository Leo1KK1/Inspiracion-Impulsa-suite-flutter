import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/purchasing_models.dart';

abstract interface class PurchasingRepository {
  Future<List<PurchaseOrder>> getOrders({String? branchId, String? status});
  Future<PurchaseOrder> getOrder(String orderId);
  Future<List<Supplier>> getSuppliers();
  Future<void> createSupplier(Map<String, Object?> payload);
  Future<void> updateSupplier(String id, Map<String, Object?> payload);
  Future<void> createOrder(String branchId, Map<String, Object?> payload);
  Future<void> updateOrder(String id, Map<String, Object?> payload);
  Future<void> submitOrder(String id);
  Future<void> receiveOrder(
    String id,
    String branchId,
    Map<String, Object?> payload,
  );
  Future<void> cancelOrder(String id);
}

class HttpPurchasingRepository implements PurchasingRepository {
  HttpPurchasingRepository(this._client);

  static const _base = '/api/v1/tenant/purchasing';
  final DioClient _client;

  @override
  Future<List<PurchaseOrder>> getOrders({
    String? branchId,
    String? status,
  }) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_base/purchase-orders',
        queryParameters: {'branchId': ?branchId, 'status': ?status},
      ),
    ),
    PurchaseOrder.fromJson,
  );

  @override
  Future<PurchaseOrder> getOrder(String orderId) async =>
      PurchaseOrder.fromJson(
        await _requestMap(
          () => _client.dio.get<Object?>('$_base/purchase-orders/$orderId'),
        ),
      );

  @override
  Future<List<Supplier>> getSuppliers() async => _objects(
    await _requestList(() => _client.dio.get<Object?>('$_base/suppliers')),
    Supplier.fromJson,
  );

  @override
  Future<void> createSupplier(Map<String, Object?> payload) => _requestVoid(
    () => _client.dio.post<Object?>('$_base/suppliers', data: payload),
  );

  @override
  Future<void> updateSupplier(String id, Map<String, Object?> payload) =>
      _requestVoid(
        () => _client.dio.patch<Object?>('$_base/suppliers/$id', data: payload),
      );

  @override
  Future<void> createOrder(String branchId, Map<String, Object?> payload) =>
      _requestVoid(
        () => _client.dio.post<Object?>(
          '$_base/purchase-orders',
          data: payload,
          options: _branch(branchId),
        ),
      );

  @override
  Future<void> updateOrder(String id, Map<String, Object?> payload) =>
      _requestVoid(
        () => _client.dio.patch<Object?>(
          '$_base/purchase-orders/$id',
          data: payload,
        ),
      );

  @override
  Future<void> submitOrder(String id) => _requestVoid(
    () => _client.dio.post<Object?>('$_base/purchase-orders/$id/submit'),
  );

  @override
  Future<void> receiveOrder(
    String id,
    String branchId,
    Map<String, Object?> payload,
  ) => _requestVoid(
    () => _client.dio.post<Object?>(
      '$_base/purchase-orders/$id/receive',
      data: payload,
      options: _branch(branchId),
    ),
  );

  @override
  Future<void> cancelOrder(String id) => _requestVoid(
    () => _client.dio.post<Object?>('$_base/purchase-orders/$id/cancel'),
  );

  Options _branch(String id) => Options(headers: {'x-branch-id': id});

  Future<Map<String, Object?>> _requestMap(
    Future<Response<Object?>> Function() request,
  ) async {
    final data = await _requestData(request);
    if (data is! Map) throw _invalid;
    return data.cast<String, Object?>();
  }

  Future<List<Object?>> _requestList(
    Future<Response<Object?>> Function() request,
  ) async {
    final data = await _requestData(request);
    if (data is! List) throw _invalid;
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
      if (envelope is! Map || envelope['success'] != true) throw _invalid;
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

  static const _invalid = ApiException(
    'El servidor devolvió una respuesta no válida.',
  );
}
