import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/report.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/loading_skeleton.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  final _searchController = TextEditingController();
  late TabController _tabController;
  int _selectedTab = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'التقارير'),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(child: _buildReports()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'ابحث عن بلاغ...',
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'الكل'),
          Tab(text: 'معلّق'),
          Tab(text: 'محلول'),
        ],
      ),
    );
  }

  Widget _buildReports() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        setState(() {});
      },
      child: StreamBuilder<List<Report>>(
        stream: _firestore.streamReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          var reports = snapshot.data ?? [];

          reports = reports.where((r) {
            switch (_selectedTab) {
              case 1:
                return r.status == 'pending';
              case 2:
                return r.status == 'resolved';
              default:
                return true;
            }
          }).toList();

          if (_searchQuery.isNotEmpty) {
            reports = reports.where((r) {
              return r.propertyId.toLowerCase().contains(_searchQuery) ||
                  r.reason.toLowerCase().contains(_searchQuery);
            }).toList();
          }

          if (reports.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _buildReportCard(reports[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: AppConstants.screenPadding,
      itemCount: 4,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonCard(height: 200),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('لا توجد بلاغات', style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(report.createdAt);
    final statusColor =
        report.status == 'resolved' ? AppColors.success : AppColors.warning;
    final statusText =
        report.status == 'resolved' ? 'محلول' : 'معلّق';
    final reasonTranslations = <String, String>{
      'إعلان مزيف': 'إعلان مزيف',
      'معلومات خاطئة': 'معلومات خاطئة',
      'احتيال': 'احتيال',
      'إعلان مكرر': 'إعلان مكرر',
      'أخرى': 'أخرى',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.labelSmall.copyWith(color: statusColor),
                ),
              ),
              const Spacer(),
              Text(dateStr, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.report_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                reasonTranslations[report.reason] ?? report.reason,
                style: AppTextStyles.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildPropertyInfo(report.propertyId),
          const SizedBox(height: 6),
          _buildReporterInfo(report.reportedBy),
          if (report.description != null && report.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(report.description!, style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (report.status != 'resolved') ...[
            const SizedBox(height: 12),
            GradientButton(
              text: 'حل البلاغ',
              icon: Icons.check_circle_outline,
              height: 40,
              onPressed: () async {
                await _firestore.resolveReport(report.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حل البلاغ'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPropertyInfo(String propertyId) {
    return FutureBuilder<String?>(
      future: _firestore.getPropertyTitle(propertyId),
      builder: (context, snapshot) {
        final title = snapshot.data;
        return Row(
          children: [
            const Icon(Icons.home_work_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title != null ? '$title (${propertyId.substring(0, 6)}...)' : 'معرف العقار: $propertyId',
                style: AppTextStyles.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReporterInfo(String reportedBy) {
    return FutureBuilder<String?>(
      future: _firestore.getUserName(reportedBy),
      builder: (context, snapshot) {
        final name = snapshot.data;
        return Row(
          children: [
            const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              name != null ? 'المبلغ: $name' : 'المبلغ: $reportedBy',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );
      },
    );
  }
}
