import 'package:flutter/material.dart';

class TransactionModel {
  const TransactionModel({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    required this.leadingIconColor,
    required this.circleAvatarColor,
  });

  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final Color leadingIconColor;
  final Color circleAvatarColor;
}
