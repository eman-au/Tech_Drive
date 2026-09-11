import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'worker_orders_screen.dart';
import 'worker_earnings_screen.dart';
import 'worker_order_detail_screen.dart';
import 'worker_notifications_screen.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  static const Color brand = Color(0xFFCCFD04);
  final AuthService _auth = AuthService();
  final user = FirebaseAuth.instance.currentUser!;
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    NotificationService.startListening(user.uid);
    _loadWorkerStatus();
  }

  Future<void> _loadWorkerStatus() async {
    final status = await _auth.getWorkerStatus();
    setState(() {
      isOnline = status;
    });
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    setState(() {
      isOnline = value;
    });
    await _auth.updateWorkerStatus(value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? "You are now ONLINE" : "You are now OFFLINE"),
        backgroundColor: value ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      drawer: _drawer(),
      appBar: AppBar(
        backgroundColor: brand,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "Welcome ${user.displayName ?? user.email?.split('@').first ?? 'User'}",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          GestureDetector(
            onTap: () => _toggleOnlineStatus(!isOnline),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOnline ? "ONLINE" : "OFFLINE",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _dashboard(),
          const SizedBox(height: 8),
          if (isOnline) _realOffersSection(),
          Expanded(
            child: isOnline
                ? const Center(
              child: Text(
                "Tap an offer to view details",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
                : _offlineView(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: _bottomBtn(
                iconWidget: const Icon(Icons.assignment, size: 20),
                label: "Orders",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkerOrdersScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _bottomBtn(
                iconWidget: _buildWorkerAlertsIcon(),
                label: "Alerts",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkerNotificationsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _bottomBtn(
                iconWidget: const Icon(Icons.account_balance_wallet, size: 20),
                label: "Earnings",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkerEarningsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          int pendingCount = 0;
          if (snapshot.hasData && !snapshot.hasError) {
            pendingCount = snapshot.data!.docs.length;
          }
          return Row(
            children: [
              _dashCard("Offers", pendingCount.toString(), Icons.local_offer),
              const SizedBox(width: 10),
              _dashCard("Status", isOnline ? "Online" : "Offline", Icons.circle),
              const SizedBox(width: 10),
              _dashCard("Mode", "Cash", Icons.money),
            ],
          );
        },
      ),
    );
  }

  Widget _dashCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: brand, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractImageUrls(Map<String, dynamic> data) {
    List<String> imageUrls = [];
    final possibleFields = ['imageUrls', 'images', 'photos'];
    for (var field in possibleFields) {
      if (data[field] != null && data[field] is List) {
        imageUrls = List<String>.from(data[field]);
        break;
      }
    }
    return imageUrls;
  }

  Widget _realOffersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final orders = snapshot.data!.docs;
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No pending orders')),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Available Offers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final data = order.data() as Map<String, dynamic>;
                  return _buildOfferCard(order.id, data);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOfferCard(String orderId, Map<String, dynamic> data) {
    String customerName = data['customerName'] ?? 'Customer';
    String serviceType = data['serviceType'] ?? 'Service';
    String address = data['address'] ?? 'No address';
    String details = data['details'] ?? 'No details';
    List<String> imageUrls = _extractImageUrls(data);
    String customerIdValue = data['customerId'] ?? '';

    String timeAgo = '';
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      DateTime orderTime = (data['createdAt'] as Timestamp).toDate();
      DateTime now = DateTime.now();
      Duration diff = now.difference(orderTime);
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours} hours ago';
      } else {
        timeAgo = DateFormat('MMM dd').format(orderTime);
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerOrderDetailScreen(
              orderId: orderId,
              customerId: customerIdValue,
              customerName: customerName,
              serviceType: serviceType,
              area: address,
              problemDetails: details,
              createdAt: timeAgo,
              imageUrls: imageUrls,
            ),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brand.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    serviceType,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              customerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              details,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.image, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${imageUrls.length} photo${imageUrls.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "View Details",
                  style: TextStyle(color: Colors.green[700], fontSize: 11),
                ),
                Icon(Icons.arrow_forward, size: 12, color: Colors.green[700]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.construction, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? user.email?.split('@').first ?? 'Worker',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _drawerTile(Icons.person_outline, "My Profile", () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            }),
            _drawerTile(Icons.settings_outlined, "Settings", () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            }),
            _drawerTile(Icons.help_outline, "Help & Support", () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/support');
            }),
            _drawerTile(Icons.contact_support_outlined, "Contact Us", () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/contact');
            }),
            const Spacer(),
            const Divider(),
            _drawerTile(Icons.logout, "Logout", () async {
              NotificationService.stopListening();
              await _auth.logout();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }, color: Colors.red),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  Widget _offlineView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("You are offline", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Turn ON to see available offers"),
        ],
      ),
    );
  }

  Widget _bottomBtn({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: iconWidget,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildWorkerAlertsIcon() {
    return StreamBuilder<int>(
      stream: NotificationService.getUnreadCountStream(user.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none, size: 20),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}