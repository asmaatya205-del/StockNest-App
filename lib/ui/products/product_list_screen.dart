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
import '../../domain/providers/warehouse_provider.dart' show LoadingStatus;

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      // Initializer Dispatcher: Triggers asynchronous data fetching for current products list
      context.read<ProductProvider>().loadProducts(userId);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Filters products matrix locally using both search query criteria and category selection bounds.
  List<ProductModel> _filtered(List<ProductModel> all) {
    return all.where((p) {
      final matchesQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          (p.sku?.toLowerCase().contains(_query.toLowerCase()) ?? false);
      final matchesCat = _category == null || p.category == _category;
      return matchesQuery && matchesCat;
    }).toList();
  }

  /// Extracts unique categories, purges null entries, and sorts them alphabetically.
  List<String> _categories(List<ProductModel> all) {
    final cats = all.map((p) => p.category).whereType<String>().toSet().toList();
    cats.sort();
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.goNamed('product-add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Header Bar Component ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: AppTextField(
              label: 'Search products or SKU',
              prefixIcon: const Icon(Icons.search_rounded),
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          Expanded(
            child: Consumer<ProductProvider>(
              builder: (_, provider, __) {
                if (provider.status == LoadingStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.status == LoadingStatus.error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        provider.errorMessage ?? 'Failed to load products.',
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final filtered = _filtered(provider.products);
                final categories = _categories(provider.products);

                return Column(
                  children: [
                    // ── Dynamic Categories Horizontal Segment Scroller ──
                    if (categories.isNotEmpty)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _category == null,
                              onTap: () => setState(() => _category = null),
                            ),
                            ...categories.map((c) => _FilterChip(
                              label: c,
                              selected: _category == c,
                              onTap: () => setState(() => _category = c),
                            )),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.sm),

                    // ── Main Content Area Render Router (List View vs Empty State) ──
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyState(onAdd: () => context.goNamed('product-add'))
                          : RefreshIndicator(
                        onRefresh: () async {
                          await context.read<ProductProvider>().loadProducts(userId);
                        },
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.pagePadding),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) => _ProductCard(product: filtered[i]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('product-add'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ── Filter Chip Widget Component ───────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Product Item Card Render Component ──────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed(
        'product-detail',
        pathParameters: {'id': '${product.id}'},
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
                gradient: AppColors.cardGradient2,
                borderRadius: AppRadius.inputRadius,
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),

            // Enforced flex boundaries across label stacks to eliminate raw overflows
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(product.name, style: AppTextStyles.labelMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
                  if (product.sku != null)
                    Text('SKU: ${product.sku}', style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 1),
                  if (product.category != null)
                    Text(product.category!, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 1),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Wrapped unit badges inside dynamic flexible boxes to protect sizing metrics
            if (product.unit != null && product.unit!.isNotEmpty) ...[
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: AppRadius.chipRadius,
                  ),
                  child: Text(
                    product.unit!,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.secondary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Empty State View Component ──────────────────────────────────────────────

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
                color: AppColors.secondarySurface,
                borderRadius: AppRadius.cardRadius,
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.secondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No Products Yet', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first product to start\ntracking inventory.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Add Product',
              icon: Icons.add_rounded,
              onPressed: onAdd,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }
}