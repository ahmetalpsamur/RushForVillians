import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/data/title_catalog.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/l10n/content_localizations.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';

/// **Üretilen** ad ve etiketlerin iki dilde biçim denetimi
/// (Bölüm D / Faz 1).
///
/// Bu dosya metnin *doğru* olup olmadığını ölçmez — onu `localization_test`
/// ve `phase3_content_localization_test` yapıyor. Buradaki soru daha dar ve
/// daha sinsi: **metni üreten kod onu bozuyor mu.**
///
/// Yakaladığı hata sınıfı gerçek: `itemName` içindeki
/// `RegExp(r' Type ([1-9])$')` kalıbı baştaki boşluğu da tüketiyordu ve
/// yerine konan metin onu geri koymuyordu. Sonuç "Ancient Spell Book Type 1"
/// yerine **"Ancient Spell BookI"**; büyük "I" küçük "l" gibi okunduğu için
/// sahada "fazladan l harfi" diye bildirildi. **238 İngilizce ad** bozuktu ve
/// hiçbir test görmüyordu: adların doğruluğunu ölçen testler tek tek
/// örneklere bakıyor, bu sınıf hata ise ancak bütün katalog taranınca
/// görünüyor.
///
/// Aynı sınıfta başka bir hata (yutulan boşluk, çift boşluk, yapışan ek,
/// sızan ham kimlik, değiştirilmemiş ICU yer tutucusu) bir daha olursa
/// burada yakalanır.
void main() {
  late AppLocalizations tr;
  late AppLocalizations en;

  setUpAll(() async {
    tr = await AppLocalizations.delegate.load(const Locale('tr'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// Katalog yerine **dosya sistemi** taranıyor: `ItemCatalog`
  /// `AssetManifest` istiyor ve test ortamında kurulu değil. Bu aynı
  /// zamanda daha sert bir ölçüt — 784 görselin hepsi geçiyor.
  List<Item> allItems() {
    final items = <Item>[];
    for (final dir in Directory('lib/Items').listSync()) {
      if (dir is! Directory) continue;
      for (final file in dir.listSync()) {
        if (file is! File || !file.path.endsWith('.png')) continue;
        final item = buildItemFromAsset(file.path.replaceAll(r'\', '/'));
        if (item != null) items.add(item);
      }
    }
    return items;
  }

  /// Tek bir üretilmiş metnin biçim denetimi. Bulunan sorunları döner.
  List<String> problems(String text) {
    final found = <String>[];
    if (text.isEmpty) {
      return ['boş'];
    }
    if (text.trim() != text) found.add('baş/son boşluk');
    if (text.contains('  ')) found.add('çift boşluk');
    // Değiştirilmemiş ICU yer tutucusu.
    if (text.contains('{') || text.contains('}')) found.add('ham placeholder');
    // Ham asset kimliği ya da dosya yolu sızıntısı.
    if (text.contains('_')) found.add('snake_case kimlik');
    if (text.contains('/')) found.add('dosya yolu');
    // Yutulan boşluk: küçük harfin hemen ardından büyük harf gelmesi.
    // "Ancient Spell BookI" ve "SpellBook" bu kalıba takılır. Üretilen
    // adlarda meşru bir deve-kambur yok; hepsi boşlukla ayrılıyor.
    if (RegExp(r'[a-zçğıöşü][A-ZÇĞİÖŞÜ]').hasMatch(text)) {
      found.add('yutulan boşluk (küçük→BÜYÜK)');
    }
    // Rakamın harfe yapışması: "Hançer3" gibi.
    if (RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]\d').hasMatch(text)) {
      found.add('rakam harfe yapışmış');
    }
    return found;
  }

  /// Hata raporunu **kısa tut** (§9 test deseni): bozuk bir üretici yüzlerce
  /// satır üretir ve hepsini birleştirmek koşucuyu kilitler.
  void expectClean(List<String> failures, String what) {
    expect(
      failures,
      isEmpty,
      reason:
          '$what: ${failures.length} bozuk metin. '
          'İlk ikisi → ${failures.take(2).join(' | ')}',
    );
  }

  test('784 eşya adı iki dilde de temiz', () {
    final items = allItems();
    expect(items.length, greaterThan(700), reason: 'katalog taranamadı');

    final failures = <String>[];
    for (final item in items) {
      for (final entry in {'TR': tr, 'EN': en}.entries) {
        final name = entry.value.itemName(item);
        final issues = problems(name);
        if (issues.isNotEmpty) {
          failures.add('${entry.key} ${item.id} → "$name" (${issues.join(', ')})');
        }
      }
    }
    expectClean(failures, 'eşya adı');
  });

  test('eşya etkisi ve lore etiketleri iki dilde de temiz', () {
    final items = allItems();
    final failures = <String>[];
    for (final item in items) {
      for (final entry in {'TR': tr, 'EN': en}.entries) {
        for (final effect in item.buff.effects) {
          final label = entry.value.itemEffectLabel(effect);
          final issues = problems(label);
          if (issues.isNotEmpty) {
            failures.add(
              '${entry.key} ${item.id} etki → "$label" (${issues.join(', ')})',
            );
          }
        }
        if (item.hasSignature) {
          final lore = entry.value.itemLore(item);
          // Lore bir cümle; snake_case denetimi burada da geçerli ama
          // "küçük→BÜYÜK" cümle içinde meşru olabilir (özel ad).
          if (lore.trim() != lore || lore.contains('  ')) {
            failures.add('${entry.key} ${item.id} lore → "$lore"');
          }
        }
      }
    }
    expectClean(failures, 'etki/lore etiketi');
  });

  test('65 ünvan adı, hikâyesi ve etkisi iki dilde de temiz', () {
    final failures = <String>[];
    for (final title in TitleCatalog.all) {
      for (final entry in {'TR': tr, 'EN': en}.entries) {
        final name = entry.value.titleName(title);
        final issues = problems(name);
        if (issues.isNotEmpty) {
          failures.add(
            '${entry.key} ${title.id} ad → "$name" (${issues.join(', ')})',
          );
        }
        for (final effect in title.effects) {
          final label = entry.value.itemEffectLabel(effect);
          final labelIssues = problems(label);
          if (labelIssues.isNotEmpty) {
            failures.add(
              '${entry.key} ${title.id} etki → "$label" '
              '(${labelIssues.join(', ')})',
            );
          }
        }
        final lore = entry.value.titleLore(title);
        if (lore.trim() != lore || lore.contains('  ')) {
          failures.add('${entry.key} ${title.id} lore → "$lore"');
        }
      }
    }
    expectClean(failures, 'ünvan metni');
  });

  test('20 düşman adı ve nadirlik adları iki dilde de temiz', () {
    final failures = <String>[];
    for (final entry in {'TR': tr, 'EN': en}.entries) {
      for (final enemy in EnemyCatalog.enemies) {
        final name = entry.value.enemyName(enemy);
        final issues = problems(name);
        if (issues.isNotEmpty) {
          failures.add(
            '${entry.key} ${enemy.id} → "$name" (${issues.join(', ')})',
          );
        }
      }
      for (final rarity in RewardRarity.values) {
        final name = entry.value.rarityName(rarity);
        final issues = problems(name);
        if (issues.isNotEmpty) {
          failures.add('${entry.key} ${rarity.name} → "$name"');
        }
      }
      for (final stat in ItemStat.values) {
        final name = entry.value.itemStatName(stat);
        final issues = problems(name);
        if (issues.isNotEmpty) {
          failures.add('${entry.key} ${stat.name} → "$name"');
        }
      }
    }
    expectClean(failures, 'düşman/nadirlik/stat adı');
  });

  test('"Type N" roma rakamına dönerken boşluk korunuyor', () {
    // Kök sebebin kendi testi: kalıbın bir daha boşluğu yutmadığını
    // doğrudan söyler, 784 adı taramaya gerek kalmadan.
    final book = buildItemFromAsset(
      'lib/Items/magic/ancient_spell_book_type_1.png',
    );
    expect(book, isNotNull, reason: 'örnek asset katalogdan kalkmış');
    final name = en.itemName(book!);
    expect(name, endsWith(' I'), reason: 'gerçek çıktı: "$name"');
    expect(name, isNot(contains('BookI')));
  });
}
