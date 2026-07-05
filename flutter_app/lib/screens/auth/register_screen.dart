import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
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
  final _authService = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final credential = await _authService.registerEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final firestore = context.read<FirestoreService>();
      final user = AppUser(
        uid: credential.user!.uid,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      await firestore.saveUser(user);
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
                  child: CustomTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    hint: 'أدخل كلمة مرور قوية',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                      if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      return null;
                    },
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
                  child: GradientButton(
                    text: 'إنشاء حساب',
                    width: double.infinity,
                    loading: _loading,
                    onPressed: _register,
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
