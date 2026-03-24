import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

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
                  'Contact Us',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Our support team is here to help you with appointments, account issues, and platform guidance.',
                  style: TextStyle(color: Color(0xFFD9FFF8), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _ContactCard(
            icon: Icons.email_outlined,
            title: 'Email',
            value: 'chandany67071@gmail.com',
          ),
          const SizedBox(height: 10),
          const _ContactCard(
            icon: Icons.phone_outlined,
            title: 'Phone',
            value: '9682000334',
          ),
          const SizedBox(height: 10),
          const _ContactCard(
            icon: Icons.location_on_outlined,
            title: 'Address',
            value: '123 Healthcare Ave, Medical City, MC 12345',
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(label: '24/7 Chat Support'),
              _TagChip(label: 'Average Response: < 10 mins'),
              _TagChip(label: 'Multilingual Assistance'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCECE8)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Hours',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                SizedBox(height: 6),
                Text('Mon - Fri: 8:00 AM - 10:00 PM',
                    style: TextStyle(color: Color(0xFF334155))),
                Text('Sat - Sun: 9:00 AM - 8:00 PM',
                    style: TextStyle(color: Color(0xFF334155))),
                SizedBox(height: 8),
                Text(
                  'For emergencies, please contact local emergency services immediately.',
                  style: TextStyle(color: Color(0xFF475569), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

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
                        fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style:
                        const TextStyle(color: Color(0xFF334155), height: 1.35),
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD4EBE6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1E4D4A),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
