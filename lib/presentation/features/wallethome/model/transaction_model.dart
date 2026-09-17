import 'package:flutter/material.dart';

import 'package:novawallet/core/money/kobo.dart';

/// Where a transaction has got to.
///
/// This is the user-facing vocabulary, not the outbox's. The outbox knows about
/// `pending`, `in_flight`, `succeeded` and `failed`; someone reading their
/// history only needs to know whether the money moved, is still on its way, or
/// never left.
enum TransactionStatus { completed, pending, failed }

class TransactionModel {
  const TransactionModel({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.leadingIcon,
    required this.leadingIconColor,
    required this.circleAvatarColor,
    this.isCredit = false,
    this.status = TransactionStatus.completed,
  });

  final String title;
  final String subtitle;

  /// Always positive. Direction is carried by [isCredit], not by the sign of
  /// the amount, so no display decision can accidentally flip the arithmetic.
  final Kobo amount;

  final bool isCredit;
  final TransactionStatus status;

  final IconData leadingIcon;
  final Color leadingIconColor;
  final Color circleAvatarColor;

  /// `−₦15,000.00`, or `+₦50,000.00` for money coming in.
  ///
  /// A failed transfer shows no sign at all: nothing moved, and a minus sign
  /// would claim the balance was debited when it was not.
  String get formattedAmount => status == TransactionStatus.failed
      ? amount.format()
      : '${isCredit ? '+' : '−'}${amount.format()}';

  /// One sentence for a screen reader, rather than four separate fragments.
  String get semanticsLabel {
    final direction = isCredit ? 'Received' : 'Sent';
    final ending = switch (status) {
      TransactionStatus.completed => '',
      TransactionStatus.pending => ', pending, will send when back online',
      TransactionStatus.failed => ', not sent',
    };
    return '$direction ${amount.format()}, $title, $subtitle$ending';
  }
}
