import 'package:flutter/material.dart';
import 'package:stock_nest/domain/providers/warehouse_provider.dart' show LoadingStatus;
import '../../data/models/warehouse_model.dart';
import '../../data/repositories/warehouse_repository.dart';

enum LoadingStatus { idle, loading, success, error }

class WarehouseProvider extends ChangeNotifier {
  final WarehouseRepository _repo = WarehouseRepository();

  List<WarehouseModel> _rootWarehouses = [];
  List<WarehouseModel> _allWarehouses = [];
  List<WarehouseModel> _children = [];
  List<Map<String, dynamic>> _warehouseProducts = [];
  WarehouseModel? _selected;
  LoadingStatus _status = LoadingStatus.idle;
  String? _errorMessage;
  bool _isTransferring = false;
  bool _isDeleting = false;

  /// Holds a localized cached map pairing each Warehouse ID directly with its total active product row count.
  Map<int, int> _productCountPerWarehouse = {};

  List<WarehouseModel> get rootWarehouses => _rootWarehouses;
  List<WarehouseModel> get allWarehouses => _allWarehouses;
  List<WarehouseModel> get children => _children;
  List<Map<String, dynamic>> get warehouseProducts => _warehouseProducts;
  WarehouseModel? get selected => _selected;
  LoadingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == LoadingStatus.loading || _isTransferring || _isDeleting;

  Map<int, int> get productCountPerWarehouse => _productCountPerWarehouse;

  /// Fetches top-level root warehouses and concurrently pre-loads the localized product counting map matrices.
  Future<void> loadRootWarehouses(int userId) async {
    _setLoading();
    try {
      _rootWarehouses = await _repo.getRootWarehouses(userId);
      _productCountPerWarehouse = await _repo.getProductCountPerWarehouse(userId);
      _setSuccess();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> loadAllWarehouses(int userId) async {
    _setLoading();
    try {
      _allWarehouses = await _repo.getAllWarehouses(userId);
      _setSuccess();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> loadChildren(int parentId) async {
    _setLoading();
    try {
      _children = await _repo.getChildren(parentId);
      _setSuccess();
    } catch (e) {
      _setError(e);
    }
  }

  /// Pulls exhaustive properties for a targeted warehouse, including child tree structures
  /// and localized product balance lists to synchronize the active detail view context.
  Future<void> loadWarehouseDetail(int warehouseId) async {
    _setLoading();
    try {
      _selected = await _repo.getById(warehouseId);
      _children = await _repo.getChildren(warehouseId);
      _warehouseProducts = await _repo.getWarehouseProducts(warehouseId);
      _setSuccess();
    } catch (e) {
      _setError(e);
    }
  }

  /// Registers a warehouse location into storage. Automatically appends it to root arrays
  /// or nested sub-warehouse child sets depending on its relational properties.
  Future<bool> createWarehouse(WarehouseModel warehouse, int authenticatedUserId) async {
    _setLoading();
    try {
      final WarehouseModel lockedWarehouse = warehouse.copyWith(userId: authenticatedUserId);
      final created = await _repo.create(lockedWarehouse);

      if (lockedWarehouse.isRoot) {
        _rootWarehouses = [..._rootWarehouses, created];
      } else {
        _children = [..._children, created];
      }

      _allWarehouses = await _repo.getAllWarehouses(authenticatedUserId);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> updateWarehouse(WarehouseModel warehouse) async {
    _setLoading();
    try {
      await _repo.update(warehouse);
      _selected = warehouse;
      _rootWarehouses = _rootWarehouses.map((w) => w.id == warehouse.id ? warehouse : w).toList();
      _children = _children.map((w) => w.id == warehouse.id ? warehouse : w).toList();
      _allWarehouses = await _repo.getAllWarehouses(warehouse.userId);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> deleteWarehouse(int id, int userId) async {
    _isDeleting = true;
    notifyListeners();
    try {
      await _repo.delete(id);

      _rootWarehouses = _rootWarehouses.where((w) => w.id != id).toList();
      _children = _children.where((w) => w.id != id).toList();
      _allWarehouses = await _repo.getAllWarehouses(userId);

      if (_selected?.id == id) {
        _selected = null;
        _warehouseProducts = [];
      }

      _isDeleting = false;
      _status = LoadingStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _isDeleting = false;
      _setError(e);
      return false;
    }
  }

  /// Dispatches internal stock quantities between two warehouses and automatically
  /// re-loads product matrices if the currently viewed warehouse is impacted by the transaction.
  Future<bool> transferProduct({
    required int productId,
    required int fromWarehouseId,
    required int toWarehouseId,
    required double quantity,
    required int userId,
    String? note,
  }) async {
    _isTransferring = true;
    notifyListeners();
    try {
      await _repo.transferProduct(
        productId: productId,
        fromWarehouseId: fromWarehouseId,
        toWarehouseId: toWarehouseId,
        quantity: quantity,
        userId: userId,
        note: note,
      );

      if (_selected != null &&
          (_selected!.id == fromWarehouseId || _selected!.id == toWarehouseId)) {
        _warehouseProducts = await _repo.getWarehouseProducts(_selected!.id!);
      }

      _isTransferring = false;
      _status = LoadingStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _isTransferring = false;
      _setError(e);
      return false;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading() {
    _status = LoadingStatus.loading;
    notifyListeners();
  }

  void _setSuccess() {
    _status = LoadingStatus.success;
    notifyListeners();
  }

  void _setError(Object e) {
    _status = LoadingStatus.error;
    _errorMessage = e.toString().replaceFirst('Exception: ', '');
    notifyListeners();
  }
}