class AutoCloseShiftSchedule {
  const AutoCloseShiftSchedule._();

  static const warningWindow = Duration(hours: 1);

  static DateTime? nextClosingAt(String configuredTime, DateTime now) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(configuredTime);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }

    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  static bool shouldWarn({
    required bool enabled,
    required int unresolvedCount,
    required String configuredTime,
    required DateTime now,
  }) {
    if (!enabled || unresolvedCount <= 0) return false;
    final target = nextClosingAt(configuredTime, now);
    if (target == null) return false;
    final remaining = target.difference(now);
    return remaining >= Duration.zero && remaining <= warningWindow;
  }
}
