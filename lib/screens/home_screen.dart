import 'package:flutter/material.dart';
import 'package:tech_drive/screens/customer_menu_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';

import 'orders_screen.dart';
import 'notifications_screen.dart';
import 'place_order_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeBody(),
    const OrdersScreen(),
    const NotificationsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final Color brandColor = const Color(0xFFCCFD04);

  final double _homeAppBarHeight = 130;
  final double _homeAppBarPadding = 22;

  final double _orderAppBarHeight = 120;
  final double _orderAppBarPadding = 22;
  final double _orderCornerRadius = 36;

  final double _appBarFontSize = 20;

  String userName = "";

  @override
  void initState() {
    super.initState();
    fetchUserName();
    saveUserCurrentAddress();
  }

  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    NotificationService.startListening(user.uid);

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      setState(() {
        userName = user.displayName!;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        userName = doc['name'] ?? "";
      });
    }
  }

  Future<void> saveUserCurrentAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return;

      final place = placemarks.first;

      final address =
          "${place.street}, ${place.locality}, ${place.administrativeArea}";

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "address": address,
        "lat": position.latitude,
        "lng": position.longitude,
      });
    } catch (e) {
      debugPrint("Location save error: $e");
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return userName.isEmpty ? "Welcome" : "Welcome, $userName!";
      case 1:
        return "Orders";
      case 2:
        return "Notifications";
      default:
        return "";
    }
  }

  bool get _isHome => _selectedIndex == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomerMenuDrawer(),
      backgroundColor: Colors.grey[100],

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          _isHome ? _homeAppBarHeight : _orderAppBarHeight,
        ),
        child: _isHome
            ? _buildHomeAppBar()
            : _buildOrdersNotificationAppBar(),
      ),

      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
          BottomNavigationBarItem(
            icon: _buildNotificationIcon(),
            label: "Notifications",
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Icon(Icons.notifications_none);
    }

    return StreamBuilder<int>(
      stream: NotificationService.getUnreadCountStream(uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
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

  // ================= HOME APPBAR =================
  Widget _buildHomeAppBar() {
    return SizedBox(
      height: _homeAppBarHeight,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [brandColor.withOpacity(0.9), brandColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: _homeAppBarPadding,
            ),
            child: Row(
              children: [
                _menuButton(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _getAppBarTitle(),
                    style: GoogleFonts.poppins(
                      fontSize: _appBarFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                // ✅ REMOVED the Worker button from here
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= ORDERS / NOTIFICATIONS APPBAR =================
  Widget _buildOrdersNotificationAppBar() {
    return SizedBox(
      height: _orderAppBarHeight,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: brandColor,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(_orderCornerRadius),
            bottomRight: Radius.circular(_orderCornerRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: _orderAppBarPadding,
            ),
            child: Row(
              children: [
                _menuButton(),
                const SizedBox(width: 16),
                Expanded(
                  child: Center(
                    child: Text(
                      _getAppBarTitle(),
                      style: GoogleFonts.poppins(
                        fontSize: _appBarFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton() {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          iconSize: 28,
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }
}

// ================= HOME BODY =================
class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Services",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          _serviceCard(
            context: context,
            icon: Icons.plumbing,
            title: "Plumber",
            subtitle: "Leaks, installations, and repairs",
          ),
          const SizedBox(height: 18),
          _serviceCard(
            context: context,
            icon: Icons.flash_on,
            title: "Electrician",
            subtitle: "Wiring outlets and electrical safety",
          ),
        ],
      ),
    );
  }

  Widget _serviceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceOrderScreen(serviceType: title),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Find a Pro →",
                    style: GoogleFonts.poppins(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}