import '../models/item.dart';
import '../models/item_effect.dart';
import '../models/reward_rarity.dart';

/// Arketip sisteminin **veri katmanı**.
///
/// `item_rules.dart` yalnızca bu tabloları okur; hiçbir yerde `switch (id)`
/// yoktur. Yeni bir arketip ya da yeni bir denge değeri gerektiğinde
/// dokunulacak tek yer burasıdır.
///
/// ## Neden arketip var
///
/// Arketipten önce bir item'ın bonusu yalnızca **nadirlik + kategori +
/// sınıf**tan türüyordu. Sonuç: aynı sınıfın bütün sıradan kılıçları birebir
/// aynı bonusu veriyordu (sıradan itemde tek bonus vardı ve o da her zaman
/// sınıfın imzasıydı). Oyuncunun iki kılıç arasında yapacağı seçim "hangisi
/// daha güzel görünüyor"dan ibaret kalıyordu.
///
/// Arketip, item'ın **kendi kimliğinden** türeyen bir karakter veriyor:
/// aynı bütçe farklı dağılıyor. Bir kılıç vurucu, öbürü düellocu olabiliyor.
class ItemArchetypes {
  ItemArchetypes._();

  /// Rolün arketip çarkı. Çekiliş bu listeden yapılır, yani **tekrar =
  /// ağırlık**: yakın dövüş kategorilerinde vurucu dört kat daha olası.
  ///
  /// **Dört arketip de her rolde bulunur.** Rol yalnızca sıklığı belirliyor:
  /// kalkanların çoğu muhafız, ama nadiren çevik bir kalkan da çıkıyor. İlk
  /// tasarımda menzil çarkında muhafız yoktu ve sıradan menzilli itemler
  /// yalnızca üç farklı savaş statı üretebiliyordu — çeşitlilik ölçümü bunu
  /// yakaladı.
  static const Map<ItemRole, List<ItemArchetype>> wheel = {
    ItemRole.melee: [
      ItemArchetype.striker,
      ItemArchetype.striker,
      ItemArchetype.striker,
      ItemArchetype.striker,
      ItemArchetype.duelist,
      ItemArchetype.duelist,
      ItemArchetype.guardian,
      ItemArchetype.swift,
    ],
    ItemRole.ranged: [
      ItemArchetype.duelist,
      ItemArchetype.duelist,
      ItemArchetype.duelist,
      ItemArchetype.swift,
      ItemArchetype.swift,
      ItemArchetype.swift,
      ItemArchetype.striker,
      ItemArchetype.guardian,
    ],
    ItemRole.defense: [
      ItemArchetype.guardian,
      ItemArchetype.guardian,
      ItemArchetype.guardian,
      ItemArchetype.guardian,
      ItemArchetype.swift,
      ItemArchetype.swift,
      ItemArchetype.duelist,
      ItemArchetype.striker,
    ],
    ItemRole.magic: [
      ItemArchetype.duelist,
      ItemArchetype.duelist,
      ItemArchetype.duelist,
      ItemArchetype.swift,
      ItemArchetype.swift,
      ItemArchetype.striker,
      ItemArchetype.striker,
      ItemArchetype.guardian,
    ],
  };

  /// Arketipin savaş statlarını verme sırası. Birincil stat en büyük payı
  /// alır; item'ın "ne yaptığı" tek bakışta anlaşılsın.
  static const Map<ItemArchetype, List<ItemStat>> combatStats = {
    ItemArchetype.striker: [
      ItemStat.attack,
      ItemStat.critDamage,
      ItemStat.maxHealth,
    ],
    ItemArchetype.guardian: [
      ItemStat.defense,
      ItemStat.maxHealth,
      ItemStat.attack,
    ],
    ItemArchetype.duelist: [
      ItemStat.critChance,
      ItemStat.critDamage,
      ItemStat.lifeSteal,
    ],
    ItemArchetype.swift: [ItemStat.dodge, ItemStat.critChance, ItemStat.attack],
  };

  /// Arketipin **ekonomi** bütçesi çarpanı.
  ///
  /// Hepsi 1.0 ya da altında: arketip sistemi ekonomiyi hiçbir koşulda
  /// bugünkünün üstüne çıkarmamalı (`economy_pacing_test.dart` bugünkü
  /// dengeyi ölçüyor). Saldırıya eğilimli item ekonomiden kırpar, dengeli
  /// olan kırpmaz — bu da gerçek bir tercih üretiyor.
  static const Map<ItemArchetype, double> economyTilt = {
    ItemArchetype.striker: 0.85,
    ItemArchetype.duelist: 0.90,
    ItemArchetype.guardian: 1.0,
    ItemArchetype.swift: 1.0,
  };

  /// Arketipin **savaş** bütçesi çarpanı. Ekonomiden kırpan arketip savaşta
  /// kazanır; toplam güç kabaca sabit kalır, dağılımı değişir.
  static const Map<ItemArchetype, double> combatTilt = {
    ItemArchetype.striker: 1.20,
    ItemArchetype.duelist: 1.10,
    ItemArchetype.guardian: 1.0,
    ItemArchetype.swift: 0.95,
  };

  /// Nadirliğin **ekonomi** bonus sayısı (bugün canlı olan statlar).
  static int economyCount(RewardRarity rarity) => switch (rarity) {
    RewardRarity.common => 1,
    RewardRarity.uncommon => 2,
    RewardRarity.rare => 2,
    RewardRarity.epic => 3,
    RewardRarity.legendary => 3,
  };

  /// Nadirliğin **savaş** stat sayısı (Aşama 4a'da canlanacak).
  static int combatCount(RewardRarity rarity) => switch (rarity) {
    RewardRarity.common => 1,
    RewardRarity.uncommon => 1,
    RewardRarity.rare => 2,
    RewardRarity.epic => 2,
    RewardRarity.legendary => 3,
  };

  /// Nadirliğin soyut savaş gücü bütçesi. Statlara [combatSpec] ile çevrilir.
  ///
  /// Savaş statları bugün **uygulanmıyor** (savaş motoru Aşama 4a), bu yüzden
  /// cömert olmak bedava (GD24). Yine de elle tasarlanmış imzalı itemlerin
  /// (`item_effects.dart`) altında kalıyor: en üst katman kuraldan türeyen
  /// hiçbir item tarafından geçilmemeli.
  static double combatBudget(RewardRarity rarity) => switch (rarity) {
    RewardRarity.common => 9,
    RewardRarity.uncommon => 18,
    RewardRarity.rare => 32,
    RewardRarity.epic => 55,
    RewardRarity.legendary => 90,
  };

  /// Savaş bütçesinin statlara dağılımı. Ekonomi tarafıyla aynı desen.
  static List<double> combatShares(int count) => switch (count) {
    1 => const [1.0],
    2 => const [0.65, 0.35],
    _ => const [0.5, 0.3, 0.2],
  };

  /// Savaş statının gösterim biçimi ve bütçe → değer çarpanı.
  ///
  /// `flat` olanlar ham sayı (`+13 saldırı`), `percent` olanlar oran
  /// (`+%6,5 savunma`).
  static const Map<ItemStat, (ItemEffectMode, double)> combatSpec = {
    ItemStat.attack: (ItemEffectMode.flat, 0.62),
    ItemStat.maxHealth: (ItemEffectMode.flat, 1.3),
    ItemStat.defense: (ItemEffectMode.percent, 0.0072),
    ItemStat.critChance: (ItemEffectMode.percent, 0.0030),
    ItemStat.critDamage: (ItemEffectMode.percent, 0.0110),
    ItemStat.lifeSteal: (ItemEffectMode.percent, 0.0026),
    ItemStat.dodge: (ItemEffectMode.percent, 0.0030),
  };

  /// Ekonomi türü çekilişinin ağırlıkları.
  ///
  /// Sınıf imzası ezici değil ama **açık ara en olası** tür: bir sınıfın
  /// itemlerinin kabaca yarısında birincil bonus odur. Böylece sınıf kimliği
  /// korunuyor ama her item aynı olmuyor.
  static const int signatureWeight = 8;

  /// Kategori rolünün eğilim listesindeki ilk üç türün ek ağırlığı.
  static const List<int> roleWeights = [4, 2, 1];

  /// Her türün taban ağırlığı: hiçbir tür tamamen elenmiyor.
  static const int baseWeight = 1;
}
