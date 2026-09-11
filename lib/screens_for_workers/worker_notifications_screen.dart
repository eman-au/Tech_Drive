import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'worker_order_detail_screen.dart';

class WorkerNotificationsScreen extends StatelessWidget {
  const WorkerNotificationsScreen({super.key});

  static const Color brand = Color(0xFFCCFD04);

  String _relativeTime(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final dt = ts.toDate();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'quotation_accepted':
        return Icons.check_circle_outline;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: brand,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: brand,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No notifications yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72, endIndent: 16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] as bool? ?? true;
              final title = data['title'] as String? ?? '';
              final body = data['body'] as String? ?? '';
              final orderId = data['orderId'] as String?;
              final type = data['type'] as String?;
              final ts = data['createdAt'] as Timestamp?;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      backgroundColor: isRead
                          ? Colors.grey[100]
                          : brand.withValues(alpha: 0.2),
                      child: Icon(
                        _iconFor(type),
                        color: isRead ? Colors.grey : Colors.black,
                        size: 22,
                      ),
                    ),
                    if (!isRead)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(body,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(_relativeTime(ts),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                isThreeLine: true,
                tileColor:
                    isRead ? Colors.white : brand.withValues(alpha: 0.06),
                onTap: () async {
                  // 1. Always mark notification as read
                  if (!isRead) {
                    await doc.reference.update({'isRead': true});
                  }

                  if (!context.mounted) return;

                  // 2. Validate orderId string (must not be null, empty, or whitespace)
                  final bool hasValidOrderId = orderId != null && orderId.trim().isNotEmpty;

                  if (hasValidOrderId) {
                    // Navigate to worker order detail screen with valid orderId
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerOrderDetailScreen(
                          orderId: orderId.trim(),
                          customerName: data['senderName'] as String? ?? 'Customer',
                          customerId: data['senderId'] as String? ?? '',
                          serviceType: '',
                          area: '',
                        ),
                      ),
                    );
                  } else {
                    // Show notification detail dialog without querying orders or crashing
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            const Icon(Icons.notifications, color: Colors.black),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title.isNotEmpty ? title : 'Notification',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                body,
                                style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                              ),
                              if (ts != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _relativeTime(ts),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
