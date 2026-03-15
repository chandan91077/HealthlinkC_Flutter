import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/features/doctor/presentation/pages/specializations_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/benefits_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/contact_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/faq_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/join_as_doctor_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/privacy_policy_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/terms_of_service_page.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
          _buildHero(),
          const SizedBox(height: 16),
          _buildMissionVision(),
          const SizedBox(height: 20),
          _buildSectionTitle('How MediConnect Works'),
          const SizedBox(height: 6),
          const Text(
            "We've simplified healthcare access through our secure and intuitive platform",
            style: TextStyle(color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 10),
          _buildHowItWorks(),
          const SizedBox(height: 20),
          _buildSectionTitle('Why Choose MediConnect?'),
          const SizedBox(height: 6),
          const Text(
            'We combine technology with compassion to deliver exceptional healthcare experiences',
            style: TextStyle(color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 10),
          _buildWhyChoose(),
          const SizedBox(height: 20),
          _buildSectionTitle('Our Core Values'),
          const SizedBox(height: 6),
          const Text(
            'The principles that guide everything we do',
            style: TextStyle(color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 10),
          _buildValues(),
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 20),
          _buildTrustSection(),
          const SizedBox(height: 20),
          _buildCta(context),
          const SizedBox(height: 20),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_tealDark, _teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _teal.withAlpha(55),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About MediConnect',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Transforming Healthcare, One Connection at a Time',
            style: TextStyle(
              color: Color(0xFFDFFFF8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'MediConnect is your trusted partner in accessible, affordable, and quality healthcare. We bridge the gap between patients and verified medical professionals through innovative technology.',
            style: TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionVision() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stack = constraints.maxWidth < 760;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _infoCard(
              width: stack ? double.infinity : (constraints.maxWidth - 12) / 2,
              icon: Icons.flag_outlined,
              title: 'Our Mission',
              body:
                  'To make quality healthcare accessible and affordable for everyone by connecting patients with verified doctors through a secure, user-friendly digital platform. We believe that distance and time should never be barriers to receiving expert medical care.',
            ),
            _infoCard(
              width: stack ? double.infinity : (constraints.maxWidth - 12) / 2,
              icon: Icons.visibility_outlined,
              title: 'Our Vision',
              body:
                  'To become the most trusted healthcare platform where every individual can access world-class medical expertise at their fingertips. We envision a future where healthcare is seamless, transparent, and centered around patient needs.',
            ),
          ],
        );
      },
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      children: const [
        _NumberedStep(
          number: '1',
          title: 'Find Your Doctor',
          body:
              'Browse through our network of verified doctors across multiple specializations. Read reviews, check credentials, and choose the right expert for your needs.',
        ),
        SizedBox(height: 10),
        _NumberedStep(
          number: '2',
          title: 'Book Instantly',
          body:
              'Schedule appointments at your convenience. Choose between video consultations or in-person visits. Pay securely through our platform.',
        ),
        SizedBox(height: 10),
        _NumberedStep(
          number: '3',
          title: 'Get Expert Care',
          body:
              'Connect with your doctor via video call or chat. Receive digital prescriptions, follow-up reminders, and ongoing support for your health journey.',
        ),
      ],
    );
  }

  Widget _buildWhyChoose() {
    final items = [
      (
        Icons.videocam_outlined,
        'Online Consultations',
        'Connect with doctors via secure video calls from anywhere.'
      ),
      (
        Icons.calendar_month_outlined,
        'Easy Booking',
        'Schedule appointments at your convenience in just a few clicks.'
      ),
      (
        Icons.verified_user_outlined,
        'Verified Doctors',
        'All healthcare professionals are thoroughly verified and licensed.'
      ),
      (
        Icons.schedule_outlined,
        '24/7 Availability',
        'Access healthcare support whenever you need it, day or night.'
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => _iconCard(
              icon: item.$1,
              title: item.$2,
              body: item.$3,
            ),
          )
          .toList(),
    );
  }

  Widget _buildValues() {
    final values = [
      (
        Icons.favorite_outline,
        'Patient-Centric Care',
        'Your health and well-being are at the heart of everything we do.'
      ),
      (
        Icons.lock_outline,
        'Trust & Security',
        'We ensure complete privacy and security of your medical data.'
      ),
      (
        Icons.workspace_premium_outlined,
        'Quality Excellence',
        'Only verified, experienced doctors join our platform.'
      ),
      (
        Icons.public_outlined,
        'Accessibility',
        'Healthcare should be accessible to everyone, everywhere.'
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values
          .map(
            (item) => _iconCard(
              icon: item.$1,
              title: item.$2,
              body: item.$3,
            ),
          )
          .toList(),
    );
  }

  Widget _buildStats() {
    final stats = [
      ('500+', 'Verified Doctors'),
      ('50,000+', 'Happy Patients'),
      ('100+', 'Specializations'),
      ('24/7', 'Support'),
    ];

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 1.2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: index.isEven
                  ? const LinearGradient(
                      colors: [Color(0xFFF6FFFC), Color(0xFFEAF8F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFF8FBFF), Color(0xFFEEF4FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.$1,
                  style: const TextStyle(
                    color: _tealDark,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.$2,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrustSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEDE9)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Trust is Our Priority',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF123636),
            ),
          ),
          SizedBox(height: 10),
          Text(
            "At MediConnect, we understand that healthcare is personal. That's why we've built our platform with industry-leading security standards. All doctors are verified, licensed professionals. Your medical data is encrypted and protected. Every consultation is confidential and secure.",
            style: TextStyle(height: 1.45, color: Color(0xFF334155)),
          ),
          SizedBox(height: 12),
          _TrustPoint(text: 'End-to-end encrypted consultations'),
          _TrustPoint(text: 'HIPAA-compliant data protection'),
          _TrustPoint(text: 'Verified and licensed healthcare professionals'),
          _TrustPoint(text: 'Secure payment processing'),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isAuthenticated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [_tealDark, _teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to Experience Better Healthcare?',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join thousands of patients who trust MediConnect for their healthcare needs. Start your journey to better health today.',
            style: TextStyle(color: Color(0xFFD9FFF8), height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.doctors),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A3D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Find a Doctor',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (!isLoggedIn) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.register),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Sign Up Free',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final BuildContext rootContext = context;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF102A2A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stack = constraints.maxWidth < 760;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: stack
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 40) / 3,
                    child: _FooterBlock(
                      title: 'MediConnect',
                      lines: [
                        'Connecting patients with trusted healthcare professionals for seamless consultations and care.',
                      ],
                    ),
                  ),
                  SizedBox(
                    width: stack
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 40) / 3,
                    child: _FooterBlock(
                      title: 'Quick Links',
                      lines: [
                        'Find Doctors',
                        'Specializations',
                        'About Us',
                        'Contact'
                      ],
                      onTapLine: (line) => _onFooterLinkTap(rootContext, line),
                    ),
                  ),
                  SizedBox(
                    width: stack
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 40) / 3,
                    child: _FooterBlock(
                      title: 'For Doctors',
                      lines: ['Join as Doctor', 'Benefits', 'FAQ'],
                      onTapLine: (line) => _onFooterLinkTap(rootContext, line),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FooterBlock(
                title: 'Contact Us',
                lines: [
                  'support@mediconnect.com',
                  '+1 (555) 123-4567',
                  '123 Healthcare Ave, Medical City, MC 12345',
                ],
                onTapLine: (line) => _onFooterLinkTap(rootContext, line),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF285454)),
              const SizedBox(height: 10),
              const Text(
                '© 2026 MediConnect. All rights reserved.',
                style: TextStyle(color: Color(0xFFC2E4DE)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: () =>
                        _onFooterLinkTap(rootContext, 'Privacy Policy'),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Color(0xFFC2E4DE),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFC2E4DE),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () =>
                        _onFooterLinkTap(rootContext, 'Terms of Service'),
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(
                        color: Color(0xFFC2E4DE),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFC2E4DE),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionContainer({required Widget child}) {
    return Card(
      elevation: 1.1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }

  Widget _infoCard({
    required double width,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return SizedBox(
      width: width,
      child: _sectionContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _teal),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(body,
                style: const TextStyle(color: Color(0xFF475569), height: 1.45)),
          ],
        ),
      ),
    );
  }

  Widget _iconCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: _sectionContainer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _teal),
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
                        body,
                        style: const TextStyle(
                            color: Color(0xFF475569), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF132E2E),
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  void _onFooterLinkTap(BuildContext context, String line) {
    switch (line) {
      case 'Find Doctors':
        context.go(AppRoutes.doctors);
        break;
      case 'Specializations':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SpecializationsPage(),
          ),
        );
        break;
      case 'About Us':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AboutPage(),
          ),
        );
        break;
      case 'Contact':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ContactPage(),
          ),
        );
        break;
      case 'Privacy Policy':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivacyPolicyPage(),
          ),
        );
        break;
      case 'Terms of Service':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TermsOfServicePage(),
          ),
        );
        break;
      case 'Join as Doctor':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const JoinAsDoctorPage(),
          ),
        );
        break;
      case 'Benefits':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BenefitsPage(),
          ),
        );
        break;
      case 'FAQ':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FaqPage(),
          ),
        );
        break;
      default:
        // Contact details are clickable and acknowledged with a toast-style hint.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(line)),
        );
    }
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF0D9488),
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 5),
                  Text(body,
                      style: const TextStyle(
                          color: Color(0xFF475569), height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF0D9488)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBlock extends StatelessWidget {
  const _FooterBlock({
    required this.title,
    required this.lines,
    this.onTapLine,
  });

  final String title;
  final List<String> lines;
  final ValueChanged<String>? onTapLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: onTapLine == null ? null : () => onTapLine!(line),
              child: Text(
                line,
                style: TextStyle(
                  color: const Color(0xFFC2E4DE),
                  height: 1.35,
                  decoration: onTapLine == null
                      ? TextDecoration.none
                      : TextDecoration.underline,
                  decorationColor: const Color(0xFFC2E4DE),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
