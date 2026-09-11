import 'package:flutter/material.dart';

class RulesTermsScreen extends StatelessWidget {
  const RulesTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rules and terms")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _tile(
              context,
              title: "Terms and Conditions",
              onTap: () {
                // future screen
              },
            ),

            _tile(
              context,
              title: "Privacy Policy",
              onTap: () {
                // future screen
              },
            ),

            _tile(
              context,
              title: "Licenses",
              onTap: () {
                // future screen
              },
            ),

            const SizedBox(height: 30),

            const Text(
              "App version\n5.152.1 (1609)",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
