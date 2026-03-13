import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

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
                  'Frequently Asked Questions',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'Find quick answers about appointments, payments, and account security.',
                  style: TextStyle(color: Color(0xFFD9FFF8), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _FaqItem(
            question: 'How do I book a consultation?',
            answer:
                'Go to Find Doctors, choose a specialist, select a slot, and confirm your booking.',
          ),
          const SizedBox(height: 10),
          const _FaqItem(
            question: 'Are doctors verified?',
            answer:
                'Yes. Every doctor on MediConnect is verified with credentials and licensing details.',
          ),
          const SizedBox(height: 10),
          const _FaqItem(
            question: 'Can I get digital prescriptions?',
            answer:
                'Yes. After your consultation, digital prescriptions are available in your account.',
          ),
          const SizedBox(height: 10),
          const _FaqItem(
            question: 'Is my medical data secure?',
            answer:
                'Yes. We use encryption and strict access controls to protect all sensitive information.',
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: const Color(0xFF0D9488),
        collapsedIconColor: const Color(0xFF0D9488),
        title:
            Text(question, style: const TextStyle(fontWeight: FontWeight.w700)),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(answer,
                style: const TextStyle(color: Color(0xFF334155), height: 1.35)),
          ),
        ],
      ),
    );
  }
}
