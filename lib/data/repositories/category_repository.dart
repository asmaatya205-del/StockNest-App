import '../dao/category_dao.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final CategoryDao _categoryDao = CategoryDao();

  Future<List<CategoryModel>> getCategories(int userId) async {
    await _categoryDao.seedDefaults();
    return _categoryDao.getAll(userId);
  }

  Future<CategoryModel> createCategory(CategoryModel cat) => _categoryDao.insert(cat);

  Future<void> deleteCategory(int id) => _categoryDao.delete(id);

  Future<void> updateCategory(CategoryModel cat) => _categoryDao.update(cat);
}