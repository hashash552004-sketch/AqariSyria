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

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      floatingActionButton: CompareService.compareIds.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComparePropertiesScreen()),
              ),
              label: Text('مقارنة (${CompareService.compareIds.length})'),
              icon: const Icon(Icons.compare_arrows),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cards,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.cairo(),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 26),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_rounded, size: 26, color: AppColors.primary),
              ),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded, size: 26),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.favorite_rounded, size: 26, color: AppColors.primary),
              ),
              label: 'المفضلة',
            ),
            BottomNavigationBarItem(
              icon: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ).createShader(bounds),
                child: Icon(Icons.add_circle_rounded, size: 36, color: Colors.white),
              ),
              activeIcon: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.accent, AppColors.secondary],
                ).createShader(bounds),
                child: Icon(Icons.add_circle_rounded, size: 36, color: Colors.white),
              ),
              label: 'إضافة',
            ),
            BottomNavigationBarItem(
              icon: StreamBuilder<int>(
                stream: context.read<FirestoreService>().streamUnreadConversationCount(context.read<AuthService>().currentUser?.uid ?? ''),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    child: const Icon(Icons.chat_bubble_rounded, size: 26),
                  );
                },
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_rounded, size: 26, color: AppColors.primary),
              ),
              label: 'الرسائل',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 26),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded, size: 26, color: AppColors.primary),
              ),
              label: 'حسابي',
            ),
          ],
        ),
      ),
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

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildPremiumHeader(userName, user?.uid ?? '')),
            SliverToBoxAdapter(child: _buildFeaturedSection(firestore)),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            SliverPadding(
              padding: AppConstants.screenHorizontalPadding,
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('عقارات حديثة', style: AppTextStyles.headlineSmall),
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
            ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: 24),
              sliver: _buildRecentProperties(firestore),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(String userName, String userId) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
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
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أهلاً بك', style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      )),
                      const SizedBox(height: 2),
                      Text(
                        userName.isNotEmpty ? userName : 'عقار اونلاين',
                        style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  StreamBuilder<int>(
                    stream: context.read<FirestoreService>().streamUnreadNotificationCount(userId),
                    builder: (context, snapshot) {
                      final unread = snapshot.data ?? 0;
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              ),
                            ),
                            if (unread > 0)
                              Positioned(
                                top: 4,
                                right: 4,
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
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.8), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'ابحث عن عقار...',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(FirestoreService firestore) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('عقارات مميزة', style: AppTextStyles.headlineSmall),
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
            height: 260,
            child: StreamBuilder<List<Property>>(
              stream: firestore.streamFeaturedProperties(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (_, __) => const SizedBox(
                      width: 280,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: PropertyCardSkeleton(),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                final properties = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: PropertyCard(
                          property: properties[index],
                          onFavorite: () => _toggleFavorite(properties[index]),
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
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final isSelected = _selectedCategory == _categories[index];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = _categories[index]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cards,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    _categories[index],
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
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
              (_, __) => const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: PropertyCardSkeleton(),
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
              return Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: PropertyCard(
                  property: properties[index],
                  isFavorite: _favoriteIds.contains(properties[index].id),
                  onFavorite: () => _toggleFavorite(properties[index]),
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
