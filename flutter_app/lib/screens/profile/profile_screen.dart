import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/app_settings.dart';
import '../../widgets/animated_widgets.dart';
import '../favorites/favorites_screen.dart';
import '../my_properties/my_properties_screen.dart';
import '../visit/visit_requests_screen.dart';
import '../compare/compare_properties_screen.dart';
import '../favorites/saved_searches_screen.dart';
import '../recently_viewed/recently_viewed_screen.dart';
import '../notifications/notifications_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'my_stats_screen.dart';
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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String _userRole = 'user';
  String _username = '';
  String _phone = '';
  String _whatsapp = '';
  String? _profileImage;
  bool _loadingRole = true;
  late AnimationController _headerAnimController;
  late Animation<double> _avatarScale;
  late Animation<double> _avatarRotation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _avatarRotation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _headerAnimController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
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
    } catch (e) {
      debugPrint('_loadUserData error: $e');
      if (mounted) setState(() => _loadingRole = false);
    }
  }

  Future<void> _startCustomerChat(BuildContext context) async {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سجل دخول أولاً'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    final convId = 'support_${user.uid}';
    try {
      final convDoc = await firestore.getConversationDoc(convId);
      if (convDoc == null || !convDoc.exists) {
        final adminId = await firestore.getAdminId();
        if (adminId == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لا يوجد مشرفون متاحون'), behavior: SnackBarBehavior.floating),
            );
          }
          return;
        }
        final adminName = await firestore.getUserName(adminId) ?? 'الدعم الفني';
        await firestore.createDirectConversation(
          convId, user.uid, user.displayName ?? 'مستخدم', adminId, adminName,
        );
      }
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversationId: convId, propertyTitle: 'خدمة العملاء'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), behavior: SnackBarBehavior.floating),
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
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildPremiumHeader(context, user),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  FadeInSlide(delay: 300, child: _buildFollowUs(context)),
                  const SizedBox(height: 24),
                  FadeInSlide(delay: 450, child: _buildMenuSection(context)),
                  const SizedBox(height: 24),
                  FadeInSlide(delay: 600, child: _buildLogoutButton(context, auth)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ScaleIn(
                    delay: 100,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        );
                        _loadUserData();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  FadeInSlide(
                    offset: const Offset(0, -20),
                    child: Text(
                      'الملف الشخصي',
                      style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                    ),
                  ),
                  ScaleIn(
                    delay: 150,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.settings, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _avatarScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _avatarScale.value,
                    child: Transform.rotate(
                      angle: _avatarRotation.value,
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GlowPulse(
                      glowColor: Colors.white,
                      duration: const Duration(milliseconds: 2500),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
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
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeInSlide(
                delay: 400,
                child: Text(
                  user?.displayName ?? 'مستخدم',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeInSlide(
                delay: 450,
                child: Text(
                  _username.isNotEmpty ? '@$_username' : '',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (_phone.isNotEmpty)
                FadeInSlide(
                  delay: 500,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          _phone,
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_whatsapp.isNotEmpty)
                FadeInSlide(
                  delay: 550,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          _whatsapp,
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
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
      color: Colors.white.withValues(alpha: 0.25),
      child: const Icon(Icons.person_rounded, size: 48, color: Colors.white),
    );
  }

  Widget _buildFollowUs(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: context.read<FirestoreService>().getSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final s = snapshot.data;
        if (s == null) return const SizedBox.shrink();
        final defaultWhatsapp = '+963 900 000 000';
        final defaultEmail = 'info@baitalomar.com';
        String clean(String v) {
          var h = v.trim();
          h = h.replaceFirst(RegExp(r'^@+'), '');
          final match = RegExp(r'(?:https?://)?(?:www\.)?[a-z]+\.[a-z.]+/(@?[A-Za-z0-9_.]+)$')
              .firstMatch(h);
          if (match != null) h = match.group(1)!;
          return h.replaceFirst(RegExp(r'^@+'), '');
        }

        final items = <_SocialItem>[];
        if (s.instagram.isNotEmpty) items.add(_SocialItem('إنستغرام', Icons.camera_alt_rounded, const Color(0xFFE1306C), 'https://instagram.com/${clean(s.instagram)}'));
        if (s.telegram.isNotEmpty) items.add(_SocialItem('تلغرام', Icons.send_rounded, const Color(0xFF0088CC), 'https://t.me/${clean(s.telegram)}'));
        if (s.facebook.isNotEmpty) items.add(_SocialItem('فيسبوك', Icons.facebook_rounded, const Color(0xFF1877F2), 'https://facebook.com/${clean(s.facebook)}'));
        if (s.tiktok.isNotEmpty) items.add(_SocialItem('تيك توك', Icons.music_note_rounded, const Color(0xFF000000), 'https://tiktok.com/@${clean(s.tiktok)}'));
        if (s.whatsapp.isNotEmpty && s.whatsapp != defaultWhatsapp) {
          final wa = s.whatsapp.replaceAll(RegExp(r'[^\d]'), '');
          if (wa.startsWith('00')) {
            items.add(_SocialItem('واتساب', Icons.chat_rounded, const Color(0xFF25D366), 'https://wa.me/${wa.substring(2)}'));
          } else if (wa.startsWith('0')) {
            items.add(_SocialItem('واتساب', Icons.chat_rounded, const Color(0xFF25D366), 'https://wa.me/963${wa.substring(1)}'));
          } else {
            items.add(_SocialItem('واتساب', Icons.chat_rounded, const Color(0xFF25D366), 'https://wa.me/$wa'));
          }
        }
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
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('تابعنا', style: AppTextStyles.titleLarge),
                ],
              ),
            ),
            Row(
              children: items.asMap().entries.map((entry) {
                final item = entry.value;
                final idx = entry.key;
                return Expanded(
                  child: ScaleIn(
                    delay: 600 + idx * 80,
                    child: GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(item.url);
                        if (uri == null) return;
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('لا يمكن فتح الرابط، تأكد من تثبيت التطبيق'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
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
                            Text(item.label, style: AppTextStyles.caption.copyWith(
                              color: item.color, fontWeight: FontWeight.w600,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      _MenuItem('عقاراتي', Icons.home_work_rounded, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPropertiesScreen()))),
      _MenuItem('طلبات المعاينة', Icons.event_available_rounded, AppColors.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitRequestsScreen()))),
      _MenuItem('المفضلة', Icons.favorite_rounded, AppColors.error, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
      _MenuItem('العقارات المقترحة', Icons.compare_arrows_rounded, AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparePropertiesScreen()))),
      _MenuItem('عمليات البحث المحفوظة', Icons.bookmark_rounded, const Color(0xFF8B5CF6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedSearchesScreen()))),
      _MenuItem('تمت المشاهدة مؤخراً', Icons.history_rounded, const Color(0xFFEC4899), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyViewedScreen()))),
      _MenuItem('الإشعارات', Icons.notifications_rounded, const Color(0xFFF59E0B), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
      _MenuItem('الإحصائيات', Icons.bar_chart_rounded, const Color(0xFF06B6D4), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyStatsScreen()))),
      _MenuItem('الإعدادات', Icons.settings_rounded, AppColors.textSecondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      _MenuItem('تواصل معنا', Icons.headset_mic_rounded, const Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen()))),
      _MenuItem('خدمة العملاء', Icons.support_agent_rounded, const Color(0xFF3B82F6), () => _startCustomerChat(context)),
      _MenuItem('حول التطبيق', Icons.info_rounded, AppColors.textSecondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
    ];

    if (!_loadingRole && (_userRole == 'admin' || _userRole == 'moderator')) {
      menuItems.insert(0, _MenuItem('لوحة الإدارة', Icons.admin_panel_settings_rounded, const Color(0xFFEF4444), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(menuItems.length, (index) {
          final item = menuItems[index];
          final isLast = index == menuItems.length - 1;
          return FadeInSlide(
            delay: 500 + index * 50,
            offset: const Offset(30, 0),
            child: Column(
              children: [
                _buildMenuItem(item, index),
                if (!isLast) Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 0,
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: item.onTap,
        splashColor: item.iconColor.withValues(alpha: 0.08),
        highlightColor: item.iconColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary,
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService auth) {
    return ScaleIn(
      delay: 700,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('تسجيل الخروج'),
                content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
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
              border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
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
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _MenuItem(this.title, this.icon, this.iconColor, this.onTap);
}

class _SocialItem {
  final String label;
  final IconData icon;
  final Color color;
  final String url;
  const _SocialItem(this.label, this.icon, this.color, this.url);
}
