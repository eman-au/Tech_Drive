import 'package:flutter/material.dart';
import '../theme_controller.dart';

class NightModeScreen extends StatelessWidget {
  const NightModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Night mode"),
      ),
      body: Column(
        children: [

          ListTile(
            title: const Text("System"),
            onTap: () {
              ThemeController.setSystem();
              Navigator.pop(context);
            },
          ),

          ListTile(
            title: const Text("Always enabled"),
            onTap: () {
              ThemeController.setDark();
              Navigator.pop(context);
            },
          ),

          ListTile(
            title: const Text("Off"),
            onTap: () {
              ThemeController.setLight();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
