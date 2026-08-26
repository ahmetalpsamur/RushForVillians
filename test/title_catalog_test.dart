import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/equipped_buffs.dart';
import 'package:rush_for_villains/core/utils/title_rules.dart';
import 'package:rush_for_villains/data/title_catalog.dart';
import 'package:rush_for_villains/models/game_title.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';

/// Ünvan kataloğunun **sözleşmesi** (Bölüm C.3).
///
/// Buradaki testler tek tek ünvanları değil, katalogun tamamının uyması
/// gereken kuralları bağlıyor: yeni bir ünvan eklenip kural unutulursa burada
/// yakalanır. Aynı desen `item_catalog_test.dart` içinde kullanılıyor.
void main() {
  group('katalog bütünlüğü', () {
    test('en az 50 ünvan var', () {
      expect(TitleCatalog.all.length, greaterThanOrEqualTo(50));
    });

    test('kimlikler benzersiz', () {
      final ids = TitleCatalog.all.map((title) => title.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('adlar benzersiz', () {
      final names = TitleCatalog.all.map((title) => title.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('her ünvanın adı, lore\'u ve en az bir etkisi var', () {
      for (final title in TitleCatalog.all) {
        expect(title.name.trim(), isNotEmpty, reason: title.id);
        expect(title.lore.trim(), isNotEmpty, reason: title.id);
        expect(title.effects, isNotEmpty, reason: title.id);
      }
    });

    test('byId katalogla tutarlı, bilinmeyen kimlik null', () {
      for (final title in TitleCatalog.all) {
        expect(TitleCatalog.byId(title.id), same(title));
      }
      expect(TitleCatalog.byId('yok-boyle-bir-unvan'), isNull);
      expect(TitleCatalog.byId(null), isNull);
    });

    test('beş nadirliğin hepsi temsil ediliyor', () {
      for (final rarity in RewardRarity.values) {
        expect(
          TitleCatalog.all.where((title) => title.rarity == rarity),
          isNotEmpty,
          reason: '${rarity.label} nadirliğinde ünvan yok',
        );
      }
    });

    test('dört kazanma yolunun hepsi kullanılıyor (C.4)', () {
      for (final source in TitleSource.values) {
        expect(
          TitleCatalog.withSource(source),
          isNotEmpty,
          reason: '${source.name} yolundan ünvan gelmiyor',
        );
      }
    });

    test('her kazanma yolu kendi alanını dolduruyor', () {
      for (final title in TitleCatalog.all) {
        switch (title.source) {
          case TitleSource.purchase:
            expect(title.cost, greaterThan(0), reason: title.id);
          case TitleSource.achievement:
            expect(title.condition, isNotNull, reason: title.id);
            expect(title.conditionThreshold, greaterThan(0), reason: title.id);
          case TitleSource.milestone:
            expect(title.milestoneDay, greaterThan(0), reason: title.id);
          case TitleSource.wheel:
            break;
        }
      }
    });

    test('kilit ipucu her ünvanda dolu (Model Kuralları #4)', () {
      for (final title in TitleCatalog.all) {
        expect(title.unlockHint.trim(), isNotEmpty, reason: title.id);
        expect(title.sourceLabel.trim(), isNotEmpty, reason: title.id);
      }
    });

    test('mağaza listesi ucuzdan pahalıya sıralı', () {
      final costs = TitleCatalog.purchasable.map((t) => t.cost).toList();
      expect(costs, orderedEquals(List.of(costs)..sort()));
      expect(costs.length, greaterThan(1));
    });

    test('kilometre taşı ünvanları benzersiz güne bağlı', () {
      final days =
          TitleCatalog.withSource(
            TitleSource.milestone,
          ).map((title) => title.milestoneDay).toList();
      expect(days.toSet().length, days.length);
      for (final day in days) {
        expect(TitleCatalog.forMilestone(day)?.milestoneDay, day);
      }
      expect(TitleCatalog.forMilestone(-1), isNull);
    });

    test('mevcut seri kilometre taşlarının hepsinin ünvanı var', () {
      for (final day in GameConstants.streakMilestones) {
        expect(
          TitleCatalog.forMilestone(day),
          isNotNull,
          reason: '$day günlük kilometre taşı ödülsüz kalmamalı',
        );
      }
    });
  });

  group('C.3 tasarım kuralı: düz stat artışı yok', () {
    test('her ünvanın bir karakteri var', () {
      // Bir ünvan ya koşullu/tetiklenen bir etki taşır, ya iki uçludur
      // (bir artı bir eksi), ya birden çok etkisi vardır, ya da kendi
      // cümlesini yazar. Tek, koşulsuz, açıklamasız bir "+%10 saldırı"
      // ünvanı eşyadan ayrışmaz.
      for (final title in TitleCatalog.all) {
        final hasTrigger = title.effects.any(
          (effect) => effect.trigger != ItemEffectTrigger.always,
        );
        final hasTradeOff = title.effects.any((effect) => effect.value < 0);
        final hasMultiple = title.effects.length > 1;
        final hasVoice = title.effects.every(
          (effect) => effect.customLabel != null,
        );
        expect(
          hasTrigger || hasTradeOff || hasMultiple || hasVoice,
          isTrue,
          reason: '${title.id} düz bir stat artışından ibaret',
        );
      }
    });

    test('katalogda her tetikleyici gerçekten kullanılıyor', () {
      final used = {
        for (final title in TitleCatalog.all)
          for (final effect in title.effects) effect.trigger,
      };
      for (final trigger in ItemEffectTrigger.values) {
        expect(
          used,
          contains(trigger),
          reason: '${trigger.name} hiçbir ünvanda kullanılmıyor',
        );
      }
    });

    test('çift etkili (bir artı bir eksi) ünvanlar var', () {
      final tradeOffs = TitleCatalog.all.where(
        (title) =>
            title.effects.any((effect) => effect.value > 0) &&
            title.effects.any((effect) => effect.value < 0),
      );
      expect(tradeOffs.length, greaterThanOrEqualTo(5));
    });

    test('nadirlik yükseldikçe etki sayısı azalmıyor', () {
      double averageEffects(RewardRarity rarity) {
        final titles =
            TitleCatalog.all.where((t) => t.rarity == rarity).toList();
        return titles.fold<int>(0, (sum, t) => sum + t.effects.length) /
            titles.length;
      }

      expect(
        averageEffects(RewardRarity.legendary),
        greaterThan(averageEffects(RewardRarity.common)),
      );
    });
  });

  group('C.3 ekonomi sınırı', () {
    /// Bir ünvanın koşulsuz ekonomi oranları (çarpana giren tek küme).
    Iterable<ItemEffect> passiveEconomy(GameTitle title) => title.effects.where(
      (effect) => effect.isPassive && effect.stat.isEconomyRate,
    );

    /// Seyrek olay statları (çark XP, düşman XP) iki katı tavanla ölçülür —
    /// gerekçe [GameConstants.maxTitleRareEventBonus] üzerinde.
    double capFor(ItemStat stat) =>
        stat == ItemStat.wheelXp || stat == ItemStat.enemyXp
        ? GameConstants.maxTitleRareEventBonus
        : GameConstants.maxTitleEconomyBonus;

    test('tek ünvanın koşulsuz ekonomi oranı tavanı aşmaz', () {
      for (final title in TitleCatalog.all) {
        for (final effect in passiveEconomy(title)) {
          expect(
            effect.value,
            lessThanOrEqualTo(capFor(effect.stat) + 1e-9),
            reason: '${title.id}: ${effect.stat.name}',
          );
        }
      }
    });

    test('her gün işleyen ekonomi statları dar tavana bağlı', () {
      // Adım parası ve adım XP'si ölçülmüş dengeye (economy_pacing_test)
      // doğrudan bağlı; onlarda seyrek olay istisnası geçerli değil.
      for (final title in TitleCatalog.all) {
        for (final effect in passiveEconomy(title)) {
          if (effect.stat == ItemStat.wheelXp ||
              effect.stat == ItemStat.enemyXp) {
            continue;
          }
          expect(
            effect.value,
            lessThanOrEqualTo(GameConstants.maxTitleEconomyBonus + 1e-9),
            reason: '${title.id}: ${effect.stat.name}',
          );
        }
      }
    });

    test('koşullu etki çarpana hiç girmez', () {
      // "Gece yürüyüşlerinde +%25" kuşanıldığı anda pasif bir çarpana
      // dönüşmemeli; yoksa koşul bedava olur.
      final nightWalker = TitleCatalog.byId('night_walker')!;
      final buffs = EquippedBuffs.from(
        const [],
        titleEffects: nightWalker.effects,
      );
      expect(buffs.stepCoinBonus, 0);
      expect(buffs.conditionalEffects, isNotEmpty);
    });

    test('ünvan + eşya birlikte bile toplam tavanı aşamaz', () {
      // En cömert ünvanı, tavanı zorlayan yapay etkilerle birlikte topla.
      final generous = [
        for (final title in TitleCatalog.all)
          for (final effect in title.effects)
            if (effect.isPassive && effect.stat == ItemStat.stepCoin) effect,
      ];
      final buffs = EquippedBuffs.from(
        const [],
        titleEffects: [
          ...generous,
          const ItemEffect(stat: ItemStat.stepCoin, value: 5),
        ],
      );
      expect(
        buffs.stepCoinBonus,
        lessThanOrEqualTo(GameConstants.maxEquippedEconomyBonus + 1e-9),
      );
      expect(
        buffs.stepCoinMultiplier,
        lessThanOrEqualTo(1 + GameConstants.maxEquippedEconomyBonus + 1e-9),
      );
    });

    test('stok bonusları da tavana kırpılır', () {
      final buffs = EquippedBuffs.from(
        const [],
        titleEffects: const [
          ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 99),
          ItemEffect.flat(stat: ItemStat.wheelSpinCap, value: 99),
          ItemEffect.flat(stat: ItemStat.streakRelief, value: 99999),
        ],
      );
      expect(
        buffs.streakFreezeCapBonus,
        lessThanOrEqualTo(GameConstants.maxEquippedStockBonus),
      );
      expect(
        buffs.wheelSpinCapBonus,
        lessThanOrEqualTo(GameConstants.maxEquippedStockBonus),
      );
      expect(buffs.streakStepThreshold, greaterThan(0));
    });

    test('savaş etkileri ekonomi çarpanına hiç girmez', () {
      final buffs = EquippedBuffs.from(
        const [],
        titleEffects: const [
          ItemEffect(stat: ItemStat.attack, value: 5),
          ItemEffect.flat(stat: ItemStat.maxHealth, value: 500),
        ],
      );
      expect(buffs.stepCoinBonus, 0);
      expect(buffs.stepXpBonus, 0);
      expect(buffs.combatEffects.length, 2);
    });
  });

  group('C.4 başarım koşulları', () {
    const empty = TitleProgress();

    test('koşul sağlanmadan açılmaz, sağlanınca açılır', () {
      final title = TitleCatalog.all.firstWhere(
        (t) =>
            t.source == TitleSource.achievement &&
            t.condition == TitleCondition.enemiesDefeated,
      );
      expect(isAchievementUnlocked(title, empty), isFalse);
      expect(
        isAchievementUnlocked(
          title,
          TitleProgress(enemiesDefeated: title.conditionThreshold),
        ),
        isTrue,
      );
      // Tam sınır dahil.
      expect(
        isAchievementUnlocked(
          title,
          TitleProgress(enemiesDefeated: title.conditionThreshold - 1),
        ),
        isFalse,
      );
    });

    test('başarım olmayan ünvan koşulla açılmaz', () {
      for (final title in TitleCatalog.all) {
        if (title.source == TitleSource.achievement) continue;
        expect(
          isAchievementUnlocked(
            title,
            const TitleProgress(
              level: 9999,
              totalSteps: 99999999,
              longestStreak: 9999,
              enemiesDefeated: 99999,
              adventuresCompleted: 99999,
              wheelSpins: 99999,
              itemsMerged: 99999,
              lifetimeCoins: 99999999,
            ),
          ),
          isFalse,
          reason: '${title.id} yalnızca ${title.source.name} yolundan gelmeli',
        );
      }
    });

    test('newlyEarnedTitles sahip olunanları atlar', () {
      const progress = TitleProgress(totalSteps: 999999999, level: 99);
      final first = newlyEarnedTitles(
        progress: progress,
        ownedTitleIds: const {},
      );
      expect(first, isNotEmpty);

      final second = newlyEarnedTitles(
        progress: progress,
        ownedTitleIds: first.map((title) => title.id).toSet(),
      );
      expect(second, isEmpty);
    });

    test('ilerleme oranı 0..1 arasında kalır', () {
      final title = TitleCatalog.all.firstWhere(
        (t) => t.source == TitleSource.achievement,
      );
      expect(achievementProgress(title, empty), 0);
      expect(
        achievementProgress(
          title,
          const TitleProgress(
            level: 99999,
            totalSteps: 999999999,
            longestStreak: 99999,
            enemiesDefeated: 99999,
            adventuresCompleted: 99999,
            ownedItemCount: 99999,
            maxItemLevel: 99999,
            wheelSpins: 99999,
            itemsMerged: 99999,
            lifetimeCoins: 999999999,
          ),
        ),
        1,
      );
      // Başarım olmayan ünvanda çubuk hiç çizilmez.
      final wheelTitle = TitleCatalog.withSource(TitleSource.wheel).first;
      expect(achievementProgress(wheelTitle, empty), 0);
    });

    test('her koşul türü en az bir ünvanda kullanılıyor', () {
      final used = {
        for (final title in TitleCatalog.all)
          if (title.condition != null) title.condition!,
      };
      for (final condition in TitleCondition.values) {
        expect(
          used,
          contains(condition),
          reason: '${condition.name} hiçbir ünvanda kullanılmıyor',
        );
      }
    });

    test('koşul açıklaması her eşikte dolu', () {
      for (final condition in TitleCondition.values) {
        expect(condition.describe(100).trim(), isNotEmpty);
      }
    });

    test('envanterden türeyen sayaçlar listeden okunur', () {
      final progress = TitleProgress.fromCounters(
        level: 3,
        totalSteps: 10,
        longestStreak: 2,
        enemiesDefeated: 1,
        adventuresCompleted: 0,
        wheelSpins: 0,
        itemsMerged: 0,
        lifetimeCoins: 0,
        ownedItems: const [],
      );
      expect(progress.ownedItemCount, 0);
      expect(progress.maxItemLevel, 0);
    });
  });
}
