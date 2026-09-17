import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/model/recipient_model.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

class SendRecipientWidget extends StatelessWidget {
  const SendRecipientWidget({
    super.key,
    required this.recipientmodel,
    required this.onTap,
  });

  final RecipientModel recipientmodel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 64.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.navyTint,
                shape: BoxShape.circle,
              ),
              child: AppText(
                recipientmodel.initials,
                fontWeight: FontWeight.w700,
                color: AppColors.navy700,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    recipientmodel.name,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy900,
                  ),
                  AppText(
                    '${recipientmodel.bank} \u00b7 ${recipientmodel.masked}',
                    fontSize: 12,
                    lineHeight: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
