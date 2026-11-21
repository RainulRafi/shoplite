import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/utils/date_format.dart';

void main() {
  test('dates read like 7 Nov 2026', () {
    expect(formatDate(DateTime(2026, 11, 7)), '7 Nov 2026');
    expect(formatDate(DateTime(2027, 1, 31)), '31 Jan 2027');
  });

  test('times use a twelve hour clock', () {
    expect(formatTime(DateTime(2026, 1, 1, 0, 5)), '12:05 AM');
    expect(formatTime(DateTime(2026, 1, 1, 9, 7)), '9:07 AM');
    expect(formatTime(DateTime(2026, 1, 1, 12, 0)), '12:00 PM');
    expect(formatTime(DateTime(2026, 1, 1, 15, 30)), '3:30 PM');
  });

  test('date and time are joined', () {
    expect(
      formatDateTime(DateTime(2026, 11, 17, 15, 30)),
      '17 Nov 2026, 3:30 PM',
    );
  });

  test('a range collapses shared parts', () {
    expect(
      formatDateRange(DateTime(2026, 11, 18), DateTime(2026, 11, 20)),
      '18 to 20 Nov',
    );
    expect(
      formatDateRange(DateTime(2026, 11, 18), DateTime(2026, 11, 18)),
      '18 Nov',
    );
    expect(
      formatDateRange(DateTime(2026, 11, 30), DateTime(2026, 12, 2)),
      '30 Nov to 2 Dec',
    );
    expect(
      formatDateRange(DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
      '30 Dec 2026 to 2 Jan 2027',
    );
  });
  test('relative times read like a notification', () {
    final now = DateTime(2026, 11, 17, 12, 0);

    expect(
      formatRelative(now.subtract(const Duration(seconds: 20)), now),
      'Just now',
    );
    expect(
      formatRelative(now.add(const Duration(minutes: 5)), now),
      'Just now',
    );
    expect(
      formatRelative(now.subtract(const Duration(minutes: 5)), now),
      '5 min ago',
    );
    expect(
      formatRelative(now.subtract(const Duration(hours: 3)), now),
      '3 h ago',
    );
    expect(formatRelative(DateTime(2026, 11, 14, 9, 0), now), '14 Nov 2026');
  });
}
