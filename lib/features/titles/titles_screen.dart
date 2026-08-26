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

class _TitlesScreenState extends State<TitlesScreen> {
  final ScrollController _scrollController = ScrollController();
  _TitleFilter _filter = _TitleFilter.all;
  RewardRarity? _rarity;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<GameTitle> _visible(TitlesScreenState state) {
    return [
      for (final title in TitleCatalog.all)
        if (_rarity == null || title.rarity == _rarity)
          if (switch (_filter) {
            _TitleFilter.all => true,
            _TitleFilter.owned => state.ownedIds.contains(title.id),
            _TitleFilter.locked => !state.ownedIds.contains(title.id),
          })
            title,
    ];
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
          return ListView(
            key: const ValueKey('titles-scroll-view'),
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
                      style: TextStyle(color: Colors.white54, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FilterBar(
                filter: _filter,
                rarity: _rarity,
                ownedCount: state.ownedIds.length,
                totalCount: TitleCatalog.all.length,
                onFilter: (value) => setState(() => _filter = value),
                onRarity: (value) => setState(() => _rarity = value),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const SectionCard(
                  child: Text(
                    'Bu süzgeçle gösterilecek ünvan yok.',
                    key: ValueKey('titles-empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                for (final title in visible) ...[
                  _TitleCard(
                    title: title,
                    owned: state.ownedIds.contains(title.id),
                    equipped: state.equippedId == title.id,
                    progress: state.progress,
                    onEquip: () => widget.onEquip(title.id),
                  ),
                  const SizedBox(height: 10),
                ],
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
  final int ownedCount;
  final int totalCount;
  final ValueChanged<_TitleFilter> onFilter;
  final ValueChanged<RewardRarity?> onRarity;

  const _FilterBar({
    required this.filter,
    required this.rarity,
    required this.ownedCount,
    required this.totalCount,
    required this.onFilter,
    required this.onRarity,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$ownedCount / $totalCount ünvan kazanıldı',
            key: const ValueKey('titles-progress-summary'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in _TitleFilter.values)
                ChoiceChip(
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
                label: const Text('Her nadirlik'),
                selected: rarity == null,
                onSelected: (_) => onRarity(null),
              ),
              for (final value in RewardRarity.values)
                ChoiceChip(
                  label: Text(value.label),
                  selected: rarity == value,
                  selectedColor: value.color.withValues(alpha: 0.28),
                  onSelected: (_) => onRarity(value),
                ),
            ],
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
