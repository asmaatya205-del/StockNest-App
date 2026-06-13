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

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Safely verify and pull current logged user index context
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<WarehouseProvider>().loadRootWarehouses(userId);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WarehouseModel> _filtered(List<WarehouseModel> all) {
    if (_query.isEmpty) return all;
    return all
        .where((w) => w.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Warehouses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.goNamed('warehouse-add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Isolated local text fields parsing mutations to separate execution lanes
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: AppTextField(
              label: 'Search warehouses',
              prefixIcon: const Icon(Icons.search_rounded),
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Core reactive workspace constrained through proper state evaluations
          Expanded(
            child: Consumer<WarehouseProvider>(
              builder: (_, provider, __) {
                // 1. Process active transactional progress cycles
                if (provider.status == LoadingStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Safely capture runtime exceptions to protect UX flows
                if (provider.status == LoadingStatus.error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        provider.errorMessage ?? 'Failed to load warehouses.',
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final list = _filtered(provider.rootWarehouses);

                // 3. Render empty structural layouts on data absence match
                if (list.isEmpty) {
                  return _EmptyState(
                    onAdd: () => context.goNamed('warehouse-add'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await context.read<WarehouseProvider>().loadRootWarehouses(userId);
                  },
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _WarehouseCard(warehouse: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('warehouse-add'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final WarehouseModel warehouse;
  const _WarehouseCard({required this.warehouse});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed(
        'warehouse-detail',
        pathParameters: {'id': '${warehouse.id}'},
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient1,
                borderRadius: AppRadius.inputRadius,
              ),
              child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(warehouse.name, style: AppTextStyles.labelMedium, overflow: TextOverflow.ellipsis),
                  if (warehouse.location != null && warehouse.location!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(warehouse.location!, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  if (warehouse.capacity != null) ...[
                    const SizedBox(height: 2),
                    Text('Capacity: ${warehouse.capacity}', style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.cardRadius,
              ),
              child: const Icon(Icons.warehouse_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No Warehouses Yet', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first warehouse to start\nmanaging your inventory.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Create Warehouse',
              icon: Icons.add_rounded,
              onPressed: onAdd,
              width: 220,
            ),
          ],
        ),
      ),
    );
  }
}