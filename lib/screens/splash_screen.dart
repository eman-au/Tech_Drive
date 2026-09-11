import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:tech_drive/screens_for_workers/worker_home_screen.dart';
import 'package:tech_drive/screens_for_workers/waiting_approval_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 800), () async {
      final user = _auth.currentUser;

      if (user != null) {
        Map<String, dynamic>? userData = await _auth.getUserData();
        bool isWorkerUser = userData?['userType'] == 'worker';
        String? workerStatus = userData?['workerStatus'];

        if (mounted) {
          if (isWorkerUser) {
            if (workerStatus == 'approved') {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkerHomeScreen())
              );
            } else {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WaitingApprovalScreen())
              );
            }
          } else {
            // Customer - go to customer home screen
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen())
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen())
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }
}