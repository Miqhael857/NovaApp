const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `15 Jan 2027`.
///
/// Written out rather than pulled from `intl`: the app ships one locale, and a
/// date this short is not worth a dependency or a plugin channel in tests.
String formatGoalDate(DateTime at) =>
    '${at.day} ${_months[at.month - 1]} ${at.year}';
