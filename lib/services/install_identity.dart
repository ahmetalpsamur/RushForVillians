import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';
import 'game_storage.dart';

/// Bu kurulum, kaydın yazıldığı kurulum mu?
enum InstallOrigin {
  /// Cihazdaki kimlik yedektekiyle aynı: kayıt bu kurulumda yazıldı.
  sameInstall,

  /// Cihazda kimlik yok ya da yedektekiyle uyuşmuyor: kayıt yedekten
  /// (Android Auto Backup / cihazdan cihaza aktarım) geldi, ya da bu sürüm
  /// ilk kez açılıyor ve ikisi ayırt edilemiyor.
  restoredOrUnknown,
}

/// Cihaza bağlı tek değer: kurulum kimliğinin **yedeklenmeyen** kopyası.
///
/// Arayüz testte değiştirilebilsin diye var; gerçek uygulamada
/// [_DataStoreDeviceLocalStore].
abstract interface class DeviceLocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Yedekten dönen bir kaydın **cihaza bağlı** alanlarını ayıklar
/// (Bölüm F / Faz 4).
///
/// Kayıt `SharedPreferences` içinde (`shared_prefs/FlutterSharedPreferences.xml`)
/// ve Android Auto Backup onu yedekliyor (`res/xml/backup_rules.xml`,
/// `data_extraction_rules.xml`). Kaydın içindeki tek bir alan ise başka bir
/// telefonda **anlamsız**: [UserProfile.lastSensorReading], cihazın açılıştan
/// beri saydığı ham adım sayacı. Yeni telefonda bu değerle karşılaştırılan
/// sayaç ya büyük çıkıp fark adım diye kredilenir (hız denetimi kapalı
/// geçen süreye göre izin verdiği için kesmez), ya da küçük çıkıp "kapalıyken
/// yeniden başlatılmış" sayılır ve 10.000 adıma kadar telafi edilir. İkisi
/// de yürünmemiş adım, yani bedava altın.
///
/// Ayırt etmenin yolu: kimliğin bir kopyası yedeklenen dosyada, bir kopyası
/// yedeklenmeyen dosyada (Android'de `SharedPreferencesAsync` → DataStore,
/// `files/datastore/`; yedek kuralları onu dışarıda bırakıyor). Yedekten
/// dönen kurulumda ilki var, ikincisi yok.
///
/// **Bilinçli takas:** kimliği olmayan bir kayıt (bu sürümden önce alınmış
/// bir yedek **ya da** bu sürüme güncelleyen mevcut oyuncu) da sıfırlanıyor;
/// ikisi ayırt edilemiyor. Bedeli tek seferlik: uygulama son açılıştan beri
/// kapalıyken atılan adımlar kredilenmez. Diğer seçenek açığı eski
/// yedeklerde açık bırakırdı.
abstract final class InstallIdentity {
  /// Yedeklenen dosyadaki kopya.
  static const backedUpKey = 'install_id_v1';

  /// Yedeklenmeyen dosyadaki kopya.
  static const deviceKey = 'device_install_id_v1';

  @visibleForTesting
  static DeviceLocalStore deviceStore = const _DataStoreDeviceLocalStore();

  /// Saf karar: iki kopyadan kurulumun kökeni.
  static InstallOrigin classify({String? backedUp, String? device}) =>
      device != null && device == backedUp
          ? InstallOrigin.sameInstall
          : InstallOrigin.restoredOrUnknown;

  /// Kaydı bu cihaza bağlar. Gerekirse sensör referansını düşürür ve
  /// **önce** kaydı, **sonra** kimliği yazar: kimlik yazılıp kayıt
  /// yazılamazsa sonraki açılış "aynı kurulum" der ve eski telefonun
  /// sensör değeri geri gelirdi.
  ///
  /// Yalnızca Android: iOS'ta iki dosya da iCloud'a gidiyor, ayrım
  /// kurulamaz; iOS sayacı da cihaz açılışından değil, Dart'ın verdiği
  /// tarihten sayıyor (§6.2).
  ///
  /// Hiçbir hata açılışı durdurmaz; kimlik okunamazsa hiçbir şey
  /// değiştirilmez ve bir sonraki açılışta yeniden denenir.
  static Future<InstallOrigin?> reconcile(GameState? state) async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    if (GameStorage.writeBlocked) return null;
    try {
      final preferences = await SharedPreferences.getInstance();
      final backedUp = preferences.getString(backedUpKey);
      final device = await deviceStore.read(deviceKey);
      final origin = classify(backedUp: backedUp, device: device);
      if (origin == InstallOrigin.sameInstall) return origin;

      if (state != null) {
        state.profile.lastSensorReading = null;
        await GameStorage.save(state);
      }
      final id = _newId();
      await deviceStore.write(deviceKey, id);
      await preferences.setString(backedUpKey, id);
      return origin;
    } catch (error) {
      debugPrint('InstallIdentity: kurulum kimliği okunamadı ($error)');
      return null;
    }
  }

  /// Oyun sonucunu etkilemeyen bir kimlik; tohum değil, yalnızca eşitlik
  /// karşılaştırması için.
  static String _newId() =>
      '${DateTime.now().toUtc().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1 << 32)}';
}

/// Android'de `SharedPreferencesAsync` varsayılan olarak DataStore'a yazar
/// (`files/datastore/`), yani oyun kaydının durduğu XML dosyasından ayrı.
class _DataStoreDeviceLocalStore implements DeviceLocalStore {
  const _DataStoreDeviceLocalStore();

  @override
  Future<String?> read(String key) => SharedPreferencesAsync().getString(key);

  @override
  Future<void> write(String key, String value) =>
      SharedPreferencesAsync().setString(key, value);
}
