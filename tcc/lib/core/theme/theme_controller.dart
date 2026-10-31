import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  // Chave utilizada para salvar no armazenamento local
  static const String _themeKey = 'is_dark_mode_key';

  // Signal reativo contendo o ThemeMode
  final themeMode = signal<ThemeMode>(ThemeMode.light);

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  // 1. Carrega o tema salvo no armazenamento local ao iniciar o app
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    final hasStoredTheme = prefs.containsKey(_themeKey);

    if (hasStoredTheme) {
      final isDark = prefs.getBool(_themeKey) ?? false;
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isSystemDark = brightness == Brightness.dark;
      
      themeMode.value = isSystemDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  // 2. Alterna e salva a preferência do usuário
  Future<void> toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final isDark = mode == ThemeMode.dark;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
}