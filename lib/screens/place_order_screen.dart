// screens/place_order_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'finding_worker_screen.dart';
import 'cloudinary_service.dart';

class PlaceOrderScreen extends StatefulWidget {
  final String serviceType;

  const PlaceOrderScreen({super.key, required this.serviceType});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final addressController = TextEditingController();
  final detailsController = TextEditingController();

  List<File> photos = [];
  bool isUploading = false;

  final Color brandColor = const Color.fromARGB(255, 204, 253, 4);
  String? customerName;
  String? customerEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    customerEmail = user.email;
    customerName = user.displayName ?? user.email?.split('@').first ?? 'Customer';

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      addressController.text = doc['address'] ?? "";
      if (doc['name'] != null && doc['name'].toString().isNotEmpty) {
        customerName = doc['name'];
      }
    }

    setState(() {});
  }

  bool _isFormValid() {
    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your address")),
      );
      return false;
    }
    if (detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe your problem")),
      );
      return false;
    }
    return true;
  }

  Future<String> _saveOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    List<String> imageUrls = [];

    if (photos.isNotEmpty) {
      for (int i = 0; i < photos.length; i++) {
        final url = await CloudinaryService.uploadImage(photos[i]);
        if (url != null && url.isNotEmpty) {
          imageUrls.add(url);
        }
      }
    }

    final orderData = {
      "serviceType": widget.serviceType,
      "address": addressController.text.trim(),
      "details": detailsController.text.trim(),
      "scheduleOrder": false,
      "date": null,
      "time": null,
      "scheduleDateTime": null,
      "imageUrls": imageUrls,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
      "customerId": user?.uid,
      "customerName": customerName ?? "Customer",
      "customerEmail": customerEmail ?? "",
    };

    final doc = await FirebaseFirestore.instance.collection('orders').add(orderData);
    return doc.id;
  }

  Future<void> _submitOrder() async {
    if (!_isFormValid()) return;

    setState(() {
      isUploading = true;
    });

    try {
      final orderId = await _saveOrder();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FindingWorkerScreen(
              orderId: orderId,
              serviceType: widget.serviceType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future pickImage(ImageSource type) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: type, imageQuality: 70);
    if (img != null) {
      setState(() => photos.add(File(img.path)));
    }
  }

  void removeImage(int index) {
    setState(() {
      photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Place order - ${widget.serviceType}",
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cleaning_services, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    widget.serviceType,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _sectionTitle("Address"),
            TextField(
              controller: addressController,
              decoration: _inputDecoration("Enter address"),
            ),

            const SizedBox(height: 22),

            _sectionTitle("Details"),
            TextField(
              controller: detailsController,
              maxLines: 3,
              decoration: _inputDecoration("Describe your issue"),
            ),

            const SizedBox(height: 22),

            _sectionTitle("Photos (${photos.length})"),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  InkWell(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => _buildPhotoSheet(),
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: _boxStyle(),
                      child: const Icon(Icons.add, size: 40),
                    ),
                  ),
                  for (int i = 0; i < photos.length; i++)
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: _boxStyle(),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(photos[i], fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => removeImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUploading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isUploading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  "Confirm Order",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Colors.black,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  BoxDecoration _boxStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildPhotoSheet() {
    return SizedBox(
      height: 160,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Choose from Gallery"),
            onTap: () {
              pickImage(ImageSource.gallery);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take Photo"),
            onTap: () {
              pickImage(ImageSource.camera);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}