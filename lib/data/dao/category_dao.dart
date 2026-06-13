import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';

/// Data Access Object (DAO) for managing Category database operations.
/// Handles both built-in global default categories and user-specific custom categories.
class CategoryDao {
  final _db = DatabaseHelper.instance;

  // ── Global Default Categories ────────────────────────────────────────────────
  // These categories are available to all users and cannot be modified or deleted.
  static const List<Map<String, dynamic>> _defaults = [
    {'name': 'Food & Beverages',  'icon': '🍔', 'is_default': 1, 'user_id': null},
    {'name': 'Medicine',          'icon': '💊', 'is_default': 1, 'user_id': null},
    {'name': 'Electronics',       'icon': '💻', 'is_default': 1, 'user_id': null},
    {'name': 'Clothing',          'icon': '👕', 'is_default': 1, 'user_id': null},
    {'name': 'Tools & Equipment', 'icon': '🔧', 'is_default': 1, 'user_id': null},
    {'name': 'Raw Materials',     'icon': '🏗️', 'is_default': 1, 'user_id': null},
    {'name': 'Packaging',         'icon': '📦', 'is_default': 1, 'user_id': null},
    {'name': 'Cleaning Supplies', 'icon': '🧹', 'is_default': 1, 'user_id': null},
    {'name': 'Office Supplies',   'icon': '🖊️', 'is_default': 1, 'user_id': null},
    {'name': 'Other',             'icon': '🗂️', 'is_default': 1, 'user_id': null},
  ];

  // ── Seeding & Initialization ───────────────────────────────────────────────

  /// Seeds the database with system-default categories if they don't already exist.
  /// Typically called once during database creation or initialization lifecycle.
  Future<void> seedDefaults() async {
    final db    = await _db.database;

    // Check if the defaults are already seeded to prevent duplicate rows
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories WHERE is_default = 1'),
    ) ?? 0;

    if (count > 0) return; // Guard: Defaults are already present

    // Use an isolated transaction batch for bulk inserting efficiently
    final batch = db.batch();
    for (final row in _defaults) {
      batch.insert('categories', row);
    }
    await batch.commit(noResult: true);
  }

  // ── Fetch Operations ────────────────────────────────────────────────────────

  /// Retrieves a unified list of global default categories alongside custom
  /// categories created specifically by the authenticated [userId].
  /// Ordered so that default categories appear first, then sorted alphabetically.
  Future<List<CategoryModel>> getAll(int userId) async {
    final db   = await _db.database;
    final rows = await db.query(
      'categories',
      where:   'is_default = 1 OR user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_default DESC, name ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  // ── Write Operations ────────────────────────────────────────────────────────

  /// Inserts a new custom category tied to a specific user into the database.
  /// Automatically extracts the auto-incremented primary key [id] and returns the updated model.
  Future<CategoryModel> insert(CategoryModel cat) async {
    final db = await _db.database;

    // Create map copy and strip the id to allow SQLite to auto-generate the primary key
    final id = await db.insert('categories', cat.toMap()..remove('id'));

    return CategoryModel(
      id:        id,
      name:      cat.name,
      icon:      cat.icon,
      isDefault: false,
      userId:    cat.userId,
    );
  }

  /// Updates an existing custom category's properties.
  /// Security Guard: Enforces that only non-default categories (`is_default = 0`) can be modified.
  Future<void> update(CategoryModel cat) async {
    final db = await _db.database;
    await db.update(
      'categories',
      cat.toMap(),
      where: 'id = ? AND is_default = 0',
      whereArgs: [cat.id],
    );
  }

  /// Deletes a specific custom category by its [id].
  /// Security Guard: Enforces that system-default categories remain fully protected from deletion.
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(
      'categories',
      where:     'id = ? AND is_default = 0',
      whereArgs: [id],
    );
  }
}