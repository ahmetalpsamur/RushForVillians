import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/item_leveling.dart';
import '../../core/utils/item_merging.dart';
import '../../models/reward_rarity.dart';
import '../../models/game_title.dart';
import '../../models/item.dart';
import '../../models/xp_store_item.dart';
import '../../widgets/archetype_badge.dart';
import '../../widgets/rarity_badge.dart';
import '../../widgets/scroll_to_top_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/title_badge.dart';
import '../tutorial/tutorial_guide.dart';

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

  /// Mağazada satılan ünvanlar (Bölüm C.4), ucuzdan pahalıya.
  final List<GameTitle> titles;

  /// Sahip olunan ünvan kimlikleri: satın alınmışı ikinci kez satmamak için.
  final List<String> ownedTitleIds;

  /// Ünvan satın alma. `null` ise ünvan bölümü hiç çizilmez — testler ve
  /// eski çağrı noktaları ünvansız bir mağaza kurabilsin diye.
  final void Function(GameTitle title)? onPurchaseTitle;
  final String? tutorialItemId;

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
    this.onPurchaseTitle,
    this.titles = const [],
    this.ownedTitleIds = const [],
    this.extraWheelSpins = 0,
    this.xpBoostActive = false,
    this.tutorialItemId,
  });

  @override
  State<XpStoreScreen> createState() => _XpStoreScreenState();
}

class _XpStoreScreenState extends State<XpStoreScreen> {
  late final PageController _pageController;
  final ScrollController _titleScrollController = ScrollController();
  final ScrollController _adventureScrollController = ScrollController();
  late int _pageIndex;

  /// `null` = bütün kategoriler.
  ItemCategory? _categoryFilter;

  /// Kilitli itemler de listelenir; oyuncu neyin peşinde olduğunu görsün.
  bool _onlyAffordable = false;

  bool get _hasTitleShop =>
      widget.titles.isNotEmpty && widget.onPurchaseTitle != null;

  @override
  void initState() {
    super.initState();
    // The title shop is the left/default page in the real game. Lightweight
    // callers that do not provide a title catalogue still land on the useful
    // adventure shop instead of an empty page.
    _pageIndex = widget.tutorialItemId != null || !_hasTitleShop ? 1 : 0;
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void didUpdateWidget(covariant XpStoreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tutorialItemId != null && oldWidget.tutorialItemId == null) {
      _pageIndex = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(1);
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleScrollController.dispose();
    _adventureScrollController.dispose();
    super.dispose();
  }

  void _openPage(int index) {
    if (index == _pageIndex || !_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

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
    Item? tutorialItem;
    for (final item in equipment) {
      if (item.id == widget.tutorialItemId) {
        tutorialItem = item;
        break;
      }
    }

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
      floatingActionButton:
          tutorialItem == null
              ? ScrollToTopButton(
                key: ValueKey('store-to-top-$_pageIndex'),
                controller:
                    _pageIndex == 0
                        ? _titleScrollController
                        : _adventureScrollController,
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          _StorePageSwitcher(
            pageIndex: _pageIndex,
            onSelected: tutorialItem == null ? _openPage : null,
          ),
          Expanded(
            child: PageView(
              key: const ValueKey('store-page-view'),
              controller: _pageController,
              physics:
                  tutorialItem != null
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
              onPageChanged: (index) => setState(() => _pageIndex = index),
              children: [
                _buildTitleShopPage(),
                _buildAdventureShopPage(
                  tutorialItem: tutorialItem,
                  equipment: equipment,
                  categories: categories,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleShopPage() {
    return CustomScrollView(
      key: const ValueKey('store-title-scroll-view'),
      controller: _titleScrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          sliver: SliverToBoxAdapter(
            child:
                _hasTitleShop
                    ? SectionCard(
                      key: const ValueKey('store-titles-section'),
                      title: 'Ünvan Mağazası',
                      child: _TitleShop(
                        titles: widget.titles,
                        coins: widget.coins,
                        ownedTitleIds: widget.ownedTitleIds,
                        onPurchase: widget.onPurchaseTitle!,
                        onBlocked: _explain,
                      ),
                    )
                    : const SectionCard(
                      title: 'Ünvan Mağazası',
                      child: Text(
                        'Şu anda mağazada satılık ünvan bulunmuyor.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdventureShopPage({
    required Item? tutorialItem,
    required List<Item> equipment,
    required List<ItemCategory> categories,
  }) {
    return CustomScrollView(
      key: const ValueKey('store-scroll-view'),
      controller: _adventureScrollController,
      physics:
          tutorialItem != null ? const NeverScrollableScrollPhysics() : null,
      slivers: [
        if (tutorialItem != null) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İLK SİLAHIN',
                    style: TextStyle(
                      color: AppColors.streak,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Yol arkadaşın bu silahı senin için seçti.',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: ValueKey('tutorial-store-item-${tutorialItem.id}'),
                    child: _EquipmentCard(
                      key: TutorialGuideTargetKeys.shopItem,
                      item: tutorialItem,
                      coins: widget.coins,
                      level: widget.level,
                      ownedCount:
                          widget.ownedEquipmentCounts[tutorialItem.id] ?? 0,
                      onPurchase:
                          () => widget.onPurchaseEquipment(tutorialItem),
                      onBlocked: _explain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
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
      ],
    );
  }
}

class _StorePageSwitcher extends StatelessWidget {
  final int pageIndex;
  final ValueChanged<int>? onSelected;

  const _StorePageSwitcher({required this.pageIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, int index) {
      final selected = pageIndex == index;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            key: ValueKey('store-page-tab-$index'),
            onTap: onSelected == null ? null : () => onSelected!(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.surface.withValues(alpha: 0.72),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [tab('Ünvan Mağazası', 0), tab('Macera Mağazası', 1)]),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < 2; index++) ...[
                  AnimatedContainer(
                    key: ValueKey('store-page-bead-$index'),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: pageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          pageIndex == index
                              ? AppColors.primary
                              : Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  if (index == 0) const SizedBox(width: 7),
                ],
              ],
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

/// Yükseltme satırı (kozmetik, unvan, dondurma hakkı).
/// Mağazadaki tek bir ünvan satırı (Bölüm C.4).
///
/// Satın alınamıyorsa **neden** alınamadığını söyler: devre dışı düğme
/// dokunulabilir kalır ve nedeni açıklar (Model Kuralları #4).
/// Mağazadaki ünvan rafı (Bölüm C.4 / D sonrası düzeltme).
///
/// Ekipman ızgarasının kendi süzgeçleri var; ünvanların da olmalı. 14 satır
/// filtresiz bir liste, mağazanın en tepesinde okunmaz bir duvar olurdu.
class _TitleShop extends StatefulWidget {
  final List<GameTitle> titles;
  final int coins;
  final List<String> ownedTitleIds;
  final void Function(GameTitle title) onPurchase;
  final ValueChanged<String> onBlocked;

  const _TitleShop({
    required this.titles,
    required this.coins,
    required this.ownedTitleIds,
    required this.onPurchase,
    required this.onBlocked,
  });

  @override
  State<_TitleShop> createState() => _TitleShopState();
}

class _TitleShopState extends State<_TitleShop> {
  RewardRarity? _rarity;
  bool _affordableOnly = false;
  bool _hideOwned = false;

  List<GameTitle> get _visible => [
    for (final title in widget.titles)
      if ((_rarity == null || title.rarity == _rarity) &&
          (!_affordableOnly || widget.coins >= title.cost) &&
          (!_hideOwned || !widget.ownedTitleIds.contains(title.id)))
        title,
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final owned =
        widget.ownedTitleIds
            .where((id) => widget.titles.any((title) => title.id == id))
            .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ünvan bir kimlik: adının yanında görünür ve kendine has bir etki '
          'taşır. Aynı anda yalnızca birini takarsın; hepsi sende kalır.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          '$owned / ${widget.titles.length} ünvan sende · '
          '${visible.length} tanesi listede',
          key: const ValueKey('store-titles-summary'),
          style: const TextStyle(color: Colors.white38, fontSize: 11.5),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FilterChip(
              key: const ValueKey('store-title-rarity-all'),
              label: const Text('Tümü'),
              selected: _rarity == null,
              onSelected: (_) => setState(() => _rarity = null),
            ),
            for (final rarity in RewardRarity.values)
              FilterChip(
                key: ValueKey('store-title-rarity-${rarity.name}'),
                label: Text(rarity.label),
                selected: _rarity == rarity,
                selectedColor: rarity.color.withValues(alpha: 0.30),
                onSelected:
                    (selected) =>
                        setState(() => _rarity = selected ? rarity : null),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FilterChip(
              key: const ValueKey('store-title-affordable'),
              label: const Text('Alabileceklerim'),
              selected: _affordableOnly,
              onSelected:
                  (selected) => setState(() => _affordableOnly = selected),
            ),
            FilterChip(
              key: const ValueKey('store-title-hide-owned'),
              label: const Text('Sendekileri gizle'),
              selected: _hideOwned,
              onSelected: (selected) => setState(() => _hideOwned = selected),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const Padding(
            key: ValueKey('store-titles-empty'),
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Bu süzgeçle gösterilecek ünvan yok. Süzgeci gevşet ya da biraz '
              'daha altın biriktir.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          )
        else
          for (final title in visible)
            _TitleRow(
              title: title,
              coins: widget.coins,
              owned: widget.ownedTitleIds.contains(title.id),
              onPurchase: () => widget.onPurchase(title),
              onBlocked: widget.onBlocked,
            ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final GameTitle title;
  final int coins;
  final bool owned;
  final VoidCallback onPurchase;
  final ValueChanged<String> onBlocked;

  const _TitleRow({
    required this.title,
    required this.coins,
    required this.owned,
    required this.onPurchase,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final affordable = coins >= title.cost;
    final buyable = !owned && affordable;
    final reason =
        owned
            ? '"${title.name}" ünvanı zaten sende. Profilden takabilirsin.'
            : '${title.cost - coins} altın daha gerekiyor.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TitleBadge(title: title, compact: true),
          ),
          const SizedBox(height: 4),
          Text(
            title.lore,
            style: const TextStyle(
              color: Colors.white60,
              fontStyle: FontStyle.italic,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 4),
          for (final effect in title.effects)
            Text('• ${effect.label}', style: const TextStyle(fontSize: 11.5)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              // Devre dışı düğme dokunmayı yutar; sarmalayıcı nedeni
              // söyleyebilmek için dokunmayı yakalar.
              onTap: buyable ? null : () => onBlocked(reason),
              child: FilledButton.icon(
                key: ValueKey('buy-title-${title.id}'),
                onPressed: buyable ? onPurchase : null,
                icon: Icon(owned ? Icons.check : Icons.monetization_on),
                label: Text(
                  owned ? 'SENDE' : '${title.cost} ALTIN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    super.key,
    required this.item,
    required this.coins,
    required this.level,
    required this.ownedCount,
    required this.onPurchase,
    required this.onBlocked,
  });

  /// "Bu eşya nereye kadar gider" satırı.
  ///
  /// İki bilgi: nadirliğin izin verdiği en yüksek eşya seviyesi ve bir üst
  /// nadirliğe çıkmak için gereken adet. Gereken adet nadirliğe göre
  /// değiştiği için sayı tablodan okunuyor, sabit yazılmıyor.
  String get _investmentLine {
    final cap = itemLevelCap(item.rarity);
    final needed = mergeCountFor(item.rarity);
    final target = nextRarity(item.rarity);
    if (needed == null || target == null) {
      return 'Yükseltilebilir · Maks Sv. $cap · en üst nadirlik';
    }
    return 'Yükseltilebilir · Maks Sv. $cap · $needed tanesini '
        'birleştirince ${target.label} olur';
  }

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
            // Satın almayı **kalıcı bir yatırım** olarak göster: bu eşya
            // nereye kadar yükselir ve kaç tanesi bir üst nadirliğe çıkar.
            const SizedBox(height: 6),
            Text(
              _investmentLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.25,
                color: Colors.white54,
              ),
            ),
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
