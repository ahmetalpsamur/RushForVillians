import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/base_combat_stats.dart';
import '../data/enemy_catalog.dart';

import '../models/avatar_profile.dart';
import '../models/game_state.dart';

/// Oyun durumunun yerel kalıcılığı. [CharacterStorage] ile aynı deseni izler:
/// statik yardımcı sınıf + SharedPreferences + elle JSON.
///
/// Diske yazılan kayıt bir "zarf" (envelope) içine sarılır:
/// `{schemaVersion, savedAt, state}`. Sürüm numarası ileride alan
/// eklendiğinde eski kayıtları taşımayı (migration), `savedAt` ise Firebase
/// eklendiğinde yerel kopya ile sunucu kopyasını karşılaştırmayı mümkün kılar.
class GameStorage {
  GameStorage._();

  static const _key = 'game_state_v1';

  /// Kayıt biçiminin güncel sürümü. Alan eklendiğinde/adı değiştiğinde bu
  /// sayı artırılır ve [_migrations] içine bir taşıma adımı eklenir.
  static const int schemaVersion = 14;

  /// Ardışık taşıma adımları: anahtar = taşınacak sürüm, değer = bir sonraki
  /// sürüme yükselten dönüşüm. `load()` kayıtlı sürümden [schemaVersion]'a
  /// kadar bu adımları sırayla uygular.
  static final Map<int, Map<String, dynamic> Function(Map<String, dynamic>)>
  _migrations = {
    // 0 -> 1: sürüm alanı olmayan en eski kayıtlar. Alan adları değişmediği
    // için içerik olduğu gibi taşınır.
    0: (state) => state,
    // 1 -> 2: UserProfile.hp / maxHp artık yazılmıyor (hiç azalmayan, bu
    // yüzden anlamsız olan alanlardı). Eski kayıtlardan temizlenir.
    1: (state) {
      final profile = state['profile'];
      if (profile is Map<String, dynamic>) {
        profile.remove('hp');
        profile.remove('maxHp');
      }
      return state;
    },
    // 2 -> 3: longestStreak, lastSeenAt ve macera startingSteps alanları
    // eklendi. Hepsi eksikken varsayılana düştüğü için taşıma gerekmiyor.
    2: (state) => state,
    // 3 -> 4: adım-para alanları eklendi (lastRewardedStepCount, günlük
    // coinsEarned). İşaretçi toplam adıma eşitlenir: ekonomi yokken atılmış
    // adımlar geriye dönük para kazandırmamalı.
    3: (state) {
      final profile = state['profile'];
      if (profile is Map<String, dynamic>) {
        profile['lastRewardedStepCount'] = profile['totalSteps'] as int? ?? 0;
      }
      return state;
    },
    // 4 -> 5: gerçek pedometer alanları eklendi. Raporlanmış sayaç mevcut
    // toplam adıma eşitlenir; ham sensör offset'i bilerek **null** bırakılır,
    // böylece ilk gerçek okuma yalnızca referans kurar ve cihaz açılışından
    // beri birikmiş ham değer tek seferde kredilenmez.
    4: (state) {
      final profile = state['profile'];
      if (profile is Map<String, dynamic>) {
        profile['lastReportedStepCount'] = profile['totalSteps'] as int? ?? 0;
        profile['lastSensorReading'] = null;
        profile['lastStepReportAt'] = null;
      }
      return state;
    },
    // 5 -> 6: adım → XP alanları eklendi. Para işaretçisiyle aynı gerekçe:
    // XP yokken atılmış adımlar geriye dönük seviye kazandırmamalı, yoksa
    // güncelleme sonrası ilk açılışta oyuncu birkaç seviye birden atlar.
    5: (state) {
      final profile = state['profile'];
      if (profile is Map<String, dynamic>) {
        profile['lastXpRewardedStepCount'] = profile['totalSteps'] as int? ?? 0;
      }
      return state;
    },
    // 6 -> 7: seri dondurma alanları eklendi (streakFreezes,
    // lastFreezeUsedOn). Varsayılanları (0 / null) doğru olduğu için içerik
    // taşınmıyor; sürüm yine de artırıldı (Model Kuralları #2 disiplini).
    6: (state) => state,
    // 7 -> 8: tamamlanan günlerin adım halkaları eklendi. Eski kullanıcılarda
    // geçmiş veri olmadığı için boş liste doğru ve dürüst varsayılandır.
    7: (state) {
      state['stepHistory'] ??= <Object>[];
      return state;
    },
    // 8 -> 9: mağazadaki iki yükseltme artık gerçekten tüketiliyor
    // (extraWheelSpins, xpBoostUntil). Varsayılanları (0 / null) doğru
    // olduğu için içerik değişmiyor; sürüm yine de artırıldı.
    8: (state) => state,
    // 9 -> 10: çark tohumu eklendi (#16). Varsayılan 0 "henüz kurulmadı"
    // demek; ilk çevirmede oyuncuya özel bir tohumla dolduruluyor.
    9: (state) => state,
    // 10 -> 11: kuşanma haritası eklendi (equippedItemIds). Yeni oyuncuda ve
    // eski kayıtta boş harita doğru varsayılan: sahip olunan hiçbir item
    // kendiliğinden kuşanılmış sayılmamalı, kuşanmayı oyuncu seçer.
    10: (state) => state,
    // 11 -> 12: envanter kimlik listesinden **örnek** listesine geçti
    // (her adedin kendi seviyesi, nadirliği ve kuşanma durumu var) ve
    // yükseltmeler ayrı bir listeye ayrıldı.
    //
    // Veri kaybı yok: sahip olunan her kimlik seviye 1 ve katalog
    // nadirliğiyle (`rarity: null`) bir örneğe dönüşüyor, kuşanılı olanlar
    // kuşanılı kalıyor.
    //
    // İki namespace'i **kimliğin biçimi** ayırıyor: katalog kimlikleri her
    // zaman `<kategori>/<dosya>` (ör. `swords/fire_sword`), yükseltme
    // kimlikleri (`boost_double_xp`) hiç `/` içermiyor. Taşıma anında
    // `AssetManifest` okunamadığı için katalogdan doğrulama yapılamaz;
    // bu ayrım katalogsuz ve güvenilir.
    11: (state) {
      final profile = state['profile'];
      if (profile is! Map<String, dynamic>) return state;

      final owned = profile.remove('ownedItemIds');
      final equipped = profile.remove('equippedItemIds');

      final equippedIds = <String>{};
      if (equipped is Map) {
        for (final value in equipped.values) {
          if (value is String && value.isNotEmpty) equippedIds.add(value);
        }
      }

      final instances = <Map<String, Object?>>[];
      final upgrades = <String>[];
      var nextId = 1;
      if (owned is List) {
        for (final id in owned) {
          if (id is! String || id.isEmpty) continue;
          if (!id.contains('/')) {
            upgrades.add(id);
            continue;
          }
          instances.add({
            'instanceId': nextId++,
            'itemId': id,
            'level': 1,
            // null = katalog nadirliği; taşıma katalogu okuyamaz.
            'rarity': null,
            'equipped': equippedIds.contains(id),
          });
        }
      }

      profile['ownedItems'] = instances;
      profile['ownedUpgradeIds'] = upgrades;
      profile['nextItemInstanceId'] = nextId;
      return state;
    },
    // 12 -> 13: seri savaş stat bonusu eklendi (Bölüm 5C).
    //
    // Varsayılanları (boş birikim / tohum 0 / gün null) doğru: seri bonusu
    // yokken geçen günler geriye dönük stat kazandırmamalı. Tohum ilk
    // kullanımda oyuncuya özel kurulacak.
    12: (state) => state,
    // 13 -> 14: savaş motoru (Aşama 4a). Düşman canı artık adımdan değil
    // kendi statından geliyor; oyuncunun can tavanı da sabit 100 değil.
    //
    // Yarım kalmış bir macera **sıfırlanmıyor**: eski ilerleme sadakatle
    // taşınıyor. Eskiden düşmanın kalan canı `stepGoal - atılanAdım` idi;
    // o oran yeni can tavanına uygulanıyor. Aksi hâlde neredeyse ölmüş bir
    // düşman güncelleme sonrası tam canla geri gelirdi.
    //
    // Düşman kataloğu saf Dart (asset okumuyor), bu yüzden taşıma sırasında
    // güvenle sorgulanabiliyor.
    13: (state) {
      final adventure = state['adventure'];
      if (adventure is! Map<String, dynamic>) return state;

      final enemyId = adventure['enemyId'];
      final enemy = enemyId is String ? EnemyCatalog.byId(enemyId) : null;
      if (enemy == null) {
        // Katalogdan kalkmış düşman: macera zaten yüklenemeyecek.
        return state;
      }

      final stepGoal = adventure['stepGoal'] as int? ?? enemy.minimumDailySteps;
      final startingSteps = adventure['startingSteps'] as int? ?? 0;
      final today = state['today'];
      final steps =
          today is Map<String, dynamic> ? (today['steps'] as int? ?? 0) : 0;

      final questSteps = (steps - startingSteps).clamp(0, stepGoal);
      final remainingRatio =
          stepGoal <= 0 ? 1.0 : (stepGoal - questSteps) / stepGoal;
      adventure['enemyHealth'] = (enemy.maxHealth * remainingRatio).round();

      // Oyuncunun canı 0-100 ölçeğindeydi; oranı korunarak yeni tavana
      // taşınıyor. Gerçek tavan (ekipman dâhil) açılışta
      // `RootShell._syncAdventureStats` tarafından tazeleniyor.
      final profile = state['profile'];
      final level =
          profile is Map<String, dynamic> ? (profile['level'] as int? ?? 1) : 1;
      final newMax =
          (baseHealthAtLevelOne + healthPerLevel * (level - 1)).round();
      final oldHealth = adventure['playerHealth'] as int? ?? 100;
      adventure['playerMaxHealth'] = newMax;
      adventure['playerHealth'] = (oldHealth / 100 * newMax).round().clamp(
        0,
        newMax,
      );

      // `acknowledgedDamage` artık "gösterilen son round serisi" demek.
      // Eski değeri adım sayısıydı; olduğu gibi bırakmak açılışta sahte bir
      // hasar mesajı gösterirdi.
      adventure['acknowledgedDamage'] =
          adventure['roundOutcomeSerial'] as int? ?? 0;
      adventure['combatSeed'] = 0;
      adventure['untouchedRounds'] = 0;
      adventure['lastPlayerDamage'] = 0;
      return state;
    },
  };

  /// Ardışık yazma isteklerinin diske gitme sıklığı. Her state değişiminde
  /// yazmak yerine bu aralıkta en fazla bir kez yazılır; ani kapanmada en
  /// kötü ihtimalle bu kadarlık ilerleme kaybolur.
  static const Duration writeInterval = Duration(seconds: 2);

  static Timer? _pendingWrite;
  static GameState? _pendingState;

  /// Kaydı okur. Kayıt yoksa, bozuksa veya bilinmeyen bir sürümdeyse `null`
  /// döner; çağıran taraf temiz varsayılanla başlar.
  static Future<GameState?> load({required AvatarProfile avatar}) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_key);
    if (value == null) return null;

    try {
      final envelope = jsonDecode(value) as Map<String, dynamic>;
      final state = _migrate(envelope);
      if (state == null) return null;
      return GameState.fromJson(state, avatar: avatar);
    } on FormatException catch (error) {
      debugPrint(
        'GameStorage: kayıt çözümlenemedi, sıfırdan başlanıyor ($error)',
      );
      return null;
    } on TypeError catch (error) {
      debugPrint('GameStorage: kayıt biçimi beklenenden farklı ($error)');
      return null;
    } catch (error) {
      // Bozuk kayıt hiçbir koşulda uygulamayı çökertmemeli.
      debugPrint('GameStorage: kayıt okunamadı ($error)');
      return null;
    }
  }

  /// Zarfı güncel sürüme taşır. Taşınamıyorsa `null` döner.
  static Map<String, dynamic>? _migrate(Map<String, dynamic> envelope) {
    var version = envelope['schemaVersion'] as int? ?? 0;
    final rawState = envelope['state'];
    var state = rawState is Map<String, dynamic> ? rawState : envelope;

    if (version > schemaVersion) {
      debugPrint(
        'GameStorage: kayıt sürümü ($version) uygulamadan yeni '
        '($schemaVersion), yok sayılıyor',
      );
      return null;
    }

    while (version < schemaVersion) {
      final migration = _migrations[version];
      if (migration == null) {
        debugPrint('GameStorage: $version sürümü için taşıma adımı yok');
        return null;
      }
      state = migration(state);
      version++;
    }
    return state;
  }

  /// Kaydı hemen diske yazar.
  static Future<void> save(GameState state) async {
    final preferences = await SharedPreferences.getInstance();
    final envelope = {
      'schemaVersion': schemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'state': state.toJson(),
    };
    await preferences.setString(_key, jsonEncode(envelope));
  }

  /// Yazmayı [writeInterval] kadar geciktirir. Aralık dolmadan gelen yeni
  /// istekler birikmez, sonuncusu yazılır.
  static void scheduleSave(GameState state) {
    _pendingState = state;
    _pendingWrite ??= Timer(writeInterval, () {
      _pendingWrite = null;
      unawaited(_writePending());
    });
  }

  /// Bekleyen yazmayı hemen tamamlar. Uygulama arka plana alınırken veya
  /// kapanırken çağrılır.
  static Future<void> flush() async {
    _pendingWrite?.cancel();
    _pendingWrite = null;
    await _writePending();
  }

  static Future<void> _writePending() async {
    final state = _pendingState;
    if (state == null) return;
    _pendingState = null;
    await save(state);
  }

  /// Kaydı siler. Testler ve ileride "ilerlemeyi sıfırla" için.
  static Future<void> clear() async {
    _pendingWrite?.cancel();
    _pendingWrite = null;
    _pendingState = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
