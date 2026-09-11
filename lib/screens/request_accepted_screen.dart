import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'live_tracking_screen.dart';
import 'chat_screen.dart';
import '../services/notification_service.dart'; // ✅ NEW

class RequestAcceptedScreen extends StatelessWidget {
  final Map<String, dynamic> worker;
  final String orderId;

  const RequestAcceptedScreen({
    super.key,
    required this.worker,
    required this.orderId,
  });

  static const Color brand = Color(0xFFCCFD04);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: brand,
        title: const Text("Request Accepted",
            style: TextStyle(color: Colors.black)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'];
          final workerId = data['workerId'];

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(workerId)
                .snapshots(),
            builder: (context, workerSnapshot) {
              final workerData = workerSnapshot.data?.data() as Map<String, dynamic>?;
              final name = workerData?['name'] ?? data['workerName'] ?? worker['name'] ?? 'Worker';
              final image = workerData?['profileImage'] ?? data['workerImage'] ?? worker['image'] ?? '';
              final double rating = workerData?['avgRating']?.toDouble() ?? 5.0;
              final price = data['quotedPrice'] != null ? "Rs. ${data['quotedPrice']}" : worker['rate'] ?? "Rate TBD";
              final eta = data['quotedEta'] ?? worker['time'] ?? "ETA TBD";
              final customerId = data['customerId'] as String? ?? '';
              final customerName = data['customerName'] as String? ?? 'Customer';

              final imageProvider = (image.startsWith('http') || image.startsWith('https'))
                  ? NetworkImage(image)
                  : AssetImage(image.isNotEmpty ? image : "assets/images/plumber1.jpg") as ImageProvider;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: imageProvider,
                    ),
                    const SizedBox(height: 20),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("⭐ ${rating.toStringAsFixed(1)} • $price • ETA $eta"),
                    const SizedBox(height: 40),

                    // Track Worker Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brand,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LiveTrackingScreen(orderId: orderId),
                            ),
                          );
                        },
                        child: const Text("Track Worker"),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Chat button — visible while order is active
                    if (status == 'accepted' ||
                        status == 'on_my_way' ||
                        status == 'arrived')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text("Chat with Worker"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  orderId: orderId,
                                  workerId: workerId ?? '',
                                  customerId: customerId,
                                  workerName: name,
                                  customerName: customerName,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 12),

                    // ✅ Cancel button — sirf tab dikhao jab worker "on_my_way" nahi hua
                    if (status == 'accepted')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            // Confirm dialog
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Cancel Order?"),
                                content: const Text(
                                    "Kya aap sach mein ye order cancel karna chahte hain?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Nahi"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Haan, Cancel Karo",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              // Firestore update
                              await FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(orderId)
                                  .update({'status': 'cancelled'});

                              // In-app notification to worker
                              if (workerId != null && workerId.isNotEmpty) {
                                await NotificationService.saveNotification(
                                  receiverId: workerId,
                                  senderId: customerId,
                                  orderId: orderId,
                                  title: 'Order Cancelled ❌',
                                  body: 'Customer ne order cancel kar diya hai.',
                                  type: 'order_cancelled',
                                );
                                // FCM push stub (no-op — requires backend)
                                await NotificationService.sendNotification(
                                  recipientUid: workerId,
                                  title: 'Order Cancelled ❌',
                                  body: 'Customer ne order cancel kar diya hai.',
                                  data: {'orderId': orderId},
                                );
                              }

                              if (context.mounted) {
                                Navigator.popUntil(
                                    context, ModalRoute.withName('/home'));
                              }
                            }
                          },
                          child: const Text("Cancel Order"),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}