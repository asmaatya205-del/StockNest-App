import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isFirstTime = true;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isFirstTime => _isFirstTime;
  int? get userId => _currentUser?.id;

  /// Restores active sessions and pulls structural user references asynchronously from storage
  Future<void> initializeSession({required bool rememberMeChecked, required bool firstTimeFlag}) async {
    _isFirstTime = firstTimeFlag;

    if (rememberMeChecked) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final int savedUserId = prefs.getInt('active_user_id') ?? 0;

        if (savedUserId != 0) {
          _currentUser = await _repo.getUserById(savedUserId);
          if (_currentUser != null) {
            _status = AuthStatus.authenticated;
          } else {
            _status = AuthStatus.unauthenticated;
          }
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } catch (e) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated; // Enforce default safe state fallback instead of initial
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_isFirstTime) {
      _isFirstTime = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_time', false);
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password, bool rememberMe = false}) async {
    _setLoading();
    try {
      _currentUser = await _repo.login(email: email, password: password);

      if (_currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', rememberMe);
        await prefs.setInt('active_user_id', _currentUser!.id ?? 0);
        _isFirstTime = false;
        await prefs.setBool('is_first_time', false);

        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    _setLoading();
    try {
      _currentUser = await _repo.register(name: name, email: email, password: password);

      if (_currentUser != null) {
        _isFirstTime = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_first_time', false);
        await prefs.setBool('remember_me', true);
        await prefs.setInt('active_user_id', _currentUser!.id ?? 0);

        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Clears user session memory with strict sequential updates and wipes flat local storage keys securely
  Future<void> logout() async {
    // 1. Wipe local hardware disk shared keys first to prevent flash reload race conditions
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('active_user_id');

    // 2. Clear runtime heap allocation data state models
    _currentUser = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;

    // 3. Dispatch atomic update down stream to trigger GoRouter recalculation pipeline
    notifyListeners();
  }
  Future<bool> updateProfile({
    required String name,
    required String email,
    String? newPassword,
    String? currentPassword,
  }) async {
    if (_currentUser == null) return false;
    _setLoading();
    try {
      _currentUser = await _repo.updateProfile(
        currentUser: _currentUser!,
        name: name,
        email: email,
        newPassword: newPassword,
        currentPassword: currentPassword,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}