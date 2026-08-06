import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StepCounterApp());
}

class StepCounterApp extends StatelessWidget {
  const StepCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6750E8);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adımım',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          surface: const Color(0xFFF8F7FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        useMaterial3: true,
      ),
      home: const StepCounterPage(),
    );
  }
}

class StepCounterPage extends StatefulWidget {
  const StepCounterPage({super.key});

  @override
  State<StepCounterPage> createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage>
    with WidgetsBindingObserver {
  static const _defaultGoal = 10000;
  static const _goalKey = 'daily_goal';
  static const _baselineKey = 'step_baseline';
  static const _dateKey = 'step_baseline_date';

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  int _steps = 0;
  int _goal = _defaultGoal;
  int? _baseline;
  String _status = 'Hazırlanıyor';
  bool _sensorError = false;
  bool _permissionDenied = false;
  bool _isStartingSensor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSavedState();
    await _startSensor();
  }

  Future<void> _startSensor() async {
    if (_isStartingSensor) return;
    _isStartingSensor = true;

    try {
      if (Platform.isAndroid) {
        final permission = await Permission.activityRecognition.request();
        if (!permission.isGranted) {
          if (!mounted) return;
          setState(() {
            _permissionDenied = true;
            _sensorError = true;
            _status = 'Aktivite izni gerekli';
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() => _permissionDenied = false);
      _listenToSensor();
    } finally {
      _isStartingSensor = false;
    }
  }

  Future<void> _loadSavedState() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _dateId(DateTime.now());
    final savedDate = preferences.getString(_dateKey);

    if (!mounted) return;
    setState(() {
      _goal = preferences.getInt(_goalKey) ?? _defaultGoal;
      _baseline = savedDate == today ? preferences.getInt(_baselineKey) : null;
    });
  }

  void _listenToSensor() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepError,
    );
    _statusSubscription = Pedometer.pedestrianStatusStream.listen(
      _onStatusChanged,
      onError: (_) {
        if (mounted) setState(() => _status = 'Durum bilinmiyor');
      },
    );
  }

  Future<void> _onStepCount(StepCount event) async {
    final preferences = await SharedPreferences.getInstance();
    final today = _dateId(DateTime.now());
    final savedDate = preferences.getString(_dateKey);
    var baseline = _baseline;

    if (savedDate != today || baseline == null || event.steps < baseline) {
      baseline = event.steps;
      await preferences.setInt(_baselineKey, baseline);
      await preferences.setString(_dateKey, today);
    }

    if (!mounted) return;
    setState(() {
      _baseline = baseline;
      _steps = math.max(0, event.steps - baseline!);
      _sensorError = false;
      _permissionDenied = false;
    });
  }

  void _onStepError(Object error) {
    if (!mounted) return;
    setState(() {
      _sensorError = true;
      _status = 'Sensöre erişilemiyor';
    });
  }

  void _onStatusChanged(PedestrianStatus event) {
    if (!mounted) return;
    setState(() {
      _status = switch (event.status) {
        'walking' => 'Yürüyorsun',
        'stopped' => 'Hareketsiz',
        _ => 'Durum bilinmiyor',
      };
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _startSensor();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _showGoalPicker() async {
    var goalText = _goal.toString();
    final newGoal = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Günlük hedef'),
            content: TextFormField(
              initialValue: goalText,
              autofocus: true,
              keyboardType: TextInputType.number,
              onChanged: (value) => goalText = value,
              onFieldSubmitted: (text) {
                final value = int.tryParse(text);
                if (value != null && value >= 100 && value <= 100000) {
                  Navigator.pop(context, value);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Adım sayısı',
                suffixText: 'adım',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(goalText);
                  if (value != null && value >= 100 && value <= 100000) {
                    Navigator.pop(context, value);
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );

    if (newGoal == null || !mounted) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_goalKey, newGoal);
    if (mounted) setState(() => _goal = newGoal);
  }

  String _dateId(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = (_steps / _goal).clamp(0.0, 1.0);
    final calories = (_steps * 0.04).round();
    final distance = _steps * 0.00075;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.directions_walk_rounded,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ADIMIM',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Bugün hareket zamanı',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6F6B7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hedefi değiştir',
                        onPressed: _showGoalPicker,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 270,
                      height: 270,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 18,
                              strokeCap: StrokeCap.round,
                              backgroundColor: colors.primaryContainer,
                              color: colors.primary,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_walk_rounded,
                                size: 38,
                                color: colors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatNumber(_steps),
                                style: const TextStyle(
                                  fontSize: 54,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ADIM',
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF77717F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _sensorError
                                ? colors.errorContainer
                                : colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sensorError
                                ? Icons.info_outline_rounded
                                : Icons.circle,
                            size: _sensorError ? 18 : 8,
                            color: _sensorError ? colors.error : colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _status,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  _GoalCard(
                    steps: _steps,
                    goal: _goal,
                    onTap: _showGoalPicker,
                    formatNumber: _formatNumber,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.route_rounded,
                          value: distance.toStringAsFixed(2),
                          unit: 'km',
                          label: 'Mesafe',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.local_fire_department_rounded,
                          value: _formatNumber(calories),
                          unit: 'kcal',
                          label: 'Yaklaşık enerji',
                        ),
                      ),
                    ],
                  ),
                  if (_sensorError) ...[
                    const SizedBox(height: 18),
                    Card(
                      color: colors.errorContainer,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _permissionDenied
                                  ? 'Adımlarınızı sayabilmek için fiziksel aktivite iznini açmanız gerekiyor.'
                                  : 'Bu cihazda adım sensörüne erişilemiyor.',
                              style: TextStyle(color: colors.onErrorContainer),
                            ),
                            if (_permissionDenied) ...[
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: openAppSettings,
                                icon: const Icon(Icons.settings_rounded),
                                label: const Text('Ayarlara git'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.steps,
    required this.goal,
    required this.onTap,
    required this.formatNumber,
  });

  final int steps;
  final int goal;
  final VoidCallback onTap;
  final String Function(int) formatNumber;

  @override
  Widget build(BuildContext context) {
    final progress = (steps / goal).clamp(0.0, 1.0);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Günlük hedef',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${formatNumber(steps)} / ${formatNumber(goal)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '%${(progress * 100).round()} tamamlandı',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF77717F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF211F26)),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF77717F)),
          ),
        ],
      ),
    );
  }
}
