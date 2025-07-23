
// lib/widgets/app_logo.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const AppLogo({
    Key? key,
    this.size = 60,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.27),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(
        Icons.verified_user,
        size: size,
        color: iconColor ?? AppTheme.primaryColor,
      ),
    );
  }
}