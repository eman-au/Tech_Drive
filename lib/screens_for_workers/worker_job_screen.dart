import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../screens/chat_screen.dart';
import 'worker_job_complete_screen.dart'; // ✅ NEW

class WorkerJobScreen extends StatefulWidget {
  final String requestId;
  const WorkerJobScreen({super.key, required this.requestId});

  @override
  State<WorkerJobScreen> createState() => _WorkerJobScreenState();
}

class _WorkerJobScreenState extends State<WorkerJobScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  LatLng? workerLatLng;
  LatLng? customerLatLng;
  String? customerId;
  String? customerName;

  @override
  void initState() {
    super.initState();
    _startLiveLocationTracking();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.requestId)
        .get();
    setState(() {
      customerId = doc['customerId'];
      customerName = doc['customerName'] ?? 'Customer';
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLiveLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      final lat = position.latitude;
      final lng = position.longitude;

      workerLatLng = LatLng(lat, lng);

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.requestId)
          .update({
        "workerLat": lat,
        "workerLng": lng,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (workerLatLng != null) {
        _mapController.move(workerLatLng!, 15);
      }

      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Job In Progress"),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: _callCustomer),
          IconButton(icon: const Icon(Icons.chat), onPressed: _openChat),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final status = data['status'];

          final double customerLat = (data['customerLat'] ?? 0).toDouble();
          final double customerLng = (data['customerLng'] ?? 0).toDouble();

          if (customerLat == 0 || customerLng == 0) {
            return const Center(child: Text("Customer location not available"));
          }

          customerLatLng = LatLng(customerLat, customerLng);

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: customerLatLng!,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.tech_drive',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: customerLatLng!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                        if (workerLatLng != null)
                          Marker(
                            point: workerLatLng!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.directions_car, color: Colors.blue, size: 36),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (status == 'accepted')
                      _actionBtn("I'm on the way", Colors.orange, () async {
                        await _updateStatus('on_my_way');
                        if (customerId != null) {
                          await NotificationService.sendNotification(
                            recipientUid: customerId!,
                            title: "Worker Aa Raha Hai! 🚗",
                            body: "Aapka worker raaste mein hai!",
                            data: {"orderId": widget.requestId},
                          );
                        }
                      }),

                    if (status == 'on_my_way')
                      _actionBtn("Arrived", Colors.blue, () async {
                        await _updateStatus('arrived');
                        if (customerId != null) {
                          await NotificationService.sendNotification(
                            recipientUid: customerId!,
                            title: "Worker Pohonch Gaya! 📍",
                            body: "Aapka worker aapke paas aa gaya hai!",
                            data: {"orderId": widget.requestId},
                          );
                        }
                      }),

                    if (status == 'arrived')
                      _actionBtn("Job Done", Colors.green, () async {
                        await _updateStatus('completed');
                        if (customerId != null) {
                          await NotificationService.sendNotification(
                            recipientUid: customerId!,
                            title: "Kaam Mukammal! 🎉",
                            body: "Aapki service complete ho gayi hai!",
                            data: {"orderId": widget.requestId},
                          );
                        }
                        if (mounted) {
                          Navigator.pushReplacement( // ✅ UPDATED
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkerJobCompleteScreen(
                                earning: 1300,
                                orderId: widget.requestId,
                                customerId: customerId!,
                                customerName: customerName ?? 'Customer',
                              ),
                            ),
                          );
                        }
                      }),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.requestId)
        .update({
      'status': status,
      '${status}At': FieldValue.serverTimestamp(),
    });
  }

  void _callCustomer() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.requestId)
          .get();

      final rawPhone = doc.data()?['customerPhone'] as String? ?? '';
      final phone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

      if (phone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer phone number is unavailable or invalid.')),
          );
        }
        return;
      }

      final uri = Uri.parse('tel:$phone');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to make call to $phone')),
          );
        }
      }
    } catch (e) {
      debugPrint("Call error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate phone call: $e')),
        );
      }
    }
  }

  void _openChat() {
    if (customerId == null) return;

    final user = FirebaseAuth.instance.currentUser;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          orderId: widget.requestId,
          workerId: user!.uid,
          customerId: customerId!,
          workerName: user.displayName ?? user.email?.split('@').first ?? 'Worker',
          customerName: customerName ?? 'Customer',
        ),
      ),
    );
  }

  Widget _actionBtn(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }
}