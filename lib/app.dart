import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:novawallet/app_router.dart';
import 'package:novawallet/core/theme/app_color.dart';

class NovaWalletApp extends ConsumerWidget {
  const NovaWalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      // Matches the design artboards: a 360x800 low-end Android phone.
      designSize: const Size(360, 800),
      minTextAdapt: false,
      splitScreenMode: false,

      fontSizeResolver: (fontSize, instance) => fontSize.toDouble(),
      builder: (context, child) => MaterialApp.router(
        title: 'NovaPay',
        debugShowCheckedModeBanner: false,
        theme: AppColor.light(),
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
