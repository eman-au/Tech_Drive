import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passC = TextEditingController();
  final TextEditingController _confC = TextEditingController();
  bool loading = false;

  Future<void> updatePass() async {
    final pass = _passC.text.trim();
    final conf = _confC.text.trim();

    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kam az kam 6 characters ka password hona chahiye"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (pass != conf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords match nahi kar rahe"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(pass);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password successfully reset 👍"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Password change failed"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFCCFD04);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Text(
                'Set New Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: _passC,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'New password',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _confC,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirm new password',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : updatePass,
                  style: ElevatedButton.styleFrom(backgroundColor: brand),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                    'Update Password',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
