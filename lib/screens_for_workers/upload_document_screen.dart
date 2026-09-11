import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'waiting_approval_screen.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  static const Color brand = Color(0xFFCCFD04);
  static const Color iconBg = Color(0xFFD9FF4D);

  final picker = ImagePicker();
  final user = FirebaseAuth.instance.currentUser!;

  final String cloudName = "dqbbi53py";
  final String uploadPreset = "unsigned_worker_upload";

  bool submitting = false;

  /// Picked images locally
  final Map<String, File?> files = {
    "profile": null,
    "cnicFront": null,
    "cnicBack": null,
    "selfie": null,
    "tools": null,
    "police": null,
  };

  /// Uploaded URLs
  final Map<String, String?> uploadedUrls = {
    "profile": null,
    "cnicFront": null,
    "cnicBack": null,
    "selfie": null,
    "tools": null,
    "police": null,
  };

  bool get canSubmit =>
      uploadedUrls["profile"] != null &&
          uploadedUrls["cnicFront"] != null &&
          uploadedUrls["cnicBack"] != null &&
          uploadedUrls["selfie"] != null &&
          uploadedUrls["tools"] != null;

  // ================= IMAGE PICK =================
  Future<void> _pickImage(ImageSource source, String key) async {
    final img = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (img == null) return;

    setState(() {
      files[key] = File(img.path);
    });

    await _uploadToCloudinary(key);
  }

  // ================= CLOUDINARY UPLOAD =================
  Future<void> _uploadToCloudinary(String key) async {
    final file = files[key];
    if (file == null) return;

    final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", uri);

    request.fields["upload_preset"] = uploadPreset;
    request.fields["folder"] = "workers/${user.uid}/$key";

    request.files.add(
      await http.MultipartFile.fromPath("file", file.path),
    );

    try {
      final response = await request.send();
      final resStr = await response.stream.bytesToString();
      final json = jsonDecode(resStr);

      if (json["secure_url"] != null) {
        setState(() {
          uploadedUrls[key] = json["secure_url"];
        });

        debugPrint("✅ Uploaded $key -> ${json["secure_url"]}");
      } else {
        throw "Upload failed";
      }
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $key")),
        );
      }
    }
  }

  // ================= SUBMIT =================
  Future<void> _submit() async {
    if (!canSubmit) return;

    setState(() => submitting = true);

    try {
      await FirebaseFirestore.instance
          .collection("worker_documents")
          .doc(user.uid)
          .set({
        "uid": user.uid,
        "documents": uploadedUrls,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const WaitingApprovalScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      debugPrint("❌ Firestore error: $e");
    }

    setState(() => submitting = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xfff5f7fb),
        appBar: AppBar(
          backgroundColor: brand,
          automaticallyImplyLeading: false,
          title: const Text(
            "Verification",
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _docTile("profile", "Profile Picture", Icons.person, true),
              _docTile("cnicFront", "CNIC Front", Icons.credit_card, true),
              _docTile("cnicBack", "CNIC Back", Icons.credit_card_outlined, true),
              _docTile("selfie", "Selfie with CNIC", Icons.camera_alt, true),
              _docTile("tools", "Tools Picture", Icons.handyman, true),
              _docTile("police", "Police Verification", Icons.verified_user, false),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canSubmit && !submitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    canSubmit ? Colors.black : Colors.grey,
                  ),
                  child: submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Submit for Review",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DOCUMENT TILE =================
  Widget _docTile(
      String key,
      String title,
      IconData icon,
      bool required,
      ) {
    final done = uploadedUrls[key] != null;

    return InkWell(
      onTap: () => _chooseSource(key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
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
              backgroundColor: iconBg,
              child: Icon(icon, color: Colors.black),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title + (required ? "" : " (Optional)"),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            done
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.upload),
          ],
        ),
      ),
    );
  }

  // ================= SOURCE PICKER =================
  void _chooseSource(String key) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Camera"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera, key);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery, key);
            },
          ),
        ],
      ),
    );
  }
}
