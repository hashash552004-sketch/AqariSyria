import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/property_card.dart';
import '../../widgets/custom_app_bar.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;
  String _lastFavKey = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;

    return Scaffold(
      appBar: const CustomAppBar(title: 'المفضلة'),
      body: uid == null
          ? const Center(child: Text('يرجى تسجيل الدخول'))
          : _buildBody(context, uid),
    );
  }

  Widget _buildBody(BuildContext context, String uid) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.streamUserFavorites(uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting && _properties.isEmpty) {
          return _buildSkeletonGrid();
        }

        final data = userSnapshot.data?.data() as Map<String, dynamic>?;
        final favoriteIds =
            (data?['favorites'] as List?)?.map((e) => e.toString()).toList() ??
                <String>[];

        if (favoriteIds.isEmpty) {
          if (_properties.isNotEmpty || _lastFavKey.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() { _properties = []; _lastFavKey = ''; });
            });
          }
          return const _EmptyFavorites();
        }

        final newKey = favoriteIds.join(',');
        if (newKey != _lastFavKey) {
          _lastFavKey = newKey;
          _fetchProperties(context, firestore, favoriteIds);
        }

        if (_isLoading && _properties.isEmpty) {
          return _buildSkeletonGrid();
        }

        if (_properties.isEmpty && !_isLoading) {
          return const _EmptyFavorites();
        }

        return RefreshIndicator(
          onRefresh: () async {
            _lastFavKey = '';
            await _fetchProperties(context, firestore, favoriteIds);
          },
          child: GridView.builder(
            padding: AppConstants.screenPadding,
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _properties.length,
            itemBuilder: (context, index) {
              final property = _properties[index];
              return GestureDetector(
                onLongPress: () =>
                    _toggleFavorite(context, uid, property.id),
                child: PropertyCard(
                  property: property,
                  isFavorite: true,
                  onFavorite: () =>
                      _toggleFavorite(context, uid, property.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: AppConstants.screenPadding,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160, color: AppColors.shimmerBase),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 120, color: AppColors.shimmerBase),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 200, color: AppColors.shimmerBase),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchProperties(
    BuildContext context,
    FirestoreService firestore,
    List<String> ids,
  ) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final properties = await firestore.getPropertiesByIds(ids);
    if (!mounted) return;
    setState(() {
      _properties = properties;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite(
      BuildContext context, String uid, String propertyId) async {
    try {
      await context.read<FirestoreService>().toggleFavorite(uid, propertyId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppConstants.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد عقارات مفضلة',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'قم بإضافة عقارات إلى المفضلة\nلمتابعة أحدث العروض',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
