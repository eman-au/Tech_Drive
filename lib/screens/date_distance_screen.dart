import 'package:flutter/material.dart';

class DateDistanceScreen extends StatefulWidget {
  const DateDistanceScreen({super.key});

  @override
  State<DateDistanceScreen> createState() => _DateDistanceScreenState();
}

class _DateDistanceScreenState extends State<DateDistanceScreen> {
  static const Color brand = Color(0xFFCCFD04);

  String timeFormat = "12h";
  String distanceUnit = "km";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        backgroundColor: brand,
        title: const Text(
          "Date & Distances",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 🕒 TIME FORMAT
          _sectionTitle("Time format"),
          _card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text("12-hour"),
                  value: "12h",
                  groupValue: timeFormat,
                  onChanged: (v) {
                    setState(() => timeFormat = v!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text("24-hour"),
                  value: "24h",
                  groupValue: timeFormat,
                  onChanged: (v) {
                    setState(() => timeFormat = v!);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// 📏 DISTANCE UNIT
          _sectionTitle("Distance unit"),
          _card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text("Kilometres (km)"),
                  value: "km",
                  groupValue: distanceUnit,
                  onChanged: (v) {
                    setState(() => distanceUnit = v!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text("Miles (mi)"),
                  value: "mi",
                  groupValue: distanceUnit,
                  onChanged: (v) {
                    setState(() => distanceUnit = v!);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// 💾 SAVE BUTTON (optional)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                // later: save to Firestore / SharedPreferences
                Navigator.pop(context);
              },
              child: const Text(
                "Save",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
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
      child: child,
    );
  }
}
