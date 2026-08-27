import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/user.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'admin_users_screen.dart';
import 'admin_properties_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  bool _loading = true;

  int _totalProps = 0;
  int _totalUsers = 0;

  Map<String, dynamic> _permissions = {};
  String _role = 'user';

  late final AnimationController _staggerController;
  late final AnimationController _headerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerController.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final fs = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    try {
      final results = await Future.wait([
        fs.getAllPropertiesAdmin(),
        fs.streamUsers().first,
      ]);

      final props = results[0] as List<Property>;
      final users = results[1] as List<dynamic>;

      AppUser? currentUser;
      if (auth.currentUser != null) {
        currentUser = await fs.getUser(auth.currentUser!.uid);
      }

      if (!mounted) return;
      setState(() {
        _totalProps = props.length;
        _totalUsers = users.length;
        _permissions = currentUser?.permissions ?? {};
        _role = currentUser?.role ?? 'user';
        _loading = false;
      });
      _staggerController.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ────────────────────── BUILD ──────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'لوحة الإدارة'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppConstants.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 28),
                    _buildAdminActions(context),
                    const SizedBox(height: 28),
                    if (_role == 'admin') ...[
                      _buildResetSection(context),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ────────────────────── HEADER ──────────────────────

  Widget _buildHeader() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _headerController,
          curve: Curves.easeOutCubic,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لوحة التحكم', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'مرحباً بك في لوحة إدارة التطبيق',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────── STATS GRID ──────────────────────

  Widget _buildStatsGrid() {
    final stats = [
      _StatData(
        label: 'العقارات',
        value: '$_totalProps',
        icon: Icons.apartment_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF1677FF), Color(0xFF4DA3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _StatData(
        label: 'المستخدمين',
        value: '$_totalUsers',
        icon: Icons.groups_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFF79009), Color(0xFFFFD666)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.55,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final delay = index * 0.15;
            final anim = CurvedAnimation(
              parent: _staggerController,
              curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(anim),
                child: _buildStatCard(stats[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: data.gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: data.gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(data.icon, color: Colors.white, size: 21),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: AppTextStyles.displaySmall.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              Text(data.label, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────── ADMIN ACTIONS ──────────────────────

  Widget _buildAdminActions(BuildContext context) {
    final actions = <_AdminAction>[];

    if (_permissions['review_properties'] == true) {
      actions.add(_AdminAction(
        'مراجعة العقارات',
        Icons.home_work_rounded,
        AppColors.primary,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminPropertiesScreen())),
      ));
    }

    if (_role == 'admin') {
      actions.add(_AdminAction(
        'إدارة المستخدمين',
        Icons.people_rounded,
        AppColors.success,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
      ));
    }

    if (_permissions['review_reports'] == true) {
      actions.add(_AdminAction(
        'مراجعة البلاغات',
        Icons.flag_rounded,
        AppColors.warning,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminReportsScreen())),
      ));
    }

    if (_permissions['view_reports'] == true) {
      actions.add(_AdminAction(
        'التقارير والإحصائيات',
        Icons.analytics_rounded,
        const Color(0xFF76C7FF),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen())),
      ));
    }

    if (_role == 'admin') {
      actions.add(_AdminAction(
        'إعدادات التطبيق',
        Icons.settings_rounded,
        AppColors.accent,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الإجراءات', style: AppTextStyles.titleLarge),
        const SizedBox(height: 14),
        ...actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final delay = index * 0.1;
          final anim = CurvedAnimation(
            parent: _staggerController,
            curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
                curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(anim),
              child: _buildActionCard(action),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionCard(_AdminAction action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          onTap: action.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: action.color, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    action.title,
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────── RESET SECTION ──────────────────────

  Widget _buildResetSection(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تصفير البيانات', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text(
          'تنبيه: هذه الإجراءات لا يمكن التراجع عنها',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 14),
        _resetButton(
          'تصفير المشاهدات',
          Icons.visibility_off_rounded,
          AppColors.warning,
          () => _confirmReset(
            'تصفير المشاهدات',
            'هل أنت متأكد من تصفير جميع المشاهدات؟',
            fs.resetAllViews,
          ),
        ),
        const SizedBox(height: 12),
        _resetButton(
          'تصفير المفضلة',
          Icons.favorite_border_rounded,
          Colors.pink,
          () => _confirmReset(
            'تصفير المفضلة',
            'هل أنت متأكد من إزالة جميع المفضلة؟',
            fs.resetAllFavorites,
          ),
        ),
        const SizedBox(height: 12),
        _resetButton(
          'حذف جميع العقارات',
          Icons.delete_sweep_rounded,
          AppColors.error,
          () => _confirmReset(
            'حذف العقارات',
            'هل أنت متأكد من حذف جميع العقارات؟ هذا الإجراء نهائي!',
            fs.deleteAllProperties,
          ),
        ),
      ],
    );
  }

  Widget _resetButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title, style: AppTextStyles.titleMedium),
                ),
                Icon(Icons.warning_amber_rounded, color: color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(
    String title,
    String msg,
    Future<void> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
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
      await _loadStats();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ────────────────────── DATA MODELS ──────────────────────

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}

class _AdminAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminAction(this.title, this.icon, this.color, this.onTap);
}
