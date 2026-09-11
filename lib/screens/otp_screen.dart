import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:tech_drive/screens/home_screen.dart';
import 'package:tech_drive/screens_for_workers/worker_home_screen.dart'; // ✅ Add this import

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final bool isReset;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.isReset = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpC = TextEditingController();
  final AuthService auth = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool loading = false;

  int seconds = 30;
  late Timer timer;
  late String currentVerificationId;

  @override
  void initState() {
    super.initState();
    currentVerificationId = widget.verificationId;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (seconds > 0) {
          seconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> resendOtp() async {
    if (seconds != 0) return;

    setState(() {
      seconds = 30;
      startTimer();
    });

    await auth.verifyPhone(
      phoneNumber: widget.phoneNumber,
      codeSent: (id) {
        currentVerificationId = id;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("New OTP sent successfully"),
            backgroundColor: Colors.green,
          ),
        );
      },
      onFailed: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Failed to resend OTP"),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  // ✅ Helper function to check if user is worker
  Future<bool> _isUserWorker(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final userType = doc['userType'];
        return userType == 'worker';
      }
      return false;
    } catch (e) {
      print("Error checking user type: $e");
      return false;
    }
  }

  Future<void> verifyOtp() async {
    final sms = otpC.text.trim();

    if (sms.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter 6 digit code"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = await auth.signInWithSms(
        verificationId: currentVerificationId,
        smsCode: sms,
      );

      if (user != null) {
        // ✅ Check if user is a worker
        bool isWorker = await _isUserWorker(user.uid);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isWorker ? "Worker login successful! 🎉" : "Login successful! 🎉"),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          if (isWorker) {
            // Worker - go to worker home screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
                  (route) => false,
            );
          } else {
            // Customer - go to customer home screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid OTP. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Verification error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid OTP. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => loading = false);
  }

  @override
  void dispose() {
    timer.cancel();
    otpC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFCCFD04);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: brand,
        elevation: 0,
        title: const Text("OTP Verify", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            Text(
              "OTP sent to:\n${widget.phoneNumber}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: otpC,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "6 digit OTP",
                filled: true,
                fillColor: Colors.grey.shade100,
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              seconds > 0
                  ? "Resend in $seconds sec"
                  : "Resend available",
              style: TextStyle(
                color: seconds > 0 ? Colors.grey : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            TextButton(
              onPressed: seconds == 0 ? resendOtp : null,
              child: const Text(
                "Resend OTP",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : verifyOtp,
                style: ElevatedButton.styleFrom(backgroundColor: brand),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                  "Verify OTP",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}