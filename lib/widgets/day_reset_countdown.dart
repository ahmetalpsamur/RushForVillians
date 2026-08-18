import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/game_clock.dart';
import '../core/utils/game_day.dart';

/// Oyun gününün sıfırlanmasına kalan süreyi canlı gösterir.
///
/// Süreyi kendi içinde dakikada bir tazeler; böylece çevresindeki ekranın
/// saniyede bir yeniden çizilmesi gerekmez. Gün hesabını [GameDay] yapar,
/// bu widget'ın kendi gün mantığı yoktur.
class DayResetCountdown extends StatefulWidget {
  final String prefix;
  final TextStyle? style;
  final TextAlign? textAlign;

  const DayResetCountdown({
    super.key,
    this.prefix = '',
    this.style,
    this.textAlign,
  });

  @override
  State<DayResetCountdown> createState() => _DayResetCountdownState();
}

class _DayResetCountdownState extends State<DayResetCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = GameDay.timeUntilReset(GameClock.now());
    return Text(
      '${widget.prefix}${GameDay.formatRemaining(remaining)}',
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
