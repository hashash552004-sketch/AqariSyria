import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

class EditPropertyScreen extends StatefulWidget {
  final Property property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _areaController;
  late final TextEditingController _roomsController;
  late final TextEditingController _bathroomsController;
  late final TextEditingController _floorController;
  late final TextEditingController _addressController;
  late final TextEditingController _regionController;

  late String _type;
  late String _operationType;
  late String _governorate;
  late String _region;

  late bool _hasElevator;
  late bool _hasParking;
  late bool _hasAC;
  late bool _hasHeating;
  late bool _hasGarden;
  late bool _hasPool;
  late bool _hasBalcony;
  late bool _hasInternet;
  late bool _hasGas;
  late bool _isFurnished;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _titleController = TextEditingController(text: p.title);
    _descController = TextEditingController(text: p.description);
    _priceController = TextEditingController(text: p.price.toString());
    _areaController = TextEditingController(text: p.area.toString());
    _roomsController = TextEditingController(text: p.rooms.toString());
    _bathroomsController = TextEditingController(text: p.bathrooms.toString());
    _floorController = TextEditingController(text: p.floor.toString());
    _addressController = TextEditingController(text: p.detailedAddress);
    _regionController = TextEditingController(text: p.region);

    _type = p.type;
    _operationType = p.operationType;
    _governorate = p.governorate;
    _region = p.region;

    _hasElevator = p.hasElevator;
    _hasParking = p.hasParking;
    _hasAC = p.hasAC;
    _hasHeating = p.hasHeating;
    _hasGarden = p.hasGarden;
    _hasPool = p.hasPool;
    _hasBalcony = p.hasBalcony;
    _hasInternet = p.hasInternet;
    _hasGas = p.hasGas;
    _isFurnished = p.isFurnished;
  }

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

  Future<void> _save() async {
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

    setState(() => _loading = true);

    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'type': _type,
      'operationType': _operationType,
      'price': double.tryParse(_priceController.text) ?? 0,
      'area': double.tryParse(_areaController.text) ?? 0,
      'rooms': int.tryParse(_roomsController.text) ?? 0,
      'bathrooms': int.tryParse(_bathroomsController.text) ?? 0,
      'floor': int.tryParse(_floorController.text) ?? 0,
      'governorate': _governorate,
      'region': _region,
      'detailedAddress': _addressController.text.trim(),
      'hasElevator': _hasElevator,
      'hasParking': _hasParking,
      'hasAC': _hasAC,
      'hasHeating': _hasHeating,
      'hasGarden': _hasGarden,
      'hasPool': _hasPool,
      'hasBalcony': _hasBalcony,
      'hasInternet': _hasInternet,
      'hasGas': _hasGas,
      'isFurnished': _isFurnished,
    };

    try {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(widget.property.id)
          .update(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التعديلات بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
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
      appBar: const CustomAppBar(title: 'تعديل العقار'),
      body: SingleChildScrollView(
        padding: AppConstants.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('معلومات العقار'),
              const SizedBox(height: 16),
              _buildCard(
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
              _buildSectionTitle('التفاصيل المالية والعقارية'),
              const SizedBox(height: 16),
              _buildCard(
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
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _areaController,
                            label: 'المساحة (م²)',
                            hint: '١٥٠',
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
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
              _buildSectionTitle('التصنيف'),
              const SizedBox(height: 16),
              _buildCard(
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
              _buildSectionTitle('الخدمات'),
              const SizedBox(height: 16),
              _buildCard(
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
              _buildSectionTitle('العنوان التفصيلي'),
              const SizedBox(height: 16),
              _buildCard(
                child: CustomTextField(
                  controller: _addressController,
                  hint: 'العنوان الكامل للعقار...',
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'حفظ التعديلات',
                onPressed: _save,
                loading: _loading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.titleMedium);
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
      child: child,
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
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppColors.primary : AppColors.border,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.add_circle_outline,
              size: 16,
              color: value ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                color: value ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
