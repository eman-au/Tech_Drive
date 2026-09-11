import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'become_worker_promo_screen.dart';
import '../screens_for_workers/worker_home_screen.dart';
import '../screens_for_workers/waiting_approval_screen.dart';

class CustomerMenuDrawer extends StatefulWidget {
  const CustomerMenuDrawer({super.key});

  @override
  State<CustomerMenuDrawer> createState() => _CustomerMenuDrawerState();
}

class _CustomerMenuDrawerState extends State<CustomerMenuDrawer> {
  final Color baseColor = const Color.fromARGB(255, 204, 253, 4);

  bool isWorkerMode = false;
  String? userType;
  String? workerStatus;

  @override
  void initState() {
    super.initState();
    _fetchUserType();
  }

  Future<void> _fetchUserType() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            userType = doc.data()?['userType'];
            workerStatus = doc.data()?['workerStatus'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user type: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tech Drive',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ================= MENU ITEMS =================
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context,
                      Icons.person_outline,
                      'My Profile',
                      routeName: '/profile',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.settings_outlined,
                      'Settings',
                      routeName: '/settings',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.contact_mail_outlined,
                      'Contact Us',
                      routeName: '/contact',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.help_outline,
                      'Help & Support',
                      routeName: '/support',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.logout,
                      'Logout',
                      isLogout: true,
                    ),
                  ],
                ),
              ),

              // ================= WORKER MODE BUTTON =================
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // close drawer

                    if (userType == 'worker') {
                      if (workerStatus == 'approved') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkerHomeScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WaitingApprovalScreen(),
                          ),
                        );
                      }
                    } else {
                      // ✅ Navigate to Become Worker Promo Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BecomeWorkerPromoScreen(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      (userType == 'worker')
                          ? 'Switch to Worker Mode'
                          : 'Become a Worker',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DRAWER ITEM =================
  Widget _buildDrawerItem(
      BuildContext context,
      IconData icon,
      String title, {
        bool isLogout = false,
        String? routeName,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: baseColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: isLogout ? Colors.red : baseColor),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isLogout ? Colors.red : Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.black38,
          ),
          onTap: () async {
            Navigator.pop(context);

            if (isLogout) {
              // ✅ FIREBASE LOGOUT
              await FirebaseAuth.instance.signOut();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                    (route) => false,
              );
            } else if (routeName != null) {
              Navigator.pushNamed(context, routeName);
            }
          },
        ),
      ),
    );
  }
}
