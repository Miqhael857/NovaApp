import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/core/theme/app_color.dart';

class CardButtonWidget extends StatelessWidget {
  const CardButtonWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? AppColors.navy900 : AppColors.surface;
    final radius = BorderRadius.circular(12.r);

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: primary ? AppColors.gold500 : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            constraints: BoxConstraints(minHeight: 48.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: primary
                ? null
                : BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: AppColors.onNavySecondary,
                      width: 1.5,
                    ),
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20.r, color: foreground),
                Gap(8.w),
                Flexible(
                  child: AppText(
                    label,
                    fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
