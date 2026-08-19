import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/utils/item_rules.dart';
import '../models/item.dart';
import '../models/reward_rarity.dart';

/// `lib/Items/` altındaki görselleri tarayıp item kataloğunu üretir.
///
/// [CharacterCatalog] ile aynı deseni izler: sanat klasörü doğruluk kaynağı,
/// kod yalnızca ona anlam veriyor ([ItemDefinitions]). Yeni bir görsel eklemek
/// = klasöre dosya atmak + `pubspec.yaml` zaten klasörü kapsıyor.
///
/// Katalog **kalıcı değildir**: diske yalnızca [Item.id] yazılır
/// ([UserProfile.ownedItemIds]) ve her açılışta buradan yeniden çözülür.
class ItemCatalog {
  ItemCatalog._();

  /// Tarama bir kez yapılır; katalog uygulama ömrü boyunca değişmez.
  static List<Item>? _cache;

  /// Yüklenmiş katalog. [load] çağrılmadıysa boştur.
  static List<Item> get items => _cache ?? const [];

  static Map<String, Item> _byId = const {};

  /// Kimlikten item çözer. Katalogdan kaldırılmış (ya da henüz yüklenmemiş)
  /// bir kimlik için `null` döner — kayıtta duran eski item oyunu bozmasın.
  static Item? byId(String id) => _byId[id];

  /// Kataloğu yükler. İkinci çağrı önbellekten döner.
  ///
  /// Asset manifesti okunamazsa (test ortamı, bozuk paket) **boş katalog**
  /// döner ve hata yutulmaz, loglanır: oyunun geri kalanı çalışmaya devam
  /// etmeli.
  static Future<List<Item>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    List<Item> parsed;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      parsed = fromAssetPaths(manifest.listAssets());
    } catch (error) {
      debugPrint('ItemCatalog: asset manifesti okunamadı ($error)');
      parsed = const [];
    }

    _cache = parsed;
    _byId = {for (final item in parsed) item.id: item};
    return parsed;
  }

  /// Asset yollarından katalog üretir. Saf: testler manifest olmadan çağırır.
  ///
  /// Tanınmayan yollar sessizce atlanır ([parseItemAsset]). Sıralama
  /// kararlıdır: önce kategori, sonra seviye kilidi, sonra kimlik — böylece
  /// mağaza ve envanter listeleri her açılışta aynı sırada gelir.
  static List<Item> fromAssetPaths(Iterable<String> assetPaths) {
    final items = <Item>[];
    for (final path in assetPaths) {
      final item = buildItemFromAsset(path);
      if (item != null) items.add(item);
    }
    items.sort((a, b) {
      final byCategory = a.category.index.compareTo(b.category.index);
      if (byCategory != 0) return byCategory;
      final byLevel = a.requiredLevel.compareTo(b.requiredLevel);
      if (byLevel != 0) return byLevel;
      return a.id.compareTo(b.id);
    });
    return items;
  }

  /// Testlerin ve ileride "ilerlemeyi sıfırla" akışının kataloğu yeniden
  /// yüklemesi için.
  @visibleForTesting
  static void reset([List<Item>? items]) {
    _cache = items;
    _byId = items == null ? const {} : {for (final i in items) i.id: i};
  }

  /// [level] seviyesindeki bir oyuncunun kuşanabileceği itemler (#10).
  static List<Item> unlockedAt(int level) =>
      items.where((item) => item.isUnlockedAt(level)).toList();

  /// [characterClass] sınıfının kullanabileceği itemler.
  static List<Item> forCharacterClass(String characterClass) =>
      items.where((item) => item.isUsableBy(characterClass)).toList();

  static List<Item> byCategory(ItemCategory category) =>
      items.where((item) => item.category == category).toList();

  static List<Item> byRarity(RewardRarity rarity) =>
      items.where((item) => item.rarity == rarity).toList();
}
