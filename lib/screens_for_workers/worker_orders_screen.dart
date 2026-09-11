import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'worker_order_detail_screen.dart';

class WorkerOrdersScreen extends StatefulWidget {
  const WorkerOrdersScreen({super.key});

  @override
  State<WorkerOrdersScreen> createState() => _WorkerOrdersScreenState();
}

class _WorkerOrdersScreenState extends State<WorkerOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const Color brand = Color(0xFFCCFD04);

  late TabController _tabController;

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

  /// Formats a Firestore Timestamp into a human-readable relative string.
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return DateFormat('MMM dd').format(dt);
    }
    return '';
  }

  /// Extracts image URLs from the order document (matches worker_home_screen logic).
  List<String> _extractImageUrls(Map<String, dynamic> data) {
    final raw = data['imageUrls'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        backgroundColor: brand,
        title: const Text(
          "My Orders",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          tabs: const [
            Tab(text: "Booked Orders"),
            Tab(text: "History"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _bookedOrdersView(),
          _historyOrdersView(),
        ],
      ),
    );
  }

  // ================= BOOKED ORDERS (accepted / on_my_way / arrived) =================
  // Query: workerId == uid only (no composite index required).
  // Status filtering and sorting are done locally in Dart.
  static const _activeStatuses = {'accepted', 'on_my_way', 'arrived'};

  Widget _bookedOrdersView() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text("Not logged in"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('workerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        // Filter locally: keep only active statuses, sort by createdAt desc
        final docs = (snapshot.data?.docs ?? [])
            .where((d) {
              final data = d.data() as Map<String, dynamic>;
              return _activeStatuses.contains(data['status']);
            })
            .toList()
          ..sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
            final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return (bTs as Timestamp).compareTo(aTs as Timestamp);
          });
        if (docs.isEmpty) {
          return const Center(child: Text("No active booked orders"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _activeOrderCard(doc.id, data);
          },
        );
      },
    );
  }

  // ================= HISTORY (completed / cancelled) =================
  // Query: workerId == uid only (no composite index required).
  // Status filtering and sorting are done locally in Dart.
  static const _historyStatuses = {'completed', 'cancelled'};

  Widget _historyOrdersView() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text("Not logged in"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('workerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        // Filter locally: keep only history statuses, sort by createdAt desc
        final docs = (snapshot.data?.docs ?? [])
            .where((d) {
              final data = d.data() as Map<String, dynamic>;
              return _historyStatuses.contains(data['status']);
            })
            .toList()
          ..sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
            final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return (bTs as Timestamp).compareTo(aTs as Timestamp);
          });
        if (docs.isEmpty) {
          return const Center(child: Text("No history available"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _historyOrderCard(data);
          },
        );
      },
    );
  }

  // ================= ACTIVE ORDER CARD (tappable – opens WorkerOrderDetailScreen) =================
  Widget _activeOrderCard(String orderId, Map<String, dynamic> data) {
    final name = data['customerName'] as String? ?? 'Customer';
    final service = data['serviceType'] as String? ?? 'Service';
    final area = data['address'] as String? ?? 'No address';
    final status = data['status'] as String? ?? 'accepted';

    void openDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerOrderDetailScreen(
            orderId: orderId,
            customerName: name,
            customerId: data['customerId'] as String? ?? '',
            serviceType: service,
            area: area,
            problemDetails: data['details'] as String?,
            createdAt: _formatTimestamp(data['createdAt']),
            imageUrls: _extractImageUrls(data),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: openDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: brand,
              child: Text(name.isNotEmpty ? name[0] : '?'),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("Service: $service"),
                  Text("Area: $area"),
                ],
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _statusColor(status),
                foregroundColor: Colors.white,
              ),
              onPressed: openDetail,
              child: Text(_statusLabel(status)),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HISTORY ORDER CARD (read-only) =================
  Widget _historyOrderCard(Map<String, dynamic> data) {
    final name = data['customerName'] as String? ?? 'Customer';
    final service = data['serviceType'] as String? ?? 'Service';
    final area = data['address'] as String? ?? 'No address';
    final status = data['status'] as String? ?? 'completed';
    final isCompleted = status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: brand,
            child: Text(name.isNotEmpty ? name[0] : '?'),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Service: $service"),
                Text("Area: $area"),
              ],
            ),
          ),

          Icon(
            isCompleted ? Icons.check_circle : Icons.cancel,
            color: isCompleted ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================
  Color _statusColor(String status) {
    switch (status) {
      case 'on_my_way':
        return Colors.indigo;
      case 'arrived':
        return Colors.green;
      default:
        return Colors.orange; // accepted
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'on_my_way':
        return 'On My Way';
      case 'arrived':
        return 'Arrived';
      default:
        return 'Open'; // accepted
    }
  }
}
