import '../models/item_effect.dart';

/// Elle tasarlanmış bir item'ın imzası: kural cümlesi + etkileri.
class ItemSignature {
  /// Kartta gösterilen kısa kural cümlesi. Efsanevi ve epik itemlerin
  /// karakterini bu cümle taşır.
  final String lore;

  /// [lore]'un İngilizcesi; elle yazılmış veri (GD89 ile aynı karar).
  /// Bölüm F'ye kadar İngilizce oyuncu 61 imzalı eşyanın hepsinde aynı
  /// jenerik cümleyi görüyordu.
  final String loreEn;

  final List<ItemEffect> effects;

  const ItemSignature({
    required this.lore,
    required this.loreEn,
    required this.effects,
  });
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
      loreEn:
          'Carved from a stone that caught fire as it fell from the sky. It '
          "still hasn't cooled, and when it finds its mark it splits the "
          'heavens one more time.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 46),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 0.9,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.15,
          customLabel:
              'vuruşta %15 ihtimalle göktaşı düşer: kritik hasarı +%90',
          customLabelEn: '15% chance on hit to call down a meteor: critical damage +90%',
        ),
        ItemEffect(stat: ItemStat.stepXp, value: 0.1),
      ],
    ),
    'arch/tsunami_arrow': ItemSignature(
      lore:
          'Ucunda bir okyanus tutulu. Serbest kaldığında geri çekilen su, '
          'yaraları da beraberinde götürür.',
      loreEn:
          'An ocean is held at its tip. Once released, the retreating water '
          'carries the wounds away with it.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 38),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.14,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.25,
        ),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.15),
      ],
    ),
    'arch/voice_of_nature_bow': ItemSignature(
      lore:
          'Kirişi tek bir ağacın son dalından örüldü. Karanlıkta çekildiğinde '
          'ormanın uyanık olduğu duyulur.',
      loreEn:
          'Its string was braided from the last branch of a single tree. Draw '
          'it in the dark and you can hear that the forest is awake.',
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
      loreEn:
          "Its pages were cut from a dragon's wing. The book opens on its own "
          'only when its owner is bleeding.',
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
      loreEn:
          'It keeps count not of who holds it, but of who falls to it. Every '
          'harvest hones it a little sharper.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 52),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.35,
          trigger: ItemEffectTrigger.onKill,
          customLabel: 'düşman yenince kaybettiğin canın %35\'i geri gelir',
          customLabelEn: 'after defeating an enemy, you recover 35% of the HP you lost',
        ),
        ItemEffect(stat: ItemStat.enemyXp, value: 0.15),
        ItemEffect(stat: ItemStat.defense, value: -0.2),
      ],
    ),
    'shields/black_hole_shield': ItemSignature(
      lore:
          'Vurulan hiçbir şey geri dönmez; darbeler kalkanın ortasındaki '
          'sessizliğe düşer ve kaybolur.',
      loreEn:
          'Nothing that strikes it ever comes back. Blows fall into the '
          'silence at its center and vanish.',
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
      loreEn:
          'It felled three armies before it broke, and a fourth one after. '
          'Distance has never been an excuse for it.',
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
      loreEn:
          'Tempered in the blood of three dragons. It never loses its heat, '
          'and the hand on its hilt learns that on the very first day.',
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
      loreEn:
          'Not a single prayer is written inside. The pages show the one '
          'question its reader never dared to ask.',
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
      loreEn:
          'The sage hid it from no one else, only from their own eyes. '
          'Everything they ever learned still waits inside.',
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
      loreEn:
          'Whoever opens its cover never walks alone again. The spirits count '
          'every step, and they remember the day you missed.',
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
      loreEn:
          'It fuses two stars on a single page. No one has ever seen the same '
          'result twice.',
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
          customLabelEn: '10% chance on hit as twin stars collide: critical damage +100%',
        ),
        ItemEffect(stat: ItemStat.wheelXp, value: 0.14),
      ],
    ),
    'magic/time_wardens_book': ItemSignature(
      lore:
          'Geçen günü değil, kaçırılan günü tutar. Defterde herkesin bir '
          'borcu var.',
      loreEn:
          'It keeps no record of the days that passed, only of the days that '
          'were missed. Everyone owes this ledger something.',
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
      loreEn:
          'The only record kept down below: who walked, and how far. The '
          'cleaner your record, the more you earn.',
      effects: [
        ItemEffect(stat: ItemStat.stepXp, value: 0.15),
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
      loreEn:
          'It returns not to where it was thrown, but to where its owner '
          'ought to be. At night it flies farther.',
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
      loreEn:
          'Made from a single scale. The rest of the dragon is still out '
          'there looking for it.',
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
      loreEn:
          'Every blow you land is written to your account as well. The shield '
          'only reminds you of the order.',
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
          customLabelEn: 'while below 40% HP, every blow you take is returned: attack +50%',
        ),
        ItemEffect(stat: ItemStat.stepXp, value: 0.12),
      ],
    ),
    'shields/soul_trapping_shield': ItemSignature(
      lore:
          'Durdurduğu darbenin sahibini de durdurur. İçinde kaç ses olduğunu '
          'kimse saymadı.',
      loreEn:
          'It stops not only the blow, but the one who threw it. No one has '
          'ever counted how many voices are trapped inside.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.48),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.4,
          trigger: ItemEffectTrigger.onKill,
          customLabel:
              'düşman yenince ruhu hapsedilir: canın %40\'ı geri gelir',
          customLabelEn: 'after defeating an enemy, its soul is bound: you recover 40% of your HP',
        ),
        ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
      ],
    ),

    // ──────────────────────────── EPİK (31) ────────────────────────────
    'magic/frost_queen_spell_book': ItemSignature(
      lore: 'Sayfaları birbirine donmuş; yalnızca sırası gelen açılır.',
      loreEn:
          'Its pages are frozen together. Only the one whose turn has come '
          'will open.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.28),
        ItemEffect(stat: ItemStat.attack, value: 0.24),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 300),
      ],
    ),
    'ranged_other/molten_throwing_axe': ItemSignature(
      lore: 'Fırlatıldığında soğumaz, döndüğünde tutulamaz.',
      loreEn:
          "It doesn't cool when thrown, and no one can catch it when it comes "
          'back.',
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
      loreEn:
          'Whoever hides behind it never wants to come out, and the shield '
          'never insists.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.4),
        ItemEffect.flat(stat: ItemStat.maxHealth, value: 28),
        ItemEffect(stat: ItemStat.dodge, value: -0.15),
      ],
    ),
    'shields/ocean_fountain_shield': ItemSignature(
      lore: 'Yüzeyinden hiç durmadan su akar; yaraları da yıkar.',
      loreEn:
          'Water pours from its face without pause, and it washes the wounds '
          'clean too.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.3),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.15,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 2,
        ),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.14),
      ],
    ),
    'arch/energy_bow': ItemSignature(
      lore: 'Kirişi yok; çekilen şey yayın kendi öfkesi.',
      loreEn: "It has no string. What you draw back is the bow's own fury.",
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 26),
        ItemEffect(stat: ItemStat.critChance, value: 0.16),
        ItemEffect(stat: ItemStat.stepXp, value: 0.09),
      ],
    ),
    'arch/energy_crossbow': ItemSignature(
      lore: 'Kurulması bir nefes, boşalması bir şimşek sürer.',
      loreEn:
          'Loading it takes one breath. Loosing it takes one bolt of '
          'lightning.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 30),
        ItemEffect(stat: ItemStat.critDamage, value: 0.35),
        ItemEffect(stat: ItemStat.dodge, value: -0.1),
      ],
    ),
    'arch/mech_bow': ItemSignature(
      lore: 'Dişlileri nişan alır, sahibi yalnızca yönü söyler.',
      loreEn: 'Its gears do the aiming. Its owner only names the direction.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 22),
        ItemEffect(
          stat: ItemStat.critChance,
          value: 0.22,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 2,
        ),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.11),
      ],
    ),
    'arch/turkish_bow': ItemSignature(
      lore: 'Menzili değil sabrı ölçülür; yolun sonunu bekleyen bir yaydır.',
      loreEn:
          'What it measures is not range but patience. This is a bow that '
          'waits for the end of the road.',
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
      loreEn:
          'Its body was torn from a mountain that still flows. It burns '
          'before a single arrow is loosed.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 28),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.3,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.2,
          customLabel: 'vuruşta %20 ihtimalle alev alır: saldırı +%30',
          customLabelEn: '20% chance on hit to burst into flame: attack +30%',
        ),
        ItemEffect(stat: ItemStat.defense, value: -0.12),
      ],
    ),
    'axes_halberds/volcanic_axe': ItemSignature(
      lore: 'İki elle kaldırılır, tek darbede iner. Ağırlığı bir cezadır.',
      loreEn:
          'It takes two hands to lift and one blow to land. Its weight is a '
          'punishment.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 34),
        ItemEffect(stat: ItemStat.critDamage, value: 0.45),
        ItemEffect(stat: ItemStat.dodge, value: -0.15),
      ],
    ),
    'maces_hammers/frost_chain_mace': ItemSignature(
      lore: 'Zinciri savrulurken donar; değdiği yer bir tur boyunca ısınmaz.',
      loreEn:
          'Its chain freezes as it swings, and whatever it touches stays cold '
          'for a whole round.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 25),
        ItemEffect.flat(stat: ItemStat.defense, value: 14),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 300),
      ],
    ),
    'magic/demons_staff': ItemSignature(
      lore: 'Bir pazarlıkla geldi. Verdiği gücün faizini canından keser.',
      loreEn:
          'It came with a bargain. The interest on the power it lends is paid '
          'out of your own health.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.42),
        ItemEffect(stat: ItemStat.maxHealth, value: -0.18),
        ItemEffect(stat: ItemStat.wheelXp, value: 0.12),
      ],
    ),
    'magic/forest_heart': ItemSignature(
      lore: 'Kökleri hâlâ toprağı arar; taşıyan kişiyi yürüdükçe besler.',
      loreEn:
          'Its roots still search for soil. It feeds whoever carries it, one '
          'step at a time.',
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
      loreEn:
          'Its owner never feels the cold. Those around them never feel warm.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.3),
        ItemEffect(stat: ItemStat.defense, value: 0.24),
        ItemEffect(stat: ItemStat.wheelXp, value: 0.14),
      ],
    ),
    'magic/mechanoid_spell_book': ItemSignature(
      lore: 'Büyüyü ezberlemez, hesaplar. Yanılma payı bırakmaz.',
      loreEn:
          "It doesn't memorize spells, it calculates them. It leaves no "
          'margin for error.',
      effects: [
        ItemEffect(stat: ItemStat.critChance, value: 0.2),
        ItemEffect(stat: ItemStat.critDamage, value: 0.3),
        ItemEffect(stat: ItemStat.stepXp, value: 0.11),
      ],
    ),
    'magic/meteor_spell_card': ItemSignature(
      lore: 'Tek kullanımlık gibi görünür; her seferinde bir kez daha yanar.',
      loreEn:
          'It looks like a single-use card, yet every time it burns once '
          'more.',
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
      loreEn:
          'The stone at its tip never went out, and laying the staff down '
          "won't put it out either.",
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
      loreEn:
          'Carried in the palm, it leaves a mark that lasts a whole day '
          'wherever it falls.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 27),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.28,
          trigger: ItemEffectTrigger.onKill,
          customLabel: 'düşman yenince bir sonraki tur saldırı +%28',
          customLabelEn: 'after defeating an enemy, attack +28% on the next round',
        ),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.1),
      ],
    ),
    'ranged_other/mech_kunai': ItemSignature(
      lore: 'Atıldıktan sonra geri döner; sahibi geri dönmesini beklemez.',
      loreEn:
          'It comes back after every throw. Its owner never waits for it to.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 21),
        ItemEffect(stat: ItemStat.dodge, value: 0.18),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.125),
      ],
    ),
    'shields/dragon_head_shield': ItemSignature(
      lore: 'Kalkanın ağzı hâlâ kapanmıyor; ilk darbeyi o karşılar.',
      loreEn:
          "The jaws on this shield still won't close, and they are the first "
          'to meet every blow.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.38),
        ItemEffect.flat(stat: ItemStat.maxHealth, value: 26),
        ItemEffect(stat: ItemStat.enemyXp, value: 0.12),
      ],
    ),
    'shields/energy_shield': ItemSignature(
      lore: 'Ağırlığı yok, bu yüzden yorulmaz. Sahibi de öyle sanır.',
      loreEn:
          'It weighs nothing, so it never tires. Its owner likes to think the '
          'same.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.3),
        ItemEffect(stat: ItemStat.dodge, value: 0.2),
        ItemEffect(stat: ItemStat.maxHealth, value: -0.1),
      ],
    ),
    'shields/holy_shield': ItemSignature(
      lore: 'Kırılmaz demezler; taşıyanı yalnız bırakmaz derler.',
      loreEn:
          "No one claims it can't break. They say it never leaves its bearer "
          'alone.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.34),
        ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 350),
      ],
    ),
    'shields/vampiric_shield': ItemSignature(
      lore: 'Savunmak için değil, beslenmek için tutulur.',
      loreEn: "It isn't held to defend. It's held to feed.",
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
      loreEn:
          'The hand that strikes it is never quite the same hand once it '
          'pulls away.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.32),
        ItemEffect.flat(stat: ItemStat.attack, value: 16),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.09),
      ],
    ),
    'spears/sea_trident': ItemSignature(
      lore: 'Üç uç, üç ayrı derinlik. Hangisinin değdiği sonradan anlaşılır.',
      loreEn:
          'Three points, three different depths. Only later do you learn '
          'which one struck.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 29),
        ItemEffect(stat: ItemStat.critChance, value: 0.14),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.11),
      ],
    ),
    'spears/vampires_spear': ItemSignature(
      lore: 'Ucu her zaman ıslak. Kimse onu temizlerken görmedi.',
      loreEn: 'Its tip is always wet. No one has ever seen it being cleaned.',
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
      loreEn:
          "Smoke rises wherever it strikes, and it doesn't stop when the "
          'trident is pulled free.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 33),
        ItemEffect(stat: ItemStat.critDamage, value: 0.4),
        ItemEffect(stat: ItemStat.dodge, value: -0.12),
      ],
    ),
    'swords/double_blade_gauntlet': ItemSignature(
      lore: 'İki ağız, tek bilek. Savunmayı kimse ona sormadı.',
      loreEn: 'Two edges, one wrist. No one ever asked it about defense.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.35),
        ItemEffect(stat: ItemStat.defense, value: -0.15),
        ItemEffect(stat: ItemStat.critChance, value: 0.18),
      ],
    ),
    'swords/fire_gem_greatsword': ItemSignature(
      lore: 'Kabzasındaki taş, sahibinin nabzıyla parlar. Yorulunca söner.',
      loreEn:
          "The stone in its hilt glows with its owner's pulse. When they "
          'tire, it fades.',
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
      loreEn:
          'Leaves rustle as it leaves its scabbard. It owes the forest a '
          'debt.',
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
      loreEn: 'Only those worthy of lifting it can feel its weight.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 30),
        ItemEffect(stat: ItemStat.defense, value: 0.2),
        ItemEffect(stat: ItemStat.enemyXp, value: 0.13),
      ],
    ),

    // ─────────────── SEÇİLMİŞ NADİRLER (imzalı alt küme) ───────────────
    'arch/knockback_arrow': ItemSignature(
      lore: 'Delmek için değil, geri itmek için yapıldı.',
      loreEn: 'Made not to pierce, but to push back.',
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
      loreEn: 'The wind picks the target. The archer only gives permission.',
      effects: [
        ItemEffect(stat: ItemStat.critChance, value: 0.12),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.08),
      ],
    ),
    'magic/frost_wave_spell_card': ItemSignature(
      lore: 'Okunduğunda oda değil, zaman soğur.',
      loreEn:
          "When it is read, it isn't the room that grows cold. It's time "
          'itself.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.2),
        ItemEffect.flat(stat: ItemStat.streakRelief, value: 250),
      ],
    ),
    'magic/mana_fusion_spell_card': ItemSignature(
      lore: 'İki büyüyü birleştirir; hangisi baskın çıkacak, kart bilmez.',
      loreEn:
          'It merges two spells into one. Which of them will win out, not '
          'even the card knows.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.28),
        ItemEffect(stat: ItemStat.maxHealth, value: -0.12),
      ],
    ),
    'ranged_other/nights_chakram': ItemSignature(
      lore: 'Gündüz sıradan bir halka, gece bambaşka bir şey.',
      loreEn: 'By day, an ordinary ring. By night, something else entirely.',
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
      loreEn: 'A small wound, a long reckoning.',
      effects: [
        ItemEffect.flat(stat: ItemStat.attack, value: 10),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.22,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.3,
          customLabel: 'vuruşta %30 ihtimalle zehir işler: saldırı +%22',
          customLabelEn: '30% chance on hit as venom sets in: attack +22%',
        ),
      ],
    ),
    'shields/forest_barrier_shield': ItemSignature(
      lore: 'Bir çitten çok bir söz; ormanın içinde geçerlidir.',
      loreEn:
          'Less a fence than a promise, and it holds wherever the forest '
          'grows.',
      effects: [
        ItemEffect(stat: ItemStat.defense, value: 0.18),
        ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
      ],
    ),
    'shields/frost_shield': ItemSignature(
      lore: 'Vurulduğu yerde çatlar, bir sonraki turda kendini onarır.',
      loreEn:
          'It cracks where it is struck and mends itself by the next round.',
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
      loreEn:
          'It flows like water. You know it not by where it is held, but by '
          'where it touches.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.22),
        ItemEffect(stat: ItemStat.dodge, value: 0.12),
      ],
    ),
    'swords/dark_dagger': ItemSignature(
      lore: 'Arkadan gelmek için değil, hiç görünmemek için yapıldı.',
      loreEn: 'Made not to strike from behind, but to never be seen at all.',
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
      loreEn: 'It spins its own web and waits for the patient.',
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
      loreEn:
          'Worn on the day you no longer have a hand left to hold a shield.',
      effects: [
        ItemEffect(stat: ItemStat.attack, value: 0.26),
        ItemEffect(stat: ItemStat.defense, value: -0.1),
      ],
    ),
  };

  static ItemSignature? of(String baseId) => entries[baseId];
}
