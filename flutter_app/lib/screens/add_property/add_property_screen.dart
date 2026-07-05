import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/auth_service.dart';
import '../../services/imgbb_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

class AddPropertyScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const AddPropertyScreen({super.key, this.onBackToHome});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _roomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _floorController = TextEditingController();
  final _addressController = TextEditingController();
  final _regionController = TextEditingController();
  final _picker = ImagePicker();

  String _type = '';
  String _operationType = '';
  String _governorate = '';
  String _region = '';
  String _deedType = '';

  bool _hasElevator = false;
  bool _hasParking = false;
  bool _hasAC = false;
  bool _hasHeating = false;
  bool _hasGarden = false;
  bool _hasPool = false;
  bool _hasBalcony = false;
  bool _hasInternet = false;
  bool _hasGas = false;
  bool _isFurnished = false;

  final List<XFile> _selectedImages = [];
  final Map<int, double> _uploadProgress = {};
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _bathroomsController.dispose();
    _floorController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _pickImageCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _selectedImages.add(image));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<String> _uploadSingleImage(
    XFile image,
    int index,
  ) async {
    setState(() => _uploadProgress[index] = 0.0);
    final url = await ImgBBService.uploadImage(File(image.path));
    setState(() => _uploadProgress[index] = 1.0);
    return url;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type.isEmpty) {
      _showError('يرجى اختيار نوع العقار');
      return;
    }
    if (_operationType.isEmpty) {
      _showError('يرجى اختيار نوع العملية');
      return;
    }
    if (_governorate.isEmpty) {
      _showError('يرجى اختيار المحافظة');
      return;
    }

    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;

    setState(() => _loading = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('properties').doc();
      final propertyId = docRef.id;

      final List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final url = await _uploadSingleImage(_selectedImages[i], i);
        imageUrls.add(url);
      }

      final property = Property(
        id: propertyId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        type: _type,
        operationType: _operationType,
        price: double.tryParse(_priceController.text) ?? 0,
        area: double.tryParse(_areaController.text) ?? 0,
        rooms: int.tryParse(_roomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        floor: int.tryParse(_floorController.text) ?? 0,
        governorate: _governorate,
        region: _region,
        detailedAddress: _addressController.text.trim(),
        images: imageUrls,
        ownerId: auth.currentUser!.uid,
        ownerName: auth.currentUser!.displayName ?? 'مستخدم',
        ownerPhone: auth.currentUser!.phoneNumber ?? '',
        hasElevator: _hasElevator,
        hasParking: _hasParking,
        hasAC: _hasAC,
        hasHeating: _hasHeating,
        hasGarden: _hasGarden,
        hasPool: _hasPool,
        hasBalcony: _hasBalcony,
        hasInternet: _hasInternet,
        hasGas: _hasGas,
        isFurnished: _isFurnished,
        deedType: _deedType,
        isSold: false,
        isActive: true,
      );

      await docRef.set({
        ...property.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نشر العقار بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.onBackToHome != null) {
        widget.onBackToHome!();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ أثناء حفظ العقار. يرجى المحاولة مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'إضافة عقار',
        showBack: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 16),
          ),
          onPressed: () => widget.onBackToHome?.call(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppConstants.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(
                'معلومات العقار',
                Icons.info_outline,
                AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildCard(
                accentColor: AppColors.primary,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      label: 'عنوان العقار',
                      hint: 'مثال: فيلا فاخرة في المزة',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descController,
                      label: 'الوصف',
                      hint: 'تفاصيل عن العقار...',
                      maxLines: 4,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(
                'التفاصيل المالية والعقارية',
                Icons.attach_money,
                AppColors.success,
              ),
              const SizedBox(height: 16),
              _buildCard(
                accentColor: AppColors.success,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _priceController,
                            label: 'السعر (بالليرة)',
                            hint: '٠٠٠ ٠٠٠ ١٠٠',
                            keyboardType: TextInputType.number,
                            prefixText: AppConstants.currency,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'مطلوب'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _areaController,
                            label: 'المساحة (م²)',
                            hint: '١٥٠',
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'مطلوب'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _roomsController,
                            label: 'عدد الغرف',
                            hint: '٣',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _bathroomsController,
                            label: 'عدد الحمامات',
                            hint: '٢',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _floorController,
                            label: 'الطابق',
                            hint: '٣',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(
                'التصنيف',
                Icons.category,
                AppColors.warning,
              ),
              const SizedBox(height: 16),
              _buildCard(
                accentColor: AppColors.warning,
                child: Column(
                  children: [
                    _buildDropdown(
                      label: 'نوع العقار',
                      value: _type,
                      items: AppConstants.propertyTypes,
                      onChanged: (v) => setState(() => _type = v),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'نوع العملية',
                      value: _operationType,
                      items: AppConstants.operationTypes,
                      onChanged: (v) => setState(() => _operationType = v),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'نوع الطابو',
                      value: _deedType,
                      items: const ['', 'طابو أخضر', 'ورثة', 'حط أنت التالي'],
                      onChanged: (v) => setState(() => _deedType = v),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'المحافظة',
                      value: _governorate,
                      items: AppConstants.governorates,
                      onChanged: (v) => setState(() => _governorate = v),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _regionController,
                      label: 'المنطقة',
                      hint: 'اختياري',
                      onChanged: (v) => _region = v,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(
                'الخدمات',
                Icons.build,
                const Color(0xFF9B51E0),
              ),
              const SizedBox(height: 16),
              _buildCard(
                accentColor: const Color(0xFF9B51E0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip('مصعد', _hasElevator,
                        (v) => setState(() => _hasElevator = v)),
                    _buildChip('موقف سيارات', _hasParking,
                        (v) => setState(() => _hasParking = v)),
                    _buildChip('تكييف', _hasAC,
                        (v) => setState(() => _hasAC = v)),
                    _buildChip('تدفئة', _hasHeating,
                        (v) => setState(() => _hasHeating = v)),
                    _buildChip('حديقة', _hasGarden,
                        (v) => setState(() => _hasGarden = v)),
                    _buildChip('مسبح', _hasPool,
                        (v) => setState(() => _hasPool = v)),
                    _buildChip('شرفة', _hasBalcony,
                        (v) => setState(() => _hasBalcony = v)),
                    _buildChip('إنترنت', _hasInternet,
                        (v) => setState(() => _hasInternet = v)),
                    _buildChip('غاز', _hasGas,
                        (v) => setState(() => _hasGas = v)),
                    _buildChip('مفروش', _isFurnished,
                        (v) => setState(() => _isFurnished = v)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(
                'العنوان التفصيلي',
                Icons.location_on,
                const Color(0xFFE0509B),
              ),
              const SizedBox(height: 16),
              _buildCard(
                accentColor: const Color(0xFFE0509B),
                child: CustomTextField(
                  controller: _addressController,
                  hint: 'العنوان الكامل للعقار...',
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(
                'رفع الصور',
                Icons.image,
                const Color(0xFF5E5CE6),
              ),
              const SizedBox(height: 16),
              _buildCard(
                accentColor: const Color(0xFF5E5CE6),
                child: Column(
                  children: [
                    if (_selectedImages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return _buildImageThumb(index);
                            },
                          ),
                        ),
                      ),
                    _buildImagePickerArea(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'نشر العقار',
                onPressed: _submit,
                loading: _loading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.03),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(color: accent),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required Color accentColor}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppConstants.cardRadius),
                  bottomRight: Radius.circular(AppConstants.cardRadius),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: AppConstants.cardPadding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              hint: Text(
                'اختر $label',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppColors.success : AppColors.border,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.add_circle_outline,
              size: 16,
              color: value ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                color: value ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumb(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_selectedImages[index].path),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        if (_uploadProgress.containsKey(index) &&
            _uploadProgress[index]! < 1.0)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    value: _uploadProgress[index],
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildAddImageButton(
                icon: Icons.photo_library_outlined,
                label: 'معرض الصور',
                onTap: _pickImages,
              ),
              const SizedBox(width: 12),
              _buildAddImageButton(
                icon: Icons.camera_alt_outlined,
                label: 'كاميرا',
                onTap: _pickImageCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({
    this.color = Colors.grey,
  });

  static const double _strokeWidth = 1.5;
  static const double _dashWidth = 6;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      const Radius.circular(12),
    );

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + _dashWidth).clamp(0, metric.length).toDouble();
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
