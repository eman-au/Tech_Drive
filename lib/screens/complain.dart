import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComplaintScreen extends StatefulWidget {
  final String orderId;
  final String? workerId;
  final String? workerName;
  final String? workerImage;
  final String? serviceType;
  final String? otherUserId;
  final String? otherUserName;
  final String? complaintBy;

  const ComplaintScreen({
    super.key,
    required this.orderId,
    this.workerId,
    this.workerName,
    this.workerImage,
    this.serviceType,
    this.otherUserId,
    this.otherUserName,
    this.complaintBy,
  });

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  static const Color brandColor = Color(0xFFCCFD04);

  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Late Arrival';
  bool _isLoading = false;
  bool _isAlreadySubmitted = false;

  String? _effectiveWorkerId;
  String? _effectiveWorkerName;
  String? _effectiveWorkerImage;
  String? _effectiveServiceType;
  String? _effectiveComplaintBy;

  final List<String> _categories = [
    'Late Arrival',
    'Overcharging',
    'Poor Work Quality',
    'Bad Behaviour',
    'Fraud',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _effectiveWorkerId = widget.workerId ?? widget.otherUserId;
    _effectiveWorkerName = widget.workerName ?? widget.otherUserName;
    _effectiveWorkerImage = widget.workerImage;
    _effectiveServiceType = widget.serviceType;
    _effectiveComplaintBy = widget.complaintBy ?? 'Customer';

    _checkExistingComplaintAndLoadOrderData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingComplaintAndLoadOrderData() async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (orderDoc.exists) {
        final data = orderDoc.data()!;
        if (data['isComplaintSubmitted'] == true) {
          if (mounted) {
            setState(() {
              _isAlreadySubmitted = true;
            });
          }
        }
        if (_effectiveWorkerId == null || _effectiveWorkerId!.isEmpty) {
          _effectiveWorkerId = data['workerId'];
        }
        if (_effectiveWorkerName == null || _effectiveWorkerName!.isEmpty) {
          _effectiveWorkerName = data['workerName'] ?? 'Worker';
        }
        if (_effectiveWorkerImage == null || _effectiveWorkerImage!.isEmpty) {
          _effectiveWorkerImage = data['workerImage'] ?? 'assets/images/plumber1.jpg';
        }
        if (_effectiveServiceType == null || _effectiveServiceType!.isEmpty) {
          _effectiveServiceType = data['serviceType'] ?? 'Service';
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error loading order complaint data: $e");
    }
  }

  Future<void> _submitComplaint() async {
    final description = _descriptionController.text.trim();

    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a complaint category.")),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a description of your complaint.")),
      );
      return;
    }

    if (_isAlreadySubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A complaint has already been submitted for this order."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final complainantId = user?.uid ?? '';
      String complaintBy = _effectiveComplaintBy ?? 'Customer';

      if (complainantId.isNotEmpty && (complaintBy == 'Customer' || complaintBy.isEmpty)) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(complainantId)
            .get();
        if (userDoc.exists && userDoc.data()?['name'] != null) {
          complaintBy = userDoc.data()!['name'];
        }
      }

      // 1. Verify order existence and check duplicate flag
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        throw "Order not found.";
      }

      final orderData = orderSnap.data()!;
      if (orderData['isComplaintSubmitted'] == true) {
        if (mounted) {
          setState(() => _isAlreadySubmitted = true);
        }
        throw "Duplicate complaint: A complaint has already been filed for this order.";
      }

      final targetWorkerId = _effectiveWorkerId ?? orderData['workerId'] ?? '';
      final targetWorkerName = _effectiveWorkerName ?? orderData['workerName'] ?? 'Worker';

      // 2. Submit complaint using existing 'complaints' schema used by Admin Dashboard
      await FirebaseFirestore.instance.collection('complaints').add({
        'orderId': widget.orderId,
        'complaintBy': complaintBy,
        'complainantId': complainantId,
        'againstUserId': targetWorkerId,
        'againstUserName': targetWorkerName,
        'category': _selectedCategory,
        'description': description,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Mark order document with isComplaintSubmitted flag
      await orderRef.update({'isComplaintSubmitted': true});

      if (mounted) {
        setState(() {
          _isAlreadySubmitted = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Complaint submitted successfully ✅"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } on FirebaseException catch (fe) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Firebase Error: ${fe.message ?? fe.code}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayWorkerName = _effectiveWorkerName ?? "Worker";
    final displayServiceType = _effectiveServiceType ?? "Service";

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: brandColor,
        elevation: 0,
        title: const Text(
          "File a Complaint",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WORKER & ORDER HEADER CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (_effectiveWorkerImage != null &&
                            _effectiveWorkerImage!.startsWith('http'))
                        ? NetworkImage(_effectiveWorkerImage!)
                        : null,
                    child: (_effectiveWorkerImage == null ||
                            !_effectiveWorkerImage!.startsWith('http'))
                        ? const Icon(Icons.person, size: 34, color: Colors.black54)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayWorkerName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Service: $displayServiceType",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Order ID: ${widget.orderId}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // COMPLAINT CATEGORY DROPDOWN
            const Text(
              "Complaint Category *",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (_isLoading || _isAlreadySubmitted)
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // DESCRIPTION INPUT FIELD
            const Text(
              "Description *",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              enabled: !_isLoading && !_isAlreadySubmitted,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: "Please describe the issue in detail (max 1000 characters)...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ALREADY SUBMITTED NOTICE
            if (_isAlreadySubmitted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "A complaint has already been submitted for this order.",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: (_isLoading || _isAlreadySubmitted) ? null : _submitComplaint,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Submit Complaint",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}