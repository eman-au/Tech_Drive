import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'finding_worker_screen.dart';
import 'request_accepted_screen.dart';
import 'order_detail_screen.dart';
import 'rating_screen.dart';
import 'complain.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color brandColor = const Color(0xFFCCFD04);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(246, 248, 252, 1),
      body: Column(
        children: [
          // TAB BAR
          Container(
            height: 80,
            color: Colors.white,
            alignment: Alignment.bottomCenter,
            child: TabBar(
              controller: _tabController,
              indicatorColor: brandColor,
              indicatorWeight: 5,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: "Pending"),
                Tab(text: "History"),
              ],
            ),
          ),

          // TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _pendingOrders(),
                _historyOrders(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= PENDING ORDERS =================
  Widget _pendingOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: user!.uid)
          .where('status', whereIn: ["pending", "accepted", "on_my_way", "arrived", "Pending", "Accepted", "On my way", "Arrived"])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
            icon: Icons.search_off,
            title: "No Pending Orders",
            subtitle: "You have no active orders right now.",
          );
        }

        final orders = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
        orders.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data() as Map<String, dynamic>;
            return _orderCard(orders[index].id, data);
          },
        );
      },
    );
  }

  // ================= HISTORY ORDERS =================
  Widget _historyOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: user!.uid)
          .where('status', whereIn: ["completed", "cancelled", "Completed", "Cancelled"])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
            icon: Icons.history,
            title: "No History Yet",
            subtitle: "Your completed orders will appear here.",
          );
        }

        final orders = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
        orders.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data() as Map<String, dynamic>;
            return _historyCard(orders[index].id, data);
          },
        );
      },
    );
  }

  // ================= EMPTY STATE =================
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ================= ORDER CARD =================
  Widget _orderCard(String orderId, Map<String, dynamic> data) {
    final status = data['status'] ?? "Pending";
    final serviceType = data['serviceType'] ?? "Service";

    return GestureDetector(
      onTap: () {
        if (status == 'pending' || status == 'Pending') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FindingWorkerScreen(
                orderId: orderId,
                serviceType: serviceType,
              ),
            ),
          );
        } else if (status == 'accepted' ||
            status == 'on_my_way' ||
            status == 'arrived' ||
            status == 'Accepted' ||
            status == 'On my way' ||
            status == 'Arrived') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestAcceptedScreen(
                worker: {
                  "name": data['workerName'] ?? 'Worker',
                  "rate": data['quotedPrice'] != null ? "Rs. ${data['quotedPrice']}" : "Rate TBD",
                  "time": data['quotedEta'] ?? "ETA TBD",
                  "image": data['workerImage'] ?? "assets/images/plumber1.jpg",
                  "uid": data['workerId'] ?? '',
                },
                orderId: orderId,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                data['serviceType'] == "Electrician"
                    ? Icons.flash_on
                    : Icons.plumbing,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['serviceType'] ?? "Service",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['details'] ?? "Service requested",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            _statusBadge(status),
          ],
        ),
      ),
    );
  }

  // ================= HISTORY CARD =================
  Widget _historyCard(String orderId, Map<String, dynamic> data) {
    final status = data['status'] ?? "Completed";
    final isCompleted = status.toString().toLowerCase() == 'completed';
    final isReviewed = data['isReviewed'] == true;
    final isComplaintSubmitted = data['isComplaintSubmitted'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['serviceType'] ?? "Service",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data['details'] ?? "Service completed successfully",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(data['createdAt']),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),

                // ACTIONS FOR COMPLETED ORDERS
                if (isCompleted) ...[
                  Row(
                    children: [
                      // RATE BADGE / BUTTON
                      if (isReviewed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Reviewed ⭐",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Rate",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RatingScreen(
                                  orderId: orderId,
                                  workerId: data['workerId'],
                                  workerName: data['workerName'],
                                  workerImage: data['workerImage'],
                                  serviceType: data['serviceType'],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(width: 8),

                      // COMPLAINT BADGE / BUTTON
                      if (isComplaintSubmitted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Complain ⚠️",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Complain",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ComplaintScreen(
                                  orderId: orderId,
                                  workerId: data['workerId'],
                                  workerName: data['workerName'],
                                  workerImage: data['workerImage'],
                                  serviceType: data['serviceType'],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATUS BADGE =================
  Widget _statusBadge(String status) {
    Color color = (status == "Completed" || status == "completed")
        ? Colors.green
        : (status == "Cancelled" || status == "cancelled")
        ? Colors.red
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.3),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  // ================= FORMAT TIME =================
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    final date = (timestamp as Timestamp).toDate();
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hrs ago";
    } else {
      return "${difference.inDays} days ago";
    }
  }
}
