import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/constants/safety_messages.dart';
import '../../core/utils/endless_rules.dart';
import '../../core/localization/app_formatters.dart';
import '../../core/theme/app_theme.dart';

import '../../l10n/l10n_context.dart';
import '../../models/avatar_profile.dart';
import '../../models/endless_run.dart';
import '../../widgets/dropped_item_card.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.endlessTitle)),
      body: SafeArea(
        child:
            run.isFinished
                ? _EndlessResult(run: run, onClose: onClose)
                : _EndlessActive(run: run, avatar: avatar, onFinish: onFinish, onSimulateSteps: onSimulateSteps),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Çarpan: ekranın en büyük ve en net sayısı. Oyuncu cebinden
        // çıkardığında tek bakışta "ne kadar biriktirdim" görmeli.
        _MultiplierBanner(run: run),
        const SizedBox(height: 12),
        _EndlessScene(run: run, avatar: avatar),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Line(
                label: l10n.endlessCuts(run.cutCount),
                value: l10n.endlessNextCut(run.stepsRemainingInCut),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                key: const ValueKey('endless-cut-progress'),
                value: run.cutProgress,
                minHeight: 8,
                backgroundColor: Colors.white12,
                color: AppColors.accent,
              ),
              const SizedBox(height: 14),
              _Line(
                label: l10n.endlessPlayerHealth,
                value: '${run.playerHealth} / ${run.playerMaxHealth}',
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                key: const ValueKey('endless-player-health'),
                value: run.playerHealthProgress,
                minHeight: 8,
                backgroundColor: Colors.white12,
                color: AppColors.hp,
              ),
              const SizedBox(height: 14),
              _Line(
                label: l10n.endlessBanked,
                value: l10n.endlessBankedValue(run.bankedCoins, run.bankedXp),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.endlessRoundInfo(
                  GameConstants.endlessRoundSteps,
                  GameConstants.endlessRoundSeconds ~/ 60,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.endlessNoInput,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              // Güvenlik metni Faz 1'de yazılanlardan: "süre sınırı var ama
              // senden bir karar beklenmiyor" tam olarak bu modu anlatıyor.
              Text(
                SafetyMessages.of(context).walking,
                style: const TextStyle(
                  color: AppColors.streak,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (onSimulateSteps != null) ...[
        OutlinedButton(
          key: const ValueKey('endless-simulate-200'),
          onPressed: onSimulateSteps,
          child: const Text('+200 Steps'),
        ),
        const SizedBox(height: 8),
        ],
        FilledButton(
          key: const ValueKey('endless-finish'),
          onPressed: () => _confirmFinish(context),
          child: Text(l10n.endlessFinish),
        ),
      ],
    );
  }
}

/// Çarpan şeridi — büyük ve net.
class _MultiplierBanner extends StatelessWidget {
  final EndlessRun run;

  const _MultiplierBanner({required this.run});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          children: [
            Text(
              context.l10n.endlessMultiplier,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '×${AppFormatters.decimal(context, run.multiplier, digits: 2)}',
                key: const ValueKey('endless-multiplier'),
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sahne: oyuncu solda, canavar sağda.
///
/// **Çizim normal maceranınkiyle aynı** — aynı `PixelSprite`, aynı 100×100
/// tuval, aynı `scale: 3` tabanı, aynı `bottom: -22` oturtması. Tek fark
/// canavarın ölçeğine [EndlessRun.spriteScale] çarpanının binmesi; güçlenme
/// böylece görsel olarak da okunuyor. `PixelSprite` zaten `ClipRect` içinde
/// ve `FilterQuality.none` koruyor, yani büyüyen sprite bulanıklaşmıyor,
/// pikselleşiyor.
///
/// Animasyon durumları da maceradakiyle aynı havuzdan: hasar alındığında
/// `hurtAsset`, normalde `walkAsset`. Ekstra durum uydurulmadı.
class _EndlessScene extends StatelessWidget {
  final EndlessRun run;
  final AvatarProfile avatar;

  const _EndlessScene({required this.run, required this.avatar});

  /// Canavarın o anki karesi.
  ///
  /// Havuz `endlessAttackAssets` ile geliyor: 15. kesimden sonra **Beam** de
  /// giriyor. Seçim tohumlu (`enemyAttackSerial`), yani aynı vuruş her
  /// çizimde aynı animasyonu gösteriyor — normal maceradaki "bir öncekiyle
  /// aynı olmasın" kuralının deterministik karşılığı.
  String _monsterAsset(EndlessRun run) {
    if (run.lastEnemyDamage <= 0) return run.enemy.walkAsset;
    final pool = endlessAttackAssets(run.enemy, run.cutCount);
    return pool[run.enemyAttackSerial % pool.length];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spriteWidth = (constraints.maxWidth * 0.42).clamp(90.0, 170.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  run.backgroundAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: AppColors.surface,
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: -22,
                  width: spriteWidth,
                  height: 190,
                  child: PixelSprite(
                    asset: avatar.characterAsset,
                    scale: 2.4,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: -22,
                  width: spriteWidth,
                  height: 190,
                  child: PixelSprite(
                    key: const ValueKey('endless-monster'),
                    asset: _monsterAsset(run),
                    // Güçlenmenin görsel karşılığı. Taban macerayla aynı
                    // oran; üstüne kesim ölçeği biniyor.
                    scale: 2.4 * run.spriteScale,
                    offset: const Offset(-8, 0),
                    // Macerayla aynı desen: durum değişince GIF baştan
                    // oynasın diye anahtar duruma bağlı.
                    imageKey: ValueKey(
                      run.lastEnemyDamage > 0
                          ? 'endless-attack-${run.enemyAttackSerial}'
                          : 'endless-cut-${run.cutSerial}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
