import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:novawallet/core/theme/app_color.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.fontSize = 16,
    this.fontWeight,
    this.borderSide,
    this.prefixText,
    this.hintSize = 16,
    this.hintWeight,
  });

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final double? fontSize;
  final double? hintSize;
  final FontWeight? fontWeight;
  final BorderSide? borderSide;
  final String? prefixText;
  final FontWeight? hintWeight;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
      style: TextStyle(
        fontSize: fontSize?.sp,
        color: AppColors.navy900,
        fontFamily: 'PlusJakartaSans',
        fontWeight: fontWeight,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: hintSize?.sp,
          color: AppColors.navy900,
          fontWeight: hintWeight,
        ),
        filled: true,
        fillColor: AppColors.surface,
        counterText: '',
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        prefixText: prefixText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: borderSide ?? BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              borderSide ?? BorderSide(color: AppColors.navy900, width: 2),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
      ),
    );
  }
}
