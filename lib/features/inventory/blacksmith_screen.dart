import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/forge_filter.dart';
import '../../core/utils/item_forging.dart';
import '../../core/utils/item_leveling.dart';
import '../../core/utils/item_merging.dart';
import '../../core/utils/item_rules.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_context.dart';
import '../../l10n/content_localizations.dart';
import '../../data/forge_tiers.dart';
import '../../models/forged_effect.dart';
import '../../models/item.dart';
import '../../models/item_effect.dart';
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

  /// Süzgeç + sıralama seçimi (Bölüm E / Faz 3).
  ///
  /// `RootShell` tutuyor: ekran kapanıp açılınca seçim **oturum boyunca**
  /// korunuyor. Diske yazılmıyor — bir görünüm tercihi, oyun ilerlemesi
  /// değil. Verilmezse süreç ömrü boyunca yaşayan bir yedek kullanılır.
  final ValueNotifier<ForgeFilter>? filter;

  /// Bir etki yuvasını yeniden atar (Faz E4). [stat] + [tier] verilirse
  /// "keşiften seç". `null` ise yeniden atma arayüzü hiç çizilmez.
  final void Function(int instanceId, int slot, {ItemStat? stat, int? tier})?
  onReroll;

  /// Bekleyen atışa karar: yeniyi al (`true`) / eskisini koru (`false`).
  final void Function(int instanceId, bool accept)? onRerollDecision;

  const BlacksmithScreen({
    super.key,
    required this.revision,
    required this.readState,
    required this.onUpgrade,
    required this.onMerge,
    this.filter,
    this.onReroll,
    this.onRerollDecision,
  });

  static final ValueNotifier<ForgeFilter> _fallbackFilter = ValueNotifier(
    const ForgeFilter(),
  );

  ValueNotifier<ForgeFilter> get _filter => filter ?? _fallbackFilter;

  /// Envanteri **kimlik + nadirlik** gruplarına böler.
  ///
  /// Sıralama artık burada değil, [ForgeFilter.apply] içinde: varsayılan
  /// ölçüt ([ForgeSort.rarity]) eski sırayla birebir aynı — nadirlik
  /// (yüksekten alçağa), en yüksek eşya seviyesi, **gösterilen** ad (GD92).
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
    return [
      for (final entry in byKey.entries) _ForgeGroup(entry.key, entry.value),
    ];
  }

  /// Bir grubun süzme/sıralama gerçekleri. Kartın kendisiyle **aynı**
  /// teklif fonksiyonlarını ([quoteUpgrade], [quoteMerge]) kullanıyor:
  /// "Yükseltilebilir" süzgeci ile kartın düğmesi asla çelişmesin.
  ForgeGroupFacts _factsFor(
    _ForgeGroup group,
    InventoryState state,
    AppLocalizations l10n,
  ) {
    final upgrade = quoteUpgrade(
      resolved: group.item,
      instance: group.best.instance,
      playerLevel: state.profile.level,
      coins: state.profile.coins,
    );
    final merge = quoteMerge(
      resolved: group.item,
      rarity: group.rarity,
      group: group.instances,
      coins: state.profile.coins,
    );
    final capped =
        upgrade.block == UpgradeBlock.rarityCap ||
        upgrade.block == UpgradeBlock.playerLevel;
    return ForgeGroupFacts(
      key: group.key,
      rarity: group.rarity,
      category: group.item.category,
      name: l10n.itemName(group.item),
      bestLevel: group.bestLevel,
      anyEquipped: group.entries.any((entry) => entry.equipped),
      canUpgrade: upgrade.canUpgrade,
      hasMergeCopies:
          merge.requiredCount > 0 &&
          merge.availableCount >= merge.requiredCount,
      nextUpgradeCost:
          capped
              ? null
              : upgradeCostFor(group.item.cost, group.rarity, group.bestLevel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([revision, _filter]),
      builder: (context, _) {
        final state = readState();
        final l10n = context.l10n;
        final filter = _filter.value;
        final groups = _groups(state);
        final byKey = {for (final group in groups) group.key: group};
        final facts = [
          for (final group in groups) _factsFor(group, state, l10n),
        ];
        final visible = [
          for (final fact in filter.apply(facts)) byKey[fact.key]!,
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.blacksmith),
            actions: [
              if (onReroll != null)
                IconButton(
                  key: const ValueKey('forge-discoveries'),
                  tooltip: l10n.forgeDiscoveriesTitle,
                  icon: Badge(
                    isLabelVisible: state.profile.discoveredAffixes.isNotEmpty,
                    label: Text('${state.profile.discoveredAffixes.length}'),
                    child: const Icon(Icons.menu_book),
                  ),
                  onPressed:
                      () => _openDiscoveries(
                        context,
                        state.profile.discoveredAffixes,
                      ),
                ),
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
                  ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.emptyForge,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  )
                  : Column(
                    children: [
                      _ForgeToolbar(
                        filter: filter,
                        shown: visible.length,
                        total: groups.length,
                        onOpenFilters:
                            () => _openFilterSheet(context, facts),
                        onSort:
                            (sort) =>
                                _filter.value = filter.copyWith(sort: sort),
                        onRemove:
                            (criterion) =>
                                _filter.value = filter.without(criterion),
                        onClear: () => _filter.value = filter.cleared(),
                      ),
                      Expanded(
                        child:
                            visible.isEmpty
                                ? _ForgeEmptyResult(
                                  message: _emptyMessage(l10n, filter, facts),
                                  onClear:
                                      () => _filter.value = filter.cleared(),
                                )
                                : ListView.builder(
                                  key: const ValueKey('forge-list'),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    24,
                                  ),
                                  itemCount: visible.length,
                                  itemBuilder: (context, index) {
                                    final group = visible[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _ForgeCard(
                                        key: ValueKey(group.key),
                                        group: group,
                                        playerLevel: state.profile.level,
                                        coins: state.profile.coins,
                                        characterClass:
                                            state.profile.avatar.characterClass,
                                        discovered:
                                            state.profile.discoveredAffixes,
                                        onUpgrade: onUpgrade,
                                        onMerge: onMerge,
                                        onReroll: onReroll,
                                        onRerollDecision: onRerollDecision,
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
        );
      },
    );
  }

  /// Sonuç boşken ne söyleneceği: **hangi** süzgecin boşalttığı.
  String _emptyMessage(
    AppLocalizations l10n,
    ForgeFilter filter,
    List<ForgeGroupFacts> facts,
  ) {
    final blocking = filter.blockingCriterion(facts);
    if (blocking != null) {
      return l10n.forgeEmptyBlocked(forgeCriterionLabel(l10n, blocking));
    }
    return l10n.forgeEmptyCombined(
      [
        for (final criterion in filter.criteria)
          forgeCriterionLabel(l10n, criterion),
      ].join(' + '),
    );
  }

  /// Süzgeç alt penceresi. Seçimler **anında** uygulanır: oyuncu listenin
  /// arkada değiştiğini görür, ayrı bir "Uygula" adımı yok.
  void _openFilterSheet(BuildContext context, List<ForgeGroupFacts> facts) {
    // Yalnızca envanterde gerçekten bulunan türler: olmayan bir türü
    // seçtirmek boş sonuçtan başka bir şey üretmez.
    final categories = [
      for (final category in ItemCategory.values)
        if (facts.any((fact) => fact.category == category)) category,
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder:
          (sheetContext) => ValueListenableBuilder<ForgeFilter>(
            valueListenable: _filter,
            builder:
                (sheetContext, filter, _) => _ForgeFilterSheet(
                  filter: filter,
                  categories: categories,
                  onChanged: (next) => _filter.value = next,
                ),
          ),
    );
  }
}

/// Keşfedilen etkilerin listesi (Faz E4): stat sırasıyla, kademe artan.
void _openDiscoveries(BuildContext context, List<String> discovered) {
  final entries = <(ItemStat, int)>[
    for (final stat in ItemStat.values)
      for (var tier = 1; tier <= ForgeTiers.tierCount; tier++)
        if (discovered.contains(forgeAffixKey(stat, tier))) (stat, tier),
  ];
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: ListView(
            key: const ValueKey('forge-discoveries-sheet'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Text(
                l10n.forgeDiscoveriesTitle,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.forgeDiscoveriesCount(entries.length),
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 10),
              if (entries.isEmpty)
                Text(
                  l10n.forgeDiscoveriesEmpty,
                  style: const TextStyle(color: Colors.white70),
                )
              else
                for (final (stat, tier) in entries)
                  ListTile(
                    key: ValueKey('forge-discovery-${forgeAffixKey(stat, tier)}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.auto_fix_high, color: AppColors.xp),
                    title: Text(l10n.itemStatName(stat)),
                    subtitle: Text(l10n.forgeTierRange(stat, tier)),
                  ),
            ],
          ),
        ),
      );
    },
  );
}

/// Bir süzgeç ölçütünün kullanıcıya görünen adı (çip ve boş sonuç mesajı).
String forgeCriterionLabel(AppLocalizations l10n, ForgeCriterion criterion) =>
    switch (criterion) {
      RarityCriterion(:final rarity) => l10n.rarityName(rarity),
      CategoryCriterion(:final category) => l10n.itemCategoryName(category),
      EquipCriterion(:final equip) => forgeEquipLabel(l10n, equip),
      UpgradableCriterion() => l10n.forgeUpgradable,
      MergeableCriterion() => l10n.forgeMergeable,
    };

String forgeEquipLabel(AppLocalizations l10n, ForgeEquipFilter equip) =>
    switch (equip) {
      ForgeEquipFilter.any => l10n.forgeEquipAny,
      ForgeEquipFilter.equipped => l10n.forgeEquipEquipped,
      ForgeEquipFilter.unequipped => l10n.forgeEquipUnequipped,
    };

String forgeSortName(AppLocalizations l10n, ForgeSort sort) => switch (sort) {
  ForgeSort.rarity => l10n.forgeSortRarity,
  ForgeSort.level => l10n.forgeSortLevel,
  ForgeSort.name => l10n.forgeSortName,
  ForgeSort.upgradeCost => l10n.forgeSortUpgradeCost,
};

/// Süzgeç düğmesi, sıralama menüsü ve etkin süzgeç çipleri.
///
/// 320 dp'ye sığmak için iki satır: üstte düğme + menü, altta yatay kayan
/// çipler. Seçili süzgeç **her zaman görünür**: oyuncu neden az eşya
/// gördüğünü buradan okur.
class _ForgeToolbar extends StatelessWidget {
  final ForgeFilter filter;
  final int shown;
  final int total;
  final VoidCallback onOpenFilters;
  final ValueChanged<ForgeSort> onSort;
  final ValueChanged<ForgeCriterion> onRemove;
  final VoidCallback onClear;

  const _ForgeToolbar({
    required this.filter,
    required this.shown,
    required this.total,
    required this.onOpenFilters,
    required this.onSort,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final criteria = filter.criteria;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: OutlinedButton.icon(
                  key: const ValueKey('forge-filter-button'),
                  onPressed: onOpenFilters,
                  icon: Icon(
                    filter.isActive ? Icons.filter_alt : Icons.filter_list,
                    size: 18,
                  ),
                  label: Text(
                    filter.isActive
                        ? l10n.forgeFilterCount(filter.activeCount)
                        : l10n.forgeFilter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        filter.isActive ? AppColors.xp : Colors.white,
                    side: BorderSide(
                      color:
                          filter.isActive
                              ? AppColors.xp
                              : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: PopupMenuButton<ForgeSort>(
                  key: const ValueKey('forge-sort-button'),
                  initialValue: filter.sort,
                  onSelected: onSort,
                  itemBuilder:
                      (context) => [
                        for (final sort in ForgeSort.values)
                          PopupMenuItem(
                            key: ValueKey('forge-sort-${sort.name}'),
                            value: sort,
                            child: Text(forgeSortName(l10n, sort)),
                          ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.forgeSortLabel(
                              forgeSortName(l10n, filter.sort),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (criteria.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                key: const ValueKey('forge-active-chips'),
                scrollDirection: Axis.horizontal,
                children: [
                  ActionChip(
                    key: const ValueKey('forge-clear-filters'),
                    avatar: const Icon(Icons.clear_all, size: 16),
                    label: Text(l10n.forgeClearFilters),
                    onPressed: onClear,
                    visualDensity: VisualDensity.compact,
                  ),
                  for (var i = 0; i < criteria.length; i++) ...[
                    const SizedBox(width: 6),
                    InputChip(
                      key: ValueKey('forge-chip-$i'),
                      label: Text(forgeCriterionLabel(l10n, criteria[i])),
                      onDeleted: () => onRemove(criteria[i]),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColors.xp),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.forgeShowingCount(shown, total),
              key: const ValueKey('forge-showing-count'),
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }
}

/// Süzgeçler hiçbir eşya bırakmadığında: boş ekran değil, **sebep** ve tek
/// dokunuşla temizleme.
class _ForgeEmptyResult extends StatelessWidget {
  final String message;
  final VoidCallback onClear;

  const _ForgeEmptyResult({required this.message, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        key: const ValueKey('forge-empty-result'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 40, color: Colors.white38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.forgeEmptyHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('forge-empty-clear'),
            onPressed: onClear,
            icon: const Icon(Icons.clear_all),
            label: Text(context.l10n.forgeClearFilters),
          ),
        ],
      ),
    );
  }
}

/// Süzgeç alt penceresi.
class _ForgeFilterSheet extends StatelessWidget {
  final ForgeFilter filter;
  final List<ItemCategory> categories;
  final ValueChanged<ForgeFilter> onChanged;

  const _ForgeFilterSheet({
    required this.filter,
    required this.categories,
    required this.onChanged,
  });

  Widget _section(String title, List<Widget> chips) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: chips),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          key: const ValueKey('forge-filter-sheet'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.forgeFilterSheetTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('forge-sheet-clear'),
                    onPressed:
                        filter.isActive
                            ? () => onChanged(filter.cleared())
                            : null,
                    child: Text(l10n.forgeClearFilters),
                  ),
                ],
              ),
              _section(l10n.forgeFilterRarity, [
                for (final rarity in RewardRarity.values)
                  FilterChip(
                    key: ValueKey('forge-filter-rarity-${rarity.name}'),
                    label: Text(l10n.rarityName(rarity)),
                    selected: filter.rarities.contains(rarity),
                    onSelected:
                        (on) => onChanged(
                          filter.copyWith(
                            rarities:
                                on
                                    ? {...filter.rarities, rarity}
                                    : ({...filter.rarities}..remove(rarity)),
                          ),
                        ),
                  ),
              ]),
              _section(l10n.forgeFilterCategory, [
                for (final category in categories)
                  FilterChip(
                    key: ValueKey('forge-filter-category-${category.name}'),
                    label: Text(l10n.itemCategoryName(category)),
                    selected: filter.categories.contains(category),
                    onSelected:
                        (on) => onChanged(
                          filter.copyWith(
                            categories:
                                on
                                    ? {...filter.categories, category}
                                    : ({...filter.categories}..remove(category)),
                          ),
                        ),
                  ),
              ]),
              _section(l10n.forgeFilterEquip, [
                for (final equip in ForgeEquipFilter.values)
                  ChoiceChip(
                    key: ValueKey('forge-filter-equip-${equip.name}'),
                    label: Text(forgeEquipLabel(l10n, equip)),
                    selected: filter.equip == equip,
                    onSelected: (_) => onChanged(filter.copyWith(equip: equip)),
                  ),
              ]),
              _section(l10n.forgeFilterStatus, [
                FilterChip(
                  key: const ValueKey('forge-filter-upgradable'),
                  label: Text(l10n.forgeUpgradable),
                  selected: filter.upgradableOnly,
                  onSelected:
                      (on) => onChanged(filter.copyWith(upgradableOnly: on)),
                ),
                FilterChip(
                  key: const ValueKey('forge-filter-mergeable'),
                  label: Text(l10n.forgeMergeable),
                  selected: filter.mergeableOnly,
                  onSelected:
                      (on) => onChanged(filter.copyWith(mergeableOnly: on)),
                ),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('forge-sheet-done'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.forgeDone),
                ),
              ),
            ],
          ),
        ),
      ),
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
  final String characterClass;
  final List<String> discovered;
  final void Function(int instanceId) onUpgrade;
  final void Function(String itemId, RewardRarity rarity) onMerge;
  final void Function(int instanceId, int slot, {ItemStat? stat, int? tier})?
  onReroll;
  final void Function(int instanceId, bool accept)? onRerollDecision;

  const _ForgeCard({
    super.key,
    required this.group,
    required this.playerLevel,
    required this.coins,
    required this.characterClass,
    required this.discovered,
    required this.onUpgrade,
    required this.onMerge,
    this.onReroll,
    this.onRerollDecision,
  });

  /// Bir jenerik yuvanın kademesi: atılmışsa saklanan kademe, değilse
  /// değerin (Sv. 1'e indirgenmiş) en yakın kademesi.
  int _tierOf(int slot, ItemEffect effect) {
    final forged = group.best.instance.forgedEffects;
    if (forged != null && slot < forged.length) return forged[slot].tier;
    final base =
        effect.stat.isCombat
            ? effect.value / levelMultiplier(group.bestLevel)
            : effect.value;
    return classifyForgeTier(effect.stat, base);
  }

  /// Yeniden atma penceresi (Faz E4).
  Future<void> _openReroll(BuildContext context, int slot) async {
    final reroll = onReroll;
    if (reroll == null) return;
    if (group.best.instance.pendingForge != null) {
      _notify(context, context.l10n.forgePendingBlocked);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder:
          (sheetContext) => _RerollSheet(
            item: group.item,
            instance: group.best.instance,
            slot: slot,
            coins: coins,
            characterClass: characterClass,
            discovered: discovered,
            onRandom: () {
              Navigator.of(sheetContext).pop();
              reroll(group.best.instanceId, slot);
            },
            onPick: (stat, tier) {
              Navigator.of(sheetContext).pop();
              reroll(group.best.instanceId, slot, stat: stat, tier: tier);
            },
          ),
    );
  }

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
            title: Text(context.l10n.mergeQuestion),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.mergeCostWarning(
                    quote.requiredCount,
                    context.l10n.itemName(group.item),
                    quote.cost,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.mergeResult(
                    context.l10n.rarityName(target),
                    context.l10n.itemName(group.item),
                    itemLevelCap(target),
                  ),
                  style: const TextStyle(color: AppColors.xp),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.consumedItemLevels(
                    _consumedLevels(context, quote).join(', '),
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
                // Birleştirme sonucu yepyeni bir örnek (GD42); tüketilen
                // örneklerde yeniden atılmış etkiler varsa kaybolurlar.
                if (group.entries.any(
                  (entry) =>
                      quote.consumedInstanceIds.contains(entry.instanceId) &&
                      entry.instance.forgedEffects != null,
                )) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.forgeMergeResetsRolls,
                    key: const ValueKey('forge-merge-resets-rolls'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.streak,
                    ),
                  ),
                ],
                if (quote.consumesEquipped) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.equippedItemConsumed,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.streak,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  context.l10n.irreversibleAction,
                  style: const TextStyle(
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
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(context.l10n.merge),
              ),
            ],
          ),
    );

    if (confirmed ?? false) onMerge(group.item.id, group.rarity);
  }

  List<String> _consumedLevels(BuildContext context, MergeQuote quote) {
    final byId = {
      for (final entry in group.entries) entry.instanceId: entry.level,
    };
    return [
      for (final id in quote.consumedInstanceIds)
        context.l10n.levelShort(byId[id] ?? 1),
    ];
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
    final upgradeReason =
        upgrade.canUpgrade
            ? null
            : context.l10n.upgradeBlockReason(
              upgrade,
              group.rarity,
              playerLevel,
            );
    final mergeReason =
        merge.canMerge
            ? null
            : context.l10n.mergeBlockReason(merge, group.rarity);

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
                      context.l10n.itemName(item),
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
                          context.l10n.ownedCount(group.count),
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
          ForgeBuffSummary(
            key: ValueKey('forge-buffs-${group.key}'),
            item: item,
            subtitleFor: (index, effect) {
              final slot = index - signatureCoreCount(item);
              if (slot < 0) return null;
              return context.l10n.forgeTierRange(
                effect.stat,
                _tierOf(slot, effect),
                scale: levelMultiplier(group.bestLevel),
              );
            },
            trailingFor:
                onReroll == null
                    ? null
                    : (index, effect) {
                      final slot = index - signatureCoreCount(item);
                      if (slot < 0) return null;
                      final blocked = group.best.instance.pendingForge != null;
                      return IconButton(
                        key: ValueKey('forge-reroll-slot-$slot'),
                        tooltip: context.l10n.forgeRerollTooltip,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: Icon(
                          Icons.casino_outlined,
                          size: 18,
                          color: blocked ? Colors.white24 : AppColors.primary,
                        ),
                        onPressed: () => _openReroll(context, slot),
                      );
                    },
          ),
          if (group.best.instance.pendingForge case final pending?
              when onRerollDecision != null) ...[
            const SizedBox(height: 10),
            _ForgeDecisionPanel(
              item: item,
              level: group.bestLevel,
              pending: pending,
              onDecide:
                  (accept) =>
                      onRerollDecision!(group.best.instanceId, accept),
            ),
          ],
          const SizedBox(height: 10),
          _ForgeAction(
            icon: Icons.upgrade,
            title: context.l10n.upgradeBestItem(
              best.level,
              upgrade.rarityCap,
              group.count > 1 ? context.l10n.mostAdvancedSuffix : '',
            ),
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
                    ? context.l10n.upgradeToLevel(
                      upgrade.nextLevel,
                      upgrade.cost,
                    )
                    : context.l10n.cannotUpgrade,
            enabled: upgrade.canUpgrade,
            onPressed: () => onUpgrade(best.instanceId),
            onBlocked:
                () => _notify(
                  context,
                  upgradeReason ?? context.l10n.cannotUpgradeNow,
                ),
          ),
          const SizedBox(height: 8),
          _ForgeAction(
            icon: Icons.merge_type,
            title:
                merge.target == null
                    ? context.l10n.mergeHighestRarity
                    : context.l10n.mergeProgressTitle(
                      group.count,
                      merge.requiredCount,
                      context.l10n.rarityName(merge.target!),
                    ),
            detail:
                merge.canMerge
                    ? context.l10n.mergeResetDetail(itemLevelCap(merge.target!))
                    : null,
            reason: mergeReason,
            actionLabel:
                merge.canMerge
                    ? context.l10n.mergeWithCost(merge.cost)
                    : context.l10n.cannotMerge,
            enabled: merge.canMerge,
            onPressed: () => _confirmMerge(context, merge),
            onBlocked:
                () => _notify(
                  context,
                  mergeReason ?? context.l10n.cannotMergeNow,
                ),
          ),
        ],
      ),
    );
  }
}

/// Kartta eşyanın **bütün** etkileri (Bölüm E / Faz 3).
///
/// Sıra GD110'un sırası: imzalı etkiler önde ve "İmza" rozetli, kural
/// havuzundan eklenenler arkada. Eksi değerli bedeller ayrı renkte ve
/// "Bedel" rozetiyle — bir artı gibi okunmamalı.
///
/// Altı etkili bir efsanevi kartı belirgin uzatıyor; liste katlanabilir ama
/// **varsayılan açık**: oyuncunun yeniden atacağı etkiyi görmesi şart.
class ForgeBuffSummary extends StatefulWidget {
  final Item item;

  /// Bir etkinin sağında gösterilecek ek (Faz E4: yeniden atma düğmesi).
  final Widget? Function(int index, ItemEffect effect)? trailingFor;

  /// Bir etkinin altındaki ikinci satır (Faz E4: kademe ve aralık).
  final String? Function(int index, ItemEffect effect)? subtitleFor;

  const ForgeBuffSummary({
    super.key,
    required this.item,
    this.trailingFor,
    this.subtitleFor,
  });

  @override
  State<ForgeBuffSummary> createState() => _ForgeBuffSummaryState();
}

class _ForgeBuffSummaryState extends State<ForgeBuffSummary> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final effects = widget.item.buff.effects;
    final core = signatureCoreCount(widget.item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const ValueKey('forge-buffs-toggle'),
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 15, color: AppColors.xp),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.buffSummaryTitle(effects.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          for (var i = 0; i < effects.length; i++)
            _BuffRow(
              key: ValueKey('forge-buff-row-$i'),
              label: l10n.itemEffectLabel(effects[i]),
              signature: i < core,
              drawback: effects[i].value < 0,
              subtitle: widget.subtitleFor?.call(i, effects[i]),
              trailing: widget.trailingFor?.call(i, effects[i]),
            ),
      ],
    );
  }
}

class _BuffRow extends StatelessWidget {
  final String label;
  final bool signature;
  final bool drawback;
  final String? subtitle;
  final Widget? trailing;

  const _BuffRow({
    super.key,
    required this.label,
    required this.signature,
    required this.drawback,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = drawback ? AppColors.accent : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              drawback
                  ? Icons.remove_circle_outline
                  : signature
                  ? Icons.star_rounded
                  : Icons.add_circle_outline,
              size: 14,
              color: drawback
                  ? AppColors.accent
                  : signature
                  ? AppColors.streak
                  : AppColors.xp,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: color)),
                    if (signature)
                      _Tag(l10n.buffSignatureBadge, AppColors.streak),
                    if (drawback) _Tag(l10n.buffDrawbackBadge, AppColors.accent),
                  ],
                ),
                if (subtitle case final text?)
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing case final widget?) ...[
            const SizedBox(width: 6),
            widget,
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.6)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
    ),
  );
}

/// Bekleyen atışın kararı: eski ve yeni **yan yana** (Faz E4).
///
/// Para atışta ödendi; burada yalnızca hangi etkinin kalacağı seçiliyor.
/// Oyuncu onaylamadan yeni etki uygulanmaz.
class _ForgeDecisionPanel extends StatelessWidget {
  final Item item;
  final int level;
  final PendingForge pending;
  final ValueChanged<bool> onDecide;

  const _ForgeDecisionPanel({
    required this.item,
    required this.level,
    required this.pending,
    required this.onDecide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slotIndex = signatureCoreCount(item) + pending.slot;
    final old =
        slotIndex < item.buff.effects.length
            ? item.buff.effects[slotIndex]
            : null;
    // Yeni etki de eşyanın seviyesiyle büyümüş hâliyle gösterilir: eskisiyle
    // aynı ölçekte karşılaştırılsın.
    final fresh =
        scaleForLevel(
          ItemBuff([forgedToItemEffect(pending.effect)]),
          level,
        ).effects.first;

    Widget column(String title, ItemEffect? effect, int tier, Color color) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  effect == null ? '-' : l10n.itemEffectLabel(effect),
                  style: const TextStyle(fontSize: 12),
                ),
                if (effect != null)
                  Text(
                    l10n.forgeTierRange(
                      effect.stat,
                      tier,
                      scale: levelMultiplier(level),
                    ),
                    style: const TextStyle(fontSize: 10.5, color: Colors.white54),
                  ),
              ],
            ),
          ),
        );

    final oldTier =
        old == null
            ? 1
            : classifyForgeTier(
              old.stat,
              old.stat.isCombat ? old.value / levelMultiplier(level) : old.value,
            );

    return Container(
      key: const ValueKey('forge-decision-panel'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.streak.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.streak.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.forgeDecisionTitle,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                column(l10n.forgeDecisionOld, old, oldTier, Colors.white70),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Center(child: Icon(Icons.arrow_forward, size: 16)),
                ),
                column(
                  l10n.forgeDecisionNew,
                  fresh,
                  pending.effect.tier,
                  AppColors.xp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.forgeDecisionPaid,
            style: const TextStyle(fontSize: 10.5, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('forge-keep-old'),
                  onPressed: () => onDecide(false),
                  child: Text(
                    l10n.forgeKeepOld,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('forge-take-new'),
                  onPressed: () => onDecide(true),
                  child: Text(
                    l10n.forgeTakeNew,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Yeniden atma penceresi (Faz E4).
///
/// İki seçenek **ayrı** duruyor: üstte rastgele atış, altta çerçeveli ve
/// uyarı renginde "keşiften seç". Pahalı seçenek iki adımlı — önce bir keşif
/// seçilir, sonra bir onay penceresi maliyeti bir kez daha söyler; tek
/// dokunuşla 4 kat altın harcanamaz.
class _RerollSheet extends StatefulWidget {
  final Item item;
  final OwnedItem instance;
  final int slot;
  final int coins;
  final String characterClass;
  final List<String> discovered;
  final VoidCallback onRandom;
  final void Function(ItemStat stat, int tier) onPick;

  const _RerollSheet({
    required this.item,
    required this.instance,
    required this.slot,
    required this.coins,
    required this.characterClass,
    required this.discovered,
    required this.onRandom,
    required this.onPick,
  });

  @override
  State<_RerollSheet> createState() => _RerollSheetState();
}

class _RerollSheetState extends State<_RerollSheet> {
  (ItemStat, int)? _choice;

  Future<void> _confirmPick(int cost) async {
    final choice = _choice;
    if (choice == null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(l10n.forgePickConfirmTitle),
            content: Text(
              l10n.forgePickConfirmBody(
                l10n.forgeAffixName(choice.$1, choice.$2),
                cost,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                key: const ValueKey('forge-pick-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.purchaseConfirmAction),
              ),
            ],
          ),
    );
    if (confirmed == true && mounted) widget.onPick(choice.$1, choice.$2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = widget.item;
    final rarity = item.rarity;
    final level = widget.instance.level;
    final count = widget.instance.rerollCount;
    final randomCost = rerollCost(rarity, count);
    final picked = pickCost(rarity, count);
    final maxTier = maxForgeTier(rarity, level);
    final current = forgeSlotEffect(item, widget.slot);
    final options = <(ItemStat, int)>[
      for (final stat in ItemStat.values)
        for (var tier = 1; tier <= ForgeTiers.tierCount; tier++)
          if (widget.discovered.contains(forgeAffixKey(stat, tier)) &&
              canPickForSlot(
                item,
                widget.slot,
                stat,
                tier,
                rarity: rarity,
                level: level,
                characterClass: widget.characterClass,
              ))
            (stat, tier),
    ];
    final unlockLevel = forgeTopTierUnlockLevel(rarity);
    final topTier = rarityTier(rarity);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          key: const ValueKey('forge-reroll-sheet'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.forgeRerollTitle,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.forgeRerollCurrent,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              Text(
                l10n.itemEffectLabel(current),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.forgeRerollCount(count),
                key: const ValueKey('forge-reroll-count'),
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(height: 14),
              // ── Rastgele atış ──
              Text(
                l10n.forgeRerollRandomHint(l10n.forgeTierRoman(maxTier)),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              if (maxTier < topTier)
                Text(
                  l10n.forgeTierLockedHint(
                    l10n.forgeTierRoman(topTier),
                    unlockLevel,
                  ),
                  key: const ValueKey('forge-tier-locked'),
                  style: const TextStyle(fontSize: 11, color: AppColors.streak),
                ),
              Text(
                l10n.forgeCostGrowthHint,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('forge-roll-random'),
                  onPressed: widget.coins >= randomCost ? widget.onRandom : null,
                  icon: const Icon(Icons.casino),
                  label: Text(l10n.forgeRerollRandom(randomCost)),
                ),
              ),
              if (widget.coins < randomCost)
                Text(
                  l10n.forgeNotEnoughCoins(randomCost - widget.coins),
                  style: const TextStyle(fontSize: 11, color: AppColors.accent),
                ),
              const SizedBox(height: 16),
              // ── Keşiften seç (pahalı, ayrı ve belirgin) ──
              Container(
                key: const ValueKey('forge-pick-section'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.streak.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.streak),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.streak,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.forgePickTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.streak,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.forgePickHint,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    if (options.isEmpty)
                      Text(
                        l10n.forgePickNone,
                        key: const ValueKey('forge-pick-none'),
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      )
                    else ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final option in options)
                            ChoiceChip(
                              key: ValueKey(
                                'forge-pick-${forgeAffixKey(option.$1, option.$2)}',
                              ),
                              label: Text(
                                '${l10n.itemStatName(option.$1)} · '
                                '${l10n.forgeTierRoman(option.$2)}',
                              ),
                              selected: _choice == option,
                              onSelected:
                                  (on) =>
                                      setState(() => _choice = on ? option : null),
                            ),
                        ],
                      ),
                      if (_choice case final choice?)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l10n.forgeTierRange(choice.$1, choice.$2),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey('forge-roll-pick'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.streak,
                            side: const BorderSide(color: AppColors.streak),
                          ),
                          onPressed:
                              _choice != null && widget.coins >= picked
                                  ? () => _confirmPick(picked)
                                  : null,
                          icon: const Icon(Icons.auto_fix_high),
                          label: Text(l10n.forgePickAction(picked)),
                        ),
                      ),
                      if (_choice == null)
                        Text(
                          l10n.forgePickChooseFirst,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        )
                      else if (widget.coins < picked)
                        Text(
                          l10n.forgeNotEnoughCoins(picked - widget.coins),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
