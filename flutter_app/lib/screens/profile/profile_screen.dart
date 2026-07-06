import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/app_settings.dart';
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
import '../chat/chat_screen.dart';
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
  String _phone = '';
  String _whatsapp = '';
  String? _profileImage;
  bool _loadingRole = true;


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
      if (mounted) {
        setState(() {
          _userRole = userData?.role ?? 'user';
          _username = userData?.username ?? '';
          _phone = userData?.phone ?? '';
          _whatsapp = userData?.whatsapp ?? '';
          final img = userData?.profileImage;
          _profileImage = (img != null && img.isNotEmpty) ? img : auth.currentUser?.photoURL;
          _loadingRole = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRole = false);
    }
  }

  Future<void> _startCustomerChat(BuildContext context) async {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;
    if (user == null) return;
    final convId = 'support_${user.uid}';
    try {
      final convDoc = await FirebaseFirestore.instance.collection('conversations').doc(convId).get();
      if (!convDoc.exists) {
        final users = await FirebaseFirestore.instance.collection('users').get();
        final admin = users.docs.firstWhere(
          (doc) => doc.data()['role'] == 'admin',
          orElse: () => users.docs.first,
        );
        await firestore.createDirectConversation(
          convId,
          user.uid,
          user.displayName ?? 'مستخدم',
          admin.id,
          admin.data()['fullName'] ?? 'الدعم الفني',
        );
      }
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convId,
              propertyTitle: 'خدمة العملاء',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ'), behavior: SnackBarBehavior.floating),
        );
      }
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
                  _buildFollowUs(context),
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
              if (_phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      _phone,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
              if (_whatsapp.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      _whatsapp,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildFollowUs(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: context.read<FirestoreService>().getSettings(),
      builder: (context, snapshot) {
        final s = snapshot.data;
        if (s == null) return const SizedBox.shrink();
        final defaultWhatsapp = '+963 900 000 000';
        final defaultEmail = 'info@baitalomar.com';
        final items = <_SocialItem>[];
        if (s.instagram.isNotEmpty) items.add(_SocialItem('إنستغرام', Icons.camera_alt_rounded, const Color(0xFFE1306C), 'https://instagram.com/${s.instagram}'));
        if (s.telegram.isNotEmpty) items.add(_SocialItem('تلغرام', Icons.send_rounded, const Color(0xFF0088CC), 'https://t.me/${s.telegram}'));
        if (s.facebook.isNotEmpty) items.add(_SocialItem('فيسبوك', Icons.facebook_rounded, const Color(0xFF1877F2), 'https://facebook.com/${s.facebook}'));
        if (s.whatsapp.isNotEmpty && s.whatsapp != defaultWhatsapp) items.add(_SocialItem('واتساب', Icons.chat_rounded, const Color(0xFF25D366), 'https://wa.me/${s.whatsapp.replaceAll(RegExp(r'[+\s]'), '')}'));
        if (s.email.isNotEmpty && s.email != defaultEmail) items.add(_SocialItem('بريد إلكتروني', Icons.email_rounded, AppColors.primary, 'mailto:${s.email}'));
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 20,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Text('تابعنا', style: AppTextStyles.titleLarge),
                ],
              ),
            ),
            Row(
              children: items.map((item) => Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(item.url);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: item.color.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Icon(item.icon, color: item.color, size: 22),
                        const SizedBox(height: 6),
                        Text(item.label, style: AppTextStyles.caption.copyWith(color: item.color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        );
      },
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
      _MenuItem('خدمة العملاء', Icons.support_agent_rounded, () => _startCustomerChat(context)),
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
            NotificationService().deleteToken(auth.currentUser?.uid ?? '');
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

class _SocialItem {
  final String label;
  final IconData icon;
  final Color color;
  final String url;
  const _SocialItem(this.label, this.icon, this.color, this.url);
}
