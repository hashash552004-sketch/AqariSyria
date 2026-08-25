import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../core/snackbar_helper.dart';

class VisitRequestsScreen extends StatelessWidget {
  const VisitRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('طلبات المعاينة'),
          backgroundColor: AppColors.cards,
          elevation: 0.5,
          titleTextStyle: AppTextStyles.titleMedium,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'الواردة'),
              Tab(text: 'طلباتي'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _IncomingRequestsTab(),
            _MyRequestsTab(),
          ],
        ),
      ),
    );
  }
}

class _IncomingRequestsTab extends StatelessWidget {
  const _IncomingRequestsTab();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return const Center(child: Text('يجب تسجيل الدخول'));
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<FirestoreService>().streamVisitRequests(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('تعذر تحميل الطلبات', style: AppTextStyles.titleMedium),
                TextButton(onPressed: () {}, child: const Text('إعادة المحاولة')),
              ],
            ),
          );
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.event_busy_rounded, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('لا توجد طلبات معاينة', style: AppTextStyles.titleLarge),
                const SizedBox(height: 6),
                Text('ستظهر هنا طلبات معاينة عقاراتك',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) =>
              _IncomingRequestCard(data: requests[index]),
        );
      },
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _IncomingRequestCard({required this.data});

  Color get _statusColor {
    switch (data['status']?.toString()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return AppColors.error;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return Colors.orange;
    }
  }

  String get _statusLabel {
    switch (data['status']?.toString()) {
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغى';
      default:
        return 'قيد الانتظار';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final date = (data['preferredDate'] as dynamic)?.toDate();
    final dateStr = date != null
        ? DateFormat('EEEE d/M/y – HH:mm', 'ar').format(date)
        : 'غير محدد';
    final isPending = data['status']?.toString() == 'pending';
    final phone = data['requesterPhone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['propertyTitle']?.toString() ?? 'عقار',
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel,
                    style: AppTextStyles.caption.copyWith(color: _statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(data['requesterName']?.toString() ?? 'مستخدم',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(dateStr, style: AppTextStyles.bodyMedium),
            ],
          ),
          if ((data['message']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(data['message'].toString(), style: AppTextStyles.bodyMedium),
                ),
              ],
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await firestore.updateVisitRequestStatus(data['id'].toString(), 'rejected');
                      } catch (_) {
                        if (context.mounted) {
                          showSnackBar(context, 'تعذر تحديث الطلب', backgroundColor: AppColors.error);
                        }
                      }
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      try {
                        await firestore.updateVisitRequestStatus(data['id'].toString(), 'accepted');
                        if (context.mounted) {
                          showSnackBar(context, 'تم قبول الطلب وإشعار الطالب');
                        }
                      } catch (_) {
                        if (context.mounted) {
                          showSnackBar(context, 'تعذر تحديث الطلب', backgroundColor: AppColors.error);
                        }
                      }
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('قبول'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MyRequestsTab extends StatelessWidget {
  const _MyRequestsTab();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return const Center(child: Text('يجب تسجيل الدخول'));
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<FirestoreService>().streamMyVisitRequests(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.schedule_send_outlined, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('لم ترسل أي طلبات', style: AppTextStyles.titleLarge),
                const SizedBox(height: 6),
                Text('اطلب معاينة من صفحة أي عقار',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index];
            final status = data['status']?.toString() ?? 'pending';
            final date = (data['preferredDate'] as dynamic)?.toDate();
            final dateStr = date != null
                ? DateFormat('d/M/y – HH:mm', 'ar').format(date)
                : '';
            final statusColor = status == 'accepted'
                ? Colors.green
                : status == 'rejected'
                    ? AppColors.error
                    : status == 'cancelled'
                        ? AppColors.textSecondary
                        : Colors.orange;
            final statusLabel = status == 'accepted'
                ? 'مقبول'
                : status == 'rejected'
                    ? 'مرفوض'
                    : status == 'cancelled'
                        ? 'ملغى'
                        : 'قيد الانتظار';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['propertyTitle']?.toString() ?? 'عقار',
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('$dateStr • $statusLabel',
                            style: AppTextStyles.caption.copyWith(color: statusColor)),
                      ],
                    ),
                  ),
                  if (status == 'pending')
                    TextButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('إلغاء الطلب'),
                            content: const Text('هل تريد إلغاء طلب المعاينة؟'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('لا')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('نعم، إلغاء')),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          try {
                            await context.read<FirestoreService>().cancelVisitRequest(
                                  data['id'].toString(),
                                  uid,
                                );
                          } catch (_) {
                            if (context.mounted) {
                              showSnackBar(context, 'تعذر الإلغاء', backgroundColor: AppColors.error);
                            }
                          }
                        }
                      },
                      child: const Text('إلغاء',
                          style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
