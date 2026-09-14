import '../core/utils/item_rules.dart' show stableSpread;

/// Rehberin serbest dolaşırken söyledikleri (Bölüm D).
///
/// **Tek dosya kuralı:** rehberin ağzından çıkan her cümle burada. Ekranların
/// içine serpiştirilmiş metin yok; ton değişecekse tek yer düzenlenir.
///
/// Eğitim cümleleriyle karıştırılmamalı: onlar
/// `features/tutorial/tutorial_guide.dart` içindeki `TutorialGuideFrame`
/// tablosunda ve **anlatının bir parçası**. Buradakiler anlatı değil, eşlik.
enum PetContext {
  home,
  adventure,
  store,
  tavern,
  profile;

  /// Sekme indeksinin karşılığı; `RootShell` sıralamasıyla aynı.
  static PetContext fromTabIndex(int index) => switch (index) {
    1 => adventure,
    2 => store,
    3 => tavern,
    4 => profile,
    _ => home,
  };
}

/// Rehberin o an neye bakabileceği.
///
/// Bağlam yalnızca sekme değil: aynı sekmede oyuncunun durumu farklıysa
/// söylenen de farklı olmalı, yoksa rehber bir süre sonra papağana döner.
class PetSituation {
  final PetContext context;

  /// Sürmekte olan bir macera var mı.
  final bool hasAdventure;

  /// Bugünün çark hakkı duruyor mu.
  final bool wheelAvailable;

  /// Günlük seri bugün güvenceye alındı mı.
  final bool streakSecured;

  const PetSituation({
    required this.context,
    this.hasAdventure = false,
    this.wheelAvailable = false,
    this.streakSecured = false,
  });
}

abstract final class PetSayings {
  /// Taverna sekmesinin karşılama cümlesi (Bölüm D).
  ///
  /// Taverna'nın **işlevi yok**: burada yalnızca rehber, çevrimiçi modun
  /// yolda olduğunu söylüyor.
  static const String tavernTeaser =
      'Çevrimiçi çok yakında — hadi git git, sen yürümene bak!';

  static const List<String> _home = [
    'Bugün de yürüyoruz, değil mi? Ben hazırım.',
    'Adımların birikiyor. Sonu güzel bitecek.',
    'Şu halkanın dolmasına bayılıyorum.',
    'Bir tur daha atsak fena olmaz bence.',
    'Sessiz duruyorum ama seni izliyorum.',
  ];

  static const List<String> _homeNoStreak = [
    'Serini bugün henüz güvenceye almadın. Acele yok ama unutma.',
    'Bir düşman devirsen seri bu akşam garanti olur.',
  ];

  static const List<String> _homeWheelReady = [
    'Çark hâlâ dönmeyi bekliyor, haberin olsun.',
    'Bugünün çark hakkı duruyor. Bedava şey sevmez misin?',
  ];

  static const List<String> _adventure = [
    'Şu düşmanın gözlerine bakma, cesareti kırılıyor.',
    'Adımlarını biriktir, güvenli olduğunda savaşa başla.',
    'Canavar bekleyebilir. Kendi temponda yürü.',
  ];

  static const List<String> _adventureIdle = [
    'Macera seçmemişsin. Hangi rakibi kızdıralım?',
    'Boş duran bir kahraman görmek beni geriyor.',
  ];

  static const List<String> _store = [
    'Bakmak bedava. Almak değil.',
    'Şu kalkanı alsan bir daha canını dert etmezdin.',
    'Altını biriktir derdim ama beni dinlemiyorsun.',
  ];

  static const List<String> _tavern = [
    tavernTeaser,
    'Burası dolduğunda masaları kapmak zor olacak, şimdiden söyleyeyim.',
    'Takım kuracağız, düşmanları paylaşacağız. Ama daha değil.',
  ];

  static const List<String> _profile = [
    'Ünvanını değiştirdin mi? Yeni birini denesen?',
    'Buradaki sayılara bakınca gurur duyuyorum.',
    'Seri bonusun her gün biraz daha birikiyor.',
  ];

  /// [situation] için uygun söz havuzu.
  static List<String> poolFor(PetSituation situation) => switch (situation
      .context) {
    PetContext.home => [
      ..._home,
      if (!situation.streakSecured) ..._homeNoStreak,
      if (situation.wheelAvailable) ..._homeWheelReady,
    ],
    PetContext.adventure => [
      ...situation.hasAdventure ? _adventure : _adventureIdle,
    ],
    PetContext.store => _store,
    PetContext.tavern => _tavern,
    PetContext.profile => _profile,
  };

  /// Havuzdan bir söz seçer.
  ///
  /// Seçim **tohumlu**: aynı [seed] aynı cümleyi verir, yani golden ve widget
  /// testleri tekrarlanabilir. Kalıcı bir sonuç üretmediği için (CLAUDE.md
  /// §4.4) tohumun saklanması gerekmiyor — burada tohum yalnızca
  /// test edilebilirlik için.
  ///
  /// [avoid] verilirse o cümle atlanır: rehber arka arkaya aynı şeyi
  /// söylemez.
  static String pick(
    PetSituation situation, {
    required int seed,
    String? avoid,
  }) {
    final pool = poolFor(situation);
    if (pool.isEmpty) return tavernTeaser;
    final options =
        pool.length > 1 && avoid != null
            ? [
              for (final line in pool)
                if (line != avoid) line,
            ]
            : pool;
    if (options.isEmpty) return pool.first;
    return options[stableSpread('pet-$seed', options.length)];
  }
}
