import 'package:flutter/material.dart';

class LanguageController extends InheritedWidget {
  final bool isUrdu;
  final VoidCallback toggleLanguage;

  const LanguageController({
    super.key,
    required this.isUrdu,
    required this.toggleLanguage,
    required super.child,
  });

  static LanguageController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LanguageController>()!;
  }

  @override
  bool updateShouldNotify(LanguageController oldWidget) {
    return oldWidget.isUrdu != isUrdu;
  }
}
