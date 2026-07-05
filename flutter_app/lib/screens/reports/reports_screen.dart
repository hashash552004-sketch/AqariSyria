import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../services/firestore_service.dart';
import '../../models/report.dart';
import '../../widgets/custom_app_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'التقارير',
      ),
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          StreamBuilder(
            stream: fs.streamProperties(),
            builder: (context, propSnap) {
              final totalProps = propSnap.data?.length ?? 0;
              return StreamBuilder(
                stream: fs.streamUsers(),
                builder: (context, userSnap) {
                  final totalUsers = userSnap.data?.length ?? 0;
                  return StreamBuilder(
                    stream: fs.streamReports(),
                    builder: (context, reportSnap) {
                      final totalReports = reportSnap.data?.length ?? 0;
                      return Column(
                        children: [
                          _buildStatCards(totalProps, totalUsers, totalReports),
                          const SizedBox(height: 20),
                          _buildRecentReports(reportSnap.data ?? []),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(int properties, int users, int reports) {
    final cards = [
      _StatCard('العقارات', '$properties', Icons.home_work, const Color(0xFF12B76A)),
      _StatCard('المستخدمين', '$users', Icons.people, const Color(0xFFF79009)),
      _StatCard('البلاغات', '$reports', Icons.description, const Color(0xFFF04438)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final c = cards[index];
        return Container(
          padding: const EdgeInsets.all(12),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(c.icon, color: c.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(c.value, style: AppTextStyles.titleLarge),
              const SizedBox(height: 2),
              Text(c.label, style: AppTextStyles.caption),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentReports(List<Report> reports) {
    if (reports.isEmpty) {
      return Container(
        padding: AppConstants.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('لا توجد بلاغات', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    final recent = reports.take(10).toList();
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
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
          Text('آخر البلاغات', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          ...recent.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: r.status == 'resolved' ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    r.status == 'resolved' ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: r.status == 'resolved' ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(r.reason, style: AppTextStyles.bodyMedium),
                ),
                Text(
                  r.status == 'resolved' ? 'تم الحل' : 'معلق',
                  style: AppTextStyles.caption.copyWith(
                    color: r.status == 'resolved' ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'إجمالي البلاغات: ${reports.length}',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
}
