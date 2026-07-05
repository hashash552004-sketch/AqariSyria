import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _sent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 20),
          FadeInSlide(
            delay: 100,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 28),
          FadeInSlide(
            delay: 200,
            child: Text(
              'نسيت كلمة المرور',
              style: AppTextStyles.headlineLarge,
            ),
          ),
          const SizedBox(height: 12),
          FadeInSlide(
            delay: 250,
            child: Text(
              'أدخل بريدك الإلكتروني وسنرسل لك رابطاً\nلإعادة تعيين كلمة المرور',
              style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          FadeInSlide(
            delay: 300,
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
          const SizedBox(height: 32),
          FadeInSlide(
            delay: 350,
            child: GradientButton(
              text: 'إرسال رابط إعادة التعيين',
              width: double.infinity,
              loading: _loading,
              onPressed: _sendResetLink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return FadeInSlide(
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'تم الإرسال!',
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى\n${_emailController.text.trim()}',
            style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          GradientButton(
            text: 'العودة إلى تسجيل الدخول',
            width: double.infinity,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() => _sent = false);
            },
            child: Text(
              'إرسال إلى بريد آخر',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
