import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DateFilter { day, week, month, custom }

class DateFilterState {
  final DateFilter filter;
  final DateTime? customStart;
  final DateTime? customEnd;

  const DateFilterState({
    this.filter = DateFilter.day,
    this.customStart,
    this.customEnd,
  });

  DateFilterState copyWith({
    DateFilter? filter,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return DateFilterState(
      filter: filter ?? this.filter,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }

  (DateTime start, DateTime end) getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case DateFilter.day:
        return (today, now);
      case DateFilter.week:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (weekStart, now);
      case DateFilter.month:
        final monthStart = DateTime(now.year, now.month, 1);
        return (monthStart, now);
      case DateFilter.custom:
        return (customStart ?? today, customEnd ?? now);
    }
  }
}

final dateFilterProvider =
    StateNotifierProvider<DateFilterNotifier, DateFilterState>(
  (ref) => DateFilterNotifier(),
);

class DateFilterNotifier extends StateNotifier<DateFilterState> {
  DateFilterNotifier() : super(const DateFilterState());

  void setFilter(DateFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      filter: DateFilter.custom,
      customStart: start,
      customEnd: end,
    );
  }

  void setToday() => setFilter(DateFilter.day);
  void setWeek() => setFilter(DateFilter.week);
  void setMonth() => setFilter(DateFilter.month);
}
