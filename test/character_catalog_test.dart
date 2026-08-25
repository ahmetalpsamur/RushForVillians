import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/character_class.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/services/character_catalog.dart';

void main() {
  // `CharacterCatalog.load()` gerçek asset manifestini okuyor; bağlama
  // kurulmadan çalışmaz. Diğer testler saf `fromAssetPaths` kullandığı için
  // etkilenmiyor.
  TestWidgetsFlutterBinding.ensureInitialized();

  final avatarRoot = Directory(
    'lib/All_Assets/Avatars/Classes/Characters(100x100 split)',
  );

  List<String> avatarAssets() =>
      avatarRoot
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.replaceAll(r'\', '/'))
          .toList();

  test('kullanımdaki 18 avatar klasörü ayrı sınıf olur', () {
    final classes = CharacterCatalog.fromAssetPaths(avatarAssets());
    final folders =
        avatarRoot
            .listSync()
            .whereType<Directory>()
            .map(
              (directory) => directory.path.split(Platform.pathSeparator).last,
            )
            .where(
              (folder) => !CharacterCatalog.retiredClassIds.contains(folder),
            )
            .toSet();

    expect(classes, hasLength(18));
    expect(classes.map((characterClass) => characterClass.id).toSet(), folders);
    expect(
      classes.every(
        (characterClass) =>
            characterClass.walkingAsset.endsWith('.gif') &&
            File(characterClass.walkingAsset).existsSync() &&
            characterClass.attackAssets.isNotEmpty &&
            characterClass.attackAssets.every(
              (asset) => asset.endsWith('.gif') && File(asset).existsSync(),
            ) &&
            characterClass.selectionSlogan.isNotEmpty,
      ),
      isTrue,
    );
  });

  test('kaldırılan sınıflar seçeneklerde görünmez', () {
    final ids = CharacterCatalog.fromAssetPaths(
      avatarAssets(),
    ).map((characterClass) => characterClass.id);

    expect(ids, isNot(contains('Bat')));
    expect(ids, isNot(contains('Lancer')));
    expect(ids, isNot(contains('Orc rider')));
    expect(ids, contains('Werebear'));
    expect(ids, isNot(contains('Necromancer')));
  });

  test('kaldırılan sınıflarla kayıtlı oyuncular aktif sınıflara taşınır', () {
    final migrations = {
      'Bat': 'Werewolf',
      'Lancer': 'Knight',
      'Orc rider': 'Orc',
      'Necromancer': 'Wizard',
    };

    for (final entry in migrations.entries) {
      final avatar = AvatarProfile.fromJson({
        'name': 'Ada',
        'age': 24,
        'weight': 70,
        'gender': 'Kadın',
        'characterClass': entry.key,
        'characterAsset':
            '${CharacterCatalog.root}${entry.key}/${entry.key}/old.gif',
      });

      expect(avatar.characterClass, entry.value);
      expect(
        avatar.characterAsset,
        AvatarProfile.walkAssetForClass(entry.value),
      );
    }
  });

  test('Slime sınıfı İlginç Slime adıyla gösterilir', () {
    expect(AvatarProfile.classLabels['Slime'], 'İlginç Slime');
  });

  test('her yeni sınıf en az üç ekipman kategorisi kullanır', () {
    final classes = CharacterCatalog.fromAssetPaths(avatarAssets());

    for (final characterClass in classes) {
      final categories = ItemCategory.values.where(
        (category) => category.characterClasses.contains(characterClass.id),
      );
      expect(
        categories.length,
        greaterThanOrEqualTo(3),
        reason: '${characterClass.id} için ekipman çeşitliliği yetersiz',
      );
    }
  });

  test('eski Characters kaydı All_Assets yürüyüş GIF\'ine taşınır', () {
    final avatar = AvatarProfile.fromJson({
      'name': 'Ada',
      'age': 24,
      'weight': 70,
      'gender': 'Kadın',
      'characterClass': 'SwordMan',
      'characterAsset': 'lib/Characters/SwordMan/hero.png',
    });

    expect(avatar.characterClass, 'Swordsman');
    expect(avatar.characterAsset, contains('lib/All_Assets/Avatars/'));
    expect(avatar.characterAsset, endsWith('Swordsman_Walk.gif'));
  });

  test('pubspec eski karakter ve düşman klasörlerini paketlemez', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('lib/All_Assets/Avatars/'));
    expect(pubspec, contains('lib/All_Assets/Enemies/'));
    expect(pubspec, isNot(contains('    - lib/Characters/')));
    expect(pubspec, isNot(contains('    - lib/Enemies/')));
    for (final retiredClass in CharacterCatalog.retiredClassIds) {
      expect(
        pubspec,
        isNot(contains('/$retiredClass/$retiredClass/')),
        reason: '$retiredClass artık paketlenmemeli',
      );
    }
  });

  /// Triaj A7: `_cache` bir kez dolduktan sonra hiç geçersizleşmiyordu ve
  /// `reset()` yoktu. Sınıf listesi bugün sabit olduğu için zararsızdı, ama
  /// kataloğu sabitleyemeyen testler gerçek asset paketine bağımlı kalıyordu —
  /// `ItemCatalog` bu deseni zaten sunuyordu.
  group('reset', () {
    tearDown(CharacterCatalog.reset);

    const stub = CharacterClass(
      id: 'Testçi',
      name: 'Testçi',
      walkingAsset: 'a.gif',
      attackAssets: ['b.gif'],
      selectionSlogan: 'slogan',
    );

    test('verilen liste kataloğu sabitler', () async {
      CharacterCatalog.reset([stub]);
      expect(await CharacterCatalog.load(), [stub]);
    });

    test('argümansız çağrı önbelleği boşaltır', () async {
      CharacterCatalog.reset([stub]);
      expect((await CharacterCatalog.load()).single.id, 'Testçi');

      CharacterCatalog.reset();
      // Önbellek boşaldı: sonraki okuma gerçek manifestten gelir ve stub
      // sınıf artık listede olmamalı.
      final reloaded = await CharacterCatalog.load();
      expect(reloaded.where((entry) => entry.id == 'Testçi'), isEmpty);
      expect(reloaded, isNotEmpty);
    });

    test('saldırı animasyonu olmayan sınıf katalogda görünmez', () {
      const id = 'Soldier';
      final classes = CharacterCatalog.fromAssetPaths([
        '${CharacterCatalog.root}$id/$id/${id}_Walk.gif',
        '${CharacterCatalog.root}$id/$id/${id}_Idle.gif',
      ]);
      expect(classes, isEmpty);
    });
  });
}
