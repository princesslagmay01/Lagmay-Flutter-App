import 'package:flutter/material.dart';

/// Global theme notifier. Kept in a separate file to avoid circular imports
/// between main.dart and home_screen.dart.
class AppTheme {
  AppTheme._();
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.dark);
}
