import 'package:flutter/material.dart';

class VideoCallPage extends StatefulWidget {
  final String roomId;
  const VideoCallPage({super.key, required this.roomId});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool isMuted = false;
  bool isCameraOff = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video Placeholder
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, size: 100, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text(
                    'Dr. Smith',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connecting...',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            
            // Local Video PIP Placeholder
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: isCameraOff
                    ? const Center(child: Icon(Icons.videocam_off, color: Colors.white54))
                    : const Center(child: Icon(Icons.person, color: Colors.white)),
              ),
            ),
            
            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            
            // Controls
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlBtn(
                    icon: isMuted ? Icons.mic_off : Icons.mic,
                    color: isMuted ? Colors.red : Colors.grey[800]!,
                    onTap: () => setState(() => isMuted = !isMuted),
                  ),
                  _ControlBtn(
                    icon: Icons.call_end,
                    color: Colors.red,
                    iconSize: 32,
                    padding: 24,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _ControlBtn(
                    icon: isCameraOff ? Icons.videocam_off : Icons.videocam,
                    color: isCameraOff ? Colors.red : Colors.grey[800]!,
                    onTap: () => setState(() => isCameraOff = !isCameraOff),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double iconSize;
  final double padding;

  const _ControlBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.iconSize = 24,
    this.padding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}
