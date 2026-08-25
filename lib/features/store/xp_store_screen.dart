import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/reward_rarity.dart';
import '../../models/item.dart';
import '../../models/xp_store_item.dart';
import '../../widgets/archetype_badge.dart';
import '../../widgets/rarity_badge.dart';
import '../../widgets/section_card.dart';

/// Mağaza: yükseltmeler ve ekipman.
///
/// Para birimi **coin** (bkz. triaj A4 — buton eskiden "N XP" yazıp `coins`
/// harcıyordu). Ekipman listesi [ItemCatalog]'tan gelir ve oyuncunun
/// **kendi sınıfının** kullanabildiği itemlerle sınırlıdır.
///
/// Kilitli kart sessiz kalmaz: kilit ikonu görünür, dokununca nedeni söylenir
/// (CLAUDE.md — Model Kuralları #4).
class XpStoreScreen extends StatefulWidget {
  final List<XpStoreItem> items;

  /// Oyuncunun sınıfının kuşanabileceği ekipman. Katalog henüz yüklenmediyse
  /// boş gelir; ekran bunu "yükleniyor" olarak değil, boş liste olarak
  /// gösterir — katalog okunamasa da mağazanın geri kalanı çalışır.
  final List<Item> equipment;

  final int coins;
  final int level;

  /// Sahip olunan **yükseltmelerin** kimlikleri (kozmetik, unvan, jeton).
  final List<String> ownedUpgradeIds;

  /// Sahip olunan **ekipman adetleri**: kimlik → adet.
  ///
  /// Adet, çünkü aynı eşyadan birden fazla alınabiliyor (birleştirme için
  /// gerekli, GD39). Kart "Sahipsin" yerine "3 adet" gösteriyor.
  final Map<String, int> ownedEquipmentCounts;

  /// Tüketilen yükseltmelerin eldeki stoğu. Kart altında gösterilir ki
  /// oyuncu stok dolduğunda boşuna satın almaya çalışmasın.
  final int streakFreezes;
  final int extraWheelSpins;
  final bool xpBoostActive;

  final void Function(XpStoreItem item) onPurchase;
  final void Function(Item item) onPurchaseEquipment;

  const XpStoreScreen({
    super.key,
    required this.items,
    required this.equipment,
    required this.coins,
    required this.level,
    required this.ownedUpgradeIds,
    required this.streakFreezes,
    this.ownedEquipmentCounts = const {},
    required this.onPurchase,
    required this.onPurchaseEquipment,
    this.extraWheelSpins = 0,
    this.xpBoostActive = false,
  });

  @override
  State<XpStoreScreen> createState() => _XpStoreScreenState();
}

class _XpStoreScreenState extends State<XpStoreScreen> {
  /// `null` = bütün kategoriler.
  ItemCategory? _categoryFilter;

  /// Kilitli itemler de listelenir; oyuncu neyin peşinde olduğunu görsün.
  bool _onlyAffordable = false;

  List<ItemCategory> get _availableCategories {
    final seen = <ItemCategory>{};
    for (final item in widget.equipment) {
      seen.add(item.category);
    }
    return ItemCategory.values.where(seen.contains).toList();
  }

  List<Item> get _visibleEquipment {
    return widget.equipment.where((item) {
      if (_categoryFilter != null && item.category != _categoryFilter) {
        return false;
      }
      // "Alabileceklerim" = **bugün satın alınabilecekler**: seviye kilidi
      // açık ve para yetiyor.
      //
      // Sahiplik artık elemiyor (GD14 güncellendi): aynı eşya birden fazla
      // kez alınabildiği için sahip olduğun bir eşya da "alabileceklerim"
      // listesine ait — birleştirme için ikinci adedi oradan alacaksın.
      if (_onlyAffordable &&
          !(item.isUnlockedAt(widget.level) && widget.coins >= item.cost)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Tüketilen yükseltmelerin kart altı durum satırı; kalıcı öğelerde `null`.
  ///
  /// Kimlikler [MockData.storeItems] ile aynı; tüketim tarafı da aynı
  /// kimliklere bakıyor ([RootShell] `_purchase`).
  String? _stockLabel(XpStoreItem item) => switch (item.id) {
    'upgrade_streak_freeze' => 'Elinde ${widget.streakFreezes} hak var',
    'wheel_extra_spin' => 'Elinde ${widget.extraWheelSpins} hak var',
    'boost_double_xp' =>
      widget.xpBoostActive ? 'Şu an etkin — gün sonuna kadar' : null,
    _ => null,
  };

  void _explain(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final equipment = _visibleEquipment;
    final categories = _availableCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mağaza'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.streak),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.coins}',
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
              child: SectionCard(
                title: 'Yükseltmeler',
                child: Column(
                  children: [
                    for (final item in widget.items)
                      _UpgradeRow(
                        item: item,
                        coins: widget.coins,
                        owned: widget.ownedUpgradeIds.contains(item.id),
                        stockLabel: _stockLabel(item),
                        onPurchase: () => widget.onPurchase(item),
                        onBlocked: _explain,
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ekipman',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Seviye ${widget.level}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.equipment.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Text(
                  'Sınıfın için ekipman bulunamadı.',
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
                      onSelected: () => setState(() => _categoryFilter = null),
                    ),
                    for (final category in categories)
                      _FilterChip(
                        label: category.label,
                        selected: _categoryFilter == category,
                        onSelected:
                            () => setState(() => _categoryFilter = category),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${equipment.length} ekipman',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Alabileceklerim'),
                      selected: _onlyAffordable,
                      onSelected:
                          (value) => setState(() => _onlyAffordable = value),
                    ),
                  ],
                ),
              ),
            ),
            if (equipment.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Text(
                    'Bu süzgeçle gösterilecek ekipman yok. '
                    'Yürümeye devam et; seviyen yükseldikçe yenileri açılır.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.builder(
                  // Satır yüksekliğini kart içeriği belirler. Böylece az bonuslu
                  // itemler, en uzun item için ayrılan boşluğu taşımaz.
                  itemCount: (equipment.length + 1) ~/ 2,
                  itemBuilder: (context, rowIndex) {
                    final firstIndex = rowIndex * 2;
                    final hasSecond = firstIndex + 1 < equipment.length;

                    Widget buildCard(Item item) => _EquipmentCard(
                      item: item,
                      coins: widget.coins,
                      level: widget.level,
                      ownedCount: widget.ownedEquipmentCounts[item.id] ?? 0,
                      onPurchase: () => widget.onPurchaseEquipment(item),
                      onBlocked: _explain,
                    );

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            rowIndex == (equipment.length - 1) ~/ 2 ? 0 : 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: buildCard(equipment[firstIndex])),
                          const SizedBox(width: 12),
                          Expanded(
                            child:
                                hasSecond
                                    ? buildCard(equipment[firstIndex + 1])
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
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

/// Yükseltme satırı (kozmetik, unvan, dondurma hakkı).
class _UpgradeRow extends StatelessWidget {
  final XpStoreItem item;
  final int coins;
  final bool owned;
  final String? stockLabel;
  final VoidCallback onPurchase;
  final ValueChanged<String> onBlocked;

  const _UpgradeRow({
    required this.item,
    required this.coins,
    required this.owned,
    required this.stockLabel,
    required this.onPurchase,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final alreadyOwned = owned && !item.repeatable;
    final affordable = coins >= item.cost;
    final enabled = !alreadyOwned && affordable;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alreadyOwned ? Icons.check_circle : item.icon,
            size: 28,
            color: alreadyOwned ? AppColors.xp : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (stockLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    stockLabel!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.xp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PriceButton(
            cost: item.cost,
            enabled: enabled,
            ownedLabel: alreadyOwned ? 'Sahipsin' : null,
            onPressed: onPurchase,
            onBlocked:
                () => onBlocked(
                  alreadyOwned
                      ? '${item.name} zaten sende.'
                      : '${item.name} için ${item.cost - coins} coin daha '
                          'gerekiyor.',
                ),
          ),
        ],
      ),
    );
  }
}

/// Ekipman kartı. Seviye kilidi (#10/#11) burada uygulanır.
class _EquipmentCard extends StatelessWidget {
  final Item item;
  final int coins;
  final int level;

  /// Envanterde bu eşyadan kaç adet var. Satın almayı **engellemez**
  /// (birleştirme için ikinci adet gerekiyor), yalnızca gösterilir.
  final int ownedCount;

  final VoidCallback onPurchase;
  final ValueChanged<String> onBlocked;

  const _EquipmentCard({
    required this.item,
    required this.coins,
    required this.level,
    required this.ownedCount,
    required this.onPurchase,
    required this.onBlocked,
  });

  /// Kart neden alınamıyor? `null` ise alınabilir.
  ///
  /// Sahiplik burada **yok**: aynı eşya birden fazla kez alınabilir.
  String? get _blockedReason {
    if (!item.isUnlockedAt(level)) {
      return '${item.name} için ${item.requiredLevel}. seviye gerekiyor. '
          'Şu an $level. seviyedesin.';
    }
    if (coins < item.cost) {
      return '${item.name} için ${item.cost - coins} coin daha gerekiyor.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locked = !item.isUnlockedAt(level);
    final reason = _blockedReason;
    final buffLabels = item.buff.labels;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: SectionCard(
        // SectionCard'ın kendi Column'u alt Column'a sınırsız yükseklik
        // veriyor; burada Expanded kullanılamaz. Görsel alanı sabit yükseklik.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 62,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    item.assetPath,
                    height: 54,
                    filterQuality: FilterQuality.none,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                          color: Colors.white24,
                        ),
                  ),
                  if (locked) ...[
                    const Icon(
                      Icons.lock,
                      size: 22,
                      color: AppColors.streak,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                    // Seviye etiketi kilit ikonunun yanına, görselin üstüne
                    // alındı. Nadirlik rozetiyle aynı satırdayken dar kartta
                    // sığmıyor ve kırpılıyordu — kilidin nedenini gösteren tek
                    // görsel bilgi o (Model Kuralları #4).
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text(
                        'Sv. ${item.requiredLevel}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.streak,
                          fontWeight: FontWeight.w800,
                          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            // Nadirlik "ne kadar güçlü", arketip "hangi yöne güçlü" sorusunu
            // cevaplar. Wrap kullanılıyor: dar kartta ikisi alt alta düşsün,
            // taşmasın.
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                RarityBadge(rarity: item.rarity),
                ArchetypeBadge(archetype: item.archetype),
                // Sahiplik satın almayı engellemiyor; adet **bilgi**.
                if (ownedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.xp.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.xp.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      '$ownedCount adet',
                      style: const TextStyle(
                        color: AppColors.xp,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            // İmzalı itemlerin kural cümlesi: item'ın karakterini bu taşıyor.
            if (item.lore case final lore?) ...[
              const SizedBox(height: 4),
              Text(
                lore,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.25,
                  fontStyle: FontStyle.italic,
                  color: item.rarity.color,
                ),
              ),
            ],
            // Her bonus kendi satırında: nadirlik yükseldikçe sayıları artıyor
            // (sıradan 1, epik/efsanevi 3-4) ve tek satıra sıkıştırmak okunmaz
            // hâle getiriyordu. Koşullu etkiler ("can %30 altındayken...")
            // tek satıra sığmadığı için iki satıra kadar sarılıyor.
            for (final line in buffLabels) ...[
              const SizedBox(height: 2),
              Text(
                line,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  color: AppColors.xp,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: _PriceButton(
                cost: item.cost,
                enabled: reason == null,
                // Adet bilgisi düğmeyi kapatmıyor; ikinci adet birleştirme
                // için gerekli olabilir.
                ownedLabel: null,
                onPressed: onPurchase,
                onBlocked: () => onBlocked(reason ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fiyat düğmesi. Devre dışı görünse de **dokunulabilir**: nedenini söyleyecek
/// birinin olması gerekiyor (Model Kuralları #4). Bu yüzden `onPressed` hiç
/// null olmuyor; engel varsa [onBlocked] çalışıyor.
class _PriceButton extends StatelessWidget {
  final int cost;
  final bool enabled;
  final String? ownedLabel;
  final VoidCallback onPressed;
  final VoidCallback onBlocked;

  const _PriceButton({
    required this.cost,
    required this.enabled,
    required this.ownedLabel,
    required this.onPressed,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final label = ownedLabel;
    return FilledButton.tonal(
      onPressed: enabled ? onPressed : onBlocked,
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        backgroundColor: enabled ? null : AppColors.surface,
        foregroundColor: enabled ? null : Colors.white38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child:
          label != null
              ? Text(label, style: const TextStyle(fontSize: 12))
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 15),
                  const SizedBox(width: 4),
                  Text('$cost', style: const TextStyle(fontSize: 13)),
                ],
              ),
    );
  }
}
