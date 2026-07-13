import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_app_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'حول التطبيق'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAppLogo(context),
            const SizedBox(height: 24),
            _buildAppInfo(),
            const SizedBox(height: 24),
            _buildDescription(),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_work_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppConstants.appName,
          style: AppTextStyles.displaySmall.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'الإصدار 1.0.0',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.info_outline_rounded, 'الاسم', AppConstants.appName),
          const Divider(height: 20),
          _buildInfoRow(Icons.code_rounded, 'الإصدار', '1.0.0'),
          const Divider(height: 20),
          _buildInfoRow(Icons.smartphone_rounded, 'نظام التشغيل', 'Android & iOS'),
          const Divider(height: 20),
          _buildInfoRow(Icons.update_rounded, 'آخر تحديث', 'يوليو 2026'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodyMedium),
        const Spacer(),
        Text(value, style: AppTextStyles.titleMedium.copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عن التطبيق',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'عقار اونلاين هو تطبيق عقاري سوري يهدف إلى تسهيل عملية البحث عن العقارات'
            ' سواء للبيع أو الإيجار. نوفر لك أحدث العروض العقارية من جميع المحافظات'
            ' السورية مع إمكانية التواصل المباشر مع المالكين والوسطاء العقاريين.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'مهمتنا هي مساعدتك في العثور على منزل أحلامك بكل سهولة وثقة.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          text: 'تقييم التطبيق',
          width: double.infinity,
          icon: Icons.star_rounded,
          onPressed: () async {
            final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.baitalomar.app');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لا يمكن فتح متجر التطبيقات'), behavior: SnackBarBehavior.floating),
              );
            }
          },
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _shareApp(context),
            icon: const Icon(Icons.share_rounded, size: 20),
            label: Text(
              'مشاركة التطبيق',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.cards,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _shareApp(BuildContext context) {
    Share.share('حمّل تطبيق ${AppConstants.appName} عبر الرابط: https://baitalomar.app');
  }
}

