import '../models/item_effect.dart';

/// Elle tasarlanmış bir item'ın imzası: kural cümlesi + etkileri.
class ItemSignature {
  /// Kartta gösterilen kısa kural cümlesi. Efsanevi ve epik itemlerin
  /// karakterini bu cümle taşır.
  final String lore;

  final List<ItemEffect> effects;

  const ItemSignature({required this.lore, required this.effects});
}

/// **Elle tasarlanmış** itemlerin etkileri.
///
/// Kataloğun geri kalanı (sıradan ve az bulunur itemlerin tamamı, imzasız
/// nadirler) nadirlik + kategori kuralından türeyen sayısal bonuslar alır
/// (`item_rules.dart:buffFor`). Buradaki tablo o kuralın **istisnası**:
/// 18 efsanevi, 31 epik ve seçilmiş nadirler koşullu, tetiklenen ve çift
/// etkili — yani karakteri olan — etkiler taşır.
///
/// **Neden hepsi değil:** *her item özelse hiçbiri özel değil.* 784 el yapımı
/// etki hem bakımı imkânsız hem de efsanevileri sıradanlaştırırdı. Küçük bir
/// alt kümeyi gerçekten özel yapmak, geri kalanın sayısal olmasını da anlamlı
/// kılıyor.
///
/// **Bu tablo veridir, kod değil.** Yeni bir imzalı item eklemek = buraya bir
/// satır yazmak; hiçbir yerde `switch (item.id)` yok.
///
/// ## Denge notu — savaş statları cömert, oyun dışı statlar sıkı
///
/// Savaş istatistikleri (saldırı, savunma, kritik, can çalma) bugün **hiçbir
/// yere uygulanmıyor**; savaş motoru Aşama 4a'da yazılacak ve denge orada
/// yapılacak. Bu yüzden burada rahat davranıldı.
///
/// Oyun dışı statlar (adım parası, adım XP, çark/düşman XP) ise **bugün canlı**
/// ve ölçülmüş bir ekonomiye bağlı (bkz. `economy_pacing_test.dart`). Bu
/// yüzden hiçbir imzalı item'ın koşulsuz oyun dışı oranı
/// [GameConstants.maxSingleItemEconomyBonus] (%15) üstüne çıkmaz; kuşanılan
/// toplam da `equipped_buffs.dart` içinde
/// [GameConstants.maxEquippedEconomyBonus] (%50) ile sert şekilde kırpılır.
/// İkisi de testle bağlıdır.
class ItemEffects {
  ItemEffects._();

  /// `<kategori>/<temel ad>` → imza. Anahtar biçimi [ItemDefinitions] ile
  /// aynıdır: varyantlar da aynı satırdan beslenir.
  static const Map<String, ItemSignature> entries = {
    // ────────────────────────── EFSANEVİ (18) ──────────────────────────
    'arch/meteor_strike_arrow': ItemSignature(
      lore:
          'Gökten düşerken tutuşan bir taştan yontuldu; hâlâ soğumadı ve '
          'hedefini bulduğunda gökyüzünü bir kez daha yarar.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 46),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 0.9,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.15,
          customLabel:
              'vuruşta %15 ihtimalle göktaşı düşer: kritik hasarı +%90',
        ),
        ItemEffect(stat: ItemStat.stepXp, value: 0.1),
      ],
    ),
    'arch/tsunami_arrow': ItemSignature(
      lore:
          'Ucunda bir okyanus tutulu. Serbest kaldığında geri çekilen su, '
          'yaraları da beraberinde götürür.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 38),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.14,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.25,
        ),
        ItemEffect.flat(stat: ItemStat.dailyCoinCap, value: 60),
      ],
    ),
    'arch/voice_of_nature_bow': ItemSignature(
      lore:
          'Kirişi tek bir ağacın son dalından örüldü. Karanlıkta çekildiğinde '
          'ormanın uyanık olduğu duyulur.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 34),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.2,
          trigger: ItemEffectTrigger.nightWalk,
        ),
        ItemEffect(stat: ItemStat.stepXp, value: 0.12),
        ItemEffect.flat(stat: ItemStat.wheelSpinCap, value: 1),
      ],
    ),
    'magic/dragons_spell_book': ItemSignature(
      lore:
          'Sayfaları bir ejderhanın kanadından; kitap ancak sahibi yaralıyken '
          'kendi kendine açılır.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.4),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.55,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.3,
        ),
        ItemEffect(stat: ItemStat.wheelXp, value: 0.15),
      ],
    ),
    'scythes/reapers_scythe': ItemSignature(
      lore:
          'Kimin tuttuğunu değil, kimin biçildiğini sayar. Her hasat onu '
          'biraz daha keskinleştirir.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 52),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.35,
          trigger: ItemEffectTrigger.onKill,
          customLabel: 'düşman yenince kaybettiğin canın %35\'i geri gelir',
        ),
        ItemEffect(stat: ItemStat.enemyXp, value: 0.15),
        ItemEffect(stat: ItemStat.defense, value: -0.2),
      ],
    ),
    'shields/black_hole_shield': ItemSignature(
      lore:
          'Vurulan hiçbir şey geri dönmez; darbeler kalkanın ortasındaki '
          'sessizliğe düşer ve kaybolur.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.6),
        ItemEffect.flat(stat: ItemStat.maxHealth, value: 40),
        ItemEffect(
          stat: ItemStat.dodge,
          value: 0.3,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 3,
        ),
        ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
      ],
    ),
    'spears/legendary_spear': ItemSignature(
      lore:
          'Kırılmadan önce üç ordu devirdi, kırıldıktan sonra dördüncüsünü. '
          'Uzaklık onun için bir mazeret değil.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 44),
        ItemEffect(
          stat: ItemStat.critChance,
          value: 0.28,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 3,
        ),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.13),
      ],
    ),
    'swords/dragons_hook': ItemSignature(
      lore:
          'Üç ejderha kanıyla su verildi. Sıcaklığını kaybetmez; kabzasını '
          'tutan el bunu ilk gün anlar.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.5),
        ItemEffect(stat: ItemStat.defense, value: -0.18),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 0.6,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.35,
        ),
        ItemEffect(stat: ItemStat.enemyXp, value: 0.14),
      ],
    ),

    'magic/eldritch_gods_holy_book': ItemSignature(
      lore:
          'Hiçbir dua yazılı değil; sayfalar okuyanın sormaya cesaret '
          'edemediği soruyu gösterir.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.45),
        ItemEffect(stat: ItemStat.maxHealth, value: -0.15),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 0.8,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.25,
        ),
        ItemEffect(stat: ItemStat.wheelXp, value: 0.15),
      ],
    ),
    'magic/sages_hidden_book': ItemSignature(
      lore:
          'Bilge onu kimseden değil, kendinden sakladı. Öğrendiği her şey '
          'burada duruyor.',
      effects: [
        ItemEffect(stat: ItemStat.stepXp, value: 0.15),
        ItemEffect(stat: ItemStat.enemyXp, value: 0.15),
        ItemEffect.flat(stat: ItemStat.attack, value: 24),
        ItemEffect(
          stat: ItemStat.critChance,
          value: 0.25,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 2,
        ),
      ],
    ),
    'magic/spirits_ancient_book': ItemSignature(
      lore:
          'Kapağını açan, bir daha yalnız yürüyemez. Ruhlar yolu sayar ve '
          'kaçırılan günü onlar hatırlar.',
      effects: [
        ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 2),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 600),
        ItemEffect(stat: ItemStat.attack, value: 0.32),
      ],
    ),
    'magic/star_fusion_spell_book': ItemSignature(
      lore:
          'İki yıldızı aynı sayfada birleştirir. Sonucu kimse iki kez aynı '
          'göremedi.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 40),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 1,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.1,
          customLabel:
              'vuruşta %10 ihtimalle iki yıldız çakışır: '
              'kritik hasarı +%100',
        ),
        ItemEffect(stat: ItemStat.wheelXp, value: 0.14),
      ],
    ),
    'magic/time_wardens_book': ItemSignature(
      lore:
          'Geçen günü değil, kaçırılan günü tutar. Defterde herkesin bir '
          'borcu var.',
      effects: [
        ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
        ItemEffect.flat(stat: ItemStat.wheelSpinCap, value: 1),
        ItemEffect(stat: ItemStat.stepXp, value: 0.14),
        ItemEffect(
          stat: ItemStat.dodge,
          value: 0.35,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 3,
        ),
      ],
    ),
    'magic/underworld_records_book': ItemSignature(
      lore:
          'Aşağıda tutulan tek kayıt: kimin ne kadar yürüdüğü. Sicili temiz '
          'olan daha çok kazanır.',
      effects: [
        ItemEffect.flat(stat: ItemStat.dailyCoinCap, value: 120),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.15,
          trigger: ItemEffectTrigger.streakActive,
        ),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.1),
      ],
    ),
    'ranged_other/wind_spirit_boomerang': ItemSignature(
      lore:
          'Atıldığı yere değil, sahibinin olması gereken yere döner. Gece '
          'daha uzağa gider.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 36),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.25,
          trigger: ItemEffectTrigger.nightWalk,
        ),
        ItemEffect(stat: ItemStat.dodge, value: 0.25),
        ItemEffect.flat(stat: ItemStat.wheelSpinCap, value: 1),
      ],
    ),
    'shields/black_dragon_scale_shield': ItemSignature(
      lore:
          'Tek bir puldan yapıldı. Ejderhanın geri kalanı hâlâ o pulu arıyor.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.55),
        ItemEffect.flat(stat: ItemStat.maxHealth, value: 45),
        ItemEffect(stat: ItemStat.enemyXp, value: 0.15),
      ],
    ),
    'shields/cause_and_effect_shield': ItemSignature(
      lore:
          'Vurduğun her darbe sana da yazılır; kalkan yalnızca sırayı '
          'hatırlatır.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.42),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.5,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.4,
          customLabel:
              'can %40 altındayken alınan her darbe geri döner: '
              'saldırı +%50',
        ),
        ItemEffect(stat: ItemStat.stepXp, value: 0.12),
      ],
    ),
    'shields/soul_trapping_shield': ItemSignature(
      lore:
          'Durdurduğu darbenin sahibini de durdurur. İçinde kaç ses olduğunu '
          'kimse saymadı.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.48),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.4,
          trigger: ItemEffectTrigger.onKill,
          customLabel:
              'düşman yenince ruhu hapsedilir: canın %40\'ı geri gelir',
        ),
        ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
      ],
    ),

    // ──────────────────────────── EPİK (31) ────────────────────────────
    'magic/frost_queen_spell_book': ItemSignature(
      lore: 'Sayfaları birbirine donmuş; yalnızca sırası gelen açılır.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.28),
        ItemEffect(stat: ItemStat.attack, value: 0.24),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 300),
      ],
    ),
    'ranged_other/molten_throwing_axe': ItemSignature(
      lore: 'Fırlatıldığında soğumaz, döndüğünde tutulamaz.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 33),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 0.5,
          trigger: ItemEffectTrigger.onKill,
        ),
        ItemEffect(stat: ItemStat.defense, value: -0.12),
      ],
    ),
    'shields/full_plate_coffin_shield': ItemSignature(
      lore: 'Arkasına saklanan çıkmak istemez; kalkan da ısrar etmez.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.4),
        ItemEffect.flat(stat: ItemStat.maxHealth, value: 28),
        ItemEffect(stat: ItemStat.dodge, value: -0.15),
      ],
    ),
    'shields/ocean_fountain_shield': ItemSignature(
      lore: 'Yüzeyinden hiç durmadan su akar; yaraları da yıkar.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.3),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.15,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 2,
        ),
        ItemEffect.flat(stat: ItemStat.dailyCoinCap, value: 55),
      ],
    ),
    'arch/energy_bow': ItemSignature(
      lore: 'Kirişi yok; çekilen şey yayın kendi öfkesi.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 26),
        ItemEffect(stat: ItemStat.critChance, value: 0.16),
        ItemEffect(stat: ItemStat.stepXp, value: 0.09),
      ],
    ),
    'arch/energy_crossbow': ItemSignature(
      lore: 'Kurulması bir nefes, boşalması bir şimşek sürer.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 30),
        ItemEffect(stat: ItemStat.critDamage, value: 0.35),
        ItemEffect(stat: ItemStat.dodge, value: -0.1),
      ],
    ),
    'arch/mech_bow': ItemSignature(
      lore: 'Dişlileri nişan alır, sahibi yalnızca yönü söyler.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 22),
        ItemEffect(
          stat: ItemStat.critChance,
          value: 0.22,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 2,
        ),
        ItemEffect.flat(stat: ItemStat.dailyCoinCap, value: 45),
      ],
    ),
    'arch/turkish_bow': ItemSignature(
      lore: 'Menzili değil sabrı ölçülür; yolun sonunu bekleyen bir yaydır.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 24),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.14,
          trigger: ItemEffectTrigger.streakActive,
        ),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.08),
      ],
    ),
    'arch/volcanic_bow': ItemSignature(
      lore: 'Gövdesi hâlâ akan bir dağdan koparıldı; ok atmadan da yakar.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 28),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.3,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.2,
          customLabel: 'vuruşta %20 ihtimalle alev alır: saldırı +%30',
        ),
        ItemEffect(stat: ItemStat.defense, value: -0.12),
      ],
    ),
    'axes_halberds/volcanic_axe': ItemSignature(
      lore: 'İki elle kaldırılır, tek darbede iner. Ağırlığı bir cezadır.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 34),
        ItemEffect(stat: ItemStat.critDamage, value: 0.45),
        ItemEffect(stat: ItemStat.dodge, value: -0.15),
      ],
    ),
    'maces_hammers/frost_chain_mace': ItemSignature(
      lore: 'Zinciri savrulurken donar; değdiği yer bir tur boyunca ısınmaz.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 25),
        ItemEffect.flat(stat: ItemStat.defense, value: 14),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 300),
      ],
    ),
    'magic/demons_staff': ItemSignature(
      lore: 'Bir pazarlıkla geldi. Verdiği gücün faizini canından keser.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.42),
        ItemEffect(stat: ItemStat.maxHealth, value: -0.18),
        ItemEffect(stat: ItemStat.wheelXp, value: 0.12),
      ],
    ),
    'magic/forest_heart': ItemSignature(
      lore: 'Kökleri hâlâ toprağı arar; taşıyan kişiyi yürüdükçe besler.',
      effects: [
        ItemEffect.flat(stat: ItemStat.maxHealth, value: 30),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.12,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 2,
        ),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 400),
      ],
    ),
    'magic/frost_queen_staff': ItemSignature(
      lore: 'Sahibi üşümez, çevresindekiler ısınamaz.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.3),
        ItemEffect(stat: ItemStat.defense, value: 0.24),
        ItemEffect(stat: ItemStat.wheelXp, value: 0.14),
      ],
    ),
    'magic/mechanoid_spell_book': ItemSignature(
      lore: 'Büyüyü ezberlemez, hesaplar. Yanılma payı bırakmaz.',
      effects: [
        ItemEffect(stat: ItemStat.critChance, value: 0.2),
        ItemEffect(stat: ItemStat.critDamage, value: 0.3),
        ItemEffect(stat: ItemStat.stepXp, value: 0.11),
      ],
    ),
    'magic/meteor_spell_card': ItemSignature(
      lore: 'Tek kullanımlık gibi görünür; her seferinde bir kez daha yanar.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 32),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 0.7,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.12,
        ),
        ItemEffect(stat: ItemStat.defense, value: -0.14),
      ],
    ),
    'magic/volcanic_staff': ItemSignature(
      lore: 'Ucundaki taş sönmedi; asayı yere bırakmak da onu söndürmez.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.36),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.25,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.4,
        ),
        ItemEffect(stat: ItemStat.wheelXp, value: 0.1),
      ],
    ),
    'ranged_other/magma_drop': ItemSignature(
      lore: 'Avucunda taşınır, düştüğü yerde bir gün boyunca iz bırakır.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 27),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.28,
          trigger: ItemEffectTrigger.onKill,
          customLabel: 'düşman yenince bir sonraki tur saldırı +%28',
        ),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.1),
      ],
    ),
    'ranged_other/mech_kunai': ItemSignature(
      lore: 'Atıldıktan sonra geri döner; sahibi geri dönmesini beklemez.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 21),
        ItemEffect(stat: ItemStat.dodge, value: 0.18),
        ItemEffect.flat(stat: ItemStat.dailyCoinCap, value: 50),
      ],
    ),
    'shields/dragon_head_shield': ItemSignature(
      lore: 'Kalkanın ağzı hâlâ kapanmıyor; ilk darbeyi o karşılar.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.38),
        ItemEffect.flat(stat: ItemStat.maxHealth, value: 26),
        ItemEffect(stat: ItemStat.enemyXp, value: 0.12),
      ],
    ),
    'shields/energy_shield': ItemSignature(
      lore: 'Ağırlığı yok, bu yüzden yorulmaz. Sahibi de öyle sanır.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.3),
        ItemEffect(stat: ItemStat.dodge, value: 0.2),
        ItemEffect(stat: ItemStat.maxHealth, value: -0.1),
      ],
    ),
    'shields/holy_shield': ItemSignature(
      lore: 'Kırılmaz demezler; taşıyanı yalnız bırakmaz derler.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.34),
        ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 350),
      ],
    ),
    'shields/vampiric_shield': ItemSignature(
      lore: 'Savunmak için değil, beslenmek için tutulur.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.26),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.18,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.3,
        ),
        ItemEffect(stat: ItemStat.maxHealth, value: -0.08),
      ],
    ),
    'shields/volcanic_shield': ItemSignature(
      lore: 'Vuran el geri çekildiğinde artık aynı el değildir.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.32),
        ItemEffect.flat(stat: ItemStat.attack, value: 16),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.09),
      ],
    ),
    'spears/sea_trident': ItemSignature(
      lore: 'Üç uç, üç ayrı derinlik. Hangisinin değdiği sonradan anlaşılır.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 29),
        ItemEffect(stat: ItemStat.critChance, value: 0.14),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.11),
      ],
    ),
    'spears/vampires_spear': ItemSignature(
      lore: 'Ucu her zaman ıslak. Kimse onu temizlerken görmedi.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 31),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.2,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.5,
        ),
        ItemEffect(stat: ItemStat.defense, value: -0.1),
      ],
    ),
    'spears/volcanic_trident': ItemSignature(
      lore: 'Saplandığı yerden duman çıkar; çekildiğinde de durmaz.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 33),
        ItemEffect(stat: ItemStat.critDamage, value: 0.4),
        ItemEffect(stat: ItemStat.dodge, value: -0.12),
      ],
    ),
    'swords/double_blade_gauntlet': ItemSignature(
      lore: 'İki ağız, tek bilek. Savunmayı kimse ona sormadı.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.35),
        ItemEffect(stat: ItemStat.defense, value: -0.15),
        ItemEffect(stat: ItemStat.critChance, value: 0.18),
      ],
    ),
    'swords/fire_gem_greatsword': ItemSignature(
      lore: 'Kabzasındaki taş, sahibinin nabzıyla parlar. Yorulunca söner.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 36),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.3,
          trigger: ItemEffectTrigger.highHealth,
          threshold: 0.7,
        ),
        ItemEffect(stat: ItemStat.stepXp, value: 0.1),
      ],
    ),
    'swords/forest_blessing_blade': ItemSignature(
      lore: 'Kınından çıkarken yaprak sesi duyulur; ormana borcu vardır.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 24),
        ItemEffect.flat(stat: ItemStat.maxHealth, value: 22),
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.15,
          trigger: ItemEffectTrigger.nightWalk,
        ),
      ],
    ),
    'swords/holy_greatsword': ItemSignature(
      lore: 'Ağırlığını yalnızca kaldırmayı hak eden hisseder.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 30),
        ItemEffect(stat: ItemStat.defense, value: 0.2),
        ItemEffect(stat: ItemStat.enemyXp, value: 0.13),
      ],
    ),

    // ─────────────── SEÇİLMİŞ NADİRLER (imzalı alt küme) ───────────────
    'arch/knockback_arrow': ItemSignature(
      lore: 'Delmek için değil, geri itmek için yapıldı.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 12),
        ItemEffect(
          stat: ItemStat.dodge,
          value: 0.15,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.25,
        ),
      ],
    ),
    'arch/wind_arrow': ItemSignature(
      lore: 'Hedefi rüzgâr seçer, okçu yalnızca izin verir.',
      effects: [
        ItemEffect(stat: ItemStat.critChance, value: 0.12),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.08),
      ],
    ),
    'magic/frost_wave_spell_card': ItemSignature(
      lore: 'Okunduğunda oda değil, zaman soğur.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.2),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 250),
      ],
    ),
    'magic/mana_fusion_spell_card': ItemSignature(
      lore: 'İki büyüyü birleştirir; hangisi baskın çıkacak, kart bilmez.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.28),
        ItemEffect(stat: ItemStat.maxHealth, value: -0.12),
      ],
    ),
    'ranged_other/nights_chakram': ItemSignature(
      lore: 'Gündüz sıradan bir halka, gece bambaşka bir şey.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 14),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.14,
          trigger: ItemEffectTrigger.nightWalk,
        ),
      ],
    ),
    'ranged_other/poison_dart': ItemSignature(
      lore: 'Küçük yara, uzun hesap.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 10),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.22,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.3,
          customLabel: 'vuruşta %30 ihtimalle zehir işler: saldırı +%22',
        ),
      ],
    ),
    'shields/forest_barrier_shield': ItemSignature(
      lore: 'Bir çitten çok bir söz; ormanın içinde geçerlidir.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.18),
        ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
      ],
    ),
    'shields/frost_shield': ItemSignature(
      lore: 'Vurulduğu yerde çatlar, bir sonraki turda kendini onarır.',
      effects: [
        ItemEffect.flat(stat: ItemStat.maxHealth, value: 18),
        ItemEffect(
          stat: ItemStat.defense,
          value: 0.22,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 2,
        ),
      ],
    ),
    'swords/aqua_sword': ItemSignature(
      lore: 'Su gibi akar; tutulduğu yerden değil, değdiği yerden anlaşılır.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.22),
        ItemEffect(stat: ItemStat.dodge, value: 0.12),
      ],
    ),
    'swords/dark_dagger': ItemSignature(
      lore: 'Arkadan gelmek için değil, hiç görünmemek için yapıldı.',
      effects: [
        ItemEffect(stat: ItemStat.critChance, value: 0.2),
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.12,
          trigger: ItemEffectTrigger.nightWalk,
        ),
      ],
    ),
    'swords/spider_sword': ItemSignature(
      lore: 'Ağını kendi örer; sabırlı olanı bekler.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 15),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 0.35,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 3,
        ),
      ],
    ),
    'swords/big_blade_gauntlet': ItemSignature(
      lore: 'Kalkan tutacak elin kalmadığı gün takılır.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.26),
        ItemEffect(stat: ItemStat.defense, value: -0.1),
      ],
    ),
  };

  static ItemSignature? of(String baseId) => entries[baseId];
}
