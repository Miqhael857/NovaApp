import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

/// Account details, plus the controls that make the offline behaviour
/// demonstrable without touching the device's radio.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineOverrideProvider);
    final queue = ref.watch(outboxItemsProvider);

    final pending = queue.maybeWhen(
      data: (items) => items.where((i) => i.needsSending).length,
      orElse: () => 0,
    );

    return AppScaffold(
      hasAppBar: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        children: [
          AppText(
            'Profile',
            fontSize: 24,
            lineHeight: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.navy900,
          ),
          Gap(16.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
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
                    'FA',
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
                        'Folake Adeyemi',
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy900,
                      ),
                      AppText(
                        'Tier 1 · NovaPay wallet',
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
          Gap(24.h),

          AppText(
            'Developer',
            fontSize: 16,
            lineHeight: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.navy900,
          ),
          Gap(12.h),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Airplane mode is the real demo, but an emulator that refuses
                // to drop its connection would take the demo with it. This is
                // the backup, and it exercises exactly the same code path.
                SwitchListTile.adaptive(
                  value: offline,
                  onChanged: (value) =>
                      ref.read(offlineOverrideProvider.notifier).setOffline(value),
                  activeThumbColor: AppColors.gold500,
                  title: AppText(
                    'Simulate offline',
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy900,
                  ),
                  subtitle: AppText(
                    offline
                        ? "Sends and contributions are being queued on this phone."
                        : 'Force the app to behave as if there is no network.',
                    fontSize: 12,
                    lineHeight: 16,
                    color: offline
                        ? AppColors.pending
                        : AppColors.textSecondary,
                  ),
                ),
                Container(height: 1, color: AppColors.border),
                ListTile(
                  title: AppText(
                    'Waiting to send',
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy900,
                  ),
                  subtitle: AppText(
                    pending == 0
                        ? 'Nothing queued.'
                        : '$pending action${pending == 1 ? '' : 's'} queued on '
                              'this phone.',
                    fontSize: 12,
                    lineHeight: 16,
                    color: AppColors.textSecondary,
                  ),
                  trailing: TextButton(
                    // Manual trigger for the demo. The engine is single-flight,
                    // so pressing it repeatedly cannot double-send.
                    onPressed: () async {
                      final services = await ref.read(
                        novaPayServicesProvider.future,
                      );
                      final report = await services.sync.run();
                      ref.invalidate(outboxItemsProvider);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            report.stoppedForNetwork
                                ? 'Still offline - nothing sent.'
                                : 'Sent ${report.succeeded}, '
                                      'rejected ${report.rejected}.',
                          ),
                        ),
                      );
                    },
                    child: AppText(
                      'Sync now',
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Gap(16.h),

          queue.when(
            loading: () => const SizedBox.shrink(),
            error: (error, _) => AppText(
              'Could not read the queue: $error',
              fontSize: 12,
              lineHeight: 16,
              color: AppColors.error,
            ),
            data: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items.take(10))
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: AppText(
                      '${item.type} · ${item.status}'
                      '${item.lastError == null ? '' : ' · ${item.lastError}'}',
                      fontSize: 12,
                      lineHeight: 16,
                      color: item.status == AppDatabase.statusFailed
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
