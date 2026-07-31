import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/features/finance/data/repositories/finance_repository.dart';
import 'package:impulsa_suite_flutter/features/finance/presentation/controllers/finance_controller.dart';
import 'package:impulsa_suite_flutter/features/finance/presentation/pages/expenses_page.dart';
import 'package:impulsa_suite_flutter/features/session/data/repositories/session_repository.dart';
import 'package:impulsa_suite_flutter/features/session/presentation/controllers/tenant_session_controller.dart';
import 'package:provider/provider.dart';

void main() {
  test('FinanceController sincroniza el rol y la sucursal de la sesión', () {
    final controller = FinanceController(
      _FakeFinanceRepository(),
      isOwner: false,
    );

    expect(controller.isOwner, isFalse);
    expect(controller.canManageCategories, isFalse);

    controller.updateSession(isOwner: true, branchId: 'BR-1');

    expect(controller.isOwner, isTrue);
    expect(controller.canManageCategories, isTrue);
    expect(controller.activeBranchId, 'BR-1');
    expect(controller.selectedBranchId, isNull);

    controller.updateSession(isOwner: false, branchId: 'BR-2');

    expect(controller.isOwner, isFalse);
    expect(controller.canManageCategories, isFalse);
    expect(controller.activeBranchId, 'BR-2');
    expect(controller.selectedBranchId, 'BR-2');
  });

  testWidgets('los filtros de gastos tienen claves únicas', (tester) async {
    final finance = FinanceController(_FakeFinanceRepository(), isOwner: true)
      ..status = FinanceStatus.success;
    final session = TenantSessionController(_FakeSessionRepository());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: finance),
          ChangeNotifierProvider.value(value: session),
        ],
        child: const MaterialApp(home: Scaffold(body: ExpensesPage())),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Gastos operativos'), findsOneWidget);
  });
}

class _FakeFinanceRepository extends Fake implements FinanceRepository {}

class _FakeSessionRepository extends Fake implements SessionRepository {}
