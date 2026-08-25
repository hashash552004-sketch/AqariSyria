import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/imgbb_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/animated_widgets.dart';

class AddPropertyScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const AddPropertyScreen({super.key, this.onBackToHome});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen>
    with TickerProviderStateMixin {
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

  late final PageController _pageController;
  late final AnimationController _progressAnimController;
  late final Animation<double> _progressAnimation;

  int _currentStep = 0;
  static const int _totalSteps = 5;

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
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressAnimController, curve: Curves.easeOutCubic),
    );
    _progressAnimController.value = 1 / _totalSteps;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimController.dispose();
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

  void _nextStep() {
    if (_currentStep == 0 && _selectedImages.isEmpty) {
      _showError('يرجى إضافة صورة واحدة على الأقل');
      return;
    }
    if (_currentStep == 1) {
      if (_titleController.text.trim().isEmpty) {
        _showError('يرجى إدخال عنوان العقار');
        return;
      }
      if (_descController.text.trim().isEmpty) {
        _showError('يرجى إدخال وصف العقار');
        return;
      }
    }
    if (_currentStep == 2) {
      if (_priceController.text.trim().isEmpty) {
        _showError('يرجى إدخال السعر');
        return;
      }
      if (_areaController.text.trim().isEmpty) {
        _showError('يرجى إدخال المساحة');
        return;
      }
    }
    if (_currentStep == 3) {
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
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      _progressAnimController.animateTo(
        (_currentStep + 1) / _totalSteps,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      _progressAnimController.animateTo(
        (_currentStep + 1) / _totalSteps,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
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

  Future<String> _uploadSingleImage(XFile image, int index) async {
    setState(() => _uploadProgress[index] = 0.0);
    final url = await ImgBBService.uploadImage(File(image.path));
    setState(() => _uploadProgress[index] = 1.0);
    return url;
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;

    setState(() => _loading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('properties').doc();
      final propertyId = docRef.id;

      final List<String> imageUrls = await Future.wait(
        _selectedImages.asMap().entries.map((entry) => _uploadSingleImage(entry.value, entry.key)),
      );

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
        region: _regionController.text.trim().isNotEmpty
            ? _regionController.text.trim()
            : _region,
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
        status: 'pending',
      );

      await docRef.set({
        ...property.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      unawaited(_notifyAdminsNewProperty(property));

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ أثناء حفظ العقار. يرجى المحاولة مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _notifyAdminsNewProperty(Property property) async {
    try {
      final firestore = context.read<FirestoreService>();
      await firestore.notifyAdminsNewProperty(property);
    } catch (_) {}
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text('تم الإرسال بنجاح', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'تم إرسال عقارك للمراجعة. سيتم نشره بعد موافقة الإدارة.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              text: 'تم',
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onBackToHome?.call();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepInfo('الصور', Icons.photo_library_rounded, const Color(0xFF5E5CE6)),
      _StepInfo('المعلومات', Icons.edit_note_rounded, AppColors.primary),
      _StepInfo('التفاصيل', Icons.straighten_rounded, AppColors.success),
      _StepInfo('التصنيف', Icons.category_rounded, AppColors.warning),
      _StepInfo('الخدمات', Icons.apartment_rounded, const Color(0xFF9B51E0)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(steps),
          _buildStepIndicator(steps),
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildImagesStep(),
                  _buildInfoStep(),
                  _buildDetailsStep(),
                  _buildClassificationStep(),
                  _buildAmenitiesStep(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(List<_StepInfo> steps) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => widget.onBackToHome?.call(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cards,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إضافة عقار', style: AppTextStyles.titleLarge),
                  Text(
                    'الخطوة ${_currentStep + 1} من $_totalSteps',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: steps[_currentStep].color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(steps[_currentStep].icon, size: 16, color: steps[_currentStep].color),
                  const SizedBox(width: 6),
                  Text(
                    steps[_currentStep].label,
                    style: AppTextStyles.labelMedium.copyWith(color: steps[_currentStep].color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(List<_StepInfo> steps) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  minHeight: 5,
                  backgroundColor: AppColors.border.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    steps[_currentStep].color,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCurrent = index == _currentStep;
              return Expanded(
                child: GestureDetector(
                  onTap: index < _currentStep ? () {
                    setState(() => _currentStep = index);
                    _pageController.jumpToPage(index);
                    _progressAnimController.animateTo(
                      (index + 1) / _totalSteps,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  } : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.only(left: index < _totalSteps - 1 ? 6 : 0),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isCurrent ? 32 : 26,
                          height: isCurrent ? 32 : 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? steps[index].color : Colors.transparent,
                            border: Border.all(
                              color: isActive ? steps[index].color : AppColors.border,
                              width: isCurrent ? 2.5 : 1.5,
                            ),
                            boxShadow: isCurrent ? [
                              BoxShadow(
                                color: steps[index].color.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ] : null,
                          ),
                          child: Center(
                            child: isActive
                                ? Icon(
                                    index < _currentStep ? Icons.check_rounded : steps[index].icon,
                                    size: isCurrent ? 16 : 13,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          steps[index].label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? steps[index].color : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInSlide(
            delay: 0,
            child: _buildStepHeader(
              'صور العقار',
              'أضف صوراً واضحة وجذابة لجذب المشترين',
              Icons.photo_library_rounded,
              const Color(0xFF5E5CE6),
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedImages.isNotEmpty) ...[
            FadeInSlide(
              delay: 100,
              child: Text(
                'الصور المحددة (${_selectedImages.length})',
                style: AppTextStyles.labelLarge,
              ),
            ),
            const SizedBox(height: 12),
            FadeInSlide(
              delay: 150,
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => _buildImageThumb(index),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          FadeInSlide(
            delay: 200,
            child: _buildImagePickerArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInSlide(
            delay: 0,
            child: _buildStepHeader(
              'معلومات العقار',
              'أدخل العنوان والوصف التفصيلي',
              Icons.edit_note_rounded,
              AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          FadeInSlide(delay: 100, child: _buildGlassCard(
            accent: AppColors.primary,
            child: Column(
              children: [
                CustomTextField(
                  controller: _titleController,
                  label: 'عنوان العقار',
                  hint: 'مثال: فيلا فاخرة في المزة',
                  prefixIcon: Icons.title_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descController,
                  label: 'وصف العقار',
                  hint: 'اكتب تفاصيل العقار: الحالة، التصميم، المميزات...',
                  prefixIcon: Icons.description_rounded,
                  maxLines: 5,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInSlide(
            delay: 0,
            child: _buildStepHeader(
              'التفاصيل المالية والعقارية',
              'حدد السعر والمساحة والتفاصيل',
              Icons.straighten_rounded,
              AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          FadeInSlide(delay: 100, child: _buildGlassCard(
            accent: AppColors.success,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _priceController,
                        label: 'السعر',
                        hint: '0',
                        prefixText: AppConstants.currency,
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _areaController,
                        label: 'المساحة',
                        hint: '0',
                        prefixText: 'م²',
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('عدد الغرف والتفاصيل', style: AppTextStyles.labelLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCounterField('غرف', _roomsController, Icons.king_bed_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCounterField('حمامات', _bathroomsController, Icons.bathtub_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCounterField('طابق', _floorController, Icons.layers_rounded)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildClassificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInSlide(
            delay: 0,
            child: _buildStepHeader(
              'تصنيف العقار',
              'حدد النوع والموقع ونوع العملية',
              Icons.category_rounded,
              AppColors.warning,
            ),
          ),
          const SizedBox(height: 20),
          FadeInSlide(delay: 100, child: _buildGlassCard(
            accent: AppColors.warning,
            child: Column(
              children: [
                _buildPremiumDropdown(
                  label: 'نوع العقار',
                  value: _type,
                  items: AppConstants.propertyTypes,
                  icon: Icons.home_rounded,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(height: 16),
                _buildPremiumDropdown(
                  label: 'نوع العملية',
                  value: _operationType,
                  items: AppConstants.operationTypes,
                  icon: Icons.swap_horiz_rounded,
                  onChanged: (v) => setState(() => _operationType = v),
                ),
                const SizedBox(height: 16),
                _buildPremiumDropdown(
                  label: 'نوع الطابو',
                  value: _deedType,
                  items: const ['', 'طابو أخضر', 'ورثة', 'حكم محكمة', 'فروغ'],
                  icon: Icons.description_rounded,
                  onChanged: (v) => setState(() => _deedType = v),
                ),
                const SizedBox(height: 16),
                _buildPremiumDropdown(
                  label: 'المحافظة',
                  value: _governorate,
                  items: AppConstants.governorates,
                  icon: Icons.location_city_rounded,
                  onChanged: (v) => setState(() => _governorate = v),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _regionController,
                  label: 'المنطقة',
                  hint: 'مثال: المزة، الشعلان...',
                  prefixIcon: Icons.map_rounded,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'العنوان التفصيلي',
                  hint: 'العنوان الكامل للعقار...',
                  prefixIcon: Icons.pin_drop_rounded,
                  maxLines: 2,
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAmenitiesStep() {
    final amenities = [
      _AmenityData('مصعد', Icons.elevator_rounded, _hasElevator, (v) => setState(() => _hasElevator = v)),
      _AmenityData('موقف سيار', Icons.local_parking_rounded, _hasParking, (v) => setState(() => _hasParking = v)),
      _AmenityData('تكييف', Icons.ac_unit_rounded, _hasAC, (v) => setState(() => _hasAC = v)),
      _AmenityData('تدفئة', Icons.whatshot_rounded, _hasHeating, (v) => setState(() => _hasHeating = v)),
      _AmenityData('حديقة', Icons.park_rounded, _hasGarden, (v) => setState(() => _hasGarden = v)),
      _AmenityData('مسبح', Icons.pool_rounded, _hasPool, (v) => setState(() => _hasPool = v)),
      _AmenityData('شرفة', Icons.balcony_rounded, _hasBalcony, (v) => setState(() => _hasBalcony = v)),
      _AmenityData('إنترنت', Icons.wifi_rounded, _hasInternet, (v) => setState(() => _hasInternet = v)),
      _AmenityData('غاز', Icons.local_fire_department_rounded, _hasGas, (v) => setState(() => _hasGas = v)),
      _AmenityData('مفروش', Icons.chair_rounded, _isFurnished, (v) => setState(() => _isFurnished = v)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInSlide(
            delay: 0,
            child: _buildStepHeader(
              'الخدمات والمرافق',
              'حدد المميزات المتوفرة في العقار',
              Icons.apartment_rounded,
              const Color(0xFF9B51E0),
            ),
          ),
          const SizedBox(height: 20),
          FadeInSlide(
            delay: 100,
            child: _buildGlassCard(
              accent: const Color(0xFF9B51E0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: amenities.length,
                itemBuilder: (context, index) {
                  final a = amenities[index];
                  return FadeInSlide(
                    delay: 150 + index * 40,
                    child: _buildAmenityTile(a),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeInSlide(
            delay: 600,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'يمكنك تعديل هذه البيانات لاحقاً من إدارة العقار',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required Color accent}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterField(String label, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  final current = int.tryParse(controller.text) ?? 0;
                  if (current > 0) {
                    controller.text = (current - 1).toString();
                  }
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.remove_rounded, size: 18, color: AppColors.error),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 36,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  final current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current + 1).toString();
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18, color: AppColors.success),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value.isNotEmpty ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              hint: Text(
                'اختر $label',
                style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary),
              ),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 22),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textPrimary),
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

  Widget _buildAmenityTile(_AmenityData amenity) {
    return GestureDetector(
      onTap: () => amenity.onChanged(!amenity.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: amenity.value
              ? LinearGradient(
                  colors: [
                    const Color(0xFF9B51E0).withValues(alpha: 0.12),
                    const Color(0xFF9B51E0).withValues(alpha: 0.04),
                  ],
                )
              : null,
          color: amenity.value ? null : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: amenity.value ? const Color(0xFF9B51E0) : AppColors.border,
            width: amenity.value ? 1.5 : 1,
          ),
          boxShadow: amenity.value ? [
            BoxShadow(
              color: const Color(0xFF9B51E0).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: amenity.value
                    ? const Color(0xFF9B51E0)
                    : AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                amenity.icon,
                size: 14,
                color: amenity.value ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                amenity.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: amenity.value ? FontWeight.w700 : FontWeight.w500,
                  color: amenity.value ? const Color(0xFF9B51E0) : AppColors.textPrimary,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: amenity.value
                  ? Icon(Icons.check_circle_rounded, size: 16, color: const Color(0xFF9B51E0))
                  : Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.textSecondary),
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
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            File(_selectedImages[index].path),
            width: 110,
            height: 110,
            fit: BoxFit.cover,
          ),
        ),
        if (_uploadProgress.containsKey(index) && _uploadProgress[index]! < 1.0)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
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
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFF5E5CE6).withValues(alpha: 0.35),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildAddImageButton(
                icon: Icons.photo_library_outlined,
                label: 'معرض الصور',
                onTap: _pickImages,
                color: const Color(0xFF5E5CE6),
              ),
              const SizedBox(width: 12),
              _buildAddImageButton(
                icon: Icons.camera_alt_outlined,
                label: 'الكاميرا',
                onTap: _pickImageCamera,
                color: const Color(0xFF5E5CE6),
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
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.cards,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!isFirst)
              Expanded(
                child: GestureDetector(
                  onTap: _prevStep,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('السابق', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!isFirst) const SizedBox(width: 12),
            Expanded(
              flex: isFirst ? 1 : 1,
              child: GradientButton(
                text: isLast ? 'نشر العقار' : 'التالي',
                icon: isLast ? Icons.send_rounded : Icons.arrow_forward_ios_rounded,
                onPressed: isLast ? _submit : _nextStep,
                loading: _loading,
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepInfo {
  final String label;
  final IconData icon;
  final Color color;
  _StepInfo(this.label, this.icon, this.color);
}

class _AmenityData {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  _AmenityData(this.label, this.icon, this.value, this.onChanged);
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({this.color = Colors.grey});

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
      const Radius.circular(14),
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
