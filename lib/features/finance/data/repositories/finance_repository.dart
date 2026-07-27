import '../models/finance_models.dart';

abstract interface class FinanceRepository {
  Future<List<Expense>> getExpenses();
  Future<List<ExpenseCategory>> getCategories();
  Future<List<BranchFinancialHealth>> getFinancialHealth();
}

class MockFinanceRepository implements FinanceRepository {
  @override
  Future<List<Expense>> getExpenses() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return [
      _expense(
        'e01',
        'GTO-0041',
        'Renta local CDMX-01 — Oct',
        'Renta',
        'CDMX-01',
        85000,
        13600,
        ExpenseStatus.approved,
        true,
      ),
      _expense(
        'e02',
        'GTO-0042',
        'Nómina quincena 1 — Oct',
        'Nómina',
        'CDMX-01',
        62000,
        0,
        ExpenseStatus.approved,
        true,
      ),
      _expense(
        'e03',
        'GTO-0043',
        'Servicio de luz — Sep',
        'Servicios',
        'CDMX-02',
        12400,
        1984,
        ExpenseStatus.approved,
        true,
      ),
      _expense(
        'e04',
        'GTO-0044',
        'Mantenimiento equipo cocina',
        'Mantenimiento',
        'GDL-01',
        8500,
        1360,
        ExpenseStatus.pending,
        false,
      ),
      _expense(
        'e05',
        'GTO-0045',
        'Publicidad redes sociales — Sep',
        'Marketing',
        'CDMX-01',
        15000,
        2400,
        ExpenseStatus.approved,
        true,
      ),
      _expense(
        'e06',
        'GTO-0046',
        'Gas — instalación GDL',
        'Servicios',
        'GDL-01',
        3200,
        512,
        ExpenseStatus.rejected,
        false,
      ),
      _expense(
        'e07',
        'GTO-0047',
        'Uniformes personal temporada',
        'Uniformes',
        'MTY-01',
        18400,
        2944,
        ExpenseStatus.pending,
        false,
      ),
      _expense(
        'e08',
        'GTO-0048',
        'Software suscripción — Contpaq',
        'Tecnología',
        'CDMX-01',
        4800,
        768,
        ExpenseStatus.approved,
        true,
      ),
    ];
  }

  Expense _expense(
    String id,
    String folio,
    String concept,
    String category,
    String branch,
    double amount,
    double tax,
    ExpenseStatus status,
    bool receipt,
  ) {
    return Expense(
      id: id,
      folio: folio,
      concept: concept,
      category: category,
      branchId: branch,
      date: DateTime(2025, 9, 30),
      amount: amount,
      tax: tax,
      method: ExpensePaymentMethod.transfer,
      status: status,
      notes: 'Registro operativo migrado desde el mock React.',
      createdBy: 'M. López',
      hasReceipt: receipt,
    );
  }

  @override
  Future<List<ExpenseCategory>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return const [
      ExpenseCategory(
        id: 'cat-01',
        name: 'Renta',
        description: 'Arrendamiento de locales comerciales',
        budgetMonthly: 340000,
        spentThisMonth: 340000,
        active: true,
        requiresReceipt: true,
        requiresApproval: false,
        colorValue: 0xFF2563EB,
      ),
      ExpenseCategory(
        id: 'cat-02',
        name: 'Nómina',
        description: 'Sueldos, salarios y prestaciones',
        budgetMonthly: 520000,
        spentThisMonth: 310000,
        active: true,
        requiresReceipt: true,
        requiresApproval: false,
        colorValue: 0xFF7C3AED,
      ),
      ExpenseCategory(
        id: 'cat-03',
        name: 'Servicios',
        description: 'Luz, agua, gas, internet y telefonía',
        budgetMonthly: 85000,
        spentThisMonth: 62400,
        active: true,
        requiresReceipt: true,
        requiresApproval: false,
        colorValue: 0xFF0D9488,
      ),
      ExpenseCategory(
        id: 'cat-04',
        name: 'Mantenimiento',
        description: 'Reparaciones preventivas y correctivas',
        budgetMonthly: 40000,
        spentThisMonth: 8500,
        active: true,
        requiresReceipt: false,
        requiresApproval: true,
        colorValue: 0xFFF97316,
      ),
      ExpenseCategory(
        id: 'cat-05',
        name: 'Marketing',
        description: 'Publicidad y material promocional',
        budgetMonthly: 60000,
        spentThisMonth: 15000,
        active: true,
        requiresReceipt: true,
        requiresApproval: true,
        colorValue: 0xFFEC4899,
      ),
      ExpenseCategory(
        id: 'cat-06',
        name: 'Uniformes',
        description: 'Ropa de trabajo del personal',
        budgetMonthly: 20000,
        spentThisMonth: 18400,
        active: true,
        requiresReceipt: false,
        requiresApproval: true,
        colorValue: 0xFF6B7280,
      ),
      ExpenseCategory(
        id: 'cat-08',
        name: 'Seguros',
        description: 'Pólizas para locales y equipo',
        budgetMonthly: 30000,
        spentThisMonth: 0,
        active: false,
        requiresReceipt: true,
        requiresApproval: true,
        colorValue: 0xFF15803D,
      ),
    ];
  }

  @override
  Future<List<BranchFinancialHealth>> getFinancialHealth() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return const [
      BranchFinancialHealth(
        id: 'CDMX-01',
        name: 'CDMX Centro',
        score: 84,
        status: FinancialHealthStatus.healthy,
        revenue: 724000,
        expenses: 402000,
        margin: 44.4,
        salesTrend: 8.1,
        expenseTrend: 5.2,
        stability: 92,
      ),
      BranchFinancialHealth(
        id: 'CDMX-02',
        name: 'CDMX Norte',
        score: 71,
        status: FinancialHealthStatus.healthy,
        revenue: 548000,
        expenses: 341000,
        margin: 37.8,
        salesTrend: 3.2,
        expenseTrend: 4.8,
        stability: 78,
      ),
      BranchFinancialHealth(
        id: 'GDL-01',
        name: 'Guadalajara',
        score: 58,
        status: FinancialHealthStatus.atRisk,
        revenue: 389000,
        expenses: 264000,
        margin: 32.1,
        salesTrend: -2.4,
        expenseTrend: 6.3,
        stability: 61,
      ),
      BranchFinancialHealth(
        id: 'MTY-01',
        name: 'Monterrey',
        score: 39,
        status: FinancialHealthStatus.critical,
        revenue: 302000,
        expenses: 228000,
        margin: 24.5,
        salesTrend: -5.8,
        expenseTrend: 9.1,
        stability: 44,
      ),
    ];
  }
}
