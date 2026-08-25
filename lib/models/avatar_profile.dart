class AvatarProfile {
  final String name;
  final int age;
  final int weight;
  final String gender;
  final String characterClass;
  final String characterAsset;

  const AvatarProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.gender,
    required this.characterClass,
    required this.characterAsset,
  });

  static const classLabels = {
    'Archer': 'Şahin Okçu',
    'Armored Axeman': 'Demir Cellat',
    'Armored Orc': 'Zırhlı Yaban',
    'Armored Skeleton': 'Kemik Muhafız',
    'Bat': 'Gece Kanadı',
    'Elite Orc': 'Kızıl Savaş Şefi',
    'Greatsword Skeleton': 'Mezar Kılıçlısı',
    'Knight': 'Kraliyet Şövalyesi',
    'Knight Templar': 'Şafak Tapınakçısı',
    'Lancer': 'Fırtına Mızrakçısı',
    'Necromancer': 'Ruh Çağıran',
    'Orc': 'Yaban Akıncı',
    'Orc rider': 'Bozkır Binicisi',
    'Priest': 'Işık Rahibi',
    'Skeleton': 'Kemik Savaşçı',
    'Skeleton Archer': 'Mezar Okçusu',
    'Slime': 'İlginç Slime',
    'Soldier': 'Sınır Muhafızı',
    'Swordsman': 'Kılıç Üstadı',
    'Werebear': 'Ayı Ruhlu',
    'Werewolf': 'Ay Kurdu',
    'Wizard': 'Gök Büyücüsü',

    // Eski kayıtlar ekranda anlamlı kalır; fromJson bunları yeni
    // All_Assets karşılıklarına taşır.
    'DarkMagic': 'Kara Büyücü',
    'Faith': 'İnanç Şövalyesi',
    'Magic': 'Büyücü',
    'Nature': 'Doğa Muhafızı',
    'Paladin': 'Paladin',
    'SwordMan': 'Kılıç Ustası',
    'Thief': 'Hırsız',
  };

  static const classSelectionSlogans = {
    'Archer':
        'Hedefini şaşırmayacağını biliyordum. Gözüm ve yayım yolunu koruyacak!',
    'Armored Axeman':
        'Beni seçeceğini biliyordum evlat. Demir irademle her engeli parçalayacağız!',
    'Armored Orc':
        'Zırhım artık senin kalen. Yanımdayken hiçbir darbe seni yolundan döndüremez!',
    'Armored Skeleton':
        'Ölüm beni durduramadı; düşmanların hiç durduramaz. Yürü, muhafızın burada!',
    'Bat':
        'Gecenin seni çağırdığını duydum. Kanatlarım karanlıkta yolunu bulacak!',
    'Elite Orc':
        'Bir savaş şefi ancak cesur olanı izler. Bugün ordumun önünde sen varsın!',
    'Greatsword Skeleton':
        'Mezarımdan bu an için kalktım. Kılıcım ve sadakatim artık senin!',
    'Knight':
        'Asil bir yüreği hemen tanırım. Kılıcım yoluna, yeminim zaferine adandı!',
    'Knight Templar':
        'Şafak seçimini yaptı. İnancım ve kalkanımla yanımda güvendesin!',
    'Lancer':
        'Fırtınadan hızlı ilerleyeceğini biliyordum. Mızrağım yolumuzu açacak!',
    'Necromancer':
        'Beni seçeceğini biliyordum evlat. Büyülerim ve kadim deneyimimle güvendesin!',
    'Orc':
        'Gücünün kokusunu uzaktan aldım. Birlikte hiçbir kapı önümüzde kapalı kalmayacak!',
    'Orc rider':
        'Bozkır senin adını fısıldadı. Yanımda ufuk bile bize yetmeyecek!',
    'Priest':
        'Işık seni bana getirdi. Dualarım yaralarını, inancım ruhunu koruyacak!',
    'Skeleton':
        'Kemiklerim eski ama yeminim diri. Son adımına kadar yanında savaşacağım!',
    'Skeleton Archer':
        'Sessizliği seçtin, isabeti kazandın. Düşmanın bizi fark ettiğinde çok geç olacak!',
    'Slime':
        'Beni küçümsemedin; doğru seçim buydu. Her darbeye uyum sağlayıp daha güçlü döneceğiz!',
    'Soldier': 'Disiplin cesaretin zırhıdır. Adımlarını koruyacak asker hazır!',
    'Swordsman':
        'Kılıcın seni seçtiğini biliyordum. Ustalığım zaferinin keskin kenarı olacak!',
    'Werebear':
        'Orman kalbindeki gücü tanıdı. Pençelerimle yoluna uzanan her tehdidi ezeceğim!',
    'Werewolf':
        'Ay ikimizi de çağırdı. Hızım ve içgüdülerimle avlanan değil, avcı olacaksın!',
    'Wizard':
        'Zihnindeki kıvılcığı gördüm. Büyülerim ve bilgeliğimle gökler bile sınır olmayacak!',
  };

  String get characterClassLabel =>
      classLabels[characterClass] ?? characterClass;

  Map<String, Object> toJson() => {
    'name': name,
    'age': age,
    'weight': weight,
    'gender': gender,
    'characterClass': characterClass,
    'characterAsset': characterAsset,
  };

  factory AvatarProfile.fromJson(Map<String, dynamic> json) {
    final storedClass = json['characterClass'] as String;
    final storedAsset = json['characterAsset'] as String;
    final usesLegacyAsset =
        storedAsset.startsWith('lib/Characters/') ||
        storedAsset.startsWith('lib/CharactersTransparent/');
    final migratedLegacyClass =
        usesLegacyAsset
            ? (_legacyClasses[storedClass] ?? storedClass)
            : storedClass;
    final characterClass =
        _retiredClasses[migratedLegacyClass] ?? migratedLegacyClass;
    final classChanged = characterClass != storedClass;

    return AvatarProfile(
      name: json['name'] as String,
      age: json['age'] as int,
      weight: json['weight'] as int,
      gender: json['gender'] as String,
      characterClass: characterClass,
      characterAsset:
          usesLegacyAsset || classChanged
              ? walkAssetForClass(characterClass)
              : storedAsset,
    );
  }

  static const _legacyClasses = {
    'DarkMagic': 'Wizard',
    'Faith': 'Priest',
    'Magic': 'Wizard',
    'Nature': 'Orc rider',
    'Paladin': 'Knight Templar',
    'SwordMan': 'Swordsman',
    'Thief': 'Werewolf',
  };

  /// Bugün oynanabilen sınıf kimlikleri.
  ///
  /// [classLabels] hem güncel All_Assets sınıflarını hem de yalnızca eski
  /// kayıtlarda geçen kimlikleri taşıyor (emekliye ayrılanlar ve
  /// All_Assets'e taşınmış eski sınıflar). Oynanabilir küme ikisini de
  /// dışarıda bırakır; [CharacterCatalog.load] de aynı sonucu üretir.
  ///
  /// Item dağılımı ve buff testleri bu listeye bakar: elle yazılmış bir
  /// kopya, sınıf eklendiğinde sessizce eskiyordu.
  static List<String> get playableClassIds => [
    for (final id in classLabels.keys)
      if (!_retiredClasses.containsKey(id) && !_legacyClasses.containsKey(id))
        id,
  ];

  static const _retiredClasses = {
    'Bat': 'Werewolf',
    'Lancer': 'Knight',
    'Orc rider': 'Orc',
    'Necromancer': 'Wizard',
  };

  static String walkAssetForClass(String characterClass) {
    const root = 'lib/All_Assets/Avatars/Classes/Characters(100x100 split)';
    final animation = switch (characterClass) {
      'Bat' => 'Bat_Flying.gif',
      'Knight Templar' => 'Knight Templar_Walk01.gif',
      'Lancer' => 'Lancer_Walk01.gif',
      _ => '${characterClass}_Walk.gif',
    };
    return '$root/$characterClass/$characterClass/$animation';
  }
}
