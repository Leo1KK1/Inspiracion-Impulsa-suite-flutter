import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/pos_models.dart';

abstract interface class PosRepository {
  Future<CashShift> openShift({required double openingAmount, String? notes});
  Future<CashShift> getActiveShift();
  Future<List<CashShift>> getShifts();
  Future<CashShift> closeShift(
    String shiftId, {
    required double closingAmount,
    String? notes,
  });
  Future<CashShiftSummary> getShiftSummary(String shiftId);
  Future<List<PosProduct>> searchProducts(String query);
  Future<PosProduct> getProduct(String productId);
  Future<PosSale> createSale(CreatePosSaleRequest request);
  Future<PosSale> getSale(String saleId);
  Future<List<PosTicket>> getTickets({String? cashShiftId});
  Future<PosTicket> getTicket(String ticketId);
  Future<CardPaymentIntent> createCardIntent({
    required String saleId,
    required double amount,
  });
  Future<void> confirmCardIntent({
    required String intentId,
    required String gatewayRef,
  });
}

class HttpPosRepository implements PosRepository {
  HttpPosRepository(this._client);

  final DioClient _client;
  static const _base = '/api/v1/tenant/pos';

  @override
  Future<CashShift> openShift({
    required double openingAmount,
    String? notes,
  }) async => CashShift.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_base/cash-shifts/open',
        data: {
          'openingAmount': openingAmount,
          if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
        },
      ),
    ),
  );

  @override
  Future<CashShift> getActiveShift() async => CashShift.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>('$_base/cash-shifts/active'),
    ),
  );

  @override
  Future<List<CashShift>> getShifts() async => _objects(
    await _requestList(() => _client.dio.get<Object?>('$_base/cash-shifts')),
    CashShift.fromJson,
  );

  @override
  Future<CashShift> closeShift(
    String shiftId, {
    required double closingAmount,
    String? notes,
  }) async => CashShift.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_base/cash-shifts/$shiftId/close',
        data: {
          'closingAmount': closingAmount,
          if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
        },
      ),
    ),
  );

  @override
  Future<CashShiftSummary> getShiftSummary(String shiftId) async =>
      CashShiftSummary.fromJson(
        await _requestMap(
          () => _client.dio.get<Object?>('$_base/cash-shifts/$shiftId/summary'),
        ),
      );

  @override
  Future<List<PosProduct>> searchProducts(String query) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_base/products/search',
        queryParameters: {'q': query.trim()},
      ),
    ),
    PosProduct.fromJson,
  );

  @override
  Future<PosProduct> getProduct(String productId) async => PosProduct.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>('$_base/products/$productId'),
    ),
  );

  @override
  Future<PosSale> createSale(CreatePosSaleRequest request) async =>
      PosSale.fromJson(
        await _requestMap(
          () =>
              _client.dio.post<Object?>('$_base/sales', data: request.toJson()),
        ),
      );

  @override
  Future<PosSale> getSale(String saleId) async => PosSale.fromJson(
    await _requestMap(() => _client.dio.get<Object?>('$_base/sales/$saleId')),
  );

  @override
  Future<List<PosTicket>> getTickets({String? cashShiftId}) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_base/tickets',
        queryParameters: {
          if (cashShiftId?.isNotEmpty == true) 'cashShiftId': cashShiftId,
        },
      ),
    ),
    PosSale.fromJson,
  );

  @override
  Future<PosTicket> getTicket(String ticketId) async => PosSale.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>('$_base/tickets/$ticketId'),
    ),
  );

  @override
  Future<CardPaymentIntent> createCardIntent({
    required String saleId,
    required double amount,
  }) async => CardPaymentIntent.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_base/payments/card-intents',
        data: {'saleId': saleId, 'amount': amount},
      ),
    ),
  );

  @override
  Future<void> confirmCardIntent({
    required String intentId,
    required String gatewayRef,
  }) => _requestVoid(
    () => _client.dio.post<Object?>(
      '$_base/payments/card-intents/$intentId/confirm',
      data: {'gatewayRef': gatewayRef},
    ),
  );

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
