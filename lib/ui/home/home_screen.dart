import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/inventory_log_model.dart';
import '../../data/models/warehouse_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/warehouse_provider.dart';
import '../../domain/providers/product_provider.dart';
import '../../domain/providers/category_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenContent();
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      await Future.wait([
        context.read<WarehouseProvider>().loadRootWarehouses(userId),
        context.read<ProductProvider>().loadProducts(userId),
        context.read<ProductProvider>().loadUserLogs(userId),
        context.read<CategoryProvider>().loadCategories(userId),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.white,
        child: CustomScrollView(
          slivers: [
            _HomeHeroHeader(userName: user?.name ?? ''),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.lg),
                  const _QuickActions(),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Product Categories Navigation Card ──
                  const _CategoryNavigationCard(),
                  const SizedBox(height: AppSpacing.lg),

                  const _RecentWarehousesSection(),
                  const SizedBox(height: AppSpacing.lg),
                  const _RecentActivitySection(),
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Navigation Card ──────────────────────────────────────────────

class _CategoryNavigationCard extends StatelessWidget {
  const _CategoryNavigationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.category_outlined, color: AppColors.primary, size: 24),
        ),
        title: const Text(
          'Product Categories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Manage custom & default product classifications', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
        onTap: () {
          context.push('/categories');
        },
      ),
    );
  }
}

// ── Hero Header with Balanced Stats ────────────────────────────────────────────

class _HomeHeroHeader extends StatelessWidget {
  final String userName;
  const _HomeHeroHeader({required this.userName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final warehouses = context.watch<WarehouseProvider>().rootWarehouses;
    final products = context.watch<ProductProvider>().products;
    final categories = context.watch<CategoryProvider>().categories;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              userName.isNotEmpty ? userName : 'Welcome back',
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _WhiteCircleButton(
                        icon: Icons.settings_outlined,
                        onTap: () => context.goNamed('settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    children: [
                      _HeroStatChip(
                        icon: Icons.warehouse_rounded,
                        value: '${warehouses.length}',
                        label: 'Warehouses',
                        onTap: () => context.goNamed('warehouses'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _HeroStatChip(
                        icon: Icons.inventory_2_rounded,
                        value: '${products.length}',
                        label: 'Products',
                        onTap: () => context.goNamed('products'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _HeroStatChip(
                        icon: Icons.category_rounded,
                        value: '${categories.length}',
                        label: 'Categories',
                        onTap: () => context.push('/categories'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WhiteCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _WhiteCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;
  final bool isAlert;

  const _HeroStatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isAlert
                ? Colors.red.withOpacity(0.25)
                : Colors.white.withOpacity(0.15),
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isAlert
                  ? Colors.red.withOpacity(0.4)
                  : Colors.white.withOpacity(0.25),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                label: 'Add\nWarehouse',
                icon: Icons.add_business_rounded,
                color: AppColors.primary,
                bgColor: AppColors.primarySurface,
                onTap: () => context.goNamed('warehouse-add'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionTile(
                label: 'Add\nProduct',
                icon: Icons.add_box_rounded,
                color: AppColors.secondary,
                bgColor: AppColors.secondarySurface,
                onTap: () => context.goNamed('product-add'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionTile(
                label: 'Transfer\nStock',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.accent,
                bgColor: AppColors.accentSurface,
                onTap: () => context.goNamed('products'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionTile(
                label: 'View\nLogs',
                icon: Icons.history_rounded,
                color: AppColors.warning,
                bgColor: AppColors.warningSurface,
                onTap: () => context.goNamed('logs'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadius.inputRadius,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Warehouses ──────────────────────────────────────────────────────

class _RecentWarehousesSection extends StatelessWidget {
  const _RecentWarehousesSection();

  @override
  Widget build(BuildContext context) {
    final warehouses = context.watch<WarehouseProvider>().rootWarehouses;
    final productCount =
        context.watch<WarehouseProvider>().productCountPerWarehouse;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Warehouses', style: AppTextStyles.headlineSmall),
            TextButton(
              onPressed: () => context.goNamed('warehouses'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (warehouses.isEmpty)
          _EmptyCard(
            icon: Icons.warehouse_outlined,
            message: 'No warehouses yet.\nTap + to create your first one.',
            onTap: () => context.goNamed('warehouse-add'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: warehouses.length > 4 ? 4 : warehouses.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _WarehouseTile(
              warehouse: warehouses[i],
              productCount: productCount[warehouses[i].id] ?? 0,
            ),
          ),
      ],
    );
  }
}

class _WarehouseTile extends StatelessWidget {
  final WarehouseModel warehouse;
  final int productCount;
  const _WarehouseTile(
      {required this.warehouse, required this.productCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed('warehouse-detail',
          pathParameters: {'id': '${warehouse.id}'}),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient1,
                borderRadius: AppRadius.inputRadius,
              ),
              child: const Icon(Icons.warehouse_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(warehouse.name,
                      style: AppTextStyles.labelMedium,
                      overflow: TextOverflow.ellipsis),
                  if (warehouse.location != null &&
                      warehouse.location!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(warehouse.location!,
                              style: AppTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.chipRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '$productCount products',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Recent Activity ────────────────────────────────────────────────────────

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<ProductProvider>().logs;
    if (logs.isEmpty) return const SizedBox.shrink();

    final recent = logs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppTextStyles.headlineSmall),
            TextButton(
              onPressed: () => context.goNamed('logs'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final log = recent[i];
              Color color;
              IconData icon;

              // ── Clean Switch Case after removing adjustment ──
              switch (log.logType) {
                case LogType.stockIn:
                  color = AppColors.success;
                  icon = Icons.add_circle_outline;
                  break;
                case LogType.stockOut:
                  color = AppColors.danger;
                  icon = Icons.remove_circle_outline;
                  break;
                case LogType.transfer:
                  color = AppColors.primary;
                  icon = Icons.swap_horiz_rounded;
                  break;
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: AppRadius.inputRadius,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                title:
                Text(log.logType.label, style: AppTextStyles.labelMedium),
                subtitle: Text(
                  log.fromWarehouseName ?? '',
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${log.logType == LogType.stockOut ? '-' : '+'}${log.quantity}',
                      style: AppTextStyles.labelMedium.copyWith(color: color),
                    ),
                    Text(
                      log.createdAt.length > 10
                          ? log.createdAt.substring(0, 10)
                          : log.createdAt,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Empty Card ─────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onTap;

  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.chipRadius,
              ),
              child: Text('Add Now',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}