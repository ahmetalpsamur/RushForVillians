import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/equipped_buffs.dart';
import '../../core/utils/item_comparison.dart';
import '../../core/utils/item_rules.dart';
import '../../models/item.dart';
import '../../models/item_effect.dart';
import '../../models/reward_rarity.dart';
import '../../models/user_profile.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/rarity_badge.dart';
import '../../widgets/section_card.dart';

/// Envanter ekranının okuduğu anlık durum.
///
/// Ekran itilen bir rotada durduğu için [RootShell]'in `setState`'i onu
/// tazelemiyor (GD11); bu yüzden veriyi tutmaz, her çizimde
/// [InventoryScreen.readState] ile **yeniden okur**. Böylece arka planda adım
/// gelip para değiştiğinde ya da seviye atlandığında envanter de güncellenir.
class InventoryState {
  final UserProfile profile;

  /// Sahip olunan itemler, oyuncunun sınıfına uyarlanmış hâlleriyle.
  final List<Item> ownedItems;

  /// Kuşanılan itemler.
  final List<Item> equippedItems;

  final EquippedBuffs buffs;

  const InventoryState({
    required this.profile,
    required this.ownedItems,
    required this.equippedItems,
    required this.buffs,
  });

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

  final void Function(Item item) onEquip;
  final void Function(ItemCategory category) onUnequip;
  final void Function(Item item) onSell;

  const InventoryScreen({
    super.key,
    required this.revision,
    required this.readState,
    required this.onEquip,
    required this.onUnequip,
    required this.onSell,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  /// `null` = bütün slotlar.
  ItemCategory? _categoryFilter;

  /// Yalnızca seviyesi yeten itemleri göster.
  bool _onlyUsable = false;

  List<Item> _visible(InventoryState state) {
    final items =
        state.ownedItems.where((item) {
          if (_categoryFilter != null && item.category != _categoryFilter) {
            return false;
          }
          if (_onlyUsable && !item.isUnlockedAt(state.profile.level)) {
            return false;
          }
          return true;
        }).toList();

    // Kuşanılanlar önce, sonra nadirlik, sonra seviye: en değerli en üstte.
    items.sort((a, b) {
      final aEquipped = state.profile.isEquipped(a.id) ? 0 : 1;
      final bEquipped = state.profile.isEquipped(b.id) ? 0 : 1;
      if (aEquipped != bEquipped) return aEquipped.compareTo(bEquipped);
      final byRarity = b.rarity.index.compareTo(a.rarity.index);
      if (byRarity != 0) return byRarity;
      final byLevel = b.requiredLevel.compareTo(a.requiredLevel);
      if (byLevel != 0) return byLevel;
      return a.name.compareTo(b.name);
    });
    return items;
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  Future<void> _openDetails(InventoryState state, Item item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (sheetContext) => _ItemSheet(
            item: item,
            state: state,
            onEquip: () {
              Navigator.of(sheetContext).pop();
              widget.onEquip(item);
            },
            onUnequip: () {
              Navigator.of(sheetContext).pop();
              widget.onUnequip(item.category);
            },
            onSell: () async {
              final confirmed = await _confirmSell(sheetContext, item);
              if (!confirmed) return;
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              widget.onSell(item);
            },
          ),
    );
  }

  /// Satış geri alınamaz: onay istenir ve geri gelecek para önceden söylenir.
  Future<bool> _confirmSell(BuildContext context, Item item) async {
    final value = sellValueFor(item.cost);
    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Item satılsın mı?'),
            content: Text(
              '${item.name} envanterinden çıkacak ve +$value coin '
              'kazanacaksın. Bu işlem geri alınamaz; itemi tekrar istersen '
              '${item.cost} coin ödemen gerekir.',
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
        final slots = state.slots;
        final categories =
            slots
                .where(
                  (category) =>
                      state.ownedItems.any((item) => item.category == category),
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
          body: CustomScrollView(
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
                    onTapEquipped: (item) => _openDetails(state, item),
                    onTapEmpty: (category) {
                      setState(() => _categoryFilter = category);
                      _notify(
                        '${category.label} slotu boş. Aşağıdan bir item seç.',
                      );
                    },
                  ),
                ),
              ),
              if (state.ownedItems.isEmpty)
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InventoryRow(
                            item: item,
                            state: state,
                            onTap: () => _openDetails(state, item),
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

  const CharacterPowerPanel({
    super.key,
    required this.buffs,
    required this.equippedCount,
    required this.slotCount,
  });

  @override
  Widget build(BuildContext context) {
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
            label: 'Günlük coin sınırı',
            base: '${GameConstants.maxDailyStepCoins}',
            bonus: _flat(buffs.dailyCoinCapBonus),
            total: '${buffs.dailyCoinCap}',
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
          if (buffs.combatEffects.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Savaş İstatistikleri',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            // Devre dışı olan şey sessiz kalmaz (Model Kuralları #4).
            const Text(
              'Bu değerler savaş sistemiyle birlikte etkinleşecek; şu an '
              'oyunda bir karşılıkları yok.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 6),
            for (final stat in buffs.touchedCombatStats)
              _StatRow(
                label: _capitalize(stat.label),
                base: '—',
                bonus: _combatBonus(buffs, stat),
                total: '—',
                dimmed: true,
              ),
          ],
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

class _StatHeader extends StatelessWidget {
  const _StatHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10.5,
      color: Colors.white38,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );
    return const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('', style: style)),
          Expanded(flex: 2, child: Text('TABAN', style: style)),
          Expanded(flex: 2, child: Text('EKİPMAN', style: style)),
          Expanded(flex: 2, child: Text('TOPLAM', style: style)),
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
  final Item item;
  final InventoryState state;
  final VoidCallback onTap;

  const _InventoryRow({
    required this.item,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !item.isUnlockedAt(state.profile.level);
    final equipped = state.profile.isEquipped(item.id);

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
                    Row(
                      children: [
                        RarityBadge(rarity: item.rarity),
                        const SizedBox(width: 8),
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
  final Item item;
  final InventoryState state;
  final VoidCallback onEquip;
  final VoidCallback onUnequip;
  final Future<void> Function() onSell;

  const _ItemSheet({
    required this.item,
    required this.state,
    required this.onEquip,
    required this.onUnequip,
    required this.onSell,
  });

  /// Kuşanmayı engelleyen sebep; engel yoksa `null`.
  ///
  /// Kilidin tek kaynağı [Item.isUnlockedAt]; burada ikinci bir seviye
  /// mantığı yok, yalnızca aynı kontrolün kullanıcıya çevirisi var.
  String? get _blockedReason {
    if (state.profile.isEquipped(item.id)) return null;
    if (!item.isUnlockedAt(state.profile.level)) {
      return '${item.requiredLevel}. seviye gerekiyor. Şu an '
          '${state.profile.level}. seviyedesin.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final equipped = state.profile.isEquipped(item.id);
    final current = state.equippedIn(item.category);
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
                        Row(
                          children: [
                            RarityBadge(rarity: item.rarity),
                            const SizedBox(width: 8),
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
                    label: Text('Sat +$sellValue'),
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
