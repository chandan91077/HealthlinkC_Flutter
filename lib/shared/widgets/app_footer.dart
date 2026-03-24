import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/features/doctor/presentation/pages/specializations_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/about_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/benefits_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/contact_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/faq_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/join_as_doctor_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/privacy_policy_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/terms_of_service_page.dart';
import 'package:healthlink_connect_flutter/shared/widgets/app_logo.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLinksColumn(context, 'Quick Links', {
                      'Find Doctors': AppRoutes.doctors,
                      'Specializations': AppRoutes.specializations,
                      'About Us': AppRoutes.about,
                      'Contact': AppRoutes.contact,
                    }),
                    _buildLinksColumn(context, 'For Doctors', {
                      'Join as Doctor': AppRoutes.joinAsDoctor,
                      'Benefits': AppRoutes.benefits,
                      'FAQ': AppRoutes.faq,
                    }),
                    _buildContactColumn(),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandColumn(context),
                    const SizedBox(height: 32),
                    _buildLinksColumn(context, 'Quick Links', {
                      'Find Doctors': AppRoutes.doctors,
                      'Specializations': AppRoutes.specializations,
                      'About Us': AppRoutes.about,
                      'Contact': AppRoutes.contact,
                    }),
                    const SizedBox(height: 24),
                    _buildLinksColumn(context, 'For Doctors', {
                      'Join as Doctor': AppRoutes.joinAsDoctor,
                      'Benefits': AppRoutes.benefits,
                      'FAQ': AppRoutes.faq,
                    }),
                    const SizedBox(height: 24),
                    _buildContactColumn(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 48),
          const Divider(color: AppColors.border),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isNarrow = constraints.maxWidth < 520;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '© 2026 MediConnect. All rights reserved.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildBottomLink(
                          context,
                          'Privacy Policy',
                          AppRoutes.privacyPolicy,
                        ),
                        _buildBottomLink(
                          context,
                          'Terms of Service',
                          AppRoutes.termsOfService,
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '© 2026 MediConnect. All rights reserved.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  Row(
                    children: [
                      _buildBottomLink(
                        context,
                        'Privacy Policy',
                        AppRoutes.privacyPolicy,
                      ),
                      const SizedBox(width: 24),
                      _buildBottomLink(
                        context,
                        'Terms of Service',
                        AppRoutes.termsOfService,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrandColumn(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.go(AppRoutes.home),
            child: const Row(
              children: [
                AppLogo(size: 32, radius: 8),
                SizedBox(width: 8),
                Text(
                  'MediConnect',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connecting patients with trusted healthcare professionals for seamless consultations and care.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksColumn(
      BuildContext context, String title, Map<String, String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ...links.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _navigate(context, entry.value),
                child: Text(entry.key,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            )),
      ],
    );
  }

  Widget _buildContactColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact Us',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildContactItem(Icons.email_outlined, 'chandany67071@gmail.com'),
        _buildContactItem(Icons.phone_outlined, '9682000334'),
        _buildContactItem(Icons.location_on_outlined,
            '123 Healthcare Ave, Medical City, MC 12345'),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLink(BuildContext context, String text, String route) {
    return InkWell(
      onTap: () => _navigate(context, route),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    switch (route) {
      case AppRoutes.specializations:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SpecializationsPage(),
          ),
        );
        break;
      case AppRoutes.about:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AboutPage(),
          ),
        );
        break;
      case AppRoutes.contact:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ContactPage(),
          ),
        );
        break;
      case AppRoutes.privacyPolicy:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivacyPolicyPage(),
          ),
        );
        break;
      case AppRoutes.termsOfService:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TermsOfServicePage(),
          ),
        );
        break;
      case AppRoutes.joinAsDoctor:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const JoinAsDoctorPage(),
          ),
        );
        break;
      case AppRoutes.benefits:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BenefitsPage(),
          ),
        );
        break;
      case AppRoutes.faq:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FaqPage(),
          ),
        );
        break;
      default:
        context.go(route);
    }
  }
}
