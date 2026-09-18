import '../core/utils/game_day.dart';

/// Durable delivery/acknowledgement markers, independent of reward grants.
class DailyEngagement {
  DateTime? streakNotifiedOn;
  DateTime? streakCelebratedOn;
  DateTime? wheelNotifiedOn;
  DateTime? wheelPromptedOn;

  DailyEngagement({
    this.streakNotifiedOn,
    this.streakCelebratedOn,
    this.wheelNotifiedOn,
    this.wheelPromptedOn,
  });

  static bool matches(DateTime? day, DateTime now) =>
      day != null && GameDay.isSameGameDay(day, now);

  Map<String, Object?> toJson() => {
    'streakNotifiedOn': streakNotifiedOn?.toIso8601String(),
    'streakCelebratedOn': streakCelebratedOn?.toIso8601String(),
    'wheelNotifiedOn': wheelNotifiedOn?.toIso8601String(),
    'wheelPromptedOn': wheelPromptedOn?.toIso8601String(),
  };

  factory DailyEngagement.fromJson(Object? value) {
    final json = value is Map<String, dynamic> ? value : <String, dynamic>{};
    DateTime? date(String key) =>
        json[key] is String ? DateTime.tryParse(json[key] as String) : null;
    return DailyEngagement(
      streakNotifiedOn: date('streakNotifiedOn'),
      streakCelebratedOn: date('streakCelebratedOn'),
      wheelNotifiedOn: date('wheelNotifiedOn'),
      wheelPromptedOn: date('wheelPromptedOn'),
    );
  }
}
