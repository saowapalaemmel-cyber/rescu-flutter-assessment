import 'package:intl/intl.dart';

/// A store's pickup window. The API sends instants as ISO-8601 UTC strings.
class PickupWindowModel {
  static const Duration _marketUtcOffset = Duration(hours: 7);

  final DateTime start;
  final DateTime end;

  const PickupWindowModel({required this.start, required this.end});

  factory PickupWindowModel.fromJson(Map<String, dynamic> json) {
    return PickupWindowModel(
      start: DateTime.parse(json['start'] as String? ?? ''),
      end: DateTime.parse(json['end'] as String? ?? ''),
    );
  }

  /// Human readable label, e.g. "17:30 – 21:00".
  String get label {
    final marketStart = start.toUtc().add(_marketUtcOffset);
    final marketEnd = end.toUtc().add(_marketUtcOffset);
    return '${DateFormat('HH:mm').format(marketStart)} – '
        '${DateFormat('HH:mm').format(marketEnd)}';
  }

  /// Whether the pickup window overlaps today in the market's UTC+7 timezone.
  bool get isToday => isTodayAt(DateTime.now());

  /// Same as [isToday] but with an injectable clock, so it is testable.
  bool isTodayAt(DateTime now) {
    final marketStart = start.toUtc().add(_marketUtcOffset);
    final marketEnd = end.toUtc().add(_marketUtcOffset);
    final marketNow = now.toUtc().add(_marketUtcOffset);
    final todayStart = DateTime.utc(
      marketNow.year,
      marketNow.month,
      marketNow.day,
    );
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return marketStart.isBefore(tomorrowStart) &&
        marketEnd.isAfter(todayStart);
  }

  /// Whether the store is currently accepting pickups.
  bool get isOpenNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  Duration get untilStart => start.difference(DateTime.now());
}
