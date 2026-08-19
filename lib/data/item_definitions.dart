import '../models/reward_rarity.dart';

/// Dosya adına anlam veren tablo: her temel item'ın Türkçe adı ve nadirliği.
///
/// 784 item görselinin tamamı `lib/Items/<kategori>/` altında hazır ve katalog
/// dosya sisteminden üretiliyor (`ItemCatalog`). Bu dosya o taramanın
/// "sözlüğü": `swords/fire_sword` → ("Ateş Kılıcı", nadir).
///
/// Anahtar, dosya adının `_variant_NN` eki atılmış hâli. Aynı temel item'ın
/// bütün varyantları (`dagger_variant_01..07`) tek satırdan beslenir; ada
/// varyant numarası eklenir.
///
/// Tanımsız bir görsel eklenirse katalog onu **atmaz**: adı dosya adından
/// üretilir ve nadirliği [fallbackRarity] olur. Yeni sanat geldiğinde oyun
/// bozulmaz; item İngilizce adıyla görünür — bu da buraya eklenmesi
/// gerektiğinin işaretidir.
class ItemDefinitions {
  ItemDefinitions._();

  /// Tanımsız görseller için nadirlik. Sıradan seçildi: tanımsız bir item
  /// yanlışlıkla efsanevi fiyat ve seviye kilidi almamalı.
  static const RewardRarity fallbackRarity = RewardRarity.common;

  /// `<kategori>/<temel ad>` → (Türkçe ad, nadirlik).
  static const Map<String, (String, RewardRarity)> entries = {
    'arch/barbed_arrow': ('Dikenli Ok', RewardRarity.common),
    'arch/bodkin_arrow': ('Zırh Delen Ok', RewardRarity.uncommon),
    'arch/charm_bow': ('Tılsımlı Yay', RewardRarity.rare),
    'arch/crossbow': ('Arbalet', RewardRarity.common),
    'arch/double_string_bow': ('Çift Kirişli Yay', RewardRarity.uncommon),
    'arch/dungeon_bolt': ('Zindan Oku', RewardRarity.uncommon),
    'arch/energy_bolt': ('Enerji Oku', RewardRarity.rare),
    'arch/energy_bow': ('Enerji Yayı', RewardRarity.epic),
    'arch/energy_crossbow': ('Enerji Arbaleti', RewardRarity.epic),
    'arch/fire_bolt': ('Ateş Oku', RewardRarity.rare),
    'arch/fire_bow': ('Ateş Yayı', RewardRarity.rare),
    'arch/flat_arrow': ('Yassı Ok', RewardRarity.common),
    'arch/flat_arrow_v2': ('Yassı Ok (Yeni Nesil)', RewardRarity.common),
    'arch/flat_bolt': ('Yassı Kısa Ok', RewardRarity.common),
    'arch/forest_fang_arrow': ('Orman Dişi Oku', RewardRarity.rare),
    'arch/grappling_arrow': ('Kancalı Tırmanma Oku', RewardRarity.uncommon),
    'arch/hook_arrow': ('Kancalı Ok', RewardRarity.uncommon),
    'arch/hook_bolt': ('Kancalı Kısa Ok', RewardRarity.uncommon),
    'arch/knockback_arrow': ('Savuran Ok', RewardRarity.rare),
    'arch/longbow': ('Uzun Yay', RewardRarity.common),
    'arch/mech_bow': ('Mekanik Yay', RewardRarity.epic),
    'arch/meteor_strike_arrow': ('Göktaşı Oku', RewardRarity.legendary),
    'arch/normal_bow': ('Basit Yay', RewardRarity.common),
    'arch/point_bolt': ('Sivri Kısa Ok', RewardRarity.common),
    'arch/recurve_bow': ('Refleks Yay', RewardRarity.uncommon),
    'arch/recurve_longbow': ('Uzun Refleks Yay', RewardRarity.uncommon),
    'arch/rhombic_arrow': ('Baklava Uçlu Ok', RewardRarity.common),
    'arch/scythian_bow': ('İskit Yayı', RewardRarity.rare),
    'arch/snake_fang_arrow': ('Yılan Dişi Oku', RewardRarity.rare),
    'arch/spur_arrow': ('Mahmuzlu Ok', RewardRarity.common),
    'arch/tsunami_arrow': ('Tsunami Oku', RewardRarity.legendary),
    'arch/turkish_bow': ('Türk Yayı', RewardRarity.epic),
    'arch/voice_of_nature_bow': ('Doğanın Sesi', RewardRarity.legendary),
    'arch/volcanic_bow': ('Volkanik Yay', RewardRarity.epic),
    'arch/wind_arrow': ('Rüzgâr Oku', RewardRarity.rare),
    'arch/wooden_bow': ('Ahşap Yay', RewardRarity.common),
    'axes_halberds/axe_type_1': ('Balta', RewardRarity.common),
    'axes_halberds/axe_type_2': ('Savaş Baltası', RewardRarity.uncommon),
    'axes_halberds/blue_axe': ('Mavi Balta', RewardRarity.rare),
    'axes_halberds/forest_axe': ('Orman Baltası', RewardRarity.rare),
    'axes_halberds/halberd': ('Teber', RewardRarity.uncommon),
    'axes_halberds/volcanic_axe': ('Volkanik Balta', RewardRarity.epic),
    'maces_hammers/frost_chain_mace': ('Buz Zincirli Topuz', RewardRarity.epic),
    'maces_hammers/hammer_type_1': ('Çekiç', RewardRarity.common),
    'maces_hammers/hammer_type_2': ('Savaş Çekici', RewardRarity.uncommon),
    'maces_hammers/mace_type_1': ('Topuz', RewardRarity.common),
    'maces_hammers/mace_type_2': ('Dikenli Topuz', RewardRarity.uncommon),
    'magic/ancient_spell_book_type_1': ('Kadim Büyü Kitabı', RewardRarity.rare),
    'magic/ancient_spell_book_type_2': (
      'Kadim Tılsım Kitabı',
      RewardRarity.rare,
    ),
    'magic/ancient_spell_book_type_3': (
      'Kadim Mühür Kitabı',
      RewardRarity.rare,
    ),
    'magic/ancient_spell_book_type_4': ('Kadim Rün Kitabı', RewardRarity.rare),
    'magic/demons_staff': ('İblis Asası', RewardRarity.epic),
    'magic/dragons_spell_book': ('Ejderha Büyü Kitabı', RewardRarity.legendary),
    'magic/eldritch_gods_holy_book': (
      'Kadim Tanrıların Kutsal Kitabı',
      RewardRarity.legendary,
    ),
    'magic/forest_half_destroyed_book': (
      'Yarı Yanmış Orman Kitabı',
      RewardRarity.rare,
    ),
    'magic/forest_heart': ('Orman Kalbi', RewardRarity.epic),
    'magic/frost_queen_spell_book': (
      'Buz Kraliçesinin Kitabı',
      RewardRarity.epic,
    ),
    'magic/frost_queen_staff': ('Buz Kraliçesinin Asası', RewardRarity.epic),
    'magic/frost_wave_spell_card': ('Buz Dalgası Kartı', RewardRarity.rare),
    'magic/heal_spell_card': ('Şifa Kartı', RewardRarity.uncommon),
    'magic/mana_fusion_spell_card': ('Mana Füzyonu Kartı', RewardRarity.rare),
    'magic/mechanoid_spell_book': ('Mekanoid Büyü Kitabı', RewardRarity.epic),
    'magic/meteor_spell_card': ('Göktaşı Kartı', RewardRarity.epic),
    'magic/sages_hidden_book': (
      'Bilgenin Gizli Kitabı',
      RewardRarity.legendary,
    ),
    'magic/spell_book_type_1': ('Büyü Kitabı', RewardRarity.common),
    'magic/spell_book_type_2': ('Çırak Kitabı', RewardRarity.common),
    'magic/spell_book_type_3': ('Gezgin Kitabı', RewardRarity.common),
    'magic/spell_book_type_4': ('Mürekkep Kitabı', RewardRarity.common),
    'magic/spell_book_type_5': ('Deri Ciltli Kitap', RewardRarity.common),
    'magic/spell_book_type_6': ('Yıpranmış Kitap', RewardRarity.common),
    'magic/spell_card_type_1': ('Büyü Kartı', RewardRarity.common),
    'magic/spell_card_type_2': ('Kıvılcım Kartı', RewardRarity.common),
    'magic/spell_card_type_3': ('Sis Kartı', RewardRarity.common),
    'magic/spell_card_type_4': ('Gölge Kartı', RewardRarity.common),
    'magic/spirits_ancient_book': (
      'Ruhların Kadim Kitabı',
      RewardRarity.legendary,
    ),
    'magic/staff_type_1': ('Asa', RewardRarity.common),
    'magic/staff_type_2': ('Çırak Asası', RewardRarity.uncommon),
    'magic/star_fusion_spell_book': (
      'Yıldız Füzyonu Kitabı',
      RewardRarity.legendary,
    ),
    'magic/time_wardens_book': (
      'Zaman Bekçisinin Kitabı',
      RewardRarity.legendary,
    ),
    'magic/underworld_records_book': (
      'Yeraltı Kayıtları',
      RewardRarity.legendary,
    ),
    'magic/volcanic_staff': ('Volkanik Asa', RewardRarity.epic),
    'ranged_other/blowdart': ('Üfleme Oku', RewardRarity.common),
    'ranged_other/bola': ('Bolas', RewardRarity.common),
    'ranged_other/boomerang': ('Bumerang', RewardRarity.common),
    'ranged_other/chakram': ('Çakram', RewardRarity.uncommon),
    'ranged_other/elemental_beads': ('Elementel Boncuklar', RewardRarity.rare),
    'ranged_other/flat_dart': ('Yassı Dart', RewardRarity.common),
    'ranged_other/frost_bite_blowdart': (
      'Buz Isırığı Üfleme Oku',
      RewardRarity.rare,
    ),
    'ranged_other/frost_dart': ('Buz Dartı', RewardRarity.uncommon),
    'ranged_other/kunai': ('Kunai', RewardRarity.common),
    'ranged_other/magma_drop': ('Magma Damlası', RewardRarity.epic),
    'ranged_other/mech_kunai': ('Mekanik Kunai', RewardRarity.epic),
    'ranged_other/metal_beads': ('Metal Boncuklar', RewardRarity.uncommon),
    'ranged_other/molten_throwing_axe': (
      'Erimiş Fırlatma Baltası',
      RewardRarity.epic,
    ),
    'ranged_other/nights_chakram': ('Gecenin Çakramı', RewardRarity.rare),
    'ranged_other/pebbles': ('Çakıl Taşları', RewardRarity.common),
    'ranged_other/point_dart': ('Sivri Dart', RewardRarity.common),
    'ranged_other/poison_dart': ('Zehirli Dart', RewardRarity.rare),
    'ranged_other/shuriken': ('Şuriken', RewardRarity.uncommon),
    'ranged_other/sling': ('Sapan', RewardRarity.common),
    'ranged_other/wind_spirit_boomerang': (
      'Rüzgâr Ruhu Bumerangı',
      RewardRarity.legendary,
    ),
    'scythes/reapers_scythe': ('Azrailin Tırpanı', RewardRarity.legendary),
    'scythes/scythe': ('Tırpan', RewardRarity.common),
    'shields/big_heater_shield': (
      'Büyük Şövalye Kalkanı',
      RewardRarity.uncommon,
    ),
    'shields/black_dragon_scale_shield': (
      'Kara Ejderha Pulu Kalkanı',
      RewardRarity.legendary,
    ),
    'shields/black_hole_shield': ('Kara Delik Kalkanı', RewardRarity.legendary),
    'shields/blue_round_shield': ('Mavi Yuvarlak Kalkan', RewardRarity.common),
    'shields/cause_and_effect_shield': (
      'Sebep ve Sonuç Kalkanı',
      RewardRarity.legendary,
    ),
    'shields/celtic_shield': ('Kelt Kalkanı', RewardRarity.uncommon),
    'shields/coffin_shield': ('Tabut Kalkanı', RewardRarity.uncommon),
    'shields/dragon_head_shield': ('Ejderha Başı Kalkanı', RewardRarity.epic),
    'shields/empowered_celtic_shield': (
      'Güçlendirilmiş Kelt Kalkanı',
      RewardRarity.rare,
    ),
    'shields/empowered_coffin_shield': (
      'Güçlendirilmiş Tabut Kalkanı',
      RewardRarity.rare,
    ),
    'shields/empowered_kite_shield': (
      'Güçlendirilmiş Badem Kalkan',
      RewardRarity.rare,
    ),
    'shields/energy_shield': ('Enerji Kalkanı', RewardRarity.epic),
    'shields/forest_barrier_shield': ('Orman Bariyeri', RewardRarity.rare),
    'shields/frost_shield': ('Buz Kalkanı', RewardRarity.rare),
    'shields/full_plate_coffin_shield': (
      'Tam Levha Tabut Kalkanı',
      RewardRarity.epic,
    ),
    'shields/heater_shield': ('Şövalye Kalkanı', RewardRarity.common),
    'shields/holy_shield': ('Kutsal Kalkan', RewardRarity.epic),
    'shields/kite_shield': ('Badem Kalkan', RewardRarity.common),
    'shields/ocean_fountain_shield': (
      'Okyanus Çeşmesi Kalkanı',
      RewardRarity.epic,
    ),
    'shields/painted_round_shield': (
      'Boyalı Yuvarlak Kalkan',
      RewardRarity.common,
    ),
    'shields/plank_shield': ('Tahta Kalkan', RewardRarity.common),
    'shields/round_shield': ('Yuvarlak Kalkan', RewardRarity.common),
    'shields/small_kite_shield': ('Küçük Badem Kalkan', RewardRarity.common),
    'shields/soul_trapping_shield': (
      'Ruh Hapseden Kalkan',
      RewardRarity.legendary,
    ),
    'shields/square_shield': ('Kare Kalkan', RewardRarity.common),
    'shields/vampiric_shield': ('Vampirik Kalkan', RewardRarity.epic),
    'shields/volcanic_shield': ('Volkanik Kalkan', RewardRarity.epic),
    'shields/wankel_shield': ('Wankel Kalkanı', RewardRarity.uncommon),
    'spears/double_sided_spear': ('Çift Uçlu Mızrak', RewardRarity.uncommon),
    'spears/hilted_spear': ('Kabzalı Mızrak', RewardRarity.common),
    'spears/legendary_spear': ('Efsanevi Mızrak', RewardRarity.legendary),
    'spears/sea_trident': ('Deniz Yabası', RewardRarity.epic),
    'spears/spear': ('Mızrak', RewardRarity.common),
    'spears/trident': ('Üç Çatallı Mızrak', RewardRarity.uncommon),
    'spears/vampires_spear': ('Vampirin Mızrağı', RewardRarity.epic),
    'spears/volcanic_trident': ('Volkanik Yaba', RewardRarity.epic),
    'special_other/nunchucks': ('Nunçaku', RewardRarity.uncommon),
    'special_other/rope_dart': ('İpli Dart', RewardRarity.uncommon),
    'special_other/whip': ('Kırbaç', RewardRarity.uncommon),
    'swords/aqua_sword': ('Su Kılıcı', RewardRarity.rare),
    'swords/big_blade_gauntlet': ('Büyük Pençe Eldiven', RewardRarity.rare),
    'swords/dagger': ('Hançer', RewardRarity.common),
    'swords/dark_dagger': ('Karanlık Hançer', RewardRarity.rare),
    'swords/double_blade_gauntlet': ('Çift Pençe Eldiven', RewardRarity.epic),
    'swords/double_tip_knife': ('Çift Uçlu Bıçak', RewardRarity.uncommon),
    'swords/dragons_hook': ('Ejderha Kancası', RewardRarity.legendary),
    'swords/fire_gem_greatsword': ('Ateş Taşlı Büyük Kılıç', RewardRarity.epic),
    'swords/fire_sword': ('Ateş Kılıcı', RewardRarity.rare),
    'swords/forest_blessing_blade': ('Orman Kutsaması', RewardRarity.epic),
    'swords/holy_greatsword': ('Kutsal Büyük Kılıç', RewardRarity.epic),
    'swords/hooked_greatsword': ('Kancalı Büyük Kılıç', RewardRarity.uncommon),
    'swords/knife': ('Bıçak', RewardRarity.common),
    'swords/machete': ('Pala', RewardRarity.common),
    'swords/pine_sword': ('Çam Kılıcı', RewardRarity.uncommon),
    'swords/poisonous_hook_dagger': (
      'Zehirli Kancalı Hançer',
      RewardRarity.rare,
    ),
    'swords/rapier': ('Rapier', RewardRarity.uncommon),
    'swords/single_edge_dagger': ('Tek Ağızlı Hançer', RewardRarity.common),
    'swords/single_edge_greatsword': (
      'Tek Ağızlı Büyük Kılıç',
      RewardRarity.uncommon,
    ),
    'swords/spider_sword': ('Örümcek Kılıcı', RewardRarity.rare),
    'swords/sword': ('Kılıç', RewardRarity.common),
    'swords/sword_no_hilt': ('Kabzasız Kılıç', RewardRarity.common),
    'swords/thick_greatsword': ('Kalın Büyük Kılıç', RewardRarity.uncommon),
    'swords/thin_greatsword': ('İnce Büyük Kılıç', RewardRarity.uncommon),
  };

  /// [baseId] için tanım; yoksa `null`.
  static (String, RewardRarity)? of(String baseId) => entries[baseId];
}
