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
  int _filterIndex = 0;

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
                  hintText: 'بحث بالاسم المستخدم...',
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
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: AppConstants.screenHorizontalPadding,
              children: [
                _filterChip('الكل', 0),
                const SizedBox(width: 8),
                _filterChip('مدير', 1),
                const SizedBox(width: 8),
                _filterChip('مشرف', 2),
                const SizedBox(width: 8),
                _filterChip('موظف', 3),
                const SizedBox(width: 8),
                _filterChip('مستخدم', 4),
                const SizedBox(width: 8),
                _filterChip('محظورين', 5),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _firestore.streamUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('حدث خطأ في تحميل المستخدمين', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '${snapshot.error}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: Text('إعادة المحاولة', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('لا يوجد مستخدمين', style: AppTextStyles.bodyMedium));
                }

                List<AppUser> users = snapshot.data!;
                if (_filterIndex == 1) {
                  users = users.where((u) => u.role == 'admin').toList();
                } else if (_filterIndex == 2) {
                  users = users.where((u) => u.role == 'moderator').toList();
                } else if (_filterIndex == 3) {
                  users = users.where((u) => u.role == 'user' && u.permissions.isNotEmpty).toList();
                } else if (_filterIndex == 4) {
                  users = users.where((u) => u.role == 'user' && u.permissions.isEmpty).toList();
                } else if (_filterIndex == 5) {
                  users = users.where((u) => u.banned).toList();
                } else if (_filterIndex == 6) {
                  users = users.where((u) => u.isTrusted).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) =>
                    u.username.toLowerCase().contains(_searchQuery) ||
                    u.fullName.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                if (users.isEmpty) {
                  return Center(child: Text('لا توجد نتائج', style: AppTextStyles.bodyMedium));
                }

                return ListView.builder(
                  padding: AppConstants.screenHorizontalPadding,
                  itemCount: users.length,
                  itemBuilder: (context, index) => _UserTile(
                    user: users[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _UserDetailScreen(user: users[index]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int index) {
    final selected = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cards,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color roleColor = _roleColor();
    final String roleLabel = _roleLabel();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withValues(alpha: 0.1),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: AppTextStyles.titleMedium.copyWith(color: roleColor),
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
                        child: Text(
                          user.username.isNotEmpty ? user.username : '—',
                          style: AppTextStyles.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (user.banned)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('محظور', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontSize: 10)),
                        ),
                      if (user.isTrusted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                              const SizedBox(width: 3),
                              Text('موثوق', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontSize: 10)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(roleLabel, style: AppTextStyles.caption.copyWith(color: roleColor, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  String _roleLabel() {
    switch (user.role) {
      case 'admin':
        return 'مدير';
      case 'moderator':
        return 'مشرف';
      default:
        return user.permissions.isNotEmpty ? 'موظف' : 'مستخدم';
    }
  }

  Color _roleColor() {
    switch (user.role) {
      case 'admin':
        return const Color(0xFFD4AF37);
      case 'moderator':
        return AppColors.success;
      default:
        return user.permissions.isNotEmpty ? AppColors.primary : AppColors.textSecondary;
    }
  }
}

// ---------------------------------------------------------------------------
// User Detail Screen
// ---------------------------------------------------------------------------

class _UserDetailScreen extends StatefulWidget {
  final AppUser user;
  const _UserDetailScreen({required this.user});

  @override
  State<_UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<_UserDetailScreen> {
  final FirestoreService _firestore = FirestoreService();
  late bool _banned;
  late bool _trusted;
  late String _currentRole;
  late Map<String, dynamic> _permissions;
  bool _saving = false;

  static const List<_PermissionEntry> _permissionDefs = [
    _PermissionEntry('review_reports', 'مراجعة البلاغات', Icons.report_outlined),
    _PermissionEntry('respond_customers', 'الرد على العملاء', Icons.support_agent_outlined),
    _PermissionEntry('review_properties', 'مراجعة العقارات', Icons.approval_outlined),
    _PermissionEntry('feature_property', 'تمييز العقار كمميز', Icons.star_outline_rounded),
    _PermissionEntry('view_reports', 'عرض التقارير', Icons.analytics_outlined),
    _PermissionEntry('mark_trusted', 'توثيق المستخدمين', Icons.verified_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _banned = widget.user.banned;
    _trusted = widget.user.isTrusted;
    _currentRole = widget.user.role;
    _permissions = Map<String, dynamic>.from(widget.user.permissions);
  }

  bool get _isModerator => _currentRole == 'moderator' || _currentRole == 'admin';

  void _applyRolePermissions(String role) {
    setState(() {
      _currentRole = role;
      if (role == 'admin') {
        for (final entry in _permissionDefs) {
          _permissions[entry.key] = true;
        }
      } else if (role == 'moderator') {
        for (final entry in _permissionDefs) {
          _permissions[entry.key] = true;
        }
      } else if (role == 'employee') {
        _permissions['review_reports'] = true;
        _permissions['respond_customers'] = true;
        _permissions['review_properties'] = true;
        _permissions['feature_property'] = false;
      } else {
        _permissions.clear();
      }
    });
  }

  void _togglePermission(String key, bool value) {
    setState(() => _permissions[key] = value);
    _savePermissions();
  }

  Future<void> _savePermissions() async {
    setState(() => _saving = true);
    try {
      await _firestore.updateUserPermissions(widget.user.uid, _permissions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الصلاحيات'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleBan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_banned ? 'إلغاء الحظر' : 'حظر المستخدم'),
        content: Text(_banned
            ? 'هل تريد إلغاء حظر "${widget.user.username}"؟'
            : 'هل تريد حظر "${widget.user.username}"؟ لن يتمكن من الدخول إلى التطبيق.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_banned ? 'إلغاء الحظر' : 'حظر',
                style: TextStyle(color: _banned ? AppColors.success : AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      if (_banned) {
        await _firestore.unbanUser(widget.user.uid);
      } else {
        await _firestore.banUser(widget.user.uid);
      }
      if (mounted) {
        setState(() => _banned = !_banned);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_banned ? 'تم حظر المستخدم' : 'تم إلغاء حظر المستخدم'),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleTrusted() async {
    setState(() => _saving = true);
    try {
      await _firestore.setUserTrusted(widget.user.uid, !_trusted);
      if (mounted) {
        setState(() => _trusted = !_trusted);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_trusted ? 'تم توثيق المستخدم' : 'تم إلغاء توثيق المستخدم'),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المستخدم "${widget.user.username}"؟\nسيتم حذف جميع بياناته وعقاراته.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await _firestore.deleteUser(widget.user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المستخدم'), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeRole(String newRole) async {
    setState(() => _saving = true);
    try {
      await _firestore.updateUserRole(widget.user.uid, newRole);
      _applyRolePermissions(newRole);
      await _firestore.updateUserPermissions(widget.user.uid, _permissions);
      if (mounted) {
        String message;
        switch (newRole) {
          case 'admin':
            message = 'تم تعيين كمدير';
          case 'moderator':
            message = 'تم تعيين كمشرف';
          case 'employee':
            message = 'تم تعيين كموظف';
          default:
            message = 'تم تعيين كمستخدم';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = _roleColor();
    final String roleLabel = _roleLabel();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'تفاصيل المستخدم',
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ---- User Header ----
          Container(
            padding: AppConstants.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.cards,
              borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: roleColor.withValues(alpha: 0.1),
                  child: Text(
                    widget.user.username.isNotEmpty ? widget.user.username[0].toUpperCase() : '?',
                    style: AppTextStyles.displaySmall.copyWith(color: roleColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.username.isNotEmpty ? widget.user.username : '—',
                  style: AppTextStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(roleLabel, style: AppTextStyles.caption.copyWith(color: roleColor, fontWeight: FontWeight.w600)),
                    ),
                    if (_banned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('محظور', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- User Details ----
          Container(
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
                Text('البيانات الشخصية', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                _detailRow(Icons.person, 'الاسم الكامل', widget.user.fullName),
                _detailRow(Icons.alternate_email, 'اسم المستخدم', widget.user.username),
                _detailRow(Icons.email_outlined, 'البريد الإلكتروني', widget.user.email),
                _detailRow(Icons.phone_outlined, 'الهاتف', widget.user.phone),
                if (widget.user.whatsapp != null && widget.user.whatsapp!.isNotEmpty)
                  _detailRow(Icons.chat_outlined, 'واتساب', widget.user.whatsapp!),
                _detailRow(Icons.badge_outlined, 'المعرّف الفريد', widget.user.uniqueUserId ?? '—'),
                _detailRow(Icons.star_border, 'المفضلة', '${widget.user.favorites.length} عقار'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Role Management ----
          Container(
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
                Text('إدارة الدور', style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'مدير: جميع الصلاحيات\nمشرف: جميع الصلاحيات\nموظف: مراجعة العقارات، مراجعة البلاغات، الرد على العملاء\nمستخدم: بدون صلاحيات إدارية',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _roleButton('مدير', const Color(0xFFD4AF37), () => _changeRole('admin')),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _roleButton('مشرف', AppColors.success, () => _changeRole('moderator')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _roleButton('موظف', AppColors.primary, () => _changeRole('employee')),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _roleButton('مستخدم', AppColors.textSecondary, () => _changeRole('user')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Permissions ----
          Container(
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
                    Text('الصلاحيات', style: AppTextStyles.titleMedium),
                    const Spacer(),
                    if (_saving)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    if (_isModerator || _currentRole == 'admin')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('الكل', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._permissionDefs.map((entry) => _buildPermissionTile(entry)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Trusted toggle ----
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _toggleTrusted,
              icon: Icon(_trusted ? Icons.verified_rounded : Icons.verified_outlined, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_trusted ? 'إلغاء التوثيق' : 'توثيق المستخدم'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _trusted ? AppColors.success : AppColors.primary,
                side: BorderSide(
                  color: (_trusted ? AppColors.success : AppColors.primary).withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ---- Action Buttons ----
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _toggleBan,
                    icon: Icon(_banned ? Icons.lock_open : Icons.block, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_banned ? 'إلغاء الحظر' : 'حظر المستخدم'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _banned ? AppColors.success : AppColors.error,
                      side: BorderSide(color: (_banned ? AppColors.success : AppColors.error).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _deleteUser,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('حذف المستخدم'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyLarge.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleButton(String label, Color color, VoidCallback onTap) {
    final isActive = (label == 'مدير' && _currentRole == 'admin') ||
        (label == 'مشرف' && _currentRole == 'moderator') ||
        (label == 'موظف' && _currentRole == 'employee') ||
        (label == 'مستخدم' && _currentRole == 'user');
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: _saving ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? color.withValues(alpha: 0.08) : null,
          foregroundColor: color,
          side: BorderSide(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive) ...[
                Icon(Icons.check_circle_rounded, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(label, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile(_PermissionEntry entry) {
    final isEnabled = _permissions[entry.key] == true;
    final canToggle = _currentRole == 'user' || _currentRole == 'employee';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEnabled
            ? entry.key == 'feature_property'
                ? AppColors.warning.withValues(alpha: 0.06)
                : AppColors.primary.withValues(alpha: 0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? entry.key == 'feature_property'
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.15)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isEnabled
                  ? (entry.key == 'feature_property' ? AppColors.warning : AppColors.primary).withValues(alpha: 0.12)
                  : AppColors.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              entry.icon,
              size: 18,
              color: isEnabled
                  ? (entry.key == 'feature_property' ? AppColors.warning : AppColors.primary)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry.label, style: AppTextStyles.labelLarge.copyWith(
              fontSize: 13,
              color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
            )),
          ),
          Switch(
            value: isEnabled,
            onChanged: canToggle ? (v) => _togglePermission(entry.key, v) : null,
            activeThumbColor: entry.key == 'feature_property' ? AppColors.warning : AppColors.primary,
          ),
        ],
      ),
    );
  }

  String _roleLabel() {
    switch (_currentRole) {
      case 'admin':
        return 'مدير';
      case 'moderator':
        return 'مشرف';
      case 'employee':
        return 'موظف';
      default:
        return 'مستخدم';
    }
  }

  Color _roleColor() {
    switch (_currentRole) {
      case 'admin':
        return const Color(0xFFD4AF37);
      case 'moderator':
        return AppColors.success;
      case 'employee':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _PermissionEntry {
  final String key;
  final String label;
  final IconData icon;
  const _PermissionEntry(this.key, this.label, this.icon);
}
