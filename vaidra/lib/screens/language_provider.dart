import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageProvider extends ChangeNotifier {
  String currentLanguage = 'English';
  bool isLoading = false;
  Map<String, dynamic> _localizedStrings = {};

  LanguageProvider() {
    loadLanguage('English');
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  Future<void> loadLanguage(String language) async {
    isLoading = true;
    notifyListeners();

    String fileName;
    if (language == 'Tamil') {
      fileName = 'ta.json';
    } else if (language == 'Hindi') {
      fileName = 'hi.json';
    } else {
      fileName = 'en.json';
    }

    String jsonString = await rootBundle.loadString('assets/translations/$fileName');
    _localizedStrings = json.decode(jsonString);
    currentLanguage = language;

    isLoading = false;
    notifyListeners();
  }

  void changeLanguage(String value) {
    loadLanguage(value);
  }
}
