import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/section_card.dart';

/// Günlük çark: adım hedefinin bir kısmı tamamlanınca açılır, günde bir
/// kez çevrilip rastgele XP kazandırır.
class DailyWheelScreen extends StatefulWidget {
  final bool alreadySpunToday;
  final ValueChanged<int> onSpinResult;

  const DailyWheelScreen({
    super.key,
    required this.alreadySpunToday,
    required this.onSpinResult,
  });

  @override
  State<DailyWheelScreen> createState() => _DailyWheelScreenState();
}

class _DailyWheelScreenState extends State<DailyWheelScreen> {
  bool _spinning = false;
  int? _result;

  Future<void> _spin() async {
    if (widget.alreadySpunToday || _spinning) return;
    setState(() => _spinning = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final options = MockData.wheelXpOptions;
    final result = options[Random().nextInt(options.length)];
    setState(() {
      _spinning = false;
      _result = result;
    });
    widget.onSpinResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final spun = widget.alreadySpunToday || _result != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Günlük Çark')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: _spinning ? 4 : 0,
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.primary, width: 4),
                  ),
                  child: const Icon(
                    Icons.casino,
                    size: 72,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (spun)
                SectionCard(
                  child: Text(
                    _result != null
                        ? 'Kazandın: +$_result XP 🎉'
                        : 'Bugün çarkı zaten çevirdin, yarın tekrar gel!',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _spinning ? null : _spin,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_spinning ? 'Çevriliyor...' : 'Çarkı Çevir'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
