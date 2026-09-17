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
    // This is the widget behind "Confirm and send", "Add" and "Create goal" —
    // the three most consequential taps in the app. Without this a screen
    // reader announces the label as ordinary text, with no hint that it can be
    // activated and no way to tell an armed button from a disabled one.
    // excludeSemantics stops the inner AppText being read a second time.
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // A minimum rather than a fixed height: the label still grows with
          // the system font setting, but a short one cannot shrink the target
          // below the 48dp that a thumb needs.
          constraints: BoxConstraints(minHeight: 48.h),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.center,
          child: AppText(text, color: tColor, fontWeight: fontWeight),
        ),
      ),
    );
  }
}
