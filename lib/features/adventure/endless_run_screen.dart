import 'package:flutter/material.dart';

import '../../core/constants/safety_messages.dart';
import '../../core/utils/endless_rules.dart';
import '../../core/localization/app_formatters.dart';
import '../../core/theme/app_theme.dart';

import '../../l10n/content_localizations.dart';
import '../../l10n/l10n_context.dart';
import '../../models/avatar_profile.dart';
import '../../models/endless_run.dart';
import '../../widgets/dropped_item_card.dart';
import '../../widgets/combat_hud.dart';
import '../../widgets/pixel_sprite.dart';
import '../../widgets/section_card.dart';

/// Sonsuz Koşu ekranı (Bölüm C / Faz 3).
///
/// ## Kullanıcı girdisi yok — bu ekranın en sert kuralı
///
/// Ekranda **tek** dokunulabilir şey "Macerayı bitir" düğmesi. Kesimler,
/// çarpan artışı ve canavar değişimi tamamen otomatik; hiçbir karar, seçim,
/// zamanlama ya da mini oyun yok. Gerçek hayatta yürürken telefona bakmak
/// tehlikeli, mod bunu teşvik etmiyor.
///
/// Bu yüzden ekran **veri de tutmuyor**: her çizimde `RootShell`'den okuyor
/// (GD27 deseni). Telefon cepteyken arka planda ilerleyen durum, ekran
/// açıldığında olduğu gibi görünüyor.
class EndlessRunScreen extends StatelessWidget {
  final EndlessRun run;
  final AvatarProfile avatar;

  /// "Macerayı bitir" — tam banka ödenir.
  final VoidCallback onFinish;

  /// Sonuç ekranını kapatır.
  final VoidCallback onClose;
  
  final VoidCallback? onSimulateSteps;

  const EndlessRunScreen({
    super.key,
    required this.run,
    required this.avatar,
    required this.onFinish,
    required this.onClose,
    this.onSimulateSteps,
  });

  @override
  Widget build(BuildContext context) {
    // Aktif koşu **tam ekran**: normal macera savaş ekranıyla aynı desen
    // (Bölüm D / Faz 2). AppBar gizleniyor, zemin siyah; alt gezinme
    // çubuğu `RootShell`'deki `fullscreenAdventure` bayrağıyla kalkıyor.
    // Sonuç perdesi ise normal bir sayfa: oradan çıkış var.
    final fullscreen = !run.isFinished;
    return Scaffold(
      backgroundColor: fullscreen ? Colors.black : null,
      appBar: fullscreen
          ? null
          : AppBar(title: Text(context.l10n.endlessTitle)),
      body: SafeArea(
        child: run.isFinished
            ? _EndlessResult(run: run, onClose: onClose)
            : _EndlessActive(
                run: run,
                avatar: avatar,
                onFinish: onFinish,
                onSimulateSteps: onSimulateSteps,
              ),
      ),
    );
  }
}

class _EndlessActive extends StatelessWidget {
  final EndlessRun run;
  final AvatarProfile avatar;
  final VoidCallback onFinish;
  final VoidCallback? onSimulateSteps;

  const _EndlessActive({
    required this.run,
    required this.avatar,
    required this.onFinish,
    this.onSimulateSteps,
  });

  Future<void> _confirmFinish(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(context.l10n.endlessFinishQuestion),
            content: Text(
              context.l10n.endlessFinishDetail(
                run.bankedCoins,
                run.bankedXp,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.endlessKeepRunning),
              ),
              FilledButton(
                key: const ValueKey('endless-finish-confirm'),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.l10n.endlessFinish),
              ),
            ],
          ),
    );
    if (confirmed == true) onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Canavarın "canı" adım cinsinden: kesime kalan adım azaldıkça
    // can çubuğu boşalıyor. Normal maceradaki düşman çubuğuyla aynı yer,
    // aynı renk, aynı okuma biçimi.
    final monsterRemaining = run.stepsRemainingInCut;
    final monsterMax = run.monsterHealthSteps;
    final monsterProgress = monsterMax <= 0
        ? 0.0
        : (monsterRemaining / monsterMax).clamp(0.0, 1.0);
    final playerPercent = (run.playerHealthProgress * 100).round();
    final monsterPercent = (monsterProgress * 100).round();

    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxHeight < 680;
        return Stack(
          fit: StackFit.expand,
          children: [
            CombatHudBackdrop(backgroundAsset: run.backgroundAsset),
            Padding(
              padding: EdgeInsets.fromLTRB(14, compact ? 6 : 12, 14, 12),
              child: Column(
                children: [
                  // Üst şerit: kesim başlığı + çarpan.
                  //
                  // ⚠️ **Geri sayan süre burada yok** (GD106). Normal macerada
                  // aynı yerde `round-countdown` duruyor; sonsuz koşuda
                  // bilerek çizilmiyor — mantık aynen işliyor, yalnızca
                  // gösterilmiyor.
                  SizedBox(
                    height: compact ? 76 : 92,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            key: const ValueKey('endless-exit'),
                            onPressed: () => _confirmFinish(context),
                            tooltip: l10n.endlessFinish,
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white70,
                              backgroundColor: Colors.black38,
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        if (onSimulateSteps != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: IconButton(
                              key: const ValueKey('endless-simulate-200'),
                              onPressed: onSimulateSteps,
                              tooltip: '+200 Steps',
                              style: IconButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                backgroundColor: Colors.black38,
                              ),
                              icon: const Icon(Icons.admin_panel_settings),
                            ),
                          ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.endlessCuts(run.cutCount).toUpperCase(),
                              key: const ValueKey('endless-cut-header'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: compact ? 14 : 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.2,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 8),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 5),
                            // Çarpan bu modun imzası; HUD'un **içinde**,
                            // normal maceranın geri sayımıyla aynı yerde.
                            Text(
                              '\u00d7${AppFormatters.decimal(
                                context,
                                run.multiplier,
                                digits: 2,
                              )}',
                              key: const ValueKey('endless-multiplier'),
                              style: TextStyle(
                                color: AppColors.streak,
                                fontSize: compact ? 34 : 44,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 10),
                                  Shadow(
                                    color: AppColors.streak,
                                    blurRadius: 22,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, stage) {
                        final spriteWidth = (stage.maxWidth * 0.58).clamp(
                          150.0,
                          300.0,
                        );
                        final spriteHeight = (stage.maxHeight * 0.82).clamp(
                          150.0,
                          390.0,
                        );
                        final healthBottom = (spriteHeight - 42).clamp(
                          94.0,
                          stage.maxHeight - 66,
                        );
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              bottom: healthBottom,
                              width: (stage.maxWidth - 18) / 2,
                              child: CombatHudHealthBar(
                                key: const ValueKey('endless-player-health'),
                                progressKey: const ValueKey(
                                  'endless-player-health-progress',
                                ),
                                label: avatar.name.toUpperCase(),
                                value: run.playerHealthProgress,
                                valueText:
                                    '${run.playerHealth} / '
                                    '${run.playerMaxHealth}  \u00b7  '
                                    '$playerPercent%',
                                color: AppColors.xp,
                                alignment: CrossAxisAlignment.start,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: healthBottom,
                              width: (stage.maxWidth - 18) / 2,
                              child: CombatHudHealthBar(
                                key: const ValueKey('endless-monster-health'),
                                progressKey: const ValueKey(
                                  'endless-monster-health-progress',
                                ),
                                label: l10n
                                    .enemyName(run.enemy)
                                    .toUpperCase(),
                                value: monsterProgress,
                                valueText:
                                    '$monsterRemaining / $monsterMax  \u00b7  '
                                    '$monsterPercent%',
                                color: AppColors.hp,
                                alignment: CrossAxisAlignment.end,
                              ),
                            ),
                            Positioned(
                              left: -spriteWidth * 0.12,
                              bottom: -spriteHeight * 0.08,
                              width: spriteWidth,
                              height: spriteHeight,
                              child: PixelSprite(
                                asset: avatar.characterAsset,
                                scale: 3.5,
                              ),
                            ),
                            Positioned(
                              right: -spriteWidth * 0.12,
                              bottom: -spriteHeight * 0.08,
                              width: spriteWidth,
                              height: spriteHeight,
                              child: PixelSprite(
                                key: const ValueKey('endless-monster'),
                                asset: _monsterAsset(run),
                                // Güçlenmenin görsel karşılığı: taban oran
                                // maceranınkiyle aynı, üstüne kesim ölçeği
                                // biniyor.
                                scale: 3.5 * run.spriteScale,
                                offset: const Offset(-8, 0),
                                // Macerayla aynı desen: durum değişince GIF
                                // baştan oynasın diye anahtar duruma bağlı.
                                imageKey: ValueKey(
                                  run.lastEnemyDamage > 0
                                      ? 'attack-${run.enemyAttackSerial}'
                                      : 'walk-${run.cutCount}',
                                ),
                              ),
                            ),
                            if (run.lastEnemyDamage > 0)
                              Positioned(
                                left: 0,
                                width: (stage.maxWidth - 18) / 2,
                                top: compact ? 58 : 72,
                                child: CombatHudDamageLabel(
                                  key: const ValueKey('endless-damage-label'),
                                  text: l10n.healthDamageUpper(
                                    run.lastEnemyDamage,
                                  ),
                                  color: AppColors.hp,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  CombatHudPanel(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        compact ? 10 : 14,
                        14,
                        compact ? 10 : 14,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_walk,
                                color: AppColors.streak,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n
                                      .endlessNextCut(run.stepsRemainingInCut)
                                      .toUpperCase(),
                                  key: const ValueKey('endless-cut-text'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 15 : 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          LinearProgressIndicator(
                            key: const ValueKey('endless-cut-progress'),
                            value: run.cutProgress.clamp(0, 1),
                            minHeight: compact ? 10 : 13,
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.streak,
                            backgroundColor: Colors.white12,
                          ),
                          SizedBox(height: compact ? 8 : 11),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${l10n.endlessBanked}: '
                                  '${l10n.endlessBankedValue(
                                    run.bankedCoins,
                                    run.bankedXp,
                                  )}',
                                  key: const ValueKey('endless-banked-text'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 5 : 8),
                          // Güvenlik satırı HUD'a taşındı: normal maceranın
                          // alt kartında böyle bir satır yok ama bu modun
                          // sözleşmesi tam olarak bu (GD90 · §6.17), ekranda
                          // tutulması bilinçli.
                          Text(
                            SafetyMessages.of(context).walking,
                            key: const ValueKey('endless-safety-note'),
                            style: const TextStyle(
                              color: AppColors.streak,
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: compact ? 7 : 10),
                          SizedBox(
                            width: double.infinity,
                            height: compact ? 34 : 40,
                            child: OutlinedButton.icon(
                              key: const ValueKey('endless-finish'),
                              onPressed: () => _confirmFinish(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(
                                  color: AppColors.hp.withValues(alpha: 0.55),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.logout, size: 17),
                              label: Text(
                                l10n.endlessFinish,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Canavarın o anki karesi.
  ///
  /// Havuz `endlessAttackAssets` ile geliyor: 15. kesimden sonra **Beam** de
  /// giriyor. Seçim tohumlu (`enemyAttackSerial`), yani aynı vuruş her
  /// çizimde aynı animasyonu gösteriyor.
  String _monsterAsset(EndlessRun run) {
    if (run.lastEnemyDamage <= 0) return run.enemy.walkAsset;
    final pool = endlessAttackAssets(run.enemy, run.cutCount);
    return pool[run.enemyAttackSerial % pool.length];
  }
}

/// Bitiş ekranı.
///
/// **Dokunma beklemez**: oyuncu cebinden çıkardığında sonucu görür, sonuç
/// onu beklemiş olur. Kapatma düğmesi var ama zorunlu değil.
class _EndlessResult extends StatelessWidget {
  final EndlessRun run;
  final VoidCallback onClose;

  const _EndlessResult({required this.run, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final defeated = run.isDefeated;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Icon(
          defeated ? Icons.favorite_border : Icons.emoji_events,
          size: 56,
          color: defeated ? AppColors.hp : AppColors.streak,
        ),
        const SizedBox(height: 14),
        Text(
          defeated ? l10n.endlessDefeatedTitle : l10n.endlessBankedTitle,
          key: const ValueKey('endless-result-title'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.endlessResultCuts(run.cutCount),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.endlessResultReward(run.paidCoins, run.paidXp),
                key: const ValueKey('endless-result-reward'),
                style: const TextStyle(
                  color: AppColors.streak,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (run.rewardItemId != null) ...[
                const SizedBox(height: 10),
                // Normal macera zaferiyle **aynı** bileşen: iki modın ödül
                // dili ayrışmamalı. Eskiden burada ham asset kimliği
                // basılıyordu ("fire_sword_variant_03") — iki dilde de bozuk.
                DroppedItemCard(
                  itemId: run.rewardItemId!,
                  label: l10n.droppedItemLabel,
                ),
              ],
              if (defeated) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.endlessDefeatedNote,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          key: const ValueKey('endless-close'),
          onPressed: onClose,
          child: Text(l10n.endlessClose),
        ),
      ],
    );
  }
}
