import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_exception.dart';
import '../../../pos/data/models/pos_models.dart';
import '../../data/models/retail_models.dart';
import '../../data/repositories/retail_repository.dart';

class RetailController extends ChangeNotifier {
  RetailController(
    this._repository, {
    String? initialBranchId,
    this.canManageFittingRooms = false,
    this.canManageDrafts = false,
  }) : branchId = initialBranchId;

  final RetailRepository _repository;

  String? branchId;
  bool canManageFittingRooms;
  bool canManageDrafts;

  bool loadingRooms = false;
  bool loadingDrafts = false;
  bool loadingDetail = false;
  bool loadingProducts = false;
  bool saving = false;
  String? errorMessage;

  List<FittingRoom> rooms = const [];
  List<RetailDraft> drafts = const [];
  FittingRoom? selectedRoom;
  CheckoutResult? lastCheckoutResult;
  List<PosProduct> searchResults = const [];

  FittingRoomStatus? statusFilter;
  RetailDraftStatus? draftStatusFilter = RetailDraftStatus.pending;

  CancelToken? _roomsToken;
  CancelToken? _draftsToken;
  CancelToken? _productsToken;
  int _branchGeneration = 0;

  bool get loading => loadingRooms || loadingDrafts;

  List<FittingRoom> get filteredRooms => rooms
      .where((room) => statusFilter == null || room.status == statusFilter)
      .toList(growable: false);

  void updateSession({
    String? branchId,
    required bool canManageRooms,
    required bool canManageDrafts,
  }) {
    final branchChanged = this.branchId != branchId;
    this.branchId = branchId;
    this.canManageFittingRooms = canManageRooms;
    this.canManageDrafts = canManageDrafts;
    if (branchChanged) {
      _branchGeneration++;
      _roomsToken?.cancel('Cambio de sucursal.');
      _draftsToken?.cancel('Cambio de sucursal.');
      rooms = const [];
      drafts = const [];
      selectedRoom = null;
      lastCheckoutResult = null;
      statusFilter = null;
      draftStatusFilter = RetailDraftStatus.pending;
      errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (branchId == null) {
      errorMessage = 'Selecciona una sucursal antes de abrir probadores.';
      notifyListeners();
      return;
    }
    await Future.wait([
      if (canManageFittingRooms) loadRooms(force: force),
      if (canManageDrafts) loadDrafts(force: force),
    ]);
  }

  Future<void> loadRooms({bool force = false}) async {
    if (!canManageFittingRooms || branchId == null || (loadingRooms && !force)) return;
    _roomsToken?.cancel('Recarga de probadores reemplazada.');
    final token = CancelToken();
    _roomsToken = token;
    final generation = _branchGeneration;
    loadingRooms = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.listRooms(status: statusFilter, cancelToken: token);
      if (generation != _branchGeneration || token.isCancelled) return;
      rooms = result;
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        errorMessage = 'No fue posible cargar los probadores.';
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cargar los probadores.';
    } finally {
      if (generation == _branchGeneration && identical(_roomsToken, token)) {
        loadingRooms = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadDrafts({bool force = false}) async {
    if (!canManageDrafts || branchId == null || (loadingDrafts && !force)) return;
    _draftsToken?.cancel('Recarga de drafts reemplazada.');
    final token = CancelToken();
    _draftsToken = token;
    final generation = _branchGeneration;
    loadingDrafts = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.listDrafts(status: draftStatusFilter, cancelToken: token);
      if (generation != _branchGeneration || token.isCancelled) return;
      drafts = result;
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        errorMessage = 'No fue posible cargar la cola de cobros.';
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cargar la cola de cobros.';
    } finally {
      if (generation == _branchGeneration && identical(_draftsToken, token)) {
        loadingDrafts = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadRoomDetail(String roomId) async {
    final generation = _branchGeneration;
    loadingDetail = true;
    errorMessage = null;
    selectedRoom = null;
    notifyListeners();
    try {
      final room = await _repository.getRoom(roomId);
      if (generation != _branchGeneration) return;
      selectedRoom = room;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cargar los detalles del probador.';
    } finally {
      if (generation == _branchGeneration) {
        loadingDetail = false;
        notifyListeners();
      }
    }
  }

  Future<bool> openSession(String roomId, String clientName) async {
    return _mutate(() async {
      final session = await _repository.openSession(roomId, clientName: clientName);
      if (selectedRoom?.id == roomId) {
        selectedRoom = selectedRoom?.copyWith(activeSession: session, status: FittingRoomStatus.occupied);
      }
      await loadRooms(force: true);
    });
  }

  Future<bool> addItem(String roomId, String productId, int quantity) async {
    return _mutate(() async {
      await _repository.addItem(roomId, productId: productId, quantity: quantity);
      if (selectedRoom?.id == roomId) {
        final updatedItems = await _repository.listItems(roomId);
        final activeSession = selectedRoom?.activeSession;
        if (activeSession != null) {
          selectedRoom = selectedRoom?.copyWith(
            activeSession: activeSession.copyWith(items: updatedItems),
          );
        }
      }
    });
  }

  Future<bool> removeItem(String roomId, String itemId) async {
    return _mutate(() async {
      await _repository.removeItem(roomId, itemId);
      if (selectedRoom?.id == roomId) {
        final activeSession = selectedRoom?.activeSession;
        if (activeSession != null) {
          final updatedItems = activeSession.items.where((item) => item.id != itemId).toList();
          selectedRoom = selectedRoom?.copyWith(
            activeSession: activeSession.copyWith(items: updatedItems),
          );
        }
      }
    });
  }

  Future<bool> checkout({
    required String sessionId,
    required List<String> returnedItemIds,
    required List<String> saleItemIds,
  }) async {
    final idempotencyKey = const Uuid().v4();
    return _mutate(() async {
      final result = await _repository.checkout(
        sessionId,
        returnedItemIds: returnedItemIds,
        saleItemIds: saleItemIds,
        idempotencyKey: idempotencyKey,
      );
      lastCheckoutResult = result;
      if (selectedRoom?.activeSession?.id == sessionId) {
        selectedRoom = selectedRoom?.copyWith(
          activeSession: null,
          status: FittingRoomStatus.available,
        );
      }
      await loadRooms(force: true);
      await loadDrafts(force: true);
    });
  }

  Future<bool> cancelDraft(String draftId) async {
    return _mutate(() async {
      await _repository.cancelDraft(draftId);
      await loadDrafts(force: true);
    });
  }

  Future<bool> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      searchResults = const [];
      notifyListeners();
      return true;
    }
    _productsToken?.cancel('Búsqueda reemplazada.');
    final token = CancelToken();
    _productsToken = token;
    final generation = _branchGeneration;
    loadingProducts = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.searchProducts(query, cancelToken: token);
      if (generation != _branchGeneration || token.isCancelled) return false;
      searchResults = result;
      return true;
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        errorMessage = 'No fue posible buscar productos.';
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible buscar productos.';
    } finally {
      if (generation == _branchGeneration && identical(_productsToken, token)) {
        loadingProducts = false;
        notifyListeners();
      }
    }
    return false;
  }

  void setStatusFilter(FittingRoomStatus? status) {
    statusFilter = status;
    loadRooms(force: true);
  }

  void setDraftStatusFilter(RetailDraftStatus? status) {
    draftStatusFilter = status;
    loadDrafts(force: true);
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearLastCheckout() {
    lastCheckoutResult = null;
    notifyListeners();
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (saving) return false;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      saving = false;
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

  @override
  void dispose() {
    _roomsToken?.cancel('Controlador cerrado.');
    _draftsToken?.cancel('Controlador cerrado.');
    _productsToken?.cancel('Controlador cerrado.');
    super.dispose();
  }
}

// Extension to help copyWith in controllers
extension on FittingRoom {
  FittingRoom copyWith({
    FittingRoomSession? activeSession,
    FittingRoomStatus? status,
  }) => FittingRoom(
    id: id,
    branchId: branchId,
    code: code,
    name: name,
    status: status ?? this.status,
    activeSession: activeSession,
  );
}

extension on FittingRoomSession {
  FittingRoomSession copyWith({
    List<FittingRoomSessionItem>? items,
  }) => FittingRoomSession(
    id: id,
    fittingRoomId: fittingRoomId,
    sellerId: sellerId,
    clientName: clientName,
    status: status,
    openedAt: openedAt,
    closedAt: closedAt,
    items: items ?? this.items,
    seller: seller,
  );
}
