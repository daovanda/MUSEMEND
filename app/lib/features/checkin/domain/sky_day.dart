/// The product day follows the same fixed time zone as the database.
DateTime vietnamWallTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 7));

bool canCheckInAt(DateTime instant) => vietnamWallTime(instant).hour >= 12;

int skyDayNumber(DateTime instant) {
  final day = vietnamWallTime(instant);
  return DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(2020)).inDays;
}

/// The next local noon or midnight, represented as a real UTC instant.
DateTime nextSkyBoundary(DateTime instant) {
  final day = vietnamWallTime(instant);
  final boundary =
      day.hour < 12
          ? DateTime.utc(day.year, day.month, day.day, 12)
          : DateTime.utc(day.year, day.month, day.day + 1);
  return boundary.subtract(const Duration(hours: 7));
}
