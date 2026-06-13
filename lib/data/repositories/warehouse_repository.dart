import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../dao/warehouse_dao.dart';
import '../dao/inventory_log_dao.dart';
import '../models/warehouse_model.dart';
import '../models/inventory_log_model.dart';

class WarehouseRepository {
  final WarehouseDao      _warehouseDao = WarehouseDao();
  final InventoryLogDao   _logDao       = InventoryLogDao();

  // Get database instance for executing ACID transactions
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<WarehouseModel> create(WarehouseModel warehouse) async {
    final id = await _warehouseDao.insert(warehouse);
    return warehouse.copyWith(id: id);
  }

  Future<List<WarehouseModel>> getRootWarehouses(int userId) =>
      _warehouseDao.getRootWarehouses(userId);

  Future<List<WarehouseModel>> getChildren(int parentId) =>
      _warehouseDao.getChildren(parentId);

  Future<List<WarehouseModel>> getAllWarehouses(int userId) =>
      _warehouseDao.getAllByUser(userId);

  Future<WarehouseModel?> getById(int id) =>
      _warehouseDao.findById(id);

  Future<List<Map<String, dynamic>>> getWarehouseProducts(int warehouseId) =>
      _warehouseDao.getWarehouseProducts(warehouseId);

  Future<void> update(WarehouseModel warehouse) =>
      _warehouseDao.update(warehouse);

  Future<void> delete(int id) => _warehouseDao.delete(id);

  Future<Map<int, int>> getProductCountPerWarehouse(int userId) =>
      _warehouseDao.getProductCountPerWarehouse(userId);

  /// Transfers a product quantity from one warehouse to another within an ACID transaction.
  /// Transfers a product quantity from one warehouse to another within a synchronized ACID transaction.
  Future<void> transferProduct({
    required int productId,
    required int fromWarehouseId,
    required int toWarehouseId,
    required double quantity,
    required int userId,
    String? note,
  }) async {
    final db = await _db;

    // Wrap all data modifications rigidly within the captured transaction instance context
    await db.transaction((txn) async {
      // 1. Check stock availability in the source warehouse using the active transaction pipeline
      final available = await _warehouseDao.getProductQuantity(fromWarehouseId, productId, txn: txn);
      if (available < quantity) {
        throw Exception('Insufficient quantity. Available: $available');
      }

      // 2. Deduct quantity from the source warehouse under the same transaction contract
      await _warehouseDao.upsertProductQuantity(
          fromWarehouseId, productId, available - quantity, txn: txn);

      // 3. Add quantity to the destination warehouse seamlessly
      final currentTarget = await _warehouseDao.getProductQuantity(toWarehouseId, productId, txn: txn);
      await _warehouseDao.upsertProductQuantity(
          toWarehouseId, productId, currentTarget + quantity, txn: txn);

      // 4. Log the stock transfer operation securely inside the atomic core block
      await _logDao.insert(
        InventoryLogModel(
          productId:       productId,
          fromWarehouseId: fromWarehouseId,
          toWarehouseId:   toWarehouseId,
          quantity:        quantity,
          logType:         LogType.transfer,
          note:            note,
          userId:          userId,
          createdAt:       DateTime.now().toIso8601String(),
        ),
        txn: txn, // ✅
      );
    });
  }
}