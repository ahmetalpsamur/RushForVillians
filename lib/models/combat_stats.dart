import 'item_effect.dart';

/// Savaşa giren **dokuz** istatistiğin tamamı.
///
/// Her birinin savaşta tam olarak ne yaptığı aşağıda yazılı; süs stat yok.
/// Motor (`core/utils/combat_engine.dart`) yalnızca bu sınıfı okur — taban,
/// ekipman, seri ve koşullu etkiler `effective_stats.dart` içinde burada
/// birleşir.
///
/// Model Kuralları #1: düz Dart, Flutter tipi yok. Diske **yazılmaz** —
/// her açılışta seviyeden, kuşanmadan ve seri birikiminden yeniden türetilir.
class CombatStats {
  /// Vuruşun ham gücü. Hasarın çıkış noktası.
  final double attack;

  /// Gelen hasarı azaltır: `azalma = savunma / (savunma + [defenseSoftening])`.
  /// Azalan getiri; hiçbir savunma değeri hasarı sıfırlayamaz.
  final double defense;

  /// Savaş canı tavanı. Macera başlarken oyuncunun canı buna eşitlenir.
  final double maxHealth;

  /// Kritik vuruş ihtimali (0..1). [luck] bunu bir miktar büyütür.
  final double critChance;

  /// Kritik vuruşun hasar çarpanına eklenen oran (0.5 = ×1,5).
  final double critDamage;

  /// Verilen hasarın bu oranı kadar can yenilenir (0..1).
  final double lifeSteal;

  /// Gelen vuruşu tamamen boşa çıkarma ihtimali (0..1). [luck] büyütür.
  final double dodge;

  /// İnisiyatif: turda kimin **önce** vurduğunu belirler. Öldürücü turlarda
  /// belirleyicidir — önce vuran, ölen tarafın karşılık vermesini engeller.
  final double speed;

  /// Şans. İki işi var: kritik ve sıyrılma ihtimaline küçük bir katkı verir
  /// ([luckToCritChance] / [luckToDodge]) ve hasar değişkenliğini kendi
  /// lehine kaydırır (yüksek şans, düşük ihtimalle kötü zar).
  final double luck;

  const CombatStats({
    this.attack = 0,
    this.defense = 0,
    this.maxHealth = 0,
    this.critChance = 0,
    this.critDamage = 0,
    this.lifeSteal = 0,
    this.dodge = 0,
    this.speed = 0,
    this.luck = 0,
  });

  static const CombatStats zero = CombatStats();

  /// Savunmanın azalan getiri sabiti. Büyüdükçe savunma zayıflar.
  ///
  /// 50 seçildi: 20. seviye düşmanın savunması (22) gelen hasarı ~%31
  /// azaltıyor, 1. seviyeninki (3) ~%6. Yani savunma hissedilir ama hiçbir
  /// zaman duvar değil.
  static const double defenseSoftening = 50;

  /// Şansın kritik ihtimaline katkısı (şans başına).
  static const double luckToCritChance = 0.002;

  /// Şansın sıyrılma ihtimaline katkısı (şans başına).
  static const double luckToDodge = 0.001;

  /// Kritik ihtimalinin tavanı. %100 kritik, kritiği anlamsız kılar.
  static const double maxCritChance = 0.6;

  /// Sıyrılma ihtimalinin tavanı. Aksi hâlde savaş bir noktada durur.
  static const double maxDodge = 0.4;

  double statFor(ItemStat stat) => switch (stat) {
    ItemStat.attack => attack,
    ItemStat.defense => defense,
    ItemStat.maxHealth => maxHealth,
    ItemStat.critChance => critChance,
    ItemStat.critDamage => critDamage,
    ItemStat.lifeSteal => lifeSteal,
    ItemStat.dodge => dodge,
    ItemStat.speed => speed,
    ItemStat.luck => luck,
    _ => 0,
  };

  CombatStats withStat(ItemStat stat, double value) => switch (stat) {
    ItemStat.attack => copyWith(attack: value),
    ItemStat.defense => copyWith(defense: value),
    ItemStat.maxHealth => copyWith(maxHealth: value),
    ItemStat.critChance => copyWith(critChance: value),
    ItemStat.critDamage => copyWith(critDamage: value),
    ItemStat.lifeSteal => copyWith(lifeSteal: value),
    ItemStat.dodge => copyWith(dodge: value),
    ItemStat.speed => copyWith(speed: value),
    ItemStat.luck => copyWith(luck: value),
    _ => this,
  };

  CombatStats copyWith({
    double? attack,
    double? defense,
    double? maxHealth,
    double? critChance,
    double? critDamage,
    double? lifeSteal,
    double? dodge,
    double? speed,
    double? luck,
  }) => CombatStats(
    attack: attack ?? this.attack,
    defense: defense ?? this.defense,
    maxHealth: maxHealth ?? this.maxHealth,
    critChance: critChance ?? this.critChance,
    critDamage: critDamage ?? this.critDamage,
    lifeSteal: lifeSteal ?? this.lifeSteal,
    dodge: dodge ?? this.dodge,
    speed: speed ?? this.speed,
    luck: luck ?? this.luck,
  );

  /// Motora girmeden önce uygulanan güvenlik kırpması.
  ///
  /// Negatif stat üretmek mümkün (çift etkili itemler eksi değer taşıyor),
  /// ama negatif saldırı ya da %100 sıyrılma savaşı anlamsız kılar.
  CombatStats sanitized() => CombatStats(
    attack: attack < 0 ? 0 : attack,
    defense: defense < 0 ? 0 : defense,
    maxHealth: maxHealth < 1 ? 1 : maxHealth,
    critChance: critChance.clamp(0, maxCritChance),
    critDamage: critDamage < 0 ? 0 : critDamage,
    lifeSteal: lifeSteal.clamp(0, 1),
    dodge: dodge.clamp(0, maxDodge),
    speed: speed < 0 ? 0 : speed,
    luck: luck < 0 ? 0 : luck,
  );

  /// Gelen hasarın savunmayla azaltılmış hâli.
  double damageAfterDefense(double rawDamage) =>
      rawDamage * (1 - defense / (defense + defenseSoftening));

  /// Şans katkısı dâhil kritik ihtimali.
  double get effectiveCritChance =>
      (critChance + luck * luckToCritChance).clamp(0, maxCritChance);

  /// Şans katkısı dâhil sıyrılma ihtimali.
  double get effectiveDodge => (dodge + luck * luckToDodge).clamp(0, maxDodge);

  @override
  String toString() =>
      'CombatStats(atk: ${attack.toStringAsFixed(1)}, '
      'def: ${defense.toStringAsFixed(1)}, '
      'hp: ${maxHealth.toStringAsFixed(1)}, '
      'crit: ${critChance.toStringAsFixed(3)}/'
      '${critDamage.toStringAsFixed(2)}, '
      'ls: ${lifeSteal.toStringAsFixed(3)}, '
      'dodge: ${dodge.toStringAsFixed(3)}, '
      'spd: ${speed.toStringAsFixed(1)}, '
      'luck: ${luck.toStringAsFixed(1)})';
}
