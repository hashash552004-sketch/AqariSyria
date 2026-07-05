import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

class AdvancedFiltersScreen extends StatefulWidget {
  const AdvancedFiltersScreen({super.key});

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  final _priceController = TextEditingController();
  RangeValues _areaRange = const RangeValues(0, 1000);
  int? _rooms;
  int? _bathrooms;
  int? _floor;
  String _type = 'الكل';
  String _operation = 'الكل';
  String _governorate = 'الكل';

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

  final List<String> _types = ['الكل', ...AppConstants.propertyTypes];
  final List<String> _operations = ['الكل', ...AppConstants.operationTypes];
  final List<String> _governorates = ['الكل', ...AppConstants.governorates];
  final List<int> _roomOptions = [0, 1, 2, 3, 4, 5, 6];
  final List<int> _bathroomOptions = [0, 1, 2, 3, 4, 5];
  final List<int> _floorOptions = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _priceController.clear();
      _areaRange = const RangeValues(0, 1000);
      _rooms = null;
      _bathrooms = null;
      _floor = null;
      _type = 'الكل';
      _operation = 'الكل';
      _governorate = 'الكل';
      _hasElevator = false;
      _hasParking = false;
      _hasAC = false;
      _hasHeating = false;
      _hasGarden = false;
      _hasPool = false;
      _hasBalcony = false;
      _hasInternet = false;
      _hasGas = false;
      _isFurnished = false;
    });
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'type': _type == 'الكل' ? null : _type,
      'operation': _operation == 'الكل' ? null : _operation,
      'governorate': _governorate == 'الكل' ? null : _governorate,
      'price': _priceController.text,
      'minArea': _areaRange.start,
      'maxArea': _areaRange.end,
      'rooms': _rooms,
      'bathrooms': _bathrooms,
      'floor': _floor,
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('فلترة متقدمة', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    Text('اختر المعايير المناسبة للعقار', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 24),
                    _buildPriceInput(),
                    const SizedBox(height: 24),
                    _buildAreaRange(),
                    const SizedBox(height: 24),
                    _buildDropdownRow(),
                    const SizedBox(height: 24),
                    _buildTypeChips(),
                    const SizedBox(height: 24),
                    _buildOperationChips(),
                    const SizedBox(height: 24),
                    _buildGovernorateDropdown(),
                    const SizedBox(height: 24),
                    _buildAmenities(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInput() {
    return CustomTextField(
      controller: _priceController,
      label: 'السعر',
      hint: 'أدخل السعر بالليرة السورية',
      prefixIcon: Icons.price_change_outlined,
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildAreaRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نطاق المساحة (م²)', style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(
          'من ${_areaRange.start.toStringAsFixed(0)} إلى ${_areaRange.end.toStringAsFixed(0)} م²',
          style: AppTextStyles.bodySmall,
        ),
        RangeSlider(
          values: _areaRange,
          min: 0,
          max: 1000,
          divisions: 100,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
          labels: RangeLabels(
            _areaRange.start.toStringAsFixed(0),
            _areaRange.end.toStringAsFixed(0),
          ),
          onChanged: (values) => setState(() => _areaRange = values),
        ),
      ],
    );
  }

  Widget _buildDropdownRow() {
    return Row(
      children: [
        Expanded(child: _buildDropdown('غرف', _rooms, _roomOptions, (v) {
          setState(() => _rooms = v);
        })),
        const SizedBox(width: 12),
        Expanded(child: _buildDropdown('حمامات', _bathrooms, _bathroomOptions, (v) {
          setState(() => _bathrooms = v);
        })),
        const SizedBox(width: 12),
        Expanded(child: _buildDropdown('الطابق', _floor, _floorOptions, (v) {
          setState(() => _floor = v);
        })),
      ],
    );
  }

  Widget _buildDropdown(String label, int? value, List<int> options, ValueChanged<int?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: value,
              isExpanded: true,
              hint: Text('الكل', style: AppTextStyles.bodyMedium),
              style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textPrimary),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              items: [
                DropdownMenuItem(value: null, child: Text('الكل', style: AppTextStyles.bodyMedium)),
                ...options.map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text('$opt', style: AppTextStyles.bodyLarge),
                )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نوع العقار', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _types.map((t) => GestureDetector(
            onTap: () => setState(() => _type = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: _type == t ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _type == t ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(t, style: AppTextStyles.labelSmall.copyWith(
                color: _type == t ? Colors.white : AppColors.textSecondary,
              )),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildOperationChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نوع العملية', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _operations.map((o) => GestureDetector(
            onTap: () => setState(() => _operation = o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: _operation == o ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _operation == o ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(o, style: AppTextStyles.labelSmall.copyWith(
                color: _operation == o ? Colors.white : AppColors.textSecondary,
              )),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildGovernorateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المحافظة', style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _governorate,
              isExpanded: true,
              style: GoogleFonts.cairo(fontSize: 15, color: AppColors.textPrimary),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              items: _governorates.map((g) => DropdownMenuItem(
                value: g,
                child: Text(g, style: AppTextStyles.bodyLarge),
              )).toList(),
              onChanged: (v) => setState(() => _governorate = v ?? 'الكل'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    final amenities = [
      {'label': 'مصعد', 'value': _hasElevator, 'onChanged': (v) => setState(() => _hasElevator = v)},
      {'label': 'موقف سيارة', 'value': _hasParking, 'onChanged': (v) => setState(() => _hasParking = v)},
      {'label': 'تكييف', 'value': _hasAC, 'onChanged': (v) => setState(() => _hasAC = v)},
      {'label': 'تدفئة', 'value': _hasHeating, 'onChanged': (v) => setState(() => _hasHeating = v)},
      {'label': 'حديقة', 'value': _hasGarden, 'onChanged': (v) => setState(() => _hasGarden = v)},
      {'label': 'مسبح', 'value': _hasPool, 'onChanged': (v) => setState(() => _hasPool = v)},
      {'label': 'شرفة', 'value': _hasBalcony, 'onChanged': (v) => setState(() => _hasBalcony = v)},
      {'label': 'إنترنت', 'value': _hasInternet, 'onChanged': (v) => setState(() => _hasInternet = v)},
      {'label': 'غاز', 'value': _hasGas, 'onChanged': (v) => setState(() => _hasGas = v)},
      {'label': 'مفروش', 'value': _isFurnished, 'onChanged': (v) => setState(() => _isFurnished = v)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الخدمات والمرافق', style: AppTextStyles.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: amenities.map((a) => FilterChip(
            label: Text(a['label'] as String, style: AppTextStyles.labelSmall),
            selected: a['value'] as bool,
            onSelected: a['onChanged'] as ValueChanged<bool>,
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            backgroundColor: AppColors.background,
            side: BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        GradientButton(
          text: 'تطبيق',
          width: double.infinity,
          onPressed: _applyFilters,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _resetFilters,
          child: Text('إعادة تعيين', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
