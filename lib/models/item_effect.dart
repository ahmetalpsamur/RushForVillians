/// Bir item efektinin dokunduğu istatistik.
///
/// İki kümeye ayrılır ve ayrım [ItemStatX.isCombat] üzerinden okunur:
///
/// - **Savaş statları** (saldırı, savunma, kritik...) bugün **hiçbir yere
///   uygulanmıyor**; savaş motoru Aşama 4a'da yazılacak. Modelde şimdiden
///   duruyorlar ki item tasarımı savaş sistemini beklemek zorunda kalmasın —
///   dengeleri orada yapılacak.
/// - **Oyun dışı statlar** (adım parası, adım XP, tavanlar...) **bugün canlı**
///   ve dikkatle dengelenmiş bir ekonomiye bağlı. Bu yüzden tek bir item'ın
///   koşulsuz oyun dışı yüzdesi [GameConstants.maxSingleItemEconomyBonus] ile,
///   kuşanılan toplam ise [GameConstants.maxEquippedEconomyBonus] ile
///   sınırlıdır.
enum ItemStat {
  // --- Savaş: Aşama 4a'da canlanacak ---
  attack,
  defense,
  maxHealth,
  critChance,
  critDamage,
  lifeSteal,
  dodge,

  // --- Oyun dışı: bugün canlı ---
  stepCoin,
  stepXp,
  wheelXp,
  enemyXp,
  dailyCoinCap,
  streakFreezeCap,
  wheelSpinCap,
  streakRelief,
}

extension ItemStatX on ItemStat {
  String get label => switch (this) {
    ItemStat.attack => 'saldırı',
    ItemStat.defense => 'savunma',
    ItemStat.maxHealth => 'savaş canı',
    ItemStat.critChance => 'kritik şansı',
    ItemStat.critDamage => 'kritik hasarı',
    ItemStat.lifeSteal => 'can çalma',
    ItemStat.dodge => 'sıyrılma',
    ItemStat.stepCoin => 'adım parası',
    ItemStat.stepXp => 'adım XP',
    ItemStat.wheelXp => 'çark XP',
    ItemStat.enemyXp => 'düşman XP',
    ItemStat.dailyCoinCap => 'günlük coin sınırı',
    ItemStat.streakFreezeCap => 'dondurma stoğu',
    ItemStat.wheelSpinCap => 'çark hakkı stoğu',
    ItemStat.streakRelief => 'seri eşiği',
  };

  /// Savaş motoruna ait mi (Aşama 4a). `false` olanlar bugün uygulanıyor.
  bool get isCombat => switch (this) {
    ItemStat.attack ||
    ItemStat.defense ||
    ItemStat.maxHealth ||
    ItemStat.critChance ||
    ItemStat.critDamage ||
    ItemStat.lifeSteal ||
    ItemStat.dodge => true,
    _ => false,
  };

  /// Ekonomiye doğrudan dokunan oran statları. Tek item ve kuşanılan toplam
  /// tavanları yalnızca bunlara uygulanır.
  bool get isEconomyRate => switch (this) {
    ItemStat.stepCoin ||
    ItemStat.stepXp ||
    ItemStat.wheelXp ||
    ItemStat.enemyXp => true,
    _ => false,
  };

  /// Değeri artı olmasına rağmen kullanıcıya **eksi** olarak gösterilen stat.
  /// Seri eşiği düşürüldükçe iyileşir; "+500 adım" yazmak yanlış olurdu.
  bool get isReduction => this == ItemStat.streakRelief;

  /// Sayısal (flat) gösterimde değerin arkasına eklenen birim.
  String get flatUnit => switch (this) {
    ItemStat.streakRelief => ' adım',
    ItemStat.dailyCoinCap => '',
    _ => '',
  };
}

/// Efektin değeri nasıl okunacak.
enum ItemEffectMode {
  /// Sabit artış: `+12 saldırı`.
  flat,

  /// Yüzdesel artış: `0.18` → `+%18`.
  percent,
}

/// Efektin ne zaman çalıştığı.
///
/// [always] dışındaki her tetikleyici **koşulludur**: [ItemBuff]'ın türetilmiş
/// sayısal getter'ları (ve dolayısıyla ekonomi çarpanları) yalnızca [always] +
/// tam ihtimalli efektleri toplar. Koşullu bir efekt kullanıcıya gösterilir
/// ama kuşanıldığı anda pasif bir çarpana dönüşmez.
enum ItemEffectTrigger {
  /// Kuşanıldığı sürece geçerli.
  always,

  /// Savaş canı eşiğin **altında**yken (Aşama 4a).
  lowHealth,

  /// Savaş canı eşiğin **üstünde**yken (Aşama 4a).
  highHealth,

  /// Her vuruşta, [ItemEffect.chance] ihtimalle (Aşama 4a).
  onHit,

  /// Düşman yenildiğinde (Aşama 4a; düşman XP dalı bugün de var).
  onKill,

  /// Arka arkaya [ItemEffect.threshold] tur hasar alınmadıysa (Aşama 4a).
  untouchedRounds,

  /// Gece yürüyüşlerinde (gün sınırından önceki karanlık saatler).
  nightWalk,

  /// Günlük seri ayaktayken.
  streakActive,
}

/// Bir item'ın taşıdığı **tek** etki.
///
/// Efektler veriyle tanımlanır ([ItemEffects] tablosu) ya da nadirlik +
/// kategori kuralından türetilir (`item_rules.dart:buffFor`); her yeni item
/// için kod yazılmaz.
///
/// Model Kuralları #1: burada hiçbir Flutter tipi yok. Efektler diske de
/// yazılmaz — kalıcı olan tek şey [Item.id] ve efektler her açılışta
/// katalogdan yeniden çözülür.
class ItemEffect {
  final ItemStat stat;
  final ItemEffectMode mode;

  /// [ItemEffectMode.percent] için oran (0.18 = %18), [ItemEffectMode.flat]
  /// için ham sayı. **Eksi olabilir**: çift etkili itemler bir artı bir eksi
  /// taşır (ör. `+%35 saldırı, -%15 savunma`).
  final double value;

  final ItemEffectTrigger trigger;

  /// Tetiklenme ihtimali (0..1). Yalnızca [ItemEffectTrigger.onHit] gibi
  /// tetiklenen efektlerde 1'den küçüktür.
  final double chance;

  /// Tetikleyicinin eşiği. Can tetikleyicilerinde oran (0.30 = %30),
  /// [ItemEffectTrigger.untouchedRounds] için tur sayısı.
  final double threshold;

  /// Etiketi tamamen değiştiren serbest metin.
  ///
  /// Elle tasarlanmış efektlerde, üretilen cümlenin bozuk ya da anlamsız
  /// kaldığı durumlar için. Yine **veri**dir; kod değil.
  final String? customLabel;

  const ItemEffect({
    required this.stat,
    required this.value,
    this.mode = ItemEffectMode.percent,
    this.trigger = ItemEffectTrigger.always,
    this.chance = 1,
    this.threshold = 0,
    this.customLabel,
  });

  /// Sabit artış kısayolu.
  const ItemEffect.flat({
    required this.stat,
    required this.value,
    this.trigger = ItemEffectTrigger.always,
    this.chance = 1,
    this.threshold = 0,
    this.customLabel,
  }) : mode = ItemEffectMode.flat;

  /// Koşulsuz ve tam ihtimalli mi. Ekonomi çarpanlarına yalnızca bunlar girer.
  bool get isPassive => trigger == ItemEffectTrigger.always && chance >= 1;

  /// Savaş motoru gelene kadar etkisiz mi (Aşama 4a).
  bool get isDormant => stat.isCombat;

  /// Aynı efektin [value] değeri değiştirilmiş kopyası.
  ItemEffect scaled(double factor) => ItemEffect(
    stat: stat,
    value: value * factor,
    mode: mode,
    trigger: trigger,
    chance: chance,
    threshold: threshold,
    customLabel: customLabel,
  );

  /// Değeri [limit] ile sınırlanmış kopya (işareti korunur).
  ItemEffect clampedTo(double limit) {
    if (value.abs() <= limit) return this;
    return scaled(limit / value.abs());
  }

  /// Kullanıcıya gösterilen tam satır.
  String get label {
    final custom = customLabel;
    if (custom != null) return custom;
    return '$_triggerPrefix${stat.label} $_valueText';
  }

  String get _triggerPrefix => switch (trigger) {
    ItemEffectTrigger.always => '',
    ItemEffectTrigger.lowHealth =>
      'can %${_plain(threshold * 100)} altındayken ',
    ItemEffectTrigger.highHealth =>
      'can %${_plain(threshold * 100)} üstündeyken ',
    ItemEffectTrigger.onHit => 'vuruşta %${_plain(chance * 100)} ihtimalle ',
    ItemEffectTrigger.onKill => 'düşman yenince ',
    ItemEffectTrigger.untouchedRounds =>
      '${_plain(threshold)} tur hasarsız kalınca ',
    ItemEffectTrigger.nightWalk => 'gece yürüyüşlerinde ',
    ItemEffectTrigger.streakActive => 'serin ayaktayken ',
  };

  String get _valueText {
    // Seri eşiği düştükçe iyileşir; artı değeri eksi olarak yazmak doğru.
    final sign = (value < 0) != stat.isReduction ? '-' : '+';
    final magnitude = value.abs();
    if (mode == ItemEffectMode.percent) {
      return '$sign%${formatPercent(magnitude)}';
    }
    return '$sign${_plain(magnitude)}${stat.flatUnit}';
  }

  /// `0.075` → `7,5`, `0.07` → `7`. Yarım yüzdeler saklanmaz, gösterilir.
  static String formatPercent(double value) {
    final percent = value * 100;
    final rounded = percent.round();
    if ((percent - rounded).abs() < 0.05) return '$rounded';
    return percent.toStringAsFixed(1).replaceAll('.', ',');
  }

  static String _plain(double value) {
    final rounded = value.round();
    if ((value - rounded).abs() < 0.005) return '$rounded';
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  String toString() => 'ItemEffect(${stat.name} $_valueText)';
}
