enum ExpenseStatus {
  recorded,
  cancelled;

  String get apiValue => switch (this) {
    recorded => 'RECORDED',
    cancelled => 'CANCELLED',
  };

  String get label => switch (this) {
    recorded => 'Registrado',
    cancelled => 'Cancelado',
  };

  static ExpenseStatus fromApi(String? value) =>
      value == 'CANCELLED' ? cancelled : recorded;
}

enum ExpenseType {
  fixed,
  variable;

  String get apiValue => switch (this) {
    fixed => 'FIXED',
    variable => 'VARIABLE',
  };

  String get label => switch (this) {
    fixed => 'Fijo',
    variable => 'Variable',
  };

  static ExpenseType fromApi(String? value) =>
      value == 'FIXED' ? fixed : variable;
}

class ExpenseCategoryRef {
  const ExpenseCategoryRef({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;

  factory ExpenseCategoryRef.fromJson(Map<String, Object?> json) =>
      ExpenseCategoryRef(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Sin categoría',
        code: json['code'] as String? ?? '',
      );
}

class ExpenseBranchRef {
  const ExpenseBranchRef({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;

  factory ExpenseBranchRef.fromJson(Map<String, Object?> json) =>
      ExpenseBranchRef(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Sucursal',
        code: json['code'] as String? ?? '',
      );
}

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExpenseCategoryRef get reference =>
      ExpenseCategoryRef(id: id, name: name, code: code);

  factory ExpenseCategory.fromJson(Map<String, Object?> json) =>
      ExpenseCategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Categoría',
        code: json['code'] as String? ?? '',
        description: json['description'] as String?,
        isActive: json['isActive'] as bool? ?? false,
        createdAt: _date(json['createdAt']),
        updatedAt: _date(json['updatedAt']),
      );
}

class Expense {
  const Expense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    required this.status,
    required this.expenseType,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.branchId,
    this.notes,
    this.branch,
  });

  final String id;
  final String? branchId;
  final String categoryId;
  final double amount;
  final String? notes;
  final DateTime expenseDate;
  final ExpenseStatus status;
  final ExpenseType expenseType;
  final ExpenseCategoryRef category;
  final ExpenseBranchRef? branch;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCancelled => status == ExpenseStatus.cancelled;
  bool get isGlobal => branchId == null;
  String get branchLabel => branch?.name ?? 'Global';

  factory Expense.fromJson(Map<String, Object?> json) => Expense(
    id: json['id'] as String? ?? '',
    branchId: json['branchId'] as String?,
    categoryId: json['categoryId'] as String? ?? '',
    amount: _double(json['amount']),
    notes: json['notes'] as String?,
    expenseDate:
        _calendarDate(json['expenseDate']) ??
        DateTime.fromMillisecondsSinceEpoch(0),
    status: ExpenseStatus.fromApi(json['status'] as String?),
    expenseType: ExpenseType.fromApi(json['expenseType'] as String?),
    category: ExpenseCategoryRef.fromJson(_mapOrEmpty(json['category'])),
    branch: json['branch'] is Map
        ? ExpenseBranchRef.fromJson(_mapOrEmpty(json['branch']))
        : null,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );
}

class FinancialIncome {
  const FinancialIncome({
    required this.totalSalesNominal,
    required this.totalCollectedReal,
    required this.salesCount,
  });

  final double totalSalesNominal;
  final double totalCollectedReal;
  final int salesCount;

  factory FinancialIncome.fromJson(Map<String, Object?> json) =>
      FinancialIncome(
        totalSalesNominal: _double(json['totalSalesNominal']),
        totalCollectedReal: _double(json['totalCollectedReal']),
        salesCount: _int(json['salesCount']),
      );
}

class FinancialExpenses {
  const FinancialExpenses({
    required this.totalExpenses,
    required this.expensesCount,
  });

  final double totalExpenses;
  final int expensesCount;

  factory FinancialExpenses.fromJson(Map<String, Object?> json) =>
      FinancialExpenses(
        totalExpenses: _double(json['totalExpenses']),
        expensesCount: _int(json['expensesCount']),
      );
}

class FinancialSummary {
  const FinancialSummary({
    required this.from,
    required this.to,
    required this.income,
    required this.expenses,
    required this.ticketAverage,
    required this.netProfit,
    this.branchId,
  });

  final DateTime? from;
  final DateTime? to;
  final String? branchId;
  final FinancialIncome income;
  final FinancialExpenses expenses;
  final double ticketAverage;
  final double netProfit;

  double get operatingMargin => income.totalSalesNominal == 0
      ? 0
      : netProfit / income.totalSalesNominal * 100;

  factory FinancialSummary.fromJson(Map<String, Object?> json) =>
      FinancialSummary(
        from: _date(json['from']),
        to: _date(json['to']),
        branchId: json['branchId'] as String?,
        income: FinancialIncome.fromJson(_mapOrEmpty(json['income'])),
        expenses: FinancialExpenses.fromJson(_mapOrEmpty(json['expenses'])),
        ticketAverage: _double(json['ticketAverage']),
        netProfit: _double(json['netProfit']),
      );
}

class DailyFinancialMetric {
  const DailyFinancialMetric({
    required this.date,
    required this.total,
    required this.count,
  });

  final DateTime date;
  final double total;
  final int count;

  factory DailyFinancialMetric.fromJson(
    Map<String, Object?> json,
  ) => DailyFinancialMetric(
    date: _calendarDate(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    total: _double(json['total']),
    count: _int(json['count']),
  );
}

class SalesVsExpensesReport {
  const SalesVsExpensesReport({
    required this.summary,
    required this.incomeByDay,
    required this.expensesByDay,
  });

  final FinancialSummary summary;
  final List<DailyFinancialMetric> incomeByDay;
  final List<DailyFinancialMetric> expensesByDay;

  factory SalesVsExpensesReport.fromJson(Map<String, Object?> json) {
    final series = _mapOrEmpty(json['series']);
    return SalesVsExpensesReport(
      summary: FinancialSummary.fromJson(json),
      incomeByDay: _maps(
        series['incomeByDay'],
      ).map(DailyFinancialMetric.fromJson).toList(growable: false),
      expensesByDay: _maps(
        series['expensesByDay'],
      ).map(DailyFinancialMetric.fromJson).toList(growable: false),
    );
  }
}

class NetProfitReport {
  const NetProfitReport({
    required this.from,
    required this.to,
    required this.income,
    required this.expenses,
    required this.netProfit,
    required this.formula,
    this.branchId,
  });

  final DateTime? from;
  final DateTime? to;
  final String? branchId;
  final double income;
  final double expenses;
  final double netProfit;
  final String formula;

  factory NetProfitReport.fromJson(Map<String, Object?> json) =>
      NetProfitReport(
        from: _date(json['from']),
        to: _date(json['to']),
        branchId: json['branchId'] as String?,
        income: _double(json['income']),
        expenses: _double(json['expenses']),
        netProfit: _double(json['netProfit']),
        formula: json['formula'] as String? ?? '',
      );
}

class BranchFinancialComparison {
  const BranchFinancialComparison({
    required this.branchId,
    required this.branchName,
    required this.branchCode,
    required this.income,
    required this.salesCount,
    required this.expenses,
    required this.expensesCount,
    required this.netProfit,
    required this.masked,
  });

  final String branchId;
  final String branchName;
  final String branchCode;
  final double income;
  final int salesCount;
  final double expenses;
  final int expensesCount;
  final double netProfit;
  final bool masked;

  double get margin => income == 0 ? 0 : netProfit / income * 100;

  factory BranchFinancialComparison.fromJson(Map<String, Object?> json) =>
      BranchFinancialComparison(
        branchId: json['branchId'] as String? ?? '',
        branchName: json['branchName'] as String? ?? 'Sucursal',
        branchCode: json['branchCode'] as String? ?? '',
        income: _double(json['income']),
        salesCount: _int(json['salesCount']),
        expenses: _double(json['expenses']),
        expensesCount: _int(json['expensesCount']),
        netProfit: _double(json['netProfit']),
        masked: json['masked'] as bool? ?? false,
      );
}

class BranchComparisonReport {
  const BranchComparisonReport({
    required this.from,
    required this.to,
    required this.viewerRole,
    required this.branches,
    this.activeBranchId,
  });

  final DateTime? from;
  final DateTime? to;
  final String viewerRole;
  final String? activeBranchId;
  final List<BranchFinancialComparison> branches;

  factory BranchComparisonReport.fromJson(Map<String, Object?> json) =>
      BranchComparisonReport(
        from: _date(json['from']),
        to: _date(json['to']),
        viewerRole: json['viewerRole'] as String? ?? '',
        activeBranchId: json['activeBranchId'] as String?,
        branches: _maps(
          json['branches'],
        ).map(BranchFinancialComparison.fromJson).toList(growable: false),
      );
}

class ExpenseMutation {
  const ExpenseMutation({
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    required this.expenseType,
    this.notes,
    this.branchId,
  });

  final String categoryId;
  final double amount;
  final DateTime expenseDate;
  final ExpenseType expenseType;
  final String? notes;
  final String? branchId;

  Map<String, Object?> toJson({required bool includeBranch}) => {
    'categoryId': categoryId,
    'amount': amount,
    'expenseDate': _dateOnly(expenseDate),
    'expenseType': expenseType.apiValue,
    'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    if (includeBranch) 'branchId': branchId,
  };
}

class ExpenseCategoryMutation {
  const ExpenseCategoryMutation({
    required this.name,
    required this.isActive,
    this.code,
    this.description,
  });

  final String name;
  final String? code;
  final String? description;
  final bool isActive;

  Map<String, Object?> toCreateJson() => {
    'name': name.trim(),
    'code': code!.trim(),
    'description': description?.trim().isEmpty == true
        ? null
        : description?.trim(),
    'isActive': isActive,
  };

  Map<String, Object?> toUpdateJson() => {
    'name': name.trim(),
    'description': description?.trim().isEmpty == true
        ? null
        : description?.trim(),
    'isActive': isActive,
  };
}

Map<String, Object?> _mapOrEmpty(Object? value) =>
    value is Map ? value.cast<String, Object?>() : const {};

List<Map<String, Object?>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, Object?>())
          .toList(growable: false)
    : const [];

double _double(Object? value) => (value as num?)?.toDouble() ?? 0;
int _int(Object? value) => (value as num?)?.toInt() ?? 0;
DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

DateTime? _calendarDate(Object? value) {
  if (value is! String || value.length < 10) return null;
  final parts = value.substring(0, 10).split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
