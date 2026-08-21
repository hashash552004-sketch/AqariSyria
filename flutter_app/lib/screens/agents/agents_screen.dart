import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_skeleton.dart';
import '../../services/firestore_service.dart';
import '../../models/property.dart';
import 'agent_profile_screen.dart';

class _AgentData {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final int reviewsCount;
  final int propertiesCount;
  final int totalViews;
  final String governorate;
  final String specialty;

  const _AgentData({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.reviewsCount,
    required this.propertiesCount,
    required this.totalViews,
    required this.governorate,
    required this.specialty,
  });
}

_AgentData? _aggregate(String ownerId, List<Property> owned) {
  if (owned.isEmpty) return null;
  final rated = owned.where((p) => p.reviewsCount > 0).toList();
  final avgRating = rated.isEmpty
      ? 0.0
      : rated.map((p) => p.rating * p.reviewsCount).reduce((a, b) => a + b) /
          rated.map((p) => p.reviewsCount).reduce((a, b) => a + b);
  final reviews = rated.fold<int>(0, (sum, p) => sum + p.reviewsCount);
  final views = owned.fold<int>(0, (sum, p) => sum + p.viewsCount);
  final govCounts = <String, int>{};
  for (final p in owned) {
    govCounts[p.governorate] = (govCounts[p.governorate] ?? 0) + 1;
  }
  final topGov = govCounts.entries
      .reduce((a, b) => b.value > a.value ? b : a)
      .key;
  return _AgentData(
    id: ownerId,
    name: owned.first.ownerName.isNotEmpty ? owned.first.ownerName : 'مستخدم',
    phone: owned.first.ownerPhone,
    rating: avgRating,
    reviewsCount: reviews,
    propertiesCount: owned.length,
    totalViews: views,
    governorate: topGov,
    specialty: owned.first.type,
  );
}

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGovernorate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_AgentData> _buildAgents(List<Property> properties) {
    final byOwner = <String, List<Property>>{};
    for (final p in properties) {
      if (p.ownerId.isEmpty) continue;
      byOwner.putIfAbsent(p.ownerId, () => []).add(p);
    }
    final agents = byOwner.entries
        .map((e) => _aggregate(e.key, e.value))
        .whereType<_AgentData>()
        .toList();
    agents.sort((a, b) => b.propertiesCount.compareTo(a.propertiesCount));
    return agents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'الوكلاء العقاريون'),
      body: StreamBuilder<List<Property>>(
        stream: FirestoreService().streamProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: AppConstants.screenPadding,
              itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PropertyCardSkeleton(),
              ),
            );
          }
          final agents = _buildAgents(snapshot.data ?? []);
          final query = _searchController.text.trim();
          var filtered = agents;
          if (query.isNotEmpty) {
            filtered = filtered.where((a) => a.name.contains(query)).toList();
          }
          if (_selectedGovernorate != null && _selectedGovernorate != 'الكل') {
            filtered =
                filtered.where((a) => a.governorate == _selectedGovernorate).toList();
          }

          return ListView(
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['الكل', ...AppConstants.governorates].map((g) {
                    final selected = _selectedGovernorate ?? 'الكل';
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: selected == g,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected == g ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (_) => setState(() => _selectedGovernorate = g),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 56, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text('لا يوجد وكلاء مطابقون',
                          style: AppTextStyles.titleMedium),
                    ],
                  ),
                )
              else
                ...filtered.map((agent) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildAgentCard(agent),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAgentCard(_AgentData agent) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AgentProfileScreen(
            agentId: agent.id,
            agentName: agent.name,
            phone: agent.phone,
          ),
        ),
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
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                agent.name.isNotEmpty ? agent.name[0] : '؟',
                style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.primary, fontSize: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.name, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                            i < agent.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.warning,
                            size: 14,
                          )),
                      const SizedBox(width: 4),
                      Text(
                        agent.reviewsCount > 0
                            ? agent.rating.toStringAsFixed(1)
                            : 'جديد',
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(agent.governorate,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.home_work,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${agent.propertiesCount} عقار',
                          style: AppTextStyles.caption),
                      const SizedBox(width: 16),
                      Icon(Icons.visibility,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${agent.totalViews} مشاهدة',
                          style: AppTextStyles.caption),
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
