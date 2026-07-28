import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/features/finance/data/models/finance_models.dart';

void main() {
  group('HU05 finance contracts', () {
    test('maps a global operational expense', () {
      final expense = Expense.fromJson({
        'id': 'expense-1',
        'branchId': null,
        'categoryId': 'category-1',
        'amount': 18000,
        'notes': 'Renta corporativa',
        'expenseDate': '2026-07-18T00:00:00.000Z',
        'status': 'RECORDED',
        'expenseType': 'FIXED',
        'category': {'id': 'category-1', 'name': 'Renta', 'code': 'RENT'},
        'branch': null,
        'createdAt': '2026-07-18T12:00:00.000Z',
        'updatedAt': '2026-07-18T12:00:00.000Z',
      });

      expect(expense.isGlobal, isTrue);
      expect(expense.branchLabel, 'Global');
      expect(expense.status, ExpenseStatus.recorded);
      expect(expense.expenseType, ExpenseType.fixed);
      expect(expense.expenseDate.day, 18);
    });

    test('maps the backend financial summary without local income', () {
      final summary = FinancialSummary.fromJson({
        'from': '2026-07-01T00:00:00.000Z',
        'to': '2026-07-31T23:59:59.999Z',
        'branchId': null,
        'income': {
          'totalSalesNominal': 12500.5,
          'totalCollectedReal': 12000,
          'salesCount': 42,
        },
        'expenses': {'totalExpenses': 3500.5, 'expensesCount': 4},
        'ticketAverage': 297.63,
        'netProfit': 9000,
      });

      expect(summary.income.totalSalesNominal, 12500.5);
      expect(summary.expenses.totalExpenses, 3500.5);
      expect(summary.netProfit, 9000);
      expect(summary.income.salesCount, 42);
    });

    test('preserves masked branch comparison rows for manager', () {
      final report = BranchComparisonReport.fromJson({
        'from': '2026-07-01T00:00:00.000Z',
        'to': '2026-07-31T23:59:59.999Z',
        'viewerRole': 'MANAGER',
        'activeBranchId': 'branch-1',
        'branches': [
          {
            'branchId': 'branch-2',
            'branchName': 'Norte',
            'branchCode': 'NORTE',
            'income': 0,
            'salesCount': 0,
            'expenses': 0,
            'expensesCount': 0,
            'netProfit': 0,
            'masked': true,
          },
        ],
      });

      expect(report.viewerRole, 'MANAGER');
      expect(report.branches.single.masked, isTrue);
    });

    test(
      'omits branchId for manager mutations and includes null for owner',
      () {
        final mutation = ExpenseMutation(
          categoryId: 'category-1',
          amount: 99,
          expenseDate: DateTime(2026, 7, 18),
          expenseType: ExpenseType.variable,
        );

        expect(
          mutation.toJson(includeBranch: false),
          isNot(contains('branchId')),
        );
        expect(
          mutation.toJson(includeBranch: true),
          containsPair('branchId', null),
        );
      },
    );
  });
}
