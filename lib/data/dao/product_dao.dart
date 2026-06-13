import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product_model.dart';

class ProductDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<int> insert(ProductModel p) async {
    final db = await _db;
    return await db.insert(
      'products',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<ProductModel>> getAllByUser(int userId) async {
    final rows = await (await _db).query(
      'products',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> findById(int id) async {
    final rows = await (await _db).query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : ProductModel.fromMap(rows.first);
  }

  /// Checks if a Stock Keeping Unit (SKU) is already assigned to a product.
  /// [excludeId] is used during updates to ignore the current product's own SKU.
  Future<bool> skuExists(String sku, {int? excludeId}) async {
    final rows = await (await _db).query(
      'products',
      where: excludeId != null ? 'sku = ? AND id != ?' : 'sku = ?',
      whereArgs: excludeId != null ? [sku, excludeId] : [sku],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> update(ProductModel p) async =>
      (await _db).update('products', p.toMap(),
          where: 'id = ?', whereArgs: [p.id]);

  /// Deletes a product along with all its related records.
  /// Wrapped in a database Transaction to ensure data integrity; if any delete fails,
  /// the whole operation rolls back to prevent leaving orphaned records.
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.transaction((txn) async {
      await txn.delete('inventory_logs',
          where: 'product_id = ?', whereArgs: [id]);
      await txn.delete('warehouse_products',
          where: 'product_id = ?', whereArgs: [id]);
      return await txn.delete('products',
          where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Aggregates and calculates the total quantity of a single product
  /// across all different warehouses. Returns 0 if the product has no stock anywhere.
  Future<double> getTotalQuantity(int productId) async {
    final result = await (await _db).rawQuery('''
      SELECT COALESCE(SUM(quantity), 0) AS total
      FROM warehouse_products
      WHERE product_id = ?
    ''', [productId]);
    return (result.first['total'] as num).toDouble();
  }

  /// Fetches items where current stock drops below or equals the localized alert threshold.
  /// Joins 'warehouse_products' with global 'products' and 'warehouses' because min_stock
  /// is managed independently per warehouse location.
  Future<List<Map<String, dynamic>>> getLowStockProducts(int userId) async {
    return (await _db).rawQuery('''
      SELECT p.id, p.name, p.unit, wp.min_stock, wp.quantity,
             w.id AS warehouse_id, w.name AS warehouse_name
      FROM warehouse_products wp
      JOIN products p ON p.id = wp.product_id
      JOIN warehouses w ON w.id = wp.warehouse_id
      WHERE p.user_id = ?
        AND wp.min_stock > 0
        AND wp.quantity <= wp.min_stock
      ORDER BY wp.quantity ASC
    ''', [userId]);
  }
}