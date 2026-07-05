import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/firestore_service.dart';
import '../../widgets/property_card.dart';
import '../../widgets/loading_skeleton.dart';
import 'advanced_filters_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _typeFilter = 'الكل';
  String _operationFilter = 'الكل';
  String _governorateFilter = 'الكل';
  String? _priceFilter;
  final bool _showFilters = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildResults(firestore),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.cards,
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(fontSize: 15, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن عقار...',
                        hintStyle: GoogleFonts.cairo(fontSize: 15, color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) => setState(() => _query = value.toLowerCase()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AdvancedFiltersScreen(),
                  );
                  if (result != null && mounted) {
                    setState(() {
                      if (result['type'] != null) _typeFilter = result['type'] as String;
                      if (result['operation'] != null) _operationFilter = result['operation'] as String;
                      if (result['governorate'] != null) _governorateFilter = result['governorate'] as String;
                      final price = result['price'] as String?;
                      _priceFilter = (price != null && price.isNotEmpty) ? price : null;
                    });
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: _buildFilterChips(),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _showFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip('نوع العقار', _typeFilter, AppConstants.propertyTypes, (v) {
                setState(() => _typeFilter = v);
              }),
              const SizedBox(width: 8),
              _filterChip('نوع العملية', _operationFilter, AppConstants.operationTypes, (v) {
                setState(() => _operationFilter = v);
              }),
              const SizedBox(width: 8),
              _filterChip('المحافظة', _governorateFilter, ['الكل', ...AppConstants.governorates], (v) {
                setState(() => _governorateFilter = v);
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('نتائج البحث', style: AppTextStyles.labelMedium),
            const Spacer(),
            if (_typeFilter != 'الكل' || _operationFilter != 'الكل' || _governorateFilter != 'الكل' || _priceFilter != null)
              GestureDetector(
                onTap: () => setState(() {
                  _typeFilter = 'الكل';
                  _operationFilter = 'الكل';
                  _governorateFilter = 'الكل';
                  _priceFilter = null;
                }),
                child: Text('إعادة تعيين', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(String label, String currentValue, List<String> options, ValueChanged<String> onSelected) {
    return GestureDetector(
      onTap: () => _showFilterDropdown(context, label, options, currentValue, onSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: currentValue != 'الكل' ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: currentValue != 'الكل' ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentValue,
              style: AppTextStyles.labelSmall.copyWith(
                color: currentValue != 'الكل' ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: currentValue != 'الكل' ? AppColors.primary : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showFilterDropdown(BuildContext context, String label, List<String> options, String current, ValueChanged<String> onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ...options.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  title: Text(opt, style: AppTextStyles.bodyLarge),
                  trailing: opt == current
                      ? Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    onSelected(opt);
                    Navigator.pop(context);
                  },
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(FirestoreService firestore) {
    return StreamBuilder<List<Property>>(
      stream: firestore.streamProperties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 4,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: PropertyCardSkeleton(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('لا توجد عقارات متاحة');
        }

        var results = snapshot.data!;

        if (_query.isNotEmpty) {
          results = results.where((p) =>
            p.title.toLowerCase().contains(_query) ||
            p.governorate.toLowerCase().contains(_query) ||
            p.region.toLowerCase().contains(_query) ||
            p.neighborhood.toLowerCase().contains(_query)
          ).toList();
        }
        if (_typeFilter != 'الكل') {
          results = results.where((p) => p.type == _typeFilter).toList();
        }
        if (_operationFilter != 'الكل') {
          results = results.where((p) => p.operationType == _operationFilter).toList();
        }
        if (_governorateFilter != 'الكل') {
          results = results.where((p) => p.governorate == _governorateFilter).toList();
        }
        if (_priceFilter != null) {
          final maxPrice = double.tryParse(_priceFilter!);
          if (maxPrice != null) {
            results = results.where((p) => p.price <= maxPrice).toList();
          }
        }

        if (results.isEmpty) {
          return _buildEmptyState('لا توجد نتائج للبحث');
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: ListView.builder(
            key: ValueKey('${_query}_${_typeFilter}_${_operationFilter}_${_governorateFilter}_$_priceFilter'),
            padding: const EdgeInsets.all(20),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PropertyCard(property: results[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(message, style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text('حاول تعديل معايير البحث', style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
