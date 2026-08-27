import '../core/constants/game_constants.dart';
import '../models/collection_reward.dart';
import '../models/reward_rarity.dart';
import 'enemy_catalog.dart';
import 'reward_assets.g.dart';

/// 1.244 PNG'yi merkezi, deterministik ve genişletilebilir kayıtlara dönüştürür.
/// Asset listesi [scripts/generate_reward_assets.dart] ile üretilir.
abstract final class RewardCatalog {
  static final List<CollectionReward> all = _build();
  static final Map<String, CollectionReward> _byId = {
    for (final reward in all) reward.id: reward,
  };

  static CollectionReward? byId(String id) => _byId[id];

  static List<CollectionReward> _build() {
    assert(rewardAssetPaths.length == expectedRewardAssetCount);
    final conditionCounts = <RewardConditionType, int>{};
    final result = <CollectionReward>[];

    for (var index = 0; index < rewardAssetPaths.length; index++) {
      final path = rewardAssetPaths[index];
      final parts = path.split('/');
      final category = parts.length > 2 ? parts[2] : 'Unsorted';
      final subcategory = parts.length > 3 ? parts[3] : category;
      final condition =
          RewardConditionType.values[index % RewardConditionType.values.length];
      final series = (conditionCounts[condition] ?? 0) + 1;
      conditionCounts[condition] = series;
      final target = _targetFor(condition, series);
      final rarity = _rarityFor(series);
      final villainId =
          condition == RewardConditionType.specificVillain
              ? EnemyCatalog
                  .enemies[(series - 1) % EnemyCatalog.enemies.length]
                  .id
              : null;
      final noun = _nouns[subcategory] ?? _nouns[category] ?? 'Hatıra';
      final adjective = _adjectives[index % _adjectives.length];
      final id = path
          .substring('lib/Rewards/'.length, path.length - '.png'.length)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_');

      result.add(
        CollectionReward(
          id: id,
          name: '$adjective $noun · ${condition.label} $series',
          description: _descriptionFor(condition, target, villainId),
          requirement: _requirementFor(condition, target, villainId),
          conditionType: condition,
          target: target,
          villainId: villainId,
          assetPath: path,
          category: category,
          subcategory: subcategory,
          rarity: rarity,
          hidden: index % 37 == 0,
        ),
      );
    }

    assert(result.map((reward) => reward.id).toSet().length == result.length);
    assert(result.map((reward) => reward.name).toSet().length == result.length);
    assert(
      result.map((reward) => reward.assetPath).toSet().length == result.length,
    );
    return List.unmodifiable(result);
  }

  static int _targetFor(RewardConditionType type, int series) {
    final tier = series - 1;
    return switch (type) {
      RewardConditionType.totalDistance =>
        [
              1000,
              5000,
              10000,
              25000,
              50000,
              100000,
              250000,
              500000,
              1000000,
            ][tier % 9] *
            (1 + tier ~/ 9),
      RewardConditionType.singleWalkDistance =>
        [500, 1000, 2500, 5000, 10000, 20000][tier % 6] * (1 + tier ~/ 6),
      RewardConditionType.dailyStepGoals ||
      RewardConditionType.completedDays ||
      RewardConditionType.activeDays =>
        [1, 3, 7, 14, 30, 60, 100, 365][tier % 8] * (1 + tier ~/ 8),
      RewardConditionType.streakDays =>
        [1, 3, 7, 14, 30, 60, 100][tier % 7] * (1 + tier ~/ 7),
      RewardConditionType.monstersDefeated =>
        [1, 3, 5, 10, 25, 50, 100, 250, 500, 1000][tier % 10] *
            (1 + tier ~/ 10),
      RewardConditionType.specificVillain =>
        [1, 3, 5, 10, 25][tier % 5] * (1 + tier ~/ 5),
      RewardConditionType.villainsDefeated =>
        [1, 5, 10, 25, 50, 100][tier % 6] * (1 + tier ~/ 6),
      RewardConditionType.flawlessWins =>
        [1, 5, 10, 25, 50][tier % 5] * (1 + tier ~/ 5),
      RewardConditionType.winStreak =>
        [3, 5, 10, 20, 50][tier % 5] * (1 + tier ~/ 5),
      RewardConditionType.questsCompleted =>
        [1, 5, 10, 25, 50, 100, 250][tier % 7] * (1 + tier ~/ 7),
      RewardConditionType.level =>
        [2, 5, 10, 15, 20, 30, 50][tier % 7] + (tier ~/ 7) * 50,
      RewardConditionType.xpEarned =>
        [100, 500, 1000, 5000, 10000, 25000, 50000][tier % 7] * (1 + tier ~/ 7),
      RewardConditionType.bossesDefeated ||
      RewardConditionType.rareVillainsDefeated =>
        [1, 3, 5, 10, 25, 50][tier % 6] * (1 + tier ~/ 6),
      RewardConditionType.villainsDiscovered =>
        [1, 3, 5, 10, 15, 20][tier % 6] + (tier ~/ 6) * 20,
    };
  }

  static RewardRarity _rarityFor(int series) {
    final tier = (series - 1) % 12;
    if (tier < 4) return RewardRarity.common;
    if (tier < 7) return RewardRarity.uncommon;
    if (tier < 9) return RewardRarity.rare;
    if (tier < 11) return RewardRarity.epic;
    return RewardRarity.legendary;
  }

  static String _requirementFor(
    RewardConditionType type,
    int target,
    String? villainId,
  ) => switch (type) {
    RewardConditionType.totalDistance => '${_km(target)} km yürü',
    RewardConditionType.singleWalkDistance =>
      'Tek yürüyüşte ${_km(target)} km ilerle',
    RewardConditionType.dailyStepGoals =>
      'Günlük adım hedefini $target gün tamamla',
    RewardConditionType.streakDays => 'Hedefini $target gün üst üste tuttur',
    RewardConditionType.completedDays => '$target hedef günü tamamla',
    RewardConditionType.monstersDefeated => '$target canavar yen',
    RewardConditionType.specificVillain =>
      '${_villainLabel(villainId)} villain’ını $target kez yen',
    RewardConditionType.villainsDefeated => '$target villain yen',
    RewardConditionType.flawlessWins => 'Hasar almadan $target savaş kazan',
    RewardConditionType.winStreak => '$target savaşlık galibiyet serisine ulaş',
    RewardConditionType.questsCompleted => '$target görev tamamla',
    RewardConditionType.level => '$target. seviyeye ulaş',
    RewardConditionType.xpEarned => 'Toplam $target XP kazan',
    RewardConditionType.bossesDefeated => '$target boss yen',
    RewardConditionType.rareVillainsDefeated => '$target nadir villain yen',
    RewardConditionType.villainsDiscovered => '$target farklı villain keşfet',
    RewardConditionType.activeDays => 'Uygulamaya $target farklı gün devam et',
  };

  static String _descriptionFor(
    RewardConditionType type,
    int target,
    String? villainId,
  ) =>
      '${_requirementFor(type, target, villainId)} ve bu hatırayı koleksiyonuna kat.';

  static String _km(int steps) {
    final km = steps / GameConstants.stepsPerKilometer;
    return km == km.roundToDouble()
        ? km.toInt().toString()
        : km.toStringAsFixed(1);
  }

  static String _villainLabel(String? id) {
    for (final enemy in EnemyCatalog.enemies) {
      if (enemy.id == id) return enemy.name;
    }
    return 'Gizemli';
  }

  static const _adjectives = [
    'Kızıl',
    'Kadim',
    'Gölgeli',
    'Işıltılı',
    'Demir',
    'Ayaz',
    'Fırtına',
    'Zümrüt',
    'Yakut',
    'Safir',
    'Altın',
    'Gece',
    'Şafak',
    'Ejder',
    'Gezgin',
    'Muhafız',
    'Efsunlu',
  ];

  static const _nouns = {
    'Armor': 'Zırh Hatırası',
    'Belts': 'Kemer',
    'Boots': 'Çizme',
    'Chestplates': 'Göğüslük',
    'Gloves': 'Eldiven',
    'Helmets': 'Miğfer',
    'Leggings': 'Dizlik',
    'Consumables': 'İksir',
    'Food': 'Erzak',
    'Handheld_Items': 'Silah Hatırası',
    'Hoes': 'Çapa',
    'Maces': 'Gürz',
    'Pickaxes': 'Kazma',
    'Scythes': 'Tırpan',
    'Shovels': 'Kürek',
    'Spears': 'Mızrak',
    'Swords': 'Kılıç',
    'Warhammers': 'Savaş Çekici',
    'Materials_Items': 'Malzeme',
    'Books': 'Tılsımlı Kitap',
    'Crystals': 'Kristal',
    'Dust': 'Efsun Tozu',
    'Electronics_Mechanics': 'Mekanik Parça',
    'Fish_Fishing': 'Balıkçı Hatırası',
    'Ingots': 'Külçe',
    'Keys': 'Anahtar',
    'Kitchen': 'Mutfak Hatırası',
    'Musical_Instruments': 'Çalgı',
    'Plants_Flowers': 'Şifalı Bitki',
    'Tribal_Ritual': 'Ritüel Tılsımı',
    'Mob_Drops': 'Canavar Ganimeti',
    'Eyes': 'Kâhin Gözü',
    'Feathers': 'Tüy',
    'Other_Drops': 'Yaratık Kalıntısı',
    'Special_Events': 'Etkinlik Hatırası',
    'Christmas': 'Kış Hatırası',
    'Unsorted': 'Gizemli Hatıra',
  };
}
