import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/features/wallethome/provider/transaction_provider.dart';
import 'package:novawallet/presentation/features/wallethome/transaction_view.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

/// The full history, reached from "See all" on Home.
///
/// Home shows a preview; this shows everything, still built lazily so a long
/// history costs nothing until it is scrolled. Anything still queued sits at
/// the top with a Pending chip, which is the point of coming here after a send
/// that went out while offline.
class AllTransactionsView extends ConsumerWidget {
  const AllTransactionsView({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    final services = await ref.read(novaPayServicesProvider.future);
    await services.sync.run();
    ref.invalidate(outboxItemsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionFeedProvider);

    return AppScaffold(
      // Its own header, matching the Send and Create-goal screens.
      hasAppBar: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 8.h, 16.w, 8.h),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 24.r,
                  color: AppColors.navy900,
                  tooltip: 'Back',
                ),
                AppText(
                  'Recent transactions',
                  fontSize: 20,
                  lineHeight: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy900,
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: transactions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Gap(100.h),
                        Center(
                          child: AppText(
                            'Nothing here yet.',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(14.w, 0, 16.w, 24.h),
                          // No limit: this is the whole history.
                          sliver: const TransactionSliverList(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
