import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class JoinAsDoctorPage extends StatelessWidget {
  const JoinAsDoctorPage({super.key});

  static const Color _tealDark = Color(0xFF0D5C57);
  static const Color _teal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MediConnectHeader(),
      drawer: const MediConnectDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [_tealDark, _teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join as Doctor',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'Grow your practice with secure telehealth, smart scheduling, and verified patient access.',
                  style: TextStyle(color: Color(0xFFD9FFF8), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _DoctorPoint(
            icon: Icons.verified_outlined,
            title: 'Verification Process',
            text:
                'Submit medical license, credentials, and identity documents for secure onboarding.',
          ),
          const SizedBox(height: 10),
          const _DoctorPoint(
            icon: Icons.videocam_outlined,
            title: 'Teleconsultation Tools',
            text:
                'Use encrypted chat and video consultations with digital prescriptions and follow-ups.',
          ),
          const SizedBox(height: 10),
          const _DoctorPoint(
            icon: Icons.calendar_month_outlined,
            title: 'Flexible Scheduling',
            text:
                'Set your availability, consultation slots, and fee preferences at your convenience.',
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              context.go('${AppRoutes.register}?role=doctor');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
            ),
            child: const Text('Apply Now',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DoctorPoint extends StatelessWidget {
  const _DoctorPoint({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF0D9488)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(text,
                      style: const TextStyle(
                          color: Color(0xFF334155), height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
