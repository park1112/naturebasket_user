import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final Widget? leading;
  final Widget? flexibleSpace;
  final bool centerTitle;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.backgroundColor,
    this.textColor,
    this.height = kToolbarHeight,
    this.leading,
    this.flexibleSpace,
    this.centerTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      elevation: 0,
      leading: showBackButton
          ? leading ??
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: textColor ?? Colors.white,
                  size: 20,
                ),
                onPressed: () => Get.back(),
              )
          : null,
      actions: actions,
      flexibleSpace: flexibleSpace,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
