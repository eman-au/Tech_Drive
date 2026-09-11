import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';

import 'worker_quiz_screen.dart';

class WorkerRegistrationScreen extends StatefulWidget {
  const WorkerRegistrationScreen({super.key});

  @override
  State<WorkerRegistrationScreen> createState() =>
      _WorkerRegistrationScreenState();
}

class _WorkerRegistrationScreenState extends State<WorkerRegistrationScreen> {
  static const Color brand = Color(0xFFCCFD04);

  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final expC = TextEditingController();

  String? workType;
  String? area;

  bool loading = false;
  bool loadingArea = true;

  List<String> nearbyAreas = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadNearbyAreas();
  }

  // ================= LOAD USER INFO =================
  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      nameC.text = doc['name'] ?? "";
      phoneC.text = doc['phone'] ?? "";
      setState(() {});
    }
  }

  // ================= LOAD NEARBY AREAS =================
  Future<void> _loadNearbyAreas() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final double lat = (userDoc['lat'] ?? 0).toDouble();
      final double lng = (userDoc['lng'] ?? 0).toDouble();

      if (lat == 0 || lng == 0) {
        loadingArea = false;
        return;
      }

      List<Placemark> places =
      await placemarkFromCoordinates(lat, lng);

      if (places.isNotEmpty) {
        final place = places.first;

        setState(() {
          nearbyAreas = [
            place.subLocality ?? "",
            place.locality ?? "",
            place.administrativeArea ?? "",
          ].where((e) => e.isNotEmpty).toSet().toList();

          area = nearbyAreas.isNotEmpty ? nearbyAreas.first : null;
          loadingArea = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Area detect error: $e");
      loadingArea = false;
    }
  }

  // ================= SUBMIT DATA =================
  Future<void> submitWorkerRequest() async {
    debugPrint("🚀 Submit pressed");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ User null");
      return;
    }

    if (workType == null || area == null || expC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      debugPrint("❌ Validation failed");
      return;
    }

    final int? experience = int.tryParse(expC.text.trim());
    if (experience == null || experience < 0 || experience > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid experience")),
      );
      debugPrint("❌ Experience invalid");
      return;
    }

    try {
      setState(() => loading = true);
      debugPrint("⏳ Saving data to Firestore...");

      // ✅ 1. Save to worker_requests collection using user UID
      await FirebaseFirestore.instance.collection('worker_requests').doc(user.uid).set({
        "uid": user.uid,
        "name": nameC.text,
        "phone": phoneC.text,
        "workType": workType,
        "experience": experience,
        "area": area,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Worker request saved");

      // ✅ 2. UPDATE the user's document in users collection
      // This is CRITICAL for worker login redirect
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        "userType": "worker", // ✅ Set as worker
        "workType": workType,
        "experience": experience,
        "serviceArea": area,
        "workerStatus": "pending", // Admin will approve later
        "workerRequestedAt": FieldValue.serverTimestamp(),
      });

      debugPrint("✅ User type updated to 'worker'");

      debugPrint("✅ Data saved successfully");
      debugPrint("➡️ Navigating to Quiz screen");

      if (!mounted) return;

      // 🔥 GUARANTEED NAVIGATION
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const WorkerQuizScreen(),
          ),
        );
      });

    } catch (e) {
      debugPrint("🔥 ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        backgroundColor: brand,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Become a Worker",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _lockedCard(
              icon: Icons.person,
              label: "Full Name",
              controller: nameC,
            ),

            _lockedCard(
              icon: Icons.phone,
              label: "Phone Number",
              controller: phoneC,
            ),

            _dropdownCard(
              title: "Work Type",
              items: ["Plumber", "Electrician"],
              value: workType,
              onChanged: (v) => setState(() => workType = v),
            ),

            _inputCard(
              title: "Experience (Years)",
              hint: "0 - 50",
              controller: expC,
              keyboard: TextInputType.number,
            ),

            loadingArea
                ? const Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(),
            )
                : _dropdownCard(
              title: "Nearby Service Area",
              items: nearbyAreas,
              value: area,
              onChanged: (v) => setState(() => area = v),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : submitWorkerRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: brand.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                  "Submit & Start Quiz",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _lockedCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: false,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.lock, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _inputCard({
    required String title,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: title,
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dropdownCard({
    required String title,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardBox(),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map(
              (e) => DropdownMenuItem(
            value: e,
            child: Text(e),
          ),
        )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: title,
          border: InputBorder.none,
        ),
      ),
    );
  }

  BoxDecoration _cardBox() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}