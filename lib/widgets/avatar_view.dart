import 'dart:math';

import 'package:flutter/material.dart';

import '../core/utils/gif_timing.dart';
import '../models/avatar_profile.dart';
import '../services/character_catalog.dart';
import 'pixel_sprite.dart';

class AvatarView extends StatelessWidget {
  final AvatarProfile avatar;
  final double size;
  final bool showBackground;
  final bool combatLoop;
  final Offset spriteOffset;

  const AvatarView({
    super.key,
    required this.avatar,
    this.size = 180,
    this.showBackground = true,
    this.combatLoop = false,
    this.spriteOffset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    final spriteScale = (size / 72).clamp(2.35, 3.0).toDouble();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: showBackground ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.14),
        gradient:
            showBackground
                ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF39325E), Color(0xFF171521)],
                )
                : null,
        border: showBackground ? Border.all(color: Colors.white12) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child:
          combatLoop
              ? _AvatarCombatLoop(
                avatar: avatar,
                scale: spriteScale,
                offset: spriteOffset,
              )
              : PixelSprite(
                asset: avatar.characterAsset,
                scale: spriteScale,
                offset: spriteOffset,
              ),
    );
  }
}

class _AvatarCombatLoop extends StatefulWidget {
  final AvatarProfile avatar;
  final double scale;
  final Offset offset;

  const _AvatarCombatLoop({
    required this.avatar,
    required this.scale,
    required this.offset,
  });

  @override
  State<_AvatarCombatLoop> createState() => _AvatarCombatLoopState();
}

class _AvatarCombatLoopState extends State<_AvatarCombatLoop> {
  final Random _random = Random();
  late String _asset = widget.avatar.characterAsset;
  int _phaseSerial = 0;
  int _runSerial = 0;

  @override
  void initState() {
    super.initState();
    _startLoop();
  }

  @override
  void didUpdateWidget(covariant _AvatarCombatLoop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatar.characterClass != widget.avatar.characterClass ||
        oldWidget.avatar.characterAsset != widget.avatar.characterAsset) {
      _startLoop();
    }
  }

  void _startLoop() {
    final run = ++_runSerial;
    _asset = widget.avatar.characterAsset;
    _phaseSerial++;
    _run(run);
  }

  Future<void> _run(int run) async {
    final classes = await CharacterCatalog.load();
    if (!mounted || run != _runSerial) return;
    final characterClass = classes.where(
      (item) => item.id == widget.avatar.characterClass,
    );
    final attacks =
        characterClass.isEmpty
            ? const <String>[]
            : characterClass.first.attackAssets;
    if (attacks.isEmpty) return;

    while (mounted && run == _runSerial) {
      final attack = attacks[_random.nextInt(attacks.length)];
      final durations = await Future.wait([
        GifTiming.cycle(
          widget.avatar.characterAsset,
          fallback: const Duration(milliseconds: 700),
        ),
        GifTiming.cycle(attack),
      ]);
      if (!mounted || run != _runSerial) return;

      setState(() {
        _asset = widget.avatar.characterAsset;
        _phaseSerial++;
      });
      await Future<void>.delayed(durations.first * 2);
      if (!mounted || run != _runSerial) return;

      setState(() {
        _asset = attack;
        _phaseSerial++;
      });
      await Future<void>.delayed(durations.last);
    }
  }

  @override
  void dispose() {
    _runSerial++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PixelSprite(
    asset: _asset,
    scale: widget.scale,
    offset: widget.offset,
    imageKey: ValueKey('avatar-combat-$_phaseSerial-$_asset'),
  );
}
