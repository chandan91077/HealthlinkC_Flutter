import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class AllSpecializationsPage extends StatefulWidget {
  const AllSpecializationsPage({super.key});

  @override
  State<AllSpecializationsPage> createState() => _AllSpecializationsPageState();
}

class _AllSpecializationsPageState extends State<AllSpecializationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Heart',
    'Brain',
    'Bones',
    'Children',
    'Skin',
    'Women',
    'Mental',
    'General',
  ];

  final List<_SpecializationEntry> _allItems = const [
    _SpecializationEntry(
        'Cardiology',
        'Heart',
        'Expert care for your heart and cardiovascular system.',
        Icons.favorite_outline),
    _SpecializationEntry(
        'Neurology',
        'Brain',
        'Diagnosis and treatment of nervous system disorders.',
        Icons.psychology_outlined),
    _SpecializationEntry(
        'Orthopedics',
        'Bones',
        'Care for bones, joints, ligaments, and muscles.',
        Icons.accessibility_new_outlined),
    _SpecializationEntry(
        'Pediatrics',
        'Children',
        'Medical care for infants, children, and adolescents.',
        Icons.child_care_outlined),
    _SpecializationEntry('Dermatology', 'Skin',
        'Treatment for skin, hair, and nail conditions.', Icons.spa_outlined),
    _SpecializationEntry('Gynecology', 'Women',
        "Health care for women's reproductive health.", Icons.female_outlined),
    _SpecializationEntry(
        'Psychiatry',
        'Mental',
        'Mental health support and treatment.',
        Icons.self_improvement_outlined),
    _SpecializationEntry(
        'General Medicine',
        'General',
        'Comprehensive care for all your general health needs.',
        Icons.medical_services_outlined),
    _SpecializationEntry(
        'Endocrinology',
        'General',
        'Specialized care for hormonal and metabolic disorders.',
        Icons.science_outlined),
    _SpecializationEntry(
        'Pulmonology',
        'General',
        'Diagnosis and treatment for lungs and breathing issues.',
        Icons.air_outlined),
    _SpecializationEntry(
        'ENT',
        'General',
        'Care for ear, nose, and throat related conditions.',
        Icons.hearing_outlined),
    _SpecializationEntry('Ophthalmology', 'General',
        'Advanced care for eyes and vision health.', Icons.visibility_outlined),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String query = _searchController.text.trim().toLowerCase();

    final items = _allItems.where((item) {
      final bool matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final bool matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const MediConnectHeader(),
      drawer: const MediConnectDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                  'All Specializations',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'Browse a complete list of available specialties and quickly find the right medical expert.',
                  style: TextStyle(color: Color(0xFFD9FFF8), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by specialization, category, or condition',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map(
                  (category) => ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    selectedColor: const Color(0xFF0D9488),
                    labelStyle: TextStyle(
                      color: _selectedCategory == category
                          ? Colors.white
                          : const Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No matching specializations found. Try a different search.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF475569)),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(item.icon, color: const Color(0xFF0D9488)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(item.description,
                                  style: const TextStyle(
                                      color: Color(0xFF475569), height: 1.35)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(item.category,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () =>
                                        context.go(AppRoutes.doctors),
                                    child: const Text('Find Doctors'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

class _SpecializationEntry {
  const _SpecializationEntry(
      this.title, this.category, this.description, this.icon);

  final String title;
  final String category;
  final String description;
  final IconData icon;
}
