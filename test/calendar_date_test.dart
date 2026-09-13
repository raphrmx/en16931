import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

void main() {
  group('CalendarDate', () {
    test('writes itself as the standard writes a date', () {
      expect(CalendarDate(2026, 1, 5).toString(), '2026-01-05');
      expect(CalendarDate(999, 12, 31).toString(), '0999-12-31');
    });

    test('reads back what it writes', () {
      final date = CalendarDate(2026, 9, 13);
      expect(CalendarDate.parse(date.toString()), date);
    });

    test('refuses a day the calendar does not have', () {
      expect(() => CalendarDate(2026, 2, 29), throwsArgumentError);
      expect(() => CalendarDate(2026, 13, 1), throwsArgumentError);
      expect(() => CalendarDate(2026, 4, 31), throwsArgumentError);
    });

    test('keeps the leap day of a leap year', () {
      expect(CalendarDate(2024, 2, 29).toString(), '2024-02-29');
      expect(CalendarDate(2000, 2, 29).toString(), '2000-02-29');
      expect(() => CalendarDate(1900, 2, 29), throwsArgumentError);
    });

    test('refuses anything that is not a bare date', () {
      expect(CalendarDate.tryParse('2026-09-13T00:00:00Z'), isNull);
      expect(CalendarDate.tryParse('13/09/2026'), isNull);
      expect(CalendarDate.tryParse('2026-9-13'), isNull);
      expect(CalendarDate.tryParse('2026-02-30'), isNull);
      expect(() => CalendarDate.parse('soon'), throwsFormatException);
    });

    test('takes the day of a moment without moving it', () {
      final localMidnight = DateTime(2026, 9, 13);
      expect(CalendarDate.from(localMidnight), CalendarDate(2026, 9, 13));
    });

    test('orders on the calendar', () {
      final first = CalendarDate(2026, 1, 31);
      final second = CalendarDate(2026, 2, 1);
      expect(first < second, isTrue);
      expect(second > first, isTrue);
      expect(first <= CalendarDate(2026, 1, 31), isTrue);
      expect([second, first]..sort(), [first, second]);
    });
  });

  group('Identifier', () {
    test('is the same identifier only under the same scheme', () {
      const plain = Identifier('0123456789');
      const scheme = Identifier('0123456789', scheme: '0208');
      expect(plain, isNot(scheme));
      expect(scheme, const Identifier('0123456789', scheme: '0208'));
    });
  });

  group('VatCategory', () {
    test('is read from the code the list publishes', () {
      expect(VatCategory.tryParse('AE'), VatCategory.reverseCharge);
      expect(VatCategory.tryParse('S'), VatCategory.standardRate);
      expect(VatCategory.tryParse('X'), isNull);
    });
  });

  group('CodeValue', () {
    test('keeps two lists apart even on the same string', () {
      expect(const UnitCode('30'), isNot(PaymentMeansCode.creditTransfer));
      expect(PaymentMeansCode.creditTransfer.value, '30');
    });
  });
}
