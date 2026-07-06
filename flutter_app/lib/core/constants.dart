import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'عقار اونلاين';
  static const String currency = 'ل.س';
  static const String currencyUsd = 'USD';

  static const double cardRadius = 20;
  static const double cardRadiusSmall = 16;
  static const double buttonRadius = 16;
  static const double inputRadius = 16;
  static const double appBarRadius = 24;

  static const EdgeInsets screenPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets screenHorizontalPadding = EdgeInsets.symmetric(horizontal: 20);

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 350);

  static const List<String> propertyTypes = [
    'شقة',
    'فيلا',
    'منزل',
    'أرض',
    'مكتب',
    'محل',
    'مستودع',
    'مزرعة',
  ];

  static const List<String> operationTypes = ['بيع', 'إيجار', 'استثمار'];

  static const List<String> governorates = [
    'دمشق',
    'حلب',
    'حمص',
    'اللاذقية',
    'طرطوس',
    'حماة',
    'إدلب',
    'دير الزور',
    'الرقة',
    'الحسكة',
    'السويداء',
    'درعا',
    'القنيطرة',
  ];
}
