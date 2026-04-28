import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const Color _tealDark = Color(0xFF0D5C57);
  static const Color _teal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          _ContactCard(
            icon: Icons.email_outlined,
            title: 'Email',
            value: 'chandany67071@gmail.com',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.phone_outlined,
            title: 'Phone',
            value: '9682000334',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.location_on_outlined,
            title: 'Address',
            value: '123 Healthcare Ave, Medical City, MC 12345',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(label: '24/7 Chat Support', isDarkMode: isDarkMode),
              _TagChip(
                  label: 'Average Response: < 10 mins', isDarkMode: isDarkMode),
              _TagChip(
                  label: 'Multilingual Assistance', isDarkMode: isDarkMode),
            ],
          ),
          const SizedBox(height: 12),
          _SupportHoursCard(isDarkMode: isDarkMode),
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
    required this.isDarkMode,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDarkMode ? 0 : 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? Theme.of(context).cardColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF0D9488).withValues(alpha: 0.2)
                    : const Color(0xFFE6F7F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0D9488),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: isDarkMode
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: isDarkMode
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : const Color(0xFF334155),
                      height: 1.35,
                    ),
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
  const _TagChip({
    required this.label,
    required this.isDarkMode,
  });

  final String label;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF0D9488).withValues(alpha: 0.15)
            : const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF0D9488).withValues(alpha: 0.3)
              : const Color(0xFFD4EBE6),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDarkMode ? const Color(0xFF5EEAD4) : const Color(0xFF1E4D4A),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SupportHoursCard extends StatelessWidget {
  const _SupportHoursCard({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isDarkMode ? Theme.of(context).cardColor : const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
              : const Color(0xFFDCECE8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Hours',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: isDarkMode
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mon - Fri: 8:00 AM - 10:00 PM',
            style: TextStyle(
              color: isDarkMode
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : const Color(0xFF334155),
            ),
          ),
          Text(
            'Sat - Sun: 9:00 AM - 8:00 PM',
            style: TextStyle(
              color: isDarkMode
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For emergencies, please contact local emergency services immediately.',
            style: TextStyle(
              color: isDarkMode
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : const Color(0xFF475569),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
