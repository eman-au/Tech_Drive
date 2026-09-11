import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'worker_home_screen.dart';
import 'worker_earnings_screen.dart';
import 'work_summary_screen.dart';

class TrackingOrderScreen extends StatefulWidget {
  final String orderId;
  const TrackingOrderScreen({super.key, required this.orderId});

  @override
  State<TrackingOrderScreen> createState() => _TrackingOrderScreenState();
}

class _TrackingOrderScreenState extends State<TrackingOrderScreen> {
  static const Color brand = Color(0xFFCCFD04);

  // Store current locations
  LatLng? _workerLocation;
  LatLng? _customerLocation;

  StreamSubscription<Position>? locationStream;
  final MapController _mapController = MapController();
  bool _mapInitialized = false;

  // ===== ROUTE DATA =====
  List<LatLng> routePoints = [];
  double distanceKm = 0.0;
  double durationMin = 0.0;

  // ===== ROUTE CALL CONTROL =====
  double? _lastWorkerLat;
  double? _lastWorkerLng;
  bool _isFetchingRoute = false;
  bool _isUpdatingLocation = false;

  int step = 0;

  // ================= UPDATE WORKER LOCATION TO FIRESTORE =================
  Future<void> _updateWorkerLocationToFirestore(double lat, double lng) async {
    if (_isUpdatingLocation) return;

    try {
      _isUpdatingLocation = true;
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'workerLat': lat,
        'workerLng': lng,
        'workerLocationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating worker location: $e");
    } finally {
      _isUpdatingLocation = false;
    }
  }

  // ================= INITIALIZE WORKER LOCATION =================
  Future<void> _initializeWorkerLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _notifyLocationUnavailable("Location services are disabled. Please enable GPS on your device.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _notifyLocationUnavailable("Location permission denied. Please grant location access.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _notifyLocationUnavailable("Location permission permanently denied. Enable it in device settings.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      setState(() {
        _workerLocation = LatLng(position.latitude, position.longitude);
      });

      await _updateWorkerLocationToFirestore(position.latitude, position.longitude);
      _startLocationUpdates();
      _fetchRouteIfNeeded();

    } catch (e) {
      debugPrint("Location initialization error: $e");
      _notifyLocationUnavailable("Could not fetch current location.");
    }
  }

  void _notifyLocationUnavailable(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ================= START LOCATION UPDATES =================
  void _startLocationUpdates() {
    locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _workerLocation = LatLng(position.latitude, position.longitude);
      });

      _updateWorkerLocationToFirestore(position.latitude, position.longitude);
      _fetchRouteIfNeeded();
    }, onError: (e) {
      debugPrint("Location stream error: $e");
    });
  }

  // ================= FETCH ROUTE =================
  void _fetchRouteIfNeeded() {
    if (_workerLocation == null || _customerLocation == null || _isFetchingRoute) return;

    final workerLat = _workerLocation!.latitude;
    final workerLng = _workerLocation!.longitude;
    final customerLat = _customerLocation!.latitude;
    final customerLng = _customerLocation!.longitude;

    if (_lastWorkerLat == null ||
        _lastWorkerLng == null ||
        (_lastWorkerLat! - workerLat).abs() > 0.0005 ||
        (_lastWorkerLng! - workerLng).abs() > 0.0005) {

      _lastWorkerLat = workerLat;
      _lastWorkerLng = workerLng;
      _fetchRoute(workerLat, workerLng, customerLat, customerLng);
    }
  }

  Future<void> _fetchRoute(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      ) async {
    if (_isFetchingRoute) return;

    try {
      _isFetchingRoute = true;

      final url = "https://router.project-osrm.org/route/v1/driving/"
          "$startLng,$startLat;$endLng,$endLat"
          "?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final meters = data['routes'][0]['distance'] ?? 0;
          final seconds = data['routes'][0]['duration'] ?? 0;

          if (!mounted) return;

          setState(() {
            routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
            distanceKm = meters / 1000;
            durationMin = seconds / 60;
          });
        }
      }
    } catch (e) {
      debugPrint("Route fetch error: $e");
      _calculateStraightLineDistance();
    } finally {
      _isFetchingRoute = false;
    }
  }

  void _calculateStraightLineDistance() {
    if (_workerLocation == null || _customerLocation == null) return;

    final meters = Geolocator.distanceBetween(
      _workerLocation!.latitude,
      _workerLocation!.longitude,
      _customerLocation!.latitude,
      _customerLocation!.longitude,
    );

    setState(() {
      distanceKm = meters / 1000;
      durationMin = (distanceKm / 35 * 60);
      routePoints = [_workerLocation!, _customerLocation!];
    });
  }

  // ================= GO TO CURRENT LOCATION =================
  Future<void> _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLat = position.latitude;
      final currentLng = position.longitude;

      _mapController.move(
        LatLng(currentLat, currentLng),
        14,
      );

      setState(() {
        _workerLocation = LatLng(currentLat, currentLng);
      });

      await _updateWorkerLocationToFirestore(currentLat, currentLng);
      _fetchRouteIfNeeded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moved to your current location'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("Current location error: $e");
    }
  }

  void onMainPressed() {
    if (step < 2) {
      setState(() => step++);

      if (step == 1) {
        _updateOrderStatus('arrived');
      } else if (step == 2) {
        _updateOrderStatus('completed');
      }
    }
  }

  Future<void> _updateOrderStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  void goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
          (route) => false,
    );
  }

  void goEarnings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkerEarningsScreen()),
    );
  }

  void goSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkSummaryScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeWorkerLocation();
  }

  @override
  void dispose() {
    locationStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: brand,
        title: const Text("Tracking Order", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Get customer location from Firestore
          final double? customerLat = data['customerLat']?.toDouble();
          final double? customerLng = data['customerLng']?.toDouble();

          if (customerLat != null && customerLng != null) {
            if (_customerLocation == null ||
                (_customerLocation!.latitude - customerLat).abs() > 0.00001 ||
                (_customerLocation!.longitude - customerLng).abs() > 0.00001) {
              setState(() {
                _customerLocation = LatLng(customerLat, customerLng);
              });
              _fetchRouteIfNeeded();
            }
          }

          // Show loading while getting customer location
          if (_customerLocation == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Waiting for customer location..."),
                ],
              ),
            );
          }

          final center = _workerLocation ?? _customerLocation!;

          // Center map only once
          if (!_mapInitialized && _workerLocation != null) {
            _mapInitialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(center, 14);
            });
          }

          return Column(
            children: [
              // 🗺 OSM MAP
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.example.tech_drive',
                        ),
                        if (routePoints.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                strokeWidth: 4,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            if (_workerLocation != null)
                              Marker(
                                point: _workerLocation!,
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.blue,
                                  size: 42,
                                ),
                              ),
                            Marker(
                              point: _customerLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.home,
                                color: Colors.green,
                                size: 34,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FloatingActionButton.small(
                        onPressed: _goToCurrentLocation,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                    if (_isFetchingRoute)
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 📏 DISTANCE + ETA
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      "📏 ${distanceKm.toStringAsFixed(2)} km",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "⏱️ ${durationMin.toStringAsFixed(1)} min",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // LOCATION INFO
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _workerLocation != null
                                ? "Your location: ${_workerLocation!.latitude.toStringAsFixed(4)}, ${_workerLocation!.longitude.toStringAsFixed(4)}"
                                : "Getting your location...",
                            style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.home, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Customer location: ${_customerLocation!.latitude.toStringAsFixed(4)}, ${_customerLocation!.longitude.toStringAsFixed(4)}",
                            style: TextStyle(fontSize: 12, color: Colors.green[800]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                step == 0
                    ? "Navigate to customer location"
                    : step == 1
                    ? "Work in progress..."
                    : "Work completed successfully ✅",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const Spacer(),

              if (step <= 1)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: step == 0 ? Colors.orange : Colors.blue,
                      ),
                      onPressed: onMainPressed,
                      child: Text(
                        step == 0 ? "Arrived at customer location" : "Start Work",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              if (step == 2)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _optionBtn("Go to Homepage", Colors.green, goHome),
                      const SizedBox(height: 10),
                      _optionBtn("Work Summary", Colors.blue, goSummary),
                      const SizedBox(height: 10),
                      _optionBtn("Earnings", brand, goEarnings),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _optionBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}