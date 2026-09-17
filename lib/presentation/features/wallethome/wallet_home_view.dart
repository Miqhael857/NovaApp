import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/features/wallethome/transaction_view.dart';
import 'package:novawallet/presentation/shared/app_balance_card_widget.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/routes.dart';

class WalletHomeScreen extends ConsumerWidget {
  const WalletHomeScreen({super.key});

  /// Pull-to-refresh replays anything still queued. The sync engine is
  /// single-flight, so pulling repeatedly cannot send the same action twice.
  Future<void> _refresh(WidgetRef ref) async {
    final services = await ref.read(novaPayServicesProvider.future);
    await services.sync.run();
    ref.invalidate(outboxItemsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineOverrideProvider);
    final queued = ref
        .watch(outboxItemsProvider)
        .maybeWhen(
          data: (items) => items.where((i) => i.needsSending).length,
          orElse: () => 0,
        );

    return AppScaffold(
      // The greeting below is this screen's header, so there is no app bar to
      // reserve space for.
      hasAppBar: false,
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          // Always scrollable, so pull-to-refresh still works when the content
          // is shorter than the screen.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(14.w, 8.h, 16.w, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText('Home', color: AppColors.navy900),
                            Gap(4.h),
                            AppText(
                              'Folake',
                              fontSize: 20,
                              lineHeight: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy900,
                            ),
                          ],
                        ),
                        CircleAvatar(
                          backgroundColor: AppColors.navy700,
                          child: AppText(
                            'FA',
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
                          ),
                        ),
                      ],
                    ),
                    Gap(15.h),

                    if (offline) ...[
                      _OfflineBanner(),
                      Gap(12.h),
                    ],

                    AppBalanceCardWidget(
                      text: 'NovaWallet balance',
                      subtitle: 'Updated 22:04 · Pull down to refresh',
                      balance: Kobo.fromNaira(20000),
                      onSend: () => context.pushNamed(RouteNames.sendRecipient),
                      onSave: () => context.goNamed(RouteNames.save),
                    ),

                    if (queued > 0) ...[
                      Gap(12.h),
                      _PendingStrip(count: queued),
                    ],

                    Gap(20.h),
                    _NovaSaveTile(
                      onTap: () => context.goNamed(RouteNames.save),
                    ),
                    Gap(20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          'Recent transactions',
                          fontSize: 16,
                          lineHeight: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy700,
                        ),
                        AppText(
                          'See all',
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy700,
                        ),
                      ],
                    ),
                    Gap(20.h),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 16.w, 24.h),
              sliver: const TransactionSliverList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the app is offline. Status is never colour alone: the icon and
/// the words carry it too.
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.offlineBanner,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 20.r, color: AppColors.surface),
            Gap(8.w),
            Expanded(
              child: AppText(
                "You're offline — we'll send when you're back. "
                'No data? Dial *894#.',
                fontSize: 12,
                lineHeight: 16,
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the brief asks to be visible: queued actions are not lost, and the user
/// is told so in plain words.
class _PendingStrip extends StatelessWidget {
  const _PendingStrip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.pendingBg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, size: 20.r, color: AppColors.pending),
            Gap(8.w),
            Expanded(
              child: AppText(
                count == 1
                    ? 'Pending — will send when back online'
                    : '$count actions pending — will send when back online',
                fontSize: 12,
                lineHeight: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.pending,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovaSaveTile extends StatelessWidget {
  const _NovaSaveTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'NovaSave, ₦412,500.00 saved across 3 goals',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.goldTint,
                child: Icon(
                  Icons.savings_outlined,
                  size: 20.r,
                  color: AppColors.navy700,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'NovaSave',
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy900,
                    ),
                    Gap(4.h),
                    AppText(
                      '₦412,500.00 saved across 3 goals',
                      fontSize: 12,
                      lineHeight: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 15.r,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
