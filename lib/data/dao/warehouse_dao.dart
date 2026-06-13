import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/warehouse_model.dart';

class WarehouseDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  /// Helper to determine whether to execute queries within an active transaction
  /// context or directly fallback to the standard database instance.
  DatabaseExecutor _getExecutor(Transaction? txn, Database db) => txn ?? db;

  Future<int> insert(WarehouseModel w) async {
    final db = await _db;

    // Security Guard: Prevents unassigned user data leaks by blocking zero IDs
    if (w.userId == 0) {
      throw Exception('Database Insert Failure: user_id cannot be zero or unassigned.');
    }
    return await db.insert(
      'warehouses',
      w.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<WarehouseModel>> getRootWarehouses(int userId) async {
    final rows = await (await _db).query(
      'warehouses',
      where: 'user_id = ? AND parent_id IS NULL',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return rows.map(WarehouseModel.fromMap).toList();
  }

  Future<List<WarehouseModel>> getChildren(int parentId) async {
    final rows = await (await _db).query(
      'warehouses',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );
    return rows.map(WarehouseModel.fromMap).toList();
  }

  Future<List<WarehouseModel>> getAllByUser(int userId) async {
    final rows = await (await _db).query(
      'warehouses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return rows.map(WarehouseModel.fromMap).toList();
  }

  Future<WarehouseModel?> findById(int id) async {
    final rows = await (await _db).query(
      'warehouses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : WarehouseModel.fromMap(rows.first);
  }

  Future<int> update(WarehouseModel w) async =>
      (await _db).update('warehouses', w.toMap(),
          where: 'id = ?', whereArgs: [w.id]);

  /// Cascade Deletion: Wrapped in a database Transaction to safely clean up all
  /// related sub-warehouses, log records, and stock entries simultaneously.
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.transaction((txn) async {
      final children = await txn.query('warehouses',
          where: 'parent_id = ?', whereArgs: [id]);

      // Step 1: Recursively purge data for all children sub-warehouses
      for (final child in children) {
        final childId = child['id'] as int;
        await txn.delete('inventory_logs',
            where: 'from_warehouse_id = ? OR to_warehouse_id = ?',
            whereArgs: [childId, childId]);
        await txn.delete('warehouse_products',
            where: 'warehouse_id = ?', whereArgs: [childId]);
        await txn.delete('warehouses',
            where: 'id = ?', whereArgs: [childId]);
      }

      // Step 2: Clear historical records and stock for the parent warehouse before deletion
      await txn.delete('inventory_logs',
          where: 'from_warehouse_id = ? OR to_warehouse_id = ?',
          whereArgs: [id, id]);
      await txn.delete('warehouse_products',
          where: 'warehouse_id = ?', whereArgs: [id]);
      return await txn.delete('warehouses',
          where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<double> getProductQuantity(int warehouseId, int productId,
      {Transaction? txn}) async {
    final db = await _db;
    final executor = _getExecutor(txn, db);
    final rows = await executor.query(
      'warehouse_products',
      columns: ['quantity'],
      where: 'warehouse_id = ? AND product_id = ?',
      whereArgs: [warehouseId, productId],
      limit: 1,
    );
    return rows.isEmpty ? 0.0 : (rows.first['quantity'] as num).toDouble();
  }

  /// Upsert Mechanism: Automatically handles both initial inventory row insertion
  /// and updates existing rows, with conditional localized [minStock] threshold configuration.
  Future<void> upsertProductQuantity(
      int warehouseId, int productId, double quantity,
      {Transaction? txn, double? minStock}) async {
    final db = await _db;
    final executor = _getExecutor(txn, db);
    final now = DateTime.now().toIso8601String();

    final existing = await executor.query(
      'warehouse_products',
      where: 'warehouse_id = ? AND product_id = ?',
      whereArgs: [warehouseId, productId],
    );

    if (existing.isEmpty) {
      await executor.insert('warehouse_products', {
        'warehouse_id': warehouseId,
        'product_id':   productId,
        'quantity':     quantity,
        'min_stock':    minStock ?? 0.0, // ✅ Default localized alert floor setup
        'updated_at':   now,
      });
    } else {
      final updateData = <String, dynamic>{
        'quantity':   quantity,
        'updated_at': now,
      };
      // ✅ Only updates localized min_stock threshold if an explicit parameter value is passed
      if (minStock != null) updateData['min_stock'] = minStock;

      await executor.update(
        'warehouse_products',
        updateData,
        where: 'warehouse_id = ? AND product_id = ?',
        whereArgs: [warehouseId, productId],
      );
    }
  }

  /// Joint query tracking localized min_stock rules bound directly to specific warehouse locations
  Future<List<Map<String, dynamic>>> getWarehouseProducts(
      int warehouseId) async {
    return (await _db).rawQuery('''
      SELECT p.id, p.name, p.sku, p.unit, wp.quantity, wp.min_stock
      FROM warehouse_products wp
      JOIN products p ON p.id = wp.product_id
      WHERE wp.warehouse_id = ?
      ORDER BY p.name ASC
    ''', [warehouseId]);
  }

  Future<Map<int, int>> getProductCountPerWarehouse(int userId) async {
    final rows = await (await _db).rawQuery('''
    SELECT wp.warehouse_id, COUNT(wp.product_id) as product_count
    FROM warehouse_products wp
    JOIN warehouses w ON w.id = wp.warehouse_id
    WHERE w.user_id = ?
    GROUP BY wp.warehouse_id
  ''', [userId]);
    return {
      for (final row in rows)
        row['warehouse_id'] as int: row['product_count'] as int
    };
  }
}