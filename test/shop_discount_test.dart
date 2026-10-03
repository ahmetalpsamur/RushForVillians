import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/equipped_buffs.dart';
import 'package:rush_for_villains/core/utils/shop_pricing.dart';
import 'package:rush_for_villains/data/mail_catalog.dart';
import 'package:rush_for_villains/data/title_catalog.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/game_title.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/user_profile.dart';

/// Mağaza indirimi penceresi (Bölüm D / Faz 3 kapanışı).
///
/// İndirim **pasif değil**: Erken Kalkan ünvanı takılıyken bir macera
/// tamamlanınca ya da sonsuz koşuda bir canavar kesilince 30 dakikalık bir
/// pencere açılır. Burada ölçülen üç şey: pencerenin açılıp kapanması,
/// kapat-aç sonrası kalan sürenin **doğru** devam etmesi, ve fiyatın tek
/// bir yerden hesaplanması.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Swordsman',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Walk.gif',
);

void main() {
  final now = DateTime.utc(2026, 10, 3, 12);

  group('fiyat hesabı tek yerden', () {
    test('indirim yokken fiyat birebir', () {
      expect(discountedCost(1000, 0), 1000);
      expect(discountedCost(825, 0), 825);
    });

    test('%25 indirim aşağı yuvarlanır', () {
      expect(discountedCost(1000, 0.25), 750);
      expect(discountedCost(825, 0.25), 618);
      expect(discountedCost(100, 0.25), 75);
    });

    test('fiyat asla sıfır olmaz', () {
      // Bedava satın alma ekonomiyi delecek bir kapı olurdu.
      expect(discountedCost(1, 0.25), 1);
      expect(discountedCost(3, 0.9), 1);
    });

    test('bozuk oran kırpılır', () {
      expect(discountedCost(100, 5), greaterThanOrEqualTo(1));
      expect(discountedCost(100, -1), 100);
      expect(discountedCost(100, double.nan), 100);
    });
  });

  group('pencere', () {
    UserProfile profile() => UserProfile(avatar: _avatar, level: 5);

    test('varsayılan kapalı', () {
      final p = profile();
      expect(p.isShopDiscountActive(now), isFalse);
      expect(p.shopDiscountRemaining(now), Duration.zero);
    });

    test('açılınca tam pencere kadar sürer', () {
      final p = profile()..openShopDiscountWindow(now);
      expect(p.isShopDiscountActive(now), isTrue);
      expect(
        p.shopDiscountRemaining(now),
        GameConstants.shopDiscountWindow,
      );
    });

    test('süre dolunca kapanır', () {
      final p = profile()..openShopDiscountWindow(now);
      final after = now.add(GameConstants.shopDiscountWindow);
      expect(p.isShopDiscountActive(after), isFalse);
      expect(p.shopDiscountRemaining(after), Duration.zero);
    });

    test('yenileme uzatmaz, sıfırlar', () {
      // İkinci macera pencereyi 60 dakikaya çıkarmamalı.
      final p = profile()..openShopDiscountWindow(now);
      final later = now.add(const Duration(minutes: 20));
      p.openShopDiscountWindow(later);
      expect(
        p.shopDiscountRemaining(later),
        GameConstants.shopDiscountWindow,
      );
    });

    test('kapat-aç kalan süreyi doğru devam ettirir', () {
      // ⚠️ Asıl risk: kalan süre saklansaydı uygulama kapalıyken işlemez
      // ve kapat-aç pencereyi uzatırdı. Bitiş anı saklandığı için geçen
      // gerçek zaman pencereden düşüyor.
      final p = profile()..openShopDiscountWindow(now);
      final round = UserProfile.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
        avatar: _avatar,
      );

      final after10 = now.add(const Duration(minutes: 10));
      expect(round.isShopDiscountActive(after10), isTrue);
      expect(
        round.shopDiscountRemaining(after10),
        GameConstants.shopDiscountWindow - const Duration(minutes: 10),
        reason: 'kapalıyken geçen süre pencereden düşmeli',
      );

      final after40 = now.add(const Duration(minutes: 40));
      expect(
        round.isShopDiscountActive(after40),
        isFalse,
        reason: 'uygulama kapalıyken pencere dolabilmeli',
      );
    });

    test('eski kayıtta pencere kapalı gelir', () {
      final round = UserProfile.fromJson(const {}, avatar: _avatar);
      expect(round.shopDiscountUntil, isNull);
      expect(round.isShopDiscountActive(now), isFalse);
    });
  });

  group('Erken Kalkan ünvanı', () {
    final title = TitleCatalog.byId(MailCatalog.earlyRiserTitleId);

    test('katalogda var ve yalnızca postadan geliyor', () {
      expect(title, isNotNull);
      expect(title!.source, TitleSource.mail);
      expect(title.cost, 0, reason: 'mağazada satılmamalı');
    });

    test('indirim etkisi taşıyor, adım kazancına dokunmuyor', () {
      final stats = title!.effects.map((e) => e.stat).toSet();
      expect(stats, contains(ItemStat.shopDiscount));
      // Faz 4 kuralı: yeni ünvanlar stepCoin/stepXp taşımaz.
      expect(stats, isNot(contains(ItemStat.stepCoin)));
      expect(stats, isNot(contains(ItemStat.stepXp)));
    });

    test('etiket oranı ile katalog oranı aynı', () {
      // İkisi ayrı yazılı; ayrışırlarsa oyuncuya yanlış yüzde gösterilir.
      final effect = title!.effects.firstWhere(
        (e) => e.stat == ItemStat.shopDiscount,
      );
      expect(effect.value, GameConstants.shopDiscountRateForLabel);
    });

    test('kuşanma toplamı indirimi taşıyor', () {
      final buffs = EquippedBuffs.from(const [], titleEffects: title!.effects);
      expect(buffs.shopDiscountBonus, GameConstants.shopDiscountRateForLabel);
      // Ekonomi oranlarına sızmamalı.
      expect(buffs.stepCoinBonus, 0);
      expect(buffs.stepXpBonus, 0);
    });

    test('ünvan yokken indirim yok', () {
      final buffs = EquippedBuffs.from(const []);
      expect(buffs.shopDiscountBonus, 0);
    });
  });
}
