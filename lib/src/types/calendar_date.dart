/// A date on the calendar, with no time of day and no time zone.
///
/// Every date the standard carries is of this kind: BT-2 is the day written on
/// the invoice, not an instant. Holding one in a `DateTime` moves it by a day
/// as soon as it crosses a zone, so the model keeps the three fields it was
/// given and never converts them.
///
/// {@category values}
final class CalendarDate implements Comparable<CalendarDate> {
  /// The date of the given [year], [month] and [day].
  ///
  /// Throws [ArgumentError] when the three do not name a day that exists.
  CalendarDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Not a month');
    }
    if (day < 1 || day > _daysInMonth(year, month)) {
      throw ArgumentError.value(day, 'day', 'Not a day of $year-$month');
    }
  }

  /// The calendar day [moment] falls on, read in its own time zone.
  factory CalendarDate.from(DateTime moment) =>
      CalendarDate(moment.year, moment.month, moment.day);

  /// The date written as `YYYY-MM-DD`.
  ///
  /// Throws [FormatException] on anything else, including a date that carries
  /// a time or a zone.
  factory CalendarDate.parse(String value) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Not a YYYY-MM-DD date', value);
    }
    return parsed;
  }

  /// The date written as `YYYY-MM-DD`, or null when [value] is anything else.
  static CalendarDate? tryParse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > _daysInMonth(year, month)) return null;
    return CalendarDate(year, month, day);
  }

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static const List<int> _lengths = [
    31,
    28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];

  static int _daysInMonth(int year, int month) {
    if (month == 2 && _isLeapYear(year)) return 29;
    return _lengths[month - 1];
  }

  static bool _isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  /// The year.
  final int year;

  /// The month, from 1 for January to 12 for December.
  final int month;

  /// The day of the month, from 1.
  final int day;

  /// The date written as `YYYY-MM-DD`, which is what both syntaxes carry.
  @override
  String toString() => '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  /// Whether this date comes before [other] on the calendar.
  bool operator <(CalendarDate other) => compareTo(other) < 0;

  /// Whether this date comes after [other] on the calendar.
  bool operator >(CalendarDate other) => compareTo(other) > 0;

  /// Whether this date is [other] or comes before it.
  bool operator <=(CalendarDate other) => compareTo(other) <= 0;

  /// Whether this date is [other] or comes after it.
  bool operator >=(CalendarDate other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
