import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/title_rules.dart';
import '../../data/title_catalog.dart';
import '../../models/game_title.dart';
import '../../models/reward_rarity.dart';
import '../../widgets/scroll_to_top_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/title_badge.dart';

/// Ünvanlar ekranı (Bölüm C.2).
///
/// Sahip olunanlar **ve** olunmayanlar birlikte görünür: kilitli bir ünvan
/// nasıl kazanılacağını söylemezse oyuncu için yok hükmündedir (Model
/// Kuralları #4). Başarım ünvanlarında ayrıca ilerleme çubuğu var — "100
/// düşman devir" yazan bir kart, 62'de olduğunu da söylemeli.
///
/// Ekran veri **tutmuyor**: her çizimde [readState] ile `RootShell`'den
/// yeniden okuyor ve [revision] değişince tazeleniyor. Gerekçe GD27: itilen
/// rota `RootShell`'in alt ağacında değil, `setState` onu tazelemiyor.
class TitlesScreen extends StatefulWidget {
  final ValueListenable<int> revision;
  final TitlesScreenState Function() readState;
  final ValueChanged<String?> onEquip;

  const TitlesScreen({
    super.key,
    required this.revision,
    required this.readState,
    required this.onEquip,
  });

  @override
  State<TitlesScreen> createState() => _TitlesScreenState();
}

/// Ekranın `RootShell`'den okuduğu anlık görüntü.
class TitlesScreenState {
  final Set<String> ownedIds;
  final String? equippedId;
  final TitleProgress progress;
  final int coins;

  const TitlesScreenState({
    required this.ownedIds,
    required this.equippedId,
    required this.progress,
    required this.coins,
  });
}

enum _TitleFilter { all, owned, locked }

/// Listenin sıralama ölçütü.
///
/// Varsayılan **katalog sırası**: ünvanlar nadirlik ve kazanma yoluna göre
/// elle dizilmiş, yani tasarımcının anlattığı sıra. Diğer üçü oyuncunun o an
/// aradığı şeye göre listeyi yeniden diziyor.
enum _TitleSort { catalog, rarity, progress, name }

class _TitlesScreenState extends State<TitlesScreen> {
  final ScrollController _scrollController = ScrollController();
  _TitleFilter _filter = _TitleFilter.all;
  RewardRarity? _rarity;
  TitleSource? _source;
  _TitleSort _sort = _TitleSort.catalog;
  String _query = '';
  final TextEditingController _search = TextEditingController();

  bool get _filtersActive =>
      _filter != _TitleFilter.all ||
      _rarity != null ||
      _source != null ||
      _sort != _TitleSort.catalog ||
      _query.isNotEmpty;

  void _clearFilters() {
    _search.clear();
    setState(() {
      _filter = _TitleFilter.all;
      _rarity = null;
      _source = null;
      _sort = _TitleSort.catalog;
      _query = '';
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _matchesQuery(GameTitle title) {
    if (_query.isEmpty) return true;
    final needle = _query.toLowerCase();
    if (title.name.toLowerCase().contains(needle)) return true;
    if (title.lore.toLowerCase().contains(needle)) return true;
    // Etki metninde de arıyoruz: "kritik" yazan oyuncu kritik veren
    // ünvanları görmeli.
    return title.effects.any(
      (effect) => effect.label.toLowerCase().contains(needle),
    );
  }

  List<GameTitle> _visible(TitlesScreenState state) {
    final list = [
      for (final title in TitleCatalog.all)
        if (_rarity == null || title.rarity == _rarity)
          if (_source == null || title.source == _source)
            if (_matchesQuery(title))
              if (switch (_filter) {
                _TitleFilter.all => true,
                _TitleFilter.owned => state.ownedIds.contains(title.id),
                _TitleFilter.locked => !state.ownedIds.contains(title.id),
              })
                title,
    ];

    switch (_sort) {
      case _TitleSort.catalog:
        break;
      case _TitleSort.rarity:
        list.sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
      case _TitleSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _TitleSort.progress:
        // En çok yaklaşılan başarım en üstte: "az kaldı" bilgisi listenin
        // en değerli bilgisi. Sahip olunanlar ve ilerlemesi olmayanlar
        // (mağaza/çark) sona düşer.
        double score(GameTitle title) {
          if (state.ownedIds.contains(title.id)) return -1;
          if (title.source != TitleSource.achievement) return -0.5;
          return achievementProgress(title, state.progress);
        }

        list.sort((a, b) => score(b).compareTo(score(a)));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ünvanlar')),
      floatingActionButton: ScrollToTopButton(controller: _scrollController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: ValueListenableBuilder<int>(
        valueListenable: widget.revision,
        builder: (context, _, __) {
          final state = widget.readState();
          final visible = _visible(state);
          final equipped = TitleCatalog.byId(state.equippedId);
          return CustomScrollView(
            key: const ValueKey('titles-scroll-view'),
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.list(
                  children: [
                    SectionCard(
                      title: 'Takılı ünvan',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (equipped == null)
                            const Text(
                              'Şu an takılı ünvanın yok. Bir ünvan tak; adının '
                              'yanında görünsün ve etkisi açılsın.',
                              key: ValueKey('no-equipped-title'),
                              style: TextStyle(color: Colors.white70),
                            )
                          else ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TitleBadge(title: equipped),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              equipped.lore,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final effect in equipped.effects)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '• ${effect.label}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                key: const ValueKey('unequip-title'),
                                onPressed: () => widget.onEquip(null),
                                icon: const Icon(Icons.close),
                                label: const Text('ÜNVANI ÇIKAR'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            'Aynı anda yalnızca **bir** ünvan takılır: ünvan bir '
                            'kimlik, bir liste değil. Diğerleri sende kalır, '
                            'istediğin zaman değiştirebilirsin.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FilterBar(
                      filter: _filter,
                      rarity: _rarity,
                      source: _source,
                      sort: _sort,
                      search: _search,
                      shownCount: visible.length,
                      ownedCount: state.ownedIds.length,
                      totalCount: TitleCatalog.all.length,
                      filtersActive: _filtersActive,
                      onFilter: (value) => setState(() => _filter = value),
                      onRarity: (value) => setState(() => _rarity = value),
                      onSource: (value) => setState(() => _source = value),
                      onSort: (value) => setState(() => _sort = value),
                      onQuery: (value) => setState(() => _query = value.trim()),
                      onClear: _clearFilters,
                    ),
                    const SizedBox(height: 12),
                    if (visible.isEmpty)
                      SectionCard(
                        child: Column(
                          children: [
                            const Text(
                              'Bu süzgeçle gösterilecek ünvan yok.',
                              key: ValueKey('titles-empty'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              key: const ValueKey('titles-clear-empty'),
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text('SÜZGEÇLERİ TEMİZLE'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Katalog 65 ünvan taşıyor; kartların hepsini birden kurmak
              // ekranı açılışta yavaşlatıyordu. Tembel liste yalnızca
              // görünenleri kuruyor.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final title = visible[index];
                    return _TitleCard(
                      title: title,
                      owned: state.ownedIds.contains(title.id),
                      equipped: state.equippedId == title.id,
                      progress: state.progress,
                      onEquip: () => widget.onEquip(title.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _TitleFilter filter;
  final RewardRarity? rarity;
  final TitleSource? source;
  final _TitleSort sort;
  final TextEditingController search;
  final int shownCount;
  final int ownedCount;
  final int totalCount;
  final bool filtersActive;
  final ValueChanged<_TitleFilter> onFilter;
  final ValueChanged<RewardRarity?> onRarity;
  final ValueChanged<TitleSource?> onSource;
  final ValueChanged<_TitleSort> onSort;
  final ValueChanged<String> onQuery;
  final VoidCallback onClear;

  const _FilterBar({
    required this.filter,
    required this.rarity,
    required this.source,
    required this.sort,
    required this.search,
    required this.shownCount,
    required this.ownedCount,
    required this.totalCount,
    required this.filtersActive,
    required this.onFilter,
    required this.onRarity,
    required this.onSource,
    required this.onSort,
    required this.onQuery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalCount == 0 ? 0.0 : ownedCount / totalCount;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$ownedCount / $totalCount ünvan kazanıldı',
                  key: const ValueKey('titles-progress-summary'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (filtersActive)
                TextButton.icon(
                  key: const ValueKey('titles-clear-filters'),
                  onPressed: onClear,
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('TEMİZLE'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppColors.xp),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('titles-search'),
            controller: search,
            onChanged: onQuery,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Ünvan, hikâye ya da etki ara…',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon:
                  search.text.isEmpty
                      ? null
                      : IconButton(
                        key: const ValueKey('titles-search-clear'),
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          search.clear();
                          onQuery('');
                        },
                      ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in _TitleFilter.values)
                ChoiceChip(
                  key: ValueKey('titles-filter-${value.name}'),
                  label: Text(switch (value) {
                    _TitleFilter.all => 'Tümü',
                    _TitleFilter.owned => 'Sende',
                    _TitleFilter.locked => 'Kilitli',
                  }),
                  selected: filter == value,
                  onSelected: (_) => onFilter(value),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                key: const ValueKey('titles-rarity-any'),
                label: const Text('Her nadirlik'),
                selected: rarity == null,
                onSelected: (_) => onRarity(null),
              ),
              for (final value in RewardRarity.values)
                ChoiceChip(
                  key: ValueKey('titles-rarity-${value.name}'),
                  label: Text(value.label),
                  selected: rarity == value,
                  selectedColor: value.color.withValues(alpha: 0.28),
                  onSelected: (_) => onRarity(value),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Kazanma yolu süzgeci: "hangilerini satın alabilirim" ya da
          // "hangileri başarımla gelir" sorusunun tek cevabı bu.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                key: const ValueKey('titles-source-any'),
                label: const Text('Her yol'),
                selected: source == null,
                onSelected: (_) => onSource(null),
              ),
              for (final value in TitleSource.values)
                ChoiceChip(
                  key: ValueKey('titles-source-${value.name}'),
                  label: Text(switch (value) {
                    TitleSource.achievement => 'Başarım',
                    TitleSource.purchase => 'Mağaza',
                    TitleSource.wheel => 'Çark',
                    TitleSource.milestone => 'Kilometre taşı',
                  }),
                  selected: source == value,
                  onSelected: (_) => onSource(value),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.sort, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final value in _TitleSort.values) ...[
                        ChoiceChip(
                          key: ValueKey('titles-sort-${value.name}'),
                          label: Text(switch (value) {
                            _TitleSort.catalog => 'Varsayılan',
                            _TitleSort.rarity => 'Nadirlik',
                            _TitleSort.progress => 'Az kaldı',
                            _TitleSort.name => 'A→Z',
                          }),
                          selected: sort == value,
                          onSelected: (_) => onSort(value),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$shownCount ünvan listede',
            key: const ValueKey('titles-shown-count'),
            style: const TextStyle(color: Colors.white38, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  final GameTitle title;
  final bool owned;
  final bool equipped;
  final TitleProgress progress;
  final VoidCallback onEquip;

  const _TitleCard({
    required this.title,
    required this.owned,
    required this.equipped,
    required this.progress,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final color = title.rarity.color;
    final ratio = achievementProgress(title, progress);
    final showProgress =
        !owned && title.source == TitleSource.achievement && ratio < 1;
    return Opacity(
      // Kilitli kart soluk ama **okunur** kalır: nasıl kazanılacağı bu kartta
      // yazıyor, gizlenmemeli.
      opacity: owned ? 1 : 0.72,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  owned ? Icons.military_tech : Icons.lock_outline,
                  size: 18,
                  color: owned ? color : Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: owned ? color : Colors.white70,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Pill(text: title.rarity.label, color: color),
                _Pill(text: title.sourceLabel, color: Colors.white38),
                if (equipped)
                  const _Pill(text: 'TAKILI', color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title.lore,
              style: const TextStyle(
                color: Colors.white60,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            for (final effect in title.effects)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${effect.label}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (!owned) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title.unlockHint,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (showProgress) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                  color: color,
                  backgroundColor: Colors.white12,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(ratio * 100).round()}% tamamlandı',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ],
            if (owned && !equipped) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: ValueKey('equip-title-${title.id}'),
                  onPressed: onEquip,
                  icon: const Icon(Icons.military_tech),
                  label: const Text('TAK'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
