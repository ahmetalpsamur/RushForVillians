/// Geliştiriciden oyuncuya giden posta (Bölüm D / Faz 3).
///
/// ## Kapsam — buraya **ne girmez**
///
/// Posta kutusu yalnızca **bizim gönderdiğimiz** şeyler içindir: telafi
/// ödülü, teşekkür ödülü, güncelleme duyurusu, kod ödülü. Macera zaferi,
/// çark, eşya düşmesi ve başarım ünvanları **bugünkü yerlerinde** kalır —
/// onları buraya taşımak oyuncuyu her ödül için ikinci bir ekrana gönderirdi.
///
/// ## Neden katalog, neden sürümlü
///
/// Firebase yok (§13) ve bu fazda da olmayacak. Posta içerikleri
/// `data/mail_catalog.dart` içinde **sabit veri** olarak duruyor; her
/// postanın değişmeyen bir [id]'si var ve oyuncu tarafı yalnızca "hangi
/// kimlikler alındı" bilgisini saklıyor (`UserProfile.claimedMailIds`).
///
/// İleride sunucu bağlandığında değişmesi gereken tek şey **listenin
/// kaynağı**: `MailCatalog.all` yerine sunucudan gelen aynı şekilli liste.
/// Model, kalıcı alanlar ve ekran olduğu gibi kalır. Bu yüzden:
/// - [id] kalıcı ve asla değişmez (§10 #6),
/// - metin **modelde taşınmıyor**, kimlikten çözülüyor (aşağıda),
/// - ödül düz `int`/`String` (Model Kuralları #1 temiz).
///
/// ## Metin neden modelde değil
///
/// Başlık ve gövde `l10n/content_localizations.dart` üzerinden [id] ile
/// çözülür — düşman, ünvan ve rehber metinleriyle **aynı desen** (Faz 3).
/// Metni modele koymak tek dilli bir katalog demekti.
library;

/// Postanın türü. Yalnızca sunumu etkiler; ödül mantığı [reward] üzerinden.
enum MailKind {
  /// Ödül taşıyan posta (teşekkür, telafi, kod karşılığı).
  reward,

  /// Yalnızca okunacak duyuru.
  announcement,
}

/// Bir postanın taşıdığı ödül.
///
/// Hepsi düz sayı/kimlik: diske yazılan hiçbir şeyde framework tipi yok.
class MailReward {
  final int coins;
  final int wheelSpins;

  /// Verilecek ünvanın kimliği; yoksa `null`.
  final String? titleId;

  const MailReward({this.coins = 0, this.wheelSpins = 0, this.titleId});

  static const none = MailReward();

  bool get isEmpty => coins == 0 && wheelSpins == 0 && titleId == null;
}

/// Tek bir posta kaydı.
class MailMessage {
  /// Kalıcı kimlik. **Asla değişmez** — alındı bilgisi buna yazılıyor.
  final String id;

  final MailKind kind;
  final MailReward reward;

  /// Postanın oyuncuya ne zaman göründüğü; sıralama için.
  final DateTime sentAt;

  /// Dolu bırakılırsa bu tarihten sonra posta listelenmez.
  ///
  /// Bugün hiçbir posta kullanmıyor; alan **ileride bir etkinlik postası**
  /// için duruyor ve kod kataloğundaki aynı alanla simetrik.
  final DateTime? expiresAt;

  /// `true` ise posta herkese açık: katalogda durduğu sürece listelenir.
  /// `false` ise yalnızca **kazanılmışsa** listelenir
  /// (`UserProfile.pendingMailIds`) — kod karşılığı gelen postalar böyle.
  final bool deliveredToEveryone;

  const MailMessage({
    required this.id,
    required this.kind,
    required this.sentAt,
    this.reward = MailReward.none,
    this.expiresAt,
    this.deliveredToEveryone = true,
  });

  bool get hasReward => !reward.isEmpty;

  bool isAvailableAt(DateTime now) =>
      expiresAt == null || now.isBefore(expiresAt!);
}

/// Oyuncunun girdiği bir kodun karşılığı.
///
/// ⚠️ **Kod doğrudan ödül vermez**, bir posta açar. Böylece ödül dağıtımının
/// **tek yolu** posta kutusu olur: iki ayrı dağıtım yolu olsaydı "iki kez
/// verme" korumasını da iki kez yazmak gerekirdi.
class RedeemableCode {
  /// Kanonik yazım: **büyük harf, boşluksuz**. Karşılaştırma bunun üzerinden.
  final String code;

  /// Kodun açtığı postanın kimliği.
  final String mailId;

  /// Dolu bırakılırsa bu tarihten sonra kod kabul edilmez.
  final DateTime? expiresAt;

  const RedeemableCode({
    required this.code,
    required this.mailId,
    this.expiresAt,
  });

  bool isActiveAt(DateTime now) =>
      expiresAt == null || now.isBefore(expiresAt!);
}

/// Kod girme denemesinin sonucu. Her durum **ayrı** bir mesaj alır.
enum CodeRedemptionResult {
  success,

  /// Katalogda böyle bir kod yok.
  invalid,

  /// Bu oyuncu bu kodu zaten kullanmış.
  alreadyUsed,

  /// Kodun süresi dolmuş.
  expired,

  /// Kutu boş bırakılmış.
  empty,

  /// Çok fazla yanlış deneme; bir süre beklenmeli.
  throttled,
}
