import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/user.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_app_bar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'إدارة المستخدمين'),
      body: Column(
        children: [
          Padding(
            padding: AppConstants.screenHorizontalPadding,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'بحث عن مستخدم...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _firestore.streamUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('لا يوجد مستخدمين', style: AppTextStyles.bodyMedium));
                }

                List<AppUser> users = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) =>
                    u.fullName.toLowerCase().contains(_searchQuery) ||
                    u.email.toLowerCase().contains(_searchQuery) ||
                    u.phone.contains(_searchQuery)
                  ).toList();
                }

                if (users.isEmpty) {
                  return Center(child: Text('لا توجد نتائج', style: AppTextStyles.bodyMedium));
                }

                return ListView.builder(
                  padding: AppConstants.screenHorizontalPadding,
                  itemCount: users.length,
                  itemBuilder: (context, index) => _UserCard(
                    user: users[index],
                    onRoleChange: (newRole) => _handleRoleChange(users[index], newRole),
                    onBanToggle: () => _handleBanToggle(users[index].uid),
                    onDelete: () => _handleDelete(users[index]),
                    onDeleteProperties: () => _handleDeleteProperties(users[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRoleChange(AppUser user, String newRole) async {
    try {
      await _firestore.updateUserRole(user.uid, newRole);
      if (mounted) {
        String message;
        switch (newRole) {
          case 'admin':
            message = 'تمت الترقية لمدير';
          case 'moderator':
            message = 'تمت الترقية لمشرف';
          default:
            message = 'تم إلغاء المشرف';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _handleBanToggle(String uid) async {
    try {
      await _firestore.banUser(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حظر المستخدم'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _handleDelete(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المستخدم "${user.fullName}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _firestore.deleteUser(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المستخدم'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }
  Future<void> _handleDeleteProperties(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد حذف العقارات'),
        content: Text('هل أنت متأكد من حذف جميع عقارات "${user.fullName}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف العقارات', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _firestore.deleteUserProperties(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف العقارات'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final ValueChanged<String> onRoleChange;
  final VoidCallback onBanToggle;
  final VoidCallback onDelete;
  final VoidCallback onDeleteProperties;

  const _UserCard({
    required this.user,
    required this.onRoleChange,
    required this.onBanToggle,
    required this.onDelete,
    required this.onDeleteProperties,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user.role == 'admin';
    final bool isModerator = user.role == 'moderator';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _roleColor().withValues(alpha: 0.1),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0] : '?',
                  style: AppTextStyles.titleMedium.copyWith(color: _roleColor()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(user.fullName, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(user.email, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              _buildRoleBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isAdmin && !isModerator) ...[
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _actionButton('ترقية لمشرف', AppColors.primary, () => onRoleChange('moderator'))),
                      const SizedBox(width: 8),
                      Expanded(child: _actionButton('ترقية لمدير', const Color(0xFFD4AF37), () => onRoleChange('admin'))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _actionButton('حظر', AppColors.error, onBanToggle)),
              ],
              if (isModerator) ...[
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _actionButton('ترقية لمدير', const Color(0xFFD4AF37), () => onRoleChange('admin'))),
                      const SizedBox(width: 8),
                      Expanded(child: _actionButton('إلغاء المشرف', AppColors.warning, () => onRoleChange('user'))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _actionButton('حظر', AppColors.error, onBanToggle)),
              ],
              if (isAdmin) ...[
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _actionButton('إلغاء المشرف', AppColors.warning, () => onRoleChange('moderator'))),
                      const SizedBox(width: 8),
                      Expanded(child: _actionButton('حذف', AppColors.error, onDelete)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _actionButton('حذف العقارات', AppColors.error, onDeleteProperties)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(label, style: AppTextStyles.labelSmall),
      ),
    );
  }

  Widget _buildRoleBadge() {
    Color textColor;
    String label;

    switch (user.role) {
      case 'admin':
        textColor = const Color(0xFFD4AF37);
        label = 'مدير';
      case 'moderator':
        textColor = AppColors.success;
        label = 'مشرف';
      default:
        textColor = AppColors.primary;
        label = 'مستخدم';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  Color _roleColor() {
    switch (user.role) {
      case 'admin':
        return const Color(0xFFD4AF37);
      case 'moderator':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
