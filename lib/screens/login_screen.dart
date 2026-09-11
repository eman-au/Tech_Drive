import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ NEW

import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';
import 'home_screen.dart';
import 'package:tech_drive/screens_for_workers/worker_home_screen.dart';
import 'package:tech_drive/screens_for_workers/waiting_approval_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;
  bool googleLoading = false;

  // ✅ NEW — FCM token save karne ka function
  Future<void> saveFcmToken(String uid) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      print("FCM token error: $e");
    }
  }

  Future<void> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> googleLogin() async {
    try {
      setState(() => googleLoading = true);

      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => googleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await _auth.signInWithCredential(credential);
      User? user = userCred.user;

      final displayName = user?.displayName ?? googleUser.displayName;
      final email = user?.email;
      final uid = user?.uid;
      final authPhone = user?.phoneNumber ?? "";

      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection("users").doc(uid).get();

      if (!doc.exists) {
        await firestore.collection("users").doc(uid).set({
          "uid": uid,
          "name": displayName,
          "email": email,
          "phone": authPhone,
          "userType": "customer",
          "emailVerified": true,
          "phoneVerified": false,
          "createdAt": FieldValue.serverTimestamp(),
        });
      } else {
        // If Firestore doc already exists: preserve non-empty phone number
        final existingPhone = (doc.data()?['phone'] as String?) ?? "";
        if (existingPhone.isEmpty && authPhone.isNotEmpty) {
          await firestore.collection("users").doc(uid).update({
            "phone": authPhone,
          });
        }
      }

      await saveFcmToken(uid!); // ✅ NEW
      NotificationService.startListening(uid);

      await requestLocationPermission();
      Map<String, dynamic>? userData = await _authService.getUserData();
      bool isWorkerUser = userData?['userType'] == 'worker';
      String? workerStatus = userData?['workerStatus'];

      if (mounted) {
        if (isWorkerUser) {
          if (workerStatus == 'approved') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WorkerHomeScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
          }
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google login failed"), backgroundColor: Colors.red),
      );
    }
    setState(() => googleLoading = false);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!userCred.user!.emailVerified) {
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please verify your email"), backgroundColor: Colors.orange),
        );
        setState(() => isLoading = false);
        return;
      }

      await saveFcmToken(userCred.user!.uid); // ✅ NEW
      NotificationService.startListening(userCred.user!.uid);

      await requestLocationPermission();
      Map<String, dynamic>? userData = await _authService.getUserData();
      bool isWorkerUser = userData?['userType'] == 'worker';
      String? workerStatus = userData?['workerStatus'];

      if (mounted) {
        if (isWorkerUser) {
          if (workerStatus == 'approved') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WorkerHomeScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
          }
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFFCCFD04);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 35),
                Container(
                  height: 125,
                  width: 125,
                  decoration: BoxDecoration(
                    color: brandColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: brandColor.withOpacity(0.5), blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset('assets/images/logo2.png', height: 65, width: 65, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("Sign in to continue to Tech Drive", style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 35),

                _inputField(controller: _emailController, hint: "Username or Email", icon: Icons.person_outline),
                const SizedBox(height: 18),

                _inputField(
                  controller: _passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  obscure: !isPasswordVisible,
                  suffix: IconButton(
                    icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF953535), fontWeight: FontWeight.w600)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgetPasswordScreen())),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      elevation: 8,
                      shadowColor: brandColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("Log In", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 28),
                const Text("or continue with"),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _socialButton(
                        label: "Google",
                        icon: googleLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : Image.asset("assets/images/google.png", width: 22),
                        onTap: googleLoading ? null : googleLogin,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                      child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}