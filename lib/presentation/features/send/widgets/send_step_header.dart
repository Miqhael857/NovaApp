import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/provider/send_step_provider.dart';
import 'package:novawallet/presentation/features/send/widgets/step_progress_indicator.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

class SendStepHeader extends ConsumerWidget {
  const SendStepHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(sendStepProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Step ${step.number} of 3 \u00b7 ${step.label}',
          fontSize: 12,
          lineHeight: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        Gap(12.h),
        StepProgressIndicator(currentStep: step.number),
      ],
    );
  }
}
