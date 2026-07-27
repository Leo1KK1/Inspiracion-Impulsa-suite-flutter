import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/pos_models.dart';
import '../../data/repositories/pos_repository.dart';

enum PosStatus { idle, loading, success, error }

enum CheckoutPhase {
  idle,
  validating,
  creatingSale,
  saleCreated,
  creatingCardIntent,
  awaitingGateway,
  confirmingCard,
  success,
  error,
}

class PosController extends ChangeNotifier {
  PosController(
    this._repository, {
    String? initialBranchId,
    this.canManageShifts = false,
  }) : branchId = initialBranchId;

  final PosRepository _repository;
  final bool canManageShifts;

  PosStatus status = PosStatus.idle;
  CheckoutPhase checkoutPhase = CheckoutPhase.idle;
  String? branchId;
  String? errorMessage;
  CashShift? activeShift;
  CashShiftSummary? activeSummary;
  List<CashShift> shiftHistory = const [];
  List<PosProduct> products = const [];
  List<PosTicket> tickets = const [];
  PosTicket? selectedTicket;
  List<CartLine> cart = const [];
  PosSale? lastSale;
  PosSale? pendingSale;
  CardPaymentIntent? pendingIntent;
  String query = '';
  String category = 'Todos';
  bool searchingProducts = false;
  bool savingShift = false;
  bool loadingSummary = false;
  bool loadingTicket = false;
  bool productActionBusy = false;

  Timer? _searchDebounce;
  int _searchGeneration = 0;

  bool get loading => status == PosStatus.loading;
  bool get shiftOpen => activeShift?.isOpen == true;
  bool get checkoutBusy => switch (checkoutPhase) {
    CheckoutPhase.validating ||
    CheckoutPhase.creatingSale ||
    CheckoutPhase.creatingCardIntent ||
    CheckoutPhase.confirmingCard => true,
    _ => false,
  };
  bool get hasPendingPayment =>
      pendingSale?.paymentStatus == PaymentStatus.pending;

  List<String> get categories => [
    'Todos',
    ...{for (final product in products) product.category},
  ];

  List<PosProduct> get filteredProducts => products
      .where((product) => category == 'Todos' || product.category == category)
      .toList(growable: false);

  double get subtotal => cart.fold(0, (sum, line) => sum + line.subtotal);
  double get discount => cart.fold(0, (sum, line) => sum + line.discountAmount);
  double get total => subtotal - discount;

  Future<void> load({String? branchId, bool force = false}) async {
    if (branchId != null) this.branchId = branchId;
    if (this.branchId == null) {
      status = PosStatus.error;
      errorMessage = 'Selecciona una sucursal antes de abrir el POS.';
      notifyListeners();
      return;
    }
    if (status == PosStatus.loading ||
        (!force && status == PosStatus.success)) {
      return;
    }

    status = PosStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>([
        _activeShiftOrNull(),
        _repository.getTickets(),
        canManageShifts
            ? _repository.getShifts()
            : Future<List<CashShift>>.value(const []),
      ]);
      activeShift = results[0] as CashShift?;
      tickets = results[1] as List<PosTicket>;
      shiftHistory = results[2] as List<CashShift>;
      _recoverPendingPayment();
      status = PosStatus.success;
    } on ApiException catch (error) {
      errorMessage = error.message;
      status = PosStatus.error;
    } on Object {
      errorMessage = 'No fue posible cargar el punto de venta.';
      status = PosStatus.error;
    }
    notifyListeners();
  }

  void setBranch(String? value) {
    if (value == branchId) return;
    branchId = value;
    invalidate();
  }

  void invalidate() {
    _searchDebounce?.cancel();
    _searchGeneration++;
    status = PosStatus.idle;
    checkoutPhase = CheckoutPhase.idle;
    errorMessage = null;
    activeShift = null;
    activeSummary = null;
    shiftHistory = const [];
    products = const [];
    tickets = const [];
    selectedTicket = null;
    cart = const [];
    lastSale = null;
    pendingSale = null;
    pendingIntent = null;
    query = '';
    category = 'Todos';
    searchingProducts = false;
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    category = 'Todos';
    _searchDebounce?.cancel();
    final term = value.trim();
    if (term.isEmpty) {
      _searchGeneration++;
      products = const [];
      searchingProducts = false;
      notifyListeners();
      return;
    }
    searchingProducts = true;
    notifyListeners();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _search(term),
    );
  }

  Future<void> searchNow(String value) async {
    query = value;
    _searchDebounce?.cancel();
    final term = value.trim();
    if (term.isEmpty) return;
    await _search(term);
  }

  Future<void> _search(String term) async {
    final generation = ++_searchGeneration;
    searchingProducts = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.searchProducts(term);
      if (generation != _searchGeneration) return;
      products = result;
      category = 'Todos';
    } on ApiException catch (error) {
      if (generation != _searchGeneration) return;
      products = const [];
      errorMessage = error.message;
    } on Object {
      if (generation != _searchGeneration) return;
      products = const [];
      errorMessage = 'No fue posible buscar productos.';
    }
    if (generation != _searchGeneration) return;
    searchingProducts = false;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  Future<void> add(PosProduct product) async {
    if (productActionBusy || hasPendingPayment) return;
    productActionBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final current = await _repository.getProduct(product.id);
      final existing = cart.indexWhere((line) => line.product.id == current.id);
      if (existing == -1) {
        if (current.availableStock <= 0) {
          errorMessage = 'El producto ya no tiene existencia disponible.';
        } else {
          cart = [...cart, CartLine(product: current, quantity: 1)];
        }
      } else {
        final line = cart[existing];
        if (line.quantity >= current.availableStock) {
          errorMessage =
              'Solo hay ${current.availableStock} unidades disponibles.';
        } else {
          final copy = [...cart];
          copy[existing] = CartLine(
            product: current,
            quantity: line.quantity + 1,
            discount: line.discount,
          );
          cart = copy;
        }
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible validar el producto.';
    }
    productActionBusy = false;
    notifyListeners();
  }

  void changeQuantity(PosProduct product, int delta) {
    if (hasPendingPayment || checkoutBusy) return;
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) return;
    final next = cart[index].quantity + delta;
    if (next <= 0) {
      cart = cart.where((line) => line.product.id != product.id).toList();
    } else if (next > cart[index].product.availableStock) {
      errorMessage =
          'Solo hay ${cart[index].product.availableStock} unidades disponibles.';
    } else {
      final copy = [...cart];
      copy[index] = copy[index].copyWith(quantity: next);
      cart = copy;
    }
    notifyListeners();
  }

  Future<bool> openShift({required double openingAmount, String? notes}) async {
    if (savingShift) return false;
    savingShift = true;
    errorMessage = null;
    notifyListeners();
    try {
      activeShift = await _repository.openShift(
        openingAmount: openingAmount,
        notes: notes,
      );
      activeSummary = await _summaryOrNull(activeShift!.id);
      if (canManageShifts) shiftHistory = await _repository.getShifts();
      savingShift = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible abrir el turno.';
    }
    savingShift = false;
    notifyListeners();
    return false;
  }

  Future<void> loadActiveSummary() async {
    final shift = activeShift;
    if (shift == null || loadingSummary) return;
    loadingSummary = true;
    errorMessage = null;
    notifyListeners();
    try {
      activeSummary = await _repository.getShiftSummary(shift.id);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible obtener el resumen del turno.';
    }
    loadingSummary = false;
    notifyListeners();
  }

  Future<bool> closeActiveShift({
    required double closingAmount,
    String? notes,
  }) async {
    final shift = activeShift;
    if (shift == null || savingShift) return false;
    savingShift = true;
    errorMessage = null;
    notifyListeners();
    try {
      final closed = await _repository.closeShift(
        shift.id,
        closingAmount: closingAmount,
        notes: notes,
      );
      activeSummary = await _summaryOrNull(closed.id);
      activeShift = null;
      cart = const [];
      if (canManageShifts) shiftHistory = await _repository.getShifts();
      savingShift = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cerrar el turno.';
    }
    savingShift = false;
    notifyListeners();
    return false;
  }

  Future<bool> checkout(
    PaymentMethod method, {
    double? cashReceived,
    String? notes,
  }) async {
    if (checkoutBusy || hasPendingPayment) return false;

    checkoutPhase = CheckoutPhase.validating;
    errorMessage = null;
    notifyListeners();

    final shift = activeShift;
    if (shift == null) {
      return _checkoutFailure('Abre un turno antes de registrar la venta.');
    }
    if (cart.isEmpty) {
      return _checkoutFailure('Agrega al menos un producto a la venta.');
    }
    if (method == PaymentMethod.cash &&
        (cashReceived == null || cashReceived < total)) {
      return _checkoutFailure('El efectivo recibido no cubre el total.');
    }
    if (method == PaymentMethod.mixed &&
        (cashReceived == null || cashReceived <= 0 || cashReceived >= total)) {
      return _checkoutFailure(
        'En pago mixto, el efectivo debe ser mayor a cero y menor al total.',
      );
    }

    checkoutPhase = CheckoutPhase.creatingSale;
    notifyListeners();
    try {
      final sale = await _repository.createSale(
        CreatePosSaleRequest(
          cashShiftId: shift.id,
          items: List<CartLine>.unmodifiable(cart),
          paymentMethod: method,
          cashReceived: method == PaymentMethod.card ? null : cashReceived,
          notes: notes,
        ),
      );
      lastSale = sale;
      checkoutPhase = CheckoutPhase.saleCreated;
      notifyListeners();

      if (method == PaymentMethod.cash) {
        cart = const [];
        checkoutPhase = CheckoutPhase.success;
        await _refreshOperationalData();
        notifyListeners();
        return true;
      }

      pendingSale = sale;
      pendingIntent = sale.cardPaymentIntent;
      if (method == PaymentMethod.card) {
        checkoutPhase = CheckoutPhase.creatingCardIntent;
        notifyListeners();
        pendingIntent = await _repository.createCardIntent(
          saleId: sale.id,
          amount: sale.total,
        );
      }
      checkoutPhase = CheckoutPhase.awaitingGateway;
      notifyListeners();

      if (pendingIntent?.isLocalDevelopment == true) {
        return confirmPendingCard();
      }
      return false;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible completar la venta.';
    }
    checkoutPhase = CheckoutPhase.error;
    notifyListeners();
    return false;
  }

  Future<bool> preparePendingCardPayment() async {
    final sale = pendingSale;
    if (sale == null || checkoutBusy) return false;
    if (pendingIntent?.intentId.isNotEmpty == true) {
      checkoutPhase = CheckoutPhase.awaitingGateway;
      notifyListeners();
      return true;
    }

    checkoutPhase = CheckoutPhase.creatingCardIntent;
    errorMessage = null;
    notifyListeners();
    try {
      final cardAmount = sale.pendingCardPayment?.amount ?? sale.total;
      pendingIntent = await _repository.createCardIntent(
        saleId: sale.id,
        amount: cardAmount,
      );
      checkoutPhase = CheckoutPhase.awaitingGateway;
      notifyListeners();
      if (pendingIntent?.isLocalDevelopment == true) {
        return confirmPendingCard();
      }
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible preparar el cobro con tarjeta.';
    }
    checkoutPhase = CheckoutPhase.error;
    notifyListeners();
    return false;
  }

  Future<bool> confirmPendingCard([String? gatewayRef]) async {
    if (checkoutBusy) return false;
    final intent = pendingIntent;
    if (intent == null || intent.intentId.isEmpty) {
      errorMessage = 'La venta pendiente aún no tiene un intent de pago.';
      checkoutPhase = CheckoutPhase.error;
      notifyListeners();
      return false;
    }
    final reference = intent.isLocalDevelopment
        ? 'POS-LOCAL-${DateTime.now().microsecondsSinceEpoch}'
        : gatewayRef?.trim() ?? '';
    if (reference.isEmpty) {
      errorMessage =
          'Ingresa la referencia real devuelta por la pasarela para confirmar.';
      checkoutPhase = CheckoutPhase.awaitingGateway;
      notifyListeners();
      return false;
    }

    checkoutPhase = CheckoutPhase.confirmingCard;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.confirmCardIntent(
        intentId: intent.intentId,
        gatewayRef: reference,
      );
      final confirmedSale = pendingSale!;
      pendingSale = null;
      pendingIntent = null;
      cart = const [];
      checkoutPhase = CheckoutPhase.success;
      lastSale = confirmedSale;
      try {
        lastSale = await _repository.getSale(confirmedSale.id);
      } on Object {
        // La confirmación ya fue aceptada; el ticket puede recargarse después.
      }
      await _refreshOperationalData();
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible confirmar el pago con la pasarela.';
    }
    checkoutPhase = CheckoutPhase.error;
    notifyListeners();
    return false;
  }

  Future<void> loadTicket(String ticketId) async {
    if (loadingTicket) return;
    loadingTicket = true;
    errorMessage = null;
    notifyListeners();
    try {
      selectedTicket = await _repository.getTicket(ticketId);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cargar el ticket.';
    }
    loadingTicket = false;
    notifyListeners();
  }

  void clearSelectedTicket() {
    selectedTicket = null;
    notifyListeners();
  }

  void resetCheckout() {
    if (hasPendingPayment || checkoutBusy) return;
    checkoutPhase = CheckoutPhase.idle;
    errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<CashShift?> _activeShiftOrNull() async {
    try {
      return await _repository.getActiveShift();
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<CashShiftSummary?> _summaryOrNull(String shiftId) async {
    try {
      return await _repository.getShiftSummary(shiftId);
    } on Object {
      return null;
    }
  }

  void _recoverPendingPayment() {
    pendingSale = null;
    pendingIntent = null;
    for (final ticket in tickets) {
      if (ticket.paymentStatus != PaymentStatus.pending) continue;
      pendingSale = ticket;
      final payment = ticket.pendingCardPayment;
      if (ticket.cardPaymentIntent != null) {
        pendingIntent = ticket.cardPaymentIntent;
      } else if (payment?.gatewayIntentId?.isNotEmpty == true) {
        pendingIntent = CardPaymentIntent.fromPayment(
          payment!,
          saleId: ticket.id,
        );
      }
      checkoutPhase = CheckoutPhase.awaitingGateway;
      break;
    }
    if (pendingSale == null && checkoutPhase != CheckoutPhase.success) {
      checkoutPhase = CheckoutPhase.idle;
    }
  }

  Future<void> _refreshOperationalData() async {
    try {
      activeShift = await _activeShiftOrNull();
      tickets = await _repository.getTickets();
      if (canManageShifts) shiftHistory = await _repository.getShifts();
      if (query.trim().isNotEmpty) {
        products = await _repository.searchProducts(query.trim());
      }
    } on Object {
      // La operación transaccional ya terminó; la recarga puede reintentarse.
    }
  }

  bool _checkoutFailure(String message) {
    errorMessage = message;
    checkoutPhase = CheckoutPhase.error;
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
