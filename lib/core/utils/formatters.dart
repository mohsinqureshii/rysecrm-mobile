import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );
  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 1,
  );
  static final DateFormat _date = DateFormat('MMM d, yyyy');
  static final DateFormat _dateShort = DateFormat('MMM d');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _fileStamp = DateFormat('yyyy-MM-dd-HHmm');

  static String currency(num value) => _currency.format(value);

  static String compactCurrency(num value) => _compactCurrency.format(value);

  static String date(DateTime value) => _date.format(value);

  static String dateShort(DateTime value) => _dateShort.format(value);

  static String time(DateTime value) => _time.format(value);

  /// Filename-safe timestamp, e.g. "2026-08-08-1432".
  static String fileStamp(DateTime value) => _fileStamp.format(value);

  /// Relative label like "2h ago", "Yesterday", or a short date.
  static String relative(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && now.day == value.day) return '${diff.inHours}h ago';
    final yesterday = now.subtract(const Duration(days: 1));
    if (value.year == yesterday.year &&
        value.month == yesterday.month &&
        value.day == yesterday.day) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _dateShort.format(value);
  }

  /// Due-date label such as "Today", "Tomorrow", "Overdue · Aug 2".
  static String dueLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final delta = day.difference(today).inDays;
    if (delta < 0) return 'Overdue · ${_dateShort.format(due)}';
    if (delta == 0) return 'Today';
    if (delta == 1) return 'Tomorrow';
    if (delta < 7) return DateFormat('EEEE').format(due);
    return _dateShort.format(due);
  }

  static bool isOverdue(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(due.year, due.month, due.day).isBefore(today);
  }

  static bool isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
