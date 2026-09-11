import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart'; // ✅ NEW
import 'worker_chat_screen.dart';

class WorkerOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String customerId;
  final String serviceType;
  final String area;
  final String? problemDetails;
  final String? createdAt;
  final List<String>? imageUrls;

  const WorkerOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerId,
    required this.serviceType,
    required this.area,
    this.problemDetails,
    this.createdAt,
    this.imageUrls,
  });

  @override
  State<WorkerOrderDetailScreen> createState() => _WorkerOrderDetailScreenState();
}

class _WorkerOrderDetailScreenState extends State<WorkerOrderDetailScreen> {
  final Color brand = const Color(0xFFCCFD04);
  bool isAccepting = false;
  int selectedPrice = 200;
  String selectedEta = "15 mins";

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> safeImageUrls = widget.imageUrls ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: brand,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: brand.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.serviceType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            _infoCard(icon: Icons.person, title: 'Customer', value: widget.customerName),
            const SizedBox(height: 12),

            _infoCard(icon: Icons.location_on, title: 'Address', value: widget.area),
            const SizedBox(height: 12),

            if (widget.problemDetails != null && widget.problemDetails!.isNotEmpty)
              _infoCard(icon: Icons.description, title: 'Problem Details', value: widget.problemDetails!),
            const SizedBox(height: 12),

            if (widget.createdAt != null)
              _infoCard(icon: Icons.access_time, title: 'Requested', value: widget.createdAt!),

            if (safeImageUrls.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Text('${safeImageUrls.length} image${safeImageUrls.length > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: safeImageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(safeImageUrls[index]),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            safeImageUrls[index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text('Image not found', style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Tap on any image to view full screen',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
            ] else ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No photos attached', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orderData = orderSnapshot.data?.data() as Map<String, dynamic>?;
                final orderStatus = orderData?['status'] ?? 'pending';
                final orderWorkerId = orderData?['workerId'];

                final workerName = orderData?['workerName'] as String? ?? 'Worker';
                return _buildWorkerActions(orderStatus, orderWorkerId, workerName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: brand, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerActions(String orderStatus, String? orderWorkerId, String workerName) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    if (orderStatus == 'pending' || orderStatus == 'Pending') {
      // Stream the worker's own offer
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .collection('offers')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasOffer = snapshot.hasData && snapshot.data!.exists;
          if (hasOffer) {
            final offerData = snapshot.data!.data() as Map<String, dynamic>;
            final price = offerData['price'] ?? 'TBD';
            final eta = offerData['eta'] ?? 'TBD';
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Quotation Submitted',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Price: $price'),
                  Text('ETA: $eta'),
                ],
              ),
            );
          }

          // Offer does not exist -> show quotation form
          return _buildQuotationForm();
        },
      );
    } else if (orderStatus == 'accepted' ||
        orderStatus == 'on_my_way' ||
        orderStatus == 'arrived' ||
        orderStatus == 'Accepted' ||
        orderStatus == 'On my way' ||
        orderStatus == 'Arrived') {
      if (orderWorkerId == user.uid) {
        // Show job controls: accepted -> "On My Way", on_my_way -> "Arrived", arrived -> "Job Completed"
        return _buildJobControls(orderStatus, workerName);
      } else {
        // Show another worker selected
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Another worker was selected for this job.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } else if (orderStatus == 'completed' || orderStatus == 'Completed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[300]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 12),
            Text(
              'Job Completed',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else if (orderStatus == 'cancelled' || orderStatus == 'Cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Order Cancelled by Customer',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildQuotationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quotation Price (Fee)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('200 PKR'),
                selected: selectedPrice == 200,
                onSelected: (val) {
                  if (val) setState(() => selectedPrice = 200);
                },
                selectedColor: brand,
                labelStyle: TextStyle(
                  color: selectedPrice == 200 ? Colors.black : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('300 PKR'),
                selected: selectedPrice == 300,
                onSelected: (val) {
                  if (val) setState(() => selectedPrice = 300);
                },
                selectedColor: brand,
                labelStyle: TextStyle(
                  color: selectedPrice == 300 ? Colors.black : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('ETA (Estimated Time of Arrival)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedEta,
          items: ['10 mins', '15 mins', '20 mins', '30 mins'].map((time) {
            return DropdownMenuItem(value: time, child: Text(time));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => selectedEta = val);
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isAccepting ? null : _submitOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isAccepting
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Submit Quotation / Offer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildJobControls(String status, String workerName) {
    String buttonText = "";
    String expectedPrevStatus = "";
    String nextStatus = "";
    Color btnColor = Colors.blue;

    if (status == 'accepted' || status == 'Accepted') {
      buttonText = "On My Way";
      expectedPrevStatus = status; // works for both casing
      nextStatus = "on_my_way";
      btnColor = Colors.orange;
    } else if (status == 'on_my_way' || status == 'On my way') {
      buttonText = "Arrived";
      expectedPrevStatus = status;
      nextStatus = "arrived";
      btnColor = Colors.indigo;
    } else if (status == 'arrived' || status == 'Arrived') {
      buttonText = "Job Completed";
      expectedPrevStatus = status;
      nextStatus = "completed";
      btnColor = Colors.green;
    }

    return Column(
      children: [
        // Status-advance button (On My Way / Arrived / Job Completed)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isAccepting ? null : () => _updateOrderStatus(expectedPrevStatus, nextStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isAccepting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Chat button — visible while order is active
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text(
              'Chat with Customer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerChatScreen(
                    orderId: widget.orderId,
                    customerId: widget.customerId,
                    customerName: widget.customerName,
                    workerName: workerName,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updateOrderStatus(String expectedPrevStatus, String nextStatus) async {
    setState(() => isAccepting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(orderRef);
        if (!doc.exists) {
          throw Exception("Order document does not exist");
        }

        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'];
        final workerId = data['workerId'];

        if (workerId != user.uid) {
          throw Exception("You are not the assigned worker for this order");
        }

        if (status != expectedPrevStatus) {
          throw Exception("Invalid order status: expected $expectedPrevStatus, but found $status");
        }

        transaction.update(orderRef, {'status': nextStatus});
      });

      // --- In-app notification to customer after successful status update ---
      final notifMap = <String, Map<String, String>>{
        'on_my_way': {
          'type': 'worker_on_my_way',
          'title': 'Worker is on the way! 🚗',
          'body': 'Your worker is heading to your location.',
        },
        'arrived': {
          'type': 'worker_arrived',
          'title': 'Worker has arrived! 📍',
          'body': 'Your worker has arrived at your location.',
        },
        'completed': {
          'type': 'order_completed',
          'title': 'Job Completed! ✅',
          'body': 'Your order has been marked as completed.',
        },
      };
      final notif = notifMap[nextStatus];
      if (notif != null && widget.customerId.isNotEmpty) {
        await NotificationService.saveNotification(
          receiverId: widget.customerId,
          senderId: user.uid,
          orderId: widget.orderId,
          title: notif['title']!,
          body: notif['body']!,
          type: notif['type']!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isAccepting = false);
    }
  }

  Future<void> _submitOffer() async {
    setState(() => isAccepting = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch worker details from Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final workerData = doc.data();
        final workerName = workerData?['name'] ?? user.displayName ?? user.email?.split('@').first ?? 'Worker';

        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .collection('offers')
            .doc(user.uid)
            .set({
          'workerId': user.uid,
          'workerName': workerName,
          'workerImage': workerData?['profileImage'] ?? '',
          'workerPhone': workerData?['phone'] ?? '',
          'price': '$selectedPrice PKR',
          'eta': selectedEta,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // --- In-app notification: customer receives quotation_received ---
        if (widget.customerId.isNotEmpty) {
          await NotificationService.saveNotification(
            receiverId: widget.customerId,
            senderId: user.uid,
            orderId: widget.orderId,
            title: 'New Offer Received! 🔔',
            body: '$workerName ne Rs. $selectedPrice ki offer bheji hai!',
            type: 'quotation_received',
          );
        }

        // FCM push stub (no-op — requires backend)
        await NotificationService.sendNotification(
          recipientUid: widget.customerId,
          title: "Nai Offer! 🔔",
          body: "$workerName ne Rs. $selectedPrice ki offer bheji hai!",
          data: {"orderId": widget.orderId},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer submitted successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isAccepting = false);
    }
  }
}