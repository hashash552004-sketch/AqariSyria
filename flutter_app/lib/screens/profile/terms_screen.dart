import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../widgets/custom_app_bar.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'شروط الاستخدام'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'القبول بالشروط',
              'باستخدامك لتطبيق بيت العمر، فإنك توافق على هذه الشروط والأحكام. إذا كنت لا توافق على أي جزء من هذه الشروط، يجب عليك التوقف عن استخدام التطبيق فوراً.',
            ),
            _buildSection(
              'وصف الخدمة',
              'بيت العمر هو تطبيق عقاري يهدف إلى تسهيل عملية البحث عن العقارات وعرضها للبيع أو الإيجار داخل سوريا. يوفر التطبيق منصة للتواصل بين مالكي العقارات والباحثين عنها.',
            ),
            _buildSection(
              'حساب المستخدم',
              'للاستفادة من خدمات التطبيق، يجب عليك إنشاء حساب. أنت مسؤول عن الحفاظ على سرية معلومات حسابك وكلمة المرور. يجب أن تكون جميع المعلومات المقدمة دقيقة وكاملة.',
            ),
            _buildSection(
              'المسؤوليات',
              '• أنت مسؤول عن دقة وصحة المعلومات التي تنشرها.\n'
                  '• يجب ألا تنشر عقارات وهمية أو مضللة.\n'
                  '• يحظر استخدام التطبيق لأي غرض غير قانوني.\n'
                  '• يجب احترام حقوق الملكية الفكرية للآخرين.\n'
                  '• أنت وحدك المسؤول عن التعاملات التي تتم عبر التطبيق.',
            ),
            _buildSection(
              'المحتوى المنشور',
              'عند نشر عقار عبر التطبيق، أنت تضمن:\n\n'
                  '• أن لديك الحق القانوني في نشر العقار.\n'
                  '• أن جميع المعلومات المقدمة صحيحة ودقيقة.\n'
                  '• أن الصور والمرفقات تخص العقار المعلن.\n'
                  '• أن سعر العقار مطابق لما هو معلن.',
            ),
            _buildSection(
              'الرسوم والعمولات',
              'قد يفرض التطبيق رسوماً على بعض الخدمات المميزة. سيتم إعلامك بأي رسوم قبل تأكيد الخدمة. جميع الرسوم غير قابلة للاسترداد ما لم ينص على خلاف ذلك.',
            ),
            _buildSection(
              'سياسة الإلغاء',
              'يحق للتطبيق إلغاء أو تعليق أي حساب يخالف هذه الشروط دون إنذار مسبق. لك الحق في حذف حسابك في أي وقت من خلال التواصل مع فريق الدعم.',
            ),
            _buildSection(
              'الملكية الفكرية',
              'جميع حقوق الملكية الفكرية المتعلقة بالتطبيق ومحتواه محفوظة. لا يحق لك نسخ أو توزيع أو تعديل أي جزء من التطبيق دون إذن خطي.',
            ),
            _buildSection(
              'الحد من المسؤولية',
              'بيت العمر غير مسؤول عن:\n\n'
                  '• دقة المعلومات المقدمة من المستخدمين.\n'
                  '• أي خسائر أو أضرار ناتجة عن استخدام التطبيق.\n'
                  '• التعاملات التي تتم بين المستخدمين خارج التطبيق.\n'
                  '• توقف الخدمة لأسباب خارجة عن إرادتنا.',
            ),
            _buildSection(
              'التعديلات على الشروط',
              'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إعلامك بالتغييرات الجوهرية عبر البريد الإلكتروني أو إشعار داخل التطبيق. استمرار استخدام التطبيق بعد التعديلات يعني موافقتك على الشروط المعدلة.',
            ),
            _buildSection(
              'القانون الواجب التطبيق',
              'تخضع هذه الشروط وأي نزاعات ناشئة عنها للقوانين السورية. يتم فض أي نزاعات عن طريق التفاوض المباشر، وفي حال عدم التوصل إلى حل، يتم اللجوء إلى القضاء السوري المختص.',
            ),
            _buildSection(
              'اتصل بنا',
              'للاستفسارات المتعلقة بشروط الاستخدام، يرجى التواصل معنا عبر:\n\n'
                  '• البريد الإلكتروني: legal@baitalomar.com\n'
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
