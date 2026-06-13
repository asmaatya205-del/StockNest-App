import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final _repository = CategoryRepository();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  /// Fetches the unified list of categories from the repository.
  /// Manages the loading state and dispatches UI notifications via notifyListeners().
  Future<void> loadCategories(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _repository.getCategories(userId);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  /// Deletes a specific custom category and triggers a silent pull to refresh
  /// the active cache context bound to the currently authenticated user.
  Future<void> deleteCategory(int id, int userId) async {
    await _repository.deleteCategory(id);
    await loadCategories(userId);
  }

  /// Updates properties for an existing custom category entry and refreshes data.
  Future<void> updateCategory(CategoryModel cat, int userId) async {
    await _repository.updateCategory(cat);
    await loadCategories(userId);
  }

  /// Composes a new Category instance, stores it into local storage,
  /// and automatically reloads the view list model to display the new entry.
  Future<void> addCategory(String name, String icon, int userId) async {
    final newCat = CategoryModel(name: name, icon: icon, userId: userId);
    await _repository.createCategory(newCat);
    await loadCategories(userId);
  }
}