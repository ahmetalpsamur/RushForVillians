# Adımla seviye ve 7.000 günlük hedef

Seviye yalnızca mevcut adım kaynağının kabul ettiği adımlarla ilerler. XP, ödül ve başarım kaynağı olarak korunur; seviye artırmaz. Yeni bir maksimum seviye eklenmedi.

## Hesaplama ve arayüz

- `lib/core/utils/level_steps.dart`: `500 * pow(1 + log(level), 1.5)`, en yakın 50'ye yuvarlama; geçersiz sıfır/negatif seviyeler için güvenli seviye 1.
- `UserProfile.creditLevelStepsThrough`: kabul edilmiş toplam adım sayacının yalnızca yeni kısmını işler. Tekrarlanan veya azalan sayaçlar ilerleme üretmez. Fazla adımlar korunur, bir güncellemede birden fazla seviye verilir.
- Ana ekran ve profil seviye çubukları mevcut seviyenin adım ilerlemesini gösterir. XP profilde ayrıca gösterilir. Mevcut seviye atlama olayı ve kutlaması kullanılır.
- `GameConstants.dailyStepGoal = 7000`: günlük modelin başlangıcı, eski kayıt geçişi ve gün yenilemesi bu değeri kullanır. Ana ekranda günlük hedef ve mevcut/hedef adım gösterilir. TR/EN açıklamalar güncellendi.
- Macera seçmek veya bırakmak günlük hedefi değiştirmez. Günlük sıfırlama mevcut oyun günü mantığını kullanır; seviye ilerlemesini sıfırlamaz. Seri ve çarkın mevcut bağımsız açılma eşikleri korunur.
- 1→80 için toplam **371.850 adım** gerekir. Günde 5.000 adımla **75. gün** seviye 80'e ulaşılır.

## Kayıt güvenliği

SharedPreferences ve mevcut anahtarlar korunur. Şema 24→25 geçişi eski seviye, XP, toplam/günlük adımlar, para, envanter, ekipman, görev/ödül bilgileri ve tutorial ilerlemesini korur. Geçmiş günlerin hedefleri değiştirilmez; mevcut günün hedefi 7.000 olur.

Yeni `levelStepProgress` alanı yoksa 0, `lastLevelRewardedStepCount` yoksa mevcut toplam adım kullanılır. Karışık kaynaklardan kazanılmış eski XP geriye dönük seviyeye çevrilmez. Alanlar zaten varsa ilerleme korunur.

Geçişte model önce doğrulanır, orijinal kayıt `game_state_v1_migration_backup` altında yedeklenir, ardından yeni sürüm yazılır. Başarılı geçiş sonraki açılışta tekrarlanmaz. Bozuk/okunamayan veya daha yeni sürümlü kayıtlar varsayılan durumla ezilmez; oturum yazmaları engellenir ve kullanıcı uyarılır. Karakter kaydı da okuma hatasına karşı korunur.

Üretimde otomatik kayıt temizleme çağrısı bulunmadı. `GameStorage.clear()` release modunda engellendi. Yeni backend veya kaldırma sonrası geri yükleme sistemi eklenmedi; uygulamayı tamamen kaldırmak yerel kaydı silebilir.

## Değişen dosyalar

Uygulama kodu:

- `lib/app.dart`
- `lib/core/constants/game_constants.dart`
- `lib/core/utils/base_combat_stats.dart`
- `lib/core/utils/level_steps.dart` (yeni)
- `lib/features/home/home_screen.dart`
- `lib/features/profile/profile_screen.dart`
- `lib/features/root/root_shell.dart`
- `lib/models/daily_progress.dart`
- `lib/models/user_profile.dart`
- `lib/services/character_storage.dart`
- `lib/services/game_storage.dart`
- `lib/services/level_events.dart`
- `lib/widgets/hero_progress_rings.dart`

Çeviriler ve üretilen karşılıkları:

- `lib/l10n/app_en.arb`
- `lib/l10n/app_tr.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_tr.dart`

Testler:

- `test/level_steps_test.dart` (yeni)
- `test/level_steps_shell_test.dart` (yeni)
- `test/economy_pacing_test.dart`
- `test/game_storage_test.dart`
- `test/hero_progress_rings_test.dart`
- `test/item_leveling_test.dart`
- `test/step_xp_test.dart`
- `test/streak_bonus_shell_test.dart`

## Doğrulama

- `flutter analyze --no-pub lib test`: sorun yok.
- 16 test dosyasında **230 test geçti**: level_steps, level_steps_shell, step_xp, game_storage, economy_pacing, item_leveling, hero_progress_rings, pedometer_step_source, game_day, daily_engagement, victory_wheel_unlock, tutorial_guide, streak, streak_stat_bonus, streak_freeze, streak_bonus_shell.
- `adventure_progress_test.dart` içindeki “macera seçimi günlük” grubu: **3 test geçti**. Toplam **233 başarılı test**.
- Formül örnekleri, 499/500 sınırı, fazla adım, çoklu seviye, tekrar/negatif adım, yeniden açılış, zengin eski kayıt geçişi, bozuk kayıt koruması, 7.000 günlük hedef ve gün değişiminde seviye koruması doğrulandı.
- `git diff --check`: hata yok.
- `flutter build apk --debug --no-pub`: başarılı; `build/app/outputs/flutter-apk/app-debug.apk` oluşturuldu.
- Release APK derlemesi `:app:packageRelease` imzalama aşamasında mevcut `upload-keystore.jks` için “Keystore was tampered with, or password was incorrect” hatası verdi. İmza dosyası ve parolası değiştirilmedi. İmzalı release APK doğrulanamadı.

Gerçek cihazda Play üzerinden eski sürümün üstüne kurulum testi bu oturumda yapılmadı; kayıt geçişi otomatik testlerle doğrulandı.

Önerilen commit mesajı: `feat: add step-based leveling and safe daily-goal migration`
