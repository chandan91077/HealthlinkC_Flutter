import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Effective date: March 9, 2026',
                  style: TextStyle(color: Color(0xFFD9FFF8)),
                ),
                SizedBox(height: 10),
                Text(
                  'Your privacy is important to us. This policy explains how MediConnect collects, uses, stores, and protects your data.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _PolicySection(
            icon: Icons.badge_outlined,
            title: 'Information We Collect',
            body:
                'We may collect account details, appointment information, consultation records, and app usage data to provide healthcare services effectively.',
          ),
          const SizedBox(height: 10),
          const _PolicySection(
            icon: Icons.settings_suggest_outlined,
            title: 'How We Use Information',
            body:
                'We use your data to deliver consultations, improve your user experience, provide support, and keep the platform secure and reliable.',
          ),
          const SizedBox(height: 10),
          const _PolicySection(
            icon: Icons.shield_outlined,
            title: 'Data Protection',
            body:
                'MediConnect uses encryption, strict access controls, and secure cloud infrastructure to protect personal and medical information.',
          ),
          const SizedBox(height: 10),
          const _PolicySection(
            icon: Icons.schedule_outlined,
            title: 'Data Retention',
            body:
                'We retain data only as long as necessary to provide services, comply with legal obligations, and resolve disputes.',
          ),
          const SizedBox(height: 10),
          const _PolicySection(
            icon: Icons.rule_outlined,
            title: 'Your Rights',
            body:
                'You can request access to your data, ask for corrections, and request deletion where permitted by law.',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCECE8)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.contact_support_outlined, color: _teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Questions about privacy? Contact us at chandany67071@gmail.com.',
                    style: TextStyle(color: Color(0xFF334155), height: 1.35),
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

class _PolicySection extends StatelessWidget {
  const _PolicySection({
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
