import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'avaliable_offers_screen.dart';
import 'request_accepted_screen.dart';

class FindingWorkerScreen extends StatefulWidget {
  final String orderId;
  final String serviceType;

  const FindingWorkerScreen({
    super.key,
    required this.orderId,
    required this.serviceType,
  });

  @override
  State<FindingWorkerScreen> createState() => _FindingWorkerScreenState();
}

class _FindingWorkerScreenState extends State<FindingWorkerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController anim;
  final brand = const Color(0xFFCCFD04);
  StreamSubscription? _orderSub;
  StreamSubscription? _offersSub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _checkInitialStateAndListen();

    // After 15 seconds, if status is still pending/searching, navigate to AvailableOffersScreen
    _timer = Timer(const Duration(seconds: 15), () {
      _goToAvailableOffers();
    });
  }

  Future<void> _checkInitialStateAndListen() async {
    try {
      // 1. One-time check for already accepted status
      final orderSnap = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!mounted) return;

      if (orderSnap.exists) {
        final data = orderSnap.data() as Map<String, dynamic>;
        final status = data['status'];
        if (status == 'accepted' || status == 'assigned') {
          _cancelListeners();
          _navigateToRequestAccepted(data);
          return;
        }
      }

      // 2. One-time check for already existing offers
      final offersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .collection('offers')
          .get();

      if (!mounted) return;

      if (offersSnap.docs.isNotEmpty) {
        _cancelListeners();
        _navigateToAvailableOffers();
        return;
      }

      // 3. Fallback: Register real-time listeners for changes
      _listenToOrderAndOffers();
    } catch (e) {
      if (mounted) {
        _listenToOrderAndOffers();
      }
    }
  }

  void _listenToOrderAndOffers() {
    // 1. Listen to parent order for status updates
    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'];
        if (status == 'accepted' || status == 'assigned') {
          _cancelListeners();
          _navigateToRequestAccepted(data);
        }
      }
    });

    // 2. Listen to offers subcollection
    _offersSub = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('offers')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        _cancelListeners();
        _navigateToAvailableOffers();
      }
    });
  }

  void _navigateToRequestAccepted(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final workerName = data['workerName'] ?? 'Worker';
        final workerId = data['workerId'] ?? '';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RequestAcceptedScreen(
              worker: {
                "name": workerName,
                "rate": data['quotedPrice'] != null ? "Rs. ${data['quotedPrice']}" : "Rate TBD",
                "time": data['quotedEta'] ?? "ETA TBD",
                "image": data['workerImage'] ?? "assets/images/plumber1.jpg",
                "uid": workerId,
              },
              orderId: widget.orderId,
            ),
          ),
        );
      }
    });
  }

  void _navigateToAvailableOffers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AvailableOffersScreen(
              orderId: widget.orderId,
              serviceType: widget.serviceType,
            ),
          ),
        );
      }
    });
  }

  void _goToAvailableOffers() {
    _cancelListeners();
    _navigateToAvailableOffers();
  }

  void _cancelListeners() {
    _orderSub?.cancel();
    _offersSub?.cancel();
    _timer?.cancel();
  }

  @override
  void dispose() {
    anim.dispose();
    _cancelListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: brand,
        title: const Text(
          "Finding Worker...",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: anim,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: brand.withOpacity(.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search,
                    size: 60, color: Colors.black),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Searching best workers nearby...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text("Please wait a moment"),
          ],
        ),
      ),
    );
  }
}