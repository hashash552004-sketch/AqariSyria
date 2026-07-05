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

class RecentlyViewedScreen extends StatelessWidget {
  const RecentlyViewedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'تمت المشاهدة مؤخراً',
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => _clearAll(context, uid),
              child: Text(
                'مسح الكل',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
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
        final viewedRaw = data?['recentlyViewed'] as List? ?? [];
        final viewedIds = viewedRaw
            .map((e) => e is Map ? e['propertyId']?.toString() ?? '' : e.toString())
            .where((id) => id.isNotEmpty)
            .toList();

        if (viewedIds.isEmpty) {
          return const _EmptyRecentlyViewed();
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
            final viewed = allProperties
                .where((p) => viewedIds.contains(p.id))
                .toList();

            if (viewed.isEmpty) {
              return const _EmptyRecentlyViewed();
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
              itemCount: viewed.length,
              itemBuilder: (context, index) {
                return PropertyCard(property: viewed[index]);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _clearAll(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'recentlyViewed': []});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}

class _EmptyRecentlyViewed extends StatelessWidget {
  const _EmptyRecentlyViewed();

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
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد عقارات تمت مشاهدتها',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'العقارات التي تتصفحها ستظهر هنا',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
