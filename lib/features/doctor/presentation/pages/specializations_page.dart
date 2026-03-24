import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/features/doctor/presentation/pages/all_specializations_page.dart';
import 'package:healthlink_connect_flutter/shared/widgets/app_footer.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class SpecializationsPage extends StatefulWidget {
  const SpecializationsPage({super.key});

  @override
  State<SpecializationsPage> createState() => _SpecializationsPageState();
}

class _SpecializationsPageState extends State<SpecializationsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<_SpecializationItem> _specializations = const [
    _SpecializationItem(
      title: 'Cardiology',
      description: 'Expert care for your heart and cardiovascular system.',
      icon: Icons.favorite_outline,
    ),
    _SpecializationItem(
      title: 'Neurology',
      description: 'Diagnosis and treatment of nervous system disorders.',
      icon: Icons.psychology_outlined,
    ),
    _SpecializationItem(
      title: 'Orthopedics',
      description: 'Care for bones, joints, ligaments, and muscles.',
      icon: Icons.accessibility_new_outlined,
    ),
    _SpecializationItem(
      title: 'Pediatrics',
      description: 'Medical care for infants, children, and adolescents.',
      icon: Icons.child_care_outlined,
    ),
    _SpecializationItem(
      title: 'Dermatology',
      description: 'Treatment for skin, hair, and nail conditions.',
      icon: Icons.spa_outlined,
    ),
    _SpecializationItem(
      title: 'Gynecology',
      description: "Health care for women's reproductive health.",
      icon: Icons.female_outlined,
    ),
    _SpecializationItem(
      title: 'Psychiatry',
      description: 'Mental health support and treatment.',
      icon: Icons.self_improvement_outlined,
    ),
    _SpecializationItem(
      title: 'General Medicine',
      description: 'Comprehensive care for all your general health needs.',
      icon: Icons.medical_services_outlined,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<_SpecializationItem> visibleSpecializations =
        _specializations.where((item) {
      if (query.isEmpty) {
        return true;
      }
      return item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MediConnectHeader(),
      drawer: const MediConnectDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          _buildHeroSection(),
          const SizedBox(height: 14),
          _buildSearchBar(),
          const SizedBox(height: 18),
          _buildInfoSection(),
          const SizedBox(height: 20),
          _buildSectionTitle('Popular Specializations'),
          const SizedBox(height: 6),
          const Text(
            'Comprehensive care covering all major medical fields',
            style: TextStyle(color: Color(0xFF475569), height: 1.35),
          ),
          const SizedBox(height: 12),
          _buildSpecializationGrid(visibleSpecializations),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllSpecializationsPage(),
                ),
              ),
              child: const Text(
                'View All Specializations',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildHighlightsSection(),
          const SizedBox(height: 20),
          _buildEasyAccessSection(),
          const SizedBox(height: 20),
          _buildCtaSection(),
          const SizedBox(height: 20),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5C57), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expert Care For Every Need',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find the Right Specialist for Your Health',
            style: TextStyle(
              color: Color(0xFFD9FFF8),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'From cardiology to pediatrics, connect with top-rated medical experts across all major specializations. Your health journey starts here.',
            style: TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search specializations (e.g. Heart, Skin...)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0D9488)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => setState(() {}),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            elevation: 0,
          ),
          child: const Text('Search',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
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
            'What is a Medical Specialization?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Medical specializations focus on specific parts of the body, age groups, or types of medical conditions. Consulting a specialist ensures you get expert diagnosis and the most effective treatment plan tailored to your specific health needs. At MediConnect, we bring all these experts to your fingertips.',
            style: TextStyle(color: Color(0xFF334155), height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationGrid(List<_SpecializationItem> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'No specialization found for your search.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF475569)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 1000) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 760) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 520) {
          crossAxisCount = 2;
        }

        final double mainAxisExtent;
        if (crossAxisCount == 1) {
          mainAxisExtent = 205;
        } else if (crossAxisCount == 2) {
          mainAxisExtent = 225;
        } else {
          mainAxisExtent = 240;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            final _SpecializationItem item = items[index];

            return Card(
              elevation: 1.2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: const Color(0xFF0D9488)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.doctors),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        'Find ${item.title}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHighlightsSection() {
    const List<_FeatureHighlight> highlights = [
      _FeatureHighlight(
        icon: Icons.verified_user_outlined,
        title: 'Verified Doctors',
        description:
            'Every doctor on our platform is thoroughly vetted and verified.',
      ),
      _FeatureHighlight(
        icon: Icons.reviews_outlined,
        title: 'Patient Reviews',
        description:
            'Read real reviews from other patients to make informed choices.',
      ),
      _FeatureHighlight(
        icon: Icons.payments_outlined,
        title: 'Affordable Care',
        description: 'Transparent pricing with no hidden fees.',
      ),
      _FeatureHighlight(
        icon: Icons.video_call_outlined,
        title: 'Online & Offline',
        description: 'Choose between video consultations or clinic visits.',
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: highlights
          .map(
            (item) => SizedBox(
              width: MediaQuery.sizeOf(context).width > 760
                  ? (MediaQuery.sizeOf(context).width - 52) / 2
                  : double.infinity,
              child: Card(
                elevation: 1.2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                        child: Icon(item.icon, color: const Color(0xFF0D9488)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 17)),
                            const SizedBox(height: 5),
                            Text(item.description,
                                style: const TextStyle(
                                    color: Color(0xFF475569), height: 1.35)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEasyAccessSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Easy Access to Medical Experts',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            "Finding the right doctor shouldn't be a headache. With MediConnect, you can browse profiles, check qualifications, view availability, and book appointments instantly.",
            style: TextStyle(color: Color(0xFF334155), height: 1.45),
          ),
          SizedBox(height: 12),
          Text('3 Simple Steps:',
              style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 10),
          _StepRow(
              number: '1', text: 'Search for a specialization or condition'),
          SizedBox(height: 8),
          _StepRow(
              number: '2',
              text: 'Compare doctors based on reviews and profile'),
          SizedBox(height: 8),
          _StepRow(number: '3', text: 'Book a video or in-clinic consultation'),
        ],
      ),
    );
  }

  Widget _buildCtaSection() {
    final isLoggedIn = context.watch<AuthProvider>().isAuthenticated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5C57), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Health is Our Priority',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            "Don't delay your care. Connect with a verified specialist today and take the first step towards better health.",
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
                  child: const Text('Find a Doctor Now',
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
}

class _SpecializationItem {
  const _SpecializationItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _FeatureHighlight {
  const _FeatureHighlight({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF0D9488),
          child: Text(
            number,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF334155))),
        ),
      ],
    );
  }
}
