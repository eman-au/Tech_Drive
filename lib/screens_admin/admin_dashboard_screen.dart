import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_login_screen.dart';
import 'admin_worker_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color brand = Color(0xFFCCFD04);

  bool _loading = true;

  int totalCustomers = 0;
  int totalWorkers = 0;
  int approvedWorkers = 0;
  int pendingRequests = 0;
  int activeOrders = 0;
  int completedOrders = 0;
  int cancelledOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ================= LOAD DASHBOARD DATA =================
  Future<void> _loadDashboard() async {
    setState(() => _loading = true);

    try {
      // 1. Fetch all users — filter locally
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();

      int customers = 0;
      int workers = 0;
      int approved = 0;

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final userType = data['userType'] as String? ?? 'customer';

        if (userType == 'worker') {
          workers++;
          final status = data['workerStatus'] as String? ?? '';
          if (status == 'approved') approved++;
        } else {
          customers++;
        }
      }

      // 2. Fetch pending worker requests — single-field query
      final pendingSnap = await FirebaseFirestore.instance
          .collection('worker_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      // 3. Fetch all orders — filter locally
      final ordersSnap =
          await FirebaseFirestore.instance.collection('orders').get();

      int active = 0;
      int completed = 0;
      int cancelled = 0;

      const activeStatuses = {
        'pending',
        'accepted',
        'on_my_way',
        'arrived',
        'Pending',
        'Accepted',
        'On my way',
        'Arrived',
      };
      const completedStatuses = {'completed', 'Completed'};
      const cancelledStatuses = {'cancelled', 'Cancelled'};

      for (final doc in ordersSnap.docs) {
        final status =
            (doc.data())['status'] as String? ?? '';
        if (activeStatuses.contains(status)) {
          active++;
        } else if (completedStatuses.contains(status)) {
          completed++;
        } else if (cancelledStatuses.contains(status)) {
          cancelled++;
        }
      }

      if (mounted) {
        setState(() {
          totalCustomers = customers;
          totalWorkers = workers;
          approvedWorkers = approved;
          pendingRequests = pendingSnap.docs.length;
          activeOrders = active;
          completedOrders = completed;
          cancelledOrders = cancelled;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: brand,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              color: Colors.black,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Users Section ----
                    const Text(
                      "Users",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "Customers",
                            totalCustomers,
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            "Workers",
                            totalWorkers,
                            Icons.engineering,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "Approved",
                            approvedWorkers,
                            Icons.verified,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _tappableStatCard(
                            "Pending",
                            pendingRequests,
                            Icons.hourglass_top,
                            Colors.amber.shade700,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminWorkerListScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ---- Orders Section ----
                    const Text(
                      "Orders",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "Active",
                            activeOrders,
                            Icons.play_circle_outline,
                            Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            "Completed",
                            completedOrders,
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _statCard(
                      "Cancelled",
                      cancelledOrders,
                      Icons.cancel_outlined,
                      Colors.red,
                    ),

                    const SizedBox(height: 28),

                    // ---- Quick Actions ----
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminWorkerListScreen(),
                            ),
                          );
                        },
                        icon:
                            const Icon(Icons.assignment, color: Colors.black),
                        label: const Text(
                          "View Pending Applications",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brand,
                          elevation: 4,
                          shadowColor: brand.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ================= STAT CARD =================
  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAPPABLE STAT CARD =================
  Widget _tappableStatCard(
    String label,
    int count,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
