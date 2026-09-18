import 'package:flutter/material.dart';
import '../../l10n/l10n_context.dart';
import '../../models/avatar_profile.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/pixel_sprite.dart';

/// Acknowledgement is explicit: neither the scrim nor Back dismisses a reward.
Future<bool?> showDailyProgressDialog(
  BuildContext context, {
  required bool wheel,
  required int streakDays,
  required AvatarProfile avatar,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  barrierColor: Colors.black.withValues(alpha: .88),
  builder:
      (_) => PopScope(
        canPop: false,
        child: DailyProgressDialog(
          wheel: wheel,
          streakDays: streakDays,
          avatar: avatar,
        ),
      ),
);

class DailyProgressDialog extends StatefulWidget {
  final bool wheel;
  final int streakDays;
  final AvatarProfile avatar;
  const DailyProgressDialog({
    super.key,
    required this.wheel,
    required this.streakDays,
    required this.avatar,
  });
  @override
  State<DailyProgressDialog> createState() => _DailyProgressDialogState();
}

class _DailyProgressDialogState extends State<DailyProgressDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (!widget.wheel) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final color =
        widget.wheel ? const Color(0xFFAD93FF) : const Color(0xFFFFC65B);
    return Dialog(
      key: ValueKey(
        widget.wheel ? 'wheel-ready-dialog' : 'streak-complete-dialog',
      ),
      backgroundColor: const Color(0xFF1D172C),
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: color.withValues(alpha: .45)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.wheel)
                const SizedBox(
                  width: 160,
                  height: 160,
                  child: PixelSprite(
                    asset: 'lib/ChanceWheel/normal_gear_1.gif',
                    scale: 3.2,
                  ),
                )
              else ...[
                ScaleTransition(
                  scale:
                      reducedMotion
                          ? const AlwaysStoppedAnimation(1.0)
                          : Tween<double>(
                            begin: .94,
                            end: 1.08,
                          ).animate(_pulse),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 86,
                    color: color,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: .5),
                        blurRadius: 36,
                      ),
                    ],
                  ),
                ),
                AvatarView(
                  avatar: widget.avatar,
                  size: 100,
                  showBackground: false,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                widget.wheel
                    ? l10n.wheelReadyTitle
                    : l10n.streakCelebrationTitle(widget.streakDays),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.wheel ? l10n.wheelReadyBody : l10n.streakCelebrationBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('daily-progress-primary'),
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    widget.wheel ? l10n.goToWheel : l10n.dailyContinue,
                  ),
                ),
              ),
              if (widget.wheel) ...[
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('daily-progress-later'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.wheelLater),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
