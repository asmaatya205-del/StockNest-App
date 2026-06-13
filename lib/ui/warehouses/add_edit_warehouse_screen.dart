import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/warehouse_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/warehouse_provider.dart';

class AddEditWarehouseScreen extends StatefulWidget {
  final int? warehouseId; // null means we are in add mode
  final int? parentId;    // set when adding a sub-warehouse under a parent

  const AddEditWarehouseScreen({
    super.key,
    this.warehouseId,
    this.parentId,
  });

  @override
  State<AddEditWarehouseScreen> createState() => _AddEditWarehouseScreenState();
}

class _AddEditWarehouseScreenState extends State<AddEditWarehouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  bool get _isEdit => widget.warehouseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _prefillForm();
  }

  void _prefillForm() {
    final warehouse = context.read<WarehouseProvider>().selected;

    // Guard: only prefill if the selected warehouse matches the one we are editing.
    // This prevents stale data from a previously viewed warehouse from leaking in.
    if (warehouse == null || warehouse.id != widget.warehouseId) return;

    _nameCtrl.text = warehouse.name;
    _locationCtrl.text = warehouse.location ?? '';
    _descCtrl.text = warehouse.description ?? '';
    _capacityCtrl.text = warehouse.capacity != null ? '${warehouse.capacity}' : '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();

    // Read the authenticated user id before any async gaps
    final int activeUserId = authProvider.userId ?? 0;

    debugPrint('=== STOCKNEST DEBUG: Active User ID during save is ($activeUserId) ===');

    // Show a soft error instead of letting the database crash on a zero user id
    if (activeUserId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session Error: No active user logged in. Please re-login.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // In edit mode, keep the original parentId from the provider
    int? finalParentId = widget.parentId;
    if (_isEdit && warehouseProvider.selected != null) {
      finalParentId = warehouseProvider.selected!.parentId;
    }

    final warehouse = WarehouseModel(
      id: _isEdit ? widget.warehouseId : null,
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      capacity: _capacityCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_capacityCtrl.text.trim()),
      parentId: finalParentId,
      userId: activeUserId,
      createdAt: DateTime.now().toIso8601String(),
    );

    warehouseProvider.clearError();

    final bool success = _isEdit
        ? await warehouseProvider.updateWarehouse(warehouse)
        : await warehouseProvider.createWarehouse(warehouse, activeUserId);

    if (success) {
      if (widget.parentId != null) {
        await context.read<WarehouseProvider>()
            .loadWarehouseDetail(widget.parentId!);
      }
      if (mounted) context.pop();
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warehouseProvider.errorMessage ?? 'An error occurred while saving.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Warehouse' : 'New Warehouse'),
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
                    gradient: AppColors.cardGradient1,
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Show a banner when creating a sub-warehouse so the user knows the context
              if (widget.parentId != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: AppRadius.inputRadius,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Creating as sub-warehouse',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              AppTextField(
                label: 'Warehouse Name *',
                hint: 'e.g. Main Warehouse',
                controller: _nameCtrl,
                prefixIcon: const Icon(Icons.warehouse_outlined),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Location',
                hint: 'e.g. Building A, Floor 2',
                controller: _locationCtrl,
                prefixIcon: const Icon(Icons.location_on_outlined),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Description',
                hint: 'Optional notes about this warehouse',
                controller: _descCtrl,
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Capacity',
                hint: 'e.g. 1000',
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.straighten_outlined),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Rebuilds only this button when loading state changes
              Consumer<WarehouseProvider>(
                builder: (_, p, __) => PrimaryButton(
                  label: _isEdit ? 'Save Changes' : 'Create Warehouse',
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
