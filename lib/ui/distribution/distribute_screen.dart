import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stock_nest/core/theme/app_colors.dart';
import 'package:stock_nest/core/theme/app_text_styles.dart';
import 'package:stock_nest/core/theme/app_spacing.dart';
import 'package:stock_nest/core/widgets/widgets.dart';
import 'package:stock_nest/data/models/warehouse_model.dart';
import 'package:stock_nest/domain/providers/auth_provider.dart';
import 'package:stock_nest/domain/providers/warehouse_provider.dart';
import 'package:stock_nest/domain/providers/product_provider.dart';

enum _StockMode { add, remove, transfer }

class DistributeScreen extends StatefulWidget {
  final int productId;
  const DistributeScreen({super.key, required this.productId});

  @override
  State<DistributeScreen> createState() => _DistributeScreenState();
}

class _DistributeScreenState extends State<DistributeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  _StockMode _mode = _StockMode.add;
  WarehouseModel? _selectedWarehouse;
  WarehouseModel? _fromWarehouse;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().userId;
    context.read<ProductProvider>().clearError();
    context.read<WarehouseProvider>().clearError();
    if (userId != null) {
      context.read<WarehouseProvider>().loadAllWarehouses(userId);
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// Processes stock modifications based on the selected operations mode (_StockMode).
  /// Validates synchronization thresholds and displays localized danger banners if any transaction fails.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a warehouse')),
      );
      return;
    }

    if (_mode == _StockMode.transfer && _fromWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select source warehouse')),
      );
      return;
    }

    if (_mode == _StockMode.transfer &&
        _fromWarehouse!.id == _selectedWarehouse!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Source and destination must be different')),
      );
      return;
    }

    // Context Safety Rule: Extract all required provider references prior to execution of any async blocks
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();
    final userId = authProvider.userId ?? 0;
    final quantity = double.parse(_quantityCtrl.text.trim());
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final warehouseId = _selectedWarehouse!.id!;
    final fromWarehouseId = _fromWarehouse?.id;

    bool success = false;

    // Operation Router: Directs stock additions, removals, or warehouse-to-warehouse transfers conditionally
    switch (_mode) {
      case _StockMode.add:
        productProvider.clearError();
        success = await productProvider.addStock(
          productId: widget.productId,
          warehouseId: warehouseId,
          quantity: quantity,
          userId: userId,
          note: note,
        );
        if (mounted && !success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(productProvider.errorMessage ?? 'Failed to add stock.'),
            backgroundColor: AppColors.danger,
          ));
        }
        break;

      case _StockMode.remove:
        productProvider.clearError();
        success = await productProvider.removeStock(
          productId: widget.productId,
          warehouseId: warehouseId,
          quantity: quantity,
          userId: userId,
          note: note,
        );
        if (mounted && !success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(productProvider.errorMessage ?? 'Failed to remove stock.'),
            backgroundColor: AppColors.danger,
          ));
        }
        break;

      case _StockMode.transfer:
        warehouseProvider.clearError();
        success = await warehouseProvider.transferProduct(
          productId: widget.productId,
          fromWarehouseId: fromWarehouseId!,
          toWarehouseId: warehouseId,
          quantity: quantity,
          userId: userId,
          note: note,
        );
        if (mounted && !success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(warehouseProvider.errorMessage ?? 'Transfer failed.'),
            backgroundColor: AppColors.danger,
          ));
        }
        break;
    }

    if (mounted && success) {
      await productProvider.loadProductDetail(widget.productId);
      if (mounted) context.pop();
    }
  }

  String get _appBarTitle {
    switch (_mode) {
      case _StockMode.add:      return 'Add Stock';
      case _StockMode.remove:   return 'Remove Stock';
      case _StockMode.transfer: return 'Transfer Stock';
    }
  }

  IconData get _modeIcon {
    switch (_mode) {
      case _StockMode.add:      return Icons.add_box_rounded;
      case _StockMode.remove:   return Icons.remove_circle_outline;
      case _StockMode.transfer: return Icons.swap_horiz_rounded;
    }
  }

  String get _buttonLabel {
    switch (_mode) {
      case _StockMode.add:      return 'Add Stock';
      case _StockMode.remove:   return 'Remove Stock';
      case _StockMode.transfer: return 'Transfer Now';
    }
  }

  IconData get _buttonIcon {
    switch (_mode) {
      case _StockMode.add:      return Icons.add_rounded;
      case _StockMode.remove:   return Icons.remove_rounded;
      case _StockMode.transfer: return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehouses = context.watch<WarehouseProvider>().allWarehouses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_appBarTitle),
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
                    gradient: _mode == _StockMode.remove
                        ? const LinearGradient(
                        colors: [AppColors.danger, AppColors.danger])
                        : AppColors.primaryGradient,
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: Icon(_modeIcon, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Center(
                child: SegmentedButton<_StockMode>(
                  segments: const [
                    ButtonSegment(
                      value: _StockMode.add,
                      label: Text('Add'),
                      icon: Icon(Icons.add_rounded),
                    ),
                    ButtonSegment(
                      value: _StockMode.remove,
                      label: Text('Remove'),
                      icon: Icon(Icons.remove_rounded),
                    ),
                    ButtonSegment(
                      value: _StockMode.transfer,
                      label: Text('Transfer'),
                      icon: Icon(Icons.swap_horiz_rounded),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (val) => setState(() {
                    _mode = val.first;
                    _fromWarehouse = null;
                    _selectedWarehouse = null;
                    _quantityCtrl.clear();
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_mode == _StockMode.transfer) ...[
                Text('From Warehouse', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                _WarehouseDropdown(
                  warehouses: warehouses,
                  selected: _fromWarehouse,
                  hint: 'Select source warehouse',
                  onChanged: (w) => setState(() => _fromWarehouse = w),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              Text(
                _mode == _StockMode.transfer ? 'To Warehouse' : 'Select Warehouse',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _WarehouseDropdown(
                warehouses: warehouses,
                selected: _selectedWarehouse,
                hint: _mode == _StockMode.transfer
                    ? 'Select destination warehouse'
                    : _mode == _StockMode.remove
                    ? 'Select warehouse to remove from'
                    : 'Select warehouse to add stock',
                onChanged: (w) => setState(() => _selectedWarehouse = w),
              ),

              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Quantity *',
                hint: 'e.g. 50',
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.numbers_rounded),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Quantity is required';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid positive number';
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Note',
                hint: 'Optional note',
                controller: _noteCtrl,
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: AppSpacing.xl),

              Consumer2<ProductProvider, WarehouseProvider>(
                builder: (_, pp, wp, __) => PrimaryButton(
                  label: _buttonLabel,
                  icon: _buttonIcon,
                  isLoading: pp.isLoading || wp.isLoading,
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

// ── Custom Dropdown Component ──────────────────────────────────────────────────

class _WarehouseDropdown extends StatelessWidget {
  final List<WarehouseModel> warehouses;
  final WarehouseModel? selected;
  final String hint;
  final ValueChanged<WarehouseModel?> onChanged;

  const _WarehouseDropdown({
    required this.warehouses,
    required this.selected,
    required this.hint,
    required this.onChanged,
  });

  /// Recursive Tree Flattening: Sorts locations into a hierarchical list
  /// grouping each parent immediately followed by its direct child sub-warehouses.
  List<({WarehouseModel warehouse, int depth})> _buildSortedList() {
    final roots = warehouses.where((w) => w.parentId == null).toList();
    final result = <({WarehouseModel warehouse, int depth})>[];

    void addWithChildren(WarehouseModel w, int depth) {
      result.add((warehouse: w, depth: depth));
      final children = warehouses.where((c) => c.parentId == w.id).toList();
      for (final child in children) {
        addWithChildren(child, depth + 1);
      }
    }

    for (final root in roots) {
      addWithChildren(root, 0);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _buildSortedList();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.inputRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<WarehouseModel>(
          value: selected,
          hint: Text(hint, style: AppTextStyles.bodyMedium),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          onChanged: onChanged,
          items: sorted.map((entry) {
            final isChild = entry.depth > 0;
            return DropdownMenuItem(
              value: entry.warehouse,
              child: Row(
                children: [
                  // Indentation Logic: Visually shifts nested children based on tree node depth mapping
                  if (isChild) ...[
                    SizedBox(width: 12.0 * entry.depth),
                    const Icon(Icons.subdirectory_arrow_right_rounded,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      entry.warehouse.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isChild ? AppColors.textSecondary : AppColors.textPrimary,
                        fontWeight: isChild ? FontWeight.normal : FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}