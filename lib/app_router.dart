import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_nest/domain/providers/auth_provider.dart';
import 'package:stock_nest/ui/onboarding/splash_screen.dart';
import 'package:stock_nest/ui/onboarding/onboarding_screen.dart';
import 'package:stock_nest/ui/auth/login_screen.dart';
import 'package:stock_nest/ui/auth/register_screen.dart';
import 'package:stock_nest/ui/home/home_screen.dart';
import 'package:stock_nest/ui/warehouses/warehouse_list_screen.dart';
import 'package:stock_nest/ui/warehouses/warehouse_detail_screen.dart';
import 'package:stock_nest/ui/warehouses/add_edit_warehouse_screen.dart';
import 'package:stock_nest/ui/products/product_list_screen.dart';
import 'package:stock_nest/ui/products/product_detail_screen.dart';
import 'package:stock_nest/ui/products/add_edit_product_screen.dart';
import 'package:stock_nest/ui/distribution/distribute_screen.dart';
import 'package:stock_nest/ui/history_logs/inventory_logs_screen.dart';
import 'package:stock_nest/ui/settings/settings_screen.dart';
import 'package:stock_nest/ui/shell/main_shell.dart';
import 'package:stock_nest/ui/categories/category_list_screen.dart';

class AppRouter {
  // Global Navigation Keys mapping root overlays (dialogs/modals) separately from sub-shell containers
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/splash',

      // Reactive Core Listener: Forces the GoRouter engine to re-evaluate redirect rules
      // immediately whenever the underlying user authorization state notifications fire.
      refreshListenable: authProvider,

      /// Structural Session Guards Pipeline Router: Analyzes active authentication steps
      /// and intercepts unsafe navigation requests conditionally across specific entry states.
      redirect: (ctx, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isFirstTime = authProvider.isFirstTime;
        final location = state.matchedLocation;

        // Step 1: Splash Screen Interceptor (allows native delayed initialization routines)
        if (location == '/splash') return null;

        // Step 2: First-Time Initialization Guard (forces layout view routes towards onboarding)
        if (isFirstTime) {
          return location != '/onboarding' ? '/onboarding' : null;
        }
        if (!isFirstTime && location == '/onboarding') {
          return '/login';
        }

        final isAuthPage = location == '/login' || location == '/register';

        // Step 3: Global Protection Guard (redirects anonymous sessions towards login interfaces)
        if (!isAuthenticated) {
          if (!isAuthPage) return '/login';
          return null;
        }

        // Step 4: Token Availability Guard (intercepts active sessions requesting login/register portals)
        if (isAuthenticated && isAuthPage) return '/home';

        return null;
      },

      routes: [
        // ── Root Overlay Navigation Stack Routes ──
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/splash',
          name: 'splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/onboarding',
          name: 'onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/login',
          name: 'login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/register',
          name: 'register',
          builder: (_, __) => const RegisterScreen(),
        ),

        // ── Nested Shell Dashboard Application Router Stack ──
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (_, __, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (_, __) => const HomeScreen(),
            ),

            GoRoute(
              path: '/categories',
              name: 'categories',
              builder: (_, __) => const CategoryListScreen(),
            ),

            // ── Warehouse Subtree Hierarchy Management Routes ──
            GoRoute(
              path: '/warehouses',
              name: 'warehouses',
              builder: (_, __) => const WarehouseListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'warehouse-add',
                  builder: (_, __) => const AddEditWarehouseScreen(),
                ),

                GoRoute(
                  path: ':id',
                  name: 'warehouse-detail',
                  builder: (_, state) => WarehouseDetailScreen(
                    warehouseId: int.parse(state.pathParameters['id']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'warehouse-edit',
                      builder: (_, state) => AddEditWarehouseScreen(
                        warehouseId: int.parse(state.pathParameters['id']!),
                      ),
                    ),

                    // Relational Navigation Guard Fix: Extracts parent warehouse indices directly
                    // out of path parameters to eliminate stale cache drops on view refreshes
                    GoRoute(
                      path: 'add-sub',
                      name: 'warehouse-add-sub',
                      builder: (_, state) {
                        final parentIdStr = state.pathParameters['id'];
                        return AddEditWarehouseScreen(
                          parentId: parentIdStr != null ? int.parse(parentIdStr) : null,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            // ── Production Catalog and Inventory Control Management Routes ──
            GoRoute(
              path: '/products',
              name: 'products',
              builder: (_, __) => const ProductListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'product-add',
                  builder: (_, __) => const AddEditProductScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: 'product-detail',
                  builder: (_, state) => ProductDetailScreen(
                    productId: int.parse(state.pathParameters['id']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'product-edit',
                      builder: (_, state) => AddEditProductScreen(
                        productId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                    GoRoute(
                      path: 'distribute',
                      name: 'distribute',
                      builder: (_, state) => DistributeScreen(
                        productId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            GoRoute(
              path: '/logs',
              name: 'logs',
              builder: (_, __) => const InventoryLogsScreen(),
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (_, __) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}