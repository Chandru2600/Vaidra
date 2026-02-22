// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaidra/screens/homePage.dart';
import 'package:vaidra/screens/locationPage.dart';
import 'package:vaidra/screens/loginPage.dart';
import 'package:vaidra/screens/medicalDetails.dart';
import 'package:vaidra/screens/profilePage.dart';
import 'package:vaidra/screens/register.dart';
import 'package:vaidra/screens/welcomePage.dart';
import 'package:vaidra/screens/historyPage.dart';
import 'screens/help_support_page.dart';
import 'screens/privacy_policy_page.dart';
import 'screens/terms_service_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, languageProvider, themeProvider, child) {
        // Wait for theme to be initialized before building the app
        if (!themeProvider.isInitialized) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
        return MaterialApp(
          title: 'Vaidra',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: WelcomePage(),
          routes: {
            '/welcome': (context) => WelcomePage(),
            '/login': (context) => LoginPage(),
            '/register': (context) => RegisterPage(),
            '/medicalDetails': (context) => MedicalDetailsPage(),
            '/location': (context) => LocationDetailsPage(),
            '/home': (context) => HomePage(),
            '/profile': (context) => ProfilePage(),
            '/history': (context) => HistoryPage(),
            '/help': (context) => const HelpSupportPage(),
            '/privacy': (context) => const PrivacyPolicyPage(),
            '/terms': (context) => const TermsServicePage(),
          },
        );
      },
    );
  }
}

