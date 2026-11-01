import 'package:intl/intl.dart';

abstract final class AppDateFormatter {
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _fullDate = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDate = DateFormat('EEE d MMM, yyyy');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _dateTime = DateFormat('MMM d, yyyy • h:mm a');

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String fullDate(DateTime date) => _fullDate.format(date);

  static String time(DateTime date) => _time.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date);

  static String relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    return switch (difference) {
      0 => 'Today',
      -1 => 'Yesterday',
      _ => _shortDate.format(date),
    };
  }

  static String dayDateTime(DateTime date) =>
      '${_shortDate.format(date)} • ${time(date)}';
}
