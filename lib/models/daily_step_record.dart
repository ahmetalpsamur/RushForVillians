/// Tamamlanmış bir takvim gününün adım halkası.
class DailyStepRecord {
  final DateTime date;
  final int steps;
  final int stepGoal;

  const DailyStepRecord({
    required this.date,
    required this.steps,
    required this.stepGoal,
  });

  DateTime get calendarDay => DateTime(date.year, date.month, date.day);

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  double get progress => stepGoal <= 0 ? 0 : (steps / stepGoal).clamp(0, 1);

  Map<String, Object?> toJson() => {
    'date': calendarDay.toIso8601String(),
    'steps': steps,
    'stepGoal': stepGoal,
  };

  factory DailyStepRecord.fromJson(Map<String, dynamic> json) {
    final parsed = DateTime.tryParse(json['date'] as String? ?? '');
    final date = parsed ?? DateTime.now();
    return DailyStepRecord(
      date: DateTime(date.year, date.month, date.day),
      steps: json['steps'] as int? ?? 0,
      stepGoal: json['stepGoal'] as int? ?? 0,
    );
  }
}
