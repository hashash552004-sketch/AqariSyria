import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/firestore_service.dart';
import '../../widgets/property_card.dart';
import '../../core/snackbar_helper.dart';

/// Formats a Syrian phone number for WhatsApp deep linking.
String? _whatsAppUrl(String rawPhone) {
  var digits = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
  digits = digits.replaceAll('+', '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = '963${digits.substring(1)}'; // Syria code
  if (digits.length < 10) return null;
  return 'https://wa.me/$digits';
}

class AgentProfileScreen extends StatelessWidget {
  final String agentId;
  final String agentName;
  final String phone;

  const AgentProfileScreen({
    super.key,
    required this.agentId,
    required this.agentName,
    required this.phone,
  });

  Future<void> _call(BuildContext context) async {
    if (phone.isEmpty) {
      showSnackBar(context, 'لا يوجد رقم هاتف مسجل لهذا الوكيل',
          backgroundColor: AppColors.error);
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showSnackBar(context, 'تعذر فتح تطبيق الاتصال',
            backgroundColor: AppColors.error);
      }
    } catch (_) {
      if (context.mounted) {
        showSnackBar(context, 'تعذر فتح تطبيق الاتصال',
            backgroundColor: AppColors.error);
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    if (phone.isEmpty) {
      showSnackBar(context, 'لا يوجد رقم واتساب مسجل لهذا الوكيل',
          backgroundColor: AppColors.error);
      return;
    }
    final url = _whatsAppUrl(phone);
    if (url == null) {
      showSnackBar(context, 'رقم الهاتف غير صالح للواتساب',
          backgroundColor: AppColors.error);
      return;
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // WhatsApp not installed – fall back to browser link.
      try {
        await launchUrl(Uri.parse('https://wa.me/'),
            mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          showSnackBar(context, 'تعذر فتح واتساب',
              backgroundColor: AppColors.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Property>>(
        stream: FirestoreService().streamPropertiesByOwner(agentId),
        builder: (context, snapshot) {
          final properties = snapshot.data ?? [];
          final rated = properties.where((p) => p.reviewsCount > 0).toList();
          final avgRating = rated.isEmpty
              ? 0.0
              : rated.map((p) => p.rating * p.reviewsCount).reduce((a, b) => a + b) /
                  rated.map((p) => p.reviewsCount).reduce((a, b) => a + b);
          final totalReviews =
              rated.fold<int>(0, (sum, p) => sum + p.reviewsCount);
          final totalViews =
              properties.fold<int>(0, (sum, p) => sum + p.viewsCount);

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                  child: _buildProfileContent(
                      context, properties.length, totalViews, avgRating, totalReviews)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text('عقارات الوكيل (${properties.length})',
                      style: AppTextStyles.headlineSmall),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )),
                )
              else if (properties.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.home_work_outlined,
                            size: 56, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('لا توجد عقارات منشورة',
                            style: AppTextStyles.titleMedium),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PropertyCard(property: properties[index]),
                      ),
                      childCount: properties.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.6)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: Text(
                      agentName.isNotEmpty ? agentName[0] : '؟',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(agentName,
                      style:
                          AppTextStyles.displaySmall.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, int propertiesCount,
      int totalViews, double avgRating, int totalReviews) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        i < avgRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.warning,
                        size: 22,
                      ),
                    )),
                const SizedBox(width: 8),
                Text(
                  totalReviews > 0 ? avgRating.toStringAsFixed(1) : '-',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.warning),
                ),
                const SizedBox(width: 4),
                Text(totalReviews > 0 ? '($totalReviews تقييم)' : '(لا تقييمات)',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.border),
                  bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _buildStatItem('$propertiesCount', 'عقار'),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildStatItem('$totalViews', 'مشاهدة'),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildStatItem(
                    totalReviews > 0 ? avgRating.toStringAsFixed(1) : '-', 'تقييم'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _call(context),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('اتصال'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openWhatsApp(context),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('واتساب'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
