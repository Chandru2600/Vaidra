import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isInitialized = false;
  
  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  // Load saved theme preference
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isInitialized = true;
    notifyListeners();
  }
  
  // Toggle dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
  
  // Set dark mode explicitly
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      notifyListeners();
    }
  }
  
  // Light theme
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6BBF8A),
      scaffoldBackgroundColor: const Color(0xFFF5F7F5),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF6BBF8A),
        secondary: const Color(0xFF4B9B6E),
        surface: Colors.white,
        background: const Color(0xFFF5F7F5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
      ),
    );
  }
  
  // Dark theme
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF6BBF8A),
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF6BBF8A),
        secondary: const Color(0xFF4B9B6E),
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
      ),
    );
  }
}
