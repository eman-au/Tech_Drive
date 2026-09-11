import 'package:flutter/material.dart';

/// 🌙 DARK MODE
ValueNotifier<bool> darkMode = ValueNotifier(false);

/// 🌐 LANGUAGE (false = English, true = Urdu)
ValueNotifier<bool> isUrdu = ValueNotifier(false);

/// 🌐 TRANSLATION FUNCTION
String tr(String en, String ur) {
  return isUrdu.value ? ur : en;
}
