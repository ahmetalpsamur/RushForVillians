import 'package:flutter/services.dart';

import '../models/avatar_profile.dart';
import '../models/character_class.dart';

class CharacterCatalog {
  CharacterCatalog._();

  static const _root = 'lib/Characters/';

  static Future<List<CharacterClass>> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final grouped = <String, List<String>>{};

    for (final asset in manifest.listAssets()) {
      if (!asset.startsWith(_root) || !asset.toLowerCase().endsWith('.png')) {
        continue;
      }
      final relativePath = asset.substring(_root.length);
      final parts = relativePath.split('/');
      if (parts.length != 2) continue;
      grouped.putIfAbsent(parts.first, () => []).add(asset);
    }

    final classes =
        grouped.entries.map((entry) {
          entry.value.sort();
          return CharacterClass(
            id: entry.key,
            name: AvatarProfile.classLabels[entry.key] ?? entry.key,
            characterAssets: entry.value,
          );
        }).toList();
    classes.sort((a, b) => a.name.compareTo(b.name));
    return classes;
  }
}
