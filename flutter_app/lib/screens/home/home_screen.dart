import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/compare_service.dart';
import '../../widgets/property_card.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/animated_widgets.dart';
import '../search/search_screen.dart';
import '../favorites/favorites_screen.dart';
import '../add_property/add_property_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/conversations_screen.dart';
import '../compare/compare_properties_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _switchToHomeTab() {
    setState(() => _selectedIndex = 0);
  }

  void _handleCompare(String propertyId) {
    CompareService.toggle(propertyId);
    final isAdding = CompareService.isInCompare(propertyId);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAdding ? 'تمت الإضافة للمقارنة' : 'تمت الإزالة من المقارنة'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      _HomeTab(onCompare: _handleCompare),
      const FavoritesScreen(),
      AddPropertyScreen(onBackToHome: _switchToHomeTab),
      const ConversationsScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        floatingActionButton: CompareService.compareIds.length >= 2
            ? ScaleIn(
                child: FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ComparePropertiesScreen()),
                  ),
                  label: Text('مقارنة (${CompareService.compareIds.length})'),
                  icon: const Icon(Icons.compare_arrows),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              )
            : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.cards,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.cairo(),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_rounded, size: 26),
                  activeIcon: _ActiveTabIcon(icon: Icons.home_rounded),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.favorite_rounded, size: 26),
                  activeIcon: _ActiveTabIcon(icon: Icons.favorite_rounded),
                  label: 'المفضلة',
                ),
                BottomNavigationBarItem(
                  icon: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ).createShader(bounds),
                    child: const Icon(Icons.add_circle_rounded, size: 36, color: Colors.white),
                  ),
                  activeIcon: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppColors.accent, AppColors.secondary],
                    ).createShader(bounds),
                    child: const Icon(Icons.add_circle_rounded, size: 36, color: Colors.white),
                  ),
                  label: 'إضافة',
                ),
                BottomNavigationBarItem(
                  icon: StreamBuilder<int>(
                    stream: context.read<FirestoreService>().streamUnreadConversationCount(
                      context.read<AuthService>().currentUser?.uid ?? '',
                    ),
                    builder: (context, snap) {
                      final count = snap.data ?? 0;
                      return Badge(
                        isLabelVisible: count > 0,
                        label: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
                        child: const Icon(Icons.chat_bubble_rounded, size: 26),
                      );
                    },
                  ),
                  activeIcon: _ActiveTabIcon(icon: Icons.chat_bubble_rounded),
                  label: 'الرسائل',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_rounded, size: 26),
                  activeIcon: _ActiveTabIcon(icon: Icons.person_rounded),
                  label: 'حسابي',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveTabIcon extends StatelessWidget {
  final IconData icon;
  const _ActiveTabIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 26, color: AppColors.primary),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final void Function(String)? onCompare;
  const _HomeTab({this.onCompare});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _selectedCategory = 'الكل';
  final List<String> _categories = ['الكل', 'شقة', 'فيلا', 'منزل', 'أرض'];
  Set<String> _favoriteIds = {};
  StreamSubscription? _favSubscription;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _scrollController.addListener(() {
      if (mounted) setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFavorites() {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;
    if (user == null) return;
    _favSubscription = firestore.streamUserFavorites(user.uid).listen((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      final ids = (data?['favorites'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{};
      if (mounted) setState(() => _favoriteIds = ids);
    });
  }

  Future<void> _toggleFavorite(Property property) async {
    try {
      final auth = context.read<AuthService>();
      final firestore = context.read<FirestoreService>();
      final user = auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      final appUser = await firestore.getUser(user.uid);
      final wasFav = appUser?.favorites.contains(property.id) ?? false;
      await firestore.toggleFavorite(user.uid, property.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasFav ? 'تمت الإزالة من المفضلة' : 'تمت الإضافة إلى المفضلة'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    final userName = user?.displayName ?? '';
    final parallaxFactor = (_scrollOffset / 300).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
            SliverToBoxAdapter(
              child: FadeInSlide(
                offset: const Offset(0, -30),
                duration: const Duration(milliseconds: 600),
                child: _buildPremiumHeader(userName, user?.uid ?? '', parallaxFactor),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeInSlide(
                delay: 150,
                offset: const Offset(30, 0),
                child: _buildFeaturedSection(firestore),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeInSlide(delay: 250, child: _buildCategoryChips()),
            ),
            SliverPadding(
              padding: AppConstants.screenHorizontalPadding,
              sliver: SliverToBoxAdapter(
                child: FadeInSlide(
                  delay: 350,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('عقارات حديثة', style: AppTextStyles.headlineSmall),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        ),
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        label: Text('عرض الكل', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: _buildRecentProperties(firestore),
            ),
          ],
        ),
    );
  }

  Widget _buildPremiumHeader(String userName, String userId, double parallaxFactor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary, AppColors.accent],
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName.isNotEmpty ? userName : 'عقار اونلاين',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<int>(
                    stream: context.read<FirestoreService>().streamUnreadNotificationCount(userId),
                    builder: (context, snapshot) {
                      final unread = snapshot.data ?? 0;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Center(
                                child: Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                              ),
                              if (unread > 0)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GlowPulse(
                                    glowColor: AppColors.error,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.85), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ابحث عن عقارك المثالي...',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.tune_rounded, color: Colors.white.withValues(alpha: 0.8), size: 18),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 17) return 'مساء الخير 🌤️';
    if (hour < 21) return 'مساء الخير 🌙';
    return 'مساء الخير 🌙';
  }

  Widget _buildFeaturedSection(FirestoreService firestore) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
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
                    Text('عقارات مميزة', style: AppTextStyles.headlineSmall),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                  child: Text('عرض الكل', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 270,
            child: StreamBuilder<List<Property>>(
              stream: firestore.streamFeaturedProperties(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (_, i) => SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: ScaleIn(delay: i * 100, beginScale: 0.9, child: const PropertyCardSkeleton()),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                final properties = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    return ScaleIn(
                      delay: index * 80,
                      duration: const Duration(milliseconds: 500),
                      child: SizedBox(
                        width: 280,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: PropertyCard(
                            property: properties[index],
                            onFavorite: () => _toggleFavorite(properties[index]),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final isSelected = _selectedCategory == _categories[index];
            return ScaleIn(
              delay: index * 50,
              beginScale: 0.8,
              duration: const Duration(milliseconds: 400),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = _categories[index]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          )
                        : null,
                    color: isSelected ? null : AppColors.cards,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.border,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _categories[index],
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentProperties(FirestoreService firestore) {
    return StreamBuilder<List<Property>>(
      stream: firestore.streamProperties(
        type: _selectedCategory == 'الكل' ? null : _selectedCategory,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => FadeInSlide(
                delay: i * 100,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: PropertyCardSkeleton(),
                ),
              ),
              childCount: 3,
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            child: EmptyStateWidget(
              icon: Icons.home_work_outlined,
              title: 'لا توجد عقارات',
              subtitle: 'ستظهر العقارات هنا عند توفرها',
            ),
          );
        }
        final properties = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return FadeInSlide(
                delay: index * 80,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: PropertyCard(
                    property: properties[index],
                    isFavorite: _favoriteIds.contains(properties[index].id),
                    onFavorite: () => _toggleFavorite(properties[index]),
                  ),
                ),
              );
            },
            childCount: properties.length,
          ),
        );
      },
    );
  }
}
