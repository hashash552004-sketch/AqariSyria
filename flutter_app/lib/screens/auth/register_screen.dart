import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/user.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  bool _passwordFocused = false;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasSpecialChar = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  void _validatePassword() {
    final p = _passwordController.text;
    setState(() {
      _hasMinLength = p.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(p);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(p);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(p);
      _hasNumber = RegExp(r'[0-9]').hasMatch(p);
    });
  }

  bool get _isPasswordValid => _hasMinLength && _hasUppercase && _hasLowercase && _hasSpecialChar && _hasNumber;

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPasswordValid) return;
    setState(() => _loading = true);
    try {
      final credential = await context.read<AuthService>().registerEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final firestore = context.read<FirestoreService>();
      final email = _emailController.text.trim();
      final defaultUsername = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final user = AppUser(
        uid: credential.user!.uid,
        fullName: _nameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
        username: defaultUsername,
      );
      await firestore.saveUser(user);
      NotificationService().saveToken(credential.user!.uid);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      String message;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            message = 'البريد الإلكتروني مستخدم بالفعل';
            break;
          case 'weak-password':
            message = 'كلمة المرور ضعيفة جداً';
            break;
          case 'invalid-email':
            message = 'البريد الإلكتروني غير صالح';
            break;
          case 'operation-not-allowed':
            message = 'التسجيل غير متاح حالياً';
            break;
          case 'too-many-requests':
            message = 'محاولات كثيرة جداً. حاول لاحقاً.';
            break;
          default:
            message = 'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى.';
        }
      } else {
        message = 'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildPasswordHint(IconData icon, String text, bool met) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              met ? Icons.check_circle_rounded : Icons.cancel_rounded,
              key: ValueKey(met),
              size: 16,
              color: met ? AppColors.success : AppColors.error.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: met ? AppColors.success : AppColors.textSecondary,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
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
                const SizedBox(height: 24),
                FadeInSlide(
                  delay: 100,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
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
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeInSlide(
                  delay: 200,
                  child: Text(
                    'إنشاء حساب جديد',
                    style: AppTextStyles.headlineLarge,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInSlide(
                  delay: 250,
                  child: Text(
                    'انضم إلينا وابحث عن عقارك المثالي',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(height: 32),
                FadeInSlide(
                  delay: 300,
                  child: CustomTextField(
                    controller: _nameController,
                    label: 'الاسم الكامل',
                    hint: 'أدخل اسمك الكامل',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل الاسم الكامل';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),
                FadeInSlide(
                  delay: 350,
                  child: CustomTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    hint: 'أدخل بريدك الإلكتروني',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                      if (!v.contains('@')) return 'أدخل بريداً إلكترونياً صحيحاً';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),
                FadeInSlide(
                  delay: 400,
                  child: CustomTextField(
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
                ),
                const SizedBox(height: 18),
                FadeInSlide(
                  delay: 450,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        label: 'كلمة المرور',
                        hint: 'أدخل كلمة مرور قوية',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                          if (!_isPasswordValid) return 'كلمة المرور لا تلبي المعايير المطلوبة';
                          return null;
                        },
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: _passwordFocused && _passwordController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPasswordHint(Icons.tag_rounded, '٨ أحرف على الأقل', _hasMinLength),
                                    _buildPasswordHint(Icons.abc, 'حرف كبير (A-Z)', _hasUppercase),
                                    _buildPasswordHint(Icons.abc, 'حرف صغير (a-z)', _hasLowercase),
                                    _buildPasswordHint(Icons.numbers_rounded, 'رقم (0-9)', _hasNumber),
                                    _buildPasswordHint(Icons.tag_rounded, 'علامة خاصة (!@#\$%^&*)', _hasSpecialChar),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FadeInSlide(
                  delay: 500,
                  child: CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'تأكيد كلمة المرور',
                    hint: 'أعد إدخال كلمة المرور',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أكد كلمة المرور';
                      if (v != _passwordController.text) return 'كلمة المرور غير متطابقة';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                FadeInSlide(
                  delay: 550,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _isPasswordValid
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: _isPasswordValid ? null : AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isPasswordValid
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isPasswordValid ? _register : null,
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  'إنشاء حساب',
                                  style: AppTextStyles.button.copyWith(
                                    color: _isPasswordValid ? Colors.white : Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInSlide(
                  delay: 600,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لديك حساب؟ ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'سجل الدخول',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
