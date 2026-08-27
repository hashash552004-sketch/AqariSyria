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
  final _usernameController = TextEditingController();
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

  bool _usernameTaken = false;
  bool _checkingUsername = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameController,
      _emailController,
      _phoneController,
      _confirmPasswordController,
    ]) {
      c.addListener(_refreshButton);
    }
    _passwordController.addListener(_validatePassword);
    _usernameController.addListener(_validateUsername);
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  void _refreshButton() {
    if (mounted) setState(() {});
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

  Future<void> _validateUsername() async {
    final u = _usernameController.text.trim();
    if (u.length < 3) {
      if (mounted) setState(() => _usernameTaken = false);
      return;
    }
    if (_checkingUsername) return;
    _checkingUsername = true;
    try {
      final taken = await context.read<FirestoreService>().isUsernameTaken(u);
      if (mounted) setState(() => _usernameTaken = taken);
    } catch (_) {
      if (mounted) setState(() => _usernameTaken = false);
    } finally {
      _checkingUsername = false;
      if (mounted) setState(() {});
    }
  }

  bool get _isPasswordValid => _hasMinLength && _hasUppercase && _hasLowercase && _hasSpecialChar && _hasNumber;

  bool get _isFormComplete {
    return _nameController.text.trim().isNotEmpty &&
        _usernameController.text.trim().length >= 3 &&
        !_usernameTaken &&
        _emailController.text.trim().isNotEmpty &&
        _emailController.text.contains('@') &&
        _phoneController.text.trim().isNotEmpty &&
        _isPasswordValid &&
        _confirmPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text == _passwordController.text;
  }

  bool get _isButtonEnabled => _isFormComplete && !_loading;

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _emailController,
      _phoneController,
      _confirmPasswordController,
    ]) {
      c.removeListener(_refreshButton);
    }
    _passwordController.removeListener(_validatePassword);
    _usernameController.removeListener(_validateUsername);
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isFormComplete) return;
    setState(() => _loading = true);
    try {
      final username = _usernameController.text.trim();
      final taken = await context.read<FirestoreService>().isUsernameTaken(username);
      if (taken) {
        if (mounted) {
          setState(() => _usernameTaken = true);
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

      final credential = await context.read<AuthService>().registerEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final firestore = context.read<FirestoreService>();
      final email = _emailController.text.trim();
      final user = AppUser(
        uid: credential.user!.uid,
        fullName: _nameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
        username: username,
        profileCompleted: true,
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
                  delay: 330,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _usernameController,
                        label: 'اسم المستخدم',
                        hint: 'اسم فريد يظهر في ملفك (٣ أحرف على الأقل)',
                        prefixIcon: Icons.alternate_email_rounded,
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return 'أدخل اسم المستخدم';
                          if (val.length < 3) return 'اسم المستخدم يجب أن يكون ٣ أحرف على الأقل';
                          if (val.contains(' ')) return 'اسم المستخدم لا يمكن أن يحتوي على مسافات';
                          if (_usernameTaken) return 'اسم المستخدم مستخدم بالفعل';
                          return null;
                        },
                      ),
                      if (_usernameController.text.trim().length >= 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _usernameTaken ? Icons.cancel_rounded : Icons.check_circle_rounded,
                                size: 14,
                                color: _usernameTaken ? AppColors.error : AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _usernameTaken
                                    ? 'اسم المستخدم مستخدم بالفعل'
                                    : _checkingUsername
                                        ? 'جاري التحقق من الاسم...'
                                        : 'اسم المستخدم متاح',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _usernameTaken ? AppColors.error : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
                      gradient: _isFormComplete
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: _isFormComplete ? null : AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isFormComplete
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
                        onTap: _isButtonEnabled ? _register : null,
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
                                    color: _isFormComplete ? Colors.white : Colors.white.withValues(alpha: 0.7),
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
