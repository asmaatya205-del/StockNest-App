import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../dao/product_dao.dart';
import '../dao/warehouse_dao.dart';
import '../dao/inventory_log_dao.dart';
import '../models/product_model.dart';
import '../models/inventory_log_model.dart';

/// Repository layer acting as a single source of truth for all product and stock mutations.
/// Enforces complete isolation between business logic models and raw database drivers.
class ProductRepository {
  final ProductDao _productDao = ProductDao();
  final WarehouseDao _warehouseDao = WarehouseDao();
  final InventoryLogDao _logDao = InventoryLogDao();

  /// Asynchronously fetches the live centralized database instance for resource locking
  Future<Database> get _db => DatabaseHelper.instance.database;

  /// Creates a clean product record template and injects the database auto-increment ID
  Future<ProductModel> create(ProductModel product) async {
    if (product.sku != null && product.sku!.isNotEmpty) {
      final exists = await _productDao.skuExists(product.sku!);
      if (exists) throw Exception('SKU already exists');
    }
    // Captures the genuine auto-generated identity integer to avoid screen flickering or null references
    final id = await _productDao.insert(product);
    return product.copyWith(id: id);
  }

  /// Retrieves all synchronized products allocated under a specific user context bounds
  Future<List<ProductModel>> getAllProducts(int userId) =>
      _productDao.getAllByUser(userId);

  /// Resolves technical data profiles for a single targeted product instance
  Future<ProductModel?> getById(int id) =>
      _productDao.findById(id);

  /// Computes the aggregate stock levels of a product across all physical storage centers
  Future<double> getTotalQuantity(int productId) =>
      _productDao.getTotalQuantity(productId);

  /// Fetches subset lists displaying items whose stock levels have fallen below safety limits
  Future<List<Map<String, dynamic>>> getLowStockProducts(int userId) =>
      _productDao.getLowStockProducts(userId);

  /// Updates modified text fields across storage structures while defending against SKU collisions
  Future<void> update(ProductModel product) async {
    if (product.sku != null && product.sku!.isNotEmpty) {
      final exists = await _productDao.skuExists(product.sku!, excludeId: product.id);
      if (exists) throw Exception('SKU already exists');
    }
    await _productDao.update(product);
  }

  /// Purges a product entity completely by enforcing strict programmatic cascade operations across tables
  Future<void> delete(int id) async {
    final db = await _db;

    // Executes a clean ACID transaction scope to scrub relational remnants sequentially
    await db.transaction((txn) async {
      // 1. Flush subset records mapping quantity limits inside warehouse structures
      await txn.delete('warehouse_products', where: 'product_id = ?', whereArgs: [id]);

      // 2. Flush related operations logs bound tightly to this validation index
      await txn.delete('inventory_logs', where: 'product_id = ?', whereArgs: [id]);

      // 3. Conclude the transaction sequence by removing the actual isolated parent template
      await txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Delegation queries preserving layered isolation barriers across presentation scopes
  Future<List<InventoryLogModel>> getLogsByProductId(int productId) =>
      _logDao.getByProduct(productId);

  /// Retrieves comprehensive structural lifecycle operations charts bounded to a unique account key
  Future<List<InventoryLogModel>> getUserLogs(int userId) =>
      _logDao.getByUser(userId);

  /// Deposits stock updates securely by channeling queries strictly inside automated transaction contexts
  Future<void> addStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    required int userId,
    String? note,
    double? minStock, // ✅
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final current = await _warehouseDao.getProductQuantity(
          warehouseId, productId, txn: txn);
      await _warehouseDao.upsertProductQuantity(
          warehouseId, productId, current + quantity,
          txn: txn, minStock: minStock); // ✅
      await _logDao.insert(
        InventoryLogModel(
          productId:       productId,
          fromWarehouseId: warehouseId,
          quantity:        quantity,
          logType:         LogType.stockIn,
          note:            note,
          userId:          userId,
          createdAt:       DateTime.now().toIso8601String(),
        ),
        txn: txn,
      );
    });
  }
  /// Dispatches quantity reductions with transactional safety guards and automated rollback boundaries
  Future<void> removeStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    required int userId,
    String? note,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      final current = await _warehouseDao.getProductQuantity(warehouseId, productId, txn: txn);
      if (current < quantity) {
        throw Exception('Insufficient quantity. Available: $current');
      }
      await _warehouseDao.upsertProductQuantity(warehouseId, productId, current - quantity, txn: txn);

      await _logDao.insert(
        InventoryLogModel(
          productId: productId,
          fromWarehouseId: warehouseId,
          quantity: quantity,
          logType: LogType.stockOut,
          note: note,
          userId: userId,
          createdAt: DateTime.now().toIso8601String(),
        ),
        txn: txn,
      );
    });
  }
}