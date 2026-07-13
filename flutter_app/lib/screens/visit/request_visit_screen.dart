import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/snackbar_helper.dart';

class RequestVisitScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String ownerId;
  final String ownerName;

  const RequestVisitScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  State<RequestVisitScreen> createState() => _RequestVisitScreenState();
}

class _RequestVisitScreenState extends State<RequestVisitScreen> {
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showSnackBar(context, 'يرجى إدخال رقم الهاتف', backgroundColor: AppColors.error);
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final firestore = context.read<FirestoreService>();
      final user = auth.currentUser!;
      await firestore.requestVisit(
        propertyId: widget.propertyId,
        propertyTitle: widget.propertyTitle,
        ownerId: widget.ownerId,
        requesterId: user.uid,
        requesterName: user.displayName ?? 'مستخدم',
        requesterPhone: phone,
        preferredDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        message: _messageController.text.trim(),
      );
      if (mounted) {
        showSnackBar(context, 'تم إرسال طلب المعاينة بنجاح');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'فشل الإرسال: $e', backgroundColor: AppColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM y', 'ar');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('طلب معاينة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.propertyTitle, style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            Text('المالك: ${widget.ownerName}', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              hint: 'أدخل رقم هاتفك للتواصل',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Text('التاريخ المفضل', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cards,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(dateFormat.format(_selectedDate), style: AppTextStyles.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('الوقت المفضل', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cards,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(_selectedTime.format(context), style: AppTextStyles.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _messageController,
              label: 'رسالة (اختياري)',
              hint: 'أضف ملاحظات إضافية',
              prefixIcon: Icons.message_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('إرسال الطلب', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
