import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/app_settings.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _instagramController = TextEditingController();
  final _telegramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _instagramController.dispose();
    _telegramController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final fs = context.read<FirestoreService>();
      final settings = await fs.getSettings();
      _whatsappController.text = settings.whatsapp;
      _phoneController.text = settings.phone;
      _emailController.text = settings.email;
      _instagramController.text = settings.instagram;
      _telegramController.text = settings.telegram;
      _facebookController.text = settings.facebook;
      _tiktokController.text = settings.tiktok;
    } catch (_) {}
    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fs = context.read<FirestoreService>();
      final settings = AppSettings(
        whatsapp: _whatsappController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        instagram: _instagramController.text.trim(),
        telegram: _telegramController.text.trim(),
        facebook: _facebookController.text.trim(),
        tiktok: _tiktokController.text.trim(),
      );
      await fs.saveSettings(settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ الإعدادات بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ: $e'),
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
      appBar: const CustomAppBar(title: 'إعدادات التطبيق'),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('بيانات التواصل', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    Text('قم بتعديل معلومات التواصل التي تظهر في صفحة "تواصل معنا"', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _whatsappController,
                      label: 'واتساب',
                      hint: 'أدخل رقم الواتساب مع مفتاح الدولة: 963900000000',
                      helperText: 'مثال: 963900000000 (بدون + وبدون فراغات)',
                      prefixIcon: Icons.chat_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'هاتف',
                      hint: 'أدخل رقم الهاتف مع مفتاح الدولة: 963900000000',
                      helperText: 'مثال: 963900000000 (بدون + وبدون فراغات)',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      label: 'بريد إلكتروني',
                      hint: 'أدخل البريد الإلكتروني: info@example.com',
                      helperText: 'مثال: info@baitalomar.com',
                      prefixIcon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 28),
                    Text('وسائل التواصل الاجتماعي', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    Text('أدخل اسم المستخدم فقط بدون @ أو رابط', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _instagramController,
                      label: 'إنستغرام',
                      hint: 'أدخل اسم المستخدم: your_username',
                      helperText: 'مثال: my_agency (بدون @)',
                      prefixIcon: Icons.camera_alt_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _telegramController,
                      label: 'تلغرام',
                      hint: 'أدخل اسم المستخدم: your_username',
                      helperText: 'مثال: my_agency (بدون @)',
                      prefixIcon: Icons.send_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _facebookController,
                      label: 'فيسبوك',
                      hint: 'أدخل اسم المستخدم: your_username',
                      helperText: 'مثال: my_agency (بدون @)',
                      prefixIcon: Icons.facebook_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _tiktokController,
                      label: 'تيك توك',
                      hint: 'أدخل اسم المستخدم: your_username',
                      helperText: 'مثال: my_agency (بدون @)',
                      prefixIcon: Icons.music_note_rounded,
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      text: 'حفظ الإعدادات',
                      width: double.infinity,
                      icon: Icons.save_rounded,
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
}
