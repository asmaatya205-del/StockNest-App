import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../dao/user_dao.dart';
import '../models/user_model.dart';

class AuthRepository {
  final UserDao _userDao = UserDao();

  /// Hashes a plain-text password using the SHA-256 algorithm.
  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final existing = await _userDao.findByEmail(email);
    if (existing != null) throw Exception('Email already registered');

    final user = UserModel(
      name:      name,
      email:     email.toLowerCase().trim(),
      password:  _hashPassword(password),
      createdAt: DateTime.now().toIso8601String(),
    );

    final id = await _userDao.insert(user);
    return user.copyWith(id: id);
  }

  /// Validates user credentials by comparing the hashed input password
  /// against the stored hashed password in the database.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final user = await _userDao.findByEmail(email.toLowerCase().trim());
    if (user == null) throw Exception('Email not found');

    if (user.password != _hashPassword(password)) {
      throw Exception('Incorrect password');
    }
    return user;
  }

  Future<UserModel?> getUserById(int id) => _userDao.findById(id);

  /// Updates profile information. Enforces unique email verification and requires
  /// current password validation before allowing a new password configuration.
  Future<UserModel> updateProfile({
    required UserModel currentUser,
    required String name,
    required String email,
    String? newPassword,
    String? currentPassword,
  }) async {

    // Security Guard: Check if the new email is already occupied by another user account
    if (email.toLowerCase().trim() != currentUser.email) {
      final existing = await _userDao.findByEmail(email.toLowerCase().trim());
      if (existing != null) throw Exception('Email already in use');
    }

    String passwordToSave = currentUser.password;

    // Password Lifecycle Rule: Enforce current password checks before applying changes
    if (newPassword != null && newPassword.isNotEmpty) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw Exception('Current password is required');
      }
      if (currentUser.password != _hashPassword(currentPassword)) {
        throw Exception('Current password is incorrect');
      }
      passwordToSave = _hashPassword(newPassword);
    }

    final updated = currentUser.copyWith(
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password: passwordToSave,
    );

    await _userDao.update(updated);
    return updated;
  }
}