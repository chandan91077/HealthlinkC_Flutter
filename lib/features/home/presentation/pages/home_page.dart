import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color _tealDark = Color(0xFF0D5C57);
  static const Color _teal = Color(0xFF0D9488);
  static const Color _softMint = Color(0xFFE8F7F4);
  static const Color _softBlue = Color(0xFFE7F4FF);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isNarrow = width < 380;

    return Container(
      color: Colors.white,
      child: ListView(
        padding:
            EdgeInsets.fromLTRB(isNarrow ? 12 : 16, 10, isNarrow ? 12 : 16, 22),
        children: [
          _buildHeroSection(context),
          const SizedBox(height: 16),
          _buildStatsSection(context),
          const SizedBox(height: 20),
          _buildSectionTitle('Everything You Need for Better Healthcare'),
          const SizedBox(height: 10),
          _buildFeaturesSection(),
          const SizedBox(height: 20),
          _buildSectionTitle('How It Works'),
          const SizedBox(height: 10),
          _buildHowItWorksSection(),
          const SizedBox(height: 20),
          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_tealDark, _teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _teal.withAlpha(60),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(28),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Your Health, Our Priority',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Healthcare Made\nSimple & Accessible',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Connect with verified doctors instantly, book appointments, and manage your health all in one place.',
            style:
                TextStyle(color: Color(0xFFE6FFFA), height: 1.45, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.register),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A3D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Get Started Free',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.doctors),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Find a Doctor',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final List<({String value, String label})> stats = [
      (value: '50+', label: 'Verified Doctors'),
      (value: '500+', label: 'Consultations'),
      (value: '4.9/5', label: 'Patient Rating'),
      (value: '24/7', label: 'Availability'),
    ];

    final bool compact = MediaQuery.sizeOf(context).width < 360;

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: compact ? 1.25 : 1.45,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 1.5,
          shadowColor: Colors.black.withAlpha(28),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: index.isEven
                  ? const LinearGradient(
                      colors: [Color(0xFFF7FFFD), Color(0xFFEEFAF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFF8FBFF), Color(0xFFF0F8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _tealDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF475569), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesSection() {
    final List<({IconData icon, String title, String text, Color tint})>
        features = [
      (
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Real-time Chat',
        text:
            'Message your doctor directly and share files, reports, and images.',
        tint: _softMint,
      ),
      (
        icon: Icons.calendar_month_outlined,
        title: 'Easy Scheduling',
        text: 'Book appointments at your convenience with just a few taps.',
        tint: _softBlue,
      ),
      (
        icon: Icons.description_outlined,
        title: 'Digital Prescriptions',
        text: 'Receive and access prescriptions digitally, anytime.',
        tint: _softMint,
      ),
      (
        icon: Icons.emergency_outlined,
        title: 'Emergency Care',
        text: 'Get immediate access to doctors for urgent health concerns.',
        tint: _softBlue,
      ),
    ];

    return Column(
      children: features
          .map(
            (feature) => Card(
              elevation: 1.4,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: feature.tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(feature.icon, color: _teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.title,
                            style: const TextStyle(
                                fontSize: 24 / 1.333,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            feature.text,
                            style: const TextStyle(
                                color: Color(0xFF475569), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildHowItWorksSection() {
    final List<({String number, String title})> steps = [
      (number: '1', title: 'Sign Up'),
      (number: '2', title: 'Find Doctor'),
      (number: '3', title: 'Book Appointment'),
      (number: '4', title: 'Get Consultation'),
    ];

    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool wrap = constraints.maxWidth < 330;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: steps
                  .map(
                    (step) => Container(
                      width: wrap
                          ? double.infinity
                          : (constraints.maxWidth - 10) / 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE6EDF5)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _teal,
                            child: Text(
                              step.number,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ContactRow(
              icon: Icons.email_outlined, text: 'support@mediconnect.com'),
          SizedBox(height: 8),
          _ContactRow(icon: Icons.phone_outlined, text: '+1 (555) 125-4567'),
          SizedBox(height: 8),
          _ContactRow(
              icon: Icons.location_on_outlined,
              text: '125 Healthcare Ave, Medical City, MC 12345'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 30 / 1.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF102A2A),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFCFFAF3), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, height: 1.35),
          ),
        ),
      ],
    );
  }
}
