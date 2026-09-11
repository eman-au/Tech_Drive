import 'package:flutter/material.dart';

class WorkerHelpSupportScreen extends StatelessWidget {
  const WorkerHelpSupportScreen({super.key});

  static const Color brand = Color(0xFFCCFD04);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: brand,
        title: const Text(
          "Support & Help",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          /// INFO BAR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: brand,
            child: const Text(
              "Support chat hours: 09:00–00:00 daily.\nYou can submit a request anytime via our support form.",
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _helpTile("Booking & Orders"),
                  _helpTile("Payments & Refunds"),
                  _helpTile("Accounts & Login"),
                  _helpTile("Becoming a Service Provider"),
                  _helpTile("Technical Issues"),
                  _helpTile("FAQs"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpTile(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: brand,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
