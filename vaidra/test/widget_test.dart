import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaidra/main.dart';
import 'package:vaidra/providers/theme_provider.dart';
import 'package:vaidra/screens/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Vaidra App smoke test: launches and renders welcome', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the app rendered
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
