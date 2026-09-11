// lib/services/navigation_service.dart (NEW FILE)
import 'package:flutter/material.dart';
import '../main.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = MyApp.navigatorKey;

  static Future<dynamic> navigateTo(String routeName, {dynamic arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }

  static void goBack() {
    return navigatorKey.currentState!.pop();
  }

  static Future<dynamic> replaceWith(String routeName, {dynamic arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }
}