import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../add_property/add_property_screen.dart';
import '../reports/reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'لوحة التحكم',
        showBack: false,
      ),
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          StreamBuilder(
            stream: fs.streamProperties(),
            builder: (context, snap) {
              final totalProps = snap.data?.length ?? 0;
              return StreamBuilder(
                stream: fs.streamUsers(),
                builder: (context, userSnap) {
                  final totalUsers = userSnap.data?.length ?? 0;
                  final activeProps = snap.data?.where((p) => p.isActive).length ?? 0;
                  return _buildSummaryCards(totalProps, activeProps, totalUsers);
                },
              );
            },
          ),
          const SizedBox(height: 24),
          _buildQuickActions(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int totalProps, int activeProps, int totalUsers) {
    final cards = [
      _SummaryCard('إجمالي العقارات', '$totalProps', Icons.home_work, AppColors.primary),
      _SummaryCard('العقارات النشطة', '$activeProps', Icons.check_circle, AppColors.success),
      _SummaryCard('المستخدمين', '$totalUsers', Icons.people, AppColors.warning),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final c = cards[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(c.icon, color: c.color, size: 20),
              ),
              const Spacer(),
              Text(c.value, style: AppTextStyles.titleLarge.copyWith(fontSize: 22)),
              const SizedBox(height: 2),
              Text(c.label, style: AppTextStyles.bodySmall),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إجراءات سريعة', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _actionCard(Icons.add_home_work, 'إضافة عقار', AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())))),
            const SizedBox(width: 12),
            Expanded(child: _actionCard(Icons.assessment, 'عرض التقارير', AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())))),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(this.label, this.value, this.icon, this.color);
}
