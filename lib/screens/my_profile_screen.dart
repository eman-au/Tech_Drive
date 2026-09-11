import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final Color brand = const Color(0xFFCCFD04);

  final TextEditingController nameC = TextEditingController();
  final TextEditingController phoneC = TextEditingController(text: "+92");
  final TextEditingController addressC = TextEditingController();

  String email = "";
  String? profileImageUrl;

  bool isEditMode = false;
  bool isSaving = false;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  // ================= FETCH USER =================
  Future<void> fetchUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    nameC.text = data?['name'] ??
        user.displayName ??
        "User";

    phoneC.text = data?['phone'] ?? "+92";
    addressC.text = data?['address'] ?? "";
    email = user.email ?? "";

    profileImageUrl =
        data?['profileImage'] ?? user.photoURL;

    setState(() {});
  }

  // ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🔴 validation
    if (phoneC.text.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid Pakistani number"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      "name": nameC.text.trim(),
      "phone": phoneC.text.trim(), // 🔥 saved
      "address": addressC.text.trim(),
    }, SetOptions(merge: true));

    setState(() {
      isSaving = false;
      isEditMode = false;
    });
  }

  // ================= IMAGE UPLOAD =================
  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isUploadingImage = true);

    final ref = FirebaseStorage.instance
        .ref()
        .child("profile_images/${user.uid}.jpg");

    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({"profileImage": url}, SetOptions(merge: true));

    setState(() {
      profileImageUrl = url;
      isUploadingImage = false;
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: brand,
        title: const Text("My Profile",
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(
              isEditMode ? Icons.close : Icons.edit,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() => isEditMode = !isEditMode);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// PROFILE HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: card(),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: isEditMode ? pickAndUploadImage : null,
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: brand,
                      backgroundImage: profileImageUrl == null
                          ? null
                          : NetworkImage(profileImageUrl!),
                      child: profileImageUrl == null
                          ? const Icon(Icons.person,
                          size: 36, color: Colors.black)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isEditMode
                            ? TextField(
                          controller: nameC,
                          decoration: const InputDecoration(
                              border: InputBorder.none),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        )
                            : Text(nameC.text,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email,
                            style:
                            const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// CONTACT (PHONE ONLY)
            Container(
              decoration: card(),
              child: ListTile(
                leading: Image.asset(
                  "assets/images/pk.png",
                  height: 20,
                ),
                title: const Text("Phone Number",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: isEditMode
                    ? TextField(
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9+]')),
                    LengthLimitingTextInputFormatter(13),
                  ],
                  onChanged: (v) {
                    if (!v.startsWith("+92")) {
                      phoneC.text = "+92";
                      phoneC.selection =
                      const TextSelection.collapsed(
                          offset: 3);
                    }
                  },
                  decoration: const InputDecoration(
                      border: InputBorder.none),
                )
                    : Text(phoneC.text,
                    style:
                    const TextStyle(color: Colors.grey)),
              ),
            ),

            const SizedBox(height: 14),

            profileTile("Address", addressC, Icons.location_on),

            const SizedBox(height: 30),

            if (isEditMode)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand,
                    foregroundColor: Colors.black,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14)),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(
                      color: Colors.black)
                      : const Text("Save Changes",
                      style: TextStyle(
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget profileTile(
      String label, TextEditingController c, IconData i) {
    return Container(
      decoration: card(),
      child: ListTile(
        leading: Icon(i, color: brand),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isEditMode
            ? TextField(
          controller: c,
          decoration:
          const InputDecoration(border: InputBorder.none),
        )
            : Text(
          c.text.isEmpty ? "Not set" : c.text,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  BoxDecoration card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
