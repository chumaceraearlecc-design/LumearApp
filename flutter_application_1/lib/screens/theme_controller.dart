import 'package:flutter/material.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

  static bool get isDarkMode {
    return themeMode.value == ThemeMode.dark;
  }

  static void setDarkMode(bool value) {
    themeMode.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  static void toggleTheme() {
    themeMode.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
  }
}
