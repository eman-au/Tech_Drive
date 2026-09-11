import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class RatingScreen extends StatefulWidget {
  final String orderId;
  final String? workerId;
  final String? workerName;
  final String? workerImage;
  final String? serviceType;

  const RatingScreen({
    super.key,
    required this.orderId,
    this.workerId,
    this.workerName,
    this.workerImage,
    this.serviceType,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  static const Color brandColor = Color(0xFFCCFD04);
  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isLoading = false;
  bool _isAlreadyReviewed = false;

  String? _effectiveWorkerId;
  String? _effectiveWorkerName;
  String? _effectiveWorkerImage;
  String? _effectiveServiceType;

  @override
  void initState() {
    super.initState();
    _effectiveWorkerId = widget.workerId;
    _effectiveWorkerName = widget.workerName;
    _effectiveWorkerImage = widget.workerImage;
    _effectiveServiceType = widget.serviceType;

    _checkExistingReviewAndLoadOrderData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReviewAndLoadOrderData() async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (orderDoc.exists) {
        final data = orderDoc.data()!;
        if (data['isReviewed'] == true) {
          if (mounted) {
            setState(() {
              _isAlreadyReviewed = true;
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
      debugPrint("Error checking order review status: $e");
    }
  }

  Future<void> _submitReview() async {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating between 1 and 5 stars.")),
      );
      return;
    }

    if (_isAlreadyReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This order has already been reviewed."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final customerId = user?.uid ?? '';
      String customerName = user?.displayName ?? 'Customer';

      if (customerId.isNotEmpty && customerName == 'Customer') {
        final customerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(customerId)
            .get();
        if (customerDoc.exists && customerDoc.data()?['name'] != null) {
          customerName = customerDoc.data()!['name'];
        }
      }

      // 1️⃣ Verify order existence & review status atomically
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        throw "Order not found.";
      }

      final orderData = orderSnap.data()!;
      if (orderData['isReviewed'] == true) {
        if (mounted) {
          setState(() => _isAlreadyReviewed = true);
        }
        throw "Duplicate review: You have already submitted a review for this order.";
      }

      final targetWorkerId = _effectiveWorkerId ?? orderData['workerId'] ?? '';
      final targetWorkerName = _effectiveWorkerName ?? orderData['workerName'] ?? 'Worker';
      final reviewText = _reviewController.text.trim();

      // 2️⃣ Save review to 'ratings' collection
      await FirebaseFirestore.instance.collection('ratings').add({
        'orderId': widget.orderId,
        'customerId': customerId,
        'customerName': customerName,
        'workerId': targetWorkerId,
        'workerName': targetWorkerName,
        'rating': _rating.toDouble(),
        'review': reviewText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Mark order as reviewed
      await orderRef.update({'isReviewed': true});

      // 4️⃣ Incrementally update worker's average rating in 'workers' and 'users' collections
      if (targetWorkerId.isNotEmpty) {
        await _updateWorkerRatingStats(targetWorkerId, _rating.toDouble());

        // Notify worker about the rating
        await NotificationService.saveNotification(
          receiverId: targetWorkerId,
          senderId: customerId,
          orderId: widget.orderId,
          title: "New Rating Received! ⭐",
          body: "$customerName gave you a $_rating star rating!",
          type: "rating",
        );
      }

      if (mounted) {
        setState(() {
          _isAlreadyReviewed = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thank you! Your review has been submitted successfully ⭐"),
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

  Future<void> _updateWorkerRatingStats(String workerId, double newRating) async {
    try {
      final workerRef = FirebaseFirestore.instance.collection('workers').doc(workerId);
      final workerSnap = await workerRef.get();

      double oldAvg = 0.0;
      int oldTotal = 0;

      if (workerSnap.exists && workerSnap.data() != null) {
        final wData = workerSnap.data()!;
        oldAvg = (wData['avgRating'] ?? wData['rating'] ?? 0.0).toDouble();
        oldTotal = (wData['totalRatings'] ?? wData['reviewsCount'] ?? 0).toInt();
      }

      final newTotal = oldTotal + 1;
      final newAvg = ((oldAvg * oldTotal) + newRating) / newTotal;

      final updatePayload = {
        'avgRating': double.parse(newAvg.toStringAsFixed(2)),
        'totalRatings': newTotal,
        'rating': double.parse(newAvg.toStringAsFixed(2)),
        'reviewsCount': newTotal,
      };

      await workerRef.set(updatePayload, SetOptions(merge: true));

      // Also sync user document for worker
      await FirebaseFirestore.instance
          .collection('users')
          .doc(workerId)
          .set(updatePayload, SetOptions(merge: true));

    } catch (e) {
      debugPrint("Error updating worker average rating: $e");
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
          "Rate & Review",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // WORKER & ORDER SUMMARY CARD
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
                    radius: 32,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (_effectiveWorkerImage != null &&
                            _effectiveWorkerImage!.startsWith('http'))
                        ? NetworkImage(_effectiveWorkerImage!)
                        : null,
                    child: (_effectiveWorkerImage == null ||
                            !_effectiveWorkerImage!.startsWith('http'))
                        ? const Icon(Icons.person, size: 36, color: Colors.black54)
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Service: $displayServiceType",
                          style: TextStyle(
                            fontSize: 14,
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

            // RATING INPUT CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  const Text(
                    "How was your service experience?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // LARGE CLICKABLE STARS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        iconSize: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          starIndex <= _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: (_isLoading || _isAlreadyReviewed)
                            ? null
                            : () {
                                setState(() {
                                  _rating = starIndex;
                                });
                              },
                      );
                    }),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "$_rating / 5 Stars",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // MULTILINE REVIEW INPUT FIELD
                  TextField(
                    controller: _reviewController,
                    enabled: !_isLoading && !_isAlreadyReviewed,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: "Write your review (optional, max 500 characters)...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xfff9fafc),
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
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ALREADY REVIEWED WARNING BADGE
            if (_isAlreadyReviewed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[800]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "You have already submitted a review for this order.",
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

            // ACTION BUTTONS
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
                        backgroundColor: brandColor,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: (_isLoading || _isAlreadyReviewed) ? null : _submitReview,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              "Submit Review",
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