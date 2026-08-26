import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/base_combat_stats.dart';
import '../../core/utils/effective_stats.dart';
import '../../core/utils/equipped_buffs.dart';
import '../../core/utils/item_comparison.dart';
import '../../core/utils/item_leveling.dart';
import '../../core/utils/item_rules.dart';
import '../../models/item.dart';
import '../../models/owned_item.dart';
import '../../models/item_effect.dart';
import '../../models/reward_rarity.dart';
import '../../models/streak_stat_bonuses.dart';
import '../../models/user_profile.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/archetype_badge.dart';
import '../../widgets/rarity_badge.dart';
import '../../widgets/scroll_to_top_button.dart';
import '../../widgets/section_card.dart';
import '../tutorial/tutorial_guide.dart';

/// Envanter ekranının okuduğu anlık durum.
///
/// Ekran itilen bir rotada durduğu için [RootShell]'in `setState`'i onu
/// tazelemiyor (GD11); bu yüzden veriyi tutmaz, her çizimde
/// [InventoryScreen.readState] ile **yeniden okur**. Böylece arka planda adım
/// gelip para değiştiğinde ya da seviye atlandığında envanter de güncellenir.
/// Envanterdeki bir örnek ve onun **çözülmüş** item hâli.
///
/// Envanter artık kimlik listesi değil (GD39): aynı eşyadan birden fazla adet
/// olabiliyor ve her adedin kendi seviyesi, nadirliği ve kuşanma durumu var.
/// Ekranın her satırı bir örneğe karşılık geliyor, bir kimliğe değil.
class InventoryEntry {
  final OwnedItem instance;

  /// Sınıfa uyarlanmış, örneğin nadirliği ve seviyesi uygulanmış item.
  final Item item;

  const InventoryEntry(this.instance, this.item);

  int get instanceId => instance.instanceId;
  bool get equipped => instance.equipped;
  int get level => instance.level;
}

class InventoryState {
  final UserProfile profile;

  /// Sahip olunan **örnekler**, çözülmüş item'larıyla birlikte.
  final List<InventoryEntry> entries;

  /// Kuşanılan itemler.
  final List<Item> equippedItems;

  final EquippedBuffs buffs;

  const InventoryState({
    required this.profile,
    required this.entries,
    required this.equippedItems,
    required this.buffs,
  });

  /// Bu kimlikten kaç adet var (birleştirme için gereken bilgi).
  int countOf(String itemId) {
    var count = 0;
    for (final entry in entries) {
      if (entry.item.id == itemId) count++;
    }
    return count;
  }

  /// [category] slotunda kuşanılı item; boşsa `null`.
  Item? equippedIn(ItemCategory category) {
    for (final item in equippedItems) {
      if (item.category == category) return item;
    }
    return null;
  }

  /// Oyuncunun sınıfının kullanabildiği slotlar. Sıra [ItemCategory.values]
  /// sırasıdır; her açılışta aynı.
  List<ItemCategory> get slots {
    final characterClass = profile.avatar.characterClass;
    return ItemCategory.values
        .where((category) => category.characterClasses.contains(characterClass))
        .toList();
  }
}

/// Envanter: sahip olunan itemler, kuşanma, satma ve karakter paneli.
///
/// Kuşanma kuralı **slot başına tek item**; slot = item kategorisi
/// ([UserProfile.equippedItemIds]).
class InventoryScreen extends StatefulWidget {
  /// [RootShell]'in her kalıcı değişimde artırdığı sayaç; ekran bunu dinler.
  final ValueListenable<int> revision;

  final InventoryState Function() readState;

  /// Kuşanma, satma ve yükseltme **örnek kimliğiyle** çalışır: aynı eşyadan
  /// üç adet varsa "hangisi" sorusunun cevabı o.
  final void Function(int instanceId) onEquip;
  final void Function(ItemCategory category) onUnequip;
  final void Function(int instanceId) onSell;
  final void Function(int instanceId) onUpgrade;

  /// Aynı eşyanın aynı nadirlikteki örneklerini birleştirir (demirci).
  final void Function(String itemId, RewardRarity rarity) onMerge;
  final String? tutorialItemId;

  const InventoryScreen({
    super.key,
    required this.revision,
    required this.readState,
    required this.onEquip,
    required this.onUnequip,
    required this.onSell,
    required this.onUpgrade,
    required this.onMerge,
    this.tutorialItemId,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ScrollController _scrollController = ScrollController();

  /// `null` = bütün slotlar.
  ItemCategory? _categoryFilter;

  /// Yalnızca seviyesi yeten itemleri göster.
  bool _onlyUsable = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<InventoryEntry> _visible(InventoryState state) {
    final entries =
        state.entries.where((entry) {
          if (widget.tutorialItemId != null &&
              entry.item.id != widget.tutorialItemId) {
            return false;
          }
          if (_categoryFilter != null &&
              entry.item.category != _categoryFilter) {
            return false;
          }
          if (_onlyUsable && !entry.item.isUnlockedAt(state.profile.level)) {
            return false;
          }
          return true;
        }).toList();

    // Kuşanılanlar önce, sonra nadirlik, sonra eşya seviyesi: en değerli
    // en üstte. Son ölçüt örnek kimliği — aynı eşyanın iki adedi arasında
    // sıra her çizimde aynı kalsın.
    entries.sort((a, b) {
      final aEquipped = a.equipped ? 0 : 1;
      final bEquipped = b.equipped ? 0 : 1;
      if (aEquipped != bEquipped) return aEquipped.compareTo(bEquipped);
      final byRarity = b.item.rarity.index.compareTo(a.item.rarity.index);
      if (byRarity != 0) return byRarity;
      final byItemLevel = b.level.compareTo(a.level);
      if (byItemLevel != 0) return byItemLevel;
      final byLock = b.item.requiredLevel.compareTo(a.item.requiredLevel);
      if (byLock != 0) return byLock;
      final byName = a.item.name.compareTo(b.item.name);
      if (byName != 0) return byName;
      return a.instanceId.compareTo(b.instanceId);
    });
    return entries;
  }

  /// Slot tahtasından kuşanılı bir item'a dokunulduğunda, o item'a karşılık
  /// gelen **örneği** bulur. Aynı eşyadan birkaç adet varsa kuşanılı olan
  /// tektir; onu açıyoruz.
  void _openEquippedDetails(Item item) {
    final state = widget.readState();
    for (final entry in state.entries) {
      if (entry.equipped && entry.item.category == item.category) {
        _openDetails(state, entry);
        return;
      }
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  Future<void> _openDetails(InventoryState state, InventoryEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (sheetContext) => _ItemSheet(
            entry: entry,
            state: state,
            onEquip: () {
              Navigator.of(sheetContext).pop();
              widget.onEquip(entry.instanceId);
            },
            onUnequip: () {
              Navigator.of(sheetContext).pop();
              widget.onUnequip(entry.item.category);
            },
            onUpgrade: () {
              Navigator.of(sheetContext).pop();
              widget.onUpgrade(entry.instanceId);
            },
            onSell: () async {
              final confirmed = await _confirmSell(sheetContext, entry);
              if (!confirmed) return;
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              widget.onSell(entry.instanceId);
            },
          ),
    );
  }

  /// Satış geri alınamaz: onay istenir ve geri gelecek para önceden söylenir.
  Future<bool> _confirmSell(BuildContext context, InventoryEntry entry) async {
    final item = entry.item;
    final value = sellValueFor(item.cost);
    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Item satılsın mı?'),
            content: Text(
              '${item.name}${entry.level > 1 ? ' (Sv. ${entry.level})' : ''} '
              'envanterinden çıkacak ve +$value coin kazanacaksın. '
              'Bu işlem geri alınamaz; itemi tekrar istersen ${item.cost} '
              'coin ödemen gerekir ve yükseltmelerini baştan yapman gerekir.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('Sat (+$value)'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.revision,
      builder: (context, _, __) {
        final state = widget.readState();
        final visible = _visible(state);
        if (widget.tutorialItemId != null) {
          return _TutorialInventoryScaffold(
            state: state,
            entry: visible.isEmpty ? null : visible.first,
            onEquip: widget.onEquip,
          );
        }
        final slots = state.slots;
        final categories =
            slots
                .where(
                  (category) => state.entries.any(
                    (entry) => entry.item.category == category,
                  ),
                )
                .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Envanter'),
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
          floatingActionButton: ScrollToTopButton(
            controller: _scrollController,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: CustomScrollView(
            key: const ValueKey('inventory-scroll-view'),
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _EquipmentShowcase(state: state),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _SlotBoard(
                    state: state,
                    slots: slots,
                    onTapEquipped: _openEquippedDetails,
                    onTapEmpty: (category) {
                      setState(() => _categoryFilter = category);
                      _notify(
                        '${category.label} slotu boş. Aşağıdan bir item seç.',
                      );
                    },
                  ),
                ),
              ),
              if (state.entries.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Text(
                      'Henüz item\'in yok. Mağazadan ekipman alabilir ya da '
                      'günlük çarkı çevirebilirsin.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _FilterChip(
                          label: 'Tümü',
                          selected: _categoryFilter == null,
                          onSelected:
                              () => setState(() => _categoryFilter = null),
                        ),
                        for (final category in categories)
                          _FilterChip(
                            label: category.label,
                            selected: _categoryFilter == category,
                            onSelected:
                                () =>
                                    setState(() => _categoryFilter = category),
                          ),
                        _FilterChip(
                          label: 'Kuşanabildiklerim',
                          selected: _onlyUsable,
                          onSelected:
                              () => setState(() => _onlyUsable = !_onlyUsable),
                        ),
                      ],
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: Text(
                        'Bu süzgeçle gösterilecek item yok.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    sliver: SliverList.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final entry = visible[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InventoryRow(
                            key: ValueKey(entry.instanceId),
                            entry: entry,
                            playerLevel: state.profile.level,
                            onTap: () => _openDetails(state, entry),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Eğitim sırasında yalnızca az önce alınan silahı ve zorunlu Kuşan eylemini
/// gösterir. İçerik tek ekrana sığar; sayfa veya kart kaydırılamaz.
class _TutorialInventoryScaffold extends StatelessWidget {
  final InventoryState state;
  final InventoryEntry? entry;
  final void Function(int instanceId) onEquip;

  const _TutorialInventoryScaffold({
    required this.state,
    required this.entry,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Envanter'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.streak),
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child:
            entry == null
                ? const Center(child: Text('Eğitim silahı bulunamadı.'))
                : _TutorialEquipCard(
                  entry: entry!,
                  onEquip: () => onEquip(entry!.instanceId),
                ),
      ),
    );
  }
}

class _TutorialEquipCard extends StatelessWidget {
  final InventoryEntry entry;
  final VoidCallback onEquip;

  const _TutorialEquipCard({required this.entry, required this.onEquip});

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    return Align(
      alignment: Alignment.topCenter,
      child: SectionCard(
        title: 'İlk silahın',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 112,
              child: Image.asset(
                item.assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder:
                    (_, _, _) => const Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.white24,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 6,
              children: [
                RarityBadge(rarity: item.rarity),
                ArchetypeBadge(archetype: item.archetype),
                _Tag(text: item.category.label, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.buff.labels.join(' · '),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.xp, height: 1.3),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: TutorialGuideTargetKeys.inventoryItem,
              onPressed: entry.equipped ? null : onEquip,
              icon: Icon(entry.equipped ? Icons.check : Icons.shield_outlined),
              label: Text(entry.equipped ? 'Kuşanıldı' : 'Kuşan'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karakteri saldırısız biçimde merkezde tutar; kuşanılmış itemleri isim
/// göstermeden, sağladıkları etkilerle birlikte çevresinde sergiler.
class _EquipmentShowcase extends StatefulWidget {
  final InventoryState state;

  const _EquipmentShowcase({required this.state});

  @override
  State<_EquipmentShowcase> createState() => _EquipmentShowcaseState();
}

class _EquipmentShowcaseState extends State<_EquipmentShowcase> {
  Timer? _waveTimer;
  bool _waveUp = false;

  @override
  void initState() {
    super.initState();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 1650), (_) {
      if (mounted) setState(() => _waveUp = !_waveUp);
    });
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equipped = widget.state.equippedItems;

    return SectionCard(
      child: SizedBox(
        height: 350,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const itemWidth = 104.0;
            const itemHeight = 112.0;
            const centerY = 175.0;
            final centerX = constraints.maxWidth / 2;
            final radiusX = (centerX - itemWidth / 2).clamp(104.0, 146.0);
            const radiusY = 118.0;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Center(
                    child: AvatarView(
                      avatar: widget.state.profile.avatar,
                      size: 164,
                      showBackground: false,
                    ),
                  ),
                ),
                if (equipped.isEmpty)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Text(
                      'Henüz kuşanılmış eşya yok',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                for (var index = 0; index < equipped.length; index++)
                  _positionedItem(
                    item: equipped[index],
                    index: index,
                    count: equipped.length,
                    centerX: centerX,
                    centerY: centerY,
                    radiusX: radiusX,
                    radiusY: radiusY,
                    itemWidth: itemWidth,
                    itemHeight: itemHeight,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _positionedItem({
    required Item item,
    required int index,
    required int count,
    required double centerX,
    required double centerY,
    required double radiusX,
    required double radiusY,
    required double itemWidth,
    required double itemHeight,
  }) {
    final angle = _angleFor(index, count);
    final left = centerX + math.cos(angle) * radiusX - itemWidth / 2;
    final top = centerY + math.sin(angle) * radiusY - itemHeight / 2;
    final movesUp = index.isEven ? _waveUp : !_waveUp;

    return Positioned(
      left: left,
      top: top,
      width: itemWidth,
      height: itemHeight,
      child: AnimatedSlide(
        offset: Offset(0, movesUp ? -0.065 : 0.065),
        duration: Duration(milliseconds: 1320 + index * 85),
        curve: Curves.easeInOutSine,
        child: _FloatingEquipment(item: item),
      ),
    );
  }

  static double _angleFor(int index, int count) {
    if (count == 1) return -math.pi / 2;
    if (count == 2) return index == 0 ? math.pi : 0;
    if (count == 3) {
      return const [-math.pi / 2, 5 * math.pi / 6, math.pi / 6][index];
    }
    return -math.pi / 2 + (2 * math.pi * index / count);
  }
}

class _FloatingEquipment extends StatelessWidget {
  final Item item;

  const _FloatingEquipment({required this.item});

  @override
  Widget build(BuildContext context) {
    final effect = item.buff.labels.join('\n');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 43,
          child: Center(
            child: Text(
              key: ValueKey('equipped-effect-${item.id}'),
              effect.isEmpty ? 'Etki yok' : effect,
              maxLines: 3,
              overflow: TextOverflow.fade,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: item.rarity.color,
                fontSize: 10.5,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.15,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 5),
                  Shadow(color: Colors.black87, blurRadius: 2),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Expanded(
          child: Image.asset(
            item.assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder:
                (_, _, _) => const Icon(
                  Icons.inventory_2_outlined,
                  size: 42,
                  color: Colors.white24,
                ),
          ),
        ),
      ],
    );
  }
}

/// Taban değer, ekipman katkısı ve toplamı ayrı ayrı gösteren güç tablosu.
/// Profil ekranında istatistiklerin altında kullanılır.
class CharacterPowerPanel extends StatelessWidget {
  final EquippedBuffs buffs;
  final int equippedCount;
  final int slotCount;

  /// Serinin biriktirdiği savaş stat bonusları (Bölüm 5C).
  final StreakStatBonuses streakBonuses;

  /// Bugünkü seri; bonus bölümünün başlığında gösterilir.
  final int streakDays;

  /// Oyuncu seviyesi. Savaş statlarının tabanı buradan geliyor.
  final int level;

  const CharacterPowerPanel({
    super.key,
    required this.buffs,
    required this.equippedCount,
    required this.slotCount,
    this.streakBonuses = StreakStatBonuses.empty,
    this.streakDays = 0,
    this.level = 1,
  });

  /// Panelde gösterilecek savaş statları.
  ///
  /// Taban her zaman var (seviyeden geliyor), o yüzden liste ekipmana bağlı
  /// değil: dokuz statın hepsi gösteriliyor.
  static List<ItemStat> get combatStatOrder => [
    for (final stat in ItemStat.values)
      if (stat.isCombat) stat,
  ];

  @override
  Widget build(BuildContext context) {
    // Tek toplama noktası: panel de savaşın okuduğu hesabı okuyor, ikinci bir
    // formül yazmıyor. Koşullu etkiler bilerek kapalı — panel "pasif hâlim"
    // sorusunu cevaplıyor, onlar ayrı listede duruyor.
    final baseStats = baseCombatStats(level);
    final totalStats = effectiveCombatStats(
      level: level,
      buffs: buffs,
      streak: streakBonuses,
    );
    return SectionCard(
      title: 'Karakter Gücü',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$equippedCount / $slotCount slot dolu',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          const _StatHeader(),
          _StatRow(
            label: 'Adım parası',
            base: '×1,00',
            bonus: _rate(buffs.stepCoinBonus),
            total: '×${_multiplier(buffs.stepCoinMultiplier)}',
          ),
          _StatRow(
            label: 'Adım XP',
            base: '×1,00',
            bonus: _rate(buffs.stepXpBonus),
            total: '×${_multiplier(buffs.stepXpMultiplier)}',
          ),
          _StatRow(
            label: 'Çark XP',
            base: '×1,00',
            bonus: _rate(buffs.wheelXpBonus),
            total: '×${_multiplier(buffs.wheelXpMultiplier)}',
          ),
          _StatRow(
            label: 'Düşman XP',
            base: '×1,00',
            bonus: _rate(buffs.enemyXpBonus),
            total: '×${_multiplier(buffs.enemyXpMultiplier)}',
          ),
          _StatRow(
            label: 'Dondurma stoğu',
            base: '${GameConstants.maxStreakFreezes}',
            bonus: _flat(buffs.streakFreezeCapBonus),
            total: '${buffs.streakFreezeCap}',
          ),
          _StatRow(
            label: 'Çark hakkı stoğu',
            base: '${GameConstants.maxExtraWheelSpins}',
            bonus: _flat(buffs.wheelSpinCapBonus),
            total: '${buffs.wheelSpinCap}',
          ),
          _StatRow(
            label: 'Seri eşiği',
            base: '${GameConstants.streakStepThreshold}',
            bonus:
                buffs.streakStepRelief == 0
                    ? '—'
                    : '-${buffs.streakStepRelief}',
            total: '${buffs.streakStepThreshold}',
            bonusIsGain: buffs.streakStepRelief > 0,
          ),
          _StreakBonusSection(bonuses: streakBonuses, streakDays: streakDays),
          const SizedBox(height: 14),
          const Text(
            'Savaş İstatistikleri',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          const Text(
            'Maceradaki savaşta kullanılır: taban seviyeden, bonus ekipman '
            've seriden gelir.',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 6),
          const _StatHeader(columns: ['TABAN', 'BONUS', 'TOPLAM']),
          for (final stat in combatStatOrder)
            _StatRow(
              label: _capitalize(stat.label),
              base: _combatValue(stat, baseStats.statFor(stat)),
              bonus: _combatBonus(buffs, stat),
              total: _combatValue(stat, totalStats.statFor(stat)),
            ),
          if (buffs.conditionalEffects.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Koşullu Etkiler',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            for (final effect in buffs.conditionalEffects)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${effect.label}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.xp),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  /// Savaş statının okunur hâli: oran statları yüzde, diğerleri tam sayı.
  static String _combatValue(ItemStat stat, double value) {
    const rateStats = {
      ItemStat.critChance,
      ItemStat.critDamage,
      ItemStat.lifeSteal,
      ItemStat.dodge,
    };
    if (rateStats.contains(stat)) return '%${(value * 100).round()}';
    return value.round().toString();
  }

  static String _rate(double value) =>
      value == 0 ? '—' : '+%${ItemEffect.formatPercent(value)}';

  static String _flat(int value) => value == 0 ? '—' : '+$value';

  static String _multiplier(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  static String _combatBonus(EquippedBuffs buffs, ItemStat stat) {
    final flat = buffs.flatBonusFor(stat);
    final rate = buffs.rateBonusFor(stat);
    final parts = <String>[
      if (flat != 0) '${flat > 0 ? '+' : '-'}${flat.abs().round()}',
      if (rate != 0)
        '${rate > 0 ? '+' : '-'}%${ItemEffect.formatPercent(rate.abs())}',
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}

/// Karakter panelindeki "Seri Bonusu" bölümü.
///
/// Hangi stata ne kadar biriktiği **stat stat** gösterilir; tek bir toplam
/// sayı, oyuncunun serisinin ona nasıl bir savaş profili verdiğini
/// anlatmıyor.
///
/// Tavan kalktı (Bölüm B). Yerine gösterilmesi gereken şey **gün başına
/// güncel kazanç**: oyuncu 200. günde kazancının neden küçüldüğünü ve 501.
/// günde neden büyüdüğünü panelde görmeli (Model Kuralları #4).
class _StreakBonusSection extends StatelessWidget {
  final StreakStatBonuses bonuses;
  final int streakDays;

  const _StreakBonusSection({required this.bonuses, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    if (bonuses.isEmpty) return const SizedBox.shrink();
    final total = StreakStatBonuses.formatRate(bonuses.totalBonus);
    // Bir sonraki günün kazancı: oyuncunun bugün baktığında görmesi gereken
    // sayı "yarın ne kazanacağım".
    final nextGain =
        StreakStatBonuses.tenthsForDay(streakDays + 1) / 1000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 15,
              color: AppColors.streak,
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Seri Bonusu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Text(
              'toplam +%$total',
              style: const TextStyle(fontSize: 11.5, color: AppColors.streak),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$streakDays günlük serin savaş statlarını büyüttü. '
          'Seri kırılırsa tamamı gider.',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          'Şu an: gün başına +%${StreakStatBonuses.formatRate(nextGain)}. '
          'Kazanç her ${GameConstants.streakBonusTierLength} günde bir azalır, '
          '${GameConstants.streakBonusTierLength * GameConstants.streakBonusTierTenths.length}. '
          'günden sonra başa döner.',
          key: const ValueKey('streak-bonus-current-rate'),
          style: const TextStyle(color: AppColors.streak, fontSize: 11),
        ),
        const SizedBox(height: 6),
        // Bölümün kendi sütun başlıkları: üstteki tabloda "EKİPMAN" yazan
        // sütun burada seri gününü taşıyor, aynı başlığı kullanmak yanıltıcı
        // olurdu.
        const _StatHeader(columns: ['BONUS', 'PAY', 'DURUM']),
        for (final stat in StreakStatBonuses.pool)
          if (bonuses.tenthsFor(stat) > 0)
            _StatRow(
              label: CharacterPowerPanel._capitalize(stat.label),
              base: '+%${StreakStatBonuses.formatRate(bonuses.bonusFor(stat))}',
              bonus:
                  bonuses.totalTenths == 0
                      ? '—'
                      : '%${(bonuses.tenthsFor(stat) * 100 / bonuses.totalTenths).round()}',
              total: '—',
              dimmed: true,
            ),
      ],
    );
  }
}

class _StatHeader extends StatelessWidget {
  /// Üç sayı sütununun başlığı. Seri bonusu bölümü aynı hizayı kullanır ama
  /// sütunların anlamı farklıdır, o yüzden başlıklar dışarıdan verilebilir.
  final List<String> columns;

  const _StatHeader({this.columns = const ['TABAN', 'EKİPMAN', 'TOPLAM']});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10.5,
      color: Colors.white38,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Expanded(flex: 4, child: Text('', style: style)),
          for (final column in columns)
            Expanded(
              flex: 2,
              child: Text(
                column,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String base;
  final String bonus;
  final String total;
  final bool bonusIsGain;
  final bool dimmed;

  const _StatRow({
    required this.label,
    required this.base,
    required this.bonus,
    required this.total,
    this.bonusIsGain = true,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasBonus = bonus != '—';
    final valueStyle = TextStyle(
      fontSize: 12,
      color: dimmed ? Colors.white38 : Colors.white70,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: dimmed ? Colors.white54 : Colors.white,
              ),
            ),
          ),
          Expanded(flex: 2, child: Text(base, style: valueStyle)),
          Expanded(
            flex: 2,
            child: Text(
              bonus,
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasBonus ? FontWeight.w800 : FontWeight.normal,
                color:
                    !hasBonus
                        ? Colors.white38
                        : bonusIsGain
                        ? AppColors.xp
                        : AppColors.accent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              total,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: dimmed ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slot tahtası: her kategori için kuşanılı item ya da boş kutu.
class _SlotBoard extends StatelessWidget {
  final InventoryState state;
  final List<ItemCategory> slots;
  final void Function(Item item) onTapEquipped;
  final void Function(ItemCategory category) onTapEmpty;

  const _SlotBoard({
    required this.state,
    required this.slots,
    required this.onTapEquipped,
    required this.onTapEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Kuşanılanlar',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final category in slots)
            _SlotTile(
              category: category,
              item: state.equippedIn(category),
              onTap: () {
                final item = state.equippedIn(category);
                if (item == null) {
                  onTapEmpty(category);
                } else {
                  onTapEquipped(item);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final ItemCategory category;
  final Item? item;
  final VoidCallback onTap;

  const _SlotTile({
    required this.category,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final equipped = item;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                equipped == null
                    ? Colors.white12
                    : equipped.rarity.color.withValues(alpha: 0.8),
            width: equipped == null ? 1 : 1.6,
          ),
          color: Colors.black.withValues(alpha: 0.18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child:
                  equipped == null
                      ? const Icon(Icons.add, color: Colors.white24, size: 26)
                      : Image.asset(
                        equipped.assetPath,
                        height: 38,
                        filterQuality: FilterQuality.none,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 28,
                              color: Colors.white24,
                            ),
                      ),
            ),
            const SizedBox(height: 4),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, color: Colors.white38),
            ),
            Text(
              equipped?.name ?? 'Boş',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: equipped == null ? Colors.white38 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Envanter listesindeki tek satır.
class _InventoryRow extends StatelessWidget {
  final InventoryEntry entry;
  final int playerLevel;
  final VoidCallback onTap;

  const _InventoryRow({
    super.key,
    required this.entry,
    required this.playerLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final locked = !item.isUnlockedAt(playerLevel);
    final equipped = entry.equipped;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      item.assetPath,
                      height: 46,
                      filterQuality: FilterQuality.none,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.inventory_2_outlined,
                            size: 32,
                            color: Colors.white24,
                          ),
                    ),
                    if (locked)
                      const Icon(
                        Icons.lock,
                        size: 20,
                        color: AppColors.streak,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (equipped)
                          const _Tag(text: 'Kuşanılı', color: AppColors.xp)
                        else if (locked)
                          _Tag(
                            text: 'Sv. ${item.requiredLevel}',
                            color: AppColors.streak,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RarityBadge(rarity: item.rarity),
                        ArchetypeBadge(archetype: item.archetype),
                        // Eşya seviyesi: yükseltilmiş bir eşya listede
                        // hemen ayırt edilebilmeli.
                        _Tag(
                          text: 'Sv. ${entry.level}',
                          color: AppColors.primary,
                        ),
                        Text(
                          item.category.label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.buff.labels.take(2).join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.xp,
                        height: 1.2,
                      ),
                    ),
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

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Item ayrıntısı: etkiler, kuşanılıyla karşılaştırma ve aksiyonlar.
class _ItemSheet extends StatelessWidget {
  final InventoryEntry entry;
  final InventoryState state;
  final VoidCallback onEquip;
  final VoidCallback onUnequip;
  final VoidCallback onUpgrade;
  final Future<void> Function() onSell;

  const _ItemSheet({
    required this.entry,
    required this.state,
    required this.onEquip,
    required this.onUnequip,
    required this.onUpgrade,
    required this.onSell,
  });

  Item get item => entry.item;

  /// Kuşanmayı engelleyen sebep; engel yoksa `null`.
  ///
  /// Kilidin tek kaynağı [Item.isUnlockedAt]; burada ikinci bir seviye
  /// mantığı yok, yalnızca aynı kontrolün kullanıcıya çevirisi var.
  String? get _blockedReason {
    if (entry.equipped) return null;
    if (!item.isUnlockedAt(state.profile.level)) {
      return '${item.requiredLevel}. seviye gerekiyor. Şu an '
          '${state.profile.level}. seviyedesin.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final equipped = entry.equipped;
    final current = state.equippedIn(item.category);
    final quote = quoteUpgrade(
      resolved: item,
      instance: entry.instance,
      playerLevel: state.profile.level,
      coins: state.profile.coins,
    );
    final comparison =
        equipped
            ? ItemComparison.none
            : compareItems(candidate: item, current: current);
    final reason = _blockedReason;
    final sellValue = sellValueFor(item.cost);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    item.assetPath,
                    height: 56,
                    filterQuality: FilterQuality.none,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                          color: Colors.white24,
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            RarityBadge(rarity: item.rarity),
                            ArchetypeBadge(archetype: item.archetype),
                            Text(
                              '${item.category.label} · Sv. '
                              '${item.requiredLevel}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Arketip bir sıralama değil, bir yön: aynı
                        // nadirlikteki iki eşya arasındaki tercihi bu cümle
                        // anlaşılır kılıyor.
                        Text(
                          '${item.archetype.label} — '
                          '${item.archetype.description}',
                          style: TextStyle(
                            fontSize: 11,
                            color: ArchetypeBadge.colorFor(item.archetype),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.lore case final lore?) ...[
                const SizedBox(height: 12),
                Text(
                  lore,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                    color: item.rarity.color,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Etkiler',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              for (final effect in item.buff.effects)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        effect.isDormant
                            ? Icons.shield_moon_outlined
                            : Icons.bolt,
                        size: 14,
                        color: effect.isDormant ? Colors.white38 : AppColors.xp,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          effect.label,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color:
                                effect.isDormant
                                    ? Colors.white54
                                    : AppColors.xp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (item.buff.combatEffects.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Soluk satırlar savaş istatistikleri; savaş sistemiyle '
                    'birlikte etkinleşecek.',
                    style: TextStyle(fontSize: 10.5, color: Colors.white38),
                  ),
                ),
              if (!equipped) ...[
                const SizedBox(height: 14),
                Text(
                  current == null
                      ? '${item.category.label} slotu boş — kuşanınca:'
                      : '${current.name} yerine kuşanınca:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                if (comparison.isEmpty)
                  const Text(
                    'Sayısal olarak fark yok.',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  )
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final delta in comparison.ordered)
                        Text(
                          delta.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color:
                                delta.isGain ? AppColors.xp : AppColors.accent,
                          ),
                        ),
                    ],
                  ),
                  for (final line in comparison.gainedConditions)
                    Text(
                      '+ $line',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.xp,
                      ),
                    ),
                  for (final line in comparison.lostConditions)
                    Text(
                      '- $line',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ],
              if (reason != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.lock, size: 15, color: AppColors.streak),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.streak,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _UpgradePanel(
                entry: entry,
                quote: quote,
                playerLevel: state.profile.level,
                coins: state.profile.coins,
                onUpgrade: onUpgrade,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child:
                        equipped
                            ? OutlinedButton.icon(
                              onPressed: onUnequip,
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('Çıkar'),
                            )
                            : FilledButton.icon(
                              onPressed: reason == null ? onEquip : null,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Kuşan'),
                            ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: onSell,
                    icon: const Icon(Icons.sell_outlined),
                    label: Text(
                      'Sat +$sellValue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Demirci paneli: mevcut seviye, sonraki seviyedeki statlar, maliyet.
///
/// Engel **sessiz kalmaz** (Model Kuralları #4): hangi tavanın bağladığı
/// ("nadirlik sınırı" mı, "kendi seviyen" mi) ayrı ayrı söylenir.
class _UpgradePanel extends StatelessWidget {
  final InventoryEntry entry;
  final UpgradeQuote quote;
  final int playerLevel;
  final int coins;
  final VoidCallback onUpgrade;

  const _UpgradePanel({
    required this.entry,
    required this.quote,
    required this.playerLevel,
    required this.coins,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final rarity = entry.instance.effectiveRarity(item.rarity);
    final reason = quote.reason(rarity, playerLevel);
    final preview =
        quote.canUpgrade
            ? compareLevels(item, entry.level, quote.nextLevel)
            : const <String>[];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hardware, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Demirci — Sv. ${entry.level} / ${quote.rarityCap}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Yükseltmek yalnızca savaş istatistiklerini büyütür; '
            'ekonomi bonusları sabit kalır.',
            style: const TextStyle(fontSize: 10.5, color: Colors.white38),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Sv. ${quote.nextLevel}: ${preview.join(' · ')}',
              style: const TextStyle(fontSize: 12, color: AppColors.xp),
            ),
          ],
          if (reason != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock, size: 14, color: AppColors.streak),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 11.5,
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
            child: FilledButton.icon(
              // Devre dışı görünse de **dokunulabilir** olmalıydı; bunun
              // yerine neden zaten yukarıda yazılı. Düğme yalnızca gerçekten
              // yükseltilebiliyorken etkin.
              onPressed: quote.canUpgrade ? onUpgrade : null,
              icon: const Icon(Icons.upgrade),
              // `FilledButton.icon` etiketi zaten kendi `Flexible`'ına
              // sarıyor; ikinci bir `Flexible` "competing ParentDataWidget"
              // hatası veriyor. Kırpma bu yüzden doğrudan `Text` üzerinde.
              label: Text(
                quote.canUpgrade
                    ? 'Sv. ${quote.nextLevel}\'e yükselt — ${quote.cost} coin'
                    : 'Yükseltilemiyor',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
