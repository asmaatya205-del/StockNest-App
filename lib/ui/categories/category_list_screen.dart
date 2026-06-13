import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/category_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/category_provider.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId ?? 0;
      context.read<CategoryProvider>().loadCategories(userId);
    });
  }

  void _showCategoryDialog({CategoryModel? categoryToEdit}) {
    final isEdit = categoryToEdit != null;
    final nameController = TextEditingController(text: isEdit ? categoryToEdit.name : '');
    final iconController = TextEditingController(text: isEdit ? categoryToEdit.icon : '📁');
    final userId = context.read<AuthProvider>().userId ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'Create New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Category Name',
              hint: 'e.g. Raw Materials',
              controller: nameController,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Icon (Emoji)',
              hint: 'e.g. ⚡, 📦',
              controller: iconController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final catProv = context.read<CategoryProvider>();
              if (isEdit) {
                final updatedCat = CategoryModel(
                  id: categoryToEdit.id,
                  name: nameController.text.trim(),
                  icon: iconController.text.trim(),
                  isDefault: false,
                  userId: userId,
                );
                await catProv.updateCategory(updatedCat, userId);
              } else {
                await catProv.addCategory(
                  nameController.text.trim(),
                  iconController.text.trim(),
                  userId,
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, catProv, child) {
          if (catProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (catProv.categories.isEmpty) {
            return const Center(child: Text('No categories available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: catProv.categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final cat = catProv.categories[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(
                    cat.name,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),                  trailing: cat.isDefault
                      ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('System', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        onPressed: () => _showCategoryDialog(categoryToEdit: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                        onPressed: () => catProv.deleteCategory(cat.id!, userId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}