import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/game_day.dart';
import '../../models/daily_progress.dart';
import '../../models/daily_step_record.dart';
import '../../widgets/daily_step_ring.dart';

class StepHistoryScreen extends StatefulWidget {
  final DailyProgress today;
  final List<DailyStepRecord> history;

  const StepHistoryScreen({
    super.key,
    required this.today,
    required this.history,
  });

  @override
  State<StepHistoryScreen> createState() => _StepHistoryScreenState();
}

class _StepHistoryScreenState extends State<StepHistoryScreen> {
  late DateTime _selectedMonth;

  /// Takvimin "bugün"ü oyun günüdür, takvim günü değil: gün sınırı gece
  /// yarısı olmadığı için (bkz. [GameDay.dayStartHour]) sınırdan önceki
  /// saatler hâlâ önceki güne yazılır.
  DateTime get _todayGameDay => GameDay.startOf(widget.today.date);

  @override
  void initState() {
    super.initState();
    final today = GameDay.startOf(widget.today.date);
    _selectedMonth = DateTime(today.year, today.month);
  }

  Map<String, DailyStepRecord> get _records {
    final records = <String, DailyStepRecord>{
      for (final record in widget.history) record.dateKey: record,
    };
    final todayRecord = DailyStepRecord(
      date: _todayGameDay,
      steps: widget.today.steps,
      stepGoal: widget.today.stepGoal,
    );
    records[todayRecord.dateKey] = todayRecord;
    return records;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final leadingBlanks =
        DateTime(_selectedMonth.year, _selectedMonth.month).weekday - 1;
    final cellCount = leadingBlanks + daysInMonth;
    final today = _todayGameDay;
    final nowMonth = DateTime(today.year, today.month);
    final canGoNext = _selectedMonth.isBefore(nowMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Adım Halkaları')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    formatLongDate(
                      DateTime(_selectedMonth.year, _selectedMonth.month, 1),
                    ).replaceFirst('1 ', ''),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      canGoNext
                          ? () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                          }
                          : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children:
                  const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                      .map(
                        (day) => Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.68,
                crossAxisSpacing: 2,
                mainAxisSpacing: 8,
              ),
              itemCount: cellCount,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final day = index - leadingBlanks + 1;
                final date = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month,
                  day,
                );
                if (date.isAfter(today)) {
                  return Center(
                    child: Text(
                      '$day',
                      style: const TextStyle(color: Colors.white12),
                    ),
                  );
                }
                final emptyRecord = DailyStepRecord(
                  date: date,
                  steps: 0,
                  stepGoal: widget.today.stepGoal,
                );
                final record = _records[emptyRecord.dateKey] ?? emptyRecord;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DailyStepRing(
                      record: record,
                      size: 43,
                      centerLabel: '$day',
                      onTap: () => showDailyStepDetails(context, record),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      child: Text(
                        '${record.steps}',
                        style: TextStyle(
                          color:
                              record.steps > 0
                                  ? AppColors.primary
                                  : Colors.white24,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
