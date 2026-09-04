import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/localization/app_formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n_context.dart';
import '../../l10n/content_localizations.dart';
import '../../models/collection_reward.dart';
import '../../models/reward_rarity.dart';
import '../../services/reward_engine.dart';

enum _OwnershipFilter { all, earned, locked }

class RewardsScreen extends StatefulWidget {
  final List<CollectionReward> rewards;
  final RewardStatistics statistics;
  final Map<String, DateTime> earnedRewardDates;
  final List<String> pinnedRewardIds;
  final ValueChanged<String> onTogglePinned;

  const RewardsScreen({
    super.key,
    required this.rewards,
    required this.statistics,
    required this.earnedRewardDates,
    required this.pinnedRewardIds,
    required this.onTogglePinned,
  });

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _searchController = TextEditingController();
  late final Set<String> _pinned = widget.pinnedRewardIds.toSet();
  String? _category;
  RewardRarity? _rarity;
  _OwnershipFilter _ownership = _OwnershipFilter.all;
  String _query = '';

  List<String> get _categories =>
      widget.rewards.map((reward) => reward.category).toSet().toList()..sort();

  List<CollectionReward> get _filtered =>
      widget.rewards.where((reward) {
        final earned = widget.earnedRewardDates.containsKey(reward.id);
        if (_category != null && reward.category != _category) return false;
        if (_rarity != null && reward.rarity != _rarity) return false;
        if (_ownership == _OwnershipFilter.earned && !earned) return false;
        if (_ownership == _OwnershipFilter.locked && earned) return false;
        if (_query.isNotEmpty) {
          final haystack =
              '${context.l10n.collectionRewardName(reward)} '
                      '${context.l10n.collectionRewardRequirement(reward)}'
                  .toLowerCase();
          if (!haystack.contains(_query)) return false;
        }
        return true;
      }).toList();

  List<CollectionReward> get _earned {
    final rewards =
        widget.rewards
            .where((reward) => widget.earnedRewardDates.containsKey(reward.id))
            .toList();
    rewards.sort((a, b) {
      final pinned =
          (_pinned.contains(b.id) ? 1 : 0) - (_pinned.contains(a.id) ? 1 : 0);
      if (pinned != 0) return pinned;
      return widget.earnedRewardDates[b.id]!.compareTo(
        widget.earnedRewardDates[a.id]!,
      );
    });
    return rewards;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _togglePinned(CollectionReward reward) {
    if (!_pinned.contains(reward.id) &&
        _pinned.length >= RewardEngine.maxPinnedRewards) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.showcasePinLimit(RewardEngine.maxPinnedRewards),
          ),
        ),
      );
      return;
    }
    setState(() {
      if (!_pinned.remove(reward.id)) _pinned.add(reward.id);
    });
    widget.onTogglePinned(reward.id);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.myRewards),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.allRewards),
              Tab(text: context.l10n.showcase),
            ],
          ),
        ),
        body: TabBarView(children: [_buildAllRewards(), _buildShowcase()]),
      ),
    );
  }

  Widget _buildAllRewards() {
    final filtered = _filtered;
    final earnedCount = widget.earnedRewardDates.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 900
                ? 5
                : constraints.maxWidth >= 650
                ? 4
                : constraints.maxWidth >= 420
                ? 3
                : 2;
        return CustomScrollView(
          key: const ValueKey('all-rewards-scroll'),
          slivers: [
            SliverToBoxAdapter(
              child: _RewardSummary(
                earned: earnedCount,
                total: widget.rewards.length,
              ),
            ),
            SliverToBoxAdapter(child: _buildFilters()),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(context.l10n.noRewardsForFilters)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                sliver: SliverGrid.builder(
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.69,
                  ),
                  itemBuilder:
                      (context, index) => _RewardCard(
                        reward: filtered[index],
                        statistics: widget.statistics,
                        earnedAt: widget.earnedRewardDates[filtered[index].id],
                        onTap: () => _openDetail(filtered[index]),
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.l10n.rewardSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _query.isEmpty
                      ? null
                      : IconButton(
                        tooltip: context.l10n.clearSearch,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
            ),
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterMenu<String>(
                  label: context.l10n.category,
                  value: _category,
                  entries: _categories,
                  text: _prettyCategory,
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(width: 8),
                _FilterMenu<RewardRarity>(
                  label: context.l10n.rarity,
                  value: _rarity,
                  entries: RewardRarity.values,
                  text: context.l10n.rarityName,
                  onChanged: (value) => setState(() => _rarity = value),
                ),
                const SizedBox(width: 8),
                for (final filter in _OwnershipFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(switch (filter) {
                        _OwnershipFilter.all => context.l10n.filterAll,
                        _OwnershipFilter.earned => context.l10n.filterEarned,
                        _OwnershipFilter.locked => context.l10n.filterLocked,
                      }),
                      selected: _ownership == filter,
                      onSelected: (_) => setState(() => _ownership = filter),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcase() {
    final earned = _earned;
    if (earned.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.noRewardsYet,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
      );
    }

    final pinned =
        earned.where((reward) => _pinned.contains(reward.id)).toList();
    final others =
        earned.where((reward) => !_pinned.contains(reward.id)).toList();
    return CustomScrollView(
      key: const ValueKey('reward-showcase-scroll'),
      slivers: [
        if (pinned.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: context.l10n.pinnedRewards,
              icon: Icons.push_pin,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              itemCount: pinned.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder:
                  (context, index) => _ShowcaseCard(
                    reward: pinned[index],
                    pinned: true,
                    onPin: () => _togglePinned(pinned[index]),
                    onTap: () => _openDetail(pinned[index]),
                  ),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: _SectionTitle(
            title: context.l10n.collection,
            icon: Icons.auto_awesome,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
          sliver: SliverList.builder(
            itemCount: others.length,
            itemBuilder:
                (context, index) => _ShowcaseTile(
                  reward: others[index],
                  earnedAt: widget.earnedRewardDates[others[index].id]!,
                  onPin: () => _togglePinned(others[index]),
                  onTap: () => _openDetail(others[index]),
                ),
          ),
        ),
      ],
    );
  }

  void _openDetail(CollectionReward reward) {
    final earnedAt = widget.earnedRewardDates[reward.id];
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.closeRewardDetails,
      barrierColor: Colors.black87,
      transitionDuration:
          MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 420),
      pageBuilder:
          (context, animation, secondaryAnimation) => _RewardDetail(
            reward: reward,
            statistics: widget.statistics,
            earnedAt: earnedAt,
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _RewardSummary extends StatelessWidget {
  final int earned;
  final int total;
  const _RewardSummary({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : earned / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.streak),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.rewardsEarnedProgress(earned, total),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '%${(ratio * 100).toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: AppColors.xp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final CollectionReward reward;
  final RewardStatistics statistics;
  final DateTime? earnedAt;
  final VoidCallback onTap;
  const _RewardCard({
    required this.reward,
    required this.statistics,
    required this.earnedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final earned = earnedAt != null;
    final progress = reward.progress(statistics).clamp(0, reward.target);
    return Semantics(
      button: true,
      label:
          earned
              ? context.l10n.rewardEarnedSemantics(
                context.l10n.collectionRewardName(reward),
              )
              : context.l10n.rewardLockedSemantics(
                context.l10n.collectionRewardName(reward),
                progress,
                reward.target,
              ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  earned
                      ? reward.rarity.color.withValues(alpha: 0.8)
                      : Colors.white12,
              width: earned ? 1.5 : 1,
            ),
            boxShadow:
                earned
                    ? [
                      BoxShadow(
                        color: reward.rarity.color.withValues(alpha: 0.17),
                        blurRadius: 14,
                      ),
                    ]
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: earned ? 1 : 0.3,
                        child: ColorFiltered(
                          colorFilter:
                              earned
                                  ? const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  )
                                  : const ColorFilter.matrix(<double>[
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                          child: Image.asset(
                            reward.assetPath,
                            fit: BoxFit.contain,
                            cacheWidth: 180,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ),
                      if (!earned)
                        const Align(
                          alignment: Alignment.topRight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(Icons.lock, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.collectionRewardName(reward),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.collectionRewardRequirement(reward),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.white60),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: earned ? 1 : progress / reward.target,
                  minHeight: 4,
                  color: reward.rarity.color,
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        earned
                            ? context.l10n.earned
                            : '$progress / ${reward.target}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.rarityName(reward.rarity),
                      style: TextStyle(
                        fontSize: 9,
                        color: reward.rarity.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> entries;
  final String Function(T value) text;
  final ValueChanged<T?> onChanged;
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.entries,
    required this.text,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => PopupMenuButton<T?>(
    initialValue: value,
    onSelected: onChanged,
    itemBuilder:
        (context) => [
          PopupMenuItem<T?>(
            value: null,
            child: Text(context.l10n.filterMenuAll(label)),
          ),
          for (final entry in entries)
            PopupMenuItem<T?>(value: entry, child: Text(text(entry))),
        ],
    child: Chip(
      label: Text(value == null ? label : text(value as T)),
      avatar: const Icon(Icons.expand_more, size: 17),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
    child: Row(
      children: [
        Icon(icon, size: 19, color: AppColors.streak),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _ShowcaseCard extends StatelessWidget {
  final CollectionReward reward;
  final bool pinned;
  final VoidCallback onPin;
  final VoidCallback onTap;
  const _ShowcaseCard({
    required this.reward,
    required this.pinned,
    required this.onPin,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                reward.assetPath,
                fit: BoxFit.contain,
                cacheWidth: 260,
                filterQuality: FilterQuality.none,
              ),
            ),
            Text(
              context.l10n.collectionRewardName(reward),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            IconButton(
              tooltip: context.l10n.removeFromShowcase,
              onPressed: onPin,
              icon: const Icon(Icons.push_pin, color: AppColors.streak),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShowcaseTile extends StatelessWidget {
  final CollectionReward reward;
  final DateTime earnedAt;
  final VoidCallback onPin;
  final VoidCallback onTap;
  const _ShowcaseTile({
    required this.reward,
    required this.earnedAt,
    required this.onPin,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Image.asset(
        reward.assetPath,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        cacheWidth: 96,
        filterQuality: FilterQuality.none,
      ),
      title: Text(
        context.l10n.collectionRewardName(reward),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${context.l10n.rarityName(reward.rarity)} • '
        '${AppFormatters.longDate(context, earnedAt)}',
      ),
      trailing: IconButton(
        tooltip: context.l10n.pinToShowcase,
        onPressed: onPin,
        icon: const Icon(Icons.push_pin_outlined),
      ),
    ),
  );
}

class _RewardDetail extends StatelessWidget {
  final CollectionReward reward;
  final RewardStatistics statistics;
  final DateTime? earnedAt;
  const _RewardDetail({
    required this.reward,
    required this.statistics,
    required this.earnedAt,
  });

  @override
  Widget build(BuildContext context) {
    final earned = earnedAt != null;
    final progress = reward.progress(statistics).clamp(0, reward.target);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Material(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 230,
                        height: 230,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              earned
                                  ? reward.rarity.color.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.03),
                          boxShadow:
                              earned
                                  ? [
                                    BoxShadow(
                                      color: reward.rarity.color.withValues(
                                        alpha: 0.42,
                                      ),
                                      blurRadius: 55,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Opacity(
                          opacity: earned ? 1 : 0.32,
                          child: Image.asset(
                            reward.assetPath,
                            fit: BoxFit.contain,
                            cacheWidth: 460,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!earned)
                        const Icon(Icons.lock, color: Colors.white54),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.collectionRewardName(reward),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        earned
                            ? context.l10n.rewardEarnedForRequirement(
                              context.l10n.collectionRewardRequirement(reward),
                            )
                            : context.l10n.collectionRewardRequirement(reward),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (earned)
                        Text(
                          context.l10n.rewardWithDate(
                            context.l10n.rarityName(reward.rarity),
                            AppFormatters.longDate(context, earnedAt!),
                          ),
                          style: TextStyle(
                            color: reward.rarity.color,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      else ...[
                        Text(
                          context.l10n.progressValue(progress, reward.target),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 260,
                          child: LinearProgressIndicator(
                            value: progress / reward.target,
                            color: reward.rarity.color,
                            minHeight: 7,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: context.l10n.commonClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _prettyCategory(String value) => value.replaceAll('_', ' ');
