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
import 'package:vaidra/screens/emergency_page.dart';
import 'package:vaidra/screens/first_aid_page.dart';
import 'package:vaidra/screens/lifecard_page.dart';
import 'package:vaidra/screens/emergency_contacts_page.dart';
import 'package:vaidra/screens/discover_page.dart';
import 'package:vaidra/screens/history_detail_page.dart';
import 'package:vaidra/screens/family_page.dart';
import 'package:vaidra/screens/subscriptions_page.dart';
import 'package:vaidra/screens/partner_page.dart';
import 'screens/help_support_page.dart';
import 'screens/privacy_policy_page.dart';
import 'screens/terms_service_page.dart';
import 'screens/language_provider.dart';
import 'providers/theme_provider.dart';

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
            '/emergency': (context) => const EmergencyPage(),
            '/first-aid': (context) => const FirstAidPage(),
            '/lifecard': (context) => const LifeCardPage(),
            '/emergency-contacts': (context) => const EmergencyContactsPage(),
            '/discover-hospitals': (context) => const DiscoverPage(type: 'hospital'),
            '/discover-pharmacies': (context) => const DiscoverPage(type: 'pharmacy'),
            '/discover-ambulances': (context) => const DiscoverPage(type: 'ambulance'),
            '/discover-blood-banks': (context) => const DiscoverPage(type: 'blood-bank'),
            '/discover-diagnostics': (context) => const DiscoverPage(type: 'diagnostic'),
            '/family': (context) => const FamilyPage(),
            '/subscriptions': (context) => const SubscriptionsPage(),
            '/partner': (context) => const PartnerPage(),
          },
          // '/result' is not in the routes map: it needs the scan id from
          // the navigation arguments (history list -> scan detail).
          onGenerateRoute: (settings) {
            if (settings.name == '/result') {
              final args = settings.arguments;
              String? scanId;
              String? fallbackTitle;
              if (args is Map) {
                final uploadId = args['uploadId'];
                if (uploadId != null) scanId = uploadId.toString();
                final item = args['historyItem'];
                if (item != null) {
                  try {
                    fallbackTitle = (item as dynamic).title?.toString();
                  } catch (_) {}
                }
              }
              if (scanId == null) return null;
              return MaterialPageRoute(
                builder: (context) => HistoryDetailPage(
                  scanId: scanId!,
                  fallbackTitle: fallbackTitle,
                ),
                settings: settings,
              );
            }
            return null;
          },
        );
      },
    );
  }
}

