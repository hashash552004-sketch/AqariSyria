import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/app_settings.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final fs = context.read<FirestoreService>();
    final settings = await fs.getSettings();
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fs = context.read<FirestoreService>();
      final auth = context.read<AuthService>();
      final ts = FieldValue.serverTimestamp();
      await fs.saveContactMessage(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        userId: auth.currentUser?.uid,
        timestamp: ts,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إرسال رسالتك بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الإرسال: $e'),
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
      appBar: const CustomAppBar(title: 'تواصل معنا'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildContactInfoCards(),
            const SizedBox(height: 24),
            _buildContactForm(),
            const SizedBox(height: 24),
            _buildSocialSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCards() {
    final items = [
      _ContactInfo(Icons.chat_rounded, 'واتساب', _settings.whatsapp, AppColors.success),
      _ContactInfo(Icons.phone_rounded, 'اتصال', _settings.phone, AppColors.primary),
      _ContactInfo(Icons.email_rounded, 'بريد إلكتروني', _settings.email, AppColors.warning),
    ];

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _launchContact(item),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.open_in_new_rounded,
                      color: item.color,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _launchContact(_ContactInfo item) async {
    String url;
    if (item.label == 'واتساب') {
      final cleaned = _settings.whatsapp.replaceAll(RegExp(r'[^\d]'), '');
      url = 'https://wa.me/$cleaned';
    } else if (item.label == 'اتصال') {
      url = 'tel:${_settings.phone}';
    } else {
      url = 'mailto:${_settings.email}?subject=استفسار من تطبيق عقارينا';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactForm() {
    return Container(
      width: double.infinity,
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أرسل لنا رسالة',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _nameController,
              label: 'الاسم',
              hint: 'أدخل اسمك الكامل',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل الاسم';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني',
              hint: 'أدخل بريدك الإلكتروني',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                if (!v.contains('@')) return 'أدخل بريداً صحيحاً';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _subjectController,
              label: 'الموضوع',
              hint: 'موضوع الرسالة',
              prefixIcon: Icons.subject_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل الموضوع';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _messageController,
              label: 'الرسالة',
              hint: 'اكتب رسالتك هنا...',
              prefixIcon: Icons.message_outlined,
              maxLines: 5,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل الرسالة';
                if (v.length < 10) return 'الرسالة قصيرة جداً';
                return null;
              },
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'إرسال',
              width: double.infinity,
              icon: Icons.send_rounded,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    final socialItems = <_SocialItem>[];
    if (_settings.instagram.isNotEmpty) {
      socialItems.add(_SocialItem(
        Icons.camera_alt_rounded, const Color(0xFFE4405F), 'انستغرام',
        'https://instagram.com/${_settings.instagram}',
      ));
    }
    if (_settings.telegram.isNotEmpty) {
      socialItems.add(_SocialItem(
        Icons.send_rounded, const Color(0xFF0088CC), 'تلغرام',
        'https://t.me/${_settings.telegram}',
      ));
    }
    if (_settings.facebook.isNotEmpty) {
      socialItems.add(_SocialItem(
        Icons.facebook_rounded, const Color(0xFF1877F2), 'فيسبوك',
        'https://facebook.com/${_settings.facebook}',
      ));
    }
    if (_settings.tiktok.isNotEmpty) {
      socialItems.add(_SocialItem(
        Icons.music_note_rounded, Colors.black, 'تيك توك',
        'https://tiktok.com/@${_settings.tiktok}',
      ));
    }

    if (socialItems.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
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
          Text('تواصل معنا عبر وسائل التواصل', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: socialItems.map((item) {
              return _socialIcon(item.icon, item.color, () async {
                final uri = Uri.tryParse(item.url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              });
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _ContactInfo {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ContactInfo(this.icon, this.label, this.value, this.color);
}

class _SocialItem {
  final IconData icon;
  final Color color;
  final String label;
  final String url;
  const _SocialItem(this.icon, this.color, this.label, this.url);
}
