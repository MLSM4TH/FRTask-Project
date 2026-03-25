// lib/app_settings.dart
import 'package:flutter/material.dart';

enum DefaultViewMode {
  board,
  map,
}

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  // Theme
  ThemeMode themeMode = ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;

  void toggleDarkMode(bool value) {
    themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Location
  bool useLocation = true;
  void setUseLocation(bool value) {
    useLocation = value;
    notifyListeners();
  }

  // Default view (we’ll hook this into StartScreen later)
  DefaultViewMode defaultViewMode = DefaultViewMode.board;
  void setDefaultViewMode(DefaultViewMode mode) {
    defaultViewMode = mode;
    notifyListeners();
  }
}
