import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/product_model.dart';
import '../../data/models/inventory_log_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/product_provider.dart';
import '../../domain/providers/warehouse_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial Dispatcher: Pre-loads complete production profiles and historic log entries
    context.read<ProductProvider>().loadProductDetail(widget.productId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Displays an explicit non-dismissible confirmation modal to verify destruction rules.
  /// If confirmed, triggers cascade deletion and safely populates context routing.
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
            'This will remove the product and all its stock from warehouses. Are you sure?'),
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
      final productProvider = context.read<ProductProvider>();
      final userId = authProvider.userId ?? 0;

      setState(() => _isDeleting = true);

      final success = await productProvider.deleteProduct(widget.productId, userId);

      if (mounted) {
        if (success) {
          await productProvider.loadProducts(userId);
          if (mounted) context.goNamed('products');
        } else {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(productProvider.errorMessage ?? 'Delete failed'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (_, provider, __) {
        final product = provider.selected;

        // Optimization: Unified lifecycle guard evaluation to handle asynchronous loading wrappers smoothly
        if (product == null || (!_isDeleting && provider.isLoading)) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.cardGradient2,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.pagePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.inventory_2_rounded,
                                color: Colors.white, size: 32),
                            const SizedBox(height: AppSpacing.sm),
                            Text(product.name,
                                style: AppTextStyles.headlineLargeOnDark),
                            const SizedBox(height: AppSpacing.sm),
                            _PillBadge(
                              label:
                              'Total: ${provider.selectedTotal} ${product.unit ?? ''}',
                              color: Colors.white.withOpacity(0.25),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => context.goNamed(
                      'product-edit',
                      pathParameters: {'id': '${product.id}'},
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
                    Tab(text: 'Info'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _InfoTab(product: product, total: provider.selectedTotal),
                _HistoryTab(logs: provider.logs),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'manage_stock',
            onPressed: () => context.goNamed(
              'distribute',
              pathParameters: {'id': '${product.id}'},
            ),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Manage Stock'),
          ),
        );
      },
    );
  }
}

// ── Pill Badge Component ───────────────────────────────────────────────────

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration:
      BoxDecoration(color: color, borderRadius: AppRadius.chipRadius),
      child: Text(label,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
    );
  }
}

// ── Info Tab Component ─────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final ProductModel product;
  final double total;
  const _InfoTab({required this.product, required this.total});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        _InfoRow(label: 'Name', value: product.name),
        if (product.sku != null) _InfoRow(label: 'SKU', value: product.sku!),
        if (product.category != null)
          _InfoRow(label: 'Category', value: product.category!),
        if (product.unit != null)
          _InfoRow(label: 'Unit', value: product.unit!),
        _InfoRow(label: 'Total Stock', value: '$total'),
        _InfoRow(
          label: 'Created',
          value: product.createdAt.length > 10
              ? product.createdAt.substring(0, 10)
              : product.createdAt,
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
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

// ── History Tab Component ──────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<InventoryLogModel> logs;
  const _HistoryTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text('No history yet', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _LogTile(log: logs[i]),
    );
  }
}

// ── Log Tile Render Component ──────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  final InventoryLogModel log;
  const _LogTile({required this.log});

  Color get _color {
    switch (log.logType) {
      case LogType.stockIn:    return AppColors.success;
      case LogType.stockOut:   return AppColors.danger;
      case LogType.transfer:   return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (log.logType) {
      case LogType.stockIn:    return Icons.add_circle_outline;
      case LogType.stockOut:   return Icons.remove_circle_outline;
      case LogType.transfer:   return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              borderRadius: AppRadius.inputRadius,
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.logType.label, style: AppTextStyles.labelMedium),
                Text(log.fromWarehouseName ?? '',
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis),
                if (log.note != null && log.note!.isNotEmpty)
                  Text(log.note!,
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${log.logType == LogType.stockOut ? '-' : '+'}${log.quantity}',
                style: AppTextStyles.labelMedium.copyWith(color: _color),
              ),
              Text(
                log.createdAt.length > 10
                    ? log.createdAt.substring(0, 10)
                    : log.createdAt,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}