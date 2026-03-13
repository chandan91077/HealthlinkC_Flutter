import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                  'Terms of Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please read these terms carefully before using MediConnect.',
                  style: TextStyle(color: Color(0xFFD9FFF8), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _TermsSection(
            icon: Icons.person_outline,
            title: 'User Responsibilities',
            body:
                'Users must provide accurate information, maintain account security, and use the platform lawfully and respectfully.',
          ),
          const SizedBox(height: 10),
          const _TermsSection(
            icon: Icons.local_hospital_outlined,
            title: 'Medical Disclaimer',
            body:
                'MediConnect facilitates access to licensed healthcare professionals but does not replace emergency care or direct clinical judgment.',
          ),
          const SizedBox(height: 10),
          const _TermsSection(
            icon: Icons.cloud_done_outlined,
            title: 'Service Availability',
            body:
                'We strive to keep services available and secure, but uptime may be affected by maintenance, updates, or external factors.',
          ),
          const SizedBox(height: 10),
          const _TermsSection(
            icon: Icons.credit_card_outlined,
            title: 'Payments and Refunds',
            body:
                'Fees for consultations are displayed before payment. Refund requests are handled per cancellation and provider policies.',
          ),
          const SizedBox(height: 10),
          const _TermsSection(
            icon: Icons.gavel_outlined,
            title: 'Changes to Terms',
            body:
                'We may update these terms periodically. Continued platform use after updates means you accept the revised terms.',
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

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
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style:
                        const TextStyle(color: Color(0xFF334155), height: 1.4),
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
