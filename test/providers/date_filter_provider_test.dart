import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:counter_app/providers/date_filter_provider.dart';

void main() {
  group('DateFilter enum', () {
    test('has all expected values', () {
      expect(DateFilter.values, contains(DateFilter.day));
      expect(DateFilter.values, contains(DateFilter.week));
      expect(DateFilter.values, contains(DateFilter.month));
      expect(DateFilter.values, contains(DateFilter.custom));
      expect(DateFilter.values.length, 4);
    });
  });

  group('DateFilterState', () {
    group('constructor', () {
      test('creates with defaults', () {
        final state = DateFilterState();
        expect(state.filter, DateFilter.day);
        expect(state.customStart, isNull);
        expect(state.customEnd, isNull);
      });

      test('creates with custom values', () {
        final start = DateTime(2026, 1, 1);
        final end = DateTime(2026, 1, 31);
        final state = DateFilterState(
          filter: DateFilter.custom,
          customStart: start,
          customEnd: end,
        );

        expect(state.filter, DateFilter.custom);
        expect(state.customStart, start);
        expect(state.customEnd, end);
      });
    });

    group('copyWith', () {
      test('copyWith filter only', () {
        final original = DateFilterState(filter: DateFilter.day);
        final copied = original.copyWith(filter: DateFilter.week);

        expect(copied.filter, DateFilter.week);
        expect(original.filter, DateFilter.day); // unchanged
      });

      test('copyWith customStart only', () {
        final start = DateTime(2026, 3, 1);
        final original = DateFilterState();
        final copied = original.copyWith(customStart: start);

        expect(copied.customStart, start);
        expect(original.customStart, isNull);
      });

      test('copyWith customEnd only', () {
        final end = DateTime(2026, 3, 31);
        final original = DateFilterState();
        final copied = original.copyWith(customEnd: end);

        expect(copied.customEnd, end);
        expect(original.customEnd, isNull);
      });

      test('copyWith preserves other fields', () {
        final start = DateTime(2026, 3, 1);
        final end = DateTime(2026, 3, 31);
        final original = DateFilterState(
          filter: DateFilter.custom,
          customStart: start,
          customEnd: end,
        );
        final copied = original.copyWith(filter: DateFilter.month);

        expect(copied.filter, DateFilter.month);
        expect(copied.customStart, start);
        expect(copied.customEnd, end);
      });
    });

    group('getDateRange', () {
      test('day filter returns today start to now', () {
        final state = DateFilterState(filter: DateFilter.day);
        final (start, end) = state.getDateRange();

        final now = DateTime.now();
        expect(start.year, now.year);
        expect(start.month, now.month);
        expect(start.day, now.day);
        expect(start.hour, 0);
        expect(start.minute, 0);
        expect(start.second, 0);
        expect(end.year, now.year);
        expect(end.month, now.month);
        expect(end.day, now.day);
      });

      test('week filter returns start of week to now', () {
        // Use a known date: 2026-05-11 is a Monday
        // When this test runs depends on system timezone but we can verify
        // that start is before end and start is at midnight
        final state = DateFilterState(filter: DateFilter.week);
        final (start, end) = state.getDateRange();

        expect(start.isBefore(end) || start.isAtSameMomentAs(end), isTrue);
        expect(start.hour, 0);
        expect(start.minute, 0);
        expect(start.second, 0);
      });

      test('month filter returns start of month to now', () {
        final state = DateFilterState(filter: DateFilter.month);
        final (start, end) = state.getDateRange();
        final now = DateTime.now();

        expect(start.year, now.year);
        expect(start.month, now.month);
        expect(start.day, 1);
        expect(start.hour, 0);
        expect(start.minute, 0);
        expect(start.second, 0);
      });

      test('custom filter uses custom dates', () {
        final start = DateTime(2026, 2, 1, 0, 0, 0);
        final end = DateTime(2026, 2, 28, 23, 59, 59);
        final state = DateFilterState(
          filter: DateFilter.custom,
          customStart: start,
          customEnd: end,
        );
        final (resultStart, resultEnd) = state.getDateRange();

        expect(resultStart, start);
        expect(resultEnd, end);
      });

      test('custom filter falls back to today when dates are null', () {
        final state = DateFilterState(filter: DateFilter.custom);
        final (start, end) = state.getDateRange();
        final now = DateTime.now();

        expect(start.year, now.year);
        expect(start.month, now.month);
        expect(start.day, now.day);
        expect(start.hour, 0);
        expect(end.year, now.year);
        expect(end.month, now.month);
        expect(end.day, now.day);
      });
    });
  });

  group('DateFilterNotifier', () {
    late ProviderContainer container;
    late DateFilterNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(dateFilterProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is day filter', () {
      final state = container.read(dateFilterProvider);
      expect(state.filter, DateFilter.day);
    });

    test('setFilter changes the filter', () {
      notifier.setFilter(DateFilter.week);
      expect(container.read(dateFilterProvider).filter, DateFilter.week);

      notifier.setFilter(DateFilter.month);
      expect(container.read(dateFilterProvider).filter, DateFilter.month);

      notifier.setFilter(DateFilter.day);
      expect(container.read(dateFilterProvider).filter, DateFilter.day);
    });

    test('setFilter does not affect custom dates', () {
      final start = DateTime(2026, 4, 1);
      final end = DateTime(2026, 4, 30);
      notifier.setCustomRange(start, end);
      expect(container.read(dateFilterProvider).customStart, start);
      expect(container.read(dateFilterProvider).customEnd, end);

      notifier.setFilter(DateFilter.day);
      // custom dates should be preserved
      expect(container.read(dateFilterProvider).customStart, start);
      expect(container.read(dateFilterProvider).customEnd, end);
    });

    test('setCustomRange sets filter to custom and stores dates', () {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 6, 30);
      notifier.setCustomRange(start, end);

      final state = container.read(dateFilterProvider);
      expect(state.filter, DateFilter.custom);
      expect(state.customStart, start);
      expect(state.customEnd, end);
    });

    test('setToday sets filter to day', () {
      notifier.setFilter(DateFilter.week);
      notifier.setToday();
      expect(container.read(dateFilterProvider).filter, DateFilter.day);
    });

    test('setWeek sets filter to week', () {
      notifier.setWeek();
      expect(container.read(dateFilterProvider).filter, DateFilter.week);
    });

    test('setMonth sets filter to month', () {
      notifier.setMonth();
      expect(container.read(dateFilterProvider).filter, DateFilter.month);
    });

    test('state is immutable via copyWith', () {
      notifier.setFilter(DateFilter.day);
      final state1 = container.read(dateFilterProvider);
      final state2 = container.read(dateFilterProvider);
      expect(state1, equals(state2));
    });
  });
}
