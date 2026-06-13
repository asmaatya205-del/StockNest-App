import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  // 1. Enforce native engine bindings are fully operational before executing asynchronous bridges
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Hydrate local key-value configurations concurrently prior to loading runtime application scopes
  final prefs = await SharedPreferences.getInstance();
  final bool rememberMeChecked = prefs.getBool('remember_me') ?? false;
  final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

  // 3. Configure hardware system navigation overlays to prevent visual rendering flickering glitches
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    // Adjusted to dark icons to maintain perfect contrast with the default Light Theme backgrounds
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // 4. Lock orientation configuration matrix to enforce strict design stability rules
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 5. Instantiates the rooted engine while passing down structural state parameters securely
  runApp(StockNestApp(
    rememberMeChecked: rememberMeChecked,
    isFirstTime: isFirstTime,
  ));
}