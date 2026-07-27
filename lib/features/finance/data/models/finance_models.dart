enum ExpenseStatus { approved, pending, rejected, cancelled }

enum ExpensePaymentMethod { cash, card, transfer, check }

class Expense {
  const Expense({
    required this.id,
    required this.folio,
    required this.concept,
    required this.category,
    required this.branchId,
    required this.date,
    required this.amount,
    required this.tax,
    required this.method,
    required this.status,
    required this.notes,
    required this.createdBy,
    required this.hasReceipt,
  });

  final String id;
  final String folio;
  final String concept;
  final String category;
  final String branchId;
  final DateTime date;
  final double amount;
  final double tax;
  final ExpensePaymentMethod method;
  final ExpenseStatus status;
  final String notes;
  final String createdBy;
  final bool hasReceipt;
  double get total => amount + tax;
}

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.budgetMonthly,
    required this.spentThisMonth,
    required this.active,
    required this.requiresReceipt,
    required this.requiresApproval,
    required this.colorValue,
  });

  final String id;
  final String name;
  final String description;
  final double budgetMonthly;
  final double spentThisMonth;
  final bool active;
  final bool requiresReceipt;
  final bool requiresApproval;
  final int colorValue;
}

enum FinancialHealthStatus { healthy, atRisk, critical }

class BranchFinancialHealth {
  const BranchFinancialHealth({
    required this.id,
    required this.name,
    required this.score,
    required this.status,
    required this.revenue,
    required this.expenses,
    required this.margin,
    required this.salesTrend,
    required this.expenseTrend,
    required this.stability,
  });

  final String id;
  final String name;
  final int score;
  final FinancialHealthStatus status;
  final double revenue;
  final double expenses;
  final double margin;
  final double salesTrend;
  final double expenseTrend;
  final double stability;
}
