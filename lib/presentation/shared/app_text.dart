import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:novawallet/core/theme/app_color.dart';

class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.lineHeight = 20,
    this.fontWeight = FontWeight.w400,
    this.color,
    this.letterSpacing,
    this.tabular = false,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
  });

  final String? text;
  final double fontSize;
  final double lineHeight;
  final FontWeight fontWeight;
  final Color? color;
  final double? letterSpacing;

  /// Fixed-width digits. Use for money so columns of amounts stay aligned.
  final bool tabular;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? '',
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: semanticsLabel,
      style: TextStyle(
        fontSize: fontSize.sp,
        height: lineHeight.h / fontSize.sp,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color ?? AppColors.textPrimary,
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      ),
    );
  }
}
