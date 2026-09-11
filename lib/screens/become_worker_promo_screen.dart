import 'package:flutter/material.dart';
import 'package:tech_drive/screens_for_workers/worker_registration_screen.dart';
// ✅ Add this import
// ✅ Add this import

class BecomeWorkerPromoScreen extends StatelessWidget {
  const BecomeWorkerPromoScreen({super.key});

  static const Color brand = Color(0xFFCCFD04);

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: Stack(
        children: [
          /// 🔥 TOP HALF IMAGE
          Container(
            height: h * 0.5,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/worker1.png"),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          /// DARK OVERLAY
          Container(
            height: h * 0.5,
            color: Colors.black.withOpacity(0.15),
          ),

          /// CONTENT
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: h * 0.38),

                /// WHITE CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xfff5f7fb),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "BECOME A WORKER WITH US?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// 🔽 POINTS
                      _point(
                        icon: Icons.trending_up,
                        title: "Increased Job Opportunities",
                        desc:
                        "Expand your client base and enjoy flexible working hours.",
                      ),
                      _point(
                        icon: Icons.verified,
                        title: "Enhanced Professional Reputation",
                        desc:
                        "Build credibility through user reviews and showcase your skills.",
                      ),
                      _point(
                        icon: Icons.security,
                        title: "Convenient Business Management",
                        desc:
                        "Enjoy secure payments with direct earnings to your account.",
                      ),

                      const SizedBox(height: 20),

                      /// 👉 REGISTER BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const WorkerRegistrationScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Register Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Need Help?",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// BACK BUTTON
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 POINT TILE
  static Widget _point({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: brand, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}