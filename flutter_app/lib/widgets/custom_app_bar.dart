import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final Color? backgroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBack = true,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading ??
          (showBack
              ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              )
              : null),
      actions: actions,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleLarge,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
