import 'package:flutter/material.dart';

class ThemeController extends InheritedWidget {
  final bool isDark;
  final Function(bool) toggleTheme;

  const ThemeController({
    super.key,
    required this.isDark,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeController>()!;
  }

  @override
  bool updateShouldNotify(ThemeController oldWidget) {
    return oldWidget.isDark != isDark;
  }
}
