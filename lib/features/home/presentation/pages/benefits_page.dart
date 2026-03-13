import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class BenefitsPage extends StatelessWidget {
  const BenefitsPage({super.key});

  static const Color _tealDark = Color(0xFF0D5C57);
  static const Color _teal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Wider Reach',
        'Consult patients beyond your city through secure online care.'
      ),
      (
        'Smart Practice Tools',
        'Manage appointments, notes, and follow-up reminders from one dashboard.'
      ),
      (
        'Secure Payments',
        'Receive timely payouts with transparent fee management.'
      ),
      (
        'Professional Visibility',
        'Build trust with verified profile badges and patient reviews.'
      ),
    ];

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
                  'Doctor Benefits',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'MediConnect gives doctors technology, reach, and tools to deliver better care efficiently.',
                  style: TextStyle(color: Color(0xFFD9FFF8), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                elevation: 1.2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$1,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(item.$2,
                          style: const TextStyle(
                              color: Color(0xFF334155), height: 1.35)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
