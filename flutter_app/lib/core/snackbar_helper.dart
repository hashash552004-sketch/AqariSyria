import 'package:flutter/material.dart';
import 'app_colors.dart';

void showSnackBar(BuildContext context, String message, {Color? backgroundColor, Duration? duration}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor ?? AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
