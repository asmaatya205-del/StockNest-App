import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/product_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/product_provider.dart';
import '../../domain/providers/warehouse_provider.dart';
import '../../domain/providers/category_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final int? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl  = TextEditingController();
  final _unitCtrl = TextEditingController();

  String? _selectedCategory;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    // Post-Frame Lifecycle: Pre-loads categories asynchronously from DB once the view is mounted
    // and safely handles pre-filling form metrics if the screen is running in edit mode.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId ?? 0;
      context.read<CategoryProvider>().loadCategories(userId).then((_) {
        if (_isEdit) _prefillForm();
      });
    });
  }

  void _prefillForm() {
    final p = context.read<ProductProvider>().selected;
    if (p == null) return;
    _nameCtrl.text = p.name;
    _skuCtrl.text  = p.sku ?? '';
    _unitCtrl.text = p.unit ?? '';

    // Safety mapping guard: Validates that the active product's category exists in the
    // refreshed layout list before updating the state binding.
    final cats = context.read<CategoryProvider>().categories;
    if (cats.any((c) => c.name == p.category)) {
      setState(() {
        _selectedCategory = p.category;
      });
    }
  }

  /// Displays an alert modal prompt allowing real-time insertion of missing custom category titles.
  /// Automatically re-allocates [_selectedCategory] memory state pointer to the newly created entity.
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📁');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Category Name',
              hint: 'e.g. Spare Parts',
              controller: nameController,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Icon (Emoji)',
              hint: 'e.g. ⚙️, 📦',
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
              if (nameController.text.trim().isNotEmpty) {
                final userId = context.read<AuthProvider>().userId ?? 0;
                await context.read<CategoryProvider>().addCategory(
                  nameController.text.trim(),
                  iconController.text.trim(),
                  userId,
                );
                setState(() {
                  _selectedCategory = nameController.text.trim();
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Packages screen form inputs into a distinct ProductModel entity payload.
  /// Routes logic via the repository system router depending on whether it's executing an update or initial insert transaction.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider      = context.read<AuthProvider>();
    final productProvider   = context.read<ProductProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();
    final userId = authProvider.userId ?? 0;

    final product = ProductModel(
      id:        _isEdit ? widget.productId : null,
      name:      _nameCtrl.text.trim(),
      sku:       _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
      category:  _selectedCategory,
      unit:      _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
      userId:    userId,
      createdAt: DateTime.now().toIso8601String(),
    );

    productProvider.clearError();
    bool success = false;

    if (_isEdit) {
      success = await productProvider.updateProduct(product);
    } else {
      final created = await productProvider.createProductWithId(product);
      success = created != null;
    }

    if (mounted) {
      if (success) {
        warehouseProvider.loadRootWarehouses(userId);
        productProvider.loadProducts(userId);
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage ?? 'An error occurred.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'New Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient2,
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppTextField(
                label: 'Product Name *',
                hint: 'e.g. Steel Bolts',
                controller: _nameCtrl,
                prefixIcon: const Icon(Icons.inventory_outlined),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'SKU',
                hint: 'e.g. SKU-001',
                controller: _skuCtrl,
                prefixIcon: const Icon(Icons.qr_code_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Relational Database Category Selector Section ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Consumer<CategoryProvider>(
                      builder: (context, catProv, child) {
                        return DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Select Category'),
                          items: catProv.categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat.name,
                              child: Text('${cat.icon}  ${cat.name}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Custom Action Button: Quick Inline Dialog Router to trigger real-time insertion rules
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_box_rounded, color: AppColors.primary, size: 28),
                      onPressed: _showAddCategoryDialog,
                      tooltip: 'Add Custom Category',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Unit',
                hint: 'e.g. kg, piece, box',
                controller: _unitCtrl,
                prefixIcon: const Icon(Icons.straighten_outlined),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xl),

              Consumer<ProductProvider>(
                builder: (_, p, __) => PrimaryButton(
                  label: _isEdit ? 'Save Changes' : 'Add Product',
                  icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
                  isLoading: p.isLoading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}