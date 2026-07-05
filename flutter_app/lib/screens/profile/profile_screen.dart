import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../favorites/favorites_screen.dart';
import '../my_properties/my_properties_screen.dart';
import '../compare/compare_properties_screen.dart';
import '../favorites/saved_searches_screen.dart';
import '../recently_viewed/recently_viewed_screen.dart';
import '../notifications/notifications_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../reports/reports_screen.dart';
import 'settings_screen.dart';
import 'contact_us_screen.dart';
import 'about_screen.dart';
import 'edit_profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userRole = 'user';
  String _username = '';
  String? _profileImage;
  bool _loadingRole = true;
  int _propertyCount = 0;
  int _favoritesCount = 0;
  int _totalViews = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingRole = false);
      return;
    }
    try {
      final userData = await fs.getUser(uid);
      final props = await FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: uid)
          .get();
      int views = 0;
      for (final doc in props.docs) {
        views += (doc.data()['viewsCount'] as num?)?.toInt() ?? 0;
      }
      if (mounted) {
        setState(() {
          _userRole = userData?.role ?? 'user';
          _username = userData?.username ?? '';
          final img = userData?.profileImage;
          _profileImage = (img != null && img.isNotEmpty) ? img : auth.currentUser?.photoURL;
          _propertyCount = props.docs.length;
          _favoritesCount = userData?.favorites.length ?? 0;
          _totalViews = views;
          _loadingRole = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGradientHeader(context, user),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildStatsRow(context),
                  const SizedBox(height: 24),
                  _buildMenuSection(context),
                  const SizedBox(height: 24),
                  _buildLogoutButton(context, auth),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4DA3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                      _loadUserData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'الملف الشخصي',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _profileImage != null
                          ? Image.network(
                              _profileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
                            )
                          : _defaultAvatar(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'مستخدم',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _username.isNotEmpty ? '@$_username' : '',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.white.withValues(alpha: 0.3),
      child: const Icon(
        Icons.person_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('العقارات', '$_propertyCount', Icons.home_work_rounded, AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('المفضلة', '$_favoritesCount', Icons.favorite_rounded, AppColors.error)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('المشاهدات', '$_totalViews', Icons.visibility_rounded, AppColors.warning)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(18),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      _MenuItem('عقاراتي', Icons.home_work_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPropertiesScreen()))),
      _MenuItem('المفضلة', Icons.favorite_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
      _MenuItem('العقارات المقترحة', Icons.compare_arrows_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparePropertiesScreen()))),
      _MenuItem('عمليات البحث المحفوظة', Icons.search_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedSearchesScreen()))),
      _MenuItem('تمت المشاهدة مؤخراً', Icons.history_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyViewedScreen()))),
      _MenuItem('الإشعارات', Icons.notifications_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
      _MenuItem('الإعدادات', Icons.settings_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      _MenuItem('تواصل معنا', Icons.headset_mic_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen()))),
      _MenuItem('حول التطبيق', Icons.info_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
    ];

    if (!_loadingRole && (_userRole == 'admin' || _userRole == 'moderator')) {
      menuItems.insert(0, _MenuItem('لوحة الإدارة', Icons.admin_panel_settings_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))));
      menuItems.insert(1, _MenuItem('الإحصائيات', Icons.bar_chart_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()))));
      menuItems.insert(2, _MenuItem('التقارير', Icons.description_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))));
    }

    return Container(
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
        children: List.generate(menuItems.length, (index) {
          final item = menuItems[index];
          final isLast = index == menuItems.length - 1;
          return Column(
            children: [
              _buildMenuItem(item),
              if (!isLast) const Divider(height: 1, indent: 56, endIndent: 0),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 15,
                  ),
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
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService auth) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('تسجيل الخروج'),
              content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await auth.signOut();
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'تسجيل الخروج',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _MenuItem(this.title, this.icon, this.onTap);
}
