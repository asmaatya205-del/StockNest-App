import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/warehouse_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/warehouse_provider.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final int warehouseId;
  const WarehouseDetailScreen({super.key, required this.warehouseId});

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load full detail for this warehouse including children and products
    context.read<WarehouseProvider>().loadWarehouseDetail(widget.warehouseId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Warehouse'),
        content: const Text('This will also delete all sub-warehouses. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final warehouseProvider = context.read<WarehouseProvider>();
      final userId = authProvider.userId ?? 0;

      // Save parentId before deletion so we can navigate back correctly
      final parentId = warehouseProvider.selected?.parentId;

      setState(() => _isDeleting = true);

      final success = await warehouseProvider.deleteWarehouse(widget.warehouseId, userId);

      if (mounted) {
        if (success) {
          // If this was a sub-warehouse, go back to the parent detail screen
          // Otherwise go back to the main warehouses list
          if (parentId != null) {
            context.pushReplacementNamed(
              'warehouse-detail',
              pathParameters: {'id': '$parentId'},
            );
          } else {
            context.goNamed('warehouses');
          }
        } else {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WarehouseProvider>(
      builder: (_, provider, __) {
        final warehouse = provider.selected;

        // While deleting, keep showing the current screen to avoid flicker
        if (!_isDeleting && (provider.isLoading || warehouse == null)) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If warehouse becomes null after deletion, show a placeholder
        // while navigation completes
        if (warehouse == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.warehouse_rounded, color: Colors.white, size: 32),
                            const SizedBox(height: AppSpacing.sm),
                            Text(warehouse.name, style: AppTextStyles.headlineLargeOnDark),
                            if (warehouse.location != null && warehouse.location!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(warehouse.location!, style: AppTextStyles.bodyMediumOnDark),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Edit button uses push to keep the navigation stack intact
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => context.pushNamed(
                      'warehouse-edit',
                      pathParameters: {'id': '${warehouse.id}'},
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(text: 'Products'),
                    Tab(text: 'Sub-Warehouses'),
                    Tab(text: 'Info'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _ProductsTab(products: provider.warehouseProducts),
                _SubWarehousesTab(
                  children: provider.children,
                  parentId: warehouse.id!,
                ),
                _InfoTab(warehouse: warehouse),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.pushNamed(
              'warehouse-add-sub',
              pathParameters: {'id': '${warehouse.id}'}, // Pass the current warehouse id as the path parameter
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Sub-Warehouse'),
          ),
        );
      },
    );
  }
}

// ── Products Tab ───────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _ProductsTab({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text('No products assigned', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final p = products[i];
        final qty = (p['quantity'] as num).toDouble();
        final minStock = (p['min_stock'] as num).toDouble();
        final isLow = qty <= minStock && minStock > 0;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isLow ? AppColors.danger.withOpacity(0.4) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLow ? AppColors.dangerSurface : AppColors.secondarySurface,
                  borderRadius: AppRadius.inputRadius,
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: isLow ? AppColors.danger : AppColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] as String, style: AppTextStyles.labelMedium),
                    if (p['sku'] != null)
                      Text('SKU: ${p['sku']}', style: AppTextStyles.bodySmall),
                    Text(
                      '$qty ${p['unit'] ?? ''}${isLow ? ' · Low stock' : ''}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isLow ? AppColors.danger : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Navigate to distribute screen to manage stock for this product
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                color: AppColors.primary,
                tooltip: 'Manage Stock',
                onPressed: () => context.goNamed(
                  'distribute',
                  pathParameters: {'id': '${p['id']}'},
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Sub-Warehouses Tab ─────────────────────────────────────────────────────

class _SubWarehousesTab extends StatelessWidget {
  final List<WarehouseModel> children;
  final int parentId;

  const _SubWarehousesTab({
    required this.children,
    required this.parentId,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_tree_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text('No sub-warehouses yet', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () => context.pushNamed(
                'warehouse-add-sub',
                pathParameters: {'id': '$parentId'}, // Pass the parentId as the path parameter
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Sub-Warehouse'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final child = children[i];
        return ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
            side: const BorderSide(color: AppColors.border),
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppRadius.inputRadius,
            ),
            child: const Icon(Icons.warehouse_outlined, color: AppColors.primary, size: 20),
          ),
          title: Text(child.name, style: AppTextStyles.labelMedium),
          subtitle: child.location != null && child.location!.isNotEmpty
              ? Text(child.location!, style: AppTextStyles.bodySmall)
              : null,
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          // Use pushNamed so the sub-warehouse detail is pushed onto the stack,
          // allowing the user to pop back to the parent detail screen
          onTap: () => context.pushNamed(
            'warehouse-detail',
            pathParameters: {'id': '${child.id}'},
          ),
        );
      },
    );
  }
}

// ── Info Tab ───────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final WarehouseModel warehouse;
  const _InfoTab({required this.warehouse});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        _InfoRow(label: 'Name', value: warehouse.name),
        if (warehouse.location != null) _InfoRow(label: 'Location', value: warehouse.location!),
        if (warehouse.description != null) _InfoRow(label: 'Description', value: warehouse.description!),
        if (warehouse.capacity != null) _InfoRow(label: 'Capacity', value: '${warehouse.capacity}'),
        _InfoRow(
          label: 'Type',
          value: warehouse.isRoot ? 'Root Warehouse' : 'Sub-Warehouse',
        ),
        _InfoRow(
          label: 'Created',
          value: warehouse.createdAt.length > 10
              ? warehouse.createdAt.substring(0, 10)
              : warehouse.createdAt,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}