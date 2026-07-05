import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/imgbb_service.dart';
import '../../models/user.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _fetching = true;
  bool _uploadingImage = false;
  String? _photoURL;
  String? _originalUsername;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final auth = context.read<AuthService>();
    final fbUser = auth.currentUser;
    if (fbUser == null) {
      if (mounted) setState(() => _fetching = false);
      return;
    }
    _nameController.text = fbUser.displayName ?? '';

    try {
      final userData = await context.read<FirestoreService>().getUser(fbUser.uid);
      if (userData != null && mounted) {
        _phoneController.text = userData.phone;
        _whatsappController.text = userData.whatsapp ?? '';
        _usernameController.text = userData.username;
        _originalUsername = userData.username;
        if (userData.profileImage != null && userData.profileImage!.isNotEmpty) {
          _photoURL = userData.profileImage;
        }
      }
    } catch (_) {}

    _photoURL ??= fbUser.photoURL;

    if (mounted) setState(() => _fetching = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      final url = await ImgBBService.uploadImage(File(picked.path));
      if (mounted) setState(() => _photoURL = url);
    } catch (e) {
      if (mounted) {
        String msg;
        final err = e.toString().toLowerCase();
        if (err.contains('network') || err.contains('timeout') || err.contains('socket')) {
          msg = 'فشل رفع الصورة: تحقق من اتصالك بالإنترنت';
        } else if (err.contains('imgbb') || err.contains('api')) {
          msg = 'فشل رفع الصورة: مشكلة في خدمة رفع الصور';
        } else {
          msg = 'فشل رفع الصورة: حاول مرة أخرى';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final auth = context.read<AuthService>();
      final firestore = context.read<FirestoreService>();
      final fbUser = auth.currentUser;
      if (fbUser == null) throw Exception('المستخدم غير موجود');

      final username = _usernameController.text.trim();
      if (username != _originalUsername) {
        final taken = await firestore.isUsernameTaken(username);
        if (taken) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('اسم المستخدم مستخدم بالفعل'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          setState(() => _loading = false);
          return;
        }
      }

      try {
        if (_nameController.text.trim() != (fbUser.displayName ?? '')) {
          await auth.updateDisplayName(_nameController.text.trim());
        }
      } catch (_) {}

      final existingUser = await firestore.getUser(fbUser.uid);

      await firestore.saveUser(AppUser(
        uid: fbUser.uid,
        fullName: _nameController.text.trim(),
        email: fbUser.email ?? '',
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        profileImage: _photoURL,
        username: username,
        favorites: existingUser?.favorites ?? [],
        role: existingUser?.role ?? 'user',
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ التغييرات بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      String msg;
      final err = e.toString().toLowerCase();
      if (err.contains('network') || err.contains('timeout') || err.contains('socket')) {
        msg = 'خطأ في الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى';
      } else if (err.contains('permission') || err.contains('denied')) {
        msg = 'ليس لديك صلاحية لإجراء هذا التعديل';
      } else if (err.contains('not-found') || err.contains('not found')) {
        msg = 'المستخدم غير موجود في قاعدة البيانات';
      } else if (err.contains('already exists') || err.contains('duplicate')) {
        msg = 'هذه المعلومات موجودة مسبقاً';
      } else {
        msg = 'حدث خطأ غير متوقع. حاول مرة أخرى لاحقاً';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'تعديل الملف الشخصي'),
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppConstants.screenPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 32),
                    _buildFormFields(),
                    const SizedBox(height: 32),
                    GradientButton(
                      text: 'حفظ التغييرات',
                      width: double.infinity,
                      icon: Icons.check_rounded,
                      loading: _loading,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileImage() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: _uploadingImage
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : _photoURL != null
                        ? Image.network(_photoURL!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultAvatar())
                        : _defaultAvatar(),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: _uploadingImage ? null : _pickImage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _uploadingImage ? null : _pickImage,
          child: Text(
            'تغيير الصورة',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.shimmerBase,
      child: const Icon(Icons.person_rounded, size: 56, color: AppColors.textSecondary),
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          CustomTextField(
            controller: _usernameController,
            label: 'اسم المستخدم',
            hint: 'أدخل اسم المستخدم',
            prefixIcon: Icons.alternate_email_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'أدخل اسم المستخدم';
              if (v.trim().length < 3) return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
              if (v.contains(' ')) return 'اسم المستخدم لا يمكن أن يحتوي على مسافات';
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _nameController,
            label: 'الاسم الكامل',
            hint: 'أدخل اسمك الكامل',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'أدخل الاسم';
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            hint: 'أدخل رقم هاتفك',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'أدخل رقم الهاتف';
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _whatsappController,
            label: 'رقم واتساب',
            hint: 'أدخل رقم واتساب (اختياري)',
            prefixIcon: Icons.chat_rounded,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}
