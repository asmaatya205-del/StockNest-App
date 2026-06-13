import 'package:flutter/material.dart';
import 'package:stock_nest/domain/providers/warehouse_provider.dart' show LoadingStatus;
import '../../data/models/product_model.dart';
import '../../data/models/inventory_log_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();

  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  List<InventoryLogModel> _logs = [];
  ProductModel? _selected;
  double _selectedTotal = 0;
  LoadingStatus _status = LoadingStatus.idle;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<Map<String, dynamic>> get lowStockItems => _lowStockItems;
  List<InventoryLogModel> get logs => _logs;
  ProductModel? get selected => _selected;
  double get selectedTotal => _selectedTotal;
  LoadingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == LoadingStatus.loading;

  Future<void> loadProducts(int userId) async {
    _setLoading();
    try {
      _products = await _repo.getAllProducts(userId);
      _lowStockItems = await _repo.getLowStockProducts(userId);
      _setSuccess();
    } catch (e) {
      _setError(e);
    }
  }

  /// Loads granular insights for a specific product context view.
  /// Synchronizes active state fields including total computed stocks and transactional log streams.
  Future<void> loadProductDetail(int productId) async {
    _setLoading();
    try {
      _selected = await _repo.getById(productId);
      _selectedTotal = await _repo.getTotalQuantity(productId);
      _logs = await _repo.getLogsByProductId(productId);
      _setSuccess();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> loadUserLogs(int userId) async {
    _setLoading();
    try {
      _logs = await _repo.getUserLogs(userId);
      _setSuccess();
    } catch (e) {
      _setError(e);
    }
  }

  /// Creates a product and returns the instantiated object containing its SQLite primary ID key.
  /// Safely catches internal database engine disruptions and logs complete stacktraces to debug console.
  Future<ProductModel?> createProductWithId(ProductModel product) async {
    _status = LoadingStatus.loading;
    notifyListeners();
    try {
      final ProductModel createdProduct = await _repo.create(product);
      _products = [..._products, createdProduct];
      _lowStockItems = await _repo.getLowStockProducts(product.userId);
      _status = LoadingStatus.success;
      notifyListeners();
      return createdProduct;
    } catch (e, stacktrace) {
      print("🚨 CRITICAL PRODUCT CREATION ERROR: $e");
      print("🚨 STACKTRACE: $stacktrace");
      _setError(e);
      return null;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    _setLoading();
    try {
      await _repo.update(product);
      _selected = product;
      _products = _products.map((p) => p.id == product.id ? product : p).toList();
      _lowStockItems = await _repo.getLowStockProducts(product.userId);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> deleteProduct(int id, int userId) async {
    _setLoading();
    try {
      await _repo.delete(id);
      _products = _products.where((p) => p.id != id).toList();
      _lowStockItems = await _repo.getLowStockProducts(userId);
      if (_selected?.id == id) {
        _selected = null;
        _selectedTotal = 0;
      }
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  /// Increments stock allocation inside a specific warehouse and automatically
  /// updates low stock tracking matrices alongside active detail view fields.
  Future<bool> addStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    required int userId,
    String? note,
    double? minStock,
  }) async {
    _setLoading();
    try {
      await _repo.addStock(
        productId:   productId,
        warehouseId: warehouseId,
        quantity:    quantity,
        userId:      userId,
        note:        note,
        minStock:    minStock,
      );
      _lowStockItems = await _repo.getLowStockProducts(userId);
      if (_selected?.id == productId) {
        _selectedTotal = await _repo.getTotalQuantity(productId);
        _logs = await _repo.getLogsByProductId(productId);
      }
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  /// Decrements stock availability levels within a given warehouse location.
  /// Refreshes low stock alerts and updates quantities on active memory context.
  Future<bool> removeStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    required int userId,
    String? note,
  }) async {
    _setLoading();
    try {
      await _repo.removeStock(
        productId: productId,
        warehouseId: warehouseId,
        quantity: quantity,
        userId: userId,
        note: note,
      );
      _lowStockItems = await _repo.getLowStockProducts(userId);
      if (_selected?.id == productId) {
        _selectedTotal = await _repo.getTotalQuantity(productId);
        _logs = await _repo.getLogsByProductId(productId);
      }
      _setSuccess();
      return true;
    } catch (e) {
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