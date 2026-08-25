import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/avatar_profile.dart';
import '../models/character_class.dart';

class CharacterCatalog {
  CharacterCatalog._();

  static const root =
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/';
  static const retiredClassIds = {'Bat', 'Lancer', 'Necromancer', 'Orc rider'};

  static List<CharacterClass>? _cache;

  static Future<List<CharacterClass>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return _cache = fromAssetPaths(manifest.listAssets());
  }

  /// Testlerin kataloğu sabitleyebilmesi ve önbelleğin geçersizleştirilebilmesi
  /// için (triaj A7). [ItemCatalog.reset] ile aynı sözleşme: argümansız çağrı
  /// önbelleği boşaltır, listeyle çağrı kataloğu sabitler.
  ///
  /// Önbellek eskiden hiç geçersizleşmiyordu; sınıf listesi bugün sabit olduğu
  /// için zararsızdı ama kataloğu sabitleyemeyen testler gerçek asset paketine
  /// bağımlı kalıyordu.
  @visibleForTesting
  static void reset([List<CharacterClass>? classes]) {
    _cache = classes;
  }

  /// Asset manifestindeki avatar animasyonlarını sınıflara dönüştürür.
  ///
  /// Her üst klasör ayrı bir sınıftır. Seçim ekranında durağan kare yerine
  /// hareket gösterildiği için normalde `Walk`, o yoksa `Walk01`, uçan
  /// karakterlerde ise `Flying` animasyonu seçilir.
  static List<CharacterClass> fromAssetPaths(Iterable<String> assets) {
    final walkingAssets = <String, ({String asset, int priority})>{};
    final attackAssets = <String, List<String>>{};

    for (final asset in assets) {
      if (!asset.startsWith(root) || !asset.toLowerCase().endsWith('.gif')) {
        continue;
      }
      final relativePath = asset.substring(root.length);
      final parts = relativePath.split('/');
      if (parts.length != 3) continue;

      final fileName = parts.last.toLowerCase();
      final walkingPriority = switch (fileName) {
        final name when name.endsWith('_walk.gif') => 0,
        final name when name.endsWith('_walk01.gif') => 1,
        final name when name.endsWith('_flying.gif') => 2,
        _ => null,
      };
      final classId = parts.first;
      if (walkingPriority != null) {
        final current = walkingAssets[classId];
        if (current == null || walkingPriority < current.priority) {
          walkingAssets[classId] = (asset: asset, priority: walkingPriority);
        }
      }

      final isAttack =
          fileName.contains('_attack') && !fileName.endsWith('_effect.gif');
      if (isAttack) {
        attackAssets.putIfAbsent(classId, () => []).add(asset);
      }
    }

    for (final assets in attackAssets.values) {
      assets.sort();
    }

    final classes =
        walkingAssets.entries
            .where(
              (entry) =>
                  !retiredClassIds.contains(entry.key) &&
                  (attackAssets[entry.key]?.isNotEmpty ?? false),
            )
            .map(
              (entry) => CharacterClass(
                id: entry.key,
                name: AvatarProfile.classLabels[entry.key] ?? entry.key,
                walkingAsset: entry.value.asset,
                attackAssets: List.unmodifiable(attackAssets[entry.key]!),
                selectionSlogan:
                    AvatarProfile.classSelectionSlogans[entry.key] ??
                    'Beni seçeceğini biliyordum. Birlikte zafere yürüyeceğiz!',
              ),
            )
            .toList();
    classes.sort((a, b) => a.name.compareTo(b.name));
    return classes;
  }
}
