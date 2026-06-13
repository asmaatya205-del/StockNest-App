import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stocknest.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final path = join(await getDatabasesPath(), fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate:  _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configures database settings during open lifecycle step.
  /// Enforces SQLite foreign key constraints implicitly across all relationships.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ── Migration Lifecycle ──────────────────────────────────────────────────────

  /// Handles schema evolution when incremental version upgrades occur.
  /// Safely injects the new categories structure for legacy version 1 databases.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCategoriesTable(db);
    }
  }

  // ── Database Schema Creation ────────────────────────────────────────────────

  /// Initializes the foundational relational database layout for initial installations.
  /// Configures data tables with explicit cascading deletes to prevent orphaned entries.
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        email      TEXT    UNIQUE NOT NULL,
        password   TEXT    NOT NULL,
        created_at TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouses (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        location    TEXT,
        description TEXT,
        capacity    REAL,
        parent_id   INTEGER,
        user_id     INTEGER NOT NULL,
        created_at  TEXT    NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES warehouses(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id)   REFERENCES users(id)      ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        sku        TEXT    UNIQUE,
        category   TEXT,
        unit       TEXT,
        user_id    INTEGER NOT NULL,
        created_at TEXT    NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    /// Many-to-Many junction table mapping products to storage locations with stock thresholds
    await db.execute('''
      CREATE TABLE warehouse_products (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        warehouse_id INTEGER NOT NULL,
        product_id   INTEGER NOT NULL,
        quantity     REAL    NOT NULL DEFAULT 0,
        min_stock    REAL    NOT NULL DEFAULT 0,
        updated_at   TEXT    NOT NULL,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id)   REFERENCES products(id)   ON DELETE CASCADE,
        UNIQUE (warehouse_id, product_id)
      )
    ''');

    /// Tracks inventory audit trails; safeguards current source logs via fallback handling
    await db.execute('''
      CREATE TABLE inventory_logs (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id        INTEGER NOT NULL,
        from_warehouse_id INTEGER NOT NULL,
        to_warehouse_id   INTEGER,
        quantity          REAL    NOT NULL,
        log_type          TEXT    NOT NULL,
        note              TEXT,
        user_id           INTEGER NOT NULL,
        created_at        TEXT    NOT NULL,
        FOREIGN KEY (product_id)        REFERENCES products(id)   ON DELETE CASCADE,
        FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
        FOREIGN KEY (to_warehouse_id)   REFERENCES warehouses(id) ON DELETE SET NULL,
        FOREIGN KEY (user_id)           REFERENCES users(id)      ON DELETE CASCADE
      )
    ''');

    await _createCategoriesTable(db);
  }

  // ── Shared Schema Component ──────────────────────────────────────────────────

  /// Isolated table structure builder shared dynamically by initialization and patch routers
  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        icon       TEXT    NOT NULL DEFAULT '📦',
        is_default INTEGER NOT NULL DEFAULT 0,
        user_id    INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async => (await database).close();
}