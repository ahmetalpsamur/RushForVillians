import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/item_effects.dart';
import 'package:rush_for_villains/data/title_catalog.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/l10n/content_localizations.dart';
import 'package:rush_for_villains/models/game_title.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';

/// İngilizce hikâye borcu (Faz 1b, Bölüm F).
///
/// Bölüm F'ye kadar İngilizce oyuncu 61 imzalı eşyanın **hepsinde** aynı
/// cümleyi ("A signature item with a unique combat trait.") ve 65 ünvanın
/// hikâyesi yerine kaynağa göre dört kalıptan birini görüyordu
/// ("{name} is proof of a hard-earned feat."). Çeviri artık katalogda veri
/// (`loreEn`, GD89'daki `customLabelEn` ile aynı karar).
///
/// Bu dosya iki şeyi bağlıyor: hiçbir satır kalıba **düşmüyor**, ve çeviri
/// gösterim yoluna (`itemLore` / `titleLore`) gerçekten ulaşıyor.
void main() {
  late AppLocalizations tr;
  late AppLocalizations en;

  setUpAll(() async {
    tr = await AppLocalizations.delegate.load(const Locale('tr'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// Eski kalıp cümleler. Ünvan kalıpları ada göre çözülüyordu; her ünvanın
  /// kendi adıyla üretilen dört cümlenin hiçbiriyle eşleşmemeli.
  Set<String> titleTemplates(GameTitle title) {
    final name = en.titleName(title);
    return {
      en.titleLorePurchase(name),
      en.titleLoreAchievement(name),
      en.titleLoreWheel(name),
      en.titleLoreMilestone(name),
      en.titleLoreMail,
    };
  }

  /// Kullanıcının isteği: çeviride uzun tire yok.
  void expectNoLongDash(String text, String id) {
    expect(text.contains('—'), isFalse, reason: '$id: uzun tire');
    expect(text.contains('–'), isFalse, reason: '$id: orta tire');
  }

  group('imzalı eşyalar', () {
    test('61 imzanın hepsinin elle yazılmış İngilizcesi var', () {
      expect(ItemEffects.entries, hasLength(61));
      final seen = <String>{};
      for (final MapEntry(key: id, value: signature)
          in ItemEffects.entries.entries) {
        final text = signature.loreEn.trim();
        expect(text, isNotEmpty, reason: id);
        expect(text, isNot(signature.lore), reason: '$id: çevrilmemiş');
        expect(text, isNot(en.signatureItemLore), reason: '$id: kalıp');
        expectNoLongDash(text, id);
        expect(seen.add(text), isTrue, reason: '$id: aynı cümle iki kez');
      }
    });

    test('katalogdaki her imzalı eşya İngilizcede kendi hikâyesini gösterir', () {
      // Dosya sistemi taranıyor: varyantlar da aynı imzadan besleniyor ve
      // gösterim yolunun (`itemLore`) hepsine ulaştığı burada görünüyor.
      var signed = 0;
      for (final dir in Directory('lib/Items').listSync()) {
        if (dir is! Directory) continue;
        for (final file in dir.listSync()) {
          if (file is! File || !file.path.endsWith('.png')) continue;
          final item = buildItemFromAsset(file.path.replaceAll(r'\', '/'));
          if (item == null || !item.hasSignature) continue;
          signed++;
          final shown = en.itemLore(item);
          expect(shown, isNot(en.signatureItemLore), reason: item.id);
          expect(shown, item.loreEn, reason: item.id);
          expect(tr.itemLore(item), item.lore, reason: item.id);
        }
      }
      expect(signed, greaterThan(61), reason: 'varyantlar da sayılmalı');
    });

    test('sınıfa uyarlama ve birleştirme çeviriyi düşürmez', () {
      // Uyarlama ve birleştirme `copyWith` ile yeni bir Item kuruyor; bir
      // dönem `lore` taşınıp İngilizcesi unutulsaydı kalıba geri düşerdi.
      final item = buildItemFromAsset('lib/Items/scythes/reapers_scythe.png')!;
      final flavored = flavorForClass(item, 'Swordsman');
      expect(en.itemLore(flavored), item.loreEn);

      final epic = buildItemFromAsset(
        'lib/Items/shields/frost_shield.png',
      )!;
      expect(epic.hasSignature, isTrue);
      final merged = withRarity(epic, RewardRarity.legendary);
      expect(en.itemLore(merged), epic.loreEn);
    });
  });

  group('ünvanlar', () {
    test('her ünvanın elle yazılmış İngilizcesi var, hiçbiri kalıp değil', () {
      final seen = <String>{};
      for (final title in TitleCatalog.all) {
        final text = title.loreEn.trim();
        expect(text, isNotEmpty, reason: title.id);
        expect(text, isNot(title.lore), reason: '${title.id}: çevrilmemiş');
        expect(
          titleTemplates(title),
          isNot(contains(text)),
          reason: '${title.id}: kalıp cümle',
        );
        expectNoLongDash(text, title.id);
        expect(seen.add(text), isTrue, reason: '${title.id}: tekrar');
      }
    });

    test('gösterim yolu dile göre doğru alanı okur', () {
      for (final title in TitleCatalog.all) {
        expect(en.titleLore(title), title.loreEn, reason: title.id);
        expect(tr.titleLore(title), title.lore, reason: title.id);
        expect(
          titleTemplates(title),
          isNot(contains(en.titleLore(title))),
          reason: title.id,
        );
      }
    });
  });
}
