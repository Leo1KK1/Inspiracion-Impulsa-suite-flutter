import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/finance_models.dart';

class ExpenseQuery {
  const ExpenseQuery({
    this.from,
    this.to,
    this.categoryId,
    this.branchId,
    this.status,
    this.limit = 200,
    this.offset = 0,
  });

  final DateTime? from;
  final DateTime? to;
  final String? categoryId;
  final String? branchId;
  final ExpenseStatus? status;
  final int limit;
  final int offset;

  Map<String, Object?> toQuery() => {
    if (from != null) 'from': _dateOnly(from!),
    if (to != null) 'to': _dateOnly(to!),
    if (categoryId?.isNotEmpty == true) 'categoryId': categoryId,
    if (branchId?.isNotEmpty == true) 'branchId': branchId,
    if (status != null) 'status': status!.apiValue,
    'limit': limit,
    'offset': offset,
  };
}

abstract interface class FinanceRepository {
  Future<List<ExpenseCategory>> getCategories({CancelToken? cancelToken});
  Future<ExpenseCategory> createCategory(ExpenseCategoryMutation mutation);
  Future<ExpenseCategory> updateCategory(
    String categoryId,
    ExpenseCategoryMutation mutation,
  );
  Future<List<Expense>> getExpenses(
    ExpenseQuery query, {
    CancelToken? cancelToken,
  });
  Future<Expense> getExpense(String expenseId);
  Future<Expense> createExpense(
    ExpenseMutation mutation, {
    required bool includeBranch,
  });
  Future<Expense> updateExpense(
    String expenseId,
    ExpenseMutation mutation, {
    required bool includeBranch,
  });
  Future<Expense> cancelExpense(String expenseId);
  Future<FinancialSummary> getSummary({
    required DateTime from,
    required DateTime to,
    String? branchId,
    CancelToken? cancelToken,
  });
  Future<SalesVsExpensesReport> getSalesVsExpenses({
    required DateTime from,
    required DateTime to,
    String? branchId,
    CancelToken? cancelToken,
  });
  Future<NetProfitReport> getNetProfit({
    required DateTime from,
    required DateTime to,
    String? branchId,
    CancelToken? cancelToken,
  });
  Future<BranchComparisonReport> getBranchComparison({
    required DateTime from,
    required DateTime to,
    CancelToken? cancelToken,
  });
}

class HttpFinanceRepository implements FinanceRepository {
  HttpFinanceRepository(this._client);

  final DioClient _client;
  static const _finance = '/api/v1/tenant/finance';
  static const _analytics = '/api/v1/tenant/analytics/dashboard';

  @override
  Future<List<ExpenseCategory>> getCategories({
    CancelToken? cancelToken,
  }) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_finance/expense-categories',
        cancelToken: cancelToken,
      ),
    ),
    ExpenseCategory.fromJson,
  );

  @override
  Future<ExpenseCategory> createCategory(
    ExpenseCategoryMutation mutation,
  ) async => ExpenseCategory.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_finance/expense-categories',
        data: mutation.toCreateJson(),
      ),
    ),
  );

  @override
  Future<ExpenseCategory> updateCategory(
    String categoryId,
    ExpenseCategoryMutation mutation,
  ) async => ExpenseCategory.fromJson(
    await _requestMap(
      () => _client.dio.patch<Object?>(
        '$_finance/expense-categories/$categoryId',
        data: mutation.toUpdateJson(),
      ),
    ),
  );

  @override
  Future<List<Expense>> getExpenses(
    ExpenseQuery query, {
    CancelToken? cancelToken,
  }) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_finance/expenses',
        queryParameters: query.toQuery(),
        cancelToken: cancelToken,
      ),
    ),
    Expense.fromJson,
  );

  @override
  Future<Expense> getExpense(String expenseId) async => Expense.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>('$_finance/expenses/$expenseId'),
    ),
  );

  @override
  Future<Expense> createExpense(
    ExpenseMutation mutation, {
    required bool includeBranch,
  }) async => Expense.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_finance/expenses',
        data: mutation.toJson(includeBranch: includeBranch),
      ),
    ),
  );

  @override
  Future<Expense> updateExpense(
    String expenseId,
    ExpenseMutation mutation, {
    required bool includeBranch,
  }) async => Expense.fromJson(
    await _requestMap(
      () => _client.dio.patch<Object?>(
        '$_finance/expenses/$expenseId',
        data: mutation.toJson(includeBranch: includeBranch),
      ),
    ),
  );

  @override
  Future<Expense> cancelExpense(String expenseId) async => Expense.fromJson(
    await _requestMap(
      () => _client.dio.delete<Object?>('$_finance/expenses/$expenseId'),
    ),
  );

  @override
  Future<FinancialSummary> getSummary({
    required DateTime from,
    required DateTime to,
    String? branchId,
    CancelToken? cancelToken,
  }) async => FinancialSummary.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>(
        '$_analytics/summary',
        queryParameters: _analyticsQuery(from, to, branchId),
        cancelToken: cancelToken,
      ),
    ),
  );

  @override
  Future<SalesVsExpensesReport> getSalesVsExpenses({
    required DateTime from,
    required DateTime to,
    String? branchId,
    CancelToken? cancelToken,
  }) async => SalesVsExpensesReport.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>(
        '$_analytics/sales-vs-expenses',
        queryParameters: _analyticsQuery(from, to, branchId),
        cancelToken: cancelToken,
      ),
    ),
  );

  @override
  Future<NetProfitReport> getNetProfit({
    required DateTime from,
    required DateTime to,
    String? branchId,
    CancelToken? cancelToken,
  }) async => NetProfitReport.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>(
        '$_analytics/net-profit',
        queryParameters: _analyticsQuery(from, to, branchId),
        cancelToken: cancelToken,
      ),
    ),
  );

  @override
  Future<BranchComparisonReport> getBranchComparison({
    required DateTime from,
    required DateTime to,
    CancelToken? cancelToken,
  }) async => BranchComparisonReport.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>(
        '$_analytics/branch-comparison',
        queryParameters: {'from': _dateOnly(from), 'to': _dateOnly(to)},
        cancelToken: cancelToken,
      ),
    ),
  );

  Map<String, Object?> _analyticsQuery(
    DateTime from,
    DateTime to,
    String? branchId,
  ) => {
    'from': _dateOnly(from),
    'to': _dateOnly(to),
    if (branchId?.isNotEmpty == true) 'branchId': branchId,
  };

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

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
