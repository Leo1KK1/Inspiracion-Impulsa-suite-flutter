import 'package:flutter/foundation.dart';

import '../../data/models/finance_models.dart';
import '../../data/repositories/finance_repository.dart';

enum FinanceStatus { idle, loading, success, error }

class FinanceController extends ChangeNotifier {
  FinanceController(this._repository);
  final FinanceRepository _repository;

  FinanceStatus status = FinanceStatus.idle;
  List<Expense> expenses = const [];
  List<ExpenseCategory> categories = const [];
  List<BranchFinancialHealth> health = const [];
  String? errorMessage;

  Future<void> load() async {
    status = FinanceStatus.loading;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _repository.getExpenses(),
        _repository.getCategories(),
        _repository.getFinancialHealth(),
      ]);
      expenses = results[0] as List<Expense>;
      categories = results[1] as List<ExpenseCategory>;
      health = results[2] as List<BranchFinancialHealth>;
      status = FinanceStatus.success;
    } on Object {
      errorMessage = 'No fue posible cargar finanzas y analítica.';
      status = FinanceStatus.error;
    }
    notifyListeners();
  }

  void addExpense(Expense expense) {
    expenses = [expense, ...expenses];
    notifyListeners();
  }

  void voidExpense(String id) {
    expenses = [
      for (final expense in expenses)
        if (expense.id == id)
          Expense(
            id: expense.id,
            folio: expense.folio,
            concept: expense.concept,
            category: expense.category,
            branchId: expense.branchId,
            date: expense.date,
            amount: expense.amount,
            tax: expense.tax,
            method: expense.method,
            status: ExpenseStatus.cancelled,
            notes: expense.notes,
            createdBy: expense.createdBy,
            hasReceipt: expense.hasReceipt,
          )
        else
          expense,
    ];
    notifyListeners();
  }
}
