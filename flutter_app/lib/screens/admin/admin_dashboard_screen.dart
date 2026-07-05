import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'admin_users_screen.dart';
import 'admin_properties_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = false;
  int _totalProps = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final fs = context.read<FirestoreService>();
    try {
      final props = await fs.getAllPropertiesAdmin();
      final users = await fs.streamUsers().first;
      if (mounted) {
        setState(() {
          _totalProps = props.length;
          _totalUsers = users.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _confirmReset(String title, String msg, Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    try {
      await action();
      _loadStats();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم بنجاح'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'لوحة الإدارة'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppConstants.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('لوحة التحكم', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildAdminActions(context),
                  const SizedBox(height: 24),
                  _buildResetSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _statCard('العقارات', '$_totalProps', Icons.home_work_rounded, AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('المستخدمين', '$_totalUsers', Icons.people_rounded, AppColors.success)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    final actions = [
      _AdminAction('إدارة العقارات', Icons.home_work_rounded, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPropertiesScreen()))),
      _AdminAction('إدارة المستخدمين', Icons.people_rounded, AppColors.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()))),
      _AdminAction('التقارير', Icons.description_rounded, AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen()))),
      _AdminAction('إعدادات التطبيق', Icons.settings_rounded, AppColors.accent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen()))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الإجراءات', style: AppTextStyles.titleLarge),
        const SizedBox(height: 16),
        ...actions.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: a.onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: a.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                      child: Icon(a.icon, color: a.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(a.title, style: AppTextStyles.titleMedium)),
                    Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 14),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildResetSection(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تصفير البيانات', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text('تنبيه: هذه الإجراءات لا يمكن التراجع عنها', style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        _resetButton('تصفير المشاهدات', Icons.visibility_off_rounded, AppColors.warning, () => _confirmReset('تصفير المشاهدات', 'هل أنت متأكد من تصفير جميع المشاهدات؟', fs.resetAllViews)),
        const SizedBox(height: 12),
        _resetButton('تصفير المفضلة', Icons.favorite_border_rounded, Colors.pink, () => _confirmReset('تصفير المفضلة', 'هل أنت متأكد من إزالة جميع المفضلة؟', fs.resetAllFavorites)),
        const SizedBox(height: 12),
        _resetButton('حذف جميع العقارات', Icons.delete_sweep_rounded, Colors.red, () => _confirmReset('حذف العقارات', 'هل أنت متأكد من حذف جميع العقارات؟ هذا الإجراء نهائي!', fs.deleteAllProperties)),
      ],
    );
  }

  Widget _resetButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
                Icon(Icons.warning_amber_rounded, color: color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AdminAction(this.title, this.icon, this.color, this.onTap);
}
