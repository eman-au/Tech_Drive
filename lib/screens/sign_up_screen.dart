import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'phone_number_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _phoneC = TextEditingController();
  final TextEditingController _passC = TextEditingController();
  final TextEditingController _confirmC = TextEditingController();

  bool passVisible = false;
  bool confirmVisible = false;
  bool isLoading = false; // Added loading state
  String strength = "";

  void checkStrength(String pass) {
    final upper = RegExp(r'[A-Z]').hasMatch(pass);
    final lower = RegExp(r'[a-z]').hasMatch(pass);
    final number = RegExp(r'[0-9]').hasMatch(pass);
    final symbol = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pass);

    if (pass.length >= 8 && upper && lower && number && symbol) {
      strength = "Strong";
    } else if (pass.length >= 6 && (upper || lower) && (number || symbol)) {
      strength = "Medium";
    } else if (pass.isNotEmpty) {
      strength = "Weak";
    } else {
      strength = "";
    }
    setState(() {});
  }

  Color strengthColor() {
    switch (strength) {
      case "Strong":
        return Colors.green;
      case "Medium":
        return Colors.orange;
      case "Weak":
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_phoneC.text.startsWith("+")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone must start with +92"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if passwords match
    if (_passC.text != _confirmC.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailC.text.trim(),
        password: _passC.text.trim(),
      );

      await cred.user!.sendEmailVerification();

      await _firestore.collection("users").doc(cred.user!.uid).set({
        "uid": cred.user!.uid,
        "name": _nameC.text.trim(),
        "email": _emailC.text.trim(),
        "phone": _phoneC.text.trim(),
        "emailVerified": false,
        "phoneVerified": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // SUCCESS - Show custom message dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Registration Successful 🎉"),
          content: const Text(
            "Please check your email for verification.\nThen verify your phone number.",
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhoneNumberScreen(
                      phoneNumber: _phoneC.text.trim(),
                      isReset: false,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      // CUSTOM ERROR MESSAGES - Firebase ke raw errors nahi dikhenge
      String errorMessage = "Registration failed";

      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address";
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = "Email/password accounts are not enabled";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak. Use at least 6 characters";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Too many attempts. Try again later";
      } else if (e.code == 'network-request-failed') {
        errorMessage = "Network error. Check your internet connection";
      }

      // Show custom error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Generic error message for any other errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration failed. Please try again"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFCCFD04);

    InputDecoration deco(String hint, IconData icon) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.grey),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: brand,
            width: 2,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 35),

                Container(
                  height: 125,
                  width: 125,
                  decoration: BoxDecoration(
                    color: brand,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: brand.withOpacity(0.5),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/logo2.png',
                        height: 65,
                        width: 65,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Create Your Account",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Register to start using Tech Drive",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _nameC,
                  decoration: deco("Full Name", Icons.person),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Name required" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _emailC,
                  decoration: deco("Email", Icons.email),
                  validator: (v) =>
                  v == null || !v.contains("@")
                      ? "Valid email required" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _phoneC,
                  decoration: deco("Phone (+92xxxxx)", Icons.phone),
                  validator: (v) =>
                  v == null || v.length < 10
                      ? "Valid phone required" : null,
                ),
                const SizedBox(height: 15),

                // Password Field
                TextFormField(
                  controller: _passC,
                  obscureText: !passVisible,
                  decoration: deco("Password", Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        passVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => passVisible = !passVisible),
                    ),
                  ),
                  onChanged: checkStrength,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Password required";
                    }
                    if (v.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    strength.isEmpty
                        ? ""
                        : "Password Strength: $strength",
                    style: TextStyle(color: strengthColor()),
                  ),
                ),

                const SizedBox(height: 10),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmC,
                  obscureText: !confirmVisible,
                  decoration:
                  deco("Confirm Password", Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        confirmVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => confirmVisible = !confirmVisible),
                    ),
                  ),
                  validator: (v) =>
                  v != _passC.text ? "Passwords do not match" : null,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Color(0xFF953535),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}