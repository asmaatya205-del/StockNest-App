// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/providers/auth_provider.dart';
import 'domain/providers/warehouse_provider.dart';
import 'domain/providers/product_provider.dart';
import 'domain/providers/category_provider.dart';

class StockNestApp extends StatelessWidget {
  final bool rememberMeChecked;
  final bool isFirstTime;

  const StockNestApp({
    super.key,
    required this.rememberMeChecked,
    required this.isFirstTime,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Global Root Providers Pipeline: Registers and injects all architectural blocks
      // into the applications context tree, allowing immediate state access across any view.
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()
            ..initializeSession(
              rememberMeChecked: rememberMeChecked,
              firstTimeFlag: isFirstTime,
            ),
        ),
        ChangeNotifierProvider(create: (_) => WarehouseProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],

      // Reactive Shell Wrapper: Uses a Consumer to automatically intercept session hydration changes,
      // forcing real-time updates through the routing pipeline router configuration.
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'StockNest',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: AppRouter.createRouter(authProvider),
          );
        },
      ),
    );
  }
}