import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORT SCREENS
import 'date_distance_screen.dart';
import 'night_mode_screen.dart';
import 'navigation_settings_screen.dart';
import 'rules_terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  void _loadPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1️⃣ pehle auth se check
    if (user.phoneNumber != null) {
      setState(() {
        phoneNumber = user.phoneNumber;
      });
      return;
    }

    // 2️⃣ warna firestore se check
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?['phone'] != null) {
      setState(() {
        phoneNumber = doc['phone'];
      });
    }
  }

  // ================= DELETE ACCOUNT =================
  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This will permanently delete your account and all data. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

    await user.delete();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          // 🌙 NIGHT MODE
          _tile(
            context,
            title: "Night Mode",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NightModeScreen(),
                ),
              );
            },
          ),

          // ⏰ DATE & DISTANCES
          _tile(
            context,
            title: "Date and Distances",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DateDistanceScreen(),
                ),
              );
            },
          ),

          // 🗺 NAVIGATION
          _tile(
            context,
            title: "Navigation",
            leading: Image.asset(
              'assets/images/googlemaps.jpg',
              width: 24,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NavigationSettingsScreen(),
                ),
              );
            },
          ),

          // 📜 RULES & TERMS
          _tile(
            context,
            title: "Rules and Terms",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RulesTermsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // 🗑 DELETE ACCOUNT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _deleteAccount,
              child: const Text(
                "Delete Account",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ================= TILE =================
  Widget _tile(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? leading,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _box(context),
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // ================= BOX =================
  BoxDecoration _box(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }
}
