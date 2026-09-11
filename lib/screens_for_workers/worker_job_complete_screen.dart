import 'package:flutter/material.dart';
import 'package:tech_drive/screens/complain.dart';

class WorkerJobCompleteScreen extends StatelessWidget {
  final int earning;
  final String orderId;
  final String customerId;
  final String customerName;

  const WorkerJobCompleteScreen({
    super.key,
    required this.earning,
    required this.orderId,
    required this.customerId,
    required this.customerName,
  });

  static const Color brand = Color(0xFFCCFD04);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: brand,
        title: const Text("Job Completed", style: TextStyle(color: Colors.black)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text("Job Done Successfully!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Text("You earned Rs $earning",
                  style: const TextStyle(
                      fontSize: 18, color: Colors.green, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Text("Customer will rate you shortly",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Home"),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.report_problem, color: Colors.red),
                  label: const Text("File a Complaint",
                      style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintScreen(
                          orderId: orderId,
                          otherUserId: customerId,
                          otherUserName: customerName,
                          complaintBy: 'worker',
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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