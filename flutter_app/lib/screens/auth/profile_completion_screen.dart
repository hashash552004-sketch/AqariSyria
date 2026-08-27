import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../home/home_screen.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _nameController.text = auth.currentUser?.displayName ?? '';
    _phoneController.text = auth.currentUser?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final fs = context.read<FirestoreService>();
      final uid = auth.currentUser?.uid;
      if (uid == null) return;

      await auth.updateDisplayName(_nameController.text.trim());
      await fs.updateUserProfile(
        uid,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profileCompleted: true,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'أكمل ملفك الشخصي',
                  style: AppTextStyles.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل معلوماتك للمتابعة',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
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
                const SizedBox(height: 18),
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
                const SizedBox(height: 12),
                Text(
                  'الصورة اختيارية - يمكنك إضافتها لاحقاً من الملف الشخصي',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'حفظ والمتابعة',
                  width: double.infinity,
                  loading: _loading,
                  onPressed: _completeProfile,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final auth = context.read<AuthService>();
                    await auth.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  child: Text(
                    ' تسجيل الخروج',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
