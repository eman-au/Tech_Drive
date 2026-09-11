// lib/screens/call_screen.dart
import 'package:flutter/material.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final String callType;
  final bool isCaller;
  final String otherUserName;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.callType,
    required this.isCaller,
    required this.otherUserName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.black],
              ),
            ),
          ),

          // Content
          Column(
            children: [
              const Spacer(),

              // User avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[800],
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                widget.otherUserName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                widget.isCaller ? 'Calling...' : 'Incoming call...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),

              const Spacer(),

              // Call controls
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mute button
                    _callButton(
                      icon: isMuted ? Icons.mic_off : Icons.mic,
                      onTap: () {
                        setState(() {
                          isMuted = !isMuted;
                        });
                      },
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 30),

                    // End call button
                    _callButton(
                      icon: Icons.call_end,
                      onTap: () => Navigator.pop(context),
                      color: Colors.red,
                      size: 70,
                      iconSize: 35,
                    ),
                    const SizedBox(width: 30),

                    // Speaker button
                    _callButton(
                      icon: isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      onTap: () {
                        setState(() {
                          isSpeakerOn = !isSpeakerOn;
                        });
                      },
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _callButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    double size = 60,
    double iconSize = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}