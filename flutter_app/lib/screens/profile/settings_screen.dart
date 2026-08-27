import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _emailNotifications = true;
  bool _showOnlineStatus = true;
  String _cacheSize = '12.4 MB';

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'الإعدادات'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSection(
              'العامة',
              [
                _buildSwitchItem(
                  icon: Icons.dark_mode_rounded,
                  iconColor: AppColors.warning,
                  title: 'الوضع المظلم',
                  subtitle: 'تفعيل المظهر الداكن',
                  value: themeProvider.isDarkMode,
                  onChanged: (v) => themeProvider.setDarkMode(v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'الإشعارات',
              [
                _buildSwitchItem(
                  icon: Icons.notifications_rounded,
                  iconColor: AppColors.primary,
                  title: 'إشعارات التطبيق',
                  subtitle: 'تلقي الإشعارات العامة',
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                _buildSwitchItem(
                  icon: Icons.email_rounded,
                  iconColor: AppColors.secondary,
                  title: 'الإشعارات البريدية',
                  subtitle: 'تلقي التحديثات عبر البريد',
                  value: _emailNotifications,
                  onChanged: (v) => setState(() => _emailNotifications = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'الخصوصية',
              [
                _buildSwitchItem(
                  icon: Icons.visibility_rounded,
                  iconColor: AppColors.success,
                  title: 'إظهار الحالة',
                  subtitle: 'السماح للآخرين برؤية حالتك',
                  value: _showOnlineStatus,
                  onChanged: (v) => setState(() => _showOnlineStatus = v),
                ),
                _buildSettingItem(
                  icon: Icons.shield_rounded,
                  iconColor: AppColors.primary,
                  title: 'سياسة الخصوصية',
                  trailing: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
                _buildSettingItem(
                  icon: Icons.description_rounded,
                  iconColor: AppColors.textSecondary,
                  title: 'شروط الاستخدام',
                  trailing: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'الحساب',
              [
                _buildSettingItem(
                  icon: Icons.switch_account_rounded,
                  iconColor: AppColors.primary,
                  title: 'تبديل الحساب',
                  subtitle: 'التبديل إلى حساب آخر محفوظ',
                  trailing: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  onTap: () => _switchAccount(),
                ),
                _buildSettingItem(
                  icon: Icons.delete_forever_rounded,
                  iconColor: AppColors.error,
                  title: 'حذف الحساب',
                  subtitle: 'حذف حسابك نهائياً وجميع بياناتك',
                  trailing: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'التخزين',
              [
                _buildSettingItem(
                  icon: Icons.cleaning_services_rounded,
                  iconColor: AppColors.warning,
                  title: 'مسح الذاكرة المؤقتة',
                  subtitle: 'مسح بيانات التطبيق المخزنة',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _cacheSize,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  onTap: () => _clearCache(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'الإصدار 1.0.0',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 12),
          child: Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
        ),
        Container(
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
            children: List.generate(items.length, (index) {
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  items[index],
                  if (!isLast) const Divider(height: 1, indent: 56, endIndent: 16),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 15)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح الذاكرة المؤقتة'),
        content: const Text('سيتم مسح جميع البيانات المخزنة مؤقتاً. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              imageCache.clear();
              setState(() => _cacheSize = '0 B');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم مسح الذاكرة المؤقتة'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text('تأكيد', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text('هل أنت متأكد من حذف حسابك نهائياً؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final passwordController = TextEditingController();
    final reAuthConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الهوية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل كلمة المرور للتأكيد'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تأكيد', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (reAuthConfirmed != true || !context.mounted) return;

    try {
      final auth = context.read<AuthService>();
      final fs = context.read<FirestoreService>();
      final uid = auth.currentUser?.uid ?? '';
      final email = auth.currentUser?.email ?? '';

      await auth.reAuthenticate(email, passwordController.text);
      passwordController.dispose();

      await fs.deleteUser(uid);
      await auth.deleteFirebaseUser();
      await auth.signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _switchAccount() async {
    final auth = context.read<AuthService>();
    final currentEmail = auth.currentUser?.email ?? '';
    final prefs = await SharedPreferences.getInstance();
    final savedAccounts = prefs.getStringList('saved_accounts') ?? <String>[];
    final savedPasswords = prefs.getStringList('saved_passwords') ?? <String>[];

    if (savedAccounts.isEmpty || savedAccounts.length <= 1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد حسابات محفوظة أخرى للتبديل'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('تبديل الحساب', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            ...List.generate(savedAccounts.length, (i) {
              final email = savedAccounts[i];
              final isCurrent = email == currentEmail;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCurrent ? Icons.check_circle_rounded : Icons.person_rounded,
                    color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                title: Text(email),
                subtitle: isCurrent ? const Text('الحساب الحالي') : null,
                trailing: isCurrent
                    ? null
                    : Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary, size: 14),
                onTap: isCurrent ? null : () => Navigator.pop(ctx, email),
              );
            }),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.primary),
              ),
              title: const Text('إضافة حساب جديد'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null) {
      if (!context.mounted) return;
      await auth.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    final idx = savedAccounts.indexOf(selected);
    if (idx == -1 || idx >= savedPasswords.length) return;
    final password = savedPasswords[idx];

    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري التبديل...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await auth.signInEmailPassword(selected, password);
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تسجيل الدخول: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
