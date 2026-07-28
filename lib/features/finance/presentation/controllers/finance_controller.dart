import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/finance_models.dart';
import '../../data/repositories/finance_repository.dart';

enum FinanceStatus { idle, loading, success, error }

class FinanceController extends ChangeNotifier {
  FinanceController(
    this._repository, {
    required this.isOwner,
    String? initialBranchId,
  }) : activeBranchId = initialBranchId,
       selectedBranchId = isOwner ? null : initialBranchId {
    final now = DateTime.now();
    from = DateTime(now.year, now.month);
    to = DateTime(now.year, now.month, now.day);
  }

  final FinanceRepository _repository;
  final bool isOwner;

  FinanceStatus status = FinanceStatus.idle;
  List<Expense> expenses = const [];
  List<ExpenseCategory> categories = const [];
  FinancialSummary? summary;
  SalesVsExpensesReport? salesVsExpenses;
  NetProfitReport? netProfit;
  BranchComparisonReport? branchComparison;
  Expense? selectedExpense;
  String? activeBranchId;
  String? selectedBranchId;
  String? selectedCategoryId;
  ExpenseStatus? selectedExpenseStatus;
  late DateTime from;
  late DateTime to;
  String query = '';
  String? errorMessage;
  bool saving = false;
  bool loadingExpense = false;

  CancelToken? _loadCancelToken;
  int _loadGeneration = 0;

  bool get canManageCategories => isOwner;

  List<ExpenseCategoryRef> get categoryOptions {
    if (isOwner) {
      return categories
          .where((category) => category.isActive)
          .map((category) => category.reference)
          .toList(growable: false);
    }
    final unique = <String, ExpenseCategoryRef>{};
    for (final expense in expenses) {
      unique[expense.category.id] = expense.category;
    }
    return unique.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Expense> get filteredExpenses {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return expenses;
    return expenses
        .where(
          (expense) =>
              expense.id.toLowerCase().contains(term) ||
              expense.category.name.toLowerCase().contains(term) ||
              expense.branchLabel.toLowerCase().contains(term) ||
              expense.notes?.toLowerCase().contains(term) == true,
        )
        .toList(growable: false);
  }

  Future<void> load({bool force = false}) async {
    if (status == FinanceStatus.loading && !force) return;
    if (!isOwner && activeBranchId == null) {
      status = FinanceStatus.error;
      errorMessage = 'Selecciona una sucursal antes de consultar finanzas.';
      notifyListeners();
      return;
    }

    _loadCancelToken?.cancel('Filtros actualizados');
    final cancelToken = CancelToken();
    _loadCancelToken = cancelToken;
    final generation = ++_loadGeneration;
    status = FinanceStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final analyticsBranch = isOwner ? selectedBranchId : null;
      final results = await Future.wait<Object>([
        _repository.getExpenses(
          ExpenseQuery(
            from: from,
            to: to,
            categoryId: selectedCategoryId,
            branchId: isOwner ? selectedBranchId : null,
            status: selectedExpenseStatus,
          ),
          cancelToken: cancelToken,
        ),
        if (isOwner)
          _repository.getCategories(cancelToken: cancelToken)
        else
          Future<List<ExpenseCategory>>.value(const []),
        _repository.getSummary(
          from: from,
          to: to,
          branchId: analyticsBranch,
          cancelToken: cancelToken,
        ),
        _repository.getSalesVsExpenses(
          from: from,
          to: to,
          branchId: analyticsBranch,
          cancelToken: cancelToken,
        ),
        _repository.getNetProfit(
          from: from,
          to: to,
          branchId: analyticsBranch,
          cancelToken: cancelToken,
        ),
        _repository.getBranchComparison(
          from: from,
          to: to,
          cancelToken: cancelToken,
        ),
      ]);
      if (generation != _loadGeneration || cancelToken.isCancelled) return;
      expenses = results[0] as List<Expense>;
      categories = results[1] as List<ExpenseCategory>;
      summary = results[2] as FinancialSummary;
      salesVsExpenses = results[3] as SalesVsExpensesReport;
      netProfit = results[4] as NetProfitReport;
      branchComparison = results[5] as BranchComparisonReport;
      status = FinanceStatus.success;
    } on ApiException catch (error) {
      if (generation != _loadGeneration || cancelToken.isCancelled) return;
      errorMessage = error.message;
      status = FinanceStatus.error;
    } on Object {
      if (generation != _loadGeneration || cancelToken.isCancelled) return;
      errorMessage = 'No fue posible cargar finanzas y analítica.';
      status = FinanceStatus.error;
    }
    notifyListeners();
  }

  void onSessionBranchChanged(String? branchId) {
    activeBranchId = branchId;
    if (!isOwner) selectedBranchId = branchId;
    invalidate();
  }

  void invalidate() {
    _loadCancelToken?.cancel('Contexto invalidado');
    _loadGeneration++;
    status = FinanceStatus.idle;
    expenses = const [];
    categories = const [];
    summary = null;
    salesVsExpenses = null;
    netProfit = null;
    branchComparison = null;
    selectedExpense = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    if (start.isAfter(end)) return;
    from = DateTime(start.year, start.month, start.day);
    to = DateTime(end.year, end.month, end.day);
    await load(force: true);
  }

  Future<void> setBranchFilter(String? branchId) async {
    if (!isOwner || selectedBranchId == branchId) return;
    selectedBranchId = branchId;
    await load(force: true);
  }

  Future<void> setCategoryFilter(String? categoryId) async {
    if (selectedCategoryId == categoryId) return;
    selectedCategoryId = categoryId;
    await load(force: true);
  }

  Future<void> setStatusFilter(ExpenseStatus? value) async {
    if (selectedExpenseStatus == value) return;
    selectedExpenseStatus = value;
    await load(force: true);
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> loadExpense(String expenseId) async {
    if (loadingExpense) return;
    loadingExpense = true;
    errorMessage = null;
    notifyListeners();
    try {
      selectedExpense = await _repository.getExpense(expenseId);
    } on ApiException catch (error) {
      errorMessage = error.message;
      selectedExpense = null;
    } on Object {
      errorMessage = 'No fue posible cargar el gasto.';
      selectedExpense = null;
    }
    loadingExpense = false;
    notifyListeners();
  }

  Future<bool> createExpense(ExpenseMutation mutation) => _mutateExpense(
    () => _repository.createExpense(mutation, includeBranch: isOwner),
  );

  Future<bool> updateExpense(String expenseId, ExpenseMutation mutation) =>
      _mutateExpense(
        () => _repository.updateExpense(
          expenseId,
          mutation,
          includeBranch: isOwner,
        ),
        selectResult: true,
      );

  Future<bool> cancelExpense(String expenseId) => _mutateExpense(
    () => _repository.cancelExpense(expenseId),
    selectResult: true,
  );

  Future<bool> createCategory(ExpenseCategoryMutation mutation) =>
      _mutateCategory(() => _repository.createCategory(mutation));

  Future<bool> updateCategory(
    String categoryId,
    ExpenseCategoryMutation mutation,
  ) => _mutateCategory(() => _repository.updateCategory(categoryId, mutation));

  Future<bool> _mutateExpense(
    Future<Expense> Function() action, {
    bool selectResult = false,
  }) async {
    if (saving) return false;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await action();
      if (selectResult) selectedExpense = result;
      saving = false;
      await load(force: true);
      if (selectResult) selectedExpense = result;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible completar la operación.';
    }
    saving = false;
    notifyListeners();
    return false;
  }

  Future<bool> _mutateCategory(
    Future<ExpenseCategory> Function() action,
  ) async {
    if (!isOwner || saving) return false;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      saving = false;
      await load(force: true);
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible guardar la categoría.';
    }
    saving = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _loadCancelToken?.cancel('Controller disposed');
    super.dispose();
  }
}
