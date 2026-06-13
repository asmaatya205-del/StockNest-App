import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class UserDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<int> insert(UserModel user) async {
    final db = await _db;
    return db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<UserModel?> findByEmail(String email) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<UserModel?> findById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<int> update(UserModel user) async {
    final db = await _db;
    return db.update('users', user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }
}