import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_context.dart';

/// Güvenlik metinleri ve bağımsız sürümlenen cihaz uyarısı.
///
/// Metinler ARB'den geliyor (GD85). Eskiden bu sınıf `tr ? ... : ...` deseniyle
/// iki dili elle taşıyordu; resmî yerelleştirme hattının dışında kalan tek
/// kullanıcı metni burasıydı.
///
/// **Metinler bilerek dürüst:** bir dönem "süre sınırı yok" diyorlardı, oysa
/// round'un süre sınırı **var** (`AttackConfig.durationForSteps`). Oyuncuya
/// yanlış söylenen şey güvenlik metniyse, bu bir üslup sorunu değil. Yeni
/// metinler süre sınırını açıkça kabul ediyor ve karşılığında doğru olanı
/// söylüyor: **süre var ama senden bir karar beklenmiyor**, o yüzden ekrana
/// bakman gerekmiyor.
class SafetyMessages {
  /// Uyarı metni anlamlı biçimde değişince artırılır; kullanıcı yeniden onaylar.
  ///
  /// v1 → v2: "süre sınırı yok" yanlış bilgisi kaldırıldı ve uyarılar
  /// trafik, karanlık, kulaklık gibi gerçek riskleri ismen sayar hâle geldi.
  static const noticeVersion = 2;

  final AppLocalizations l10n;

  const SafetyMessages._(this.l10n);

  factory SafetyMessages.of(BuildContext context) =>
      SafetyMessages._(context.l10n);

  /// Testlerin ve çağrı noktalarının dili elle verebildiği kapı.
  factory SafetyMessages.from(AppLocalizations l10n) = SafetyMessages._;

  String get title => l10n.safetyTitle;

  String get pageTitle => l10n.safetyPageTitle;

  /// Güvenlik sayfasında **hepsi birden** gösterilen uyarı maddeleri.
  ///
  /// Sıralı ve sabit: rastgele seçim ya da döndürme yok. Bir maddeyi hiç
  /// görmemiş kullanıcı kalmamalı.
  List<String> get tips => [
    l10n.safetyTip1,
    l10n.safetyTip2,
    l10n.safetyTip3,
    l10n.safetyTip4,
    l10n.safetyTip5,
    l10n.safetyTip6,
    l10n.safetyTip7,
    l10n.safetyTip8,
  ];

  /// Maddelerin tek bir metin bloğu hâli.
  ///
  /// Ekran davranışı korunuyor: sayfa eskiden de tek bir blok gösteriyordu.
  /// Madde sayısı değişirse burası kendiliğinden uyum sağlar.
  String get fullNotice => tips.join('\n\n');

  String get checkbox => l10n.safetyAcknowledgement;

  String get continueLabel => l10n.safetyContinue;

  String get saveError => l10n.safetySaveError;

  String get firstSafety => l10n.safetyFirstSafety;

  String get adventureNotice => l10n.safetyAdventureNotice;

  String get walkingAcknowledgement => l10n.safetyWalkingAcknowledgement;

  String get startAdventure => l10n.safetyStartAdventure;

  String get battleNotice => l10n.safetyBattleNotice;

  String get startBattle => l10n.safetyStartBattle;

  String get later => l10n.safetyLater;

  String get walking => l10n.safetyWalking;

  /// Eski adı `noTimeLimit` idi ve **yanlış** bilgi veriyordu; süre sınırı var.
  String get timeLimitNotice => l10n.safetyTimeLimitNotice;

  String get ready => l10n.safetyReady;

  /// Bağlam okunamadığında gösterilecek en kısa uyarı.
  String get fallbackNotice => l10n.fallbackSafetyMessage;
}
