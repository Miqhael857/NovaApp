import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/presentation/features/wallethome/widgets/card_button_widget.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/core/theme/app_color.dart';

class AppBalanceCardWidget extends StatefulWidget {
  const AppBalanceCardWidget({
    super.key,
    required this.balance,
    this.onSend,
    this.onSave,
    this.text,
    this.subtitle,
    this.showButton = true,
  });

  final Kobo balance;
  final VoidCallback? onSend;
  final VoidCallback? onSave;
  final String? text;
  final String? subtitle;
  final bool showButton;

  @override
  State<AppBalanceCardWidget> createState() => _AppBalanceCardWidgetState();
}

class _AppBalanceCardWidgetState extends State<AppBalanceCardWidget> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final amount = widget.balance.format(); // ₦248,350.75
    final dot = amount.lastIndexOf('.');
    final naira = amount.substring(0, dot); // ₦248,350
    final kobo = amount.substring(dot); // .75

    return Container(
      padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.navy900,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AppText(
                  widget.text ?? '',
                  fontWeight: FontWeight.w500,
                  color: AppColors.onNavySecondary,
                ),
              ),
              _EyeButton(
                hidden: _hidden,
                onTap: () => setState(() => _hidden = !_hidden),
              ),
            ],
          ),
          Gap(10.h),
          Semantics(
            label: _hidden
                ? 'NovaWallet balance hidden'
                : 'NovaWallet balance $amount',
            excludeSemantics: true,
            child: _hidden
                ? AppText(
                    '₦ ••••••',
                    fontSize: 32,
                    lineHeight: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.surface,
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: AppText(
                          naira,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.surface,
                          tabular: true,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppText(
                        kobo,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.surface,
                        tabular: true,
                      ),
                    ],
                  ),
          ),
          Gap(16.h),
          AppText(
            widget.subtitle,
            fontSize: 12,
            lineHeight: 16,
            color: AppColors.onNavySecondary,
          ),
          Gap(16.h),
          if (widget.showButton == true) ...[
            Row(
              children: [
                Expanded(
                  child: CardButtonWidget(
                    icon: Icons.arrow_outward,
                    label: 'Send',
                    primary: true,
                    onTap: widget.onSend,
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: CardButtonWidget(
                    icon: Icons.savings_outlined,
                    label: 'Save',
                    primary: false,
                    onTap: widget.onSave,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({required this.hidden, required this.onTap});

  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hidden ? 'Show balance' : 'Hide balance',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48.w,
          height: 48.w,
          child: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20.r,
            color: AppColors.onNavySecondary,
          ),
        ),
      ),
    );
  }
}
