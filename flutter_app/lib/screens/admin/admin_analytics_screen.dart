import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_app_bar.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<Property> _allProps = [];
  late AnimationController _animController;

  int _totalProps = 0;
  int _publishedProps = 0;
  int _pendingProps = 0;
  int _rejectedProps = 0;
  int _soldProps = 0;
  int _featuredProps = 0;

  List<int> _propsPerDay = [];
  List<int> _usersPerDay = [];
  List<int> _propsPerMonth = [];
  List<int> _usersPerMonth = [];

  int _dateFilterIndex = 3;

  static const _dayLabels = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
  static const _monthLabels = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final fs = context.read<FirestoreService>();
    try {
      final props = await fs.getAllPropertiesAdmin();

      final usersSnap = await FirebaseFirestore.instance.collection('users').get();

      if (!mounted) return;

      _computeStats(props, usersSnap.docs);

      setState(() {
        _allProps = props;
        _totalProps = props.length;
        _publishedProps = props.where((p) => p.status == 'published').length;
        _pendingProps = props.where((p) => p.status == 'pending').length;
        _rejectedProps = props.where((p) => p.status == 'rejected').length;
        _soldProps = props.where((p) => p.isSold).length;
        _featuredProps = props.where((p) => p.isFeatured).length;
        _loading = false;
      });
      _animController.forward();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _computeStats(List<Property> props, List<QueryDocumentSnapshot> userDocs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    DateTime filterStart;
    switch (_dateFilterIndex) {
      case 0:
        filterStart = todayStart;
        break;
      case 1:
        filterStart = todayStart.subtract(const Duration(days: 6));
        break;
      case 2:
        filterStart = todayStart.subtract(const Duration(days: 29));
        break;
      default:
        filterStart = DateTime(2000);
        break;
    }

    _propsPerDay = List.filled(7, 0);
    _usersPerDay = List.filled(7, 0);
    _propsPerMonth = List.filled(12, 0);
    _usersPerMonth = List.filled(12, 0);

    for (final p in props) {
      final c = p.createdAt;
      if (c != null && c.isAfter(filterStart)) {
        _propsPerDay[c.weekday % 7]++;
      }
      if (c != null) {
        _propsPerMonth[c.month - 1]++;
      }
    }

    for (final doc in userDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        final c = createdAt.toDate();
        if (c.isAfter(filterStart)) {
          _usersPerDay[c.weekday % 7]++;
        }
        _usersPerMonth[c.month - 1]++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'التقارير والإحصائيات'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppConstants.screenHorizontalPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildDateFilter(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('ملخص العقارات', Icons.pie_chart_rounded),
                    const SizedBox(height: 12),
                    _buildPropertyStatusCards(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('العقارات الحالية', Icons.bar_chart_rounded),
                    const SizedBox(height: 12),
                    _buildPieChart(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('عقارات آخر 7 أيام', Icons.show_chart_rounded),
                    const SizedBox(height: 12),
                    _buildBarChart(_propsPerDay, _dayLabels, AppColors.primary),
                    const SizedBox(height: 24),
                    _buildSectionTitle('مستخدمين آخر 7 أيام', Icons.people_rounded),
                    const SizedBox(height: 12),
                    _buildBarChart(_usersPerDay, _dayLabels, AppColors.success),
                    const SizedBox(height: 24),
                    _buildSectionTitle('العقارات الشهرية', Icons.calendar_month_rounded),
                    const SizedBox(height: 12),
                    _buildBarChart(_propsPerMonth, _monthLabels, AppColors.accent),
                    const SizedBox(height: 24),
                    _buildSectionTitle('المستخدمين الشهريين', Icons.groups_rounded),
                    const SizedBox(height: 12),
                    _buildBarChart(_usersPerMonth, _monthLabels, AppColors.warning),
                    const SizedBox(height: 24),
                    _buildSectionTitle('العقارات المرفوضة', Icons.cancel_rounded),
                    const SizedBox(height: 12),
                    _buildRejectedList(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('العقارات المباعة', Icons.shopping_cart_rounded),
                    const SizedBox(height: 12),
                    _buildSoldList(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateFilter() {
    final filters = [
      (0, 'اليوم'),
      (1, '7 أيام'),
      (2, '30 يوم'),
      (3, 'الكل'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: filters.map((f) {
          final selected = _dateFilterIndex == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _dateFilterIndex = f.$1);
                _computeStats(_allProps, []);
                _animController.forward(from: 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    f.$2,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleLarge),
      ],
    );
  }

  Widget _buildPropertyStatusCards() {
    final cards = [
      _StatusCardData('الكل', _totalProps, Icons.home_work_rounded, AppColors.primary),
      _StatusCardData('منشورة', _publishedProps, Icons.check_circle_rounded, AppColors.success),
      _StatusCardData('قيد المراجعة', _pendingProps, Icons.hourglass_top_rounded, AppColors.warning),
      _StatusCardData('مرفوضة', _rejectedProps, Icons.cancel_rounded, AppColors.error),
      _StatusCardData('مباعة', _soldProps, Icons.payments_rounded, const Color(0xFF76C7FF)),
      _StatusCardData('مميزة', _featuredProps, Icons.star_rounded, const Color(0xFFD4AF37)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final c = cards[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(c.icon, size: 22, color: c.color),
              const SizedBox(height: 6),
              Text('${c.value}', style: AppTextStyles.titleLarge.copyWith(fontSize: 20)),
              const SizedBox(height: 2),
              FittedBox(child: Text(c.label, style: AppTextStyles.bodySmall)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart() {
    if (_totalProps == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('لا توجد عقارات', style: AppTextStyles.bodyMedium),
      );
    }

    final slices = [
      _PieSlice('منشورة', _publishedProps, AppColors.success),
      _PieSlice('قيد المراجعة', _pendingProps, AppColors.warning),
      _PieSlice('مرفوضة', _rejectedProps, AppColors.error),
    ].where((s) => s.value > 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _PieChartPainter(slices, _totalProps),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_totalProps', style: AppTextStyles.headlineLarge.copyWith(fontSize: 24)),
                      Text('عقار', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: slices.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.label, style: AppTextStyles.bodySmall)),
                    Text('${s.value}', style: AppTextStyles.titleMedium.copyWith(fontSize: 14)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<int> data, List<String> labels, Color color) {
    final maxVal = data.reduce(math.max).toDouble();
    if (maxVal == 0) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('لا توجد بيانات', style: AppTextStyles.bodyMedium),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(data.length, (i) {
                    final ratio = maxVal > 0 ? data[i] / maxVal : 0.0;
                    final barHeight = 120.0 * ratio * _animController.value;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (data[i] > 0)
                              Text('${data[i]}', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Container(
                              height: math.max(barHeight, 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.5)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: labels.map((l) => Expanded(
              child: Text(l, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 9)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedList() {
    final rejected = _allProps.where((p) => p.status == 'rejected').toList();
    if (rejected.isEmpty) {
      return _buildEmptyCard('لا توجد عقارات مرفوضة');
    }
    return Column(
      children: rejected.take(10).map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home_work, size: 16, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(child: Text(p.title, style: AppTextStyles.titleMedium.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                Text('${p.price.toStringAsFixed(0)} ${AppConstants.currency}', style: AppTextStyles.priceSmall),
              ],
            ),
            if (p.rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(child: Text(p.rejectionReason, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                  ],
                ),
              ),
            ],
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSoldList() {
    final sold = _allProps.where((p) => p.isSold).toList();
    if (sold.isEmpty) {
      return _buildEmptyCard('لا توجد عقارات مباعة');
    }
    return Column(
      children: sold.take(10).map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_circle, size: 18, color: AppColors.success),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: AppTextStyles.titleMedium.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(p.ownerName, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Text('${p.price.toStringAsFixed(0)} ${AppConstants.currency}', style: AppTextStyles.priceSmall),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: AppTextStyles.bodyMedium),
    );
  }
}

class _StatusCardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatusCardData(this.label, this.value, this.icon, this.color);
}

class _PieSlice {
  final String label;
  final int value;
  final Color color;
  _PieSlice(this.label, this.value, this.color);
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;
  final int total;
  _PieChartPainter(this.slices, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final innerRadius = radius * 0.55;

    double startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = 2 * math.pi * (slice.value / total);
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    final bgPaint = Paint()
      ..color = AppColors.cards
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, bgPaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) => oldDelegate.total != total;
}
