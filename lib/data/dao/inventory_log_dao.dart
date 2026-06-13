import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/inventory_log_model.dart';

class InventoryLogDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  // Resolves structural transaction locks by falling back gracefully to static connections if missing
  DatabaseExecutor _getExecutor(Transaction? txn, Database db) => txn ?? db;

  /// Inserts an inventory log while supporting dynamic transaction pipeline migration
  Future<int> insert(InventoryLogModel log, {Transaction? txn}) async {
    final db = await _db;
    final executor = _getExecutor(txn, db);
    return await executor.insert('inventory_logs', log.toMap());
  }

  Future<List<InventoryLogModel>> getByUser(int userId, {int limit = 50}) async {
    final rows = await (await _db).rawQuery('''
      SELECT
        il.*,
        p.name  AS product_name,
        wf.name AS from_warehouse_name,
        wt.name AS to_warehouse_name
      FROM inventory_logs il
      JOIN products   p  ON p.id  = il.product_id
      JOIN warehouses wf ON wf.id = il.from_warehouse_id
      LEFT JOIN warehouses wt ON wt.id = il.to_warehouse_id
      WHERE il.user_id = ?
      ORDER BY il.created_at DESC
      LIMIT ?
    ''', [userId, limit]);
    return rows.map(InventoryLogModel.fromMap).toList();
  }

  Future<List<InventoryLogModel>> getByProduct(int productId) async {
    final rows = await (await _db).rawQuery('''
      SELECT
        il.*,
        p.name  AS product_name,
        wf.name AS from_warehouse_name,
        wt.name AS to_warehouse_name
      FROM inventory_logs il
      JOIN products   p  ON p.id  = il.product_id
      JOIN warehouses wf ON wf.id = il.from_warehouse_id
      LEFT JOIN warehouses wt ON wt.id = il.to_warehouse_id
      WHERE il.product_id = ?
      ORDER BY il.created_at DESC
    ''', [productId]);
    return rows.map(InventoryLogModel.fromMap).toList();
  }

  Future<List<InventoryLogModel>> getByWarehouse(int warehouseId) async {
    final rows = await (await _db).rawQuery('''
      SELECT
        il.*,
        p.name  AS product_name,
        wf.name AS from_warehouse_name,
        wt.name AS to_warehouse_name
      FROM inventory_logs il
      JOIN products   p  ON p.id  = il.product_id
      JOIN warehouses wf ON wf.id = il.from_warehouse_id
      LEFT JOIN warehouses wt ON wt.id = il.to_warehouse_id
      WHERE il.from_warehouse_id = ? OR il.to_warehouse_id = ?
      ORDER BY il.created_at DESC
    ''', [warehouseId, warehouseId]);
    return rows.map(InventoryLogModel.fromMap).toList();
  }
}