import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_nest/app.dart';
void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StockNestApp(
      rememberMeChecked: false,
      isFirstTime: false,
    ));

    expect(find.byType(MaterialApp), findsNothing);
  });
}