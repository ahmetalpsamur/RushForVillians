import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/day_reset_countdown.dart';
import '../../widgets/section_card.dart';

/// Günlük çark: adım hedefinin bir kısmı tamamlanınca açılır, günde bir
/// kez çevrilip rastgele XP kazandırır.
class DailyWheelScreen extends StatefulWidget {
  /// Bu oyun gününün **ücretsiz** hakkı kullanıldı mı.
  final bool alreadySpunToday;

  /// Mağazadan alınmış ekstra çark hakkı. Günlük hak bittiğinde bunlar
  /// kullanılır ([UserProfile.consumeWheelSpin]).
  final int extraSpins;

  final ValueChanged<int> onSpinResult;

  const DailyWheelScreen({
    super.key,
    required this.alreadySpunToday,
    required this.onSpinResult,
    this.extraSpins = 0,
  });

  @override
  State<DailyWheelScreen> createState() => _DailyWheelScreenState();
}

class _DailyWheelScreenState extends State<DailyWheelScreen> {
  bool _spinning = false;
  int? _result;

  /// Bu ekran açıldığından beri kaç ücretli hak harcandı.
  ///
  /// Ekran itilen bir rotada duruyor ve [RootShell] `setState`'i onu
  /// tazelemiyor; kalan hakkı burada sayıyoruz ki oyuncu ekrandan çıkmadan
  /// ikinci jetonunu da kullanabilsin.
  int _spentExtras = 0;

  /// Günlük hak bu ekranda kullanıldı mı.
  bool _spentDaily = false;

  static const _spinDuration = Duration(milliseconds: 900);

  int get _remainingExtras => widget.extraSpins - _spentExtras;

  bool get _dailyUsed => widget.alreadySpunToday || _spentDaily;

  bool get _canSpin => !_dailyUsed || _remainingExtras > 0;

  /// Sonuç animasyondan **önce** belirlenir; animasyon yalnızca belirlenmiş
  /// sonucu gösterir, onu üretmez.
  ///
  // TODO(#16): Gerçek dilimli çark grafiği gelince dönüş açısı bu sonuca göre
  // hesaplanacak (şimdiki çark jenerik bir daire, gösterecek dilimi yok).
  Future<void> _spin() async {
    if (!_canSpin || _spinning) return;

    final options = MockData.wheelXpOptions;
    final result = options[Random().nextInt(options.length)];
    // Hangi hakkın harcandığı burada belirlenir; RootShell aynı kuralı
    // [UserProfile.consumeWheelSpin] içinde uyguluyor.
    final usesExtra = _dailyUsed;

    setState(() => _spinning = true);
    await Future<void>.delayed(_spinDuration);
    if (!mounted) return;
    setState(() {
      _spinning = false;
      _result = result;
      if (usesExtra) {
        _spentExtras++;
      } else {
        _spentDaily = true;
      }
    });
    widget.onSpinResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final spun = !_canSpin;
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
              if (_result != null) ...[
                Text('Kazandın: +$_result XP 🎉', textAlign: TextAlign.center),
                const SizedBox(height: 12),
              ],
              if (spun)
                SectionCard(
                  child: Column(
                    children: [
                      if (_result == null)
                        const Text(
                          'Bugün çarkı zaten çevirdin.',
                          textAlign: TextAlign.center,
                        ),
                      if (_result == null) const SizedBox(height: 8),
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
              else ...[
                FilledButton.icon(
                  onPressed: _spinning ? null : _spin,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_spinning ? 'Çevriliyor...' : 'Çarkı Çevir'),
                ),
                // Ücretli hak harcanacaksa oyuncu bunu **önceden** bilmeli.
                if (_dailyUsed) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Bu çevirme ekstra hakkından düşecek '
                    '($_remainingExtras hak kaldı).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.streak,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
