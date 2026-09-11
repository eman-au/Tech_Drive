import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_screen.dart';
import '../services/auth_service.dart';

class PhoneNumberScreen extends StatefulWidget {
final String? phoneNumber;
final bool isReset;

const PhoneNumberScreen({
super.key,
this.phoneNumber,
this.isReset = false,
});

@override
State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
late TextEditingController phoneC;
final AuthService auth = AuthService();
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
bool loading = false;
String? _errorMessage;

@override
void initState() {
super.initState();
phoneC = TextEditingController(text: widget.phoneNumber ?? "");
}

Future<void> startVerification() async {
final phone = phoneC.text.trim();

if (phone.isEmpty) {
_showError("Please enter phone number");
return;
}

if (!phone.startsWith("+")) {
_showError("Use +92 format e.g. +92312xxxxxxx");
return;
}

setState(() {
loading = true;
_errorMessage = null;
});

try {
// Check if phone is registered
final userData = await _checkPhoneRegistration(phone);

if (userData == null) {
_showError("This phone number is not registered");
return;
}

// Proceed with verification
await auth.verifyPhone(
phoneNumber: phone,
codeSent: (id) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => OtpScreen(
verificationId: id,
phoneNumber: phone,
isReset: widget.isReset,
),
),
);
},
onFailed: (e) {
String errorMsg = e.message ?? "Verification failed";

if (e.code == 'unregistered-phone') {
errorMsg = "This phone number is not registered";
} else if (e.code == 'invalid-phone-number') {
errorMsg = "Invalid phone number format";
} else if (e.code == 'quota-exceeded') {
errorMsg = "Too many attempts. Try again later";
}

_showError(errorMsg);
},
);
} catch (e) {
_showError("Something went wrong: $e");
} finally {
setState(() => loading = false);
}
}

// ✅ Return user data instead of just boolean
Future<DocumentSnapshot?> _checkPhoneRegistration(String phone) async {
try {
final query = await _firestore
    .collection('users')
    .where('phone', isEqualTo: phone)
    .limit(1)
    .get();

if (query.docs.isNotEmpty) {
return query.docs.first;
}
return null;
} catch (e) {
return null;
}
}

void _showError(String message) {
setState(() {
_errorMessage = message;
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor: Colors.red,
),
);
}

@override
Widget build(BuildContext context) {
const brand = Color(0xFFCCFD04);

return Scaffold(
backgroundColor: const Color(0xFFF8F9FB),
appBar: AppBar(
backgroundColor: brand,
elevation: 0,
leading: IconButton(
icon: const Icon(Icons.close, color: Colors.black),
onPressed: () => Navigator.pop(context),
),
),
body: Padding(
padding: const EdgeInsets.all(24),
child: Column(
children: [
const SizedBox(height: 35),

Container(
height: 90,
width: 90,
decoration: BoxDecoration(
color: brand,
borderRadius: BorderRadius.circular(45),
),
child: const Icon(
Icons.phone_android,
size: 40,
color: Colors.black,
),
),

const SizedBox(height: 24),

Text(
widget.isReset ? "Reset via Phone" : "Login with Phone",
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 6),

const Text(
"Enter your registered phone number",
style: TextStyle(color: Colors.grey),
),

const SizedBox(height: 30),

// Error Message
if (_errorMessage != null)
Container(
padding: const EdgeInsets.all(12),
margin: const EdgeInsets.only(bottom: 10),
decoration: BoxDecoration(
color: Colors.red.shade100,
borderRadius: BorderRadius.circular(12),
border: Border.all(color: Colors.red),
),
child: Row(
children: [
const Icon(Icons.error, color: Colors.red, size: 20),
const SizedBox(width: 10),
Expanded(
child: Text(
_errorMessage!,
style: const TextStyle(color: Colors.red),
),
),
],
),
),

TextField(
controller: phoneC,
keyboardType: TextInputType.phone,
decoration: InputDecoration(
hintText: "+92xxxxxxxxx",
filled: true,
fillColor: Colors.white,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
prefixIcon: const Icon(Icons.phone),
),
),

const SizedBox(height: 10),
const Text(
"Only registered phone numbers can login",
style: TextStyle(fontSize: 12, color: Colors.grey),
),

const SizedBox(height: 30),

SizedBox(
width: double.infinity,
height: 48,
child: ElevatedButton(
onPressed: loading ? null : startVerification,
style: ElevatedButton.styleFrom(backgroundColor: brand),
child: loading
? const CircularProgressIndicator(color: Colors.black)
    : const Text(
"Send Verification Code",
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