import '../models/mail_message.dart';

/// Geliştirici postalarının ve kodların **sürümlü** kataloğu
/// (Bölüm D / Faz 3).
///
/// Bu dosya `data/` kuralına uyar: içinde `switch (id)` yoktur, düz veridir.
/// Metin burada **yok** — kimlikten `content_localizations.dart` ile
/// çözülür (düşman ve ünvan kataloglarıyla aynı desen).
///
/// ## Sürüm
///
/// [version] katalogun kendi sürümü. Bugün yalnızca bir not; ileride
/// sunucudan gelen katalogla yereli karşılaştırmak gerektiğinde
/// karşılaştırılacak alan bu olacak. Oyuncu tarafındaki alındı bilgisi
/// **kimliğe** bağlı olduğu için sürüm artsa bile hiçbir posta ikinci kez
/// alınamaz.
///
/// ## ⚠️ Güvenlik — kodlar APK'nın içinde
///
/// [codes] derlenmiş uygulamanın içinde duruyor. APK'yı açan biri bütün
/// kodları görebilir. **Kapalı beta için kabul edilebilir**: kod başına
/// ödül sabit, oyuncu başına bir kez ve ödülün kendisi ekonomiyi bozacak
/// büyüklükte değil.
///
/// Firebase geldiğinde (§13) kod doğrulaması **sunucuya taşınmalı**:
/// istemci yalnızca kodu gönderir, sunucu geçerliliğini ve kullanım
/// sayısını doğrular, postayı sunucu açar. O zamana kadar buradaki
/// yavaşlatma (`UserProfile.registerCodeAttempt`) yalnızca kaba kuvvetle
/// kod aramayı **sıkıcı** hale getirir, imkânsız değil.
abstract final class MailCatalog {
  MailCatalog._();

  /// Katalog sürümü. Yeni posta eklendiğinde artırılır.
  static const int version = 1;

  /// Kapalı beta teşekkür postasının kimliği.
  static const String closedBetaThanksId = 'mail_closed_beta_thanks';

  /// `WENEEDHEROES2026` kodunun açtığı postanın kimliği.
  static const String heroesCodeRewardId = 'mail_code_we_need_heroes';

  /// Erken Kalkan ünvanının kimliği. **Yalnızca** postadan gelir.
  ///
  /// Oyun çıktıktan sonra ikinci güncellemeye kadar indirenlere de
  /// verilecek; bu yüzden ad "kapalı beta" değil — kapalı beta yalnızca
  /// onu dağıtan **ilk** posta.
  static const String earlyRiserTitleId = 'early_riser';

  static final List<MailMessage> all = [
    MailMessage(
      id: closedBetaThanksId,
      kind: MailKind.reward,
      sentAt: DateTime.utc(2026, 10, 1),
      reward: MailReward(
        coins: 1000,
        wheelSpins: 5,
        titleId: earlyRiserTitleId,
      ),
    ),
    MailMessage(
      id: heroesCodeRewardId,
      kind: MailKind.reward,
      sentAt: DateTime.utc(2026, 10, 1),
      reward: MailReward(coins: 1000, wheelSpins: 5),
      // Kod karşılığı: herkese açık değil, yalnızca kodu giren görür.
      deliveredToEveryone: false,
    ),
  ];

  static final List<RedeemableCode> codes = [
    // Süresiz: `expiresAt` bilerek boş.
    RedeemableCode(
      code: 'WENEEDHEROES2026',
      mailId: heroesCodeRewardId,
    ),
  ];

  static MailMessage? byId(String id) {
    for (final mail in all) {
      if (mail.id == id) return mail;
    }
    return null;
  }

  /// Girilen metne karşılık gelen kod. Karşılaştırma **kanonik** yazımla:
  /// baştaki/sondaki boşluklar atılır, büyük harfe çevrilir.
  static RedeemableCode? findCode(String input) {
    final canonical = canonicalize(input);
    if (canonical.isEmpty) return null;
    for (final code in codes) {
      if (code.code == canonical) return code;
    }
    return null;
  }

  /// Bir kod metninin kanonik hâli. Hem arama hem kayıt bunu kullanır,
  /// yoksa "aynı kod" iki farklı yazımla iki kez kullanılabilirdi.
  static String canonicalize(String input) => input.trim().toUpperCase();
}
