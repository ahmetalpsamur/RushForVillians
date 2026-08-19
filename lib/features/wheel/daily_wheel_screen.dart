import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/day_reset_countdown.dart';
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

  static const _spinDuration = Duration(milliseconds: 900);

  /// Sonuç animasyondan **önce** belirlenir; animasyon yalnızca belirlenmiş
  /// sonucu gösterir, onu üretmez.
  ///
  // TODO(#16): Gerçek dilimli çark grafiği gelince dönüş açısı bu sonuca göre
  // hesaplanacak (şimdiki çark jenerik bir daire, gösterecek dilimi yok).
  Future<void> _spin() async {
    if (widget.alreadySpunToday || _spinning) return;

    final options = MockData.wheelXpOptions;
    final result = options[Random().nextInt(options.length)];

    setState(() => _spinning = true);
    await Future<void>.delayed(_spinDuration);
    if (!mounted) return;
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
                duration: _spinDuration,
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
                  child: Column(
                    children: [
                      Text(
                        _result != null
                            ? 'Kazandın: +$_result XP 🎉'
                            : 'Bugün çarkı zaten çevirdin.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Gün sınırı GameDay'den okunur; burada ayrı bir
                      // gün/saat hesabı yapılmaz.
                      const DayResetCountdown(
                        prefix: 'Yeni çark hakkına kalan süre: ',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
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
