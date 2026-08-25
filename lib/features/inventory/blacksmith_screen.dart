import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/item_leveling.dart';
import '../../core/utils/item_merging.dart';
import '../../models/item.dart';
import '../../models/owned_item.dart';
import '../../models/reward_rarity.dart';
import '../../widgets/archetype_badge.dart';
import '../../widgets/rarity_badge.dart';
import '../../widgets/section_card.dart';
import 'inventory_screen.dart';

/// Demirci: eşya **yükseltme** ve **birleştirme**.
///
/// Envanterden ayrı bir ekran, çünkü iki işlem de aynı soruyu soruyor —
/// "elimdeki eşyaya mı yatırım yapayım, yenisini mi alayım" — ve bu soruyu
/// envanterin kuşanma listesinin arasında sormak kayboluyordu.
///
/// Ekran veri **tutmuyor**: her çizimde [readState] ile durumu yeniden okuyor
/// ve `RootShell`'in `revision` sayacını dinliyor (GD27). İtilen bir rota
/// `RootShell`'in alt ağacında değil, `setState` onu tazelemiyor.
class BlacksmithScreen extends StatelessWidget {
  final ValueListenable<int> revision;
  final InventoryState Function() readState;

  /// Tek bir örneği bir seviye yükseltir.
  final void Function(int instanceId) onUpgrade;

  /// Aynı eşyanın aynı nadirlikteki örneklerini birleştirir.
  final void Function(String itemId, RewardRarity rarity) onMerge;

  const BlacksmithScreen({
    super.key,
    required this.revision,
    required this.readState,
    required this.onUpgrade,
    required this.onMerge,
  });

  /// Envanteri **kimlik + nadirlik** gruplarına böler ve her grubu bir
  /// karta çevirir.
  ///
  /// Sıra: nadirlik (yüksekten alçağa), sonra en yüksek eşya seviyesi, sonra
  /// ad. Son ölçüt anahtar — her çizimde aynı sıra çıksın.
  List<_ForgeGroup> _groups(InventoryState state) {
    final byKey = <String, List<InventoryEntry>>{};
    for (final entry in state.entries) {
      byKey
          .putIfAbsent(
            mergeGroupKey(entry.item.id, entry.item.rarity),
            () => [],
          )
          .add(entry);
    }

    final groups = [
      for (final entry in byKey.entries) _ForgeGroup(entry.key, entry.value),
    ];
    groups.sort((a, b) {
      final byRarity = b.rarity.index.compareTo(a.rarity.index);
      if (byRarity != 0) return byRarity;
      final byLevel = b.bestLevel.compareTo(a.bestLevel);
      if (byLevel != 0) return byLevel;
      final byName = a.item.name.compareTo(b.item.name);
      if (byName != 0) return byName;
      return a.key.compareTo(b.key);
    });
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: revision,
      builder: (context, _, __) {
        final state = readState();
        final groups = _groups(state);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Demirci'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: AppColors.streak,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${state.profile.coins}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body:
              groups.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Örs boş. Mağazadan ekipman aldığında burada '
                      'yükseltebilir, aynı eşyadan birkaç adet biriktirince '
                      'birleştirebilirsin.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ForgeCard(
                          key: ValueKey(group.key),
                          group: group,
                          playerLevel: state.profile.level,
                          coins: state.profile.coins,
                          onUpgrade: onUpgrade,
                          onMerge: onMerge,
                        ),
                      );
                    },
                  ),
        );
      },
    );
  }
}

/// Aynı eşyanın aynı nadirlikteki bütün örnekleri.
class _ForgeGroup {
  final String key;
  final List<InventoryEntry> entries;

  _ForgeGroup(this.key, this.entries) {
    // En yüksek seviyeli örnek başa: yükseltme her zaman **en gelişmiş**
    // örneğe uygulanıyor, oyuncu yatırımını tek bir eşyada toplasın.
    entries.sort((a, b) {
      if (a.level != b.level) return b.level.compareTo(a.level);
      return a.instanceId.compareTo(b.instanceId);
    });
  }

  InventoryEntry get best => entries.first;
  Item get item => best.item;
  RewardRarity get rarity => item.rarity;
  int get bestLevel => best.level;
  int get count => entries.length;
  List<OwnedItem> get instances => [for (final e in entries) e.instance];
}

class _ForgeCard extends StatelessWidget {
  final _ForgeGroup group;
  final int playerLevel;
  final int coins;
  final void Function(int instanceId) onUpgrade;
  final void Function(String itemId, RewardRarity rarity) onMerge;

  const _ForgeCard({
    super.key,
    required this.group,
    required this.playerLevel,
    required this.coins,
    required this.onUpgrade,
    required this.onMerge,
  });

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  /// Birleştirme geri alınamaz: onay istenir ve **ne kaybedildiği** ile
  /// **ne kazanıldığı** açıkça yazılır.
  Future<void> _confirmMerge(BuildContext context, MergeQuote quote) async {
    final target = quote.target;
    if (target == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Birleştirilsin mi?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${quote.requiredCount} adet ${group.item.name} '
                  've ${quote.cost} coin harcanacak.',
                ),
                const SizedBox(height: 8),
                Text(
                  'Karşılığında 1 adet ${target.label} '
                  '${group.item.name} alacaksın — Sv. 1, nadirlik tavanı '
                  '${itemLevelCap(target)}.',
                  style: const TextStyle(color: AppColors.xp),
                ),
                const SizedBox(height: 8),
                Text(
                  'Harcanan eşyaların seviyeleri: '
                  '${_consumedLevels(quote).join(', ')}.',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
                if (quote.consumesEquipped) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Kuşanılı bir adet harcanacak; önce çıkarılacak.',
                    style: TextStyle(fontSize: 12, color: AppColors.streak),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Bu işlem geri alınamaz.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Birleştir'),
              ),
            ],
          ),
    );

    if (confirmed ?? false) onMerge(group.item.id, group.rarity);
  }

  List<String> _consumedLevels(MergeQuote quote) {
    final byId = {
      for (final entry in group.entries) entry.instanceId: entry.level,
    };
    return [for (final id in quote.consumedInstanceIds) 'Sv. ${byId[id] ?? 1}'];
  }

  @override
  Widget build(BuildContext context) {
    final item = group.item;
    final best = group.best;
    final upgrade = quoteUpgrade(
      resolved: item,
      instance: best.instance,
      playerLevel: playerLevel,
      coins: coins,
    );
    final merge = quoteMerge(
      resolved: item,
      rarity: group.rarity,
      group: group.instances,
      coins: coins,
    );
    final upgradeReason = upgrade.reason(group.rarity, playerLevel);
    final mergeReason = merge.reason(group.rarity);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Image.asset(
                  item.assetPath,
                  filterQuality: FilterQuality.none,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.inventory_2_outlined,
                        size: 32,
                        color: Colors.white24,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RarityBadge(rarity: group.rarity),
                        ArchetypeBadge(archetype: item.archetype),
                        Text(
                          '${group.count} adet',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ForgeAction(
            icon: Icons.upgrade,
            title:
                'Yükselt — Sv. ${best.level} / ${upgrade.rarityCap}'
                '${group.count > 1 ? ' (en gelişmiş adet)' : ''}',
            detail:
                upgrade.canUpgrade
                    ? compareLevels(
                      item,
                      best.level,
                      upgrade.nextLevel,
                    ).join(' · ')
                    : null,
            reason: upgradeReason,
            actionLabel:
                upgrade.canUpgrade
                    ? 'Sv. ${upgrade.nextLevel} — ${upgrade.cost} coin'
                    : 'Yükseltilemiyor',
            enabled: upgrade.canUpgrade,
            onPressed: () => onUpgrade(best.instanceId),
            onBlocked:
                () =>
                    _notify(context, upgradeReason ?? 'Şu an yükseltilemiyor.'),
          ),
          const SizedBox(height: 8),
          _ForgeAction(
            icon: Icons.merge_type,
            title:
                merge.target == null
                    ? 'Birleştirme — en üst nadirlik'
                    : 'Birleştirme — ${group.count}/${merge.requiredCount} '
                        'adet → ${merge.target!.label}',
            detail:
                merge.canMerge
                    ? 'Sonuç Sv. 1\'e döner, nadirlik tavanı '
                        '${itemLevelCap(merge.target!)} olur'
                    : null,
            reason: mergeReason,
            actionLabel:
                merge.canMerge
                    ? 'Birleştir — ${merge.cost} coin'
                    : 'Birleştirilemiyor',
            enabled: merge.canMerge,
            onPressed: () => _confirmMerge(context, merge),
            onBlocked:
                () =>
                    _notify(context, mergeReason ?? 'Şu an birleştirilemiyor.'),
          ),
        ],
      ),
    );
  }
}

/// Demirci kartındaki tek bir işlem satırı.
///
/// Devre dışı görünse de **dokunulabilir**: engelin nedenini söyleyecek
/// birinin olması gerekiyor (Model Kuralları #4).
class _ForgeAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final String? reason;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onPressed;
  final VoidCallback onBlocked;

  const _ForgeAction({
    required this.icon,
    required this.title,
    required this.detail,
    required this.reason,
    required this.actionLabel,
    required this.enabled,
    required this.onPressed,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: enabled ? 0.10 : 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: enabled ? 0.35 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          if (detail case final text?) ...[
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 11, color: AppColors.xp),
            ),
          ],
          if (reason case final text?) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 13,
                  color: AppColors.streak,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.streak,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enabled ? onPressed : onBlocked,
              style:
                  enabled
                      ? null
                      : FilledButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white38,
                      ),
              child: Text(
                actionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
