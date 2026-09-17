import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:novawallet/core/theme/app_color.dart';

import 'app_text.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  /// Text shown on the left of the app bar. Needs [hasLeading].
  final String? leadingText;

  /// Replaces the whole leading area. Wins over both flags below.
  final Widget? leadingWidget;

  /// Shows [leadingText] in the leading area.
  final bool hasLeading;

  /// Shows the back arrow. Leave false on tab roots (Home, NovaSave, Profile),
  /// where there is nothing to go back to.
  final bool automaticallyImplyLeading;

  final Color? appbarBackgroundColor;
  final double? elevation;
  final List<Widget>? actions;
  final double size;
  final double lineHeight;

  /// How far the leading area sits from the left edge.
  final double leadingPadding;

  /// App bar height. Flutter's default is 56; smaller pulls the body up closer
  /// to the leading text.
  final double toolbarHeight;

  /// Set false on a screen that draws its own header inside the body (Home),
  /// so an empty AppBar does not still reserve its height at the top.
  final bool hasAppBar;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.bottom,
    this.leadingText,
    this.leadingWidget,
    this.hasLeading = false,
    this.appbarBackgroundColor,
    this.elevation,
    this.size = 17,
    this.automaticallyImplyLeading = false,
    this.lineHeight = 18,
    this.leadingPadding = 14,
    this.toolbarHeight = 48,
    this.hasAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    // An AppBar ignores automaticallyImplyLeading whenever `leading` is
    // non-null, so the leading is built only when there is something to put in
    // it: your own widget, the back arrow, or the leading text.
    final showsArrow = automaticallyImplyLeading;
    final showsText = hasLeading && leadingText != null;

    Widget? leading;

    if (leadingWidget != null) {
      leading = leadingWidget;
    } else if (showsArrow || showsText) {
      leading = Padding(
        padding: EdgeInsets.only(left: leadingPadding.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showsArrow)
              SizedBox(
                width: 30.w,
                height: 48.h,
                child: Center(
                  child: IconButton(
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_back_ios_sharp,
                      size: 18.sp,
                      color: AppColors.navy900,
                    ),
                  ),
                ),
              ),

            if (showsArrow && showsText) Gap(5.w),

            if (showsText)
              InkWell(
                onTap: showsArrow ? () => context.pop() : null,
                child: AppText(
                  leadingText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  lineHeight: lineHeight,
                  color: AppColors.navy900,
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: hasAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              scrolledUnderElevation: 0,
              backgroundColor: appbarBackgroundColor ?? AppColors.background,
              foregroundColor: AppColors.navy900,
              iconTheme: const IconThemeData(color: AppColors.navy900),
              actionsIconTheme: const IconThemeData(color: AppColors.navy900),
              elevation: elevation,
              toolbarHeight: toolbarHeight,

              leading: leading,

              leadingWidth: 110.w,

              title: AppText(title, fontSize: size),
              centerTitle: true,
              titleSpacing: 0,
              actions: actions,
              bottom: bottom,
            )
          : null,
      body: hasAppBar ? body : SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
