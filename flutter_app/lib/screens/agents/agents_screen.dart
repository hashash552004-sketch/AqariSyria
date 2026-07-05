import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../widgets/custom_app_bar.dart';
import 'agent_profile_screen.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedGovernorate;
  String? _selectedSpecialty;

  final List<String> _categories = ['الكل', 'وكيل معتمد', 'وكيل عادي', 'مكتب عقاري'];
  final List<String> _specialties = ['الكل', 'شقق', 'فلل', 'أراضي', 'عقارات تجارية', 'مزارع'];

  final List<_AgentData> _agents = [
    _AgentData(
      name: 'أحمد الخطيب',
      image: null,
      rating: 4.9,
      propertiesCount: 48,
      category: 'وكيل معتمد',
      governorate: 'دمشق',
      specialty: 'شقق',
      phone: '0933123456',
    ),
    _AgentData(
      name: 'سلمى حديد',
      image: null,
      rating: 4.8,
      propertiesCount: 36,
      category: 'وكيل معتمد',
      governorate: 'حلب',
      specialty: 'فلل',
      phone: '0944123456',
    ),
    _AgentData(
      name: 'خالد ديب',
      image: null,
      rating: 4.6,
      propertiesCount: 29,
      category: 'وكيل عادي',
      governorate: 'اللاذقية',
      specialty: 'أراضي',
      phone: '0955123456',
    ),
    _AgentData(
      name: 'نور الأسعد',
      image: null,
      rating: 4.9,
      propertiesCount: 52,
      category: 'وكيل معتمد',
      governorate: 'دمشق',
      specialty: 'عقارات تجارية',
      phone: '0966123456',
    ),
    _AgentData(
      name: 'محمود الصالح',
      image: null,
      rating: 4.5,
      propertiesCount: 22,
      category: 'وكيل عادي',
      governorate: 'حمص',
      specialty: 'شقق',
      phone: '0977123456',
    ),
    _AgentData(
      name: 'رنا القاسم',
      image: null,
      rating: 4.7,
      propertiesCount: 41,
      category: 'وكيل معتمد',
      governorate: 'طرطوس',
      specialty: 'مزارع',
      phone: '0988123456',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'الوكلاء العقاريون'),
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cards,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'بحث عن وكيل...',
                hintStyle: AppTextStyles.bodyMedium,
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 20),
          ..._agents.map((agent) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAgentCard(agent),
          )),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(child: _buildDropdown('التصنيف', _categories, _selectedCategory, (v) {
          setState(() => _selectedCategory = v);
        })),
        const SizedBox(width: 8),
        Expanded(child: _buildDropdown('المحافظة', ['الكل', ...AppConstants.governorates], _selectedGovernorate, (v) {
          setState(() => _selectedGovernorate = v);
        })),
        const SizedBox(width: 8),
        Expanded(child: _buildDropdown('التخصص', _specialties, _selectedSpecialty, (v) {
          setState(() => _selectedSpecialty = v);
        })),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selected, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Text(label, style: AppTextStyles.caption),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          style: AppTextStyles.labelMedium,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, style: AppTextStyles.labelMedium),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAgentCard(_AgentData agent) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AgentProfileScreen()),
      ),
      child: Container(
        padding: AppConstants.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    agent.name[0],
                    style: AppTextStyles.displaySmall.copyWith(color: AppColors.primary, fontSize: 28),
                  ),
                ),

              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(agent.name, style: AppTextStyles.titleMedium),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(agent.category, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < agent.rating.floor() ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                        size: 14,
                      )),
                      const SizedBox(width: 4),
                      Text(agent.rating.toString(), style: AppTextStyles.labelSmall),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(agent.governorate, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.home_work, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${agent.propertiesCount} عقار', style: AppTextStyles.caption),
                      const SizedBox(width: 16),
                      Icon(Icons.business, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(agent.specialty, style: AppTextStyles.caption),
                    ],
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

class _AgentData {
  final String name;
  final String? image;
  final double rating;
  final int propertiesCount;
  final String category;
  final String governorate;
  final String specialty;
  final String phone;
  const _AgentData({
    required this.name,
    this.image,
    required this.rating,
    required this.propertiesCount,
    required this.category,
    required this.governorate,
    required this.specialty,
    required this.phone,
  });
}
