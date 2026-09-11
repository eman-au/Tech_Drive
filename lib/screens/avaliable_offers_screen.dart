import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'request_accepted_screen.dart';
import '../services/notification_service.dart';

class AvailableOffersScreen extends StatelessWidget {
  final String orderId;
  final String serviceType; // ✅ NEW — service ke hisaab se workers filter honge

  const AvailableOffersScreen({
    super.key,
    required this.orderId,
    required this.serviceType, // ✅ NEW
  });

  final Color brand = const Color(0xFFCCFD04);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: brand,
        title: const Text("Available Workers",
            style: TextStyle(color: Colors.black)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ Listen in real time to the offers subcollection
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .collection('offers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final offers = snapshot.data!.docs;

          if (offers.isEmpty) {
            return const Center(
              child: Text("No offers submitted yet"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (_, index) {
              final worker = offers[index].data() as Map<String, dynamic>;
              final workerUid = offers[index].id;
              final workerName = worker['workerName'] ?? 'Worker';
              final workerImage = worker['workerImage'] ?? '';
              final price = worker['price'] ?? 'TBD';
              final eta = worker['eta'] ?? 'TBD';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      backgroundImage: (workerImage.startsWith('http') || workerImage.startsWith('https'))
                          ? NetworkImage(workerImage)
                          : null,
                      child: workerImage.isEmpty
                          ? const Icon(Icons.person, color: Colors.white, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(workerName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Quoted Price: $price"),
                          Text("Estimated ETA: $eta",
                              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brand,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

                        // Capture customerId before transaction (needed for in-app notifications)
                        String customerId = '';
                        String customerName = '';

                        try {
                          await FirebaseFirestore.instance.runTransaction((transaction) async {
                            final orderSnap = await transaction.get(orderRef);
                            final orderData = orderSnap.data();

                            // Prevent multiple accepted offers
                            if (orderData?['status'] == 'accepted') {
                              throw Exception('Order already accepted');
                            }

                            // Capture customer info for notifications (post-transaction)
                            customerId = (orderData?['customerId'] ?? '') as String;
                            customerName = (orderData?['customerName'] ?? 'Customer') as String;

                            // 1. Update parent order document
                            transaction.update(orderRef, {
                              "status": "accepted",
                              "workerName": workerName,
                              "workerId": workerUid,
                              "workerPhone": worker['workerPhone'] ?? '',
                              "workerImage": workerImage,
                              "quotedPrice": price,
                              "quotedEta": eta,
                              "acceptedAt": FieldValue.serverTimestamp(),
                            });

                            // 2. Get all offers for this order and update statuses
                            final offersRef = orderRef.collection('offers');
                            final offersSnap = await offersRef.get();

                            for (var doc in offersSnap.docs) {
                              if (doc.id == workerUid) {
                                transaction.update(doc.reference, {"status": "accepted"});
                              } else {
                                transaction.update(doc.reference, {"status": "rejected"});
                              }
                            }
                          });

                          // --- In-app notification: worker receives quotation_accepted ---
                          if (customerId.isNotEmpty) {
                            await NotificationService.saveNotification(
                              receiverId: workerUid,
                              senderId: customerId,
                              orderId: orderId,
                              title: 'Offer Accepted! 🎉',
                              body: '$customerName ne aapki offer accept kar li hai!',
                              type: 'quotation_accepted',
                            );
                          }

                          // --- FCM push to worker (existing behaviour) ---
                          await NotificationService.sendNotification(
                            recipientUid: workerUid,
                            title: "Offer Accepted! 🎉",
                            body: "Customer ne aapki offer accept kar li hai!",
                            data: {"orderId": orderId},
                          );

                          if (!context.mounted) return;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestAcceptedScreen(
                                worker: {
                                  "name": workerName,
                                  "rate": price,
                                  "time": eta,
                                  "image": workerImage,
                                  "uid": workerUid,
                                },
                                orderId: orderId,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text("Select"),
                    )
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