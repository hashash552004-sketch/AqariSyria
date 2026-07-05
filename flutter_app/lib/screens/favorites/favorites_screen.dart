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
import '../../widgets/loading_skeleton.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data =
            userSnapshot.data?.data() as Map<String, dynamic>?;
        final favoriteIds = (data?['favorites'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];

        if (favoriteIds.isEmpty) {
          return const _EmptyFavorites();
        }

        return StreamBuilder<List<Property>>(
          stream: context.read<FirestoreService>().streamProperties(),
          builder: (context, propSnapshot) {
            if (propSnapshot.connectionState == ConnectionState.waiting) {
              return GridView.builder(
                padding: AppConstants.screenPadding,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 2 : 1,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 4,
                itemBuilder: (_, __) => const PropertyCardSkeleton(),
              );
            }
            final allProperties = propSnapshot.data ?? [];
            final favorites =
                allProperties.where((p) => favoriteIds.contains(p.id)).toList();

            if (favorites.isEmpty) {
              return const _EmptyFavorites();
            }

            return GridView.builder(
              padding: AppConstants.screenPadding,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 2 : 1,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final property = favorites[index];
                return GestureDetector(
                  onLongPress: () =>
                      _toggleFavorite(context, uid, property.id),
                  child: PropertyCard(
                    property: property,
                    onFavorite: () =>
                        _toggleFavorite(context, uid, property.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
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
