import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../widgets/custom_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'سياسة الخصوصية'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'المقدمة',
              'نحن في بيت العمر نلتزم بحماية خصوصية مستخدمينا. توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية المعلومات الشخصية التي تقدمها عند استخدام تطبيقنا.',
            ),
            _buildSection(
              'المعلومات التي نجمعها',
              'نقوم بجمع المعلومات التالية عند استخدامك للتطبيق:\n\n'
                  '• المعلومات الشخصية: الاسم، رقم الهاتف، البريد الإلكتروني، العنوان.\n'
                  '• معلومات العقار: تفاصيل العقارات التي تنشرها أو تبحث عنها.\n'
                  '• معلومات الاستخدام: بيانات حول كيفية تفاعلك مع التطبيق.\n'
                  '• معلومات الموقع: لتحديد مواقع العقارات القريبة منك.',
            ),
            _buildSection(
              'كيف نستخدم معلوماتك',
              'نستخدم المعلومات التي نجمعها للأغراض التالية:\n\n'
                  '• تقديم وتحسين خدمات التطبيق العقارية.\n'
                  '• تمكين التواصل بين الباحثين عن العقارات وأصحابها.\n'
                  '• إرسال الإشعارات والتحديثات المتعلقة بالخدمة.\n'
                  '• تحسين تجربة المستخدم وتخصيص المحتوى.\n'
                  '• تحليل استخدام التطبيق لتطويره.',
            ),
            _buildSection(
              'مشاركة المعلومات',
              'نحن لا نبيع أو نشارك معلوماتك الشخصية مع أطراف ثالثة إلا في الحالات التالية:\n\n'
                  '• بموافقتك الصريحة.\n'
                  '• للامتثال للقوانين واللوائح.\n'
                  '• لحماية حقوقنا القانونية.\n'
                  '• مع مزودي الخدمة الذين يساعدوننا في تشغيل التطبيق.',
            ),
            _buildSection(
              'حماية المعلومات',
              'نتخذ إجراءات أمنية مناسبة لحماية معلوماتك الشخصية من الوصول غير المصرح به أو التعديل أو الإفصاح أو الإتلاف. تشمل هذه الإجراءات التشفير وجدران الحماية وبروتوكولات الأمان المتقدمة.',
            ),
            _buildSection(
              'ملفات تعريف الارتباط',
              'نستخدم ملفات تعريف الارتباط وتقنيات مماثلة لتحسين تجربتك على التطبيق، وتحليل الأداء، وتخصيص المحتوى. يمكنك التحكم في إعدادات ملفات تعريف الارتباط من خلال إعدادات المتصفح الخاص بك.',
            ),
            _buildSection(
              'حقوقك',
              'لديك الحق في:\n\n'
                  '• الوصول إلى معلوماتك الشخصية وتحديثها.\n'
                  '• طلب حذف معلوماتك الشخصية.\n'
                  '• الاعتراض على معالجة بياناتك.\n'
                  '• سحب الموافقة في أي وقت.\n'
                  '• تقديم شكوى إلى الجهة التنظيمية المختصة.',
            ),
            _buildSection(
              'التغييرات على السياسة',
              'قد نقوم بتحديث سياسة الخصوصية هذه من وقت لآخر. سنقوم بإعلامك بأي تغييرات جوهرية عن طريق نشر السياسة الجديدة على التطبيق. يرجى مراجعة هذه الصفحة بشكل دوري.',
            ),
            _buildSection(
              'اتصل بنا',
              'إذا كان لديك أي استفسارات أو مخاوف بشأن سياسة الخصوصية هذه، يرجى الاتصال بنا عبر:\n\n'
                  '• البريد الإلكتروني: privacy@baitalomar.com\n'
                  '• الهاتف: +963 900 000 000',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(title, style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
