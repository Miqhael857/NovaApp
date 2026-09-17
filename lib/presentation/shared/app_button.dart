import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final Color? bgColor;
  final Color? tColor;
  final FontWeight fontWeight;
  const AppButton({
    super.key,
    this.onTap,
    required this.text,
    this.bgColor,
    this.tColor,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: AppText(text, color: tColor, fontWeight: fontWeight),
      ),
    );
  }
}
