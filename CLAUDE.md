# CLAUDE.md

Bu dosyadaki kurallar tüm oturumlarda geçerlidir.

> ## 🧭 NEREDEN BAŞLAMALI
>
> Bu dosya ~4000 satır ve **kronolojik** — eski bölümler tarihsel kayıt, güncel
> durum sonda. Yeni bir oturuma başlıyorsan:
>
> 1. Bu baştaki **Çalışma Kuralları** + **Model Kuralları** bölümünü oku
>    (zorunlu, kısa).
> 2. **Dosyanın en sonuna git:** "⭐ OTURUM KAPANIŞI — 2026-08-26 ·
>    SONRAKİ OTURUM BURADAN BAŞLASIN". Ne bitti, ne açık, sıradaki işin
>    (**Bölüm 8 — iki fazlı macera**) tam şartnamesi — hepsi orada ve
>    **tek başına yeterli**. Daha eski kapanışlar (2026-08-19, 08-20,
>    08-25 SABAH/AKŞAM) tarihsel kayıt.
> 3. Test çalıştırmadan önce **"Test ortamı — testler neden `--no-test-assets`
>    ile çalışıyor"** bölümünü oku. Bu bayrak olmadan hiçbir test çalışmaz.
> 4. Verilmiş kararları değiştirmeden önce **"GERİ DÖNÜLECEK KARARLAR"**
>    (GD1–GD43) içinde gerekçesini ara.
>
> Aradaki "Aşama 0…3g", "Bug Triajı", "Trello Kartları" ve eski oturum
> kapanışları **tarihsel bağlam**. Bir çelişki görürsen **en yeni tarih
> geçerlidir**.

## Çalışma Kuralları

1. **MEVCUT KODA SAYGI:** Bu projede zaten yazılmış, çalışan kod var. Hiçbir dosyayı
   "daha iyisini yazayım" diye baştan yazma. Mevcut yapıyı, isimlendirmeyi, mimariyi
   ve kod stilini olduğu gibi benimse ve onun üstüne ekle.

2. **SIFIRDAN YAZMA YASAĞI:** Bir dosyayı tamamen değiştirmen gerektiğini düşünüyorsan
   ÖNCE sor, nedenini açıkla, onay bekle. Kendiliğinden büyük refactor yapma.

3. **ÖNCE OKU:** Herhangi bir değişiklik yapmadan önce ilgili mevcut kodu oku. Aynı işi
   yapan bir fonksiyon/sınıf zaten varsa onu kullan, ikinci bir tane yazma.

4. **KÜÇÜK ADIMLAR:** Büyük değişiklikleri parçala. Her adımdan sonra
   `flutter analyze` çalıştır, hata varsa devam etme.

5. **BOZMA:** Mevcut çalışan bir özelliği bozacak bir değişiklik yapman gerekiyorsa
   önce söyle. Var olan testleri silme veya devre dışı bırakma.

6. **EMİN DEĞİLSEN SOR:** Kartın ne istediği veya mevcut kodun nasıl çalıştığı konusunda
   emin değilsen tahmin etme, sor.

7. **TÜRKÇE İSİMLENDİRME:** Projede mevcut isimlendirme dili neyse (Türkçe/İngilizce)
   ona uy, karıştırma.

---

## Model Kuralları

1. **KALICI MODELDE FRAMEWORK TİPİ YOK:** Kalıcı hale gelecek (diske veya
   Firebase'e yazılacak) hiçbir modelde Flutter framework tipi tutulmaz —
   `IconData`, `Color`, `Widget`, `TextStyle` gibi. Bunların yerine `String`
   veya `int` anahtar tutulur, görsel karşılığı katalogdan çözülür.
   **Sebep:** release build'de `--tree-shake-icons`, sabit olmayan `IconData`
   üretimini bozar; serileştirilmiş ikon kodu geri yüklendiğinde ikon kaybolur.
   İyi örnek: `models/enemy.dart` asset yollarını `String` olarak tutuyor.

2. **Serileştirme elle yazılır.** Proje `build_runner` kullanmıyor;
   `freezed`/`json_serializable` getirme. İzlenecek desen:
   `AvatarProfile`, `UserProfile`, `GameState`.

3. **Gün hesabı tek yerden:** `lib/core/utils/game_day.dart`. Hiçbir yerde
   ikinci bir `a.day == b.day` karşılaştırması yazma; `GameDay.isSameGameDay`,
   `GameDay.daysBetween`, `GameDay.nextResetAfter`, `GameDay.timeUntilReset`
   kullan. Gün sınırı `GameDay.dayStartHour` = **04:00**.

5. **Şimdiki zaman tek yerden:** `lib/core/utils/game_clock.dart`. Gün, seri
   ve çark hesaplarında `DateTime.now()` **yazma**; `GameClock.now()` kullan.
   Hem test edilebilirlik hem de geriye alınan cihaz saatine karşı koruma
   oradan geliyor. Aşama 6a'da sunucu saatine tek noktadan geçilecek.

4. **Devre dışı kontrol sessiz kalmaz.** Kilitli bir buton/kart neden kilitli
   olduğunu söylemeli: kilit ikonu + dokununca açıklama. İzlenecek desen:
   `features/home/home_screen.dart` içindeki `_QuickAction.disabledReason`.

---

## Build Zinciri ve Ortam

**Bu proje Flutter 3.47.0 gerektirir.** Eski Flutter kullanan takım üyeleri
`flutter upgrade` yapmalı.

Flutter 3.47.0 eski sürümleri reddettiği için build zinciri yükseltildi
(2026-08-18, elle terminalden yapıldı):

| Dosya | Ne | Eski → Yeni |
|---|---|---|
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle | 8.10.2 → 8.14.3 |
| `android/settings.gradle.kts` | AGP | 8.7.0 → 8.11.1 |
| `android/settings.gradle.kts` | Kotlin | 1.8.22 → 2.2.20 |

- **JDK 25 kullananlar:** Gradle 8.14.3 Java 25'i desteklemiyor.
  `flutter config --jdk-dir=<jdk-21-yolu>` çalıştırılmalı.
- **AGP 9+ ve Gradle 9.x geçişi ertelendi:** Flutter Gradle eklentisi AGP 9'un
  yeni DSL'iyle uyumsuz. Aşama 1 sonrası tekrar değerlendirilecek.

---

# Proje: Rush For Villains

Adım sayar tabanlı Flutter RPG'si. Gerçek adım sayısı hem macera haritasındaki
ilerlemeyi hem de oyun içi kazancı besler. Oyuncu yürüdükçe düşmanla savaşır,
XP ve item kazanır; itemler buff verir ve seviye kilidine tabidir. Günlük streak
ve şans çarkı var. İleride gerçek oyuncuların takım kurup çok düşmanlı takım
savaşı yapması planlanıyor. Backend olarak Firebase (Firestore + Auth) planlanıyor.

**Analiz tarihi:** 2026-08-17 · **Branch:** `feature/claude-gelistirme` · **Son commit:** `dcd3e0c Huge Update`

## 1. Mimari

- **Desen:** Feature-first + paylaşılan katmanlar. Katmanlı (data/domain/presentation)
  ayrım YOK; repository/usecase katmanı YOK.
- **State management:** Paket kullanılmıyor. Tüm oyun state'i tek bir
  `StatefulWidget` içinde — `lib/features/root/root_shell.dart` — `setState` ile
  yönetiliyor. Alt ekranlar `StatelessWidget` ve state'i `final` alan + callback
  (`ValueChanged`, `VoidCallback`) ile alıyor. Dosyanın kendi yorumunda "ileride
  Riverpod/Bloc'a taşınabilir" notu var.
- **Routing:** Deklaratif router yok. `MaterialApp.home` + imperatif
  `Navigator.push(MaterialPageRoute(...))`. `RootShell._push()` tek yardımcı;
  pop sonrası `setState(() {})` ile ekranı tazeliyor.
- **Navigasyon iskeleti:** `RootShell` içinde 5 sekmeli `NavigationBar`
  (Ana Sayfa / Macera / Mağaza / Takım / Profil), `tabs[_tabIndex]` ile gövde seçiliyor.
- **Açılış akışı:** `main.dart` → bildirim servisi init → `RushForVilliansApp`
  (`app.dart`) → `CharacterStorage.load()`; avatar yoksa `CharacterCreationScreen`,
  varsa `RootShell`.

### Klasör yapısı (`lib/`)

```
lib/
├── main.dart                     # giriş noktası, servis init
├── app.dart                      # MaterialApp + avatar var/yok yönlendirmesi
├── core/
│   ├── constants/game_constants.dart   # denge sabitleri
│   ├── theme/app_theme.dart            # AppColors + AppTheme.dark
│   └── utils/reward_calculator.dart    # adım oranı → RewardRarity
├── data/
│   ├── enemy_catalog.dart        # 4 düşmanın sabit tanımı (const)
│   └── mock_data.dart            # takım, mağaza, çark, ejderha demo verisi
├── models/                       # düz Dart sınıfları (11 dosya)
├── services/
│   ├── adventure_notification_service.dart  # flutter_local_notifications
│   ├── character_catalog.dart    # AssetManifest'ten karakter sınıflarını okur
│   └── character_storage.dart    # SharedPreferences ile avatar kalıcılığı
├── features/<feature>/<feature>_screen.dart  # 9 ekran
├── widgets/                      # paylaşılan UI parçaları (5 dosya)
├── Characters/<Sınıf>/*.png      # avatar görselleri (asset)
└── Enemies/<Düşman>/*.gif        # düşman animasyonları (asset)
```

Toplam ~4.360 satır Dart. En büyük dosyalar:
`character_creation_screen.dart` (1047), `adventure_screen.dart` (699),
`root_shell.dart` (348), `hero_progress_rings.dart` (269).

### Kod stili ve isimlendirme kuralları (bunlara uy)

- **Kod dili İngilizce, kullanıcıya görünen metin ve yorumlar Türkçe.**
  Sınıf/değişken/dosya adları İngilizce (`AdventureQuest`, `remainingHealth`),
  dartdoc yorumları ve UI stringleri Türkçe. Bu ayrımı bozma.
- Dosya adları `snake_case`, ekranlar `<feature>_screen.dart`, sınıflar
  `<Feature>Screen`. **İstisna:** `lib/Characters/` ve `lib/Enemies/` asset
  klasörleri PascalCase ve Türkçe klasör adları içeriyor
  (`Gergin Asker/`, `Tekinsiz Canavar!/`) — boşluk ve `!` dahil, dokunma.
- Alan tanımları `final <Tip> <ad>;` şeklinde, `const` constructor tercih ediliyor,
  parametreler `required` named.
- Statik yardımcı sınıflar private constructor ile kapatılıyor:
  `class GameConstants { GameConstants._(); ... }` — yeni servis/katalog eklerken
  aynı deseni kullan.
- Ekran içindeki yardımcı widget'lar aynı dosyada `_` prefix'li private sınıf
  olarak yazılıyor (`_QuickAction`, `_EnemyChoiceCard`, `_NeonOption`).
- Dart 3 özellikleri kullanılıyor: switch expression (`=> switch (this) {...}`),
  extension (`RewardRarityX`), record (`('Kadın', Icons.female)`).
- Renkler `AppColors` üzerinden; ekran içinde ham `Color(0x...)` sadece karakter
  yaratma ekranının neon paletinde var.
- Sürekli tekrar eden UI için `SectionCard` ve `StatBar` widget'ları var —
  yeni kart/çubuk yazmadan önce bunları kullan.
- **Yazım notu:** repo adı ve `RushForVilliansApp` sınıfı "Villians" (hatalı),
  paket adı `rush_for_villains` (doğru). Mevcut haliyle bırakıldı; yeni kodda
  hangi bağlamdaysan ona uy.

## 2. Paketler (`pubspec.yaml`)

| Paket | Sürüm | Durum |
|---|---|---|
| `flutter_local_notifications` | ^19.5.0 | **Aktif** — `adventure_notification_service.dart` |
| `shared_preferences` | ^2.5.3 | **Aktif** — `character_storage.dart` (sadece avatar) |
| `timezone` | ^0.10.1 | **Aktif** — bildirim zamanlaması (`tz.UTC` sabit) |
| `flutter_lints` | ^5.0.0 | **Aktif** (dev) |

- Kullanılmayan paket yok.
- **Eksik olanlar:** pedometer/health paketi yok, Firebase paketleri yok,
  state management paketi yok, HTTP/serialization paketi yok, `mocktail`/`bloc_test` yok.
- SDK: `^3.7.2`. `analysis_options.yaml` = `flutter_lints` + platform klasörleri exclude.
- Android: `multiDexEnabled`, `coreLibraryDesugaring 2.1.4` (bildirimler için gerekli),
  `applicationId com.ahmetalpsamur.rush_for_villains`. Platform klasörleri: sadece
  `android/` ve `ios/` (web/desktop yok).

## 3. Çalışan Özellikler

| Ekran / Özellik | Dosya | Durum |
|---|---|---|
| Karakter yaratma sihirbazı (7 adım: isim→cinsiyet→yaş→kilo→sınıf→görünüm→özet) | `features/character/character_creation_screen.dart` | **~%95.** Tam çalışıyor; haptic, neon tema, `ListWheelScrollView`, düzenleme modu (`initialAvatar`) dahil. Projedeki en olgun ekran. |
| Ana sayfa (HP/XP/adım halkası, macera özeti, hızlı erişimler) | `features/home/home_screen.dart` + `widgets/hero_progress_rings.dart` | **~%85.** Çalışıyor. `_StepRingPainter` ile özel halka + tur sayacı. Alt tarafta "Demo Kontrolleri" (+1000/+5000/+20000 adım butonları) var. |
| Macera: düşman/hedef seçimi ve sıra tabanlı savaş | `features/adventure/adventure_screen.dart` | **~%80.** Çalışıyor ve en zengin oyun döngüsü burada. Tur sayacı, düşman saldırı/hasar/ölüm GIF animasyonları, yenilgi & zafer ekranları. |
| Macera savaş mantığı | `models/adventure_quest.dart` | **Çalışıyor, testli.** 1000 adım = 1 tur, tur süresi = adım/100 dk + 1 dk senkron payı; tur sonunda eksik adım oranına göre oyuncu hasar alır. |
| Profil (avatar, seviye, HP/XP çubukları, streak, coin) | `features/profile/profile_screen.dart` | **~%90** görsel olarak; ama gösterdiği HP/coin/streak değerleri henüz gerçek oyun döngüsüne bağlı değil. |
| Günlük çark | `features/wheel/daily_wheel_screen.dart` | **~%60.** Çalışıyor ama basit: `AnimatedRotation` + `Random`, gerçek çark grafiği yok, günlük sıfırlama yok (uygulama kapanınca `_wheelSpunToday` sıfırlanır). |
| Mağaza | `features/store/xp_store_screen.dart` | **~%50.** Grid + satın alma çalışıyor ama coin hiç kazanılmadığı için pratikte kullanılamıyor. Item envantere eklenmiyor, buff/seviye kilidi yok. |
| Takım | `features/team/team_screen.dart` | **~%30.** Salt görsel, `MockData.defaultTeam()` sabit 3 üye. Backend/eşleşme yok. |
| Ödüllerim | `features/rewards/rewards_screen.dart` | **~%40.** Liste UI hazır ama `RootShell._rewards` listesine hiçbir yerden ekleme yapılmıyor → her zaman boş. |
| Bildirimler | `services/adventure_notification_service.dart` | **~%70.** Uygulama arka plana alınınca 10'ar dk arayla en fazla 16 hatırlatma planlıyor, düşman saldırı GIF'ini attachment olarak ekliyor, öne gelince iptal ediyor. |
| Karakter kalıcılığı | `services/character_storage.dart` | **%100** — SharedPreferences + JSON. Kalıcı olan **tek** veri bu. |
| Karakter kataloğu | `services/character_catalog.dart` | **%100** — `AssetManifest` üzerinden `lib/Characters/<Sınıf>/*.png` tarayıp sınıf listesi üretiyor. Yeni sınıf = klasör + pubspec asset satırı. |

## 4. Yarım Kalanlar / Bilinen Eksikler

**Kod içi işaretler:**
- `models/adventure_quest.dart:113` — `TODO(combat)`: düşman canı şu an günlük adım
  hedefine eşit, her adım 1 hasar. Can/saldırı/hasar ayrı combat istatistiği olmalı.
- `data/mock_data.dart:7` — "İleride bir backend veya yerel veritabanı ile değiştirilecek".
- `features/root/root_shell.dart:24` — "Şimdilik yerel state; ileride Riverpod/Bloc".
- `models/team.dart:13` — yan yana yürüme gerçekte konum/zaman senkronu ile hesaplanacak.
- `android/app/build.gradle.kts` — Flutter şablonundan gelen TODO'lar (applicationId,
  release signing config hâlâ debug key kullanıyor).
- `README.md` hâlâ "A new Flutter project." (şablon).

**Ölü / bağlanmamış kod:**
- `features/boss/boss_battle_screen.dart` (168 satır) **hiçbir yerden çağrılmıyor.**
  Yanında `models/boss_quest.dart`, `MockData.dailyDragon()` ve
  `core/utils/reward_calculator.dart` de yalnızca bu ekran üzerinden kullanılıyor →
  fiilen ölü zincir. Ödül nadirlik sistemi (`RewardRarity`, `RarityBadge`) sadece
  burada gerçekten üretiliyor.
- `RootShell._rewards` listesi hiç doldurulmuyor → Ödüllerim ekranı hep boş.
- `UserProfile.lastActiveDay` tanımlı ama hiç yazılmıyor/okunmuyor.
- `GameConstants.sideBySideWindowMinutes` tanımlı ama kullanılmıyor.

**Oyun döngüsündeki boşluklar:**
- **Para (coin) hiç kazanılmıyor.** `coins` sadece `_purchase`'ta azalıyor;
  artıran kod yok. Mağaza butonu "N XP" yazıyor ama `coins` harcıyor (etiket/kaynak tutarsız).
- **Item / envanter / buff / seviye kilidi sistemi hiç yok.** `XpStoreItem` sadece
  isim-açıklama-fiyat-ikon; satın alınan item hiçbir yere yazılmıyor.
- **Streak sahte:** `_simulateSteps` içinde hedefe ulaşınca `streakDays` 0→1 oluyor,
  başka artış yok, gün değişimi izlenmiyor.
- **Oyuncu HP'si (`UserProfile.hp`, 5000) hiç değişmiyor.** Savaştaki can ayrı bir
  alan: `AdventureQuest.playerHealth` (0-100). İki ayrı can kavramı birleştirilmemiş.
- **Günlük sıfırlama yok.** `DailyProgress` uygulama açılışında sıfırdan kuruluyor,
  tarih kontrolü yapılmıyor.
- **XP dışında kalıcılık yok:** adım, macera, seviye, coin, streak — uygulama kapanınca
  hepsi sıfırlanıyor. Sadece avatar kaydediliyor.
- **Macera haritası yok.** Konsepte göre bir "macera haritası" var ama kodda düşman
  seçim listesi + tek düşmanla savaş var; harita/ilerleme düğümü yok.
- **Takım savaşı yok** (planlanan çok oyunculu mod).
- Bildirim ekranındaki hatırlatma metinleri iki yerde kopyalanmış:
  `root_shell.dart:_reminderMessages` ve `adventure_notification_service.dart:_messages`.

## 5. Veri Katmanı

> **GÜNCEL (2026-08-18):** Aşama 0 tamamlandı — yerel kalıcılık eklendi.
> Aşağıdaki tespitler analiz anına aittir; güncel durum için dosya sonundaki
> "Aşama 0 — Yerel Kalıcılık" bölümüne bak.

- **Firebase BAĞLANMAMIŞ.** Ne pubspec'te firebase paketi, ne `firebase_options.dart`,
  ne `google-services.json`, ne `GoogleService-Info.plist` var. Sıfırdan kurulacak.
- **Local storage:** yalnızca `shared_preferences`, yalnızca avatar için
  (`CharacterStorage`, key: `player_avatar_v1`). Hive/sqflite/Drift yok.
- **Sabit veri:** `data/enemy_catalog.dart` (4 düşman, `const`) ve `data/mock_data.dart`
  (takım, mağaza, çark ödülleri, ejderha) derleme zamanı sabitleri.
- **Model sınıfları:** düz Dart sınıfı, elle yazılmış; `freezed`/`json_serializable`
  yok, `build_runner` yok. `copyWith` yok. Çoğu model **mutable** (`int playerHealth;`
  gibi alanlar doğrudan değiştiriliyor) — mevcut `setState` mimarisi buna dayanıyor.
- **Serileştirme:** yalnızca `AvatarProfile` içinde elle `toJson()` / `fromJson()`
  yazılmış. Firebase'e geçerken diğer modeller için aynı elle yazma desenini izle
  (proje `build_runner` kullanmıyor).
- Model listesi: `adventure_quest` (+`CombatRoundResult`), `avatar_profile`, `boss_quest`,
  `character_class`, `daily_progress`, `enemy`, `reward`, `reward_rarity`,
  `team` (+`TeamMember`), `user_profile`, `xp_store_item`.

## 6. Adım Sayar

- **Pedometer entegrasyonu YOK.** `pedometer`, `health`, `sensors_plus` gibi hiçbir
  paket yok; hiçbir platform kanalı yok.
- Adımlar `HomeScreen`'deki "Demo Kontrolleri" bölümünden manuel simüle ediliyor
  (`+1000 / +5000 / +20000` butonları → `RootShell._simulateSteps`).
  Ekranda "Gerçek adım sayacı entegrasyonu gelene kadar..." notu var.
- **İzinler yapılandırılmamış:**
  - Android: `ACTIVITY_RECOGNITION` **yok**, `POST_NOTIFICATIONS` **yok**
    (Android 13+ için gerekli; kodda `requestNotificationsPermission()` çağrılıyor
    ama manifest izni tanımlı değil → sessizce başarısız olur).
    Manifest'te sadece `RECEIVE_BOOT_COMPLETED` var.
  - iOS: `NSMotionUsageDescription` **yok**, `UIBackgroundModes` **yok**.
- Bildirim servisi `tz.setLocalLocation(tz.UTC)` ile sabit UTC kullanıyor; cihaz saat
  dilimi okunmuyor (`flutter_timezone` yok). Göreli offsetlerle çalıştığı için
  şimdilik sorun çıkarmıyor ama günlük/saat bazlı bildirimlerde sorun olacak.

## 7. Testler

- Tek test dosyası: `test/adventure_quest_test.dart` — 4 test, `AdventureQuest`
  savaş dengesini kapsıyor (düşman eşikleri, tur süresi, eksik adım hasarı, tam tur).
- **`flutter test` → 4/4 geçiyor.** ✅
- Widget testi, golden testi, servis testi YOK. Ekranların hiçbiri test edilmiyor.
- **Not:** Bu ortamda bir hook `flutter test` komutunu bash üzerinden engelleyip
  Very Good CLI istiyor. Testleri PowerShell üzerinden `flutter test` ile çalıştır.

## 8. Sağlık Kontrolü

- **`flutter analyze` → "No issues found!"** — 0 hata, 0 uyarı. ✅
- **`flutter test` → All tests passed (4 test).** ✅
- Git durumu: `analysis_options.yaml` ve `pubspec.lock` commit edilmemiş değişiklik
  içeriyor (analysis_options'a platform klasörü exclude'ları eklenmiş).

## Özet Durum

Proje sağlıklı, temiz ve tutarlı yazılmış bir **UI prototipi**. Analyze temiz,
testler geçiyor. Oyunun görsel katmanı ve macera savaş mekaniği gerçekten çalışıyor.
Eksik olan üç büyük parça: **(1)** gerçek adım sayacı, **(2)** kalıcılık/backend
(Firebase), **(3)** ekonomi + item/envanter sistemi. State tek bir `setState`'li
`RootShell`'de toplandığı için bu üç parça eklenirken state yönetimi de büyüyecek.

---

# Trello Kartları ↔ Kod Karşılaştırması (2026-08-17)

> Not: Pano "15 kart" olarak tarif edildi, listede **18 madde** var. Aşağıda 18'i de
> numaralandırdım.

## 🔑 Analiz sırasında çıkan kritik bulgu

**`lib/Items/` klasöründe 784 adet item görseli hazır duruyor** ve hiçbiri kullanılmıyor:

| Kategori | Adet | Kategori | Adet |
|---|---|---|---|
| `swords/` | 180 | `spears/` | 60 |
| `magic/` | 172 | `ranged_other/` | 56 |
| `shields/` | 112 | `axes_halberds/` | 45 |
| `arch/` | 84 | `scythes/` | 15 |
| `maces_hammers/` | 57 | `special_other/` | 3 |

Dosya adları anlamlı ve tutarlı (`fire_bow.png`, `energy_crossbow.png`,
`knockback_arrow.png`, `longbow_variant_01..07.png`). **`pubspec.yaml`'a
eklenmemişler**, yani şu an APK'ya bile girmiyorlar. Bu, tüm Items/Mağaza
kartlarının maliyetini düşürüyor: **sanat işi bitmiş, sadece veri modeli + katalog
yazılacak.** `CharacterCatalog`'daki `AssetManifest` tarama deseni birebir
kopyalanabilir.

Ayrıca `lib/GIF Animations/Soldier/` (7 GIF) kullanılmıyor — `lib/Enemies/Gergin Asker/`
altındaki dosyaların gölgeli kopyası.
`lib/Characters/DarkMagic/Nature/` yanlış yere kopyalanmış bir Nature klasörü;
`CharacterCatalog` iki seviyeden derin yolları atladığı için zararsız.

---

## AnaSayfa

### 1. Demo Kontroller değişicek → **[VAR AMA HATALI]**
Demo butonları çalışıyor ama gerçek adım sayacı hiç yok; bu kart aslında
"pedometer entegrasyonu" kartı.
- **Dosyalar:** `features/home/home_screen.dart:132-160` (`'Demo Kontrolleri'` kartı,
  `_StepButton`), `features/root/root_shell.dart:117` (`_simulateSteps`),
  `models/daily_progress.dart`, `pubspec.yaml`,
  `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`
- **İş:** **orta-büyük** — paket (`pedometer`/`health`), `ACTIVITY_RECOGNITION` +
  `POST_NOTIFICATIONS` (Android), `NSMotionUsageDescription` (iOS), ve en önemlisi:
  `pedometer` cihaz açılışından beri **kümülatif** sayı döner → günlük adımı bulmak
  için "gün başı baseline"ı diske yazmak gerekir.
- **Bağımlı:** #13 (Database). Baseline kalıcı olmadan pedometer verisi anlamsız.
- **Not:** Demo butonlarını hemen silme — gerçek sayaç gelene kadar tek test yolu.
  Debug modda kalması mantıklı.

### 2. default seviye ilerleme adıma bağlı olmalı → **[YARIM]**
Seviye motoru çalışıyor ama adım XP vermiyor: XP yalnızca düşman yenince
(`enemy.xpReward`) ve çarktan geliyor.
- **Dosyalar:** `models/user_profile.dart:41` (`addXp`, `xpToNextLevel`),
  `features/root/root_shell.dart:117-132` (`_simulateSteps`),
  `widgets/hero_progress_rings.dart` (görsel hazır),
  `core/constants/game_constants.dart` (`baseXpPerLevel`)
- **İş:** **küçük** — `_simulateSteps` içinde adım başına XP; sabit
  `GameConstants`'a eklenir.
- **Bağımlı:** Hiçbiri (bugün demo butonlarıyla yazılabilir). #1 gelince
  otomatik gerçek adıma bağlanır.

---

## Macera

### 3. Slide Scroll adım seçim → **[YARIM]**
Seçim var ama 4 sabit `ChoiceChip` ile (2000/5000/7000/10000).
- **Dosyalar:** `features/adventure/adventure_screen.dart:296-323` (`ChoiceChip`
  bloğu), `:159` (`_selectGoal`), `:332-350` (düşman kilidi `_stepGoal`'e bağlı)
- **İş:** **küçük-orta** — **hazır widget var:**
  `features/character/character_creation_screen.dart:488-640` içindeki `_NumberWheel`
  (ListWheelScrollView + haptic + neon vurgu) tam da istenen şey. `lib/widgets/`
  altına taşınıp iki yerden kullanılabilir. Ama bu, çalışan karakter yaratma
  ekranına dokunmak demek → **önce sor** (Kural 2/5).
- **Bağımlı:** #4'ten SONRA yapılmalı. Şu an `stepGoal` aynı zamanda düşmanın canı
  ve kilit eşiği; #4 bunu ayırınca serbest seçim mantığı değişecek. Şimdi yapılırsa
  iki kez yazılır.

### 4. Canavar Savaş Sistemi → **[YARIM]**
Tur döngüsü, hasar, animasyon, yenilgi/zafer ekranları çalışıyor; **istatistik
sistemi yok.** Kodda zaten `TODO(combat)` olarak işaretli.
- **Dosyalar:** `models/adventure_quest.dart:113` (TODO), `models/enemy.dart`,
  `data/enemy_catalog.dart`, `features/adventure/adventure_screen.dart`,
  `features/root/root_shell.dart:117-144`, `test/adventure_quest_test.dart`
- **Mevcut durum:** düşman canı = günlük adım hedefi, her adım 1 hasar.
  `Enemy` modelinde `attackDamage`/`xpReward`/`minimumDailySteps` var; `maxHealth`,
  `defense`, direnç yok.
- **İş:** **büyük** — çekirdek sistem. Burada **iki HP çakışması da çözülmeli:**
  `UserProfile.hp` (5000, hiç kullanılmıyor) vs `AdventureQuest.maxPlayerHealth`
  (100, savaşta kullanılan).
- **Bağımlı:** #8/#9 (item buff'ları neyi değiştirecekse o statlar burada
  tanımlanmalı) — **ikisi birlikte tasarlanmalı**, önce item stat listesi netleşsin.
- **Dikkat:** 4 testin hepsi bu modeli test ediyor. Kural 5 gereği testler
  silinmeyecek, birlikte güncellenecek.

### 5. Dakika zaman kontrolü → **[VAR AMA HATALI]**
Beklenenden çok daha ileride — sistem kurulu, **2 somut hatası var.**
- **Dosyalar:** `models/adventure_quest.dart:44` (`roundDurationForSteps`),
  `:80` (`resolveExpiredRound`), `:74` (`countdownRemaining`),
  `features/adventure/adventure_screen.dart:565` (`_buildCountdownCard`, mm:ss),
  `features/root/root_shell.dart:66` (`Timer.periodic(1s)`), `:80`
  (`didChangeAppLifecycleState`)
- **Çalışan:** 1000 adım = 1 tur, tur süresi = adım/100 dk + 1 dk senkron payı,
  geri sayım, tur sonu hasarı, arka plana geçince bildirim planlama.
- **Hata 1:** `_updateAdventureClock` her tick'te **yalnızca bir** turu çözüyor.
  Uygulama 2 saat arka planda kalırsa ~11 tur birikir ve öne gelince saniyede
  1 tur hızında çözülür → oyuncu ekrana bakarken yavaş yavaş can kaybeder.
  `resolveExpiredRound` bir `while` döngüsünde çağrılmalı.
- **Hata 2:** `nextEnemyAttackAt` diske yazılmıyor. Uygulama tamamen kapatılıp
  açılırsa macera zaten sıfırlanıyor → geri sayım bedava resetleniyor.
- **Hata 3 (küçük):** `adventure_notification_service.dart:30`
  `tz.setLocalLocation(tz.UTC)` sabit UTC; cihaz saat dilimi okunmuyor
  (`flutter_timezone` yok). Göreli offsetlerle çalıştığı için şimdilik patlamıyor.
- **İş:** **küçük** (Hata 1 tek başına birkaç satır) + **orta** (Hata 2, #13'e bağlı)
- **Bağımlı:** Hata 1 hemen yapılabilir. Hata 2 → #13.

### 6. arka plan ekle + VS dövüş ekranı → **[YOK]**
Şu an dövüş alanı `ListView` içinde 260px'lik bir `SectionCard`; sol altta avatar
(yürüme animasyonlu), sağ altta düşman GIF'i. Arka plan yok, VS çerçevesi yok.
- **Dosyalar:** `features/adventure/adventure_screen.dart:360-499`
  (`_buildAdventure`, `Stack`), `widgets/avatar_view.dart`
- **İş:** **orta** — ama **asset bloklu:** repoda hiç arka plan/arena görseli yok
  (sadece Characters, Enemies, Items, GIF Animations). Önce sanat gerekli.
  Geçici çözüm olarak `character_creation_screen.dart:1006` içindeki
  `_EpicBackground` (radial gradient) deseni kullanılabilir.
- **Bağımlı:** Kod olarak bağımsız; pratikte arka plan görseli üretilmeden
  başlanmamalı.

---

## Takım

### 7. Takım savaşları (gerçek oyuncular, çoklu düşman) → **[YOK]**
Ekran salt görsel; `MockData.defaultTeam()` sabit 3 üye ("Sen/Ayşe/Mehmet").
- **Dosyalar:** `features/team/team_screen.dart`, `models/team.dart`,
  `data/mock_data.dart:20`, kullanılmayan
  `core/constants/game_constants.dart:sideBySideWindowMinutes`
- **İş:** **çok büyük** — Firebase Auth (gerçek kimlik), Firestore (takım dokümanı,
  realtime senkron), davet/eşleşme akışı, çoklu düşman savaş modeli, çatışma çözümü.
- **Bağımlı:** #13 (Firebase — sert bağımlılık) **ve** #4 (tek düşmanlı savaş
  sistemi çoklu düşmana genişletilecek). **En son yapılmalı.**

---

## Items

### 8. Özellikler eklenmeli (item modeli) → **[YOK]**
Ortada `Item` sınıfı yok. `XpStoreItem` sadece ad/açıklama/fiyat/`IconData`.
- **Dosyalar:** yeni `models/item.dart` + `data/item_catalog.dart` (veya
  `services/item_catalog.dart`, `CharacterCatalog` desenini kopyala),
  `models/xp_store_item.dart` (`Item`'a devredecek), `pubspec.yaml` (10 asset yolu)
- **İş:** **orta** — ama sanat hazır (784 PNG). Asıl iş: hangi görselin hangi
  item olduğunu tanımlayan veri + kategori→sınıf eşlemesi
  (`swords`→SwordMan, `magic`→Magic, `arch`→Archer...).
- **Bağımlı:** Hiçbiri. **Items zincirinin kökü.**
- **Karar gerekli:** 784 item'ın hepsi mi oyuna girecek, yoksa bir seçki mi?

### 9. Item değeri + birbirinden farklı buff → **[YOK]**
- **Dosyalar:** `models/item.dart` (yeni), `models/user_profile.dart`,
  `models/adventure_quest.dart` (buff'lar burada uygulanacak)
- **İş:** **orta**
- **Bağımlı:** #8 (model) **+ #4** (buff neyi artıracak? önce stat listesi lazım).
  Bu ikisi aynı tasarım oturumunda kararlaştırılmalı.

### 10. Itemlar seviyeye göre kullanılabilmeli → **[YOK]**
- **Dosyalar:** `models/item.dart` (`requiredLevel` alanı),
  `models/user_profile.dart:level` (hazır)
- **İş:** **küçük** — model varsa tek alan + tek kontrol.
- **Bağımlı:** #8

---

## Mağaza

### 11. Belli seviyede itemlar satın alınamasın → **[YOK]**
Şu an tek kontrol `affordable = coins >= item.cost`.
- **Dosyalar:** `features/store/xp_store_screen.dart:51-79`,
  `features/root/root_shell.dart:236` (`_purchase`)
- **İş:** **küçük** — `_QuickAction`/`_EnemyChoiceCard`'daki "kilitli" görsel dili
  (opacity + `Icons.lock`) burada da kullanılabilir, desen zaten var.
- **Bağımlı:** #10 (`requiredLevel` alanı olmadan yapılamaz)

### 12. Adımlar parayı arttırsın → **[YOK]** ⚠️
**Panodaki en kritik boşluk:** `coins` hiçbir yerde **artmıyor**. `_purchase`
sadece azaltıyor, başlangıç değeri 0. Yani mağaza şu an fiilen kullanılamaz.
- **Dosyalar:** `features/root/root_shell.dart:117` (`_simulateSteps` — para burada
  eklenecek), `:236` (`_purchase`), `models/user_profile.dart:11` (`coins`),
  `core/constants/game_constants.dart` (dönüşüm oranı buraya)
- **İş:** **küçük** — birkaç satır. Değer/etki oranı panodaki en yüksek kart.
- **Bağımlı:** Hiçbiri; bugün demo butonlarıyla yazılabilir.
- **Ek hata:** `xp_store_screen.dart:76` butonu `'${item.cost} XP'` yazıyor ama
  `coins` harcanıyor. **Karar gerekli:** mağaza para birimi XP mi coin mi?

---

## Database

### 13. Data birbirine bağlı olmalı, kapanınca devam etmeli → **[YARIM]**

> **GÜNCEL (2026-08-18):** #13a (yerel kalıcılık) **TAMAMLANDI**. #13b (Firebase)
> hâlâ açık. Detay: dosya sonundaki "Aşama 0 — Yerel Kalıcılık" bölümü.
Kalıcı olan tek veri avatar. Adım, macera, seviye, XP, coin, streak, çark, ödüller
— hepsi `RootShell`'in belleğinde ve uygulama kapanınca yok oluyor. Firebase hiç
bağlanmamış (paket/config/`firebase_options.dart` yok).
- **Dosyalar:** `services/character_storage.dart` (**izlenecek desen**),
  `features/root/root_shell.dart:44-53` (tüm state burada), tüm `models/`
  (`toJson`/`fromJson` yalnızca `AvatarProfile`'da var)
- **İş:** **büyük**
- **Bağımlı:** Hiçbiri. **#1, #5(hata2), #14, #15, #16, #17 bu karta bağlı.**
- **Önemli öneri — kartı ikiye böl:**
  - **13a — Yerel kalıcılık:** mevcut `CharacterStorage` desenini genişlet
    (SharedPreferences + elle `toJson`). Ucuz, hemen 6 kartı açar, hiçbir dış
    hesap/config gerektirmez.
  - **13b — Firebase (Firestore + Auth):** sert bağımlı olan **tek** kart #7
    (takım savaşları). Ondan önce yapılması zorunlu değil.
  - Proje `build_runner` kullanmıyor → serileştirme `AvatarProfile`'daki gibi
    **elle** yazılmalı, `freezed`/`json_serializable` getirme (Kural 1).

---

## Ödüller

### 14. Canavara göre ödül verilmeli → **[YARIM — altyapı var ama kopuk]**
`Reward`, `RewardRarity`, `RarityBadge`, `RewardsScreen`, `calculateRewardRarity`
hepsi yazılmış ve çalışır durumda; ama **`Reward` üreten tek kod ölü ekranda**
(`boss_battle_screen.dart`, hiçbir yerden çağrılmıyor). `RootShell._rewards`
listesine hiçbir şey eklenmiyor → Ödüllerim ekranı her zaman boş.
- **Dosyalar:** `features/root/root_shell.dart:47` (`_rewards`), `:117-144`
  (düşman yenilme hook'u **zaten var**), `models/enemy.dart` (loot tablosu yok),
  `data/enemy_catalog.dart`, `features/boss/boss_battle_screen.dart:31` (`_buildReward`),
  `core/utils/reward_calculator.dart`
- **İş:** **orta** — `Enemy`'ye loot tablosu + `_simulateSteps` içindeki mevcut
  "enemyDefeated" bloğuna ödül üretimi bağlanacak. Bağlantı noktası hazır.
- **Bağımlı:** #13 (ödüller kalıcı olmalı) + #8 (ödül item verecekse)
- **Karar gerekli:** `boss_battle_screen.dart` ve `BossQuest`/`reward_calculator`
  zinciri yeniden mi bağlanacak, yoksa silinecek mi? Silme/yeniden yazma yapmadan
  önce onay alınacak (Kural 2).

---

## Streak ve Çark

### 15. Streak sistemi gün bazlı olmalı → **[VAR AMA HATALI]**
`root_shell.dart:129-131`: hedefe ulaşınca `streakDays` 0→1 oluyor, **bir daha
asla artmıyor.** `UserProfile.lastActiveDay` alanı tanımlı ama hiç okunmuyor/
yazılmıyor — kartın ihtiyacı olan alan zaten orada, boş duruyor.
- **Dosyalar:** `models/user_profile.dart:13` (`lastActiveDay`), `:12` (`streakDays`),
  `features/root/root_shell.dart:129`, `models/daily_progress.dart`
- **İş:** **küçük-orta**
- **Bağımlı:** #13 (kalıcılık olmadan streak kavramsal olarak imkânsız)

### 16. Günlük çark XP veya item verebilmeli → **[YARIM]**
Çark sadece XP veriyor (`MockData.wheelXpOptions` = 6 sabit değer).
- **Dosyalar:** `features/wheel/daily_wheel_screen.dart:33`, `data/mock_data.dart:58`,
  `features/root/root_shell.dart:229` (`_spinWheel`)
- **İş:** **küçük**
- **Bağımlı:** #8 (item olmadan "item ver" yapılamaz)

### 17. Çark her gün bir kez kullanılabilmeli → **[VAR AMA HATALI]**
`_wheelSpunToday` bellekte bir `bool`. Uygulamayı kapat-aç → bedava çevirme.
Gün değişiminde sıfırlanma da yok.
- **Dosyalar:** `features/root/root_shell.dart:50` (`_wheelSpunToday`), `:229`,
  `features/wheel/daily_wheel_screen.dart:26` (`alreadySpunToday`)
- **İş:** **küçük**
- **Bağımlı:** #13 + #15 ile **aynı gün-döngüsü mekanizması**. İkisi tek işte
  yapılmalı, ayrı ayrı değil.

---

## Profil

### 18. Avatar Asset gerekli → **[BELİRSİZ — soru sorulacak]**
Avatar altyapısı tam çalışıyor: `AvatarView`, `CharacterCatalog` (AssetManifest
taraması), `AvatarProfile.characterAsset`, profilde 170px gösterim, ana sayfada
halka içinde gösterim.
- **Dosyalar:** `widgets/avatar_view.dart`, `features/profile/profile_screen.dart:41`,
  `services/character_catalog.dart`, `lib/Characters/`
- **İki okuma var:**
  - "Profilde avatar görünsün" → **[TAMAM]**, iş yok.
  - "Portre/avatar tarzı ayrı bir asset seti gerekli" (şu an tam boy Meshy
    render'ları avatar olarak kullanılıyor) → **[YOK]**, sanat işi, kod işi değil.
- İpucu: `lib/Characters/Magic/Meshy_AI_Pixel Mage Avatar.png` adlı tek dosya,
  bir ara portre tarzının denendiğini gösteriyor.
- **Kullanıcıya sorulacak.**

---

# ÖNERİLEN SIRA

Sıralamayı üç ilkeye göre kurdum: **(a)** ucuz olup çok kart açanlar önce,
**(b)** yeniden yazmaya yol açacak sıralamalardan kaçın, **(c)** bitmiş sanat
varlığını boşta bekletme.

### Aşama 0 — Temel: yerel kalıcılık `[#13a]`
**Neden ilk:** #1, #5(hata2), #14, #15, #16, #17 — altı kart buna bağlı ve
hepsi tek tek küçük. Kalıcılık olmadan yapılırlarsa **hepsi sahte** olur
(streak hep 1, çark her açılışta bedava, geri sayım resetlenir). `RootShell`
tüm state'i tek yerde tuttuğu için kalıcılık **bir kez** yazılır; sonraya
bırakılırsa altı ayrı yerde retrofit edilir.
**Neden Firebase değil:** Firebase'e sert bağımlı olan tek kart #7 (takım savaşları)
ve o zaten en sonda. `CharacterStorage` deseni genişletilerek yerel kalıcılık
bugün, hesap/config beklemeden yapılabilir. Firebase'i erken getirmek altı kartı
gereksiz yere bloklar.

### Aşama 1 — Gün döngüsü `[#15 + #17]` + hızlı düzeltmeler `[#5-hata1, #12]`
Aynı mekanizma (gün değişimi tespiti, `lastActiveDay`) hem streak'i hem çark
hakkını çözüyor → **tek iş olarak yapılmalı.** Yanına iki ucuz kazanç:
- **#12 (adım→para):** birkaç satır, ama panonun en yüksek etkili maddesi —
  mağazayı ölü olmaktan çıkarır.
- **#5 hata 1 (`while` döngüsü):** bağımsız, birkaç satır, gerçek bir oyun hatası.

### Aşama 2 — Gerçek adım sayacı `[#1]` + adım→XP `[#2]`
Baseline'ı yazacak yer (Aşama 0) artık hazır. Sayaç bağlanınca #2 ve #12 kendiliğinden
gerçek veriyle çalışmaya başlar. İzinler (Android `ACTIVITY_RECOGNITION` +
`POST_NOTIFICATIONS`, iOS `NSMotionUsageDescription`) burada eklenir — not:
`POST_NOTIFICATIONS` eksikliği **şu an da** bir hata, bildirim izni sessizce
başarısız oluyor.

### Aşama 3 — Item temeli `[#8 → #10 → #11 → #16]`
784 asset boşta bekliyor; bu aşama panodaki **en yüksek değer/emek oranı.**
#8 (model+katalog) yazıldıktan sonra #10, #11, #16 birer küçük iş olarak arka
arkaya düşer. `CharacterCatalog` deseni doğrudan kopyalanabilir.

### Aşama 4 — Savaş sistemi `[#4 + #9 birlikte]`, sonra `[#14]`
#4 ve #9 **aynı tasarım kararına** bakıyor: "hangi statlar var?" Ayrı yapılırsa
biri diğerini yeniden yazdırır. Burada iki HP çakışması da çözülür.
Bitince #14 (canavara göre ödül) doğal devamı olur — `RootShell`'de düşman
yenilme hook'u zaten hazır.

### Aşama 5 — UI/UX `[#3, #6, #18]`
- **#3 (slide scroll)** bilerek buraya alındı: #4 `stepGoal`'ün anlamını
  değiştireceği için önce yapılırsa iki kez yazılır. `_NumberWheel` hazır bekliyor.
- **#6 (VS ekranı + arka plan)** kod olarak bağımsız ama **arka plan görseli
  üretilmeden başlanmamalı.** Sanat paralel ilerletilebilir.
- **#18** önce netleşmeli (kod işi mi, sanat işi mi?).

### Aşama 6 — Firebase `[#13b]` → Takım savaşları `[#7]`
En büyük ve en çok ön koşullu kart. Tek oyunculu döngü (ekonomi, item, savaş,
kalıcılık) oturmadan çok oyunculuya geçmek, oturmamış kuralları ağ katmanında
ikinci kez yazmak demek.

### Özet sıra
```
0. #13a yerel kalıcılık            (büyük)  → 6 kartı açar
1. #15+#17 gün döngüsü             (orta)
   #12 adım→para                   (küçük)  ← en yüksek etki/emek
   #5 hata1 tur çözüm döngüsü      (küçük)
2. #1 pedometer + izinler          (büyük)
   #2 adım→XP                      (küçük)
3. #8 item modeli+katalog          (orta)   ← 784 asset hazır
   #10 seviye kilidi               (küçük)
   #11 mağaza seviye kilidi        (küçük)
   #16 çark item verebilsin        (küçük)
4. #4+#9 savaş sistemi + buff'lar  (büyük)
   #14 canavara göre ödül          (orta)
5. #3 slide scroll                 (küçük)
   #6 VS ekranı + arka plan        (orta, asset bloklu)
   #18 avatar asset                (belirsiz)
6. #13b Firebase                   (büyük)
   #7 takım savaşları              (çok büyük)
```

## Başlamadan önce cevaplanması gereken sorular

1. **İki HP kavramı:** `UserProfile.hp` (5000, kullanılmıyor) mu kalacak,
   `AdventureQuest.playerHealth` (100, savaşta kullanılan) mı? İkisi birleşecek mi?
2. **Mağaza para birimi:** XP mi coin mi? Buton "N XP" yazıyor, `coins` harcıyor.
3. **`boss_battle_screen.dart` ölü zinciri:** #14'te yeniden bağlanacak mı,
   silinecek mi? (Silme/yeniden yazma öncesi onay gerekli — Kural 2)
4. **Kalıcılık:** Yerel-önce (#13a) yaklaşımı onaylanıyor mu, yoksa doğrudan
   Firebase mi isteniyor?
5. **Items:** 784 görselin hepsi mi oyuna girecek, yoksa bir seçki mi?
   Kategori→karakter sınıfı eşlemesi nasıl olacak?
6. **#18 Avatar Asset** kartı tam olarak neyi istiyor?

---

# Aşama 0 — Yerel Kalıcılık ✅ TAMAMLANDI (2026-08-18)

Kart #13a bitti. Kabul testi geçti: kapat-aç sonrası para, seviye, adım, macera
ve çark durumu korunuyor.

## Kalıcılık katmanı

| Dosya | Rol |
|---|---|
| `lib/models/game_state.dart` | Kalıcı olması gereken durumun tamamını taşıyan kap (profil + günlük ilerleme + macera). "Nerede saklandığından" bağımsız: dışarıya düz `Map<String, dynamic>` verir. |
| `lib/services/game_storage.dart` | SharedPreferences'a yazma/okuma. `CharacterStorage` desenini izler. |
| `lib/core/utils/game_day.dart` | Oyun gününün **tek** doğruluk kaynağı. |
| `lib/widgets/day_reset_countdown.dart` | Gün sıfırlamasına kalan süreyi canlı gösteren paylaşılan widget. |

**Kayıt biçimi (zarf):** `{schemaVersion, savedAt, state}` — key: `game_state_v1`.

- **Şema versiyonlama:** `GameStorage.schemaVersion` + `_migrations` haritası
  ("sürüm N → N+1"). `load()` kayıtlı sürümden güncele kadar adımları sırayla
  uygular. Alan eklerken: sürümü artır **ve** haritaya bir satır ekle.
- **Bozuk veri:** `FormatException` / `TypeError` / genel `catch` yakalanır,
  `debugPrint` ile loglanır, `null` dönülür → temiz varsayılan. Uygulamadan
  **yeni** sürümdeki kayıt (downgrade) da yok sayılır.
- **Yazma sıklığı:** `scheduleSave()` en fazla 2 saniyede bir yazar
  (`GameStorage.writeInterval`). Arka plana geçişte ve `dispose`'da `flush()`.
- **Firebase hazırlığı:** `GameState.toJson()` çıktısı doğrudan bir Firestore
  dokümanı. `savedAt` alanı yerel/sunucu karşılaştırması için zarfta hazır.
  Aşama 6'da yerel depo "cache" rolüne geçebilir.

**Persist edilenler:** seviye, XP, coin, streak, `lastActiveDay`, `totalSteps`,
`ownedItemIds`, `lastWheelSpinAt`, günlük adım + hedef + tarih, macera
(düşman id, başlangıç adımı, tur hedefi, geri sayım, savaş canı, saldırı sayacı).

**Persist EDİLMEYENLER (bilerek):**
- `RootShell._rewards` — bkz. Model Kuralları #1 (`Reward.icon` bir `IconData`)
- `UserProfile.hp` / `maxHp` — **şema v2'de çıkarıldı.** Bu alanları azaltan
  hiçbir kod yok; kalıcılaştırılırsa her kayda sabit 5000/5000 gider. Savaş canı
  `AdventureQuest.playerHealth` üzerinde tutuluyor. İki can kavramının
  birleştirilmesi Aşama 4a'nın konusu.
- Takım (`MockData`), mağaza kataloğu (sabit veri)

**Şema sürümü:** `2`. (v1 → v2 taşıması eski kayıtlardan `hp`/`maxHp` anahtarlarını
temizler.)

## Gün döngüsü (Aşama 1b, 2026-08-18)

Gün hesabı `GameDay` içinde tek fonksiyona toplandı. Bu noktadan sonra
`DailyProgress.isSameDayAs`, `UserProfile.wheelSpunToday` ve çark geri sayımı
aynı sınırı kullanıyor. `GameDay.dayStartHour` değişince üçü birden uyar.

## Bilinen sorun — gün değişiminde macera düşüyor

Kayıt başka bir güne aitse günlük adım sıfırlanıyor **ve macera düşürülüyor**
(`root_shell.dart:_restoreState`). Bugün zararsız, çünkü macera başlatmak
bedava.

> **Aşama 5a'da (#3) macera adım harcayarak başlatılacak. O noktada gün
> değişiminde macerayı düşürmek, oyuncunun harcadığı adımı yakmak demek.
> Kalan seçenek: macerayı düşürmek yerine kısmi ödülle sonuçlandır.**

> **GÜNCELLEME (2026-08-18):** Bu notun ikinci yarısı — "macera ilerlemesini
> `_today.steps`'ten ayır" — **kapandı.** B1 düzeltmesiyle macera artık
> `AdventureQuest.startingSteps` taşıyor ve ilerlemesini
> `today.steps - startingSteps` üzerinden hesaplıyor; günlük sayaç hiçbir yerde
> sıfırlanmıyor. Açık kalan tek konu, gün değişiminde düşürülen maceranın
> harcanmış adımının nasıl telafi edileceği.

---

# Bug Triajı (2026-08-18)

Üç kova: **A** = zaten yeniden yazılacak kodda (şimdi düzeltmek boşa emek),
**B** = bozuk veri üretiyor (ACİL — Aşama 0'dan sonra bu değerler diske
yazılıyor ve kapat-aç ile sıfırlanmıyor), **C** = kozmetik/bağımsız.

## Kova B — BOZUK VERİ ÜRETENLER (ACİL)

> **Durum (2026-08-18):** B1 **düzeltildi**, B2 **kısmen düzeltildi**,
> B3 ve B4 **düzeltildi** (Aşama 1a). Kova B kapandı.

### B1. ✅ ÇÖZÜLDÜ — Macera seçmek/bırakmak günün adımlarını sıfırlıyordu
- **Dosya:** `lib/features/root/root_shell.dart` — `_selectAdventure`,
  `_chooseNewAdventure`
- **Ne oluyor:** İkisi de `_today = DailyProgress(date: DateTime.now())` ile
  **yeni** bir günlük ilerleme kuruyor; `steps` varsayılanı 0. Yani 4.000 adım
  atmış oyuncu macera seçtiğinde günlük adımı 0'a düşüyor.
- **Neden B:** Doğrudan veri kaybı, üstelik artık kalıcı. Ayrıca `totalSteps`
  (Aşama 0'da eklendi) sıfırlanmadığı için iki sayaç kalıcı olarak çelişiyor
  (`totalSteps` = 4000, `today.steps` = 0). Çark kilidi (`isWheelUnlocked`) ve
  streak de bu yanlış sayıya bakıyor.
- **Çözüm (2026-08-18):** `AdventureQuest`'e `startingSteps` alanı eklendi —
  macera başlarken günlük sayacın o anki değerini saklıyor. İlerleme artık
  `questSteps(currentSteps) = currentSteps - startingSteps` üzerinden
  hesaplanıyor (`remainingHealth`, `isDefeated`, `takePendingDamage` bunu
  kullanıyor). `roundStartingSteps` varsayılanı `startingSteps`.
  `_selectAdventure` / `_chooseNewAdventure` artık günün adımını ve tarihini
  koruyor, yalnızca günlük hedefi güncelliyor. Test: `adventure_quest_test.dart`
  → `macera başlangıç adımı` grubu (6 test).

### B2. İki HP kavramı — ikisi de diske yazılıyor
- **Dosyalar:** `lib/models/user_profile.dart:7` (`hp`, `maxHp` = 5000),
  `lib/models/adventure_quest.dart:15` (`playerHealth`, 0-100),
  `lib/features/profile/profile_screen.dart:74`,
  `lib/widgets/hero_progress_rings.dart:149`
- **Ne oluyor:** `UserProfile.hp` hiçbir yerde **azalmıyor** — kodda onu yazan
  tek satır yok. Ama profil ekranı ve ana sayfa halkası onu "canın" diye
  gösteriyor. Oyuncu savaşta can kaybederken (`playerHealth` 100 → 60) profilde
  hep `5000 / 5000` görüyor.
- **Neden B (sadece A değil):** Bu yalnızca "ileride birleştirilecek" bir tasarım
  borcu değil; **şu an** kullanıcıya doğru olmayan bir değer gösteriliyor ve
  Aşama 0'dan beri o değer her kayıtta diske yazılıyor. Birleştirme kararı
  Aşama 4'e ait, ama veri sorunu bugün canlı.
- **Kısmi çözüm (2026-08-18) — birleştirme YAPILMADI, o karar Aşama 4a'nın:**
  1. `UserProfile.hp` / `maxHp` **şemadan çıkarıldı** (sürüm 1 → 2, taşıma eski
     kayıtlardan bu anahtarları siliyor). Alanlar sınıfta duruyor, sadece
     kalıcılaştırılmıyor.
  2. Profil ekranı ve ana sayfa halkası artık **gerçek kaynağı** gösteriyor:
     macera varken `AdventureQuest.playerHealth` ("Savaş Canı", 0-100), macera
     yokken can çubuğu hiç çizilmiyor (profilde tek satır açıklama var).
  - **Açık kalan:** iki can kavramının birleştirilmesi (Aşama 4a).
  - **Not:** Kart metninde "playerHealth hiç azalmıyor" deniyordu; azalmayan
    alan `UserProfile.hp`. `AdventureQuest.playerHealth` doğru çalışıyor ve
    persist edilmeye devam ediyor.

### B3. ✅ ÇÖZÜLDÜ — Streak sahte ve kalıcıydı
- **Dosya:** `lib/features/root/root_shell.dart:_simulateSteps`,
  `lib/models/user_profile.dart` (`streakDays`, `lastActiveDay`)
- **Ne oluyor:** Hedefe ulaşınca `streakDays` 0 → 1 oluyor, **bir daha asla
  artmıyor**. Gün değişimi izlenmiyor.
- **Neden B:** Aşama 0 öncesi bu değer uygulama kapanınca sıfırlanıyordu, yani
  yalnızca "yanlış görünüyordu". Artık yanlış değer kalıcı ve kendiliğinden
  düzelmiyor. Aşama 1a'da çözülecek, ama veri şimdi bozuluyor.
- **Çözüm (Aşama 1a):** `UserProfile.registerStreakDay` / `refreshStreak` +
  `GameDay.daysBetween`. Tetikleyici günlük hedef değil, sabit 2000 adım.
  Ayrıntı: aşağıdaki "Aşama 1a" bölümü.

### B4. ✅ ÇÖZÜLDÜ — `lastActiveDay` hiç yazılmıyordu
- **Dosya:** `lib/models/user_profile.dart:14`
- **Ne oluyor:** Alan tanımlı, `toJson`/`fromJson` içinde var, ama onu yazan
  hiçbir kod yok → her kayıtta `null` yazılıyor.
- **Neden B:** Gün döngüsünün (B3, #15/#17) dayanacağı alan boş. Kalıcı state'te
  "var gibi görünen ama hiç dolmayan" alan, sonraki aşamada yanlış varsayıma
  yol açar.
- **Çözüm (Aşama 1a):** Alan artık serinin dayanağı;
  `registerStreakDay` her ilerlemede yazıyor.

## Kova A — ZATEN YENİDEN YAZILACAK KODDA

### A1. Tur çözüm döngüsü tek tur çözüyor (#5 hata 1)
- **Dosya:** `lib/features/root/root_shell.dart:_updateAdventureClock`
- **Ne oluyor:** Her saniyelik tick'te `resolveExpiredRound` yalnızca **bir kez**
  çağrılıyor. Uygulama 2 saat arka planda kalırsa ~11 tur birikir ve öne gelince
  saniyede 1 tur hızıyla çözülür → oyuncu ekrana bakarken yavaş yavaş can
  kaybeder. `while` döngüsü olmalı.
- **Kova gerekçesi:** Aşama 4a savaş motorunu sıfırdan yazacak; tur çözümü orada
  yeniden ele alınacak.
- **⚠️ Not:** Bu hata artık `playerHealth`'i **kalıcı** olarak yanlış değere
  düşürüyor. Aşama 4 uzarsa tek satırlık `while` düzeltmesi B kovasına terfi
  etmeli.

### A2. Düşman canı = günlük adım hedefi, her adım 1 hasar
- **Dosya:** `lib/models/adventure_quest.dart:113` (`TODO(combat)`)
- **Kova gerekçesi:** Aşama 4a'nın tam konusu. Can/saldırı/savunma ayrı combat
  istatistikleri olarak modellenecek.

### A3. `stepGoal` üç işi birden yapıyor
- **Dosyalar:** `lib/models/adventure_quest.dart`,
  `lib/features/adventure/adventure_screen.dart:332`
- **Ne oluyor:** Aynı sayı hem düşmanın canı, hem düşman kilidi eşiği, hem
  günlük adım hedefi. Biri değişince üçü birden değişiyor.
- **Kova gerekçesi:** Aşama 4a (combat istatistikleri) + Aşama 5a (#3 serbest
  adım seçimi) bunu zaten ayıracak.

### A4. Mağaza butonu "XP" yazıyor, `coins` harcıyor
- **Dosya:** `lib/features/store/xp_store_screen.dart:76`
- **Kova gerekçesi:** Aşama 3'te #11 (seviye kilidi) ve #12 (adım→para) için
  mağaza ekranı ve para birimi kararı zaten elden geçecek.

### A5. Mağaza item'ları `XpStoreItem` + `IconData`
- **Dosyalar:** `lib/models/xp_store_item.dart`, `lib/data/mock_data.dart:27`
- **Kova gerekçesi:** Aşama 3'te #8 gerçek `Item` modeliyle değişecek. Model
  Kuralları #1 gereği yeni modelde `IconData` yerine asset yolu (`String`)
  tutulacak.

### A6. Takım ekranı sabit demo veriyle çalışıyor
- **Dosyalar:** `lib/features/team/team_screen.dart`,
  `lib/data/mock_data.dart:18` (`defaultTeam`)
- **Kova gerekçesi:** Aşama 6 (#7 takım savaşları) tamamını Firestore'a taşıyacak.

### A7. Ölü zincir: boss savaşı
- **Dosyalar:** `lib/features/boss/boss_battle_screen.dart` (hiçbir yerden
  çağrılmıyor), `lib/models/boss_quest.dart`, `lib/data/mock_data.dart`
  (`dailyDragon`), `lib/core/utils/reward_calculator.dart`
- **Kova gerekçesi:** Aşama 4b (#14 canavara göre ödül) bu zinciri ya yeniden
  bağlayacak ya kaldıracak. **Silinmedi** (Kural 2 — onay olmadan silme yok).

### A8. ✅ ÇÖZÜLDÜ — Adım → para hiç kazanılmıyordu
- **Dosya:** `lib/features/root/root_shell.dart:_onStepsReported`
- **Not:** `coins` yalnızca `_purchase`'ta azalıyordu, artıran kod yoktu.
- **Çözüm (Aşama 1b):** 50 adım = 1 coin, günde en fazla 400 coin. Para adım
  deltasından kazanılıyor (`UserProfile.lastRewardedStepCount`). Ayrıntı:
  aşağıdaki "Aşama 1b" bölümü.

## Kova C — KOZMETİK / BAĞIMSIZ

| # | Dosya | Ne | Neden C |
|---|---|---|---|
| C1 | `lib/features/rewards/rewards_screen.dart`, `lib/features/store/xp_store_screen.dart`, `lib/features/team/team_screen.dart` | `dart format` uygulanmamış (3 dosya) | Derlemeyi/işlevi etkilemiyor |
| C2 | `android/src/main/AndroidManifest.xml` | `POST_NOTIFICATIONS` izni yok → Android 13+'ta `requestNotificationsPermission()` sessizce başarısız | İşlevsel ama veri bozmuyor; Aşama 2'de izinlerle birlikte |
| C3 | `lib/services/adventure_notification_service.dart:30` | `tz.setLocalLocation(tz.UTC)` sabit; cihaz saat dilimi okunmuyor | Göreli offsetlerle çalışıyor. **Uyarı:** gün/saat bazlı bildirim eklenirse B'ye terfi eder |
| C4 | `lib/features/root/root_shell.dart:_reminderMessages` + `lib/services/adventure_notification_service.dart:_messages` | Hatırlatma metinleri iki yerde kopyalanmış | Sadece bakım borcu |
| C5 | `lib/features/root/root_shell.dart:_rewards` | Liste hiç doldurulmuyor → Ödüllerim ekranı hep boş | Aşama 4b'de (#14) doğal olarak çözülecek |
| C6 | `lib/core/constants/game_constants.dart` | `sideBySideWindowMinutes` kullanılmıyor | Ölü sabit |
| C7 | `lib/models/adventure_quest.dart` | `nextReminderAt` kayıttan geçmiş bir zamanla dönerse resume'da anında bir hatırlatma tetikler | Tek seferlik, zararsız |
| C8 | `lib/Items/` | 784 PNG `pubspec.yaml`'a eklenmemiş → APK'ya girmiyor | Aşama 3'te (#8) eklenecek |
| C9 | `lib/GIF Animations/Soldier/`, `lib/Characters/DarkMagic/Nature/` | Kullanılmayan/yanlış yere kopyalanmış asset klasörleri | Zararsız; `CharacterCatalog` iki seviyeden derini atlıyor |
| C10 | `README.md` | Hâlâ "A new Flutter project." | Şablon artığı |
| C11 | `android/app/build.gradle.kts` | Release imzası hâlâ debug key + şablon TODO'ları | Yayına çıkmadan önce |
| C12 | Repo adı, `RushForVilliansApp` | "Villians" yazım hatası (paket adı `rush_for_villains` doğru) | Değiştirmek riskli, bırakıldı |
| C13 | `lib/models/reward_rarity.dart` | `RewardRarityX.color` model katmanında `Color` döndürüyor | Alan değil, extension getter → persist edilmiyor. Model Kuralları #1'i **teknik olarak** ihlal etmiyor ama sunum mantığı model klasöründe |

## Model Kuralları #1 taraması — aykırı alanlar

Kalıcı hale gelecek modellerde Flutter framework tipi araması:

| Dosya | Alan | Durum |
|---|---|---|
| `lib/models/reward.dart:11` | `final IconData icon` | **AYKIRI** — #14'te persist edilecek. Aşama 4b'de `String` anahtara çevrilmeli |
| `lib/models/xp_store_item.dart:9` | `final IconData icon` | **AYKIRI** — #8'de persist edilecek. Aşama 3'te `Item` modeline geçerken asset yolu tutulmalı |
| `lib/models/reward_rarity.dart` | `RewardRarityX.color` → `Color` | Sınır durum (bkz. C13). Enum'un kendisi `name` ile güvenle persist edilir |
| Diğer 9 model | — | Temiz. `enemy.dart` asset yollarını `String` tutarak doğru deseni gösteriyor |

**Düzeltme yapılmadı** — talep üzerine yalnızca listelendi.

## Aşama 0 sonrası: diske yazdığımız state'te güvenmediğim alanlar

Kalıcılığı yazarken, **yanlış hesaplanan bazı değerleri farkında olmadan kalıcı
hale getirdim.** B1/B2 düzeltmelerinden sonra kalan durum:

| Alan | Durum |
|---|---|
| `profile.hp`, `profile.maxHp` | ✅ Artık **persist edilmiyor** (şema v2) |
| `today.steps` | ✅ Artık sıfırlanmıyor (B1) |
| `profile.totalSteps` | ✅ `today.steps` ile çelişmesi bitti (B1). **Ama B1 öncesi yazılmış kayıtlarda hâlâ şişkin** — bkz. aşağıdaki temizlik notu |
| `adventure.roundStartingSteps` | ✅ `startingSteps` ile aynı koordinat sisteminde, tutarlı |
| `profile.streakDays` | ✅ Gün bazlı hesaplanıyor (B3, Aşama 1a) |
| `profile.lastActiveDay` | ✅ Serinin dayanağı, her ilerlemede yazılıyor (B4) |
| `adventure.playerHealth` | ⚠️ Tur başına doğru, ama A1 (tek tur çözümü) uzun arka plandan sonra değeri yanlış düşürüyor |

**Güvenilir alanlar:** `level`, `xp`, `coins`, `ownedItemIds`, `lastWheelSpinAt`,
`streakDays`, `lastActiveDay`, `longestStreak`, `lastSeenAt`, `today.steps`,
`today.stepGoal`, `today.date`, `adventure.enemyId`, `adventure.stepGoal`,
`adventure.startingSteps`, `adventure.nextEnemyAttackAt`.

### Eski kayıttaki `totalSteps` şişkinliği — temizlik önerisi

B1 öncesi kayıtlarda `totalSteps` ile `today.steps` çelişiyor ve **doğru değer
geri hesaplanamaz** (kaç kez macera seçildiği bilinmiyor). Bu yüzden veri onaran
bir migration yazılmadı: tahmine dayalı bir taşıma, yanlış veriyi "doğrulanmış"
gibi gösterirdi.

**Öneri: test kaydını silmek** (uygulamayı kaldır-kur veya uygulama verisini
temizle). Gerekçe:
- Tek etkilenen kayıt geliştiricinin test kaydı.
- `totalSteps`'in henüz hiçbir tüketicisi yok (Aşama 2'de pedometer baseline'ı
  için kullanılacak) — yani şişkin değer bugün hiçbir şeyi bozmuyor ama Aşama 2
  temiz bir baseline ile başlamalı.
- `today.steps` zaten gün değişiminde kendini sıfırlıyor, tek kalıcı kirlilik
  `totalSteps`.

---

---

# Aşama 1a — Gün döngüsü, streak ve zaman güvenliği ✅ (2026-08-18)

Kartlar #15 (gün bazlı streak) ve #17 (çark günde bir kez) kapandı.
Triajdaki **B3** ve **B4** çözüldü.

## Gün sınırı 04:00'e taşındı

`GameDay.dayStartHour = 4`. Gerekçe: gece yarısını geçmiş ama hâlâ ayakta olan
kullanıcı gün ortasında kesilmiyor, serisi haksız yere kırılmıyor.

00:00–04:00 arasında ne değişti:

| | Önce (00:00) | Şimdi (04:00) |
|---|---|---|
| Adım sayacı | Gece yarısında sıfırlanırdı | 04:00'a kadar aynı güne yazılır |
| Çark hakkı | 00:00'da yenilenirdi → 23:50'de çevirip 00:10'da tekrar çevirmek mümkündü | 00:00–04:00 arası hâlâ dünün hakkı |
| Geri sayım | Gece yarısını hedeflerdi | 04:00'ı hedefler |
| Macera | 00:00'da düşerdi | 04:00'da düşer |

Aşama 0'da yazılan gün testleri `dayStartHour`'a göreliydi; sınır değişince
**hiçbiri kırılmadı**.

## Zaman kaynağı: `GameClock`

`lib/core/utils/game_clock.dart` — gün/seri/çark hesaplarında `DateTime.now()`
yerine **tek giriş noktası**. İki işi var:

1. **Enjekte edilebilirlik.** `GameClock.useSource(...)` ile testler sahte saat
   verir; Aşama 6a'da Firestore server timestamp'e geçilirken yalnızca bu çağrı
   değişecek, çağıran hiçbir kod değişmeyecek.
2. **Geriye alınan cihaz saatini yakalamak.** En son güvenilen okuma
   hatırlanır (`UserProfile.lastSeenAt`, diske UTC yazılır). Cihaz saati ondan
   `backwardTolerance` (5 dk) fazla geriye giderse `now()` **son güvenilen
   zamanı döndürür** — yani ilerleme donar.

**Neden ayrı bir "şüpheli saat" bayrağı yok:** `now()` donunca seri de, çark
hakkı da, gün değişimi de kendiliğinden donuyor. Tek mekanizma, tek dal.

### Saat dilimi ↔ saat hilesi dengesi

- **Monotonluk kontrolü UTC üzerinden.** Seyahat eden kullanıcının *yerel* saati
  saatlerce geri kayabilir ama UTC'si kaymaz → seyahat şüpheli sayılmaz.
- **Gün sınırı yerel saate göre.** 04:00, nerede olursan ol 04:00'tür.
- **5 dakikalık tolerans** NTP düzeltmelerini ve küçük sapmaları geçirir.

### BİLİNEN BOŞLUKLAR — zaman güvenliği

Üçü de **bilinçli olarak açık bırakıldı**; yerelde kapatmaya çalışmak sahte
güvenlik hissi verirdi. Hepsi Aşama 6a'da sunucu saatiyle kapanır.

1. **İleri alınan cihaz saati yakalanamıyor.** İleri gitmek, gerçek zamanın
   geçmesinden yerelde ayırt edilemez. Kullanıcı saati bir gün ileri alıp
   fazladan bir çark hakkı ve bir seri günü kazanabilir. Geri aldığında
   monotonluk kontrolü yakalar ve dondurur, ama kazanılan gün geri alınmaz.

2. **Doğuya seyahat, saati ileri almakla aynı görünür.** Yerel saat ileri
   atlar; (1) ile aynı sonuç. Kasıtlı hile ile gerçek seyahat ayırt edilemiyor,
   ikisi de kullanıcı lehine yorumlanıyor.

3. **Batıya seyahat gün sınırını kullanıcıyla taşır**, o gün 24 saatten uzun
   sürer. Bu "04:00 nerede olursan ol 04:00" kararının doğrudan sonucu — hata
   değil, ama ölçülü bir avantaj.

### BİLİNEN BOŞLUK — test edilemeyen durum

**Gerçek saat dilimi değişimi test edilemiyor.** `DateTime.now()`'ın yerel saat
dilimi süreç başlangıcında işletim sisteminden okunuyor; Dart'ta bunu süreç
içinde değiştirecek desteklenen bir API yok (`TZ` ortam değişkeni Windows'ta
çalışmıyor ve zaten süreç başlamadan ayarlanması gerekir).

Bunun yerine okumalar `DateTime.utc(...)` ile kurulup karşılaştırmanın UTC
üzerinden yapıldığı doğrulandı. Bu **mekanizmayı** kanıtlıyor (UTC ilerledikçe
dondurmuyor) ama gerçek bir saat dilimi geçişini simüle etmiyor. Aşama 2'de
gerçek cihazda elle doğrulanmalı.

## Streak (#15)

**Tetikleyici:** günlük **2000 adım** (`GameConstants.streakStepThreshold`).
Günlük hedeften bilinçli olarak bağımsız ve düşük: seri "yürüdüm" demeli ama
20.000 adımlık hedefe bağlanırsa çoğu gün kırılır ve anlamını yitirir. En düşük
düşman eşiğiyle aynı sayı.

`UserProfile` üzerindeki API:

| Üye | İş |
|---|---|
| `registerStreakDay(now)` | Koşul sağlanınca çağrılır. Aynı oyun gününde ikinci kez çağrılırsa hiçbir şey yapmaz. Seri ilerlediyse `true`. |
| `refreshStreak(now)` | Aktivite gerektirmez. Gün atlanmışsa (`gap >= 2`) seriyi sıfırlar. |
| `streakCompletedOn(now)` | Bugünkü seri tamamlandı mı. |
| `longestStreak` | En uzun seri; seri kırılsa da korunur. Profilde gösteriliyor. |
| `reachedStreakMilestone` | Şu an denk gelinen kilometre taşı (7/30/100) ya da null. |
| `nextStreakMilestone` | Sonraki kilometre taşı. |

Gün farkı `GameDay.daysBetween` ile hesaplanır — takvim günü üzerinden, çünkü
yaz saati geçişlerinde bir gün 23 ya da 25 saat sürebilir ve saat farkını güne
bölmek yanlış sonuç verir.

`lastActiveDay` seri kırılınca **bilerek silinmez**: sonraki
`registerStreakDay` aradaki boşluğu oradan görüp seriyi 1'den başlatır.

### Kilometre taşı ödülleri — hook, ödül yok

7 / 30 / 100 gün `GameConstants.streakMilestones` içinde tanımlı. Ulaşıldığında
`root_shell.dart:_showStreakMilestone` uygulama içi bildirim gösteriyor.

> **Ödül üretimi bilinçli olarak bağlanmadı.** Mevcut `Reward` altyapısı ölü
> (bkz. A7) ve `Reward.icon` bir `IconData` — Model Kuralları #1'i ihlal ediyor.
> Ödül altyapısı Aşama 3d/4b'de kurulunca `_showStreakMilestone` içindeki
> `TODO(rewards)` noktasına bağlanacak.

### Streak koruması (dondurucu) — ✅ UYGULANDI (Aşama 2c)

> Aşağıdaki tasarım olduğu gibi kabul edildi ve tüketim tarafı yazıldı.
> Güncel durum için "Aşama 2c" bölümüne bak.

Bir günlük kaçırmayı telafi eden jeton önerildi:

- **Alan:** `UserProfile.streakFreezes` (int) + `lastFreezeUsedOn` (DateTime?)
- **Kazanım:** 7 günlük kilometre taşında 1 adet + mağazadan satın alma
- **Tüketim:** otomatik ve geriye dönük — seri kırılacakken jeton varsa 1 tanesi
  harcanır, seri korunur ama **artmaz**
- **Sınırlar:** stok en fazla 2; art arda en fazla 1 gün korunur
- **Neden otomatik:** manuel kurtarma penceresini kaçıran kullanıcı iki kez
  cezalanır; serinin amacı alışkanlık, ceza değil

Karar verilirse şema v4 + gün geçiş mantığında bir dal gerekir.

## Çark (#17)

- Günlük hak kısıtı Aşama 0'da fiilen çözülmüştü; 04:00 sınırıyla gece yarısı
  açığı da kapandı.
- **Sonuç artık animasyondan önce belirleniyor.** Önceden `_spin()` 900 ms
  bekleyip *sonra* `Random()` çağırıyordu. Ayrıca eksik `mounted` kontrolü
  eklendi (ekran kapatılırken `setState` çağrılabiliyordu).
- Çarkın iğnesinin doğru dilimde durması gerçek dilimli çark grafiğini
  gerektiriyor → `TODO(#16)`, Aşama 3d.
- Ödül havuzuna dokunulmadı (#16'nın konusu).

## Arayüz

Ana ekrana **Günlük Seri** kartı eklendi (`home_screen.dart:_StreakCard`):
mevcut seri, bugün tamamlandı mı, seri için kalan adım, sonraki kilometre taşına
kalan gün. Gün bitmesine `GameConstants.streakWarningHours` (3 saat) kaldıysa ve
seri hâlâ tamamlanmadıysa turuncu uyarı satırı çıkıyor.

Kart dakikada bir **yalnızca kendini** tazeliyor (`DayResetCountdown` ile aynı
desen); ana ekranın tamamı yeniden çizilmiyor. Bildirim gönderilmiyor —
`POST_NOTIFICATIONS` izni Aşama 2'de eklenecek.

Profil ekranında streak satırına "En uzun seri: N gün" alt bilgisi eklendi.

## Şema v3

Yeni alanlar: `longestStreak`, `lastSeenAt` (UTC), macera `startingSteps`.
Hepsi eksikken varsayılana düştüğü için 2 → 3 taşıması içerik değiştirmiyor;
sürüm yine de artırıldı (Model Kuralları #2 disiplini).

## Test

`test/streak_test.dart` — 20 test: 5 gün üst üste, gün atlama, aynı gün ikinci
tetikleme, `refreshStreak` ile aktivitesiz kırılma, en uzun seri, gün sınırının
iki yanı, kilometre taşları, `GameClock` monotonluk (geri alma / NTP toleransı /
UTC ilerlemesi / diskten restore), ve donmuş zamanda seri + çark davranışı.

**Testlerin kapsamadığı:** gerçek saat dilimi değişimi — bkz. yukarıdaki
"BİLİNEN BOŞLUK — test edilemeyen durum".

---

# Aşama 1b — Adım → para (#12) ✅ (2026-08-18)

Panonun en yüksek etki/emek oranlı maddesi kapandı: `coins` artık kazanılıyor,
mağaza ölü olmaktan çıktı.

## Ekonomi

Oran ve tavan **mevcut mağaza fiyatlarından türetildi**; fiyatlara dokunulmadı
(300 / 500 / 800 / 1200).

| Sabit | Değer | Nereden |
|---|---|---|
| `GameConstants.stepsPerCoin` | 50 | 6.000 adım/gün = 120 coin/gün = 840 coin/hafta → haftada 1-2 anlamlı satın alma |
| `GameConstants.maxDailyStepCoins` | 400 | 20.000 adım karşılığı, yani `dragonStepGoal` ile aynı: gerçekten o kadar yürüyen cezalanmaz |

Önerilen oranda kullanıcı profilleri:

| Günlük adım | Coin/gün | Coin/hafta | Bir haftada |
|---|---|---|---|
| 3.000 | 60 | 420 | 1 × 300 |
| 6.000 (hedef) | 120 | 840 | 300 + 500 · ya da 800 |
| 10.000 | 200 | 1.400 | 1 × 1200 |
| 20.000 (tavan) | 400 | 2.800 | ~2 × 1200 |

## Çift sayma yasağı

Para **delta**dan kazanılır, toplamdan değil:

```
bekleyen = profile.totalSteps - profile.lastRewardedStepCount
```

`UserProfile.lastRewardedStepCount` yalnızca **paraya çevrilmiş** adım kadar
ilerler; bir coin'e yetmeyen artık adımlar bir sonraki hesaba kalır. Alan
persist edildiği için kapat-aç turu da güvenli.

Neden bu üç senaryoda da çift sayma yok:

| Senaryo | Neden güvenli |
|---|---|
| Uygulama kapat-aç | `totalSteps` ve `lastRewardedStepCount` birlikte diske yazılıyor; ikisi de geri geliyor |
| Gün değişimi | `totalSteps` günlük değil, ömür boyu sayaç — sıfırlanmıyor. Sıfırlanan tek şey `DailyProgress.coinsEarned` (tavan sayacı) |
| Macera seçimi | B1'den beri `today.steps` sıfırlanmıyor; `totalSteps` zaten hiç sıfırlanmıyordu |
| Kaynak aynı değeri tekrar bildirirse | `_onStepsReported` deltayı hesaplayıp `<= 0` ise hiç işlem yapmıyor |

## Günlük tavan

`DailyProgress.coinsEarned` günün adım kazancını tutar; gün değişince yeni
`DailyProgress` kurulduğu için kendiliğinden sıfırlanır.

**Tavana dayanınca kalan adımlar bilerek taşınmaz.** Aksi halde adım biriktirip
ertesi gün bozdurmak tavanı anlamsız kılardı.

Tavan **sessizce durmuyor**: dolduğu anda bir kez SnackBar
(`_showCoinCapNotice`), ana ekranda da kalıcı "günlük sınır doldu" satırı.

## Adım kaynağı soyutlaması

`lib/services/step_source.dart`:

- `StepSource` — sözleşme: `cumulativeSteps` **kümülatif ve azalmayan**.
  Gerçek pedometer de cihaz açılışından beri kümülatif sayar.
- `ManualStepSource` — bugünkü tek uygulama; demo kontrolleri besliyor.

`RootShell` kaynağı dinliyor; tüm akış tek bir yerden geçiyor:
`_onStepsReported(int cumulativeSteps)` → günlük ilerleme + para + seri +
macera. Demo butonlarının callback'i (`_simulateSteps`) artık yalnızca kaynağı
besleyen tek satırlık bir adaptör.

**Aşama 2'de** yalnızca `StepSource`'un yeni bir uygulaması (pedometer +
gün başı baseline) yazılacak; kazanç, seri ve macera kodu değişmeyecek.

## Item buff hook'u

`calculateStepCoins(..., double multiplier = 1.0)` — çarpan noktası bırakıldı.
Yalnızca ödemeyi büyütür, tüketilen adımı değiştirmez (buff adımı daha değerli
yapar, daha çok adım harcatmaz) ve günlük tavanı aşamaz.

> Buff sistemi **yazılmadı**. Aşama 3'te "adım başına +%X para" (kart #9)
> `coin_calculator.dart` içindeki `TODO(items)` noktasına bağlanacak.

## Arayüz

Ana sayfada adım halkasının hemen altında: "Bugün adımlarından **N** coin
kazandın." + sağda "50 adım = 1" hatırlatması. Tavan dolunca metin
"— günlük sınır doldu." ile tamamlanıyor.

## Şema v4

Yeni alanlar: `UserProfile.lastRewardedStepCount`, `DailyProgress.coinsEarned`.

**3 → 4 taşıması içerik değiştiriyor:** `lastRewardedStepCount` mevcut
`totalSteps` değerine eşitleniyor. Gerekçe: ekonomi yokken atılmış adımlar
geriye dönük para kazandırmamalı. (Aksi halde eski kayıttaki 42.000 adım
açılışta tavan dolusu 400 coin verirdi.)

## Test

`test/step_coins_test.dart` — 23 test: dönüşüm oranı, artık adımların
taşınması, günlük tavan (tam/kısmi/dolu), buff çarpanı, çift sayma (aynı değer
tekrar, sayaç geriye, ardışık partiler, macera seçimi), gün değişimi, kapat-aç
turu, v3→v4 taşıması, `ManualStepSource` davranışı.

## Not — A4 hâlâ açık

Mağaza butonu `'${item.cost} XP'` yazıyor ama `coins` harcıyor. Para
kazanılamadığı için bugüne kadar görünmüyordu; **artık kullanıcının gözüne
girecek.** Aşama 3'te #11/#12 kapsamında düzeltilecek (bkz. Kova A/A4).

---

# Çalışma Kuralı — Commit

**Asla commit atma.** `/commit` çalıştırma, commit-commands skill'ini kullanma,
`git commit` çağırma. Commit'leri kullanıcı elle atıyor.

Bir iş bitince: değişen dosyaları listele, ne yaptığını özetle, önerdiğin commit
mesajını yaz. Commit'i kullanıcı atacak.

---

# Streak Koruması — ONAYLANDI (2026-08-18) → ✅ Aşama 2c'de uygulandı

Aşama 1a'da önerilen tasarım **olduğu gibi kabul edildi** ve Aşama 2c'de
uygulandı. Uygulama ayrıntıları için "Aşama 2c" bölümüne bak; aşağıdaki
karar metni referans olarak duruyor.

- `UserProfile.streakFreezes` (int, varsayılan 0) + `lastFreezeUsedOn` (DateTime?)
- **Tüketim tarafı ŞİMDİ uygulanacak.** Varsayılan 0 olduğu için davranış
  bugün değişmiyor.
- Otomatik ve geriye dönük: seri kırılacakken jeton varsa 1 harcanır, seri
  korunur ama **artmaz**.
- Sınırlar: stok en fazla 2, art arda en fazla 1 gün korunur.
- Kullanıcıya bildir: "Serin korundu, 1 dondurma hakkı kullanıldı."
- **Kazanım yolları ERTELENDİ:** 7 günlük kilometre taşı ödülü ve mağazadan
  satın alma Aşama 3'e ait (ödül altyapısı ve gerçek Item modeli orada geliyor).
  `TODO(items)` ile işaretle.
- Şema **v7** ile geldi (karar anında v5 planlanmıştı; 2a ve 2b araya girdi).

Gerekçe: tek kötü günde uzun seriyi kaybetmek, streak sistemlerinin terk
ettiren bir numaralı sebebi. Tüketim mantığı şimdi yazılıyor çünkü gün
aritmetiği taze; sonra dönmek `refreshStreak`'i ikinci kez açmak demek.

---

# Aşama 2 — EN KRİTİK RİSK

`StepSource` sözleşmesi `cumulativeSteps`'in **azalmayan** olduğunu varsayıyor.
Gerçek pedometer bu sözleşmeyi **ihlal edecek**: Android'de TYPE_STEP_COUNTER
cihaz açılışından beri sayar ve **cihaz yeniden başlayınca sıfırlanır.**

Ekonomi `totalSteps - lastRewardedStepCount` deltasından para üretiyor.
Ham sensör değeri geriye giderse iki şeyden biri olur: oyuncu adımlarını
kaybeder, ya da baseline yanlış kurulursa bir anda tavan dolusu coin kazanır.

**Çözüm yönü:** sensörün ham değeri ile `totalSteps` AYRI kavramlar olsun.
Sensör baseline'ı ayrı saklansın, düşüş tespit edilince baseline yeniden
kurulsun, `totalSteps` **asla geriye alınmasın**. `StepSource` sözleşmesi
korunsun — ihlali pedometer uygulaması içinde emsin, `RootShell`'e sızdırma.

**Özel test şart:** sensör 8000'den 50'ye düşerse `totalSteps`, `coins` ve
`lastRewardedStepCount` ne oluyor?

Aynı desen `GameClock`'un geriye alınan saati emmesiyle birebir aynı —
o çözümü örnek al.

---

# Aşama 2a — Gerçek pedometer (#1) ✅ (2026-08-18)

Kart #1 kapandı. Triajdaki **C2** (POST_NOTIFICATIONS eksikliği) da burada
kapandı.

## Kritik risk nasıl çözüldü

Yukarıdaki "EN KRİTİK RİSK" bölümünün cevabı **üç ayrı katmana** bölündü.
Hiçbiri diğerinin işini yapmıyor:

| Katman | Dosya | Sorumluluk |
|---|---|---|
| Ham sensör | `services/raw_step_sensor.dart` | Platform verisi. Değeri **azalabilir**; düzeltmez, olduğu gibi verir. |
| Sıfırlanma emme | `services/pedometer_step_source.dart` | Azalan ham değeri `StepSource`'un azalmayan sözleşmesine çevirir. `GameClock` deseninin aynısı. |
| Hız kontrolü | `core/utils/step_rate_limiter.dart` | Saf domain kuralı: "insan bu kadar adımı bu sürede atabilir mi". Sensör/platform bilmez. |

`RootShell` **hiçbir koşulda** azalan bir kümülatif değer görmez — ihlal
kaynağın içinde emilir, sözleşme değişmedi.

### Aritmetik: tek referans, iki sayaç

Artış her zaman `ham - öncekiHam` üzerinden. Sıfırlanma tespiti **offset'e
değil, bir önceki ham okumaya** göre yapılır (ilk tasarım offset'e bakıyordu;
testler yakaladı, düzeltildi).

Kalıcı üç yeni alan (`UserProfile`):

| Alan | Anlamı |
|---|---|
| `lastReportedStepCount` | Kaynağın **raporladığı** son kümülatif değer |
| `lastSensorReading` (`int?`) | En son görülen **ham** sensör değeri |
| `lastStepReportAt` (UTC) | Hız kontrolünün "aradan ne kadar geçti" hesabı |

`lastSensorReading`'in **nullable olması şart:** varsayılan 0 olsaydı, cihaz
açılışından beri birikmiş ham değer (milyonlarca adım) ilk okumada tek seferde
kredilenirdi. `null` = referans henüz kurulmadı, ilk okuma yalnızca referans
kurar.

`lastReportedStepCount` ile `totalSteps` **ayrı kavramlar**: hız kontrolüne
takılan adımlar raporlanmış sayılır ama kredilenmez. İşaretçi her raporda
ilerlediği için **yakılan adım bir sonraki raporda geri sızmaz**. 1b'deki
`lastRewardedStepCount` / `totalSteps` çift-sayma koruması hiç değişmedi.

### Sıfırlanma: reboot mu, arıza mı

Ayrımı **oturum bağlamı** yapar:

| Durum | Varsayım | Davranış |
|---|---|---|
| Soğuk açılışın **ilk** okuması düşük | Cihaz kapalıyken yeniden başlatılmış | Ham değer telafi edilir (en fazla `maxResetRecoverySteps` = 10.000) |
| **Oturum içi** düşüş (8000 → 50) | Sensör arızası | Hiçbir şey kredilenmez; değerler aynen kalır |

Arıza dalındaki asıl tehlike **toparlanma**: 8000 → 50 → 8010 dizisinde
normalize sayaç 15.960'a fırlar. Bu sıçrama hız kontrolünde yanar.

## Hile koruması

`limitStepBatch(reportedSteps, elapsed)` — `calculateStepCoins` ile aynı
desende saf fonksiyon. İzin = `max(stepBurstAllowance, elapsed × maxStepsPerMinute)`.

| Sabit | Değer | Gerekçe |
|---|---|---|
| `maxStepsPerMinute` | 250 | Yarış yürüyüşü ~200/dk, koşu ~180/dk. Telefon sallamak 400+ üretir. |
| `stepBurstAllowance` | 100 | Aynı saniyede gelen tek bir sensör partisi kırpılmasın. Bilerek küçük. |
| `maxResetRecoverySteps` | 10.000 | Günlük coin tavanının yarısı (200 coin). |

Hesap **milisaniye** üzerinden: saniyeye yuvarlamak kısa aralıklarda gerçek
adımları kırpıyordu.

Günlük coin tavanının (1b) yerine geçmez, **üstünde** çalışır: burada
"kaç adım", orada "kaç para" sorusu cevaplanır. İkisi sıralı uygulanır.

**Demo kaynağı muaf.** `StepSource.isPhysical` eklendi; `ManualStepSource`
`false` döner ve hız kontrolünden geçmez — emülatörde +20.000 çalışmaya devam
etmeli.

### BİLİNEN BOŞLUK — taban izin sızıntısı

Toparlanma sıçramasının `stepBurstAllowance` kadarı (100 adım = 2 coin)
kredilenir. Sensör arızası başına bir kez, günlük tavanla sınırlı. Tabanı
sıfırlamak, partiler hâlinde gelen gerçek sensör verisini kırpardı; ölçülü
bir takas olarak bırakıldı.

## Platform

**Android:** `pedometer` paketi → `TYPE_STEP_COUNTER`. Cihaz açılışından beri
kümülatif, uygulama kapalıyken de artar → kapalıyken atılan adımlar ek bir iş
olmadan, baseline aritmetiğinden gelir. Arka plan servisi yok.

**iOS:** `pedometer` paketi **kullanılmadı.** Paket iOS'ta sayacı son cihaz
açılışından başlatıyor; `CMPedometer` yalnızca 7 günlük geçmiş tuttuğu için
uzun süre yeniden başlatılmamış cihazda o başlangıç noktası kayar ve değer
oturumlar arasında **düşer** → sahte sıfırlanma → her açılışta bedava adım.
Bunun yerine `ios/Runner/AppDelegate.swift` içinde kendi kanalımız var:
başlangıç anını Dart veriyor (son rapor anı), yani okunan değer doğrudan
"son rapordan beri atılan adım". Geçmiş sorgusu ve canlı akış tek kanaldan.
`RawStepSensor.isBootCumulative` bu iki aritmetiği ayırıyor.

> ⚠️ **iOS kodu derlenmedi ve test edilmedi.** Geliştirme Windows'ta yapılıyor.
> Swift kanalı `AppDelegate.swift` içine yazıldı (yeni dosya `project.pbxproj`
> düzenlemesi gerektirirdi). **Gerçek cihazda doğrulanmalı.**

## İzinler

| Platform | İzin | Nerede |
|---|---|---|
| Android | `ACTIVITY_RECOGNITION` | manifest + runtime (`permission_handler`) |
| Android | `POST_NOTIFICATIONS` | manifest — **triaj C2 kapandı** |
| Android | `stepcounter` / `stepdetector` uses-feature `required=false` | sensörsüz cihaz Play'de filtrelenmesin |
| iOS | `NSMotionUsageDescription` | Info.plist |

Reddedilme davranışı: hiçbir yol exception fırlatmaz. `StepPermissionStatus`
beş durum taşır, ana ekranda açıklayıcı kart + kalıcı reddedildiyse
"Ayarları Aç" düğmesi çıkar. Macera, mağaza, çark, profil çalışmaya devam eder.

> **Yapılacak (macOS'ta):** `permission_handler` iOS'ta Podfile'da
> `PERMISSION_*` makroları ile kısıtlanmazsa tüm izinleri derlemeye katar ve
> App Store incelemesinde sorun çıkarır. Repoda henüz `ios/Podfile` yok
> (ilk macOS derlemesinde üretilecek); o zaman yalnızca
> `PERMISSION_EVENTS`/`PERMISSION_NOTIFICATIONS` gibi gerekenler açılmalı.

## Debug görünürlüğü

"Demo Kontrolleri" kartı **"Adım Kaynağı"** oldu: aktif kaynağı yazıyor
(`Pedometer (gerçek sensör)` / `Manuel (demo kontrolleri)`) ve debug'da bir
anahtarla kaynak değiştiriliyor. Debug varsayılanı **manuel** (emülatör kutudan
çıkar çıkmaz çalışsın), release varsayılanı **pedometer**. Gerçek sensör
aktifken demo butonları kilitli ve nedenini söylüyor.

`ManualStepSource` **korundu** — testlerin ve emülatörün tek adım üretme yolu.

## Şema v5

Yeni alanlar: `lastReportedStepCount`, `lastSensorReading`, `lastStepReportAt`.
4 → 5 taşıması: `lastReportedStepCount = totalSteps`, diğer ikisi **null**.
Böylece güncelleme sonrası ilk gerçek okuma yalnızca referans kurar, birikmiş
ham değer kredilenmez.

⚠️ **Streak koruması artık v6.** CLAUDE.md'de v5 yazıyordu; 2a önce geldi.

## Test

- `test/step_rate_limiter_test.dart` — 10 test: sınırdaki hız, imkânsız hız,
  uzun aradan sonra gerçek yürüyüş, taban izin, milisaniye hassasiyeti,
  negatif süre.
- `test/pedometer_step_source_test.dart` — 20 test: **CLAUDE.md senaryosu
  (8000 → 50 → 8010)**, ilk kurulumda birikmiş ham değerin kredilenmemesi,
  reboot telafisi ve üst sınırı, kapalıyken atılan adımlar (Android + iOS),
  yakılan adımın geri gelmemesi, gün değişimi, izin reddi, kapat-aç turu,
  v4→v5 taşıması.

Toplam **116 test geçiyor**, `flutter analyze` temiz.

---

# Aşama 2b — Adım → XP (#2) ✅ (2026-08-18)

Kart #2 kapandı. XP artık yalnızca düşman ve çarktan değil, **her adımdan**
geliyor.

## Seviye eğrisi — değiştirilmedi, gerekçelendirildi

Mevcut formül korundu (Kural 1/3): `xpToNextLevel = baseXpPerLevel * level`.
Seviye başına maliyet **doğrusal** artar, kümülatif maliyet karesel olur:

```
N. seviyeye ulaşmak için gereken toplam XP = 500 · N · (N-1)
```

Günlük girdisi kabaca sabit olan bir oyuncu için seviye numarası `√gün`
hızında ilerler — erken seviyeler hızlı (ilk oturumda ilerleme hissi),
sonrakiler anlamlı.

**Üstel eğri bilerek seçilmedi.** Girdisi gerçek hayattan gelen bir oyunda
üstel maliyet bir noktada "aylarca sürecek seviye" üretir ve sayı durmuş gibi
görünür. Doğrusal artış, sonraki seviyeyi her zaman makul bir ufukta tutar.

## Oran: `stepsPerXp = 2`

Eğriden türetildi: 10. seviye 45.000 XP istiyor, günde 6.000 adım 3.000 XP
eder.

| Seviye | Bu seviye | Kümülatif XP | Kümülatif adım | Gün (6.000/gün) |
|---|---|---|---|---|
| 1→2 | 1.000 | 1.000 | 2.000 | 0,3 |
| 3→4 | 3.000 | 6.000 | 12.000 | 2 |
| 5→6 | 5.000 | 15.000 | 30.000 | 5 |
| 7→8 | 7.000 | 28.000 | 56.000 | 9,3 |
| 9→10 | 9.000 | 45.000 | 90.000 | **15** |

Kullanıcı profilleri (yalnızca adımdan; düşman 300–1.500 XP ve çark bunu
~%20 kısaltır):

| Günlük adım | XP/gün | 10. seviye | 20. seviye |
|---|---|---|---|
| 3.000 | 1.500 | 30 gün | 127 gün |
| 6.000 (hedef) | 3.000 | **15 gün** | 63 gün |
| 10.000 | 5.000 | 9 gün | 38 gün |
| 20.000 | 10.000 | 4,5 gün | 19 gün |

Tablodaki 15 ve 9 gün **testle doğrulandı** (`step_xp_test.dart`), prosa
tahmini değil.

**Günlük XP tavanı yok.** Para tavanı ([`maxDailyStepCoins`]) bir ekonomi
koruması; XP'nin harcanacağı bir yer olmadığı için aynı gerekçe geçmiyor.
Sahte adıma karşı koruma zaten akışın yukarısında, `limitStepBatch` içinde.
Gerçekten 20.000 adım atan kullanıcının ilerlemesi kesilmemeli.

## İşaretçi kararı: AYRI, paylaşılmadı

`UserProfile.lastXpRewardedStepCount`, `lastRewardedStepCount`'tan **ayrı**.

**Neden paylaşılmadı:** para işaretçisi günlük tavan dolduğunda bekleyen
**tüm** adımları tüketiyor (1b kararı: biriktirip ertesi gün bozdurmak yok).
Tek işaretçi olsaydı, para tavanına ulaşan oyuncunun **XP'si de dururdu** —
birbirine bağlanmaması gereken iki ekonomi. Ayrıca iki oranın artık-adım
davranışı da farklı (50 vs 2).

Test: `para ve XP işaretçileri bağımsız` grubu — tavan doluyken 4.000 adım
para vermiyor ama 2.000 XP veriyor.

## Seviye atlama yayını

`lib/services/level_events.dart` — `GameStorage` deseninde statik servis,
`Stream<LevelUpEvent>` broadcast.

XP veren **tüm** yollar tek noktadan geçiyor: `RootShell._awardXp`. Öncesinde
`_profile.addXp` üç ayrı yerden çağrılıyordu (adım/düşman/çark); yayını
oraya bağlamak her birini tek tek gezmek demekti.

> Aşama 3'teki item seviye kilidi (#10) ve mağaza seviye kilidi (#11) bu
> yayını dinleyecek. Bugün tek dinleyici kutlama.

Tek ödülle birden fazla seviye atlanırsa **tek** olay yayınlanır
(`levelsGained > 1`), her seviye için ayrı değil.

## Arayüz

- Ana ekrandaki kazanç satırı ikiye çıktı: coin + XP, her biri kendi oranıyla.
  `DailyProgress.xpEarned` yalnızca **adımdan** gelen XP'yi sayar; düşman ve
  çark XP'si buraya yazılmaz — satır "yürüyerek ne kazandım" sorusunu
  cevaplıyor.
- XP ilerleme çubuğu zaten `HeroProgressRings` içinde vardı, dokunulmadı.
- Seviye atlama kutlaması: `AppColors.xp` çerçeveli, 5 saniyelik zengin
  SnackBar. `_showStreakMilestone` / `_showCoinCapNotice` ile aynı desen.
  `setState` içinden çağrılabilsin diye `addPostFrameCallback` ile
  gösteriliyor.

## Şema v6

Yeni alanlar: `UserProfile.lastXpRewardedStepCount`, `DailyProgress.xpEarned`.
5 → 6 taşıması: `lastXpRewardedStepCount = totalSteps`. Gerekçe 1b ile aynı —
XP yokken atılmış adımlar geriye dönük seviye kazandırmamalı, yoksa
güncelleme sonrası ilk açılışta oyuncu birkaç seviye birden atlar.

⚠️ **Streak koruması artık v7.**

## Test

`test/step_xp_test.dart` — 22 test: dönüşüm oranı, artık adımların taşınması,
tavansızlık, buff çarpanı, seviye eğrisi (doğrusal artış + 45.000 XP + 15/9
günlük ulaşma süreleri), çift sayma (aynı adım, ardışık parti, gün değişimi),
para/XP işaretçi bağımsızlığı, seviye atlama olayı (tek/çoklu/hiç), kapat-aç
turu, v5→v6 taşıması.

Toplam **138 test geçiyor**, `flutter analyze` temiz.

---

# Aşama 2c — Streak koruması ✅ (2026-08-18)

Onaylanmış tasarımın **tüketim tarafı** uygulandı. Kazanım yolları Aşama 3'te
(bkz. `UserProfile.grantStreakFreeze` üzerindeki `TODO(items)`).

**Bugün hiçbir davranış değişmiyor:** `streakFreezes` varsayılanı 0, kazanım
yolu yok. Tüketim mantığı şimdi yazıldı çünkü gün aritmetiği bu işte tazeydi;
sonra dönmek `refreshStreak`'i ikinci kez açmak demekti.

## Yeni alanlar

| Alan | Rol |
|---|---|
| `UserProfile.streakFreezes` | Eldeki jeton (varsayılan 0, tavan `maxStreakFreezes` = 2) |
| `UserProfile.lastFreezeUsedOn` | Jetonun kapattığı son oyun günü — "art arda koruma yok" kuralının dayanağı |

## Dönüş tipi değişti: `bool` → `StreakDayOutcome`

`refreshStreak` artık `unchanged / broken / frozen` döner. Gerekçe: "gün
atlandı ama jetonla kurtarıldı" üçüncü bir durum ve kullanıcıya söylenmesi
gerekiyor; bool bunu ifade edemiyor. `streak_test.dart` içindeki iki iddia
buna göre güncellendi (test silinmedi, daha kesin hâle geldi).

## Köprüleme kuralı

Tek bir private yardımcı (`_bridgeWithFreeze`) hem pasif kontrolden
(`refreshStreak`) hem aktif yoldan (`registerStreakDay`) çağrılıyor — aynı
mantığın iki kopyası olmasın diye. İki yolun aynı sonucu verdiği testle
doğrulandı.

Köprülenen gün = son aktif günden sonraki oyun günü (`GameDay.nextResetAfter`).
`lastActiveDay` oraya taşınır, `streakDays` **değişmez**.

Üç sınır:

| Sınır | Nasıl |
|---|---|
| Yalnızca **tek** kaçırılan gün | `gap == 2` şartı. İki gün üst üste kaçıran, stokta iki jeton olsa bile serisini kaybeder — jeton da boşa harcanmaz. |
| Stok en fazla 2 | `GameConstants.maxStreakFreezes`; `fromJson` içinde savunma amaçlı kırpma da var (elle düzenlenmiş kayıt sınırsız jeton getirmesin). |
| Art arda en fazla 1 gün | Son aktif gün zaten jetonla kapatılmışsa (`lastFreezeUsedOn` ile aynı oyun günü) ikinci jeton kullanılamaz. Arada **gerçek** aktivite varsa jeton tekrar geçerli. |

**Otomatik ve geriye dönük** olması bilinçli: manuel bir kurtarma penceresi
koyulsaydı, o pencereyi kaçıran kullanıcı iki kez cezalanırdı. Serinin amacı
alışkanlık, ceza değil.

Gün döngüsü saniyede bir çalıştığı için **aynı boşluk için ikinci kez jeton
harcanmaması** ayrıca test edildi: köprüden sonra `gap` 1'e indiği için
sonraki çağrılar `unchanged` döner.

## Arayüz

- Jeton harcandığında: "Serin korundu, 1 dondurma hakkı kullanıldı. Kalan
  hak: N." — `_refreshDayCycle` `initState` içinden de çağrıldığı için
  bildirim `addPostFrameCallback` ile gösteriliyor.
- Seri kartında stok satırı **yalnızca stok > 0 iken** çıkar. Kazanım yolu
  gelene kadar kullanıcıya boş bir sayaç göstermenin anlamı yok.

## Şema v7

`streakFreezes`, `lastFreezeUsedOn`. Varsayılanları (0 / null) doğru olduğu
için 6 → 7 taşıması içerik değiştirmiyor; sürüm yine de artırıldı
(Model Kuralları #2 disiplini).

## Test

`test/streak_freeze_test.dart` — 21 test: varsayılan davranışın değişmediği,
tek günün köprülenmesi, serinin korunup **artmaması**, köprüden sonra normal
ilerleme, aynı boşluk için ikinci harcama olmaması, iki gün üst üste, art arda
koruma yasağı, arada gerçek aktivite, jeton bitmesi, kırık seri, geriye alınan
saat, aktif/pasif yol eşitliği, stok tavanı, kapat-aç turu, bozuk kayıt
kırpması, v6→v7.

Toplam **159 test geçiyor**, `flutter analyze` temiz.

---

# Not — şema sürümü

Aşama 0 bölümünde "Şema sürümü: 2" yazıyor; o bölüm yazıldığında güncel
sürüm buydu. **Güncel sürüm v7** (bkz. Aşama 2c).

---

# Aşama 2d — Açılış dayanıklılığı ✅ (2026-08-19)

Kart yok; Faz 0 incelemesinde çıkan tek gerçek hata.

## Ne düzeltildi

**Açılış akışı artık hiçbir koşulda ekranı kilitlemiyor.** Önceden
`_initializeApp` içindeki `CharacterStorage.load()`, `GameStorage.load()` ve
`AdventureNotificationService.initialize()` çağrılarının hiçbirinde hata
yönetimi yoktu. Platform kanalı düşerse (SharedPreferences yok, bildirim
kanalı yok) `_isLoading` sonsuza kadar `true` kalıyor ve kullanıcı markalı
açılış görselinde asılı kalıyordu — ne hata mesajı vardı ne çıkış yolu.

- Kayıt okuma `try/catch` içine alındı; hata `debugPrint` ile loglanır,
  açılış temiz varsayılanla devam eder (gerekçe: **GD1**).
- Bildirim servisi başlatması `.catchError` ile ayrıştırıldı; bildirim
  kurulamayan cihazda oyunun geri kalanı açılır.
- `CharacterStorage.save()` de sarmalandı: yazma başarısızsa oturum devam eder.
- Hata sessiz kalmıyor: `scaffoldMessengerKey` üzerinden oturumda **bir kez**
  açıklayıcı SnackBar gösterilir (CLAUDE.md — Model Kuralları #4).
- `adventure_notification_service.dart` hatırlatma sayısı artık
  `GameClock.now()` ile hesaplanıyor (gerekçe: **GD2**).

## Test

- `test/app_boot_test.dart` — 4 test: kayıt okunamazken açılış ekranında
  asılı kalınmaması, kullanıcının sessizce geçiştirilmemesi, sağlıklı
  kayıtta uyarı çıkmaması, açılış görselinin hemen kaybolmaması.
  **Not:** platform kanalı cevapları `testWidgets`'in sahte saatiyle teslim
  edilmiyor; açılış hem `WidgetTester.runAsync` ile gerçek zamanda hem de
  `pump` ile sahte saatte ilerletiliyor. Mock kurulu olup olmamasına göre iki
  yoldan biri çalışıyor.
- `test/step_history_test.dart` — 8 test: `DailyStepRecord` gün anahtarı,
  ilerleme kırpması, sıfır hedefte sıfıra bölme olmaması, kayıt turu, eksik
  alanlar; `GameState` tarafında geçmişin yokluğu, liste olmayan geçmiş ve
  bozuk satırların atılıp sağlamların korunması. (Arkadaşımın eklediği
  `DailyStepRecord` modelinin hiç testi yoktu; yapısına dokunulmadı.)

Toplam **179 test geçiyor**, `flutter analyze` temiz.

## Sonraki adım

Aşama 3 — Item temeli (`#8 → #10 → #11 → #16`). 784 asset hâlâ
`pubspec.yaml`'a eklenmemiş durumda (triaj C8).


---

# Aşama 2e — Gün sınırı ve adım geçmişi bütünlüğü ✅ (2026-08-19)

Faz 0'daki B listesinin (arkadaşımın mimari tercihleri) karara bağlandığı
birim. Kararların gerekçeleri **GD4–GD6**; madde madde durum "Arkadaşımın
Kodu" bölümünde.

## Ne değişti

| Konu | Değişiklik |
|---|---|
| Gün sınırı | `GameDay.dayStartHour` 0 → **4** (Aşama 1a kararı geri geldi) |
| Çark açığı | 23:59'da çevirip 00:01'de tekrar çevirme kapandı |
| Halka arşivi | Kayıt artık **oyun gününe** anahtarlanıyor, ham tarihe değil |
| Geçmiş boyutu | En yeni **400** gün tutuluyor (`maxStepHistoryDays`) |
| Testedilebilirlik | Arşivleme mantığı `core/utils/step_history.dart`'a taşındı |
| Android | `MainActivity.kt` — `prepare()` patlarsa `MediaPlayer` sızıntısı |
| Biçim | `dart format` uygulanmamış 3 dosya düzeltildi (**triaj C1 kapandı**) |

## Gizli hata: arşiv gününün kayması

Gün sınırı gece yarısı **olmadığında**, `DailyProgress.date`'in ham değerini
kullanarak arşivlemek kaydı yanlış güne yazıyor: 20 Ağustos 01:00'de açılmış
bir günlük ilerleme aslında **19 Ağustos** oyun gününe ait, ama ham tarih
20 Ağustos'u gösteriyor. 00:00 sınırında bu hiç görünmüyordu; 04:00'e dönünce
açığa çıkacaktı. `archiveStepDay` artık `GameDay.startOf(...)` kullanıyor.
Aynı düzeltme profil ekranındaki "Son 3 Gün" ve takvim ekranının "bugün"
hesabına da uygulandı.

## Test

`test/step_history_archive_test.dart` — 13 test: gün ortasında açılmış gün,
gün sınırının iki yanı, aynı günün iki kez arşivlenmesi, sıralama, gelen
listenin değiştirilmemesi, sınırın altı/üstü/sıfır/negatif, arşivlemenin
sınırı kendi başına uygulaması, gece yarısının iki yanının aynı oyun günü
olması.

Toplam **192 test geçiyor**, `flutter analyze` temiz.

## Sonraki adım

Aşama 3 — Item temeli (`#8 → #10 → #11 → #16`). 784 asset hâlâ
`pubspec.yaml`'a eklenmemiş (triaj C8).


---

# Aşama 3 — Item temeli ✅ (2026-08-19)

Kartlar **#8** (item modeli + katalog), **#10** (seviye kilidi), **#11** (mağaza
seviye kilidi) kapandı. Triajdaki **A4** (mağaza para birimi) ve **C8** (784
PNG pubspec'te değil) de burada kapandı. Aşama 2c'de bilerek boş bırakılan
**streak dondurma kazanım yolları** da bağlandı.

## Karar: 784 görselin hepsi oyuna girdi

CLAUDE.md'deki "hepsi mi, seçki mi?" sorusunun cevabı **hepsi**. Gerekçe:
toplam 1,8 MB (ortalama ~2 KB pixel art), yani APK maliyeti yok; nadirlik ve
seviye kilidi zaten 784 item'ı uzun bir ilerlemeye yayıyor. Seçki yapmak,
oyuncuya daha az şey verip aynı işi yapmak olurdu.

## Katalog nasıl üretiliyor

`CharacterCatalog` deseninin aynısı: **sanat klasörü doğruluk kaynağı**, kod
yalnızca ona anlam veriyor.

| Dosya | Rol |
|---|---|
| `lib/models/item.dart` | `Item`, `ItemCategory` (+rol, sınıf kısıtı), `ItemBuff` |
| `lib/data/item_definitions.dart` | 166 temel adın **Türkçe adı ve nadirliği** |
| `lib/core/utils/item_rules.dart` | Saf türetme: yol çözümleme, seviye, fiyat, buff |
| `lib/services/item_catalog.dart` | `AssetManifest` taraması + süzgeçler |

Akış: `lib/Items/swords/fire_sword.png` → kategori `swords`, temel kimlik
`swords/fire_sword` → tablo ("Ateş Kılıcı", nadir) → seviye bandı, fiyat, buff.
Varyant dosyaları (`dagger_variant_04`) aynı satırdan beslenir; ada varyant
numarası eklenir ("Hançer 4").

**Model Kuralları #1 temiz:** `Item` diske hiç yazılmıyor — `ownedItemIds`
yalnızca `String` kimlik tutuyor, item her açılışta katalogdan çözülüyor.
Görsel `assetPath` ile `String` olarak taşınıyor; `IconData` yok.

## Üretilen denge

| Nadirlik | Adet | Seviye | Fiyat |
|---|---|---|---|
| Sıradan | 371 | 1–3 | 100–125 |
| Az Bulunur | 271 | 4–7 | 300–350 |
| Nadir | 81 | 8–12 | 775–875 |
| Epik | 43 | 14–19 | 2.375–2.725 |
| Efsanevi | 18 | 22–29 | 7.550–8.825 |

6.000 adım/gün = 120 coin/gün oyuncusu için kabaca: sıradan yarım gün, nadir
bir hafta, epik üç hafta, efsanevi iki aydan uzun.

## Mağaza yeniden kuruldu

- **Para birimi coin** — buton artık "N XP" yazmıyor (triaj A4 kapandı).
  Sınıf/dosya adı `XpStoreScreen` olarak **bırakıldı** (bkz. GD10); yalnızca
  kullanıcıya görünen başlık "Mağaza" oldu.
- İki bölüm: **Yükseltmeler** (eski `XpStoreItem`'lar, korundu) ve **Ekipman**
  (katalogdan, oyuncunun **kendi sınıfının** kullanabildikleri).
- Kategori süzgeci + "Alabileceklerim" süzgeci.
- **Kilitli kart sessiz kalmıyor** (Model Kuralları #4): kilit ikonu, "Sv. N"
  etiketi ve dokununca tam neden — "29. seviye gerekiyor, şu an 2.
  seviyedesin" / "375 coin daha gerekiyor" / "zaten sende".
- Kilit **iki yerde** tutuluyor: ekranda (görünürlük) ve `RootShell`'de
  (`_purchaseEquipment`). Son söz state'in.

## Çözülen hata: aynı öğeyi ikinci kez almak parayı yakıyordu

`RootShell._purchase` coin'i düşürüyor, ama kimlik `ownedItemIds` içinde zaten
varsa ikinci kez eklemiyordu. Sahip olunan kozmetiği tekrar satın almak parayı
alıp hiçbir şey vermiyordu. Artık sahiplik önce kontrol ediliyor.

## Streak dondurma kazanım yolları bağlandı

Aşama 2c'de tüketim tarafı yazılmış, kazanım `TODO(items)` ile Aşama 3'e
bırakılmıştı. İkisi de `UserProfile.grantStreakFreeze` üzerinden geçiyor:

1. **Kilometre taşları** (7/30/100 gün) — `_onStepsReported` içinde 1 hak.
2. **Mağaza** — "Seri Dondurma Hakkı", 600 coin, `repeatable: true`.
   Stok doluysa **satış yapılmıyor ve para harcanmıyor**; nedeni söyleniyor.

`XpStoreItem`'a `repeatable` alanı eklendi: kozmetik bir kez alınır, tüketilen
yükseltme stok dolana kadar tekrar alınabilir.

## Test

- `test/item_catalog_test.dart` — 39 test. Türetme kurallarının tamamı, artı
  bir **sanat kapsamı** grubu: dosya sistemini okuyup 784 görselin hepsinin
  item'a dönüştüğünü, kimliklerin benzersizliğini, **her görselin Türkçe tanımı
  olduğunu**, tanımlarda öksüz satır kalmadığını, bütün kategorilerin
  `pubspec.yaml`'da olduğunu ve her karakter sınıfına item düştüğünü doğruluyor.
  Yeni sanat eklenip tanımı unutulursa burada yakalanır.
- `test/store_screen_test.dart` — 14 widget testi: seviye kilidinin gerçekten
  tutması, nedenin söylenmesi, süzgeçler, tekrarlanabilir yükseltme, para
  biriminin coin olduğu. Bu testler yazılırken ekipman kartında gerçek bir
  layout hatası da yakalandı (`SectionCard` içinde `Expanded` sınırsız yükseklik
  alıyordu).

Toplam **245 test geçiyor**, `flutter analyze` temiz.

## Açık kalan

- **#9 (item buff'ları oyuna işlesin)** — `ItemBuff` üretiliyor ve mağazada
  gösteriliyor ama **hiçbir yere uygulanmıyor**: kuşanma (equip) kavramı yok.
  `coin_calculator.dart` / `xp_calculator.dart` içindeki `TODO(items)` çarpan
  kancaları hâlâ boş. Sıradaki iş: envanter + kuşanma, sonra çarpanın
  bağlanması.
- **#16 (çark item verebilsin)** — katalog hazır, çark hâlâ yalnızca XP veriyor.
- Kilometre taşı **item** ödülü (#14) hâlâ Aşama 4b'de.


---

# Arkadaşımın Kodu — inceleme ve kararlar (2026-08-19)

`e902185` + `f28f510` (merge) + `feec7db`. Bunlar **hata değil**, bilinçli
tercihler. Kullanıcı "hepsini kendi kararınla düzelt/geliştir ve ilerle" dedi;
her madde için verilen karar aşağıda. Karar **DOKUNULMADI** olanların gerekçesi
tek cümleyle: çalışan koda mimari uyum için dokunmak boşa risk (Kural 1/3).

### K1. Gün sınırı 04:00 → 00:00'a çekilmişti → ✅ **04:00'e geri alındı**
- **Dosya:** `lib/core/utils/game_day.dart`
- **Neden yapılmıştı:** adım halkası takvim günüyle kapansın ve arşivlensin.
- **Neden geri alındı:** 04:00, Aşama 1a'da iki gerekçeyle seçilmişti — gece
  yarısını geçmiş kullanıcının serisi haksız yere kırılmasın, **ve** çarkın
  gece yarısı açığı kapansın (23:59'da çevir, 00:01'de tekrar çevir). 00:00
  sınırı ikisini de geri açıyordu; hem de en kolay istismar edilecek saatte.
- **Halka ne oldu:** halka artık oyun gününü gösteriyor. Bu **daha tutarlı**:
  halka günlük hedefe göre ölçülen bir ilerlemeyi çiziyor ve o hedef bu
  sınırda sıfırlanıyor. İki ayrı sınır, halkanın ölçtüğü şeyle gösterdiği
  pencereyi ayırırdı.
- Ayrıntı: **GD4**.

### K2. Round süresi adımdan bağımsız sabit 20 dakika → **DOKUNULMADI**
- `roundDuration = 20dk`, `briskWalkingStepsPerMinute`/`syncGraceMinutes`
  kaldırıldı. Denge kararı, kod hatası değil; testler birlikte güncellenmiş.

### K3. Round erken tamamlanınca anında kazanılıyor → **DOKUNULMADI**
- `resolveExpiredRound` artık `resolveRound`'a yönlendiren kabuk.
  `isDefeated` erken çıkışı yerine `roundTargetSteps <= 0` koruması var;
  düşman ölünce hedef 0'a düşüyor ve döngü orada duruyor. **Sonsuz döngü ve
  çift hasar yok — satır satır doğrulandı.**

### K4. Sunum durumu (`presentedRoundOutcomeSerial`) modelde → **DOKUNULMADI**
- "Animasyon oynatıldı mı" bilgisi `AdventureQuest` üzerinde ve diske
  yazılıyor. Model Kuralları #1'i ihlal etmiyor (`int`), yalnızca sunum/model
  sınırını bulanıklaştırıyor. Ayırmak modeli, ekranı ve şemayı birlikte
  değiştirmek demek — kazancı riskini karşılamıyor.

### K5. Ekran, model nesnesini doğrudan değiştiriyor → **DOKUNULMADI**
- `adventure_screen.dart` `RootShell`'in state nesnesini mutasyona uğratıp
  `onAdventureUpdated()` ile kaydettiriyor. Mevcut `setState` mimarisi zaten
  buna dayanıyor (`RootShell` yorumundaki not). Riverpod/Bloc'a geçişte ilk
  kırılacak yer burası; o geçiş geldiğinde birlikte ele alınmalı.

### K6. Yeni düşmanlar kataloğun başına eklendi → **DOKUNULMADI**
- `border_scout` (500), `forest_raider` (1000), `blood_apprentice` (1500).
  Testler `enemies[0]` yerine `byId(...)` kullanacak şekilde güncellenmiş;
  sıraya bağlı kod kalmamış.

### K7. Açılış sesi için elle yazılmış platform kanalı → ✅ **sızıntı kapatıldı**
- **Dosya:** `MainActivity.kt`
- Kanalın kendisine dokunulmadı (paket getirmek daha büyük bir karar).
  Düzeltilen: `prepare()` ya da `setDataSource()` fırlatırsa `MediaPlayer`
  release edilmiyordu ve `AssetFileDescriptor` kapatılmıyordu. Artık
  `try/catch` + `use {}` ile her yolda kapanıyor.
- ⚠️ iOS tarafı (`AppDelegate.swift`) Windows'ta **derlenemedi**.

### K8. `_stepHistory` sınırsız büyüyordu → ✅ **sınır kondu**
- `GameConstants.maxStepHistoryDays = 400`. Ayrıntı: **GD5**.

### K9. Ekipman ızgarası sabit yükseklikten esnek satıra çevrildi → **DOKUNULMADI, iyileştirme**
- **Commit:** `04a3687 estetik` (2026-08-20, Berkay)
- **Dosya:** `lib/features/store/xp_store_screen.dart`
- **Ne yapıldı:** `SliverGrid` + `mainAxisExtent: 302` yerine
  `SliverList.builder` + iki hücreli `Row` + `CrossAxisAlignment.start`.
  Satır yüksekliğini artık kart içeriği belirliyor.
- **Neden dokunulmadı:** GD12'nin çözdüğü sorunu (dar ekranda satın alma
  düğmesinin kartın dışında kalması) **daha iyi** çözüyor: az bonuslu itemler
  artık en uzun item için ayrılmış boşluğu taşımıyor ve `SliverList.builder`
  hâlâ tembel. `store_screen_test.dart` içindeki altı genişlikte taşma testleri
  değişmeden geçiyor.
- **GD12 artık geçersiz:** `_equipmentCardHeight` sabiti kaldırıldı. Bu, Aşama
  3f'te buff satır sayısını 3'ün üstüne çıkarmayı da mümkün kıldı (koşullu
  etkiler iki satıra sarabiliyor, lore cümlesi üç satır).

# GERİ DÖNÜLECEK KARARLAR

Gözetimsiz oturumlarda tek başıma verdiğim, ileride tartışmaya açık kararlar.

### GD1. Açılışta kayıt okunamazsa oyun temiz varsayılanla açılır (2026-08-19)
- **Nerede:** `lib/app.dart:_initializeApp`
- **Karar:** `CharacterStorage.load()` / `GameStorage.load()` fırlatırsa hata
  yutulmuyor ama açılış da durmuyor: `avatar = null`, `gameState = null` ile
  devam edilir ve kullanıcıya bir SnackBar ile "kayıtlı ilerlemene şu an
  ulaşılamadı" denir.
- **Neden:** eskiden herhangi bir platform kanalı hatası `_isLoading`'i sonsuza
  kadar `true` bırakıyordu — kullanıcı açılış görselinde asılı kalıyor, ne hata
  görüyor ne çıkış yolu buluyordu.
- **Riski ve neden kabul edildi:** temiz varsayılanla açılmak, oyuncuya
  "ilerlemem silinmiş" hissi verebilir. Bu yüzden **kayıt silinmiyor ve
  üzerine hemen yazılmıyor kararı verilmedi** — `RootShell` normal akışında
  `_persist()` çağırdığı anda eski kayıt üzerine yazılır. Kalıcı bir okuma
  hatası (bozuk değil, erişilemez kayıt) senaryosunda bu veri kaybı demektir.
- **Geri dönülecek nokta:** Aşama 6 (Firebase) geldiğinde sunucu kaydı ikinci
  bir kaynak olur. O zamana kadar daha güvenli davranış: `_storageFailed`
  iken `GameStorage` yazmayı tamamen kilitlemek (salt-okunur oturum). Şimdi
  yapılmadı çünkü `RootShell`'in yazma yolunu tek bayrakla kilitlemek onun
  akışına dokunmayı gerektiriyor ve bu birimin kapsamı dışıydı.

### GD2. Bildirim planlaması `GameClock`'a bağlandı (2026-08-19)
- **Nerede:** `lib/services/adventure_notification_service.dart`
- **Karar:** `countdownRemaining(DateTime.now())` → `countdownRemaining(GameClock.now())`.
- **Neden:** `nextEnemyAttackAt` `GameClock` ile yazılıyor. İki farklı saat
  kaynağını karşılaştırmak, cihaz saati geriye alınmış (GameClock donmuş)
  durumda kalan süreyi olduğundan kısa gösteriyor ve hiç hatırlatma
  planlanmamasına yol açıyordu.
- **Açık kalan:** `tz.setLocalLocation(tz.UTC)` hâlâ sabit (triaj C3).

### GD3. Round sistemine dokunulmadı (2026-08-19)
- İncelendi, gerçek bir hata bulunmadı: `_onStepsReported` tek round çözüyor
  ama saniyelik `_updateAdventureClock` → `resolveExpiredRounds` kalanları bir
  saniye içinde topluyor; düşman aynı partide ölürse `roundTargetSteps` zaten
  0'a düştüğü için çözülecek round kalmıyor. Kova A'ya terfi eden bir şey yok.

### GD4. Gün sınırı 04:00'e geri alındı, adım halkası da onu kullanıyor (2026-08-19)
- **Nerede:** `lib/core/utils/game_day.dart`, `lib/core/utils/step_history.dart`
- **Karar:** `dayStartHour = 4`. Adım halkası arşivi de takvim gününü değil
  **oyun gününü** anahtarlıyor (`GameDay.startOf(progress.date)`).
- **Neden anahtarlama değişti:** arşivleme, `DailyProgress.date`'in **ham**
  değerini kullanıyordu. Gün sınırı gece yarısı olmadığında bu değer
  sınırdan sonra ama gece yarısından önce açılmış bir gün için **bir sonraki
  takvim gününü** gösterir; halka yanlış güne düşerdi. 00:00 sınırında bu
  gizli kalıyordu, 04:00'e dönünce açığa çıkardı.
- **Kabul edilen takas:** 02:00'de atılan adım önceki günün halkasında
  görünür. Apple Health / Google Fit gece yarısında keser; biz kesmiyoruz.
  Gerekçe: halka, günlük **hedefe** göre ölçülüyor ve hedef 04:00'te
  sıfırlanıyor — halkanın penceresi ölçtüğü şeyle aynı olmalı.
- **Geri dönülecek nokta:** kullanıcı geri bildirimi "gece yürüyüşüm yanlış
  güne yazılıyor" derse, halkaya ayrı bir takvim-günü sınırı verilebilir.
  Bu, `GameDay`'e ikinci bir gün kavramı eklemek demek; bugün gereksiz
  karmaşıklık.

### GD5. Adım halkası geçmişi 400 günle sınırlandı (2026-08-19)
- **Nerede:** `GameConstants.maxStepHistoryDays`, `core/utils/step_history.dart`
- **Karar:** en yeni 400 gün tutulur, daha eskiler **kalıcı olarak düşer**.
  Sınır hem arşivlemede hem diskten okumada uygulanır (sınır konmadan önce
  yazılmış kayıtlar da kırpılır).
- **Neden 400:** takvim ekranında bir yıl geriye rahatça gitmeye yeter (~13
  ay) ve ~40 KB'ın altında kalır. Geçmiş tek bir SharedPreferences anahtarında
  duruyor; sınırsız liste hem her açılış okumasını hem **her yazmayı**
  (2 saniyede bir) yavaşlatır.
- **Riski:** veri kaybı geri alınamaz. Bugün kabul edildi çünkü tüketicisi
  yalnızca takvim ekranı. Aşama 6'da Firestore geldiğinde geçmişin tamamı
  sunucuda tutulabilir; yerel liste "cache" rolüne düşer ve sınır sorun olmaz.

### GD6. `_archiveDailySteps` saf bir fonksiyona taşındı (2026-08-19)
- **Nerede:** `lib/core/utils/step_history.dart` (`archiveStepDay`,
  `pruneStepHistory`)
- **Karar:** mantık `RootShell`'in private metodundan çıkarıldı; `RootShell`
  artık yalnızca çağırıyor. Davranış birebir aynı.
- **Neden:** `StatefulWidget` içindeki private metot test edilemiyordu ve bu
  kod (gün anahtarlama + sınır) sessizce yanlış veri üretebilecek türden.
  Proje zaten bu deseni kullanıyor: `calculateStepCoins`, `calculateStepXp`,
  `limitStepBatch` hepsi `core/utils/` altında saf fonksiyon.
- **Not:** bu, arkadaşımın kodunda yaptığım **tek** yapısal değişiklik.
  İsimlendirme, model ve ekran akışı olduğu gibi bırakıldı.

### GD7. 784 item'ın tamamı katalogda; ad ve nadirlik elle tanımlandı (2026-08-19)
- **Nerede:** `lib/data/item_definitions.dart` (166 satır), `core/utils/item_rules.dart`
- **Karar:** Türkçe ad ve nadirlik **elle** yazıldı; seviye kilidi, fiyat ve
  buff bunlardan **türetiliyor**.
- **Neden elle ad:** dosya adını kelime kelime çevirmek Türkçede bozuk sonuç
  veriyor ("Ateş Kılıç"). 166 satırlık tablo, 784 item'ın hepsini düzgün Türkçe
  yapıyor — kullanıcıya görünen metnin Türkçe olması CLAUDE.md kuralı.
- **Neden türetilmiş seviye/fiyat:** 784 item'a elle seviye ve fiyat vermek hem
  tutarsız olurdu hem bakımı imkânsız. Nadirlik tek karar noktası.
- **Geri dönülecek nokta:** bant değerleri (`_levelBand`, `_costBase`,
  `_buffTotal`) tek yerde; denge değişecekse yalnızca orası düzenlenir.

### GD8. Seviye kilidi kararlı bir dağılımdan çıkıyor, `String.hashCode`'dan değil (2026-08-19)
- **Nerede:** `item_rules.dart:stableSpread`
- **Karar:** aynı nadirlikteki itemleri bir seviye bandına yaymak için kimlikten
  hesaplanan kendi kararlı fonksiyonumuz kullanılıyor.
- **Neden:** `String.hashCode` Dart sürümleri ve platformlar arasında **sabit
  değil**. Seviye kilidi ondan çıksaydı, bir güncelleme sonrası oyuncunun sahip
  olduğu item "seviyen yetmiyor" diyebilirdi. `ownedItemIds` kalıcı olduğu için
  bu sessiz bir veri hatası olurdu.

### GD9. Item buff'ı bugün yalnızca adım kazancını büyütüyor (2026-08-19)
- **Nerede:** `models/item.dart:ItemBuff`, `item_rules.dart:buffFor`
- **Karar:** `stepCoinBonus` ve `stepXpBonus` — başka stat yok. Dağılım role
  göre: yakın dövüş → XP, menzil ve savunma → para, büyü → yarı yarıya.
- **Neden:** Aşama 1b ve 2b bu iki noktaya (`calculateStepCoins`,
  `calculateStepXp`) zaten birer `TODO(items)` çarpan kancası bıraktı. Savaş
  istatistikleri (can, saldırı, savunma) Aşama 4a'da tanımlanacak; onlar
  netleşmeden buff'a savaş alanı eklemek, iki kez yazmak olurdu.
- **Bilinçli tuhaflık:** **kalkanlar para veriyor.** Doğru cevap savunma
  istatistiği; o istatistik henüz yok. Aşama 4a'da düzeltilecek.
- **Açık:** buff hiçbir yere **uygulanmıyor** — kuşanma (equip) kavramı yok.
  Bu #9'un işi.

### GD10. `XpStoreScreen` adı korundu, yalnızca başlık değişti (2026-08-19)
- Para birimi coin olduğu hâlde sınıf/dosya adı "Xp" ile başlıyor. Yeniden
  adlandırmak `root_shell` dahil çağrı noktalarını gezmek demek ve CLAUDE.md
  zaten benzer bir yazım borcunu ("Villians") bilerek bırakıyor. Kullanıcıya
  görünen başlık "Mağaza" oldu; kod adı olduğu gibi kaldı.

### GD11. Mağaza artık itilmiyor, sekmeye geçiliyor (2026-08-20)
- **Nerede:** `lib/features/root/root_shell.dart:_openStore`
- **Karar:** Ana ekrandaki "Mağaza" hızlı erişimi `_push(XpStoreScreen(...))`
  yerine `setState(() => _tabIndex = 2)` yapıyor. `_openAdventure` zaten aynı
  deseni kullanıyordu.
- **Neden:** `_push` **önceden inşa edilmiş** bir widget örneğini
  `MaterialPageRoute`'a veriyor. İtilen rota kök Navigator'ın overlay'inde
  duruyor, yani `RootShell`'in alt ağacında **değil** — `setState` onu
  tazelemiyor. Gerçek `RootShell` üzerinde ölçüldü: 99999 coin ile 850
  coinlik ekipman alındığında profildeki para 99149'a düşüyor ama ekranda
  hâlâ 99999 yazıyor, kart "Sahipsin" demiyor, seviye atlayınca kilitler
  açılmıyor ve aynı düğmeye ikinci dokunuş sessizce düşüyor (Model Kuralları
  #4 ihlali). Sekme gövdesi her `setState`'te yeniden kurulduğu için mağazanın
  sekme sürümünde bu sorun hiç yoktu.
- **Kabul edilen takas:** mağazadan geri düğmesiyle ana ekrana dönülmüyor;
  alt gezinme çubuğu kullanılıyor. Macera sekmesi zaten böyle çalışıyor.
- **Geri dönülecek nokta:** aynı tuzak `_openWheel`, `_openRewards` ve
  `_editCharacter` için de var. Üçü de **bugün güvenli**, çünkü ya kendi
  iç durumlarını tutuyorlar (çark) ya da salt-okunur bir anlık görüntü
  gösteriyorlar. `RootShell` durumunu canlı yansıtması gereken **yeni** bir
  ekran eklenirse ya sekmeye alınmalı ya da state bir `Listenable`'a
  taşınmalı. Riverpod/Bloc geçişinde bu tuzak kendiliğinden kapanır.

### GD12. Ekipman kartı sabit yükseklikte (2026-08-20)
- **Nerede:** `lib/features/store/xp_store_screen.dart` —
  `_equipmentCardHeight`, `_EquipmentCard`
- **Karar:** `childAspectRatio: 0.72` yerine `mainAxisExtent: 280`. Seviye
  etiketi ("Sv. N") nadirlik rozetinin yanından alınıp görselin üstüne,
  kilit ikonunun yanına taşındı. Buff satırı 2 satırdan 1 satıra indi.
- **Neden:** en-boy oranı, hücre yüksekliğini ekran genişliğinden türetiyordu
  ve dar ekranda kartı kısaltıyordu. Ölçülen dikey taşma: 320 dp'de 67 px,
  360 dp'de (en yaygın Android) 40 px, 390 dp'de 19 px, 412 dp'de 3,4 px.
  Taşan kısım Column'un son çocuğu, yani **satın alma düğmesi** — yaygın
  telefonlarda ekipman satın almak fiilen imkânsızdı. Ayrıca rozet + "Sv. N"
  satırı 480 dp'de bile yatay taşıyor ve kilidin nedenini gösteren tek görsel
  bilgiyi kırpıyordu.
- **Neden `Expanded` değil:** `SectionCard`'ın kendi `Column`'u alt Column'a
  sınırsız yükseklik veriyor; esnek çocuk kullanmak paylaşılan `SectionCard`
  widget'ını değiştirmeyi gerektirirdi (Kural 1/3).
- **Neden 280:** 320 dp'de, katalogdaki **en uzun Türkçe adlarla** ölçülüp
  ~18 px pay bırakıldı. Değer değişecekse `store_screen_test.dart` içindeki
  "dar ekran düzeni" grubu altı genişlikte taşma olmadığını doğruluyor.

### GD13. Para alıp hiçbir şey yapmayan iki yükseltme tüketilir hâle geldi (2026-08-20)
- **Nerede:** `models/user_profile.dart` (`extraWheelSpins`, `xpBoostUntil`),
  `features/root/root_shell.dart` (`_purchase`, `_awardXp`, `_spinWheel`),
  `features/wheel/daily_wheel_screen.dart`, `data/mock_data.dart`
- **Sorun:** `ownedItemIds`'i okuyan tek kod "Sahipsin" etiketiydi.
  `boost_double_xp` (800 coin) ve `wheel_extra_spin` (300 coin) satın
  alınıyor, para gidiyor, hiçbir yerde tüketilmiyordu. Üstelik
  `boost_double_xp` `repeatable: false` olduğu için bir kez alınınca kalıcı
  "Sahipsin" oluyor ve "1 gün" vaadi anlamsız kalıyordu.
- **Karar:** ikisi de `repeatable: true` oldu ve gerçek tüketim aldı:
  - **Ekstra çark hakkı:** `UserProfile.grantExtraWheelSpin()` /
    `consumeWheelSpin()`. Stok `GameConstants.maxExtraWheelSpins` = 2.
    Dondurma hakkıyla **birebir aynı sözleşme**: stok doluysa 0 döner,
    satış yapılmaz, para harcanmaz, nedeni söylenir.
  - **2x XP:** `activateXpBoost()` süreyi
    `GameDay.nextResetAfter(now)`'a kadar açar — ayrı bir gün/saat hesabı
    yok (Model Kuralları #3). Zaten etkinse satış yapılmaz.
- **Çarpan neden `_awardXp` içinde:** yükseltmenin sözü "kazandığın XP",
  yani adım + düşman + çark. `_awardXp` XP veren **tek** nokta (Aşama 2b);
  çarpanı `calculateStepXp`'in `multiplier` kancasına koymak yalnızca adım
  XP'sini büyütürdü. `_awardXp` artık **gerçekten verilen** XP'yi döndürüyor,
  böylece ana ekrandaki "adımdan kazandığın XP" satırı da doğru kalıyor.
- **Kalan:** `skin_dragon_cape` ve `title_villain_hunter` hâlâ hiçbir yerde
  gösterilmiyor. Bunlar kod değil **sanat/ekran** işi (pelerin görseli,
  profilde unvan satırı); mağazadaki tüketim hatası kapsamında değil.
- **Şema v9.** 8 → 9 taşıması içerik değiştirmiyor (varsayılanlar 0 / null
  doğru); sürüm yine de artırıldı. `fromJson` stoğu savunma amaçlı kırpıyor.

### GD20. Fiyat eğrisi "katman başına 2 item" varsayımına kalibre (2026-08-20)
- **Nerede:** `test/economy_pacing_test.dart`, `item_rules.dart:_costBase`
- **Karar:** ölçümün açık varsayımı **katman başına 2 item**. Her sınıf 3–5
  kategori görüyor (GD15) ve gerçekçi bir oyuncu katman başına bunların
  ikisinde yükseltme yapıyor.
- **Neden bu varsayım kritik:** tek item varsayımıyla ölçülürse para seviyeden
  **iki kat önce** birikiyor görünür (nadir 0,46 · epik 0,48 · efsanevi 0,60);
  üç item varsayımıyla tersi çıkar (1,38 · 1,43 · 1,81). Kesişim tam ikide
  (0,92 · 0,96 · 1,20). CLAUDE.md §4.1'in "nadir ve üstünde fiyat kapı olmaktan
  çıkıyor, ~2× sapma var" okuması **tek item varsayımının artefaktıydı** —
  notun kendisi bu tuzağı uyarmıştı.
- **Oran bandı [0,5 – 1,8]:** altında para hiç kısıt olmaz (fiyat dekoratif),
  üstünde seviye hiç kısıt olmaz (kilit dekoratif). 2× sapmayı yakalayacak
  kadar dar, gürültüye takılmayacak kadar geniş.
- **Sıradan katman ölçümün dışında.** Seviye bandı 1–3, yani seviye kapısı
  birkaç saatte geçiliyor; oran orada anlamsız (payda sıfıra yakın). O katmanın
  ölçütü **mutlak**: günlük hedefini tutturan oyuncu ilk akşam bir item
  alabilmeli.

### GD21. Sıradan item fiyat tabanı 120 → 100 (2026-08-20)
- **Nerede:** `item_rules.dart:_costBase(common)`
- **Sorun:** 120 tabanı en ucuz sıradan item'ı **125 coin**'e çıkarıyordu.
  6.000 adımlık günlük hedefi tutturan oyuncu **120 coin** kazanıyor — beş
  coin farkla ikinci güne sarkıyordu. Mağazanın ilk gün ölü görünmesinin tek
  sebebi buydu.
- **Karar:** taban 100. En ucuz item artık 100 coin; hedefini tutturan oyuncu
  ilk akşam alışverişini yapıyor.
- **Neden fiyat, XP değil:** düzeltmenin fiyat eğrisine yazılacağı §4.1'de
  önceden kararlaştırılmıştı. XP eğrisi Aşama 2b'de ayrıca gerekçelendirildi
  ve `step_xp_test.dart` ile bağlı (15/9 günlük ulaşma süreleri testli).
- **Neden 100'ün altına inilmedi:** `economy_pacing_test.dart` en ucuz item'ın
  günlük kazancın yarısından ucuz olmamasını da bağlıyor; bedava sayılan bir
  giriş item'ı ekonominin ilk basamağını yok ederdi.
- **Diğer dört katmana dokunulmadı:** ölçüm hepsini bandın içinde buldu.

### GD18. Çark tohumlu ve saklanan bir rastgelelikle çalışıyor (2026-08-20)
- **Nerede:** `core/utils/wheel_rewards.dart`, `UserProfile.wheelSeed`
- **Karar:** çarkın hem dilim havuzu hem kazanan dilimi tek bir tohumdan
  çıkıyor. Tohum `UserProfile.wheelSeed` olarak **diske yazılıyor** ve her
  çevirmeden sonra bir adım ilerletiliyor.
- **Neden:** CLAUDE.md §4.4 — kalıcı oyun sonucunu (XP, item) etkileyen
  rastgelelik tohumlu olmalı ve tohum durumla birlikte saklanmalı. Çark
  eskiden `Random()` çağırıyordu; sonuç kalıcı bir ödüle dönüştüğü için bu
  kuralın tam kapsamındaydı. Aşama 6b'de aynı mantık sunucuda çalışacak.
- **Başlangıç tohumu oyuncuya özel:** `initialWheelSeed('<ad>|<sınıf>')`,
  `stableSpread` üzerinden. `String.hashCode` **kullanılmadı** (GD8) — sürümler
  arası sabit değil, bir güncelleme sonrası çark sıralaması değişirdi.
  `0` "henüz kurulmadı" anlamında; çark ilk açıldığında dolduruluyor.
- **Ekran ve state aynı adımı ayrı ayrı uyguluyor:** çark ekranı itilen bir
  rotada duruyor ve `RootShell` `setState`'i onu tazelemiyor (bkz. GD11), bu
  yüzden ikinci çevirmenin yeni dilimleri ekranın kendi kopyasından geliyor.
  İki taraf da `nextWheelSeed` kullandığı için aynı yerde kalıyorlar.

### GD19. Çarkta epik ve efsanevi yok, en fazla üç item dilimi var (2026-08-20)
- **Nerede:** `wheel_rewards.dart:maxWheelRarity` / `maxItemSlices`
- **Karar:** çark yalnızca **nadir ve altı** item verir; sekiz dilimin en fazla
  üçü item olur, kalanı XP.
- **Neden:** epik ~üç haftalık, efsanevi ~iki aylık birikim (bkz. Aşama 3
  denge tablosu). Günde bir dönen bir çarktan düşmeleri hem mağazayı hem
  seviye kilidini anlamsız kılardı. Item dilimlerini azınlıkta tutmak da aynı
  gerekçe: çark bir bonus, ekipmanın ana kaynağı değil.
- **Süzgeçler:** seviye kilidi **tek kaynaktan** — `Item.isUnlockedAt` (#10),
  ikinci bir kontrol yazılmadı. Sahip olunanlar eleniyor (sahip olduğun şeyin
  çıkması ödül değil). Sınıf süzgeci çağıran tarafta
  (`ItemCatalog.forCharacterClass`), sözleşme testle bağlandı.
- **Boş dilim yok:** uygun item bulunamazsa (seviye düşük, hepsi alınmış,
  katalog okunamadı) sekiz dilimin tamamı XP olur.

### GD15. Sınıf ↔ kategori dağılımı dengelendi (2026-08-20)
- **Nerede:** `lib/models/item.dart:ItemCategoryX.characterClasses`
- **Sorun:** Magic **tek** kategori (yalnızca Büyü) görüyordu; mağazanın
  kategori süzgeci o sınıfta "Tümü + Büyü"ye düşüp fiilen işlevsiz kalıyordu.
  Archer ve DarkMagic ikide kalmıştı. Item sayısı 140–341 arasında saçılıyordu.
- **Karar:** her sınıfa **en az üç kategori**. Eklenenler tematik:
  cirit → Archer, tırpan (hasat aleti) → Nature, arbalet → Thief,
  fırlatma silahları → Magic/DarkMagic, topuz → SwordMan.
- **Sonuç:** 200–394 item, 3–5 kategori.

| Sınıf | Item | Kategori | İmza bonusu |
|---|---|---|---|
| SwordMan | 394 | 4 | düşman XP |
| Faith | 341 | 3 | seri eşiği indirimi |
| Thief | 338 | 5 | günlük coin sınırı |
| Nature | 331 | 4 | çark hakkı stoğu |
| Paladin | 274 | 4 | dondurma stoğu |
| DarkMagic | 246 | 4 | çark XP |
| Magic | 231 | 3 | adım XP |
| Archer | 200 | 3 | adım parası |

- **Neden sınıf kısıtı büsbütün kaldırılmadı:** herkes 784'ü görürse sınıf
  seçiminin oyun içi bir karşılığı kalmaz. Test iki yönü de bağlıyor: her sınıf
  ≥3 kategori **ve** ≥150 item görmeli, ama hiçbiri kataloğun %60'ından
  fazlasını görmemeli.

### GD16. Aynı görsel sınıfa göre farklı item (2026-08-20)
- **Nerede:** `item_rules.dart:flavorForClass` / `classEpithet`,
  `services/item_catalog.dart:forCharacterClass`
- **Karar:** paylaşılan bir kategorideki item, oyuncunun sınıfına göre **farklı
  ad** ve **farklı buff** alır. Ad, sınıf lakabıyla önden genişler
  ("Kadim Büyü Kitabı" → Büyücüde *Esrarlı* Kadim Büyü Kitabı, Kara Büyücüde
  *Lanetli* Kadim Büyü Kitabı). Tek sınıfa özel kategorilerde ad değişmez.
- **Neden sıfat, tamlama değil:** "Şövalyenin Hançer" bozuk Türkçe; iyelik eki
  ada göre değişiyor ve 166 tanımın hepsini elle çekimlemek gerekirdi. Sıfat
  her ada eksiz takılır.
- **KRİTİK — kimlik değişmez.** `Item.id` sınıftan bağımsız kalır. Kimliğe
  sınıf gömseydik, oyuncu karakter düzenleme ekranından sınıf değiştirdiğinde
  `ownedItemIds` içindeki kimlikler katalogda karşılık bulamaz ve **envanter
  sessizce boşalırdı**. Şimdi sınıf değişince aynı item yeni adını ve yeni
  buff'ını alır, sahiplik korunur. Testle bağlandı.

### GD17. Buff sistemi: sekiz tür, nadirliğe göre 1–3 bonus (2026-08-20)
- **Nerede:** `models/item.dart:ItemBuffType` / `ItemBuff`,
  `item_rules.dart:buffFor` / `buffCountFor` / `buffTypeOrder`
- **Karar:** iki alanlık buff (`stepCoinBonus`, `stepXpBonus`) **sekiz türe**
  çıktı ve nadirlik hem miktarı hem **sayıyı** büyütüyor:
  sıradan 1, az bulunur 2, nadir 2, epik 3, efsanevi 3 bonus.
  Bütçe paylaşımı 1→[%100], 2→[%60,%40], 3→[%50,%30,%20].
- **Sekiz tür ve uygulama noktaları** — hepsi **bugün var olan** bir yere
  bağlanabilir; savaş istatistiği (can/saldırı/savunma) bilerek yok, o statlar
  Aşama 4a'nın konusu (GD9 hâlâ geçerli):

| Tür | Etki | Uygulama noktası |
|---|---|---|
| `stepCoin` | adım parası +%X | `calculateStepCoins` çarpanı |
| `stepXp` | adım XP +%X | `calculateStepXp` çarpanı |
| `wheelXp` | çark XP +%X | `_spinWheel` → `_awardXp` |
| `enemyXp` | düşman XP +%X | `_onStepsReported` düşman yenilme dalı |
| `dailyCoinCap` | günlük coin sınırı +N | `GameConstants.maxDailyStepCoins` |
| `streakFreezeCap` | dondurma stoğu +N | `GameConstants.maxStreakFreezes` |
| `wheelSpinCap` | çark hakkı stoğu +N | `GameConstants.maxExtraWheelSpins` |
| `streakRelief` | seri eşiği −N adım | `GameConstants.streakStepThreshold` |

- **Sıralama nasıl belirleniyor:** birincil bonus her zaman **sınıfın imzası**
  (yukarıdaki tablo), ardından kategori rolünün eğilimi, sonra kalanlar. Kuyruk
  `stableSpread(id, ...)` ile döndürülüyor ki aynı sınıf+kategorideki yüzlerce
  item aynı ikincil bonusa yapışmasın. Döndürme kimlikten çıktığı için
  **kararlı** (GD8): aynı item her açılışta aynı bonusları verir.
- **Çark ve düşman XP'si iki katı çarpanla ölçekleniyor:** nadir olaylar,
  aynı bütçe payı orada daha az hissedilir.
- **Sayısal bonuslar sıfıra düşmez** (`_atLeastOne` / `_roundTo`): etiketi
  görünüp etkisi olmayan bonus olmamalı. Beş nadirlik × sekiz sınıf × on
  kategori kombinasyonunun tamamı testle taranıyor.
- **GD9'un tuhaflığı kapandı:** kalkanlar artık menzille aynı eğilimde değil;
  savunma rolü kendi eğilimini (seri koruma, eşik indirimi) aldı. Savaş
  istatistiği hâlâ yok; verilen şey "dayanıklılığın oyun dışı karşılığı".
- **Neden üçte duruldu:** mağaza kartı sabit yükseklikte (GD12) ve dört satır
  bonus okunmaz hâle geliyor. Kart 280 → **302** px'e çıkarıldı ve altı ekran
  genişliğinde yeniden ölçüldü.
- **HÂLÂ AÇIK:** buff'lar **hiçbir yere uygulanmıyor** — kuşanma (equip)
  kavramı yok (#9). Bu birim buff'ları modelledi ve gösterdi; uygulama Aşama
  4a'da envanter/kuşanma ile birlikte gelecek. Yukarıdaki tablo o işin
  yol haritası.

### GD22. İmzalı itemler sınıfa göre değişmez (2026-08-20)
- **Nerede:** `item_rules.dart:flavorForClass` — `if (item.hasSignature) return item;`
- **Karar:** elle tasarlanmış (lore taşıyan) itemler sınıf lakabı almaz ve
  buff'ları yeniden türetilmez. "Azrailin Tırpanı" her sınıfta Azrailin
  Tırpanı'dır.
- **Neden:** GD16'nın amacı paylaşılan bir görseli sınıfa göre farklı bir item
  yapmaktı — yani **karakteri olmayan** itemlere karakter vermek. İmzalı
  itemin zaten bir karakteri var; onu sınıfa göre yeniden yazmak o karakteri
  silerdi. Oyuncular arasında "şu itemi istiyorum" diyebilmenin şartı da bu:
  itemin ne yaptığı sınıfa göre değişmemeli.
- **Kimlik yine değişmiyor**, dolayısıyla GD16'nın envanter güvencesi
  bozulmuyor.

### GD23. Varyantlar numara değil sıfat alıyor, sıfat sınıfa göre kayıyor (2026-08-20)
- **Nerede:** `item_rules.dart:variantAdjectives` / `variantAdjective` /
  `decorateVariantName`
- **Karar:** "Hançer 4" → "Yıpranmış Hançer". 36 sıfatlık tek havuz; havuzdaki
  başlangıç noktası `stableSpread('<baseId>|<sınıf>')` ile kayıyor, yani aynı
  görsel Savaşçıda ve Hırsızda farklı sıfat alıyor.
- **Neden numara değil:** varyant numarası bir dosya indeksidir, ad değildir.
- **Neden sıfat yığmak yerine kaydırma:** sınıf lakabı + varyant sıfatı üst
  üste gelseydi "Çelik Paslı Hançer" gibi hem çelişkili hem üç kelimeli adlar
  çıkardı; mağaza kartında ad iki satırla sınırlı. Bu yüzden **ikisi birden
  hiçbir zaman uygulanmaz**: varyantlıysa sıfat, varyantsızsa lakap.
- **Neden 36:** en kalabalık temel item 28 varyant taşıyor
  (`magic/staff_type_1`); havuz onun üstünde olmalı ki indeksler ardışık
  ilerlerken aynı temel item'ın iki varyantı çakışmasın. Testle bağlı.
- **`String.hashCode` yine kullanılmadı** (GD8): ad kalıcı bir şeyin görünen
  yüzü, sürümler arası değişmemeli.

### GD24. Savaş statları cömert, oyun dışı statlar sıkı (2026-08-20)
- **Nerede:** `item_effects.dart` denge notu, `GameConstants.maxSingleItemEconomyBonus`
- **Karar:** saldırı/savunma/kritik/can çalma değerleri rahat verildi
  (+52 saldırı, +%60 savunma, %15 ihtimalle +%90 kritik hasarı); adım parası
  ve XP oranları item başına **%15** ile sınırlandı.
- **Neden asimetrik:** savaş motoru Aşama 4a'da yazılacak ve denge orada
  yapılacak — bugün o sayıların hiçbir etkisi yok, dolayısıyla cömert olmak
  bedava. Oyun dışı statlar ise **canlı** ve `economy_pacing_test.dart` ile
  ölçülmüş bir ekonomiye bağlı.
- **Kabul edilen takas:** imzalı itemlerin çoğu ağırlıkla savaş statı veriyor,
  yani bugün bir epik silah bir nadirden daha az *görünür* fayda sağlayabilir.
  Bu bilinçli; ama **her efsanevinin en az bir canlı etkisi olması** şart
  koşuldu ve testle bağlandı, çünkü en üst katmanın bugün de bir karşılığı
  olmalı.
- **Geri dönülecek nokta:** Aşama 4a'da savaş statları canlanınca imzalı
  itemler kendiliğinden güçlenecek; o noktada oyun dışı oranların
  düşürülmesi gerekebilir. Tek yer: `_buffTotal` ve `item_effects.dart`.

### GD25. Kuşanma tavanı toplama noktasında, item başına değil (2026-08-20)
- **Nerede:** `core/utils/equipped_buffs.dart:_cap`
- **Karar:** "+%50" sınırı tek tek itemlerde değil, `EquippedBuffs.from`
  içinde sert kırpma olarak uygulanıyor.
- **Neden:** item başına %15 bir **tasarım disiplini** — insan hatasıyla
  aşılabilir. Toplama noktasındaki kırpma bir **garanti**: 784 item'ın tasarımı
  ne olursa olsun, ne kadar slot açılırsa açılsın toplam çarpan sabit bir
  sınırın altında kalır. İkisi birlikte tutuluyor; ilki testle taranıyor,
  ikincisi kodla zorlanıyor.
- **Ölçüm:** gerçek katalogla en kötü kuşanmada en yüksek tek oran **+%29**,
  yani kırpma bugün hiç devreye girmiyor. Kırpma sigortadır, tasarım aracı
  değil.

### GD26. Slot = item kategorisi (2026-08-20)
- **Nerede:** `UserProfile.equippedItemIds` (`Map<String, String>`),
  `RootShell._equipItem`
- **Karar:** kuşanma slotu için yeni bir kavram uydurulmadı; `ItemCategory`
  doğrudan slot anahtarı oldu (`ItemCategory.folder`).
- **Neden:** kategori zaten mağaza süzgeci olarak kullanılıyor, sınıf başına
  3–5 tanesi açık (GD15) ve her sınıfa makul sayıda slot düşüyor. Ayrı bir
  `EquipmentSlot` enum'u aynı bilgiyi ikinci kez modellemek olurdu ve
  kategoriyle eşlemesini elle bakmak gerekirdi.
- **Neden `Map`, `List` değil:** "slot başına tek item" kuralı böylece
  **veri düzeyinde** zorlanıyor; aynı anahtara ikinci kimlik yazılamıyor.
  Liste olsaydı kural her yazma noktasında elle kontrol edilecekti.
- **Kabul edilen takas:** "iki yüzük" gibi aynı türden iki slot mümkün değil.
  Bugün öyle bir kategori yok; gerekirse anahtar biçimi
  `<kategori>#<indeks>`'e genişletilebilir, şema taşımayla.

### GD27. Envanter itilen rotada ama canlı: `_revision` sayacı (2026-08-20)
- **Nerede:** `RootShell._revision` (`ValueNotifier<int>`),
  `InventoryScreen.revision` + `readState`
- **Karar:** envanter ekranı veri **tutmuyor**; her çizimde `readState()` ile
  `RootShell`'den yeniden okuyor ve `_persist()` içinde artırılan bir sayacı
  `ValueListenableBuilder` ile dinliyor.
- **Neden:** GD11'in tuzağı — itilen rota `RootShell`'in alt ağacında değil,
  `setState` onu tazelemiyor. Mağazada bu tuzak sekmeye geçilerek çözülmüştü;
  envanter için altıncı bir sekme açmak alt gezinme çubuğunu sıkıştırırdı.
- **Neden veri kopyalanmadı:** çark ekranı kendi kopyasını tutuyor (GD18) ve
  bu, iki tarafın aynı adımı ayrı ayrı uygulamasını gerektiriyor. Envanterde
  para, seviye ve kuşanma aynı anda değişebiliyor; kopya tutmak kaçınılmaz
  olarak tutarsızlık üretirdi.
- **Yan fayda:** arka planda adım gelip para değiştiğinde envanter de
  güncelleniyor. Riverpod/Bloc geçişinde bu sayaç kendiliğinden düşer.

### GD28. Kuşanma temizliği sahipliğe dokunmaz (2026-08-20)
- **Nerede:** `RootShell._refreshEquipment`
- **Karar:** çözülemeyen bir kuşanma (katalogdan kalkmış, satılmış, sınıfın
  kullanamadığı, yanlış slota yazılmış) **yalnızca slotu boşaltır**;
  `ownedItemIds` hiç değişmez.
- **Neden:** GD16, kimliğe sınıf gömmeme kararını "envanter sessizce
  boşalmasın" diye vermişti. Temizlik sahipliği de silseydi aynı sorun bu kez
  sınıf değişiminde geri gelirdi; şimdi oyuncu sınıf değiştirip geri
  döndüğünde itemleri yerinde duruyor.
- **Sessiz değil:** slot boşalınca envanterdeki slot tahtası "Boş" gösteriyor
  ve karakter panelindeki "N / M slot dolu" satırı düşüyor.

### GD29. Satış fiyatın %40'ı ve geri alınamaz (2026-08-20)
- **Nerede:** `GameConstants.itemSellRatio`, `item_rules.dart:sellValueFor`
- **Karar:** %40, 5'in katına yuvarlı, en az 5 coin.
- **Neden tam iade değil:** itemleri bir "depo" hâline getirirdi — oyuncu her
  şeyi alır, beğenmediğini iade ederdi ve satın alma kararının ağırlığı
  kalmazdı. Alım-satım döngüsünün para üretmemesi testle bağlı.
- **Neden çok düşük değil:** yanlış alınan bir item kalıcı bir ceza olmamalı;
  %40 bir sonraki alışverişe anlamlı katkı yapıyor.
- **Onay şart:** satış geri alınamaz, bu yüzden diyalog hem geri gelecek
  parayı hem tekrar almanın maliyetini söylüyor.

### GD14. "Alabileceklerim" süzgeci sahip olunanları eliyor (2026-08-20)
- **Nerede:** `xp_store_screen.dart:_visibleEquipment`
- Süzgeç yalnızca seviye + paraya bakıyordu; zaten sahip olunan item de
  "alabileceklerim" listesinde çıkıyordu. Süzgecin sözü "bugün satın
  alabileceklerim" — alınamayacak bir şey orada olmamalı.

---
---

# OTURUM KAPANIŞI — 2026-08-19

> ⚠️ **ESKİ — güncel devam noktası dosyanın sonundaki 2026-08-25 kapanışıdır.**
> Bu bölüm tarihsel kayıt olarak duruyor.
>
> (Yazıldığı gün geçerliydi:) **Sonraki oturum buradan başlasın.** Bu bölüm, hiçbir şey sormadan devam
> edebilmek için gereken her şeyi taşıyor: ne yapıldı, hangi kararlar hangi
> gerekçeyle verildi, ne açık kaldı ve sıradaki iş neyle başlamalı.

## 1. Bu oturumda ne yapıldı

Oturum gözetimsiz çalıştı. Önce Faz 0 incelemesi (kod yazmadan), sonra üç birim.

| Birim | Ne | Test |
|---|---|---|
| **Aşama 2d** | Açılış dayanıklılığı — kayıt/bildirim hatası artık açılışı kilitlemiyor | 167 → 179 |
| **Aşama 2e** | Gün sınırı 04:00'e geri alındı, adım geçmişi oyun gününe bağlandı, 400 gün sınırı, MediaPlayer sızıntısı | 179 → 192 |
| **Aşama 3** | Item temeli: model + katalog + mağaza + seviye kilidi (#8, #10, #11) | 192 → **245** |

Kapanan kartlar: **#8**, **#10**, **#11**.
Kapanan triaj maddeleri: **A4** (mağaza para birimi), **C1** (dart format),
**C8** (784 PNG pubspec'te değildi).
Kapanan `TODO`: streak dondurma **kazanım** yolları (Aşama 2c'de bilerek
boş bırakılmıştı).

Oturum sonunda: `flutter analyze` temiz, `flutter test` **245/245 geçiyor**.

### Commit durumu — DİKKAT

- **Aşama 2d commit edildi** (`fix: harden app boot against storage and
  notification failures`).
- **Aşama 2e ve Aşama 3 commit EDİLMEDİ.** Çalışma ağacında duruyorlar.
  Kullanıcı "çok sık commit yapmayalım" dedi; commit'i kendisi atıyor
  (bkz. "Çalışma Kuralı — Commit").

Commit edilmemiş dosyalar:

```
M  CLAUDE.md
M  android/.../MainActivity.kt
M  lib/core/constants/game_constants.dart
M  lib/core/utils/game_day.dart
M  lib/data/mock_data.dart
M  lib/features/profile/profile_screen.dart
M  lib/features/profile/step_history_screen.dart
M  lib/features/rewards/rewards_screen.dart        (yalnızca dart format)
M  lib/features/root/root_shell.dart
M  lib/features/store/xp_store_screen.dart
M  lib/features/team/team_screen.dart              (yalnızca dart format)
M  lib/models/user_profile.dart
M  lib/models/xp_store_item.dart
M  pubspec.yaml
?? lib/core/utils/item_rules.dart
?? lib/core/utils/step_history.dart
?? lib/data/item_definitions.dart
?? lib/models/item.dart
?? lib/services/item_catalog.dart
?? test/item_catalog_test.dart
?? test/step_history_archive_test.dart
?? test/store_screen_test.dart
```

⚠️ **`pubspec.yaml` değişti** (10 item asset klasörü eklendi). Çalışan bir
`flutter run` varsa **yeniden başlatılmalı** — hot reload yeni asset'leri almaz.

## 2. Verilen kararlar

Hepsi "GERİ DÖNÜLECEK KARARLAR" bölümünde gerekçesiyle yazılı. Özet:

| # | Karar | Tek cümlelik gerekçe |
|---|---|---|
| GD1 | Açılışta kayıt okunamazsa temiz varsayılanla devam | Sonsuza kadar açılış ekranında asılı kalmaktansa açılmak yeğ; kayıt silinmiyor |
| GD2 | Bildirim planlaması `GameClock`'a bağlandı | İki farklı saat kaynağını karşılaştırmak, donmuş saatte hiç hatırlatma planlamıyordu |
| GD3 | Round sistemine dokunulmadı | İncelendi, gerçek hata yok |
| GD4 | Gün sınırı 04:00, adım halkası da onu kullanıyor | 00:00 sınırı çarkın gece yarısı açığını geri açıyordu |
| GD5 | Adım geçmişi 400 günle sınırlı | Tek anahtarda büyüyen liste her açılışı ve **her yazmayı** yavaşlatır |
| GD6 | `_archiveDailySteps` saf fonksiyona taşındı | Sessizce yanlış veri üretebilecek mantık test edilemiyordu |
| GD7 | 784 item'ın hepsi katalogda; ad+nadirlik elle | Sanat bedava (1,8 MB); kelime kelime çeviri Türkçede bozuk sonuç veriyor |
| GD8 | Seviye kilidi kararlı dağılımdan, `hashCode`'dan değil | `hashCode` sürümler arası sabit değil; sahip olunan item kilitlenebilirdi |
| GD9 | Buff bugün yalnızca adım kazancını büyütüyor | Savaş statları Aşama 4a'da tanımlanacak; şimdi uydurmak iki kez yazmak olur |
| GD10 | `XpStoreScreen` adı korundu, başlık "Mağaza" oldu | Yeniden adlandırma churn; CLAUDE.md benzer yazım borcunu bilerek bırakıyor |

## 3. Arkadaşımın kodu — bulgular

İncelenen: `e902185` (adventure rounds + step history) + `f28f510` (merge) +
`feec7db` (açılış ekranı ve sesi). Merge, önceki işi (Aşama 0–2c) **hiç
kaybetmemiş**; dosya dosya doğrulandı.

**Genel değerlendirme: kod sağlam.** Şema sürümü doğru artırılmış (v7 → v8) ve
migration eklenmiş; controller/timer/stream dispose'ları eksiksiz; mevcut
testler silinmemiş, birlikte güncellenmiş; `enemy_catalog` sıraya bağlı kod
bırakmamış (`byId` kullanılıyor).

**Bulunan gerçek hatalar (ikisi de düzeltildi):**
1. `app.dart:_initializeApp` — kayıt okuma ve bildirim init'inde hiç hata
   yönetimi yoktu; platform kanalı düşerse uygulama açılış görselinde
   **sonsuza kadar** asılı kalıyordu. (Bu kodun bir kısmı bize aitti; `feec7db`
   bildirim init'ini de bu yola taşıyıp hata yüzeyini büyütmüştü.)
2. `MainActivity.kt` — `prepare()` / `setDataSource()` fırlatırsa `MediaPlayer`
   release edilmiyor, `AssetFileDescriptor` kapanmıyordu.

**Ayrıntılı inceleme edilip hata bulunmayan yer:** yeni round sistemi
(`resolveRound`, erken kazanma, `resolveExpiredRounds`). Sonsuz döngü, çift
hasar ya da yanlış değer yok — `roundTargetSteps <= 0` koruması düşman ölünce
döngüyü durduruyor.

**Mimari farklılıklar:** "Arkadaşımın Kodu — inceleme ve kararlar" bölümünde
K1–K8 olarak madde madde duruyor. K1 (gün sınırı), K7 (ses sızıntısı) ve K8
(sınırsız geçmiş) düzeltildi; K2–K6 bilinçli olarak **dokunulmadı**.

**Bir sonraki oturuma not:** kullanıcı "arkadaşımla konuşacak bir şey yok, sen
karar ver" dedi. Yani K listesi artık bir bekleme listesi değil; K2–K6 için
verilen "dokunma" kararı nihai, tekrar açılmasına gerek yok.

## 4. AÇIK KALANLAR — öncelik sırası

### 4.1. Seviye ↔ fiyat hizalama kontrolü ✅ YAPILDI (2026-08-20)

> **Bu bölüm kapandı.** Ölçüm yapıldı, tek düzeltme uygulandı ve hesap
> `test/economy_pacing_test.dart` içine taşındı. Sonuç ve tablo için dosya
> sonundaki "Aşama 3e" bölümüne bak. Aşağıdaki metin ölçüm öncesine ait.

Aşama 3'te seviye kilidi ve fiyat **ayrı ayrı** türetildi; ikisinin aynı
ilerleme hızına oturup oturmadığı **hiç ölçülmedi**.

**Yapılacak ölçüm.** Beş nadirlik için iki sayı hesaplanmalı ve
karşılaştırılmalı:

- **Seviyeye ulaşma günü** — o nadirliğin seviye bandına varmak kaç gün sürer.
  `N. seviyeye toplam XP = 500 · N · (N−1)` (bkz. Aşama 2b), günlük XP =
  `günlük adım / stepsPerXp`.
- **Fiyatı biriktirme günü** — o nadirliğin fiyatını biriktirmek kaç gün sürer.
  Günlük coin = `günlük adım / stepsPerCoin`, günlük tavan
  `maxDailyStepCoins`.

Referans oyuncu: **6.000 adım/gün** → 3.000 XP/gün, 120 coin/gün.

**Kalem hesabı (DOĞRULANMADI — testle üretilmeli):**

| Nadirlik | Örnek seviye | Seviyeye ulaşma | Örnek fiyat | Fiyatı biriktirme | Sapma |
|---|---|---|---|---|---|
| Sıradan | 2 | ~0,3 gün | 125 | ~1,0 gün | fiyat bağlıyor |
| Az Bulunur | 5 | ~3,3 gün | 325 | ~2,7 gün | dengeli |
| Nadir | 10 | ~15 gün | 825 | ~6,9 gün | **seviye bağlıyor, ~2,2×** |
| Epik | 16 | ~40 gün | 2.550 | ~21 gün | **seviye bağlıyor, ~1,9×** |
| Efsanevi | 25 | ~100 gün | 8.100 | ~67 gün | **seviye bağlıyor, ~1,5×** |

**Okuma:** nadir ve üstünde parayı seviyeden **önce** biriktiriyorsun. Yani
fiyat fiilen bir kapı olmaktan çıkıyor, coin birikip duruyor ve ekonomi
anlamını yitiriyor.

**Karar kuralı — sapma büyükse FİYAT eğrisi düzeltilecek, XP eğrisine
DOKUNULMAYACAK.** Gerekçe: XP eğrisi (doğrusal artan seviye maliyeti) Aşama
2b'de ayrıca gerekçelendirildi ve `stepsPerXp` ile birlikte test edildi
(`step_xp_test.dart`, 15/9 günlük ulaşma süreleri testli). Fiyat ise tek bir
sabit tablodan çıkıyor: `item_rules.dart:_costBase`. Düzeltme oraya yazılır.

**Ölçmeden karar verilmemesi gereken çelinme:** yukarıdaki hesap **tek item**
alındığını varsayıyor. Oyuncu her katmanda birden çok item alıyorsa (81 nadir,
43 epik var) gerçek coin talebi kat kat yüksek ve mevcut fiyatlar göründüğünden
daha doğru olabilir. Ölçüm "katman başına kaç item alınıyor" varsayımını açıkça
yazmalı; aksi halde fiyatlar gereksiz yere şişirilir.

**Nereye yazılacak:** hesap bir teste dönüştürülmeli (ör.
`test/economy_pacing_test.dart`), prosa tahmini olarak bırakılmamalı — Aşama
2b'de 15/9 günlük süreler için yapılan şeyin aynısı.

### 4.2. #9 — Item buff'ları oyuna işlesin (Aşama 4a ile birlikte)

**Bugünkü durum:** `ItemBuff` üretiliyor ve mağaza kartında gösteriliyor ama
**hiçbir yere uygulanmıyor**. Kuşanma (equip) kavramı yok; `ownedItemIds`
yalnızca sahiplik tutuyor. `coin_calculator.dart` ve `xp_calculator.dart`
içindeki `TODO(items)` çarpan kancaları hâlâ boş.

**Karar verilmiş plan — Aşama 4a'da uygulanacak:**

Buff'lar **iki katmanlı** olacak:

1. **Kural türetmesi (çoğunluk).** 784 item'ın büyük kısmı bugünkü gibi
   nadirlik + kategori rolünden türetilen sayısal bonusu almaya devam eder
   (`buffFor`). Bunlar tahmin edilebilir ve bakımı bedava.
2. **Elle tasarlanmış özel buff'lar (küçük alt küme).** Yalnızca **18
   efsanevi + seçilmiş bazı epikler** elle yazılmış, karakteri olan etkiler
   alır: koşullu ("gece yürüyüşlerinde"), tetiklenen ("düşman öldürünce"),
   oyun dışı ("uygulama kapalıyken de sayar", "kaçırılan günü telafi eder")
   tipleri dahil.

**Gerekçe:** *her item özelse hiçbiri özel değil.* 784 el yapımı etki hem
bakımı imkânsız hem de efsanevileri sıradanlaştırır. Küçük bir alt kümeyi
gerçekten özel yapmak, geri kalanın sayısal olmasını da anlamlı kılar.

**Sıra:** kuşanma (equip) + envanter ekranı → çarpanın `coin_calculator` /
`xp_calculator` kancalarına bağlanması → özel buff tipleri. İlk ikisi
Aşama 4a'nın savaş statlarını beklemiyor; özel buff'lar bekliyor.

**Ayrıca düzeltilecek:** GD9'daki bilinçli tuhaflık — **kalkanlar şu an para
veriyor.** Savunma istatistiği tanımlanır tanımlanmaz kalkanlar oraya taşınmalı.

### 4.3. #16 — Çark item ödülü verebilsin ✅ YAPILDI (2026-08-20)

> **Bu bölüm kapandı.** Ayrıntı: dosya sonundaki "Aşama 3d" bölümü.
> Aşağıdaki metin iş öncesine ait.

Katalog hazır (`ItemCatalog.byId`, `unlockedAt`, `forCharacterClass`) ama çark
hâlâ yalnızca XP veriyor (`MockData.wheelXpOptions`, 6 sabit değer).

Yapılacak: çark ödül havuzuna item eklenmesi. Havuz oyuncunun **seviyesine ve
sınıfına** göre süzülmeli, yoksa 1. seviyede efsanevi çıkar ve hem seviye
kilidi hem ekonomi anlamını yitirir.

Not: `daily_wheel_screen.dart` içinde `TODO(#16)` olarak işaretli ikinci bir iş
daha var — çarkın iğnesinin doğru dilimde durması gerçek dilimli çark grafiği
gerektiriyor. İkisi aynı ekranda, birlikte yapılabilir.

### 4.4. Aşama 4 — Savaş sistemi (#4 + #9)

#### ⚠️ EN KRİTİK ŞART: SAVAŞ MOTORU DETERMİNİSTİK OLMALI

**Kural:** savaş sonucunu etkileyen hiçbir rastgelelik motorun **içinden**
gelmeyecek. `Random()` çağrısı savaş kodunda **yasak**. Tohum (seed) dışarıdan
enjekte edilecek ve **savaş durumuyla birlikte diske yazılacak**; aynı tohum +
aynı girdi her zaman aynı sonucu vermeli.

**Neden:** Aşama 6b'de (takım savaşları, #7) **aynı motor sunucuda çalışacak.**
İstemci ile sunucu aynı girdiden farklı sonuç üretirse ya hile kapısı açılır ya
da savaş sistemi ikinci kez, bu sefer sunucu için baştan yazılır. Deterministik
olmayan bir motoru sonradan deterministik yapmak, motoru yeniden yazmakla aynı
şey.

**İzlenecek desen:** `GameClock`. Tek giriş noktası, enjekte edilebilir,
testlerde sahte kaynak verilebiliyor, kalıcı durumda saklanıyor. Rastgelelik
için birebir aynısı yapılmalı (ör. `CombatRng` / `AdventureQuest.seed`).

**Bugünkü durum ve yapılacak ayrım:**

| Yer | Durum |
|---|---|
| `adventure_quest.dart` | ✅ Şu an **hiç** `Random` kullanmıyor; hasar tamamen deterministik. Bu özellik korunacak. |
| `adventure_screen.dart:_startAdventure` | Arka plan seçimi `Random(startedAt.microsecondsSinceEpoch)` ile. **Sorun değil:** sonuç `backgroundAsset` olarak kaydediliyor, yani bir kez üretilip sabitleniyor. |
| `root_shell.dart:_random` | Hatırlatma metni seçimi. Sunum, savaş sonucu değil — serbest. |
| `daily_wheel_screen.dart` | `Random()` — çark sonucu **kalıcı ödüle** dönüşüyor. #16 ile birlikte tohumlu kaynağa taşınmalı. |

**Kural netleştirmesi:** kalıcı oyun sonucunu (can, ödül, item, para, XP)
etkileyen her rastgelelik tohumdan gelmeli ve tohum durumla birlikte
saklanmalı. Yalnızca sunumu etkileyen rastgelelik (animasyon, metin seçimi)
serbest.

#### Aşama 4'ün geri kalanı

- **İki HP kavramının birleştirilmesi** (triaj B2'nin açık kalan yarısı):
  `UserProfile.hp` (5000, hiç azalmıyor, şema v2'de persist'ten çıkarıldı) ve
  `AdventureQuest.playerHealth` (0-100, savaşta kullanılan). Karar Aşama 4a'nın.
- **A2 — düşman canı = günlük adım hedefi, her adım 1 hasar**
  (`adventure_quest.dart:TODO(combat)`). Can/saldırı/savunma ayrı combat
  istatistikleri olarak modellenecek.
- **A3 — `stepGoal` üç işi birden yapıyor**: düşmanın canı, düşman kilidi eşiği
  ve günlük adım hedefi. Aşama 4a bunları ayıracak.
- **A1 — tur çözüm döngüsü**: `resolveExpiredRounds` ile zaten çözüldü, ama
  savaş motoru yeniden yazılırken korunmalı (arka planda biriken turların
  hepsi çözülmeli, tek tur değil).
- Bitince **#14** (canavara göre ödül) doğal devamı: `RootShell`'de düşman
  yenilme hook'u hazır, `Reward.icon` ise `IconData` — Model Kuralları #1
  gereği `String` anahtara çevrilmeli.

### 4.5. Daha sonrası (sıra değişmedi)

- **Aşama 5:** #3 (slide scroll adım seçimi — `_NumberWheel` hazır bekliyor),
  #6 (VS ekranı — arka plan görselleri artık var: `lib/Backgrounds/`),
  #18 (avatar asset — hâlâ belirsiz, kod işi mi sanat işi mi netleşmedi).
- **Aşama 6:** #13b Firebase → #7 takım savaşları. 6a'da `GameClock` sunucu
  saatine geçecek; 6b'de savaş motoru sunucuda çalışacak (bkz. determinizm
  şartı).

## 5. Hâlâ açık duran küçük maddeler

| Kaynak | Ne | Not |
|---|---|---|
| Triaj C3 | `tz.setLocalLocation(tz.UTC)` sabit; cihaz saat dilimi okunmuyor | Gün/saat bazlı bildirim eklenirse B'ye terfi eder |
| Triaj C4 | Hatırlatma metinleri iki yerde kopyalanmış | Bakım borcu |
| Triaj C5 | `RootShell._rewards` hiç doldurulmuyor → Ödüllerim hep boş | #14 ile kapanacak |
| Triaj C6 | `GameConstants.sideBySideWindowMinutes` kullanılmıyor | Ölü sabit, #7'ye ait |
| Triaj C7 | `nextReminderAt` geçmiş bir zamanla dönerse resume'da anında hatırlatma | Tek seferlik, zararsız |
| Triaj C9 | `lib/GIF Animations/Soldier/`, `lib/Characters/DarkMagic/Nature/` kullanılmayan asset klasörleri | Zararsız |
| Triaj C10 | `README.md` hâlâ "A new Flutter project." | Şablon artığı |
| Triaj C11 | Release imzası hâlâ debug key | Yayına çıkmadan önce |
| Triaj C13 | `RewardRarityX.color` model katmanında `Color` döndürüyor | Extension getter, persist edilmiyor |
| Aşama 2a | `ios/Podfile` yok; `permission_handler` makroları macOS'ta kısıtlanmalı | İlk macOS derlemesinde |
| Aşama 2a | iOS `AppDelegate.swift` (pedometer kanalı) **derlenmedi, test edilmedi** | Gerçek cihazda doğrulanmalı |
| `feec7db` | iOS açılış sesi kanalı (`AppDelegate.swift`) da Windows'ta derlenmedi | Gerçek cihazda doğrulanmalı |
| Aşama 1a | Saat dilimi değişimi test edilemiyor (Dart'ta süreç içi API yok) | Gerçek cihazda elle |
| Aşama 1a | İleri alınan cihaz saati yerelde yakalanamıyor | Aşama 6a'da sunucu saatiyle kapanır |
| Aşama 2a | Sensör arızası toparlanmasında `stepBurstAllowance` kadar (100 adım) sızıntı | Ölçülü takas, bilinçli |
| Aşama 0 | Gün değişiminde macera düşüyor; #3'te adım harcanacağı için telafi gerekecek | Aşama 5a |
| GD1 | Kayıt okunamazken `RootShell` yine de üzerine yazabilir (salt-okunur oturum yok) | Aşama 6'da sunucu ikinci kaynak olunca kapanır |

## 6. Sonraki oturum için önerilen sıra

1. **Seviye ↔ fiyat hizalama ölçümü** (§4.1) — ucuz, tek test dosyası, ve
   Aşama 4'ün denge kararlarının üstüne oturacağı zemini sağlamlaştırır.
   Sapma büyükse yalnızca `item_rules.dart:_costBase` düzeltilir.
2. **Envanter + kuşanma ekranı**, ardından buff çarpanlarının
   `coin_calculator` / `xp_calculator` kancalarına bağlanması (§4.2'nin
   savaş statlarını beklemeyen kısmı).
3. **#16 çark item ödülü** (§4.3) — katalog hazır, küçük iş.
4. **Aşama 4a savaş motoru** — determinizm şartıyla (§4.4).


---
---

# Aşama 3b — Mağaza denetimi ✅ (2026-08-20)

Mağaza "sorunsuz görünüyordu"; kapsamlı denetimde **beş gerçek hata** çıktı.
Kararların gerekçesi GD11–GD14.

## Denetimde temiz çıkanlar

Bunlar okunarak doğrulandı, hepsi gerçekten çalışıyor — ileride tekrar
açılmasına gerek yok:

| Kontrol | Neden güvenli |
|---|---|
| Yetersiz bakiye / negatif coin | Her iki satın alma yolunda `coins < cost` erken çıkışı |
| Aynı öğeyi ikinci kez alma | Yükseltmede `alreadyOwned && !repeatable`, ekipmanda `ownedItemIds.contains` |
| Atomiklik | Para düşme + envantere ekleme aynı senkron `setState` bloğunda, arada `await` yok |
| Çift dokunma / eşzamanlılık | Dart tek iş parçacıklı; muhafızlar ikinci çağrıyı yakalıyor |
| Kalıcılık | `_persist()` → `profile.coins` + `ownedItemIds` zaten yazılıyor |
| Seviye kilidi tam sınırda | `isUnlockedAt(l) => l >= requiredLevel` — Sv.7 item + Sv.7 oyuncu = açık |
| Kilidi arayüzden atlatma | `_purchaseEquipment` seviyeyi **yeniden** kontrol ediyor |
| Kilit tek kaynaktan mı | `Item.isUnlockedAt` tek fonksiyon, iki katmanda çağrılıyor; kopya mantık yok |
| Dondurma stok sınırı | Mağaza ve kilometre taşı **aynı** `grantStreakFreeze()`'den geçiyor |
| Tembel yükleme | `SliverGrid` + `SliverChildBuilderDelegate` |
| Boş durum | İki ayrı mesaj (sınıfa ekipman yok / süzgeç boş) |

## Düzeltilen hatalar

| # | Ne | Ciddiyet | Karar |
|---|---|---|---|
| M1 | Ana ekrandan itilen mağaza satın alma sonrası hiç tazelenmiyordu | işlevsel, yüksek | GD11 |
| M2 | Ekipman kartı dikey taşıyor, satın alma düğmesi kartın dışında kalıyordu | işlevsel, yüksek | GD12 |
| M3 | Nadirlik + "Sv. N" satırı yatay taşıyor, seviye etiketi kırpılıyordu | işlevsel, orta | GD12 |
| M4 | İki yükseltme para alıp hiçbir şey yapmıyordu | işlevsel, orta | GD13 |
| M5 | "Alabileceklerim" sahip olunanları da gösteriyordu | kozmetik | GD14 |

## Test

Toplam **295 test geçiyor**, `flutter analyze` temiz.

## Test kapsamı — mağaza artık sessizce bozulamaz

Aşama 4'te savaş sistemi item buff'larına dokunacak ve mağazayı dolaylı
etkileyebilir; bu testlerin görevi o anda alarm vermek.

| Dosya | Ne kapsıyor | Test |
|---|---|---|
| `test/store_screen_test.dart` | **Ekranın ne gösterdiği:** seviye kilidi görünürlüğü, kilidin nedeni, süzgeçler (kategori / "Alabileceklerim" / sahip olunanların elenmesi), boş durumlar, tüketilen yükseltmelerin stok satırı, para biriminin coin olduğu, ve **altı ekran genişliğinde taşma olmadığı** (320/360/390/412/480/800, katalogdaki en uzun adlı 20 item ile) | 26 |
| `test/store_purchase_test.dart` | **Satın alma kararı:** gerçek `RootShell` widget ağacı üzerinden para/sahiplik/seviye kilidi/kalıcılık. Yetersiz bakiye, negatif coin, ikinci satın alma, hızlı çift dokunma, atomiklik, tam seviye sınırı, seviye atlayınca kilidin açılması, ekranın tazelenmesi (M1 regresyonu), stok dolu reddi, 2x XP çarpanı, diske yazma, model kuralları ve v8→v9 taşıması | 30 |
| `test/daily_wheel_test.dart` | Mağazanın sattığı **ekstra çark hakkının tüketimi:** günlük hak dururken jeton harcanmaması, jetonla çevirme, kalan hakkın önceden söylenmesi, iki hakkın aynı ekranda kullanılabilmesi | 8 |

**Neden `RootShell` üzerinden:** `_purchase` / `_purchaseEquipment` bir
`StatefulWidget`'ın private metodu ve mağazanın **son söz sahibi** orası
(ekran kilitli görünse bile state yeniden kontrol ediyor). Mantığı saf bir
fonksiyona çıkarmak çalışan mimariye dokunmak olurdu (Kural 1/3); widget
testi aynı garantiyi mevcut yapıyı bozmadan veriyor. M1 regresyon testi
("satın alma sonrası ekran tazelenir") ancak bu seviyede yazılabiliyordu.

---
---

# Aşama 3c — Item dağılımı ve buff sistemi ✅ (2026-08-20)

Mağaza denetimi sırasında kullanıcı "neden sadece 3 kategori görüyorum"
sorusunu sordu; cevabı sınıf süzgeciydi ama dağılımda gerçek bir dengesizlik
çıktı. Üç iş birlikte yapıldı — kararlar **GD15–GD17**.

## 1. Dağılım dengelendi (GD15)

Her sınıf artık **en az üç kategori** ve **en az 150 item** görüyor;
hiçbiri kataloğun %60'ından fazlasını görmüyor. Aralık 140–341'den
**200–394**'e daraldı. Detay tablosu GD15'te.

## 2. Aynı görsel, sınıfa göre farklı item (GD16)

`ItemCatalog.forCharacterClass` artık itemleri **uyarlanmış** döndürüyor:

```
lib/Items/magic/ancient_spell_book_type_1_variant_01.png
  Magic     → "Esrarlı Kadim Büyü Kitabı 1"  [adım XP +%5,4 · düşman XP +%7,2]
  DarkMagic → "Lanetli Kadim Büyü Kitabı 1"  [çark XP +%10,8 · düşman XP +%7,2]
```

**Kimlik ikisinde de aynı** (`magic/ancient_spell_book_type_1_variant_01`).
Sınıf değiştiren oyuncunun envanteri bu yüzden kaybolmuyor — testle bağlandı.

## 3. Buff sistemi zenginleşti (GD17)

İki alandan **sekiz türe**; nadirlik hem miktarı hem sayıyı büyütüyor.
Sekiz sınıfın sekiz ayrı **imza bonusu** var, hiçbiri tekrar etmiyor.

| Nadirlik | Bonus sayısı | Toplam bütçe |
|---|---|---|
| Sıradan | 1 | %2 |
| Az Bulunur | 2 | %5 |
| Nadir | 2 | %9 |
| Epik | 3 | %15 |
| Efsanevi | 3 | %26 |

Mağaza kartı her bonusu kendi satırında gösteriyor; kart yüksekliği
280 → **302** px oldu ve altı ekran genişliğinde yeniden ölçüldü.

> **Buff'lar hâlâ hiçbir yere uygulanmıyor** — kuşanma (equip) kavramı yok.
> Bu birim buff'ları modelledi, türetti ve gösterdi. Uygulama noktalarının
> tam listesi GD17'deki tabloda; #9 (Aşama 4a) o tabloyu takip edecek.

## Test

- `test/item_catalog_test.dart` (39 → 43): bonus sayısı tablosu, sınıf
  imzalarının benzersizliği, aynı görselin sınıfa göre farklılaşması,
  kimliğin sabit kalması, **5 nadirlik × 8 sınıf × 10 kategori** taramasında
  hiçbir sayısal bonusun sıfıra düşmemesi, her sınıfın ≥3 kategori/≥150 item
  görmesi, hiçbir sınıfın kataloğun yarısından fazlasını görmemesi.
- `test/store_screen_test.dart`: dar ekran testleri artık **sınıfa uyarlanmış**
  (en uzun lakaplı, üç bonuslu) itemlerle çalışıyor — gerçek en kötü durum.

Toplam **299 test geçiyor**, `flutter analyze` temiz.

---
---

# Aşama 3d — Çark item ödülü (#16) ✅ (2026-08-20)

Kart **#16** kapandı. `daily_wheel_screen.dart` içindeki `TODO(#16)` (gerçek
dilimli çark grafiği) de kapandı. Kararlar **GD18–GD19**.

## Ne değişti

| Önce | Sonra |
|---|---|
| `Random()`, sonuç yalnızca XP | Tohumlu, sonuç XP **ya da ekipman** |
| Jenerik daire, gösterecek dilimi yok | 8 dilimli gerçek çark; ibre kazanan dilimin üstünde durur |
| Ödül havuzu 6 sabit XP değeri | Seviyeye ve sınıfa göre süzülmüş havuz + XP |
| Tohum yok | `UserProfile.wheelSeed` diske yazılıyor, her çevirmede ilerliyor |

## Havuz kuralları (`core/utils/wheel_rewards.dart` — saf)

- 8 dilim, **boş dilim yok**: her dilim ya XP ya item.
- En fazla **3** item dilimi (`maxItemSlices`), kalanı XP.
- Item adayları: sınıfa göre süzülmüş katalog → **seviye kilidi**
  (`Item.isUnlockedAt`, tek kaynak, ikinci kontrol yok) → sahip olunanlar
  elenir → **nadir ve altı** (`maxWheelRarity`).
- Uygun item yoksa dilimlerin tamamı XP olur.
- Aynı item iki dilimde birden çıkmaz.

## Görsel

`CustomPainter` ile dilimli çark: XP dilimleri tema renginde, item dilimleri
**nadirlik renginde** ve nadirlik etiketiyle — oyuncu çark dönmeden neyin
peşinde olduğunu görüyor. Kazanan dilimin **ortası** ibrenin altına gelecek
şekilde döndürülüyor; animasyon sonucu üretmiyor, önceden belirlenmiş sonucu
gösteriyor.

## Şema v10

Yeni alan: `UserProfile.wheelSeed`. 9 → 10 taşıması içerik değiştirmiyor
(varsayılan `0` = "henüz kurulmadı", ilk açılışta oyuncuya özel dolduruluyor).

## Test

- `test/wheel_rewards_test.dart` (17 test): determinizm (aynı tohum → aynı
  çark ve aynı kazanan), tohum ilerlemesinin döngüye düşmemesi, başlangıç
  tohumunun oyuncuya özel ve kararlı olması; havuz kuralları — boş dilim yok,
  seviye kilidi tutuyor, sahip olunan çıkmıyor, epik/efsanevi çıkmıyor, item
  dilimi tavanı, aynı item iki kez çıkmıyor, ekipmansız çarkın çalışması.
- `test/daily_wheel_test.dart` (12 test): hak yönetimi + item ödülünün
  gösterimi, sabit tohumla tekrarlanabilirlik, ikinci çevirmenin farklı sonuç
  vermesi.
- `test/store_purchase_test.dart` (+2): ödülün gerçekten profile işlemesi ve
  tohumun çevirdikten sonra ilerlemesi (`RootShell` üzerinden).

Toplam **322 test geçiyor**, `flutter analyze` temiz.

---
---

# Aşama 3e — Ekonomi hizalama ölçümü ✅ (2026-08-20)

CLAUDE.md §4.1 kapandı. Ölçüm yapıldı, **tek** düzeltme uygulandı ve hesap
`test/economy_pacing_test.dart` içine taşındı — prosa tahmini olarak
bırakılmadı. Kararlar **GD20–GD21**.

## Ölçüm

Referans oyuncu **6.000 adım/gün** → 3.000 XP/gün, 120 coin/gün.
Katman değerleri katalogun **medyanı** (784 item üzerinden).
Kümülatif XP: `baseXpPerLevel/2 · N · (N−1)`.

| Nadirlik | Adet | Medyan seviye | Seviyeye ulaşma | Medyan fiyat | Fiyatı biriktirme (2 item) | Oran |
|---|---|---|---|---|---|---|
| Sıradan | 371 | 2 | 0,3 gün | 100 | 1,7 gün | *ölçüm dışı* |
| Az Bulunur | 271 | 5 | 3,3 gün | 325 | 5,4 gün | **1,63** |
| Nadir | 81 | 10 | 15,0 gün | 825 | 13,8 gün | **0,92** |
| Epik | 43 | 17 | 45,3 gün | 2.600 | 43,3 gün | **0,96** |
| Efsanevi | 18 | 27 | 117,0 gün | 8.450 | 140,8 gün | **1,20** |

**Sonuç: fiyat eğrisi zaten hizalı.** Nadir, epik ve efsanevi oranları 1'e
çok yakın; az bulunur bandın üst ucunda ama içinde.

## §4.1'in "~2× sapma" okuması neden yanlıştı

O hesap **tek item/katman** varsayıyordu ve notun kendisi bu tuzağı uyarmıştı.
Varsayıma göre oranlar tamamen değişiyor:

| Katman başına item | Nadir | Epik | Efsanevi |
|---|---|---|---|
| 1 | 0,46 | 0,48 | 0,60 |
| **2** | **0,92** | **0,96** | **1,20** |
| 3 | 1,38 | 1,43 | 1,81 |

Kesişim tam **ikide**. Yani mevcut fiyatlar "oyuncu katman başına iki item
alır" varsayımına kalibre; bu varsayım artık testin içinde yazılı (GD20).

## Uygulanan tek düzeltme

**Sıradan taban 120 → 100** (GD21). Ölçüm dışı bıraktığımız katmanda gerçek
bir sorun vardı: en ucuz item 125 coin'di, günlük hedefin karşılığı 120 coin.
Oyuncu **beş coin** farkla ilk gününü eli boş kapatıyordu.

Diğer dört katmana dokunulmadı; XP eğrisine hiç dokunulmadı.

## Test

`test/economy_pacing_test.dart` — 10 test:
- kümülatif XP formülünün doğrulanması (10. seviye = 45.000 XP),
- referans oyuncunun günlük kazancı,
- dört katmanın oran bandında ([0,5–1,8]) kalması,
- nadirlik yükseldikçe **iki kapının da** uzaması,
- günlük hedefi tutturan oyuncunun ilk akşam alışveriş yapabilmesi,
- en ucuz item'ın ilk seviyede açık ve bedava olmaması.

Sabitlerden biri (`stepsPerCoin`, `stepsPerXp`, `maxDailyStepCoins`,
`baseXpPerLevel`, `_costBase`, `_levelBand`) değişirse bu test alarm verir.

Toplam **332 test geçiyor**, `flutter analyze` temiz.

---
---

# OTURUM KAPANIŞI — 2026-08-20

> ⚠️ **ESKİ — güncel devam noktası dosyanın sonundaki 2026-08-25 kapanışıdır.**
> Bu bölüm tarihsel kayıt olarak duruyor; §3'teki "#9 envanter + kuşanma"
> maddesi **tamamlandı** (Aşama 3g).
>
> (Yazıldığı gün geçerliydi:) **Sonraki oturum buradan başlasın.** Hiçbir şey sormadan devam edebilmek
> için gereken her şey burada. Bir önceki kapanış ("OTURUM KAPANIŞI —
> 2026-08-19") hâlâ geçerli; bu bölüm onun üstüne yazıyor.

## 1. Bu oturumda ne yapıldı

Oturum "mağazayı sağlama al" göreviyle başladı; denetimde beş gerçek hata
çıktı ve iş oradan büyüdü. Beş bölüm tamamlandı, hepsi ayrı commit edildi.

| Bölüm | Ne | Test |
|---|---|---|
| **Aşama 3b** | Mağaza denetimi — 5 gerçek hata düzeltildi (GD11–GD14) | 245 → 252 |
| — | Mağaza regresyon testleri (satın alma, kilit, kalıcılık, çark jetonu) | 252 → 295 |
| **Aşama 3c** | Sınıf dağılımı + sınıfa özel ad/buff + 8 türlü buff sistemi (GD15–GD17) | 295 → 299 |
| **Aşama 3d** | #16 çark item ödülü + gerçek dilimli çark (GD18–GD19) | 299 → 322 |
| **Aşama 3e** | Ekonomi hizalama ölçümü + sıradan fiyat düzeltmesi (GD20–GD21) | 322 → **332** |

Oturum sonunda: `flutter analyze` temiz, `flutter test` **332/332 geçiyor**.

**Kapanan kartlar/maddeler:** #16 (çark item ödülü), CLAUDE.md §4.1 (ekonomi
hizalama), §4.3 (çark), `daily_wheel_screen.dart:TODO(#16)`, GD9'un
"kalkanlar para veriyor" tuhaflığı.

**Şema sürümü: v7 → v10.**
- v9: `extraWheelSpins`, `xpBoostUntil` (mağaza yükseltmeleri tüketilir oldu)
- v10: `wheelSeed` (çark determinizmi)

### Commit durumu
Beş bölümün beşi de kullanıcı tarafından commit edildi. **Bu kapanış
bölümünün eklendiği `CLAUDE.md` değişikliği commit edilmedi.**

## 2. Verilen kararlar (GD11–GD21)

Hepsi "GERİ DÖNÜLECEK KARARLAR" bölümünde gerekçesiyle yazılı. Özet:

| # | Karar | Tek cümlelik gerekçe |
|---|---|---|
| GD11 | Mağaza itilmiyor, sekmeye geçiliyor | İtilen rota `RootShell`'in alt ağacında değil; `setState` onu tazelemiyordu |
| GD12 | Ekipman kartı sabit yükseklikte (302 px) | `childAspectRatio` dar ekranda satın alma düğmesini kartın dışında bırakıyordu |
| GD13 | İki yükseltme gerçekten tüketiliyor | 800 ve 300 coin alıp hiçbir şey yapmıyorlardı |
| GD14 | "Alabileceklerim" sahip olunanları eliyor | Alınamayacak şey o listede olmamalı |
| GD15 | Her sınıf en az 3 kategori görüyor | Magic tek kategori görüyordu, süzgeç işlevsizdi |
| GD16 | Aynı görsel sınıfa göre farklı ad + buff | Kimlik **değişmiyor**; sınıf değişince envanter kaybolmasın |
| GD17 | 8 buff türü, nadirliğe göre 1–3 bonus | Hepsi bugün var olan bir uygulama noktasına karşılık geliyor |
| GD18 | Çark tohumlu ve tohum saklanıyor | Kalıcı ödül üreten rastgelelik §4.4 kapsamında |
| GD19 | Çarkta epik/efsanevi yok, en fazla 3 item dilimi | Aylık birikimler günlük çarktan düşerse mağaza anlamsız |
| GD20 | Fiyat "katman başına 2 item"e kalibre | §4.1'in "2× sapma" okuması tek item varsayımının artefaktıydı |
| GD21 | Sıradan taban 120 → 100 | Oyuncu 5 coin farkla ilk gününü eli boş kapatıyordu |

## 3. SIRADAKİ İŞ — #9: envanter + kuşanma

**Bu oturumun bıraktığı en büyük açık:** `ItemBuff` üretiliyor, sınıfa göre
farklılaşıyor ve mağazada gösteriliyor ama **hiçbir yere uygulanmıyor**.
Kuşanma (equip) kavramı yok; `ownedItemIds` yalnızca sahiplik tutuyor.

### Uygulama noktaları hazır (GD17 tablosu)

| Buff türü | Nereye bağlanacak | Durum |
|---|---|---|
| `stepCoin` | `coin_calculator.dart` → `calculateStepCoins(multiplier:)` | **Kanca var, boş** (`TODO(items)`) |
| `stepXp` | `xp_calculator.dart` → `calculateStepXp(multiplier:)` | **Kanca var, boş** (`TODO(items)`) |
| `wheelXp` | `root_shell.dart:_spinWheel` → `_awardXp` | Bağlanacak |
| `enemyXp` | `root_shell.dart:_onStepsReported` düşman yenilme dalı | Bağlanacak |
| `dailyCoinCap` | `GameConstants.maxDailyStepCoins` + buff | Bağlanacak |
| `streakFreezeCap` | `GameConstants.maxStreakFreezes` + buff | Bağlanacak |
| `wheelSpinCap` | `GameConstants.maxExtraWheelSpins` + buff | Bağlanacak |
| `streakRelief` | `GameConstants.streakStepThreshold` eksi buff | Bağlanacak |

### Önerilen sıra

1. **Kuşanma modeli.** `UserProfile.equippedItemIds` (kategori başına bir
   slot mu, yoksa sabit N slot mu — karar gerekli). Şema v11.
   - **Uyarı:** kuşanılan itemin buff'ı **sınıfa göre çözülmeli**
     (`ItemCatalog.byId(id, characterClass: ...)`), yoksa temel buff uygulanır
     ve GD16 anlamını yitirir.
2. **Toplam buff hesabı.** Saf fonksiyon (`core/utils/equipped_buffs.dart`
   gibi): kuşanılan itemlerin `ItemBuff`'larını toplayan tek nokta. Proje
   deseni bu (`calculateStepCoins`, `limitStepBatch`, `archiveStepDay`).
3. **Envanter ekranı.** Bugün yok. Sahip olunan itemleri gösterip
   kuşandıran ekran. Mağaza kartı deseni (`_EquipmentCard`) yeniden
   kullanılabilir — **sabit yükseklik kuralına dikkat** (GD12).
4. **Çarpanların bağlanması.** Yukarıdaki tablo sırayla.
5. **Özel (elle yazılmış) buff'lar** — 18 efsanevi + seçilmiş epikler için
   koşullu/tetiklenen etkiler. Bu, Aşama 4a savaş statlarını **bekliyor**;
   ilk dördü beklemiyor. (Bkz. bir önceki kapanışın §4.2'si.)

### Dikkat edilecekler

- **Buff'lar günlük tavanı aşamamalı** — 1b'deki kural: çarpan yalnızca ödemeyi
  büyütür, tüketilen adımı değiştirmez.
- **`dailyCoinCap` buff'ı `DailyProgress.coinsEarned` karşılaştırmasına
  girmeli**, `maxDailyStepCoins` sabitine değil.
- **`streakRelief` seri eşiğini düşürüyor** — kuşanmayı çıkarınca serinin
  geriye dönük bozulmaması gerekir; eşik kontrolü yalnızca **o an** yapılıyor
  (`_onStepsReported`), yani sorun yok, ama testle bağlanmalı.
- `economy_pacing_test.dart` buff'sız dünyayı ölçüyor. Buff'lar bağlanınca
  o testin varsayımı ("günlük 120 coin") hâlâ **taban** olarak doğru kalır;
  buff'lı senaryo ayrı ölçülmeli.

## 4. Sıradaki işten sonra (sıra değişmedi)

- **Aşama 4a — savaş sistemi (#4).** ⚠️ **Determinizm şartı geçerli:**
  `Random()` savaş kodunda yasak, tohum enjekte edilip durumla saklanacak.
  Çark için yapılan şey (`wheel_rewards.dart` + `UserProfile.wheelSeed`)
  **birebir izlenecek desen** — artık projede çalışan bir örneği var.
  Ayrıca: iki HP kavramının birleştirilmesi (B2'nin açık yarısı), A2
  (düşman canı = adım hedefi), A3 (`stepGoal` üç iş birden).
- **Aşama 4b — #14 canavara göre ödül.** `Reward.icon` bir `IconData`;
  Model Kuralları #1 gereği `String` anahtara çevrilmeli. `RootShell`'de
  düşman yenilme hook'u hazır. `WheelReward` modeli izlenecek örnek:
  ödül **tüketilip** atıldığı için framework tipi tutmuyor.
- **Aşama 5 — #3 (slide scroll), #6 (VS ekranı), #18 (avatar asset).**
- **Aşama 6 — #13b Firebase → #7 takım savaşları.**

## 5. Hâlâ açık duran küçük maddeler

Bir önceki kapanışın §5 tablosu **aynen geçerli** (C3, C4, C5, C6, C7, C9,
C10, C11, C13, iOS derleme borçları, saat dilimi boşlukları, GD1). Bu oturumda
eklenenler:

| Kaynak | Ne | Not |
|---|---|---|
| GD11 | `_openWheel`, `_openRewards`, `_editCharacter` hâlâ `_push` kullanıyor | Bugün güvenli (kendi durumlarını tutuyorlar / salt-okunur). Canlı state yansıtması gereken **yeni** ekran eklenirse sekmeye alınmalı |
| GD13 | `skin_dragon_cape` ve `title_villain_hunter` hiçbir yerde gösterilmiyor | Sanat/ekran işi (pelerin görseli, profilde unvan satırı), kod hatası değil |
| GD17 | Buff'lar hiçbir yere uygulanmıyor | **Yukarıdaki §3'ün konusu** |
| Aşama 3d | Çark ekranı itilen rotada; tohumu kendi kopyasında ilerletiyor | İki taraf da `nextWheelSeed` kullanıyor, uyumlular. Riverpod geçişinde sadeleşir |
| Aşama 3e | `economy_pacing_test.dart` buff'sız dünyayı ölçüyor | Buff'lar bağlanınca buff'lı senaryo ayrıca ölçülmeli |

## 6. Bu oturumda eklenen dosyalar

    lib/core/utils/wheel_rewards.dart      # çark havuzu + tohum (saf)
    lib/models/wheel_reward.dart           # çark ödülü (XP ya da item)
    test/store_purchase_test.dart          # RootShell üzerinden satın alma (32)
    test/wheel_rewards_test.dart           # çark havuz kuralları (17)
    test/economy_pacing_test.dart          # seviye/fiyat hizalaması (10)

`test/daily_wheel_test.dart` bu oturumda yazıldı ve #16 ile birlikte
yeniden yazıldı (12 test).

---
---

# Aşama 3f — Buff sistemi ve item isimleri ✅ (2026-08-20)

Kart **#9**'un tasarım yarısı kapandı: buff'lar artık çeşitli, güçlü ve
karakterli. **Uygulama yarısı (kuşanma) hâlâ açık** — Aşama 3g'nin konusu.
Kararlar **GD22–GD25**.

## 1. Buff modeli efektler üstüne yeniden kuruldu

`lib/models/item_effect.dart` (yeni):

| Kavram | Ne |
|---|---|
| `ItemStat` | 15 stat. **7 savaş** (saldırı, savunma, savaş canı, kritik şansı, kritik hasarı, can çalma, sıyrılma) + **8 oyun dışı** (eskiden var olanlar). |
| `ItemEffectMode` | `flat` (+12 saldırı) / `percent` (+%18 savunma) |
| `ItemEffectTrigger` | `always`, `lowHealth`, `highHealth`, `onHit`, `onKill`, `untouchedRounds`, `nightWalk`, `streakActive` |
| `ItemEffect` | stat + mode + değer (**eksi olabilir**) + tetikleyici + ihtimal + eşik + serbest etiket |

`ItemBuff` artık tek alanlı: `List<ItemEffect> effects`. Sekiz sayısal getter
(`stepCoinBonus`, `dailyCoinCapBonus`, …) **türetilmiş** hâle geldi, yani
mevcut 43 katalog testi kırılmadan çalışmaya devam ediyor.

> **Kritik ayrım:** türetilmiş getter'lar yalnızca `ItemEffect.isPassive`
> (koşulsuz + tam ihtimalli) etkileri toplar. Koşullu bir etki kuşanıldığı anda
> pasif bir çarpana dönüşmez; gösterilir, ekonomiye girmez.

İstenen yedi buff tipinin karşılığı:

| İstenen | Karşılığı |
|---|---|
| sabit artış | `ItemEffect.flat(stat: attack, value: 46)` |
| yüzdesel artış | `ItemEffect(stat: defense, value: 0.38)` |
| koşullu | `trigger: lowHealth, threshold: 0.3` |
| tetiklenen | `trigger: onHit, chance: 0.15` |
| eşikli | `trigger: untouchedRounds, threshold: 3` |
| oyun dışı | `stepCoin` / `stepXp` / `wheelXp` / `enemyXp` + `nightWalk`, `streakActive` |
| çift etkili | aynı listede bir artı bir eksi değer (`+%50 saldırı, -%18 savunma`) |

## 2. Elle tasarlanmış alt küme

`lib/data/item_effects.dart` (yeni) — **veri, kod değil**. Hiçbir yerde
`switch (item.id)` yok; `buildItemFromAsset` tabloyu okur.

- **18 efsanevi + 31 epik temel item'ın tamamı** imzalı (kart 43 epik *item*
  diyordu; 43 item = 31 temel tanım, hepsi kapsandı).
- **12 seçilmiş nadir** de imzalı.
- Her imzalı item bir **lore cümlesi** taşır (`Item.lore`) ve mağaza kartında
  nadirlik renginde, italik gösterilir.
- Geri kalan (bütün sıradan ve az bulunur, imzasız nadirler) kural
  türetmesinde kaldı.

Test `bütün epik ve efsanevi temel itemlerin imzası var` bunu bağlıyor: yeni
bir epik/efsanevi eklenip imzası unutulursa test kırılır.

## 3. Ekonomi hesabı — istenen üç sınır

| Sınır | Nerede | Nasıl garanti |
|---|---|---|
| Tek item ≤ **+%15** | `GameConstants.maxSingleItemEconomyBonus` | Kural türetmesinde `_cappedRate`; imzalı itemlerde tasarım disiplini. **784 item × 8 sınıf taranarak** testle doğrulanıyor. |
| Kuşanılan toplam ≤ **+%50** | `GameConstants.maxEquippedEconomyBonus` | `EquippedBuffs.from` içinde **sert kırpma**. Item tasarımı ne olursa olsun garanti. |
| Günlük coin tavanı aşılamaz | `maxEquippedCoinCapBonus = 200` | Tavan bonusu da kırpılıyor; çarpan yalnızca ödemeyi büyütür, tüketilen adımı değiştirmez (Aşama 1b kuralı). |

Ek kırpmalar: stok bonusu ≤ +2 (her biri), seri eşiği indirimi ≤ 1000 adım
(yani eşik hiçbir zaman 1000'in altına inmez).

**Ölçülen en kötü durum** (her kategoriden en yüksek nadirlikli item kuşanılmış):

| Sınıf | Slot | adım parası | adım XP | çark XP | düşman XP | coin tavanı | koşullu | savaş |
|---|---|---|---|---|---|---|---|---|
| SwordMan | 4 | — | — | — | +%14 | — | 0 | 11 |
| Paladin | 4 | +%13 | — | — | — | — | 0 | 10 |
| Thief | 5 | — | — | — | +%29 | +80 | 1 | 10 |
| Archer | 3 | +%13 | — | — | — | +60 | 1 | 6 |
| Magic | 3 | — | +%3 | +%15 | — | — | 1 | 4 |
| DarkMagic | 4 | — | — | +%21 | +%15 | — | 1 | 7 |
| Faith | 3 | — | — | +%15 | — | — | 0 | 7 |
| Nature | 4 | +%13 | +%15 | +%15 | — | +60 | 0 | 9 |

En yüksek tek oran **+%29** — kırpmaya (%50) hiç dayanmıyor. Kırpma yalnızca
teorik uç durumu (beş item de aynı statı %15 verirse %75) kapatıyor.

`economy_pacing_test.dart` buff'sız dünyayı ölçüyor ve **hâlâ geçerli**:
oradaki 120 coin/gün artık "taban" değeri, kuşanma onu en fazla %50 büyütüyor.

## 4. İsimler

166 temel adın tamamı elden geçti (`item_definitions.dart`).

- **Varyantlar artık numaralanmıyor.** "Hançer 4" → "Yıpranmış Hançer".
  36 sıfatlık havuz (`variantAdjectives`); en kalabalık temel item 28 varyant
  taşıyor, havuz onun üstünde tutuldu ki aynı temel item'ın iki varyantı asla
  aynı sıfatı almasın.
- **Sıfat sınıfa göre kayıyor** (GD23): aynı görsel Savaşçıda *Paslı Hançer*,
  Hırsızda *Uğursuz Hançer*. Sıfat yığmak yerine sınıf farkı sıfatın
  kendisinden geliyor.
- **Efsanevilere unvan verildi:** "Efsanevi Mızrak" → **Ordu Deviren**,
  "Göktaşı Oku" → **Yıldız Düşüren**, "Tsunami Oku" → **Kıyı Yutan**,
  "Yeraltı Kayıtları" → **Yeraltı Sicili**, "Ejderha Büyü Kitabı" →
  **Ejderha Fermanı**, "Ruh Hapseden Kalkan" → **Ruh Kapanı**.
- **Sıradan/az bulunur adlar isimle başlıyor**, sıfatla değil — varyant sıfatı
  öne geldiği için iki sıfatlı ağır adlar çıkmasın diye ("Yassı Ok" →
  "Talim Oku").
- Uydurma İngilizce yok. `rapier` → **Meç**. Yerleşmiş yabancı kökenli silah
  adları korundu (arbalet, kunai, şuriken, bumerang).
- **Aynı ad iki kez geçmiyor** — hem temel adlar, hem 784 item, hem her sınıfın
  gördüğü liste ayrı ayrı testle taranıyor.

## 5. Test

- `test/item_effects_test.dart` (33 test): etiket üretimi (yedi tetikleyicinin
  hepsi), toplama kuralları, imza tablosunun eksiksizliği, imzalı itemlerin
  sınıfa göre değişmemesi, efsanevilerin ≥3 etki + lore taşıması, **her
  efsanevinin bugün de işe yarayan bir etkisi olması**, yedi tetikleyicinin ve
  çift etkili itemlerin katalogda gerçekten bulunması, ekonomi tavanları,
  varyant sıfatlarının benzersizliği/kararlılığı, ad benzersizliği.
- `test/equipped_buffs_test.dart` (13 test): boş kuşanma, toplama, koşullu ve
  savaş etkilerinin çarpana girmemesi, dört tavanın da tutması, **gerçek
  katalogla her sınıfın en güçlü kuşanmasının** tavanı aşmaması.

Toplam **379 test geçiyor**, `flutter analyze` temiz.

## 6. Açık kalan (Aşama 3g)

Buff'lar hâlâ **hiçbir yere uygulanmıyor**: `EquippedBuffs` yazıldı ve test
edildi ama onu besleyecek kuşanma kavramı yok. `coin_calculator.dart` ve
`xp_calculator.dart` içindeki `TODO(items)` kancaları hâlâ boş.

---
---

# Aşama 3g — Envanter ve kuşanma (#9) ✅ (2026-08-20)

Kart **#9** kapandı. Buff'lar artık gerçekten uygulanıyor:
`coin_calculator.dart` ve `xp_calculator.dart` içindeki `TODO(items)`
kancaları doldu ve kaldırıldı. Kararlar **GD26–GD29**.

## Slot modeli

**Slot = item kategorisi.** Yeni bir kavram uydurulmadı; `ItemCategory` zaten
mağaza süzgeci olarak kullanılıyordu ve sınıf başına 3–5 kategori düşüyor
(GD15). Sonuç: her sınıf 3–5 item kuşanabiliyor ve "slot başına tek item"
kuralı veri düzeyinde zorlanıyor.

`UserProfile.equippedItemIds` bir **`Map<String, String>`**: slot anahtarı
(`ItemCategory.folder`) → item kimliği. Aynı anahtara ikinci bir kimlik
yazılamayacağı için kural kodla değil yapıyla korunuyor.

Model Kuralları #1 temiz: yalnızca `String` tutuluyor, item her açılışta
katalogdan çözülüyor ve **sınıfa uyarlanıyor**
(`ItemCatalog.byId(id, characterClass:)`) — yoksa GD16'nın sınıfa özel
buff'ları uygulanmazdı.

## Buff uygulama noktaları — sekizi de bağlandı

| Buff | Nerede |
|---|---|
| `stepCoin` | `calculateStepCoins(multiplier:)` |
| `dailyCoinCap` | `calculateStepCoins(dailyCap:)` — yeni parametre |
| `stepXp` | `calculateStepXp(multiplier:)` |
| `wheelXp` | `_spinWheel` → `_awardXp((reward.xp * çarpan).floor())` |
| `enemyXp` | `_onStepsReported` düşman yenilme dalı |
| `streakFreezeCap` | `grantStreakFreeze(1, cap)` — kilometre taşı **ve** mağaza |
| `wheelSpinCap` | `grantExtraWheelSpin(1, cap)` — mağaza |
| `streakRelief` | `_onStepsReported` seri eşiği kontrolü |

`EquippedBuffs` (Aşama 3f'te yazılmıştı) tek okuma noktası; hiçbir yerde
ikinci bir toplama yok.

**Ekonomi güvenliği korundu:** çarpan yalnızca ödemeyi büyütüyor, tüketilen
adımı değiştirmiyor (Aşama 1b kuralı) ve günlük tavanı aşamıyor — kırpma
`calculateStepCoins` içinde. `lastRewardedStepCount` /
`lastXpRewardedStepCount` çift-sayma koruması hiç değişmedi.

## Kuşanmanın sessizce bozulmaması

`_refreshEquipment` her çözümlemede dört şeyi temizliyor:

1. katalogdan kalkmış kimlik → slot boşalır,
2. artık **sahip olunmayan** kimlik (satılmış item) → slot boşalır,
3. oyuncunun sınıfının kullanamadığı kategori (sınıf değişimi) → slot boşalır,
4. yanlış slota yazılmış kimlik (elle düzenlenmiş kayıt) → slot boşalır.

**Sahiplik kaydına hiç dokunulmuyor.** Sınıf değiştiren oyuncu itemlerini
kaybetmiyor, yalnızca kullanamadıklarını kuşanmıyor — GD16'nın kimlik
kararının doğrudan meyvesi. Karakter düzenleme ekranından sınıf değişince
`didUpdateWidget` bunu tetikliyor.

## Ekran

`lib/features/inventory/inventory_screen.dart`:

- **Karakter paneli** — sekiz canlı stat için *taban · ekipman · toplam* ayrı
  sütunlarda. Savaş statları ayrı bir başlıkta, soluk ve **nedeni yazılı**:
  "Bu değerler savaş sistemiyle birlikte etkinleşecek". Koşullu etkiler ayrı
  listede; sayıya indirgenip toplama katılmıyorlar.
- **Slot tahtası** — her kategori için kuşanılı item ya da boş kutu. Boş kutuya
  dokunmak o kategoriye süzgeç uygulayıp nedenini söylüyor.
- **Liste** — kuşanılanlar önce, sonra nadirlik ve seviye. Kilitli itemler
  soluk + kilit ikonu + "Sv. N" etiketi, ama **tıklanabilir**: neden kilitli
  olduğunu görebilmeli.
- **Item kartı (bottom sheet)** — lore, etkiler (savaş statları soluk),
  **karşılaştırma** ("Çelik Kılıç yerine kuşanınca: +8 saldırı, -%3 savunma"),
  kilit sebebi, Kuşan/Çıkar ve Sat düğmeleri.
- **Satış onay diyaloğu** geri gelecek parayı ve geri alınamazlığı önceden
  söylüyor.

Giriş noktaları: ana ekranda ikinci hızlı erişim satırı (dört kart tek satıra
sığmıyordu) ve profildeki "Ekipman" kartı.

## Satış

`sellValueFor(cost)` = fiyatın **%40'ı**, 5'in katına yuvarlı, en az 5.
Alım-satım döngüsü para üretemez; testle bağlı. Kuşanılı bir item satılırsa
önce çıkarılıyor ve bu kullanıcıya söyleniyor.

## Şema v11

Yeni alan: `equippedItemIds`. 10 → 11 taşıması içerik değiştirmiyor — boş
harita doğru varsayılan, hiçbir item kendiliğinden kuşanılmış sayılmamalı.

`streakFreezes` / `extraWheelSpins` okuma kırpması **buff'lı tavana**
genişletildi (`taban + maxEquippedStockBonus`): kuşanılan bir item stoğu
büyütmüş olabilir ve o jetonlar okurken sessizce yakılmamalı. İki mevcut test
bu yeni sınıra göre güncellendi (silinmedi).

## Test

- `test/item_comparison_test.dart` (10 test): boş slot, artı/eksi fark, denk
  itemler, aynı statın sabit+oransal ayrımı, koşullu etkilerin sayıya
  indirgenmemesi, kazanılan/kaybedilen koşullar.
- `test/inventory_test.dart` (22 test, gerçek `RootShell` üzerinden):
  kuşanma, slot çakışması (yerinden edilen item **satılmıyor**), farklı
  kategoriler, çıkarma, seviye kilidi (tam sınır dahil), **buff'ın gerçekten
  paraya yansıması** (+%50 → 100 coin yerine 150), çıkarınca geri düşmesi,
  satış (onay/vazgeç/kuşanılı item), dört temizlik senaryosu, diske yazma,
  v10→v11, bozuk kuşanma satırları, stok tavanı.

> **Test notu:** aynı test içinde ikinci kez `pumpWidget` çağrılınca Flutter
> aynı tipteki elemanı yeniden kullanıp `initState` yerine `didUpdateWidget`
> çalıştırıyor; `RootShell._profile` `late final` olduğu için eski profil
> yerinde kalıyor ve test sessizce yanlış şeyi ölçüyordu. Her kurulum ayrı bir
> `ValueKey` alıyor.

Toplam **411 test geçiyor**, `flutter analyze` temiz.

## Açık kalan

- **Özel buff'ların koşullu dalları hâlâ çalışmıyor**: `nightWalk`,
  `streakActive`, `lowHealth`, `onHit`, `onKill`, `untouchedRounds`. Bunlar
  gösteriliyor ama uygulanmıyor. Savaş tetikleyicileri Aşama 4a'yı bekliyor;
  `nightWalk` ve `streakActive` **beklemiyor** ve bir sonraki uygun birimde
  bağlanabilir.
- `economy_pacing_test.dart` hâlâ buff'sız dünyayı ölçüyor; buff'lı senaryo
  ayrıca ölçülmedi (tavanlar `equipped_buffs_test.dart` ile bağlı).

---
---

# Test ortamı — testler neden `--no-test-assets` ile çalışıyor (2026-08-25)

Bu makinede **Smart App Control `impellerc.exe`'yi engelliyor.** Bu yalnızca
`flutter run`'ı değil test komutunu da düşürüyor: Flutter, test asset paketini
kurarken Material'ın `ink_sparkle.frag` shader'ını derlemek zorunda ve
derleyici çalışmayınca **araç çöküyor** (testler bile başlamıyor).

Flutter'ın bu durum için bir tutamacı var (`ShaderCompiler` içindeki
`_SecurityPolicyBlockException`) ama yalnızca Windows hata kodu **1260** için;
bu makinede gelen kod **4551**, dolayısıyla tutamak devreye girmiyor.
Flutter tarafında bir eksik, bizim kodumuzda değil.

**Kullanılan çözüm — SDK'ya dokunmadan:**

```powershell
# 1) Bir kereye mahsus: eski başarılı Android build'inden kalan DERLENMİŞ
#    shader'ı test paketine kopyala
copy build\app\intermediates\flutter\debug\flutter_assets\shaders\ink_sparkle.frag `
     build\unit_test_assets\shaders\ink_sparkle.frag

# 2) Bundan sonra testler böyle çalıştırılır
flutter  test --no-test-assets
```

`--no-test-assets` "asset yok" demek değil; "asset paketini **yeniden kurma**"
demek. `build/unit_test_assets/` zaten dolu (784 item görseli, avatar GIF'leri,
`AssetManifest.bin`), yalnızca shader eksikti.

⚠️ **`pubspec.yaml`'a yeni asset eklenirse** paket bayatlar. O zaman bir kez
normal test komutu çalıştırılır (çökecek ama paketi yazacak), sonra shader
tekrar kopyalanır, sonra `--no-test-assets` ile devam edilir.

`flutter analyze` ve `flutter pub get` etkilenmiyor.

## Golden testler

Golden altyapısı bu ortamda **çalışıyor**. Bir uyarı: test ortamında gerçek
font yok, bütün yazılar **dolu kutu** olarak çiziliyor. Bu hizalama ve taşma
denetimi için avantaj (metin sınırları birebir görünür) ama "yazı doğru mu"
sorusunu golden cevaplayamaz — o `find.text` ile ayrıca doğrulanmalı.

`pumpAndSettle` **kullanılamıyor**: sonsuz tekrar eden animasyonlar var
(ör. `_equipmentBobController.repeat()`). Bunun yerine sabit kare dizisi
(`pump(Duration)` × N) kullanılıyor; bu aynı zamanda golden'ları
tekrarlanabilir kılıyor.

Golden dosyaları `test/golden/goldens/` altında ve repoya giriyor: arayüz
sessizce bozulduğunda alarm versinler.

---

# Bölüm 1 — Sınıf seçme ekranı ✅ (2026-08-25)

Cihazda görülen üç sorun düzeltildi, ekranın tamamı gözden geçirildi.
Kararlar **GD30–GD33**.

| Sorun | Kök neden | Çözüm |
|---|---|---|
| Tanıtım ekranında geri yok | `_ClassReveal` bir overlay, rota değil; `PopScope` de yoktu | Sol üstte geri butonu + `PopScope` |
| Çift onay | `_confirmClassReveal` yalnızca seçimi işaretliyor, ızgarada ikinci kez "DEVAM ET" gerekiyordu | Onay tanıtım ekranında, doğrudan özet adımına ilerliyor |
| Eşya görselleri sola kayık | Yatay `ListView` içerik sığsa bile sola yaslar | Sığdığında ortalayan, taşınca kayan şerit |

**Eşya şeridi ayrıca ekrana uyarlanıyor:** kart genişliği görüntüden
türetiliyor (64–92 px arası), böylece en dar destekli ekranda (320 dp) üç kart
**tam** sığıyor. Dörtten fazla kategori gören sınıflarda şerit yine kayıyor;
kırpılan kart "devamı var" işaretidir.

## Gözden geçirmede çıkan üç sessiz hata

1. **Varsayılan sınıf sessizce kabul ediliyordu.** Katalog yüklenirken
   `classes.first` seçili geliyor ve oyuncu hiçbir karta dokunmadan
   "DEVAM ET"e basabiliyordu. Artık `_classConfirmed` bayrağı var; onaylanmadan
   devam kapalı ve **nedeni yazılı** (Model Kuralları #4).
2. **Vurgu yalan söylüyordu.** Izgaradaki "seçili" çerçevesi de varsayılan
   seçimi gösteriyordu. Artık yalnızca onaylanmış seçim vurgulanıyor.
3. **Navigasyon haptik geri bildirimi bekliyordu.** `_goToStep` ve `_complete`
   `await HapticFeedback…` yapıyordu; titreşim kanalı yanıt vermezse sihirbaz
   **tamamen kilitleniyor**. Bu widget testinde birebir gözlendi (platform
   kanalı mock'lanmadan hiçbir adım ilerlemiyordu). Haptik artık beklenmiyor.

## Test

`test/character_creation_test.dart` — 18 test: katalog yükleme, tanıtımın
açılması, geri butonu, donanım geri tuşunun iki dalı (tanıtımı kapat / bir
adım geri), onaysız devamın kapalı olması ve nedeninin yazılı olması, tek
onayın doğrudan özete geçirmesi, düzenleme modunda kayıtlı sınıfın onaylı
sayılması, **beş ekran genişliğinde şerit hizalaması** ve **beş golden**
(ızgara 320/360, tanıtım 320/360/800).

Toplam **440 test geçiyor**, `flutter analyze` temiz.

---

### GD30. Tanıtım ekranı onayı doğrudan özet adımına geçiriyor (2026-08-25)
- **Nerede:** `character_creation_screen.dart:_confirmClassReveal`
- **Karar:** "BU SINIFI SEÇ" hem sınıfı seçiyor hem bir sonraki adıma
  ilerletiyor. Izgaradaki "DEVAM ET" duruyor ama artık yalnızca özetten geri
  dönen oyuncu için anlamlı.
- **Neden:** karar karakteri incelediğin yerde verilmeli. İki onay, ikincisini
  "ne onayladım ben?" sorusuna çeviriyordu.
- **Geri dönülecek nokta:** ileride sınıf karşılaştırma ekranı eklenirse
  (iki sınıfı yan yana koymak) tanıtımdan ızgaraya dönüp başka bir sınıfa
  bakmak yeniden değerli olur; o zaman "seç ve kal" ikinci bir düğme olabilir.

### GD31. Onaylanmamış varsayılan sınıf artık geçerli seçim sayılmıyor (2026-08-25)
- **Nerede:** `_classConfirmed`
- **Karar:** katalogdan gelen varsayılan seçim ne vurgulanıyor ne de "DEVAM
  ET"i açıyor. Düzenleme modunda kayıtlı sınıf onaylı sayılıyor (o zaten
  verilmiş bir karar).
- **Neden:** oyuncu 18 sınıfın hiçbirini açmadan varsayılan sınıfla oyuna
  başlayabiliyordu ve bunu fark etmesinin bir yolu yoktu.

### GD32. Tanıtımdaki örnek ekipman ve saldırı animasyonu kararlı (2026-08-25)
- **Nerede:** `_showcaseEquipmentFor`, `_selectClass`
- **Karar:** tohumsuz `math.Random` yerine `stableSpread('<sınıf>|<kategori>')`.
  Aynı sınıf her açılışta aynı silahları ve aynı saldırı animasyonunu gösterir.
- **Neden:** (a) sınıfın kimlik kartı her açılışta değişince sınıf keyfî
  görünüyor, (b) proje kuralı — kimliğe dönüşen rastgelelik tohumlu olmalı
  (GD8/GD18), (c) golden ile doğrulanamıyordu.
- **Kaybedilen:** her açılışta yeni silah görme sürprizi. Karşılığında sınıf
  tanınabilir hâle geldi; takas bilinçli.

### GD33. Haptik geri bildirim artık beklenmiyor (2026-08-25)
- **Nerede:** `_goToStep`, `_complete`
- **Karar:** `await HapticFeedback…` → `HapticFeedback…` (bekleme yok).
- **Neden:** titreşim bir süstür; adım geçişini ve karakter kaydını ona
  bağlamak, kanal yanıt vermeyen cihazda sihirbazı kilitler. Widget testinde
  bu kilit birebir gözlendi. Aynı desen ekranın başka yerlerinde (`_selectClass`,
  `_dismissClassReveal`) zaten beklemesiz kullanılıyordu.

---
---

# Bölüm 2 — Macera ilerleme göstergeleri ✅ (2026-08-25)

## Teşhis: bar bozuk değildi, **yanlış şeyi ölçüyordu**

Sürenin altındaki çubuk `stepsThisRound / roundTargetSteps` hesaplıyordu —
matematiksel olarak **doğru**. Her round sıfırlanması bir hata değil, ölçtüğü
şeyin doğal sonucuydu. Yanlış hissettiren iki şey vardı:

1. Oyuncunun tek gördüğü ilerleme göstergesi buydu ve her round sıfırlanınca
   "kazandığım yolu kaybettim" izlenimi veriyordu.
2. Son roundun hedefi küçülüyor (1000 → ör. 165), yani çubuğun **ölçeği**
   roundlar arasında sessizce değişiyordu.

Ama aynı ekranda **gerçek bir hata** vardı (aşağıda).

## Değişiklik

| Konum | Önce | Sonra |
|---|---|---|
| Geri sayımın altı (ana) | round içi ilerleme, her round sıfırlanır | **macera ilerlemesi** `questSteps / stepGoal`, hiç sıfırlanmaz (10 px, `ValueKey('quest-progress-bar')`) |
| Ana barın altı (ikincil) | — | round içi ilerleme: 3 px ince çizgi + "Bu round: 200 / 1000 adım" (`ValueKey('round-progress-bar')`) |
| "Macera durumu" kartı | `StatBar('Adım İlerlemesi')` | `StatBar('Günlük Adım')` — dürüst etiket |

## Düzeltilen gerçek hatalar

### 1. "Adım İlerlemesi" barı yanlış değer gösteriyordu
`progress: widget.today.stepProgress` (günlük ilerleme) ama etiketi
`adventure.stepGoal` idi. Macera günün ortasında başlamışsa (`startingSteps > 0`)
bu bar macera ilerlemesini **olduğundan fazla** gösteriyor ve hemen üstündeki
"Canavar Canı" barıyla çelişiyordu — o `questSteps` kullanıyor.
Örnek: 3000 adım atmış oyuncu 2000 hedefli maceraya başlar, 500 adım atar;
bar "3500 / 2000" diyordu.

Çözüm: macera ilerlemesi artık geri sayım kartındaki ana barda; bu bar günlük
sayacı gösterip **günlük hedefle** etiketleniyor.

### 2. ⚠️ Macera seçmek günlük para tavanını sıfırlıyordu (ekonomi açığı)
`root_shell.dart:_selectAdventure` / `_chooseNewAdventure` yeni bir
`DailyProgress` kuruyor ama `coinsEarned` ve `xpEarned` alanlarını
**taşımıyordu**. `coinsEarned` günlük para tavanının sayacı olduğu için:

> Tavanı doldur → macera seç → sayaç 0 → tavan yeniden açılır → **günde
> sınırsız coin.**

Bu B1'in (macera seçmek günün adımlarını sıfırlıyordu) aynısı, bu sefer para
sayacında. Aynı satırlarda, aynı sebeple: kap nesnesi elle yeniden kuruluyor ve
bir alan unutuluyor.

Çözüm: iki alan da taşınıyor. **Testler düzeltme geri alınarak doğrulandı** —
üçü de kırmızıya dönüyor.

### 3. `StatBar` dar ekranda taşıyordu
`lib/widgets/stat_bar.dart` — `Icon + Text(label) + Spacer + Text(value)`.
İki metin de esnek olmadığı için uzun etiket + uzun değer satırı taşırıyordu
(390 dp'de 29 px, ölçüldü). Etiket artık `Expanded` + ellipsis; sayı asla
kırpılmıyor. Bu **paylaşılan** widget, düzeltme tüm ekranlara yarıyor.

### 4. "Zafer ödülü" satırı 320 dp'de taşıyordu
`adventure_screen.dart` — aynı desen, `Expanded` eklendi (55 px taşma).

### 5. ⚠️ Dar ekranda düşman oyuncunun üstüne biniyordu
Savaş sahnesindeki iki sprite kutusu sabit **210 px**'di. 320 dp'de sahne
genişliği ~256 px; iki kutu üst üste biniyor ve sonra çizilen düşman oyuncuyu
**tamamen örtüyordu** — golden'da oyuncu hiç görünmüyordu. Kutu genişliği artık
sahneden türetiliyor (`maxWidth + 8 - 110`, 120–210 arası kırpılı), iki figürün
merkezleri arasında en az 110 px kalıyor. 390 dp ve üstünde görüntü değişmedi.

## Test

`test/adventure_progress_test.dart` — 13 test:
- ana barın macera ilerlemesini göstermesi, `startingSteps`'in düşülmesi,
  **round sınırında sıfırlanmaması**, macera bitince dolması,
- round çubuğunun ikincil (daha ince) olması ve round içi ilerlemeyi
  göstermesi — aynı anda ana barın devam ediyor olması,
- "Günlük Adım" barının dürüst etiketi (eski hatanın regresyonu),
- **iki golden** (320/390 dp),
- macera seçmenin ve bırakmanın günlük kazanç sayaçlarını koruması + **tavanın
  macera seçilerek aşılamaması**.

Toplam **453 test geçiyor**, `flutter analyze` temiz.

---

### GD34. Ana ilerleme göstergesi macera, ikincil gösterge round (2026-08-25)
- **Nerede:** `adventure_screen.dart:_buildCountdownCard`
- **Karar:** kalın bar macera ilerlemesi (`questSteps / stepGoal`), ince çizgi
  round ilerlemesi. Round bilgisi kaybolmadı, ana gösterge olmaktan çıktı.
- **Neden:** oyuncunun cevaplaması gereken birinci soru "maceranın neresindeyim";
  "bu roundu tutturur muyum" ikinci soru. Her round sıfırlanan tek bir bar
  birinci soruyu görünmez kılıyordu.
- **Geri dönülecek nokta:** Aşama 4a savaş motoru round kavramını değiştirirse
  ikincil çizginin ölçeği yeniden düşünülmeli. İki barın `ValueKey`'i var,
  testler ikisini de ayrı ayrı bağlıyor.

### GD35. Sprite kutusu genişliği sahneden türetiliyor (2026-08-25)
- **Nerede:** `adventure_screen.dart` savaş sahnesi `LayoutBuilder`
- **Karar:** sabit 210 px yerine `(maxWidth + 8 - 110).clamp(120, 210)`.
- **Neden:** 320 dp'de düşman oyuncuyu tamamen örtüyordu. Sabit piksel
  yerleşim, sahne genişliği değişkenken çalışmıyor.
- **Kabul edilen takas:** dar ekranda figürler biraz küçülüyor. İkisinin de
  görünmesi, ikisinin de büyük olmasından önemli.
- **Not:** bu arkadaşımın kodu; "varsayılan dokunma" kuralına rağmen
  düzeltildi çünkü **gerçek bir görsel hata** (oyuncu görünmüyor).

### GD36. Sınıf imzası artık her itemde değil, dağılımda okunuyor (2026-08-25)
- **Nerede:** `item_rules.dart:economyTypeOrder` / `_classSignature`,
  `data/item_archetypes.dart`
- **Sorun:** buff türetmesi item'ın **kendi kimliğini hiç kullanmıyordu.**
  `buildItemFromAsset` `buffFor(rarity, category)` çağırıyordu — `id`
  parametresi varsayılan `''` kalıyordu. Sıradan itemde tek bonus vardı ve
  bonus listesinin ilk elemanı **her zaman** sınıfın imzasıydı. Sonuç: bir
  sınıfın bütün sıradan kılıçları birebir aynı bonusu veriyordu; oyuncunun
  seçimi "hangisi daha güzel görünüyor"dan ibaretti.
- **Karar:** ekonomi bonusu türleri artık **ağırlıklı, tekrarsız ve kararlı
  bir çekilişten** geliyor. Sınıf imzası +8, kategori rolünün ilk üç eğilimi
  +4/+2/+1, her tür +1 taban ağırlık taşıyor. Tohum: item kimliği + sınıf.
- **Eski invariant düştü:** "her sınıfın imzası ayrı ve her itemde bulunur".
  18 oynanabilir sınıf ve sekiz bonus türüyle bu **matematiksel olarak
  imkânsız**; test sekiz **ölü** sınıfa baktığı için yanlışlıkla geçiyordu
  (bkz. GD37). Yerine iki ölçülebilir kural geldi:
  1. imza, sınıfın gördüğü katalogda **en sık** birincil bonus olmalı
     (ölçülen: %25–%75 bandı; gerçek değerler %34–%50),
  2. hiçbir bonus türü sahipsiz kalmamalı, hiçbiri üçten fazla sınıfa imza
     olmamalı.
- **İmzalar yeniden dağıtıldı.** Eski haritada `wheelXp` **hiçbir oynanabilir
  sınıfın** imzası değildi (tek sahibi emekliye ayrılmış Necromancer'dı) ve
  beş sınıf `enemyXp` paylaşıyordu. Yeni dağılım: sekiz türün her biri iki ya
  da üç sınıfın imzası. Eski (yalnızca kayıtlarda geçen) sınıfların imzaları
  **değiştirilmedi** — güncelleme sonrası eski bir kaydın itemleri sessizce
  başka bir bonusa kaymamalı.
- **Ölçülen sonuç:** aynı sınıf + aynı kategori + aynı nadirlikteki en kötü
  grup, 14 itemde 7 farklı buff (en sık kalıp %43). Öncesinde her grup
  **tek** kalıptı.

### GD37. Item↔sınıf dağılımı canlı sınıf listesinden doğrulanıyor (2026-08-25)
- **Nerede:** `AvatarProfile.playableClassIds`, `test/item_catalog_test.dart`,
  `test/item_effects_test.dart`, `test/equipped_buffs_test.dart`,
  `ItemCategoryX.characterClasses`
- **Sorun:** üç test dosyası da elle yazılmış sekiz sınıflık bir liste
  (`Archer, DarkMagic, Faith, Magic, Nature, Paladin, SwordMan, Thief`)
  kullanıyordu. Karakterler `All_Assets`'e taşınınca bu sekizi **oynanamaz**
  hâle geldi; testler ölü sınıfları doğrulayıp gerçek 18 sınıfın hiçbirini
  denetlemiyordu.
- **Karar:** liste `AvatarProfile.playableClassIds` üzerinden tek kaynaktan
  okunuyor (`classLabels` eksi emekliler eksi eski kimlikler = 18).
- **Ortaya çıkan iki gerçek ihlal düzeltildi:**
  - *Mezar Okçusu* 143 item görüyordu (alt sınır 150) → **tırpanlar** eklendi
    (158). Ölümün aleti, ölü bir okçuya tematik olarak düşüyor.
  - *Ayı Ruhlu* 105 item görüyordu → **kalkanlar** eklendi (217). Ağır bir
    savaşçının doğal ekipmanı.
- **Sınırların dışında kalan yok:** en geniş sınıf (Sınır Muhafızı, 408 item)
  kataloğun %52'sini görüyor; testin üst sınırı %60.

### GD38. Kuraldan türeyen itemler de savaş statı taşıyor (2026-08-25)
- **Nerede:** `data/item_archetypes.dart`, `item_rules.dart:_combatEffects`
- **Karar:** her item bir **arketip** taşıyor (Vurucu / Muhafız / Düellocu /
  Çevik) ve arketip ona savaş statları veriyor. Nadirlik başına toplam etki
  sayısı 1/2/2/3/3'ten **2/3/4/5/6**'ya çıktı; ek satırların hepsi savaş
  statı.
- **Neden ekonomi büyümedi:** ekonomi bütçesi arketipe göre **yalnızca
  küçülüyor** (`economyTilt` en fazla 1.0: vurucu 0.85, düellocu 0.90,
  muhafız/çevik 1.00). Savaş bütçesi ise büyüyor (1.20 / 1.10 / 1.00 / 0.95).
  Aynı güç bütçesi farklı dağılıyor; `economy_pacing_test.dart` ve dört
  ekonomi tavanı olduğu gibi geçerli.
- **Neden savaş tarafında cömert olundu:** GD24 — savaş motoru Aşama 4a'da
  geliyor, bugün o sayıların hiçbir etkisi yok. Yine de kuraldan türeyen
  hiçbir item elle tasarlanmış (imzalı) itemlerin savaş gücünü geçemiyor;
  testle bağlı.
- **Rol kısıtı korundu ama gevşetildi:** dört arketip de her rolde çıkabiliyor,
  yalnızca sıklıkları farklı (kalkanların %40'ından fazlası muhafız). İlk
  tasarımda menzil çarkında muhafız yoktu ve sıradan menzilli itemler yalnızca
  üç farklı savaş statı üretebiliyordu — çeşitlilik ölçümü bunu yakaladı.
- **İmzalı itemlerin arketipi uydurulmuyor:** taşıdıkları savaş statlarından
  okunuyor (`archetypeFromEffects`), yoksa "Vurucu" yazan bir kalkan
  çıkabilirdi.
- **Mağaza kartında satır sayısı kısıtı kalktı:** GD12'nin sabit yüksekliği K9
  ile esnek satıra dönmüştü; altı ekran genişliğindeki taşma testleri hâlâ
  geçiyor.

### GD39. Envanter kimlik listesinden **örnek** listesine geçti (2026-08-25)
- **Nerede:** `models/owned_item.dart` (yeni), `UserProfile.ownedItems` /
  `ownedUpgradeIds` / `nextItemInstanceId`, `GameStorage` şema **v12**
- **Karar:** `List<String> ownedItemIds` → `List<OwnedItem>`; her örnek
  `{instanceId, itemId, level, rarity, equipped}` taşıyor.
- **Neden `instanceId` var (şartnamede yoktu):** aynı eşyadan üç adet varsa
  "hangisini yükselt / sat / kuşan" sorusunun bir cevabı olmalı. Liste indeksi
  kullanılamazdı: envanter ekranı her çizimde durumu yeniden okuyor (GD27) ve
  indeks aradaki bir değişiklikte kayabilir. Kimlik kalıcı bir sayaçtan
  geliyor — rastgele değil, tohum gerektirmiyor, kayıt tekrarlanabilir.
- **Neden `rarity` nullable:** `null` = "katalog nadirliği". Taşıma anında
  `AssetManifest` okunamıyor, dolayısıyla v11 kayıtlarına katalog nadirliği
  yazılamazdı. Yan fayda: katalog nadirliği ileride dengelenirse
  birleştirilmemiş örnekler onu izliyor.
- **İki namespace ayrıldı.** `ownedItemIds` hem katalog itemlerini hem mağaza
  yükseltmelerini (`boost_double_xp`) taşıyordu. Ayrımı **kimliğin biçimi**
  yapıyor: katalog kimlikleri her zaman `<kategori>/<dosya>`, yükseltme
  kimlikleri hiç `/` içermiyor. Taşıma katalogsuz ve güvenilir.
- **⚠️ ZİNCİRLEME SONUÇ — mağaza aynı eşyayı tekrar satıyor.** Birleştirme
  aynı eşyadan birkaç adet istiyor; ikinci satın alma artık reddedilmiyor,
  gerçekten ikinci bir örnek veriyor. Kart "Sahipsin" yerine **"N adet"**
  gösteriyor ve düğme açık kalıyor.
  - **GD14 güncellendi:** "Alabileceklerim" süzgeci sahipliğe artık
    bakmıyor — sahip olduğun eşya da "bugün alabileceklerim" listesine ait.
  - **GD26 kısmen taşındı:** "slot başına tek eşya" kuralını `Map` yapısı
    veri düzeyinde zorluyordu. Örnek listesinde bu garanti yok; kural
    `RootShell._refreshEquipment` içinde normalleştiriliyor ve testle bağlı.
  - Kırılan dört test **güncellendi, silinmedi** (davranış bilerek değişti).
- **Şema v12 taşıması veri kaybetmiyor:** her kimlik seviye 1 + katalog
  nadirliğiyle örneğe dönüşüyor, kuşanılı olanlar kuşanılı kalıyor,
  yükseltmeler ayrı listeye gidiyor. Sayaç kayıttaki en büyük kimliğin
  altına düşemiyor — yoksa sonraki satın alma var olan bir örneğin kimliğini
  yeniden kullanırdı.

### GD40. Nadirlik yükselince seviye kilidi **değişmez** (2026-08-25)
- **Nerede:** `item_rules.dart:withRarity`
- **Karar:** birleştirmeyle bir üst nadirliğe çıkan bir örneğin
  `requiredLevel` değeri **korunuyor**; yalnızca buff ve fiyat yeni nadirlikten
  hesaplanıyor.
- **Neden:** üç sıradan eşyayı (kilit Sv. 1–3) birleştiren oyuncunun elinde
  birden Sv. 4–7 kilitli bir eşya kalırdı ve kuşanamazdı. Emek verip
  birleştirdiği şeyin kullanılamaz hâle gelmesi cezalandırıcı; birleştirme bir
  ödül olmalı.
- **Fiyat neden yeni nadirlikten:** satış değeri fiyata bağlı; birleştirilmiş
  bir eşyanın hâlâ sıradan fiyatından değerlenmesi yatırımı yok sayardı.
  Alım-satım döngüsünün para üretemediği ayrıca testle bağlı.
- **İmzalı itemler karakterini koruyor** (GD22): elle yazılmış etkileri
  yeniden türetilmiyor, nadirlik bütçesi oranında ölçekleniyor. Ekonomi
  oranları yine tek item tavanına kırpılıyor.

### GD41. Yükseltme yalnızca **savaş** statlarını büyütür (2026-08-25)
- **Nerede:** `core/utils/item_leveling.dart:scaleForLevel`,
  `GameConstants.itemStatGrowthPerLevel`
- **Karar:** eşya seviyesi savaş statlarını seviye başına **+%10** büyütüyor
  (Sv. 1 = ×1.00, Sv. 10 = ×1.90, Sv. 50 = ×5.90). **Ekonomi bonusları
  (adım→para, adım→XP, çark XP, düşman XP, tavanlar, seri eşiği) sabit
  kalıyor.**
- **Neden:** ekonomi dikkatle dengelendi (`economy_pacing_test.dart` ve dört
  tavan). Çarpanlar eşya seviyesiyle büyüseydi günlük coin tavanı katlanır ve
  denge çökerdi. Kural `scaleForLevel` içinde **kodla** zorlanıyor
  (`stat.isCombat` olmayan her etki olduğu gibi geçiyor) ve iki ayrı testle
  bağlı.
- **Çift etkili itemlerin bedeli de büyüyor:** yükselen bir eşyanın hem gücü
  hem bedeli artıyor, yoksa dezavantaj seviyeyle erirdi.
- **İki tavan birden geçerli:** nadirlik tavanı (10/20/30/40/50) ve oyuncunun
  kendi seviyesi. Hangisinin bağladığı kullanıcıya **ayrı ayrı** söyleniyor
  (Model Kuralları #4); "yükseltilemiyor" tek başına bir cevap değil.
- **Maliyet eğrisi tek sayıdan:** 1'den tavana çıkarmak eşya fiyatının
  **7 katı**. Bir seviyenin payı `0.5 + seviye / tavan`; ağırlıkların toplamı
  tam olarak `tavan − 1` ettiği için toplam oranla birebir tutuyor. Ölçüm
  tablosu aşağıda, `item_leveling_test.dart` ile bağlı.

### GD42. Birleştirmenin sonucu Sv. 1'e döner (2026-08-25)
- **Nerede:** `RootShell._mergeItems`, `item_merging.dart:selectMergeInstances`
- **Karar:** N örnek + coin → 1 örnek, bir üst nadirlikte ve **Sv. 1**.
- **Neden en yüksek seviye korunmuyor:** korunsaydı "üç eşyayı yükselt, sonra
  birleştir" her zaman baskın strateji olurdu — ucuz katmanda kazanılan
  seviyeler pahalı katmana taşınır, seviye maliyet eğrisi (GD41) anlamını
  yitirirdi. Nadirlik birleştirmeden, seviye coinden gelmeli; iki sistem
  birbirini beslememeli.
- **Sertliği dengeleyen karar:** tüketilecek örnekler **otomatik olarak en
  düşük seviyeliden** seçiliyor ve kuşanılı olanlar en sona atılıyor. Dört
  adedi olan oyuncu birleştirdiğinde Sv. 9 olan elinde kalıyor, Sv. 1'ler
  yanıyor. Pratikte oyuncu bir adedi yükseltip yedekleri Sv. 1'de tutuyor,
  yani yatırım korunuyor. Testle bağlı.
- **Onay ekranı harcanacak seviyeleri tek tek yazıyor** ve "geri alınamaz"
  diyor; kuşanılı bir adet harcanacaksa bu da önceden söyleniyor.

### GD43. Birleştirme ücreti hedef nadirliğin fiyatının %50'si (2026-08-25)
- **Nerede:** `GameConstants.itemMergeCostRatio`, `item_merging.dart`
- **Ölçüm:** birleştirerek bir eşyaya sahip olmak, aynı nadirlikteki bir
  eşyayı doğrudan satın almanın **~2 katına** mal oluyor (test bunu bağlıyor).

| Geçiş | Adet | Ücret | Toplam | Doğrudan alım |
|---|---|---|---|---|
| Sıradan → Az Bulunur | 3 | 150 | 450 | 325 |
| Az Bulunur → Nadir | 4 | 350 | 1.650 | 825 |
| Nadir → Epik | 5 | 1.050 | 5.175 | 2.600 |
| Epik → Efsanevi | 6 | 3.325 | 18.925 | 8.450 |

- **Neden pahalı olmalı:** birleştirmenin iki kalıcı avantajı var —
  **(1)** seviye kilidi değişmiyor (GD40), yani erişemeyeceğin bir nadirliği
  erken kuşanabiliyorsun; **(2)** nadirlik tavanı yükseldiği için eşya çok
  daha ileri yükseltilebiliyor. Ücretsiz olsaydı mağaza anlamını yitirirdi.
- **Neden imkânsız olmamalı:** gereken adet zaten kendi başına bir sürtünme
  (aynı eşyayı 3–6 kez almak ya da çarktan toplamak). Ücret o sürtünmenin
  üstüne ikinci bir duvar örmemeli.
- **Alım-satım-birleştirme döngüsü para üretmiyor:** sonuçtaki örneğin satış
  değeri (%40) harcanan toplamın altında; testle bağlı.

---
---
---

### GD49. Düşman canı adımdan koparıldı; `stepGoal` artık yalnızca yürüyüş taahhüdü (2026-08-26)
- **Nerede:** `models/adventure_quest.dart` (`enemyHealth`, `isEnemyDefeated`),
  `models/enemy.dart` (`stats`)
- **Karar:** düşmanın canı kendi statı (`Enemy.stats.maxHealth`). `stepGoal`
  üç işten ikisini bıraktı: artık yalnızca **round hedefini** ve beklenen
  round sayısını belirliyor; düşman canı ve kilit eşiği ondan gelmiyor.
  Triaj **A2** ve **A3** böylece kapandı.
- **Neden:** "her adım 1 hasar" modelinde saldırı, savunma, kritik gibi hiçbir
  statın girecek yeri yoktu — 15 statın 9'u tanımlıydı ama okunmuyordu.
- **Zincirleme sonuç — kilitlenme kapatıldı:** adım hedefi bitip düşman hâlâ
  ayaktaysa round hedefi **tam boya** dönüyor (`_nextRoundTarget`). Eski
  formül 0 döndürüyordu ve round çözülemeyeceği için savaş kilitlenirdi.
- **Yan fayda:** güçlü oyuncu düşmanı adım hedefinden **önce** deviriyor. Bu,
  Bölüm 8'in yürüyüş fazının zemini — testle bağlandı.
- **Kabul edilen takas:** oyuncu hedefi bitirdiği hâlde düşmanı devirememiş
  olabilir. Savaş, taraflardan biri düşene kadar sürüyor; "adımı bitirdim ama
  kazanamadım" durumu bir çıkmaz değil, devam eden bir dövüş.

### GD50. Savaş motoru saf, deterministik ve tohumu saklanan (2026-08-26)
- **Nerede:** `core/utils/combat_engine.dart`, `AdventureQuest.combatSeed`
- **Karar:** motorda `Random()` **yok**; rastgeleliğin tamamı dışarıdan
  verilen tohumdan geliyor ve tohum sonuçla birlikte geri dönüyor. Tohum
  macera durumuyla diske yazılıyor.
- **Neden:** CLAUDE.md §4.4 — aynı motor Aşama 6b'de sunucuda çalışacak.
  Deterministik olmayan bir motoru sonradan deterministik yapmak, motoru
  yeniden yazmakla aynı şey.
- **Ayrı akış:** `nextCombatSeed` çark ve seri bonusuyla aynı LCG ama **ayrı**
  sayaç. Paylaşsalardı oyuncu çarkı çevirerek savaşın zarını kaydırabilirdi.
- **Yedek tohum deterministik:** tohum kurulmadan round çözülürse
  `fallbackCombatSeed(enemyId, startingSteps)` devreye giriyor —
  `stableSpread`, `String.hashCode` değil (GD8).

### GD51. Düşman statları kademe + arketipten türetiliyor (2026-08-26)
- **Nerede:** `core/utils/enemy_stats.dart`, `Enemy.archetype`
- **Karar:** 20 düşmana elle 9'ar stat yazılmadı. Elle verilen tek şey
  **arketip** (Dengeli / Dayanıklı / Çevik / Büyücü); can, saldırı, savunma,
  hız, kritik ve sıyrılma kademeden ve arketipten çıkıyor. Item kataloğunda
  aynı karar GD7'de verilmişti.
- **İki hedef sayı:**
  1. **Can** = o kademeye denk seviyedeki ölçüt oyuncunun round başına
     hasarı × beklenen round sayısı. Yani kilit eşiğini seçen ölçüt oyuncu
     maceranın sonunda devirir, güçlü oyuncu erken.
  2. **Saldırı** = tamamen kaçırılan bir roundun oyuncu canının
     [missedRoundHealthCost] (%15) kadarını götürmesi. Ölçülen: her kademede
     hiç yürümeyen oyuncu 4–12 round içinde düşüyor (hedef ~7).
- **Katalogdaki elle yazılmış `attackDamage` korundu:** kademenin doğrusal
  beklentisine oranlanıp çarpan olarak uygulanıyor. Tasarımcının bilerek
  zayıf bıraktığı düşman (13. kademedeki Eyeball Monster, 12 yerine 20
  beklenirdi) zayıf kalıyor — testle bağlı.
- **Ölçülen sonuç:** ölçüt oyuncu her düşmanı beklenen round + 3 içinde
  deviriyor; dayanıklı arketip uzatıyor, cam top kısaltıyor. Tam tamamlanan
  roundda hiçbir kademede hasar alınmıyor.

### GD52. `speed` ve `luck` eklendi ama itemler henüz vermiyor (2026-08-26)
- **Nerede:** `ItemStat.speed`, `ItemStat.luck`
- **Karar:** iki yeni savaş statı eklendi (inisiyatif ve şans). Kaynakları
  **taban stat, düşman statları ve seri bonusu**; item arketip tablolarına
  eklenmedi.
- **Neden:** arketip tablolarına eklemek 784 item'ın buff çekilişini yeniden
  yapardı ve Bölüm 3/4'te ölçülmüş dengeyi (`item_variety_test`,
  `economy_pacing_test`, mağaza goldenları) geçersiz kılardı. İki stat da
  savaşta gerçekten iş yapıyor, süs değil: hız inisiyatifi belirliyor, şans
  kritik/sıyrılma ihtimalini ve hasar bandını kaydırıyor.
- **Yan etki (bilinçli):** `StreakStatBonuses.pool` `isCombat`'tan türediği
  için 7'den **9**'a çıktı. Toplam tavan hâlâ bağlayıcı (9 × %25 = %225 >
  %100) ve eski kayıtlar stat adıyla saklandığı için bozulmuyor.
- **Geri dönülecek nokta:** ayrı bir denge geçişinde arketiplere eklenebilir;
  `item_archetypes.dart` tek yer.

### GD53. Oyuncunun savaş canı sabit 100 olmaktan çıktı (2026-08-26)
- **Nerede:** `AdventureQuest.playerMaxHealth`, `RootShell._syncAdventureStats`
- **Karar:** can tavanı seviyeden ve kuşanmadan geliyor
  (`effectiveCombatStats`). Macera nesnesinde tutuluyor; `RootShell` seviye
  atlandığında ve kuşanma değiştiğinde tazeliyor, mevcut can tavanı aşamıyor.
- **Bedava iyileşme yok:** tavan büyüyünce mevcut can **yükselmiyor**, yalnızca
  tavan küçülürse kırpılıyor. Aksi hâlde seviye atlamak ya da eşya takıp
  çıkarmak savaş ortasında tam iyileşme verirdi.
- **B2'nin açık yarısı kapandı:** savaş canının tek kaynağı artık
  `AdventureQuest`. `UserProfile.hp` / `maxHp` hâlâ persist **edilmiyor** ve
  hiçbir savaş yolunda okunmuyor.

### GD54. `onKill` etkileri bitirici vuruşa katılıyor (2026-08-26)
- **Nerede:** `combat_engine.dart` — bitirici vuruş bloğu ve `killHeal`
- **Sorun:** katalogdaki `onKill` etkilerinin bir kısmı "düşman yenince bir
  sonraki tur +%28 saldırı" diyor. Savaş düşman ölünce bittiği için
  uygulanacak "sonraki tur" yok — etki ölü kalırdı.
- **Karar:** iki dal:
  - `lifeSteal` / `maxHealth` statlı `onKill` etkileri **öldürme anında
    iyileştiriyor** ("kaybettiğin canın %35'i geri gelir" sözü birebir).
  - Diğer `onKill` etkileri **bitirici vuruşa** katılıyor: normal hasar
    yetmiyor ama bonusla yetiyorsa bonus devreye giriyor ve vuruş öldürücü
    oluyor. Öldürmeyeceği turda hasarı **büyütmüyor** — koşulsuz bir saldırı
    bonusuna dönüşmesin diye; testle bağlı.
- **Neden veri değiştirilmedi:** etkiler `item_effects.dart` içinde tasarım
  verisi. Sözü tutulur hâle getirmek, sözü değiştirmekten yeğ.

### GD55. Macera iki fazlı; faz durumdan türetiliyor, ayrı bir alan değil (2026-08-26)
- **Nerede:** `models/adventure_quest.dart` — `victorySteps`, `walkSteps`,
  `AdventureQuestPhase`
- **Karar:** düşman devrilince macera **bitmiyor**; adım taahhüdü dolana kadar
  bir **yürüyüş fazı** sürüyor. Faz için kalıcı bir bayrak yok: zaferin
  geldiği nokta (`victorySteps`) damgalanıyor, yürüyüş hedefi ondan türüyor
  (`stepGoal - victorySteps`), ilerleme `walkSteps` ile birikiyor.
- **Neden ayrı bayrak yok:** iki doğruluk kaynağı, er ya da geç çelişir.
  `battleOutcome` zaten otoriter durum; faz onun ve yürüyüş ilerlemesinin
  **türevi**. `AdventureQuestPhase` bu yüzden sunum enumu, kalıcı alan değil.
- **Neden `revivalSteps` deseni:** arkadaşımın Hayat Yürüyüşü aynı şekli
  kuruyor (hedef türetilir, ilerleme kalıcı, ekleme kabul edileni döner).
  İkinci bir desen uydurmak yerine olanı izledim (Kural 1/3).
- **Eski kayıt yürüyüş fazına geriye dönük sokulmuyor:** damgası olmayan
  zaferli kayıtta `victorySteps = stepGoal` kurulur → yürüyüş hedefi 0,
  çarpan ×1. Tamamlanmış bir macerayı güncelleme sonrası yeniden açmak,
  oyuncunun bitirdiği işi geri almak olurdu.
- **Zafer kutlaması bir kez oynar:** `deathAnimationPlayed && isWalkPhaseActive`
  ise ekran doğrudan yürüyüş sahnesine düşer. Aksi hâlde oyuncu Macera
  sekmesine her dönüşünde aynı kutlamayla karşılaşıp yürüyüşe geçemezdi.
- **Geri dönülecek nokta:** gün değişiminde macera hâlâ düşüyor (Aşama 0'ın
  açık notu). Yürüyüş fazı harcanan adımı artık daha görünür kıldığı için o
  telafi kararı bir sonraki turda ele alınmalı.

### GD56. Hız ödülü **adımla** ölçülüyor, roundla değil (2026-08-26)
- **Nerede:** `AdventureQuest.speedRewardMultiplier`,
  `GameConstants.maxVictorySpeedMultiplier`
- **Karar:** çarpan = `1 + (1 - victorySteps/stepGoal) × (tavan - 1)`, tavan
  **×2**. Tam hedefte devirmek ×1, hiç adım harcamadan devirmek ×2.
- **Neden round değil:**
  1. Round sayısı kaba. 500 adımlık hedefte `totalRounds` **1**; round
     ölçüsüyle o hedefte hız ödülü hiç oluşamazdı.
  2. Yürüyüş fazı zaten adımla tanımlı. Aynı büyüklüğün iki sistemi birden
     sürmesi ilişkiyi tutarlı kılıyor: **harcamadığın her adım hem çarpana
     hem bonuslu yürüyüşe yazılıyor.**
  3. "Beklersem bedava çarpan alırım" kaçamağı yok: savaş motoru verilen
     hasarı round tamamlanma oranıyla ölçekliyor, yani yürümeden düşman
     devrilmiyor. Dört round idle geçirip beşincide devirmek can pahasına
     olur ve yürüyüş fazını kısaltmaz.
- **Hem XP'ye hem altına uygulanıyor.** Çarpanın işi hızlı zaferi
  hissettirmek; tek ödüle uygulanınca etkisi yarıya iner. Risk ikisinde de
  sınırlı: XP'nin harcanacağı yer yok (projenin kendi gerekçesi), altın
  tarafında çarpan yalnızca **kademe bazlı zafer damlasına** biniyor (en üst
  kademede ~130 coin), adım parasına değil.
- **Gösterim şart:** görünmeyen çarpan kural değil, sürprizdir. Zafer
  ekranında ve yürüyüş kartında "N round · M adım — hız ödülü ×1.8" yazıyor.

### GD57. Zafer altını tohumlu oldu (E1 düzeltmesi) (2026-08-26)
- **Nerede:** `AdventureQuest.victoryCoinRoll`
- **Sorun:** `root_shell.dart` kademe bazlı zafer altınını tohumsuz `Random()`
  ile atıyordu. Kalıcı bir ödülü (`victoryCoinReward` diske yazılıyor, coin
  profile ekleniyor) etkileyen rastgelelik CLAUDE.md §4.4 / GD18 / GD50 gereği
  tohumlu olmalı. `xpAwarded` kapısı yeniden zar atmayı engellediği için
  sömürülebilir değildi, ama **test edilemezdi** ve A.2 bu ödülü hız
  çarpanıyla çarpacağı için önce sağlama alınması gerekti.
- **Karar:** çekiliş `stableSpread('victory-coins|<düşman>|<başlangıçAdımı>|<hedef>')`
  üzerinden. Deterministik, macera başına farklı, sürümler arası sabit.
  `String.hashCode` **kullanılmadı** (GD8).

### GD58. Yürüyüş fazı oranı 30/1; para hesabı iki geçişli (2026-08-26)
- **Nerede:** `GameConstants.walkPhaseStepsPerCoin`,
  `calculateStepCoins(stepsPerCoin:)`, `root_shell.dart:_onStepsReported`
- **Karar:** yürüyüş fazı boyunca **30 adım = 1 altın**; faz bitince oran
  `stepsPerCoin` (50) değerine döner. XP oranı **değişmiyor**.
- **Neden yalnızca coin:** iki kaldıracı birden oynatmak dengeyi ölçülemez
  hâle getirir. XP eğrisi Aşama 2b'de ayrıca gerekçelendirilmiş ve
  `step_xp_test.dart` ile bağlı (15/9 günlük ulaşma süreleri testli).
- **İki geçiş, çünkü bir parti faz sınırını geçebilir:** önce bonuslu payı
  (`min(bekleyen, kabul edilen yürüyüş adımı)`) 30/1 ile, sonra kalanı 50/1
  ile. İşaretçi her geçişte yalnızca **tüketilen** adım kadar ilerlediği için
  çift sayma yok; bir coin'e yetmeyen artık adım (en fazla 29) sonraki
  hesaba devreder. 5.000 adımlık bir parti 1.000 adımlık yürüyüş hedefine
  denk gelirse: 33 + 80 = 113 coin, tüketilen 4.990, devreden 10 — testle
  bağlı.
- **Adımlar paradan **önce** yürüyüş fazına yazılıyor**, ki hesap bu partinin
  kaçının bonuslu olduğunu bilsin. Düşmanın devrildiği partide bu değer 0'dır
  (round çözümü paradan sonra çalışıyor) — yani **savaş adımı bonus almaz**,
  doğru olan da bu.

#### Ekonomi ölçümü (A.3)

⚠️ **Günlük 400 coin tavanı artık yok.** Arkadaşım `a3569a0` ile kaldırdı
(`coin_calculator.dart`, `DailyProgress.coinCapReached` → `false`,
`ItemStat.dailyCoinCap` emekliye ayrıldı). Ölçüm bu yüzden **tavansız gerçek
ekonomiye** göre yapıldı; tavan geri getirilmedi (Kural 7).

Günde **bir** macera varsayımıyla, teorik en iyi durum (düşman hiç adım
harcanmadan devriliyor, yani hedefin tamamı yürüyüş fazı):

| Günlük adım | Taban coin | 2.000'lik hedef | 5.000'lik hedef | 10.000'lik hedef |
|---|---|---|---|---|
| 3.000 | 60 | 86 (+26) | — | — |
| 6.000 (referans) | 120 | **146 (+26)** | 186 (+66) | — |
| 10.000 | 200 | 226 (+26) | 266 (+66) | 333 (+133) |
| 20.000 | 400 | 426 (+26) | 466 (+66) | 533 (+133) |

Gerçekçi durum (düşman hedefin ~%40'ında devriliyor, yürüyüş fazı hedefin
%60'ı):

| Günlük adım | Hedef | Coin | Sapma |
|---|---|---|---|
| 6.000 | 2.000 | 136 | **+%13** |
| 6.000 | 5.000 | 160 | +%33 |
| 10.000 | 10.000 | 280 | +%40 |
| 20.000 | 10.000 | 480 | +%20 |

**Karar: 30/1 korundu, faz uzunluğu ayarlanmadı.** Gerekçe:
- Referans oyuncunun sapması **+%13** — 120 coin/gün dengesi ayakta.
- Kazanç **yapısal olarak sınırlı**: bir maceranın verebileceği ek coin en
  fazla `stepGoal × (1/30 − 1/50) = stepGoal/75`. Yürüyüş hedefi, savaş ne
  kadar uzun sürerse o kadar küçülür — yani kazanç kendi kendini frenler.
- Ek kazanç bir düşman devirmeyi gerektiriyor; bedava değil.
- Tavansız ekonomide oyuncular arası doğal fark (60 ↔ 400 coin/gün) bu
  sapmanın kat kat üstünde.

**Geri dönülecek nokta:** günde birden çok macera tamamlamak mümkün olduğu
için, ekonomi ileride sıkılaştırılacaksa ilk bakılacak yer "gün başına kaç
macera yürüyüş bonusu alabilir" sorusudur. Bugün sınır yok.

### GD59. Seri ve çark **iki kapıdan** açılıyor: zafer ya da adım eşiği (2026-08-26)
- **Nerede:** `DailyProgress.enemyDefeated` / `isWheelUnlocked`,
  `root_shell.dart:_onStepsReported`
- **Karar (A.6):** bir düşman devirmek günlük seriyi güvenceye alır **ve**
  çarkı açar. Mevcut adım eşikleri (`streakStepThreshold` 2.000,
  `dailyWheelUnlockSteps` 3.000) **kaldırılmadı**; hangisi önce gelirse o
  açar.
- **Neden eşikler kaldırılmadı** (CLAUDE.md Bölüm 5a/5b "adım eşiği tamamen
  kalksın" diyordu):
  1. Macera oynamayan ama gerçekten yürüyen oyuncu cezalanmamalı. Serinin
     amacı alışkanlık; onu tek bir oyun moduna kilitlemek dar bir kural.
  2. `ItemStat.streakRelief` buff'ı eşiğe bağlı. Eşik kalksaydı bu tür ölü
     kalır ve GD36'nın "boşta bonus türü kalmasın" invariantı kırılırdı —
     ya da türün yeniden anlamlandırılması Bölüm A'nın kapsamını şişirirdi.
  3. 66 mevcut seri testi eşiğe dayanıyor; ikinci bir kapı eklemek hiçbirini
     kırmıyor, eşiği kaldırmak hepsini yeniden yazdırırdı.
- **Zafer bayrağı `DailyProgress` üzerinde**, yani gün değişince kendiliğinden
  sıfırlanıyor — ayrı bir sıfırlama koduna gerek yok.
- **Macera değiştirmek bayrağı yakmıyor:** `_selectAdventure` /
  `_chooseNewAdventure` `enemyDefeated`'i de taşıyor. Aksi hâlde bugün
  kazanılmış bir seri ve açılmış bir çark, yeni macera seçilince geri
  alınırdı — B1 ve "günlük tavan sıfırlanıyor" hatalarının tam olarak aynı
  sınıfı.
- **Yürüyüş fazı zorunlu değil:** streak zaferde güvenceye alınır, yürüyüş
  bonustur. Oyuncuyu hedefin tamamını yürümeye mecbur bırakmak seriyi
  kırılgan yapardı. Arayüz bunu açıkça söylüyor ("Serin ve çark hakkın bu
  zaferle güvence altında").
- **Eğitim zaferi de gerçek zafer sayılıyor:** eğitimin son durağı çark;
  kilitli bir çarkla karşılaşmamalı.

### GD60. Yürüyüş fazının kendi sahnesi var; savaş sahnesine dokunulmadı (2026-08-26)
- **Nerede:** `adventure_screen.dart` — `_buildWalkPhase`, `_WalkPhaseScene`
- **Karar (A.4):** yürüyüş fazı savaş ekranını paylaşmıyor. Düşman sahneden
  çıkıyor, karakter `_Walk.gif` ile sahnede yürüyor, üstte "YÜRÜYÜŞ FAZI"
  şeridi var, kartlar savaş yerine kalan taahhüdü ve bonuslu oranı anlatıyor.
  Arkadaşımın savaş sahnesine **hiç dokunulmadı** (Kural 7).
- **Karakter sahneden çıkmıyor:** uçtan uca gidip geri dönüyor ve dönüşte
  yatay olarak aynalanıyor. Tek yönlü sonsuz geçiş daha "yol" gibi dururdu
  ama karakteri zamanın yarısında ekran dışında bırakırdı — yürüyüş fazına
  bakan biri yürüyen birini görmeli. (İlk golden bunu yakaladı: figür
  çerçevenin dışındaydı.)
- **Yeni asset gerekmedi.** `lib/All_Assets/.../<Sınıf>_Walk.gif` zaten var ve
  `avatar.characterAsset` bunu gösteriyor. Triajdaki C9 klasörleri
  (`lib/GIF Animations/Soldier/`) ölü kopya; kullanılmadı.
- **Performans:** tek `AnimationController`, tek `Transform`. Yeniden çizilen
  alt ağaç `AnimatedBuilder`'ın `child`'ı olarak dışarıda tutuluyor, yani her
  karede yeniden **inşa** edilmiyor; yürüyüşün kendisi zaten GIF. Ölçüm:
  `pumpAndSettle` kullanılamıyor (sonsuz animasyon), golden sabit kare
  dizisiyle üretiliyor ve iki genişlikte de taşma yok.

### GD61. Ganimet düşmanın önünde (A.5 düzeltmesi) (2026-08-26)
- **Nerede:** `adventure_screen.dart` zafer sahnesi `Stack`'i
- **Sorun:** `..._coinScatter()` düşman `Positioned`'ından **önce** geliyordu.
  `Stack` çocukları sırayla boyandığı için ceset altınları örtüyordu.
- **Karar:** altın bloğu düşmandan sonraya taşındı. Aynı sahnedeki diğer
  katmanlar (hasar mesajı, "VURUŞ!" yazısı) zaten doğru sıradaydı; gözden
  geçirildi, başka yanlış sıralanmış katman bulunmadı.
- **Nasıl bağlandı:** golden **tek başına yetmez** (kırpılmış bir altın
  gözle kaçabilir). Test ağaç sırasını doğrudan ölçüyor: ceset anahtarı ilk,
  altın anahtarları sonra. Golden ayrıca gözle doğrulandı.

### GD62. Seri bonusunun tavanı kalktı; kazanç azalıp sıfırlanan bir döngüye girdi (2026-08-26)
- **Nerede:** `GameConstants.streakBonusTierLength` / `streakBonusTierTenths`,
  `StreakStatBonuses.tenthsForDay`
- **Karar (Bölüm B):** gün başına kazanç sabit +%1 olmaktan çıktı; her 100
  günde bir azalıyor ve tablonun sonunda başa dönüyor:

  | Gün | Kazanç |
  |---|---|
  | 1–100 | +%0,5 |
  | 101–200 | +%0,4 |
  | 201–300 | +%0,3 |
  | 301–400 | +%0,2 |
  | 401–500 | +%0,1 |
  | 501+ | +%0,5 — döngü baştan |

  Basamak uzunluğu ve kazanç tablosu **iki config sabitinde**; koda gömülü
  sayı yok ve test bunu bağlıyor.
- **Neden tavan kalktı:** sabit tavan (+%100) uzun seride her günü boşa
  çıkarıyordu. Serinin amacı alışkanlık; 120. günde hiçbir şey kazanmayan
  oyuncu için seri bir sayaçtan ibaret kalıyordu.
- **Neden azalıp sıfırlanıyor, sadece azalmıyor:** monoton azalan bir eğri
  sonsuza kadar sıfıra yaklaşır ve aynı anlamsızlığa varır. Sıfırlanma, 500.
  günü geçmeyi **ödül** yapıyor ve uzun seriye somut bir hedef veriyor.
- **Kutlama şart:** görünmeyen bir ödül ödül değildir. 501. (ve 1001., …)
  günde bildirimde "Döngü başa döndü! Gün başına kazanç yeniden +%0,5."
  yazıyor; ilk turun 1. günü kutlanmıyor — kutlanacak şey **geri dönmek**.

### GD63. Birikim **binde** cinsinden tam sayı tutuluyor (2026-08-26)
- **Nerede:** `StreakStatBonuses.tenths`, şema **v17 → v18**
- **Karar:** stat başına birikim `int` olarak binde tutuluyor (5 = +%0,5);
  oran okurken türetiliyor.
- **Neden gün sayısı yetmedi:** Bölüm 5C gün sayısı tutuyordu ve oranı
  `gün × %1` ile türetiyordu — gün başına kazanç sabit olduğu için doğruydu.
  Kazanç basamağa bağlanınca gün sayısı oranı belirleyemez oldu.
- **Neden `double` değil:** 0.005'i yüz kez toplamak 0.5 etmiyor. Bölüm
  5C'nin kendi notu bu tuzağı zaten yazmıştı; aynı hata daha büyük ölçekte
  geri gelirdi.
- **Taşıma veri kaybetmiyor:** v17 kaydındaki her gün değeri **10 ile
  çarpılıyor** (1 gün = +%1 = 10 binde). Uzun serili bir oyuncunun bonusu
  güncelleme sonrası onda birine düşmüyor; testle bağlı.

### GD64. Stat başına tavan da kalktı; yerine **ağırlıklı çekiliş** geldi (2026-08-26)
- **Nerede:** `StreakStatBonuses.drawWeights`,
  `GameConstants.streakBonusBalanceWeight`
- **Sorun:** şartname "toplam tavan kalksın ama tavana yakın statın seçilme
  ihtimali azalsın" diyordu. Sert bir **stat** tavanını korumak, toplam tavan
  kalkınca uzun seride bütün statları tavana oturtur ve her günü boşa
  çıkarırdı — yani kaldırılan tavanın geri gelmesi.
- **Karar:** hiçbir tavan yok. Her statın çekiliş ağırlığı
  `1 + min(streakBonusBalanceWeight, enYüksekStat − kendisi)`. Lider **her
  zaman** 1 ağırlıkla çekilişte kalır (rastgelelik gerçek), geride kalan en
  fazla 9 kat şanslı olur.
- **Ölçülen sonuç:** 90 günlük seride dokuz savaş statının **hepsi** bonus
  alıyor ve lider, en geriden gelenin iki katını geçmiyor. Testle bağlı.
- **Determinizm korundu:** çekiliş tek bir `Random(seed).nextInt(toplamAğırlık)`
  çağrısı ve kümülatif ağırlıkta yürüyüş. Ağırlıklar kalıcı birikimden
  türediği için `f(tohum, birikim)` deterministik; kapat-aç zar attırmıyor
  (gün işareti `lastStreakBonusDay` yerinde).

### GD65. Ekonomi statları havuzda **hâlâ** yok (2026-08-26)
- **Nerede:** `StreakStatBonuses.pool` (`ItemStat.isCombat` türevi)
- **Karar:** tavan kalktığı hâlde havuz genişletilmedi. Sekiz ekonomi statı
  (adım parası, adım XP, çark XP, düşman XP, stoklar, seri eşiği) dışarıda.
- **Neden:** tavansız büyüyen bir para çarpanı ekonomiyi tamamen çökertir —
  501. gündeki bir oyuncunun adım parası çarpanı sınırsız olurdu. Savaş
  statlarında aynı risk yok: onları düşman statları dengeliyor ve savaş
  motorunun kendi tavanları var (kritik %60, sıyrılma %40).
- Sekiz ekonomi statının hepsi ayrı ayrı sıfır kontrol ediliyor (test Bölüm
  5C'den korundu).

### GD66. Panel tavanı değil **güncel basamağı** gösteriyor (2026-08-26)
- **Nerede:** `inventory_screen.dart:_StreakBonusSection`,
  `root_shell.dart:_showStreakStatBonus`
- **Karar:** "tavan" etiketi ve "seri bonusu tavana ulaştı" metni kalktı.
  Yerine karakter panelinde tek satır: "Şu an: gün başına +%0,4. Kazanç her
  100 günde bir azalır, 500. günden sonra başa döner."
- **Neden:** oyuncunun 200. günde kazancının **neden** küçüldüğünü ve 501.
  günde neden büyüdüğünü görmesi gerekiyor (Model Kuralları #4). Tavan
  kalktığı için eski etiketin söyleyeceği bir şey kalmamıştı.
- **Sütun anlamı da değişti:** "GÜN / BONUS / DURUM" → "BONUS / PAY / DURUM".
  Gün sayısı artık bonusu belirlemediği için onu göstermek yanıltıcıydı; pay
  sütunu serinin oyuncuya nasıl bir profil verdiğini tek bakışta anlatıyor.
- **Ortak biçimlendirici:** `StreakStatBonuses.formatRate` (0.005 → "0,5").
  Üç ekran da onu kullanıyor; tam sayıya yuvarlamak gün başına kazancı sıfır
  ya da 1 gösteriyordu.

### GD47. Adım partisinin **bütün** bildirimleri frame sonuna alındı (2026-08-25)
- **Nerede:** `root_shell.dart:_onStepsReported`
- **Sorun (GD46'nın devamı):** `_showLevelUp` `hideCurrentSnackBar()` çağırıyor
  ve kendisi frame sonunda gösteriliyor. Senkron gösterilen bildirimler
  kuyruğa **önce** girip seviye kutlaması gelir gelmez, hiç görülmeden
  kapanıyordu. Ölçüldü: 6 günlük seriyle 5000 adım atan 1. seviye oyuncu
  **7 günlük kilometre taşı bildirimini hiç görmüyordu** — üstelik o bildirim
  kazanılan dondurma hakkını duyuran tek yer.
- **Karar:** günlük coin tavanı, seri stat bonusu ve kilometre taşı — üçü de
  tek bir `addPostFrameCallback` içinde, sabit sırayla kuyruğa giriyor.
  Frame sonu callback'leri kayıt sırasıyla çalıştığı için seviye kutlaması
  (setState içinde kaydediliyor) önce geliyor, bunlar arkasından.
- **Neden `_showLevelUp` değiştirilmedi:** `hideCurrentSnackBar()` doğru
  davranış — seviye atlamak manşet, kuyrukta beklememeli. Sorun sırada, o
  çağrıda değil.

### GD48. `StillGifFrame` test edilebilmek için public yapıldı (2026-08-25)
- **Nerede:** `features/wheel/daily_wheel_screen.dart`
- **Karar:** `_StillGifFrame` → `StillGifFrame` (state sınıfı private kaldı).
- **Neden:** triaj A6'nın (yükleme hatası yönetimi) düzeltmesi ancak asset
  yolunu dışarıdan verebilen bir testle doğrulanabiliyordu. Widget yalnızca
  `_GearSprite` içinden ve sabit bir asset yoluyla kuruluyor; hatalı asset
  enjekte etmenin başka yolu yok.
- **Neden başka yol seçilmedi:** `rootBundle`'ı test içinde düşürmek
  (`flutter/assets` kanalını mock'lamak) aynı testte `Image.asset`'i de
  düşürür ve alakasız hatalar üretirdi.
- **Kapsam:** yalnızca görünürlük değişti; davranış, dosya konumu ve
  isimlendirme deseni aynı (`PixelSprite`, `AvatarView` da public).

### GD44. Seri bonusu her gün **rastgele bir** savaş statını büyütür (2026-08-25)
- **Nerede:** `models/streak_stat_bonuses.dart`, `core/utils/streak_bonus.dart`,
  `UserProfile.grantStreakStatBonus`
- **Karar:** her seri günü havuzdan bir savaş statı seçilir ve o stat **+%1**
  büyür. Stat başına tavan **+%25**, toplam tavan **+%100** (~100 günde
  dolar). Tavana ulaşan stat havuzdan çıkar, yani gün boşa gitmez.
- **Neden tek stat değil:** tek stata giden bonus, 30 günlük seriyi tek bir
  sayıya indiriyordu ve "bugün ne kazandım" anı yoktu. Dağılım her oyuncuya
  serisine özel bir savaş profili bırakıyor.
- **Neden tavan +%100:** bonus yediye yayıldığı için tek statlık düşük bir
  tavan pratikte hiçbir şey ifade etmezdi. Stat başına +%25 sınırı da uzun
  serinin tek stata yığılmasını engelliyor. 7 stat × %25 = %175 > %100, yani
  **toplam tavan bağlayıcı** — bu ilişki testle bağlı.
- **Havuz elle yazılmadı:** `ItemStat.isCombat` üzerinden türetiliyor. Bölüm 7
  savaş motoru yeni bir stat eklerse havuz kendiliğinden genişler.
- **Ekonomi statları havuzda yok** (adım parası, adım XP, çark XP, düşman XP,
  tavanlar, seri eşiği): ekonomi ölçülmüş bir dengeye bağlı
  (`economy_pacing_test.dart`) ve seriyle büyürse günlük coin tavanı katlanır.
  Sekiz ekonomi statının hepsi ayrı ayrı sıfır kontrol ediliyor.
- **Seri kırılınca birikimin tamamı gider.** Bilerek: seriyi değerli kılan ve
  600 coin'lik dondurma hakkını haklı çıkaran şey bu. Dondurma hakkı köprü
  kurduğunda birikim **korunur** (seri artmıyor, ama kırılmıyor da).

### GD45. Rastgelelik hem tohumlu hem **kalıcı** (2026-08-25)
- **Nerede:** `UserProfile.streakBonusSeed`, `streakStatBonuses`,
  `lastStreakBonusDay`
- **Karar:** çekiliş tohumdan çıkıyor **ve** sonucu diske yazılıyor. Gün
  `lastStreakBonusDay` ile işaretleniyor; aynı oyun gününde ikinci çekiliş
  yapılmıyor.
- **Neden tohum tek başına yetmedi:** çekiliş **yol bağımlı** — tavana ulaşan
  stat havuzdan çıkıyor, yani N. günün havuzu önceki N−1 günün sonucuna
  bağlı. Saf bir `f(tohum, günIndeksi)` bunu ancak bütün geçmişi yeniden
  oynatarak üretebilirdi; üstelik havuz Bölüm 7'de genişleyecek ve eski
  günlerin sonucu geriye dönük değişirdi.
- **Zar atma kapatıldı:** kapat-aç yeni bir çekiliş yaptırmaz (gün işareti),
  çark çevirmek de sırayı değiştirmez — tohum çarkınkinden **ayrı** bir akış
  (`nextStreakSeed`), aynı LCG ama farklı sayaç. Aynı sayacı paylaşsalardı
  oyuncu "önce çarkı çevir, sonra yürü" ile stat seçebilirdi.
- **`String.hashCode` kullanılmadı** (GD8): başlangıç tohumu `stableSpread`
  ile oyuncunun adı ve sınıfından türüyor, sürümler arası sabit.
- **Tohum kırılmada sıfırlanmaz:** sıfırlansaydı her kırılıştan sonra aynı
  stat dizisi tekrarlanırdı.

### GD46. Seviye kutlaması seri bildirimini yutuyordu (2026-08-25)
- **Nerede:** `root_shell.dart:_onStepsReported`
- **Sorun:** `_showLevelUp` `hideCurrentSnackBar()` çağırıyor (seviye
  kutlaması manşet olmalı). Seri stat bildirimi senkron gösterildiği için
  kuyruğa **önce** giriyor, seviye kutlaması frame sonunda gelip onu hemen
  kapatıyordu. Aynı partide seviye atlayan oyuncu günün bonusunu hiç
  görmüyordu.
- **Karar:** seri bildirimi de `addPostFrameCallback` ile kuyruğa alınıyor.
  Frame sonu callback'leri kayıt sırasıyla çalıştığı için seviye kutlaması
  (setState içinde kaydediliyor) önce, seri bildirimi arkasından geliyor;
  ikisi de görülüyor. Testle bağlandı.
- **Kilometre taşı bildirimi (`_showStreakMilestone`) hâlâ senkron** ve aynı
  riski taşıyor. Bu birimin kapsamı dışında bırakıldı; Bölüm 6'da ele
  alınacak.

---
---

# Bölüm 3 — Buff çeşitliliği ✅ (2026-08-25)

Kartın sözü: *"aynı sınıftaki üç eşyanın en düşük seviyeli hallerinin buff'ı
aynı."* Doğrulandı, kökü bulundu ve kapatıldı. Kararlar **GD36–GD38**.

## Kök neden — iki ayrı hata üst üste binmişti

1. **`buildItemFromAsset` item kimliğini hiç geçmiyordu.**
   `buffFor(rarity, identity.category)` çağrılıyordu; `id` parametresi
   varsayılan `''` kalıyordu. Yani kuraldan türeyen **bütün** itemler, aynı
   kategori ve nadirlikteyse birebir aynı buff'ı alıyordu.
2. **Sıradan itemde tek bonus vardı ve o her zaman sınıf imzasıydı.**
   `buffTypeOrder` listesinin ilk elemanı `_classSignature(sınıf)` idi;
   kimliğe göre dönen yalnızca **kuyruk**tu. Sıradan item kuyruğa hiç
   ulaşmıyordu.

Sonuç: bir sınıfın gördüğü bütün sıradan kılıçlar aynı, bütün sıradan
kalkanlar aynı. Oyuncunun seçimi kozmetikti.

## Çözüm — arketip + ağırlıklı çekiliş

| Katman | Ne yapar |
|---|---|
| `lib/data/item_archetypes.dart` | **Veri**: arketip çarkları, savaş stat sıraları, bütçeler, eğilim çarpanları, çekiliş ağırlıkları |
| `models/item.dart:ItemArchetype` | Vurucu / Muhafız / Düellocu / Çevik + Türkçe ad ve açıklama |
| `item_rules.dart:archetypeFor` | Kimlikten kararlı arketip; kategori rolüne göre ağırlıklı |
| `item_rules.dart:economyTypeOrder` | Ağırlıklı, tekrarsız, kararlı ekonomi bonusu çekilişi |
| `item_rules.dart:_combatEffects` | Arketipin savaş statları |
| `widgets/archetype_badge.dart` | Mağaza ve envanterde arketip rozeti |

Hiçbir yerde `switch (id)` yok; tablo veridir (Model Kuralı #1: enum ve
`String`, Flutter tipi yok — `Item` zaten diske yazılmıyor).

### Etki sayısı ve bütçe

| Nadirlik | Ekonomi | Savaş | Toplam | Ekonomi bütçesi | Savaş bütçesi |
|---|---|---|---|---|---|
| Sıradan | 1 | 1 | 2 | %2 | 9 |
| Az Bulunur | 2 | 1 | 3 | %5 | 18 |
| Nadir | 2 | 2 | 4 | %9 | 32 |
| Epik | 3 | 2 | 5 | %15 | 55 |
| Efsanevi | 3 | 3 | 6 | %26 | 90 |

Arketip eğilimi bütçeyi kaydırıyor: **ekonomi ×0.85–1.00, savaş ×0.95–1.20.**
Ekonomi çarpanı hiçbir arketipte 1.0'ı geçmiyor — `economy_pacing_test.dart`
bugünkü dengeyi ölçüyor ve arketip sistemi onu büyütmemeli (GD38).

### Ölçülen çeşitlilik

Aynı sınıf + aynı kategori + aynı nadirlikteki gruplar (yalnızca kuraldan
türeyen itemler, ≥6 item):

| | Önce | Sonra |
|---|---|---|
| En kötü grupta farklı buff sayısı | **1** | **7** (14 itemde) |
| En sık kalıbın payı | **%100** | **%43** |

Sınıf kimliği kaybolmadı: imza hâlâ **en sık** birincil bonus (Kılıç Ustası
%50 düşman XP, Şahin Okçu %50 adım parası, Işık Rahibi %36 seri eşiği, Ayı
Ruhlu %34 çark hakkı).

## Beraberinde kapanan iki gerçek hata (Faz 0 A listesi)

- **A3 — testler ölü sınıfları doğruluyordu.** Üç test dosyasındaki elle
  yazılmış sekiz sınıflık liste `AvatarProfile.playableClassIds` ile
  değiştirildi; ortaya çıkan iki dağılım ihlali (Mezar Okçusu 143 item, Ayı
  Ruhlu 105 item) düzeltildi. Ayrıntı: **GD37**.
- **A4 — sınıf imzaları çakışıyordu.** Beş sınıf `enemyXp` paylaşıyor,
  `wheelXp` ise hiçbir oynanabilir sınıfın imzası değildi. İmzalar sekiz türe
  dengeli dağıtıldı. Ayrıntı: **GD36**.

## Yol boyunca bulunan iki başka hata

1. **`ArchetypeBadge` dar kartta `RenderFlex` taşması üretiyordu** (320 ve
   360 dp'de 10 px). Etiket `Flexible` + `TextOverflow.fade` ile esnetildi.
   Test ortamında gerçek font olmadığı için yazılar dolu kutu çiziliyor ve bu
   **en kötü durum**; gerçek cihazda etiket rahat sığıyor.
2. **`store_screen_test.dart` taşma testi 10 dakikada zaman aşımına
   uğruyordu.** `expect(errors, isEmpty, reason: errors.join(' | '))` — taşan
   bir düzen her karede yüzlerce hata üretiyor ve hepsini birleştirmek test
   koşucusunu kilitliyordu. Artık yalnızca ilk iki hata raporlanıyor; hata
   varken **10 dakika beklemek yerine saniyeler içinde** kırmızıya dönüyor.

## Arayüz

Arketip rozeti nadirlik rozetinin yanında, `Wrap` içinde: dar kartta alt
satıra düşüyor, taşmıyor. Envanterin item kartında ayrıca tek satırlık
açıklama var ("Düellocu — kritik vuruşa yatırım yapar"), çünkü rozet tek
başına "hangi yöne güçlü" sorusunu cevaplamıyor.

Nadirlik "ne kadar güçlü", arketip "hangi yöne güçlü" sorusunu cevaplıyor;
görsel dil bilerek nadirlikten soluk — arketip bir sıralama değil.

## Test

- `test/item_variety_test.dart` — **14 test** (yeni): aynı sınıf/kategori/
  nadirlik gruplarının tek kalıba sıkışmaması, varyantların ayrışması, sınıf
  kimliğinin dağılımda korunması, arketipin kararlılığı ve sınıftan
  bağımsızlığı, her rolde dört arketipin bulunması, rol eğiliminin korunması,
  imzalı itemin arketipinin gerçekten taşıdığı stattan okunması, ekonomi
  tavanları, kuraldan türeyenin imzalıyı geçmemesi, sıfıra düşen stat
  olmaması.
- `test/golden/store_card_golden_test.dart` — **3 test** (yeni): 320 ve 390 dp
  golden + örneklemin gerçekten dört farklı arketip/buff içerdiği iddiası.
  PNG'ler okundu ve gözle doğrulandı: dört kart dört farklı renkte rozet ve
  dört farklı bonus satırı gösteriyor.
- Güncellenen (silinmedi): `item_catalog_test.dart` (imza invariantı yeniden
  tanımlandı, bonus sayısı tablosu, rol eğilimi artık istatistiksel),
  `item_effects_test.dart`, `equipped_buffs_test.dart`,
  `item_comparison_test.dart`, `inventory_test.dart`, `store_screen_test.dart`.

Toplam **470 test geçiyor**, `flutter analyze` temiz.

## Açık kalan

`ItemArchetype` bugün yalnızca **buff türetmesini** ve **gösterimi** etkiliyor.
Savaş statları hâlâ uyuyor (Aşama 4a). Bölüm 4'te eşya seviyesi savaş
statlarını büyütecek; arketip o noktada "hangi stat büyüyor" sorusunun da
cevabı olacak.

---
---

# Bölüm 4.1–4.2 — Eşya örnekleri ve seviye ✅ (2026-08-25)

Demircinin **temeli**: envanter örnek listesine geçti, mağaza aynı eşyayı
tekrar satıyor, eşyalar coin harcanarak yükseliyor. Birleştirme, ayrı demirci
ekranı ve mağaza duyurusu **Bölüm 4.3–4.6**'nın konusu.

Kararlar **GD39–GD41**. Şema **v11 → v12**.

## 1. Veri yapısı

| Önce | Sonra |
|---|---|
| `List<String> ownedItemIds` (ekipman + yükseltmeler karışık) | `List<OwnedItem> ownedItems` + `List<String> ownedUpgradeIds` |
| `Map<slot, itemId> equippedItemIds` | `OwnedItem.equipped` + `_refreshEquipment` normalleştirmesi |
| Nadirlik ve seviye katalogdan | Nadirlik ve seviye **örnekten**; katalog nadirliği "başlangıç" |

`OwnedItem` = `{instanceId, itemId, level, rarity, equipped}`. Model Kuralları
#1 temiz: yalnızca `String` ve sayı; item her açılışta katalogdan çözülüyor ve
sınıfa uyarlanıyor (GD16).

**Taşıma veri kaybetmiyor** ve testle bağlı: her kimlik seviye 1 + katalog
nadirliğiyle örneğe dönüşüyor, kuşanılı olanlar kuşanılı kalıyor, `/`
içermeyen kimlikler (yükseltmeler) ayrı listeye gidiyor.

## 2. Mağaza artık aynı eşyayı tekrar satıyor

Birleştirmenin zorunlu sonucu. Kart "Sahipsin" yerine **"N adet"** rozeti
gösteriyor, satın alma düğmesi açık kalıyor, "Alabileceklerim" süzgeci
sahipliğe bakmıyor (GD14 güncellendi).

Para kontrolü yerinde: bakiye bir adede yetiyorsa ikincisi alınmıyor ve coin
negatife düşmüyor. Tüketilen yükseltmelerin (dondurma hakkı, 2x XP) muhafızları
hiç değişmedi.

## 3. Eşya seviyesi

Her örnek **Sv. 1**'de başlıyor; otomatik seviye atlama yok.

**İki tavan, ikisi de geçerli:**

| Nadirlik | Nadirlik tavanı | 1→tavan toplam maliyet | Coin günü (120/gün) | Oyuncu seviyesi günü (3000 XP/gün) |
|---|---|---|---|---|
| Sıradan | 10 | 675 (6,8×) | **6** | 15 |
| Az Bulunur | 20 | 2.300 (7,1×) | **19** | 63 |
| Nadir | 30 | 5.775 (7,0×) | **48** | 145 |
| Epik | 40 | 18.225 (7,0×) | **152** | 260 |
| Efsanevi | 50 | 59.200 (7,0×) | 493 | 408 |

Fiyatlar katmanın medyan eşyasından (100 / 325 / 825 / 2.600 / 8.450).

**Okuma:** ilk dört katmanda **oyuncunun kendi seviyesi coinden daha sıkı bir
kısıt.** Yani para gerçek bir maliyet ama duvar değil — "yükseltmek mi, yeni
eşya mı" sorusu gerçekten sorulabiliyor. Efsanevi bilerek istisna: aylara
yayılan bir hedef.

Karşılaştırma noktası: 10. seviyedeki oyuncu (15 gün, ~1.800 coin kazanmış)
ya sıradan bir eşyayı tavana çıkarır (675 coin → saldırı 6 → 11,4) ya da bir
nadir eşya alır (825 coin → saldırı 13, sonradan 50,7'ye kadar büyüyebilir).
İkisi de canlı seçenek.

⚠️ **Yükseltme yalnızca savaş statlarını büyütüyor** (GD41). Ekonomi bonusları
sabit; kural `scaleForLevel` içinde kodla zorlanıyor.

**Katman sıralaması hiç bozulmuyor** (testle bağlı): sıradan tavanı (11,4) <
az bulunur tavanı (31,9) < nadir (50,7) < epik (107,8) < efsanevi (165,2).
Sıradan bir eşya asla efsaneviye yetişemiyor.

## 4. Demirci — bu bölümdeki arayüz

Envanterdeki item kartına (bottom sheet) bir **demirci paneli** eklendi:
mevcut seviye / nadirlik tavanı, sonraki seviyedeki stat farkı, maliyet ve
"yükselt" düğmesi. Engel **sessiz kalmıyor** ve hangi tavanın bağladığı ayrı
ayrı söyleniyor:

- "Nadirlik sınırı (Sıradan: 10). Daha ileri gitmek için birleştirerek
  nadirliğini yükseltmelisin."
- "Eşya kendi seviyeni geçemez (Sv. 7). Sen yükseldikçe eşyan da yükselebilir."
- "N coin gerekiyor."

Panel ayrıca "yükseltmek yalnızca savaş istatistiklerini büyütür; ekonomi
bonusları sabit kalır" diyor — oyuncu neye para verdiğini bilsin.

Envanter listesinde her satır artık bir **örnek**: eşya seviyesi rozet olarak
görünüyor, aynı eşyanın iki adedi ayrı satırlar.

> **Ayrı demirci/örs ekranı, birleştirme ve mağaza duyurusu Bölüm 4.3–4.6'da.**
> Bu bölüm yükseltmeyi **ulaşılabilir** kıldı: yarım bir özellik bırakılmadı.

## 5. Yol boyunca bulunan iki gerçek hata

1. **Ana ekrandaki seri kartı 320 dp'de 61 px taşıyordu**
   (`home_screen.dart` — "Bugün tamamlandı" satırı). Demirci golden'ı
   yakaladı; metin `Flexible` + ellipsis oldu. Seri sayısı asla kırpılmıyor.
2. **`FilledButton.icon` etiketini `Flexible`'a sarmak hata veriyor**
   ("competing ParentDataWidget"): Material etiketi zaten kendi `Flexible`'ına
   koyuyor. Kırpma doğrudan `Text` üzerinde yapılmalı. İlk denemede bu tuzağa
   düşüldü; golden yakaladı.

## 6. Test

- `test/item_leveling_test.dart` — **28 test** (yeni): iki tavan ve
  hangisinin bağladığı, maliyet eğrisi (artan, 25 katı, ~7×), ilk dört
  katmanda seviye kapısının coin kapısından sıkı olması, **ekonomi
  bonuslarının seviyeyle büyümediği** (sekiz statın hepsi ayrı ayrı), savaş
  statlarının büyüdüğü, çift etkili itemin bedelinin de büyüdüğü, katman
  sıralamasının bozulmadığı, nadirlik yükselmesinin `requiredLevel`'ı
  değiştirmediği, imzalı itemin karakterini koruduğu, ekonomi tavanının
  aşılmadığı, örnek modelinin kayıt turu ve bozuk satır davranışı.
- `test/inventory_test.dart` — **+8 test**: yükseltmenin parayı düşürüp
  seviyeyi artırması, **yalnızca seçilen örneği** etkilemesi, üç engelin
  ayrı ayrı söylenmesi, kuşanılı eşyada savaş statının büyüyüp ekonominin
  değişmemesi, diske yazılması, yükseltilmiş eşyanın satış değeri.
  Ayrıca "aynı slotta ikinci kuşanılı örnek düşer" (GD26'nın yeni yeri) ve
  "v11 kaydı örnek listesine taşınır, veri kaybolmaz".
- `test/golden/blacksmith_golden_test.dart` — **3 golden** (yeni):
  yükseltilebilir panel (320/390 dp) ve engelli panel (320 dp). PNG'ler
  okundu ve gözle doğrulandı.
- Güncellenen (silinmedi): `store_purchase_test.dart` (çoklu satın alma),
  `store_screen_test.dart` ("N adet" ve süzgeç), `game_storage_test.dart`.

Toplam **511 test geçiyor**, `flutter analyze` temiz.

## 7. Sıradaki bölüm — 4.3–4.6

- **Birleştirme:** aynı eşyadan N örnek + coin → 1 örnek, bir üst nadirlikte.
  Gereken adet 3/4/5/6 (tek config sabiti). Sonuç örneğin seviyesi ve maliyet
  kararı orada verilecek. Altyapı hazır: `OwnedItem.rarity` ve
  `item_rules.dart:withRarity` çalışıyor ve testli — bugün onları **kullanan
  yol yok**.
- **Ayrı demirci/örs ekranı:** bu bölümde panel item kartının içinde; 4.4'te
  envanterde belirgin bir giriş noktası olacak.
- **Mağaza duyurusu (4.5):** "Yükseltilebilir · Maks Sv. 30",
  "3 tanesini birleştirerek nadirliğini yükseltebilirsin".

---
---

# Bölüm 4.3–4.6 — Birleştirme ve demirci ✅ (2026-08-25)

Demirci tamamlandı: aynı eşyanın birkaç adedi birleşip bir üst nadirliğe
çıkıyor, ayrı bir demirci ekranı var ve mağaza satın almayı kalıcı bir yatırım
olarak duyuruyor. Kararlar **GD42–GD43**. Şema değişmedi (**v12**).

## 1. Birleştirme kuralları

`lib/core/utils/item_merging.dart` — saf, `item_leveling.dart` ile aynı desen.

| Geçiş | Gereken adet | Ücret |
|---|---|---|
| Sıradan → Az Bulunur | 3 | 150 |
| Az Bulunur → Nadir | 4 | 350 |
| Nadir → Epik | 5 | 1.050 |
| Epik → Efsanevi | 6 | 3.325 |
| Efsanevi | — | birleştirilemez |

Adetler **tek config sabitinde** (`GameConstants.itemMergeCounts`); koda gömülü
sayı yok ve test bunu bağlıyor. Efsanevinin haritada anahtarı **yok** — üstünde
nadirlik olmadığı için birleştirilemiyor ve nedeni kullanıcıya söyleniyor.

Üç şart: aynı **kimlik**, aynı **nadirlik**, yeterli **adet** + para.
Seviyeler farklı olabilir.

- **Sonuç Sv. 1'e döner** (GD42). Sertliği dengeleyen karar: tüketilecek
  örnekler otomatik olarak **en düşük seviyeliden** seçiliyor, kuşanılı olanlar
  en sona atılıyor. Dört adedi olan oyuncu birleştirdiğinde Sv. 9 olan elinde
  kalıyor.
- **Kuşanılı bir adet harcanacaksa** önce çıkarılıyor ve bu hem onay ekranında
  hem sonuçta söyleniyor — sessizce kaybolmuyor.
- **Seviye kilidi değişmiyor** (GD40): birleştirdiğin eşya birden
  kuşanılamaz hâle gelmiyor. Bu, birleştirmenin asıl ödülü.
- **Nadirlik tavanı yükseliyor**: sıradan bir kılıç Sv. 10'da duruyordu,
  birleştirilince Sv. 20'ye kadar gidebiliyor.

## 2. Demirci ekranı

`lib/features/inventory/blacksmith_screen.dart` — envanterin AppBar'ındaki
**örs düğmesinden** açılıyor.

Envanter **kimlik + nadirlik** gruplarına bölünüyor; her grup bir kart:

- **Yükselt** — "Sv. 4 / 10 (en gelişmiş adet)", sonraki seviyedeki stat farkı,
  maliyet. Yükseltme her zaman **en gelişmiş** adede uygulanıyor; oyuncu
  yatırımını tek eşyada toplasın.
- **Birleştirme** — "3/3 adet → Az Bulunur", sonuç bilgisi ("Sv. 1'e döner,
  nadirlik tavanı 20 olur"), ücret.

Engellerin hiçbiri sessiz değil (Model Kuralları #4): devre dışı düğme
**dokunulabilir** ve nedeni söylüyor, ayrıca neden kartın içinde de yazılı.
Beş ayrı engel metni var: nadirlik tavanı, oyuncu seviyesi, yetersiz bakiye
(yükseltme), yetersiz adet, en üst nadirlik (birleştirme).

Ekran veri **tutmuyor**: `readState` + `revision` ile `RootShell`'i canlı
okuyor (GD27) — arka planda adım gelip para değiştiğinde demirci de tazeleniyor.

Onay diyaloğu ne kaybedildiğini ve ne kazanıldığını tek tek yazıyor, harcanacak
adetlerin **seviyelerini** listeliyor ve "Bu işlem geri alınamaz." diyor
(GD29'un satış onayıyla aynı dil).

## 3. Mağaza duyurusu

Ekipman kartına tek satır eklendi:

> Yükseltilebilir · Maks Sv. 10 · 3 tanesini birleştirince Az Bulunur olur

Efsanevide "en üst nadirlik" yazıyor. Gereken adet nadirliğe göre değiştiği
için sayı **tablodan** okunuyor, sabit yazılmıyor.

Kart bu satırla uzadı; iki test buna göre güncellendi:
- "kilitli item satın alınamaz" artık düğmeyi `ensureVisible` ile buluyor
  (varsayılan 800×600 test görüntüsünde ekran dışına düşüyordu),
- "az içerikli kart gereksiz boşluk bırakmaz" ölçütü 250 → **302 px**;
  ölçütün anlamı zaten GD12'nin kaldırdığı **sabit** yükseklikten küçük olmak.

Altı ekran genişliğindeki taşma testleri değişmeden geçiyor.

## 4. Test

- `test/item_merging_test.dart` — **22 test** (yeni): adet tablosu ve tek
  config kaynağı, efsanevinin birleştirilemezliği, ücretin nadirlikle artması
  ve doğrudan alımdan pahalı olması, tüketilecek örneklerin seçimi (en düşük
  seviye önce, kuşanılı en sona, kararlı sıra, gelen liste değiştirilmez),
  dört engelin ayrı ayrı raporlanması, gruplama (farklı nadirlik ayrı grup),
  zincirleme yükselmenin efsanevide durması.
- `test/blacksmith_test.dart` — **16 test** (yeni, gerçek `RootShell`
  üzerinden): örs düğmesinin ekranı açması, boş durum, adetlerin tek kartta
  toplanması, farklı nadirliklerin ayrı kartlara düşmesi, birleştirmenin
  nadirliği yükseltip Sv. 1'e döndürmesi, fazla adette en gelişmiş örneğin
  elde kalması, vazgeçme, onay ekranının içeriği, kuşanılı adedin çıkarılması,
  üç engel, diske yazma, döngünün para üretmemesi, demirciden yükseltmenin en
  gelişmiş adede uygulanması.
- `test/golden/forge_golden_test.dart` — **2 golden** (320/390 dp): karışık
  örneklem (birleştirilebilir / adedi yetmeyen / efsanevi). PNG'ler okundu ve
  gözle doğrulandı.
- `test/store_screen_test.dart` — **+3 test**: yatırım satırının içeriği,
  adedin nadirliğe göre değişmesi, efsanevi metni.
- Yeniden üretilen golden'lar: `store_card_*` (yatırım satırı),
  `blacksmith_*` (envanter AppBar'ına örs düğmesi eklendi).

Toplam **554 test geçiyor**, `flutter analyze` temiz.

## 5. Bölüm 4 kapandı

4.1 → 4.6'nın tamamı bitti. Açık kalan tek konu, savaş statlarının **hâlâ
uygulanmıyor** olması — savaş motoru Aşama 4a'nın konusu (bkz. kapanış §7).
Yükseltme ve birleştirme bugün o statları büyütüyor ve gösteriyor; motor
gelince kendiliğinden canlanacaklar.

---
---

# OTURUM KAPANIŞI — 2026-08-25 (SABAH) · ŞARTNAME ARŞİVİ

> ⚠️ **Devam noktası artık dosyanın en sonundaki akşam kapanışı.**
> Bu bölüm **hâlâ gerekli**: aşağıdaki §5, **Bölüm 5 / 6 / 7+**'nın tam
> şartnamesini taşıyor ve o işler henüz yapılmadı. Bölüm 1–4 ile ilgili
> kısımlar tarihsel kayıt.

> Bu bölüm **tek başına yeterlidir.** Kullanıcıya hiçbir şey sormadan devam
> edebilmek için gereken her şey burada: ne bitti, ne açık, hangi işin şartnamesi
> ne, hangi sırayla yapılacak. Kullanıcının bağlamı (usage) sınırlı — soru sorma,
> karar gerektiren yerde en makul seçeneği kendin seç ve gerekçesini buraya yaz.

## 0. Bu oturumun bağlamı

Oturum gözetimsiz çalıştı. Görev listesi 7 bölümdü; **Bölüm 1 ve 2 bitti**,
kalanlar aşağıda tam şartnameleriyle duruyor.

Değişmeyen kurallar:
- ⛔ **FIREBASE'E DOKUNMA.** `firebase_options.dart`, Firestore, Auth, Cloud
  Functions, `google-services.json`, `GoogleService-Info.plist` — hiçbirine.
  pubspec'e firebase paketi ekleme. Bir iş Firebase gerektiriyorsa **atla** ve
  buraya "arkadaşımın işi" diye yaz.
- ⚠️ **`flutter run` ÇALIŞMIYOR** (Smart App Control). Cihazda gözle doğrulama
  yok. Görsel işler **golden test** ile doğrulanacak: golden üret, PNG'yi **oku
  ve gerçekten bak**, farklı ekran genişlikleri için ayrı golden üret.
- **Commit atma.** Bölüm bitince değişen dosyaları listele, ne yaptığını özetle,
  tek satırlık conventional-commit mesajı öner. Commit'i kullanıcı atıyor.
- **Arkadaşımın kodu — varsayılan: dokunma.** Yalnızca gerçek hataları düzelt.
  Mimari uyum için refactor etme, isim/stil değiştirme, dosya silme.
- Her adımdan sonra `flutter analyze` temiz + testler yeşil olmalı. **Adım
  sonunda durma, bölüm bitene kadar devam et.**

## 1. Bu oturumda ne yapıldı

| Bölüm | Ne | Test |
|---|---|---|
| Faz 0 | İnceleme + test altyapısının kurtarılması | 421 |
| **Bölüm 1** | Sınıf seçme ekranı: geri tuşu, tek onay, ortalanmış eşya şeridi + 3 sessiz hata | 421 → 440 |
| **Bölüm 2** | Macera ilerleme barları + 5 gerçek hata (biri ekonomi açığı) | 440 → **453** |

Ayrıntılar: yukarıdaki "Bölüm 1 — Sınıf seçme ekranı" ve "Bölüm 2 — Macera
ilerleme göstergeleri" bölümleri. Kararlar **GD30–GD35**.

`flutter analyze` temiz · **453/453 test geçiyor** · paket eklenmedi ·
şema sürümü hâlâ **v11** (bu oturumda kalıcı alan eklenmedi).

## 2. Commit durumu — DİKKAT

- **Bölüm 1 commit edildi** (`fix(character): add back navigation, single
  confirmation and centered gear strip to class select`).
- **Bölüm 2 commit EDİLMEDİ.** Önerilen mesaj:
  `fix(adventure): show quest progress as primary bar and stop daily coin cap reset on quest change`

Bölüm 2'nin commit edilmemiş dosyaları:

```
M  .gitignore                                  (test/failures/ eklendi)
M  CLAUDE.md
M  lib/features/adventure/adventure_screen.dart
M  lib/features/root/root_shell.dart
M  lib/widgets/stat_bar.dart
?? test/adventure_progress_test.dart
?? test/golden/goldens/adventure_320.png
?? test/golden/goldens/adventure_390.png
```

`pubspec.lock` de değişik görünüyor (oturum öncesinden kalma, dokunulmadı).

## 3. ⚠️ TEST ORTAMI — ilk iş bu

Testleri çalıştırmadan önce yukarıdaki **"Test ortamı — testler neden
`--no-test-assets` ile çalışıyor"** bölümünü oku. Özet:

```powershell
# bir kereye mahsus (build/unit_test_assets/shaders/ boşsa)
copy build\app\intermediates\flutter\debug\flutter_assets\shaders\ink_sparkle.frag `
     build\unit_test_assets\shaders\ink_sparkle.frag
# her seferinde
flutter  test --no-test-assets
```

Bu bayrak olmadan **hiçbir test çalışmaz** (araç çöker). Golden üretmek için
`--update-goldens` eklenir. `pumpAndSettle` kullanma — sonsuz animasyonlar var,
sabit kare dizisi kullan.

## 4. Faz 0'da bulunan, HÂLÂ DÜZELTİLMEMİŞ gerçek hatalar

Bölüm 1 ve 2 kendi kapsamlarındaki hataları kapattı. Kalanlar:

### A3. ✅ ÇÖZÜLDÜ (Bölüm 3) — dağılım testi ölü sınıfları doğruluyordu
- **Nerede:** `test/item_catalog_test.dart:_allClasses` (dosyanın en üstü)
- **Ne:** Liste hâlâ **eski 8 sınıf** (`Archer, DarkMagic, Faith, Magic,
  Nature, Paladin, SwordMan, Thief`). Arkadaşım karakterleri `All_Assets`
  setine taşıdı; oynanabilir sınıflar artık **18 tane** ve hiçbiri
  denetlenmiyor.
- **Elle hesaplanan ihlaller** (`ItemCategoryX.characterClasses` üzerinden,
  kategori sayıları: swords 180 · magic 172 · shields 112 · arch 84 ·
  spears 60 · maces 57 · ranged_other 56 · axes 45 · scythes 15 ·
  special_other 3 = **784**):

  | Sınıf | Kategoriler | Item | İhlal |
  |---|---|---|---|
  | Skeleton Archer | arch + rangedOther + specialOther | **143** | alt sınır 150 |
  | Werebear | axes + maces + specialOther | **105** | alt sınır 150 |
  | Soldier | swords + spears + shields + rangedOther | **408** | üst sınır 392 (%50) |

  Diğer 15 sınıf sınırların içinde.
- **Çözüm (2026-08-25):** `AvatarProfile.playableClassIds` eklendi ve üç
  test dosyası da ondan okuyor; iki dağılım ihlali kapatıldı (bkz. GD37).
- *(Yapılacaklar, tarihsel):* `_allClasses`'ı canlı listeden türet (retired olanlar hariç —
  `CharacterCatalog.retiredClassIds` = `{Bat, Lancer, Necromancer, Orc rider}`),
  testi kırmızıya düşür, sonra `ItemCategoryX.characterClasses` haritasını
  dengele. **Bölüm 3 ile aynı dosyalara dokunuyor, birlikte yapılmalı.**

### A4. ✅ ÇÖZÜLDÜ (Bölüm 3) — sınıf imzaları çakışıyordu
- **Nerede:** `lib/core/utils/item_rules.dart:_classSignature`
- **Ne:** GD17'nin "her sınıfın imza bonusu ayrı" garantisi 18 sınıf × 8 buff
  türüyle **matematiksel olarak imkânsız**. Beş sınıf `enemyXp` paylaşıyor
  (`Armored Axeman, Elite Orc, Greatsword Skeleton, Orc, Swordsman`).
- **Çözüm (2026-08-25):** imzalar sekiz türe dengeli dağıtıldı, invariant
  yeniden tanımlandı (bkz. GD36). `wheelXp` eskiden **hiçbir oynanabilir
  sınıfın** imzası değildi; artık iki sınıfın.

### A6. Çark GIF karesi yüklerken hata yönetimi yok · **DÜŞÜK**
- **Nerede:** `lib/features/wheel/daily_wheel_screen.dart:_StillGifFrameState._load`
- `rootBundle.load` ve `instantiateImageCodec` try/catch'siz. Asset eksikse
  yakalanmayan async exception. `GifTiming._measure` doğru deseni gösteriyor
  (try/catch + finally dispose).

### A7. `CharacterCatalog._cache` hiç geçersizleşmiyor · **DÜŞÜK**
- Statik önbellek, `reset()` yok. Bugün zararsız (katalog sabit). `ItemCatalog`
  test edilebilirlik için `reset()` sunuyor; aynı deseni eklemek yeterli.

### Bölüm 2'de bulunup **kapsam dışı bırakılan**
- 320 dp'de savaş sahnesindeki görev metni katmanı (yeşil bloklar) altı satıra
  çıkıp karakterlerin üstüne biniyor. Sprite çakışması düzeltildi (GD35) ama
  metin katmanı hâlâ sahnenin yarısını kaplıyor. Golden:
  `test/golden/goldens/adventure_320.png`.

## 5. KALAN İŞ — tam şartname

> Aşağıdaki üç bölüm kullanıcının orijinal talebidir, birebir aktarılmıştır.
> Bölüm 4 büyük; **4.1–4.2 bir bölüm, 4.3–4.6 ayrı bölüm** olarak yapılacak.

---

### BÖLÜM 3 — Buff çeşitliliği

**Sorun:** aynı sınıftaki üç eşyanın en düşük seviyeli hallerinin buff'ı
**aynı**. Aynı sınıf + aynı seviye + farklı eşya = aynı sonuç. Bu seçimi
anlamsız kılıyor.

**Kök neden (Faz 0'da doğrulandı):** `item_rules.dart:buffFor`
- `count` ve bütçe **yalnızca nadirlikten**, paylar sabit (`_buffShares`).
- `buffTypeOrder` listesinin **ilk elemanı** her zaman `_classSignature(sınıf)`
  — yani sınıfın bütün itemlerinde aynı.
- Sıradan itemde `count == 1`, dolayısıyla **tek** etki var ve o da imza →
  aynı sınıfın bütün sıradan itemleri **birebir aynı**.
- Kuyruk `stableSpread(id, …)` ile döndürülüyor ama bu yalnızca **ikincil**
  bonusu değiştiriyor.

**İstenen:**
- Aynı sınıf ve aynı seviyedeki eşyalar birbirinden **ayrışsın**.
- Buff türetmesine eşyanın **kendi kimliğini** kat; sadece kategori ve
  nadirlikten türetme.
- Her eşyanın bir "karakteri" olsun: biri saldırıya, biri savunmaya, biri
  kritiğe, biri hıza eğilimli. **Aynı güç bütçesi farklı dağılsın.**
- Oyuncu iki eşya arasında gerçek bir tercih yapmalı, "hangisi daha yüksek
  sayı" değil.
- Buff'lar **veriyle** tanımlansın. Model Kuralı #1'e uy.
- Test yaz: aynı sınıf + aynı seviyedeki eşyaların buff'ları farklı olmalı.

**Zemin (hazır):** `lib/models/item_effect.dart` içinde **15 stat** var —
7 savaş (`attack, defense, combatHealth, critChance, critDamage, lifesteal,
evasion`) + 8 oyun dışı. Şu an **kural türetmeli itemler yalnızca oyun dışı**
statlar alıyor; savaş statları sadece elle tasarlanmış imzalı itemlerde
(`lib/data/item_effects.dart`, 18 efsanevi + 31 epik + 12 nadir).

**Önerilen yaklaşım (uygulanmadı, karar senin):**
1. `stableSpread(item.id, 4)` ile bir **arketip** türet (vurucu / muhafız /
   düellocu / çevik) ama kategori rolüne göre ağırlıklandır (kalkan "vurucu"
   olmasın).
2. Arketip hem **hangi savaş statının** birincil olacağını hem **bütçe
   dağılımını** belirlesin. Bütçe toplamı nadirlikten gelmeye devam etsin.
3. Sınıf imzası korunsun ama artık tek etki olmasın: sıradan itemde bile
   "1 ekonomi + 1 savaş" olsun.
4. Arketip tablosu `lib/data/` altında **veri** olarak dursun; `switch (id)`
   yazma (mevcut `item_effects.dart` bu deseni izliyor).

**Bozulmaması gerekenler (mevcut testler):**
- `test/item_effects_test.dart` — "her sınıfın imza bonusu ayrı ve her itemde
  bulunur" invariant'ı **yeniden tanımlanmalı** (A4). Testi silme, kesinleştir.
- `test/equipped_buffs_test.dart` — dört tavan: tek item ≤ +%15
  (`GameConstants.maxSingleItemEconomyBonus`), kuşanılan toplam ≤ +%50
  (`maxEquippedEconomyBonus`), stok bonusu ≤ +2, seri eşiği indirimi ≤ 1000.
  **Bu tavanlar korunmalı.**
- `test/economy_pacing_test.dart` — buff'sız dünyayı ölçüyor, etkilenmemeli.
- A3'ü de burada kapat.

---

### BÖLÜM 4 — Eşya yükseltme ve birleştirme (demirci)

Eşyalar **otomatik seviye atlamayacak**. Oyuncu emek ve para harcayarak
yükseltecek. Amaç: envanterde her seferinde "yeni eşya mı alsam, yoksa bunu mu
yükseltsem" sorusu sorulsun.

#### 4.1 Veri yapısı değişikliği (ÖNCE BU)

**Mevcut durum:** `UserProfile.ownedItemIds` bir **`List<String>`** (yalnızca
kimlik). `UserProfile.equippedItemIds` bir `Map<slotKey, itemId>` (slot =
`ItemCategory.folder`). Seviye ve nadirlik **katalogdan** türetiliyor.
**Şema sürümü: v11.**

**İstenen:** envanter artık kimlik listesi olamaz. Her sahip olunan eşya, kendi
seviyesi ve kendi nadirliği olan bir **ÖRNEK** olmalı:

```
{ itemId, level, rarity, equipped }
```

- Nadirlik artık **katalogdan değil örnekten** okunur (birleştirmeyle değişir).
- Katalog nadirliği "başlangıç nadirliği" olur.
- **Şema sürümünü artır (v12), migration yaz:** mevcut kimlikler seviye 1 ve
  katalog nadirliğiyle örneğe dönüşsün. **Veri kaybı olmasın.**
- Migration deseni: `lib/services/game_storage.dart` içindeki `_migrations`
  haritası ("sürüm N → N+1"). Serileştirme elle yazılır (`build_runner` yok).

**⚠️ ZİNCİRLEME SONUÇ — ATLAMA:**
Birleştirme aynı eşyadan birden fazla adet gerektiriyor. Yani mağaza artık
**aynı eşyayı birden fazla kez satabilmeli.** Şu an ikinci satın alma
engelleniyor (`root_shell.dart:_purchaseEquipment` ilk satırda
`if (_profile.ownedItemIds.contains(item.id)) return;`). Bu davranışı değiştir:
- aynı eşya tekrar alınabilsin, envanterde **ayrı bir örnek** olarak dursun,
- mağazadaki "Sahipsin" işareti **adet** göstersin ("3 adet"),
- bu değişikliğin kırdığı satın alma testlerini **güncelle** (silme):
  `test/store_purchase_test.dart`, `test/store_screen_test.dart`,
  `test/inventory_test.dart`.

Ayrıca `EquippedBuffs.from` ve `_refreshEquipment` örnek tabanlı hâle gelecek;
`ItemCatalog.byId(id, characterClass:)` çağrısı **korunmalı** (GD16: buff sınıfa
göre çözülüyor).

#### 4.2 Eşya seviyesi

- Her örnek **seviye 1**'de başlar.
- Oyuncu **coin** harcayarak seviye yükseltir.
- Seviye yükseldikçe **SAVAŞ STATLARI** artar.
- ⚠️ **EKONOMİ BUFF'LARI (adım→para, adım→XP, çark şansı) ARTMAZ, SABİT KALIR.**
  Sebep: ekonomi dikkatle dengelendi (`economy_pacing_test.dart`), çarpan
  büyürse günlük tavan katlanır ve denge çöker. **Bu kuralı koda yorum olarak
  ve buraya yaz.**

**İKİ TAVAN, ikisi de geçerli — eşya seviyesi ikisinin de altında kalmalı:**

a) **Nadirliğe göre maks seviye.** Öneri (uygun bulmazsan değiştir, gerekçelendir):
   `Sıradan 10 · Az Bulunur 20 · Nadir 30 · Epik 40 · Efsanevi 50`
   Böylece nadirlik kalıcı bir üstünlük olur, sıradan bir eşya asla efsaneviye
   yetişemez.

b) **Oyuncu seviyesi.** Eşya seviyesi oyuncu seviyesini **geçemez.**
   1. seviyedeki oyuncu eşyasını max'a çıkaramaz — istenen bu.

Yükseltme maliyeti seviyeyle artsın ve nadirlikle ölçeklensin. **Ekonomiye göre
hesabını yap ve tabloyu buraya yaz:** 6000 adım/gün atan oyuncu (120 coin/gün)
bir eşyayı 10. seviyeye kaç günde çıkarır? **Hedef: yükseltmek yeni eşya
almakla YARIŞABİLİR olsun** — ne bariz daha ucuz ne bariz daha pahalı.

Denge zemini (Aşama 3'ten): sıradan item 100–125 coin (seviye 1–3), az bulunur
300–350 (4–7), nadir 775–875 (8–12), epik 2375–2725 (14–19), efsanevi
7550–8825 (22–29). Referans oyuncu 120 coin/gün.

#### 4.3 Birleştirme

Aynı eşyadan N örnek + coin → 1 örnek, **bir üst nadirlikte**.

**Gereken adet nadirlikle artar — 3'ten başlar, her kademede +1:**
```
Sıradan → Az Bulunur : 3 adet
Az Bulunur → Nadir   : 4 adet
Nadir → Epik         : 5 adet
Epik → Efsanevi      : 6 adet
```
Bu sayılar **tek bir config sabitinde** dursun, koda gömülmesin
(`GameConstants` deseni).

- Birleştirilen örnekler **aynı itemId ve aynı nadirlikte** olmalı.
- Seviyeleri farklı olabilir; sonuçtaki örneğin seviyesi ne olacak, **karar ver
  ve gerekçelendir** (öneri: **1'e dönmesi** — en yükseği korumak birleştirmeyi
  her zaman baskın strateji yapar; maliyeti buna göre ayarla).
- Efsanevi üstü nadirlik yok → efsaneviler birleştirilemez (ya da başka bir
  ödüle dönüşür, karar senin).
- Birleştirme maliyeti nadirlikle artsın.
- **Kuşanılı bir eşya birleştirmeye girerse önce çıkarılsın**, sessizce
  kaybolmasın.
- Onay ekranı: ne kaybediyorum, ne kazanıyorum, **net** gösterilsin.
- **Geri alınamaz olduğu açıkça söylensin.** (Satış onayı deseni hazır:
  `inventory_screen.dart`, GD29.)

#### 4.4 Demirci arayüzü

Envanterde belirgin bir **demirci/örs** işareti olsun. Oradan:
- **Yükseltme:** mevcut seviye, sonraki seviyedeki statlar, maliyet, "yükselt".
- **Birleştirme:** aynı eşyadan kaç adet var, gereken adete ulaşıldı mı, maliyet.
- Tavana ulaşıldıysa sebebi **net** söylensin: "Nadirlik sınırı (Sıradan: 10)"
  veya "Kendi seviyeni geçemez (Sv. 7)" — hangisi bağlayıcıysa o.
- **Yetersiz bakiye, yetersiz adet, tavan — hiçbiri sessiz kalmasın**
  (Model Kuralları #4).
- Yükseltmeden önce/sonra **stat farkı** gösterilsin
  (`lib/core/utils/item_comparison.dart` hazır desen).

#### 4.5 Mağazada duyur

- Eşya kartında: "Yükseltilebilir · Maks Sv. 30" gibi net bilgi.
- "3 tanesini birleştirerek nadirliğini yükseltebilirsin" (gereken adet
  nadirliğe göre değiştiği için **doğru sayıyı** göster).
- Nadirlik farkını göster: "Efsanevi eşyalar Sv. 50'ye kadar yükselir".
- Amaç: oyuncu satın almayı **kalıcı bir yatırım** olarak görsün.
- ⚠️ Mağaza kartı yüksekliği artık **esnek** (K9, `SliverList` + iki hücreli
  `Row`); yeni satır eklemek serbest ama `test/store_screen_test.dart`
  içindeki **altı genişlikte taşma testleri** geçmeli.

#### 4.6 Test

Şema migration, iki tavanın da doğru bağlaması, yükseltme maliyeti, **ekonomi
buff'larının artMAması**, birleştirme (nadirliğe göre değişen adet şartı,
nadirlik artışı, kuşanılı eşya durumu, efsanevi sınırı), aynı eşyanın tekrar
satın alınması, kalıcılık.

---

### BÖLÜM 5 — Günlük döngüyü maceraya bağla

#### a) Streak tetikleyicisi
**2000 adım DEĞİL, günde BİR MACERA TAMAMLAMAK.** Adım eşiği tamamen kalkıyor.
- `GameConstants.streakStepThreshold`'u **kullanımdan çıkar** (sil değil —
  `equipped_buffs.dart:streakStepThreshold` ve `streakRelief` buff'ı buna
  bağlı; o buff türü de yeniden anlamlandırılmalı).
- "Tamamlamak" kazanmak mı bitirmek mi? **Öneri: kazan-kaybet fark etmez,
  bitirmek yeter.** Kaybetmenin zaten cezası var, üstüne streak kaybı çifte
  ceza olur. Karar senin, gerekçelendir.
- Arayüzdeki **tüm "2000 adım" metinlerini** güncelle. Bugünkü yerler:
  `home_screen.dart:454,493` (`_StreakCard`), `inventory_screen.dart:583,588`
  (karakter paneli), `root_shell.dart:645` (tetikleyici).
- Ana ekrandaki streak kartı **"bugün macera yaptın mı"** göstersin.

#### b) Çark kilidi
Çarkın ilk açılışı için istenen **3000 adım** şartını kaldır
(`GameConstants.dailyWheelUnlockSteps`, `DailyProgress.isWheelUnlocked`,
`home_screen.dart:160`), yerine **1 macera tamamlama** şartı koy.
- Şartın **tekrarlama mantığına (günlük mü, tek seferlik mi) DOKUNMA** —
  sadece koşulu değiştir.
- Kilitliyken sessiz kalmasın: "Çarkı açmak için bir macera tamamla".
- **Günlük hak kısıtı aynen kalsın** (`UserProfile.wheelSpunToday`,
  `extraWheelSpins`).

#### c) Streak stat bonusu
Günlük streak arttıkça **tüm SAVAŞ statları** çok az artsın.

**Öneri (uygun bulmazsan değiştir ama gerekçelendir):**
> Streak günü başına **+%0,5**, tavan **+%30** (60 günde dolar).
> 7 gün = +%3,5 · 30 gün = +%15 · 60+ gün = +%30

Gerekçe: her gün küçük ama hissedilir kazanç, uzun vadede anlamlı hedef, tavan
sayesinde eski oyuncu yeniyi ezmiyor.

- ⚠️ **EKONOMİ BUFF'LARINA UYGULAMA.** Sadece savaş statları.
- Streak kırılınca bonus da gider. Bu **bilerek** — streak'i değerli kılan bu ve
  streak dondurma hakkının 600 coin'lik fiyatını haklı çıkarıyor.
- Karakter panelinde ayrı satır: "Seri bonusu: +%7,5"
  (`inventory_screen.dart` karakter paneli).
- Streak kırılma uyarısı bonusu da hatırlatsın: "Serini kaybedersen +%15 stat
  bonusun gider." (`home_screen.dart:_StreakCard` turuncu uyarı satırı hazır.)

Şema değişikliği gerekiyorsa sürümü artır ve migration yaz.

**Test:** macera tamamlanınca streak artıyor mu, aynı gün ikinci macera
artırmıyor mu, çark kilidi doğru açılıyor mu, stat bonusu doğru mu, tavan
çalışıyor mu, streak kırılınca bonus gidiyor mu, ekonomi etkilenmiyor mu.

**Dikkat:** `test/streak_test.dart` (20 test) ve `test/streak_freeze_test.dart`
(21 test) adım eşiğine dayanıyor. **Silme, birlikte güncelle.**

---

### BÖLÜM 6 — Kalan gerçek hatalar
Yukarıdaki §4'teki **A3, A4, A6, A7** ve savaş sahnesindeki metin katmanı.
(A3 ve A4 zaten Bölüm 3 ile birlikte kapanacak.)

### BÖLÜM 7+ — CLAUDE.md'deki kalan açık işler
Firebase gerektirenler **hariç**. Kaynak: bu dosyadaki "OTURUM KAPANIŞI —
2026-08-20" bölümünün §4 ve §5 tabloları. Öne çıkanlar:
- **Aşama 4a — savaş motoru (#4).** ⚠️ Determinizm şartı: `Random()` savaş
  kodunda **yasak**, tohum enjekte edilip durumla saklanacak. İzlenecek örnek:
  `wheel_rewards.dart` + `UserProfile.wheelSeed` (GD18). Ayrıca iki HP
  kavramının birleştirilmesi, A2 (düşman canı = adım hedefi), A3
  (`stepGoal` üç iş birden).
  → **Bölüm 4 ve 5'in savaş statları bu motora bağlanacak; ikisi de bugün
  "gösteriliyor ama uygulanmıyor" durumunda.**
- **Aşama 4b — #14 canavara göre ödül.** `Reward.icon` bir `IconData`;
  Model Kuralları #1 gereği `String` anahtara çevrilmeli. `RootShell._rewards`
  hiç doldurulmuyor (triaj C5).
- **Aşama 5 — #3 (slide scroll adım seçimi), #6 (VS ekranı), #18 (avatar asset).**
- **Aşama 6 — Firebase → takım savaşları. ⛔ ARKADAŞIMIN İŞİ, DOKUNMA.**
- Küçük borçlar: C3 (`tz.UTC` sabit), C4 (hatırlatma metinleri iki yerde),
  C6 (`sideBySideWindowMinutes` ölü sabit), C7, C9, C10, C11, C13, iOS derleme
  borçları (`ios/Podfile` yok, `AppDelegate.swift` Windows'ta derlenmedi).

## 6. Önerilen sıra

1. ~~**Bölüm 3** (buff çeşitliliği) + **A3** + **A4**~~ ✅ **BİTTİ**
   (2026-08-25) — bkz. "Bölüm 3 — Buff çeşitliliği" bölümü, GD36–GD38.
2. ~~**Bölüm 4.1–4.2** (veri yapısı + eşya seviyesi)~~ ✅ **BİTTİ**
   (2026-08-25) — şema v12, mağaza çoklu satın alma; bkz. "Bölüm 4.1–4.2"
   bölümü, GD39–GD41.
3. ~~**Bölüm 4.3–4.6** (birleştirme + demirci arayüzü + mağaza duyurusu)~~
   ✅ **BİTTİ** (2026-08-25) — bkz. "Bölüm 4.3–4.6" bölümü, GD42–GD43.
4. **Bölüm 5** (streak ↔ macera, çark kilidi, streak stat bonusu).
5. **Bölüm 6** (A6, A7, savaş sahnesi metin katmanı).
6. Bölüm 7+ — Aşama 4a savaş motoru.

**Neden bu sıra:** Bölüm 4'ün "savaş statları artar" sözü ile Bölüm 5'in "streak
savaş statlarını artırır" sözü **aynı stat toplama noktasına** bakıyor
(`lib/core/utils/equipped_buffs.dart`). Bölüm 3 o statların nasıl üretildiğini
değiştiriyor. Sıra bozulursa aynı yer üç kez yazılır.

## 7. Bu oturumda eklenen dosyalar

```
test/character_creation_test.dart        # sınıf seçim ekranı (18 test)
test/adventure_progress_test.dart        # macera ilerleme + A1 regresyonu (13 test)
test/golden/_smoke_golden_test.dart      # golden altyapısı duman testi
test/golden/goldens/_smoke.png
test/golden/goldens/class_grid_320.png
test/golden/goldens/class_grid_360.png
test/golden/goldens/class_reveal_320.png
test/golden/goldens/class_reveal_360.png
test/golden/goldens/class_reveal_800.png
test/golden/goldens/adventure_320.png
test/golden/goldens/adventure_390.png
```


---
---
---

# Bölüm 5C — Seri savaş stat bonusu ✅ (2026-08-25)

Seri artık yalnızca bir sayaç değil: her gün savaş statlarından **birini**
kalıcı olarak büyütüyor. Kararlar **GD44–GD46**. Şema **v12 → v13**.

> **Not — Bölüm 5a ve 5b yapılmadı.** Seri tetikleyicisi hâlâ 2000 adım
> (`GameConstants.streakStepThreshold`), çark kilidi hâlâ 3000 adım
> (`dailyWheelUnlockSteps`). "Macera tamamlamak" şartına geçiş **Bölüm 8.5**'in
> zincirleme sonucu olarak orada ele alınacak: iki fazlı macerada
> "tamamlamak"ın ne demek olduğu orada cevaplanıyor, ikisini ayrı yapmak aynı
> yeri iki kez yazmak olurdu.

## Tasarım

| Kural | Değer |
|---|---|
| Gün başına | seçilen stata **+%1** (`streakStatBonusPerDay`) |
| Stat başına tavan | **+%25** (`maxStreakStatBonus`) → 25 gün |
| Toplam tavan | **+%100** (`maxStreakTotalBonus`) → ~100 gün |
| Havuz | `ItemStat.isCombat` olan **7 stat**: saldırı, savunma, savaş canı, kritik şansı, kritik hasarı, can çalma, sıyrılma |
| Tavandaki stat | havuzdan çıkar, gün boşa gitmez |
| Seri kırılınca | birikimin **tamamı** gider |
| Dondurma hakkı | birikimi **korur** (seri artmaz ama kırılmaz) |

7 × %25 = %175 > %100, yani toplam tavan bağlayıcı. Bu ilişki testle bağlı:
sabitlerden biri değişirse alarm verir.

## Kalıcılık ve zar atma koruması

Çekiliş **yol bağımlı** (tavana ulaşan stat havuzdan çıkıyor), bu yüzden tek
başına tohum yetmiyor — birikimin kendisi diske yazılıyor. Gerekçe **GD45**.

| Alan | İş |
|---|---|
| `streakStatBonuses` | Stat → kazandırılmış **gün sayısı**. Oran türetiliyor. |
| `streakBonusSeed` | Çekilişin tohumu; çarkınkinden ayrı akış. `0` = kurulmadı. |
| `lastStreakBonusDay` | Bonusun verildiği son oyun günü; aynı gün ikinci çekiliş yok. |

**Gün sayısı tutuluyor, oran değil:** `0.01` yirmi beş kez toplanınca `0.25`
etmiyor (`0.2499…`) ve stat tavana hiç oturmuyordu. Tam sayı hem kayıt turunda
kaymıyor hem tavan karşılaştırmasını kesin yapıyor.

## Arayüz

- **Profil → Karakter Gücü**: "Seri Bonusu" bölümü; hangi stata kaç gün ve ne
  kadar oran biriktiği **stat stat**. Bölümün kendi sütun başlıkları var
  (`GÜN / BONUS / DURUM`) — üstteki tablonun "EKİPMAN" başlığını paylaşmak
  yanıltıcı olurdu. Tavandaki stat "tavan" etiketiyle işaretli.
- **Yeni gün bildirimi**: "3. gün: +%1 kritik şansı (seriden toplam +%3)".
  Stat tavana oturduysa ya da toplam tavan dolduysa bunu da söylüyor
  (Model Kuralları #4).
- **Ana ekran seri kartı**: tek satırlık özet; kırılma uyarısı artık birikimi
  de hatırlatıyor ("Biriken +%15 savaş bonusun gider.").
- **Kırılma anı**: seri kırıldığında ne kaybedildiği söyleniyor.

## Bugün uygulanmıyor — ve bu bilinçli

Savaş statlarının hiçbiri bugün bir yere uygulanmıyor (item savaş statları da
öyle, bkz. GD24/GD38). Bonus üretiliyor, saklanıyor ve gösteriliyor; savaş
motoru **Bölüm 7**'de yazılınca item + eşya seviyesi + birleştirme + seri
bonusu dördü birden canlanacak. Toplama noktası tek olmalı.

## Test

- `test/streak_stat_bonus_test.dart` — **25 test**: havuzun canlı stat
  listesinden türemesi ve ekonomi statlarını içermemesi, determinizm (aynı
  tohum → aynı stat, aynı gün ikinci çağrı `null`, kapat-aç turu aynı diziyi
  sürdürüyor, farklı oyuncular farklı dizi), tohumun her günde ilerlemesi,
  stat başına ve toplam tavan, tavandaki statın havuzdan çıkması, tavan
  dolunca serinin yine ilerlemesi, dağılımın tek stata yığılmaması, seri
  kırılınca sıfırlanma, dondurma hakkının koruması, tohumun kırılmada
  sıfırlanmaması, sekiz ekonomi statının hiç etkilenmemesi, bozuk ve tavan
  üstü kayıtların kırpılması, v12 kaydının temiz varsayılana düşmesi.
- `test/streak_bonus_shell_test.dart` — **6 test** (gerçek `RootShell`):
  eşik geçilince bonusun verilip duyurulması, **seviye atlansa bile
  bildirimin yutulmaması** (GD46 regresyonu), aynı gün ikinci partinin bonus
  vermemesi, diske yazılması, profilde ve ana ekranda gösterilmesi.
- `test/golden/streak_bonus_golden_test.dart` — **3 test**: 320/390 dp golden
  (PNG'ler üretildi ve gözle doğrulandı) + bonus yokken bölümün hiç çıkmaması.

Toplam **588 test geçiyor**, `flutter analyze` temiz.

---
---

# Bölüm 6 — Kalan gerçek hatalar ✅ (2026-08-25)

Faz 0'da bulunan beş hata kapatıldı. Her biri için **önce hatayı yakalayan
test** yazıldı, sonra düzeltildi. Kararlar **GD47–GD48**.

## 1. Hasar mesajı savaş sahnesini örtüyordu · **yüksek**

- **Nerede:** `adventure_screen.dart`, `_pendingDamage > 0` katmanı
- **Ne:** "Düşmanın N canını aldın. Böyle devam et!" mesajı `titleLarge` ile ve
  **satır sınırı olmadan** çiziliyordu. Sahne 260 px yüksekliğinde; ölçülen
  mesaj yüksekliği **320 dp'de 168 px, 390 dp'de 112 px**. Yani mesaj sahnenin
  yarısından fazlasını kaplıyor, hem oyuncuyu hem düşmanı örtüyordu.
- **Düzeltme:** `titleSmall`, `maxLines: 2`, okunurluk için yarı saydam koyu
  şerit, metin kısaltıldı ("Böyle devam et!" düştü). Ölçülen yeni yükseklik
  ikisinde de 65 px'in altında.
- **Test:** `adventure_progress_test.dart` → "hasar mesajı savaş sahnesini
  örtmez" (320/390 dp, gerçek yükseklik ölçülüyor). Golden'lar yeniden
  üretildi ve gözle doğrulandı: iki figür de tam görünüyor.

## 2. Kilometre taşı bildirimi hiç görünmüyordu · **yüksek**

Ayrıntı ve gerekçe **GD47**. Ölçülen: 6 günlük seriyle 5000 adım atan
1. seviye oyuncu, kazandığı dondurma hakkını duyuran tek bildirimi
görmüyordu. Günlük coin tavanı bildirimi de aynı riski taşıyordu.

**Test:** `streak_bonus_shell_test.dart` → "kilometre taşı bildirimi de
yutulmaz" (aynı partide seviye + seri bonusu + kilometre taşı; üçünün de
görüldüğü doğrulanıyor).

## 3. Çark GIF karesi yüklemesinde hata yönetimi yoktu (triaj A6) · **orta**

- **Nerede:** `daily_wheel_screen.dart:StillGifFrame`
- **Ne:** `rootBundle.load` ve `instantiateImageCodec` `try/catch` içinde
  değildi. Asset eksik ya da bozuksa **yakalanmayan asenkron istisna**
  çıkıyordu; `_load()` bekletilmediği için hata çark ekranını açan başka bir
  yere düşüyordu. Hata yolunda yarım kalan `Codec`/`Image` de bırakılıyordu.
- **Düzeltme:** `try/catch`, `debugPrint` ile loglama, yarım kaynakların
  dispose'u, widget boş çizerek ayakta kalıyor. Aynı dosyadaki
  `GifTiming._measure` bu deseni zaten izliyordu.
- **Test:** `still_gif_frame_test.dart` — 3 test. Widget public yapıldı
  (**GD48**); test ortamında yükleme gerçek asenkron iş olduğu için
  `runAsync` kullanılıyor.

## 4. `CharacterCatalog` önbelleği geçersizleşmiyordu (triaj A7) · **düşük**

`reset([List<CharacterClass>?])` eklendi — `ItemCatalog.reset` ile birebir
aynı sözleşme. **Test:** `character_catalog_test.dart` içine `reset` grubu
eklendi (mevcut 7 test korundu, 3 test eklendi).

## 5. Adım hedefi seçicide denetleyici sızıntısı · **düşük**

- **Nerede:** `adventure_screen.dart:_showGoalPicker`
- **Ne:** `FixedExtentScrollController`, `showModalBottomSheet` `await`'inden
  **sonra** dispose ediliyordu. Bekleyiş bir istisnayla sonlanırsa
  `dispose()` hiç çalışmıyordu.
- **Düzeltme:** `try/finally`.
- **Test:** `goal_picker_test.dart` — 3 test (seçim, vazgeçme, arka arkaya
  açıp kapatma; hiçbir yolda istisna çıkmıyor). Seçicinin daha önce hiç
  testi yoktu.

## Süreç notu — üzerine yazılan test dosyası

Bu birim sırasında `test/character_catalog_test.dart` yanlışlıkla **sıfırdan
yazıldı** ve mevcut 7 test kayboldu. Testlerin toplam sayısı beklenenden 7
eksik çıkınca fark edildi (595 yerine 602 bekleniyordu), dosya `git checkout`
ile geri alındı ve yeni testler **eklendi**. Ders: yeni bir test dosyası
oluşturmadan önce aynı adda dosya olup olmadığı kontrol edilmeli; toplam test
sayısı her birimden sonra beklenen değerle karşılaştırılmalı.

Toplam **600 test geçiyor**, `flutter analyze` temiz.

---
---
---

# Bölüm 7 — Aşama 4a: Savaş motoru ✅ (2026-08-26)

Kart **#4** kapandı. `TODO(combat)` kalktı; triajdaki **A2** (düşman canı =
adım hedefi) ve **A3** (`stepGoal` üç iş birden) kapandı; **B2**'nin açık
yarısı (iki can kavramı) çözüldü. Kararlar **GD49–GD54**. Şema **v13 → v14**.

## Öncesinde ne eksikti

| # | Eksik | Durum |
|---|---|---|
| 1 | `TODO(combat)`: düşman canı = adım hedefi, her adım 1 hasar | ✅ |
| 2 | `Enemy` yalnızca `attackDamage` taşıyor | ✅ 9 statlı `CombatStats` |
| 3 | 7 savaş statı tanımlı ama hiç okunmuyor | ✅ motor okuyor |
| 4 | Hız/inisiyatif ve şans statları yok | ✅ eklendi (GD52) |
| 5 | Taban stat kavramı yok; seviyenin savaşa etkisi yok | ✅ `base_combat_stats.dart` |
| 6 | 6 koşullu/tetiklenen efekt türü uygulanmıyor | ✅ hepsi çalışıyor |
| 7 | Eşya seviyesi ve birleştirme savaş statlarını büyütüyor → etkisiz | ✅ canlı |
| 8 | Seri bonusu (5C) → etkisiz | ✅ canlı |
| 9 | İki can kavramı | ✅ tek kaynak: `AdventureQuest` (GD53) |
| 10 | Tohum yok; determinizm kazara | ✅ enjekte + saklanan (GD50) |
| 11 | `stepGoal` üç iş birden | ✅ yalnızca yürüyüş taahhüdü (GD49) |

## Stat seti — dokuzu da savaşta iş yapıyor

`lib/models/combat_stats.dart`. Süs stat yok:

| Stat | Savaşta ne yapıyor |
|---|---|
| saldırı | Hasarın çıkış noktası |
| savunma | `azalma = savunma / (savunma + 50)` — azalan getiri, asla %100 değil |
| savaş canı | Can tavanı; macera başlarken oyuncunun canı buna eşitlenir |
| kritik şansı | Vuruşun hasarını `1 + kritik hasarı` ile çarpma ihtimali (tavan %60) |
| kritik hasarı | O çarpanın büyüklüğü |
| can çalma | Verilen hasarın bu oranı kadar can yenilenir |
| sıyrılma | Gelen vuruşu tamamen boşa çıkarma ihtimali (tavan %40) |
| **hız** | İnisiyatif: turda kim önce vurur. Öldürücü turda belirleyici |
| **şans** | Kritik/sıyrılma ihtimaline katkı + hasar bandını yukarı kaydırır |

## Stat kaynakları — tek toplama noktası

`core/utils/effective_stats.dart`:

```
değer = (taban + ekipmanSabit) × (1 + ekipmanOran + seriOran + koşulluOran)
```

Dört kaynak: **taban** (seviye) + **ekipman** (eşya seviyesi ve birleştirme
dâhil; `EquippedBuffs` zaten `scaleForLevel` uygulanmış itemleri topluyor) +
**seri** (Bölüm 5C) + **koşullu etkiler**. Motor ikinci bir hesap yazmıyor;
karakter paneli de aynı fonksiyonu okuyor.

Sabit katkı çarpandan **önce** giriyor: aksi hâlde "+12 saldırı" veren bir
item, oran bonusları büyüdükçe kendiliğinden değersizleşirdi.

## Motor

`core/utils/combat_engine.dart` — saf, arayüzden bağımsız, deterministik
(GD50).

**Adım ↔ savaş bağı korundu:** roundun tamamlanma oranı oyuncunun vuruşunu,
kaçırılan oran düşmanınkini ölçekliyor. Yani tam round = tam vuruş + hiç hasar
almama; hiç yürümemek = hiç vuramamak + tam hasar. Motordan önceki davranışın
statlarla zenginleşmiş hâli.

**Tur akışı:** inisiyatif (hız) → sıyrılma → kritik → değişkenlik (±%12, şans
bandı yukarı kaydırır) → savunma → can çalma. Savunan ilk vuruşta öldüyse
ikinci vuruş yapılmıyor — hız bu yüzden gerçek bir stat.

**Altı koşullu tetikleyicinin hepsi çalışıyor:** `lowHealth`, `highHealth`,
`untouchedRounds`, `nightWalk`, `streakActive` durum üzerinden
(`CombatConditions`); `onHit` ve `onKill` olay üzerinden, motorun içinde
(GD54).

## Düşmanlar

20 düşmanın hepsi savaş statı aldı; statlar kademe + arketipten türetiliyor
(GD51). Dört davranış: **Dengeli** (6), **Dayanıklı** (4), **Çevik** (5),
**Büyücü** (5).

Ölçülen denge (ölçüt = kademeye denk seviyedeki ekipmansız oyuncu):

| Kademe | Arketip | Can | Saldırı | Devirme | Beklenen | Ölüm |
|---|---|---|---|---|---|---|
| 1 | Dayanıklı | 13 | 13,8 | 2 | 1 | 9 |
| 5 | Çevik | 36 | 23,1 | 3 | 3 | 8 |
| 10 | Çevik | 88 | 34,1 | 4 | 5 | 7 |
| 13 | Büyücü | 141 | 34,0 | 5 | 7 | 9 |
| 14 | Dayanıklı | 252 | 39,3 | 10 | 7 | 8 |
| 20 | Büyücü | 266 | 91,7 | 8 | 10 | 5 |

"Ölüm" = hiç yürümeyen oyuncunun kaç roundda düştüğü; hedef ~7, ölçülen bant
4–12. Sayıların hepsi motor çalıştırılarak ölçülüyor ve
`combat_balance_test.dart` ile bağlı.

## Şema v14 — eski macera sıfırlanmıyor

Yarım kalmış bir macera **sadakatle taşınıyor**: eski modelde düşmanın kalan
canı `stepGoal - atılanAdım` idi; o oran yeni can tavanına uygulanıyor.
Oyuncunun canı da 0–100 ölçeğinden oranı korunarak yeni tavana taşınıyor.
Aksi hâlde neredeyse ölmüş bir düşman güncelleme sonrası tam canla geri
gelirdi. Düşman kataloğu saf Dart (asset okumuyor), o yüzden taşıma sırasında
güvenle sorgulanabiliyor.

`acknowledgedDamage` alanının **anlamı değişti** (adım sayısı → gösterilen son
round serisi); taşıma onu sıfırlıyor, yoksa açılışta sahte bir hasar mesajı
çıkardı.

## Arayüz

- **Karakter paneli**: savaş statları artık "savaş sistemiyle birlikte
  etkinleşecek" demiyor — dokuz statın **taban / bonus / toplam** değerleri
  gerçek sayılarla görünüyor.
- **Düşman önizlemesi**: can, saldırı, savunma ve arketip rozetleri +
  tek cümlelik davranış açıklaması ("Yavaş ama çok dayanıklı…"). Oyuncu neyle
  karşılaştığını savaşa girmeden biliyor.
- **Can barları**: düşman canı artık adım değil, gerçek can (`87 / 143`).
- Geri sayım kartındaki "en fazla N can vurur" cümlesi kaldırıldı — savunma
  devreye girdiği için o sayı artık doğru değildi.

## Test

- `test/combat_engine_test.dart` — **32 test**: determinizm (aynı tohum aynı
  sonuç, tohum ilerlemesi, motorun kendi başına zar atmaması), adım↔hasar
  bağı ve sınır dışı oranların kırpılması, dokuz statın her birinin etkisi,
  inisiyatifin öldürücü turdaki rolü, tavanlar, sonlanma koşulları, `onHit` /
  `onKill` ve bitirici vuruş.
- `test/combat_balance_test.dart` — **21 test**: 20 düşmanın statları,
  kademe ve arketip tutarlılığı, katalogdaki elle yazılmış saldırı farkının
  korunması, ölçüt oyuncunun devirme süresi, tam yürüyende sıfır hasar,
  ölüm süresi bandı, seviye farkının savaşı kısaltması, ekipman/seri/koşullu
  etkilerin statlara işlemesi ve ekonomiye **dokunmaması**.
- `test/combat_persistence_test.dart` — **9 test** (gerçek `RootShell`):
  can tavanının açılışta tazelenmesi, yedek tohumun deterministikliği,
  adımın roundu çözmesi, zafer ve XP, seviye atlayınca tavanın büyümesi,
  diske yazma, kapat-aç turunda aynı sonuç, **v13 yarım macerasının sadık
  taşınması**.
- Güncellenen (silinmedi): `adventure_quest_test.dart` (sabit hasar sayıları
  yerine ilişkiler bağlandı, düşman canının adımdan bağımsızlığı eklendi),
  `adventure_progress_test.dart` (hasar mesajı artık round çözümünde çıkıyor).

Toplam **664 test geçiyor**, `flutter analyze` temiz.

## Açık kalan

- **Bölüm 8** — iki fazlı macera. Zemin hazır: güçlü oyuncu düşmanı adım
  hedefinden önce deviriyor ve bu testle bağlı.
- Itemler `speed` / `luck` vermiyor (GD52) — ayrı bir denge geçişinin işi.
- Round süresi hâlâ test dengesi (`AdventureQuest.roundDuration` = 30 sn).

---
---
---

# OTURUM KAPANIŞI — 2026-08-25 (AKŞAM)

> ⚠️ **ESKİ — güncel devam noktası dosyanın en sonundaki 2026-08-26
> kapanışıdır.** Bu bölüm tarihsel kayıt; §2'deki "SIRADAKİ İŞ — BÖLÜM 5"
> tamamlandı (Bölüm 5C), §3'teki Bölüm 6 ve Bölüm 7 de tamamlandı.

## 0. Bu oturumda ne bitti

| Bölüm | Ne | Test | Kararlar |
|---|---|---|---|
| **Bölüm 3** | Buff çeşitliliği: arketip sistemi + ağırlıklı ekonomi çekilişi | 453 → 470 | GD36–GD38 |
| **Bölüm 4.1–4.2** | Envanter örnek listesine geçti (şema **v12**), mağaza çoklu satın alma, eşya seviyesi | 470 → 511 | GD39–GD41 |
| **Bölüm 4.3–4.6** | Birleştirme, ayrı demirci ekranı, mağaza yatırım duyurusu | 511 → **554** | GD42–GD43 |

Üçü de kullanıcı tarafından **commit edildi**. Ayrıntılar dosyadaki
"Bölüm 3", "Bölüm 4.1–4.2" ve "Bölüm 4.3–4.6" bölümlerinde.

Kapanan Faz 0 hataları: **A3** (testler ölü sınıfları doğruluyordu),
**A4** (sınıf imzaları çakışıyordu). İkisi de Bölüm 3 ile kapandı.

**Durum:** `flutter analyze` temiz · **554/554 test geçiyor** · paket
eklenmedi · şema **v12** · çalışma ağacında yalnızca bu CLAUDE.md
değişikliği kalmış olmalı.

## 1. ⚠️ İLK İŞ: test ortamı

```powershell
flutter test --no-test-assets
```

Bu bayrak **olmadan hiçbir test çalışmaz** (araç çöker). Gerekçe ve
`ink_sparkle.frag` kopyalama adımı için dosyadaki **"Test ortamı — testler
neden `--no-test-assets` ile çalışıyor"** bölümünü oku.

Golden üretmek: `flutter test --no-test-assets --update-goldens test/golden/`.
`pumpAndSettle` yerine sabit kare dizisi kullan (sonsuz animasyonlar var).

**Yararlı alışkanlık:** test çıktısı çok uzun; log'u dosyaya yazıp `[E]`
satırlarını süzmek bu oturumda çok işe yaradı.

## 2. SIRADAKİ İŞ — BÖLÜM 5

**Tam şartname:** SABAH kapanışının §5 → "BÖLÜM 5 — Günlük döngüyü maceraya
bağla". Özet:

- **(a) Streak tetikleyicisi:** 2000 adım **değil**, günde **bir macera
  tamamlamak**. `GameConstants.streakStepThreshold` kullanımdan çıkacak.
  ⚠️ `EquippedBuffs.streakStepThreshold` ve `streakRelief` buff türü ona
  bağlı — **o buff türü yeniden anlamlandırılmalı** (yoksa ölü bir bonus
  kalır ve GD36'nın "boşta tür kalmasın" invariantı kırılır).
- **(b) Çark kilidi:** `dailyWheelUnlockSteps` (3000 adım) yerine 1 macera
  tamamlama. Tekrarlama mantığına **dokunma**.
- **(c) Streak savaş stat bonusu:** gün başına +%0,5, tavan +%30. **Yalnızca
  savaş statları** — ekonomiye uygulanmayacak.

**Dikkat edilecekler (bu oturumdan çıkan bilgi):**
- Savaş stat bonusunun toplandığı yer `lib/core/utils/equipped_buffs.dart`;
  eşya seviyesi çarpanı `item_leveling.dart:scaleForLevel`. Streak bonusu
  ikisinin **üstüne** binen üçüncü bir katman — nereye ekleneceği bilinçli
  seçilmeli (öneri: `EquippedBuffs`'a bir `streakMultiplier` alanı, çünkü
  savaş statlarının tek toplama noktası orası).
- Arayüzdeki "2000 adım" metinleri: `home_screen.dart` (`_StreakCard`),
  `inventory_screen.dart` (karakter paneli), `root_shell.dart`
  (`_onStepsReported` tetikleyici dalı).
- `test/streak_test.dart` (20) ve `test/streak_freeze_test.dart` (21) adım
  eşiğine dayanıyor. **Silme, birlikte güncelle.**
- Şema değişirse sürümü artır (v12 → v13) ve migration yaz.

## 3. Sonra ne var

- **BÖLÜM 6** — kalan Faz 0 hataları: **A6** (çark GIF karesi yüklenirken
  try/catch yok), **A7** (`CharacterCatalog._cache` hiç geçersizleşmiyor,
  `reset()` yok) ve 320 dp'de savaş sahnesindeki görev metni katmanının
  karakterlerin üstüne binmesi. Üçünün de tarifi SABAH kapanışının §4'ünde.
- **BÖLÜM 7+** — **Aşama 4a savaş motoru (#4).** ⚠️ Determinizm şartı:
  `Random()` savaş kodunda yasak, tohum enjekte edilip durumla saklanacak
  (izlenecek örnek: `wheel_rewards.dart` + `UserProfile.wheelSeed`, GD18).
  Sonra Aşama 4b (#14 canavara göre ödül), Aşama 5 (#3/#6/#18).
  **Firebase (Aşama 6) arkadaşımın işi — dokunma.**

## 4. Bu oturumda eklenen dosyalar

```
lib/data/item_archetypes.dart              # arketip tabloları (veri)
lib/widgets/archetype_badge.dart           # arketip rozeti
lib/models/owned_item.dart                 # envanter örneği
lib/core/utils/item_leveling.dart          # eşya seviyesi (saf)
lib/core/utils/item_merging.dart           # birleştirme (saf)
lib/features/inventory/blacksmith_screen.dart

test/item_variety_test.dart                # buff çeşitliliği (14)
test/item_leveling_test.dart               # seviye kuralları (28)
test/item_merging_test.dart                # birleştirme kuralları (22)
test/blacksmith_test.dart                  # demirci, RootShell üzerinden (16)
test/golden/store_card_golden_test.dart    # mağaza kartı (3)
test/golden/blacksmith_golden_test.dart    # demirci paneli (3)
test/golden/forge_golden_test.dart         # demirci ekranı (2)
test/golden/goldens/store_card_{320,390}.png
test/golden/goldens/blacksmith_{320,390}.png
test/golden/goldens/blacksmith_blocked_320.png
test/golden/goldens/forge_{320,390}.png
```

## 5. Bu oturumda **savaş motorunu bekleyen** birikim

Üç bölüm de savaş statlarını üretiyor ama **hiçbiri uygulanmıyor**:

| Kaynak | Ne üretiyor |
|---|---|
| Arketip (Bölüm 3) | Her itemde 1–3 savaş statı |
| Eşya seviyesi (4.2) | Seviye başına +%10 savaş statı |
| Birleştirme (4.3) | Nadirlik yükselince daha büyük savaş statı |
| Bölüm 5c (yapılacak) | Streak başına +%0,5 savaş statı |

Aşama 4a savaş motoru yazılınca dördü birden canlanacak. Toplama noktası
`EquippedBuffs.combatEffects` / `flatBonusFor` / `rateBonusFor` — motor oradan
okumalı, beşinci bir hesap yazmamalı.

## 6. Değişmeyen kurallar (hatırlatma)

- ⛔ **Firebase'e dokunma.**
- ⚠️ **`flutter run` çalışmıyor** (Smart App Control). Görsel iş = **golden**;
  PNG'yi üret, **oku ve gerçekten bak**, birden çok genişlik için üret.
- **Commit atma.** Bölüm bitince değişen dosyaları listele, özetle, tek satır
  conventional-commit mesajı öner.
- **Arkadaşımın kodu — varsayılan: dokunma.** Yalnızca gerçek hataları düzelt.
- Her adımdan sonra `flutter analyze` temiz + testler yeşil.



---
---
---

# ⭐ OTURUM KAPANIŞI — 2026-08-26 · SONRAKİ OTURUM BURADAN BAŞLASIN

> Bu bölüm **tek başına yeterlidir**. Kullanıcıya hiçbir şey sormadan devam
> edebilmek için gereken her şey burada: ne bitti, ne açık, sıradaki işin tam
> şartnamesi ne. Kullanıcının bağlamı (usage) sınırlı — soru sorma, karar
> gerektiren yerde en makul seçeneği kendin seç ve gerekçesini yaz.

## 0. Bu oturumda ne bitti

| Bölüm | Ne | Test | Kararlar |
|---|---|---|---|
| **Bölüm 5C** | Seri savaş stat bonusu (her gün rastgele bir stat, kalıcı birikim) | 554 → 588 | GD44–GD46 |
| **Bölüm 6** | Faz 0'da bulunan 5 gerçek hata | 588 → 600 | GD47–GD48 |
| **Bölüm 7** | Aşama 4a — savaş motoru (kart #4) | 600 → **664** | GD49–GD54 |

Ayrıntılar: dosyadaki "Bölüm 5C", "Bölüm 6" ve "Bölüm 7" bölümleri.

**Durum:** `flutter analyze` temiz · **664/664 test geçiyor** · paket
eklenmedi · şema **v14**.

### ⚠️ Commit durumu

- **Bölüm 5C commit edildi** (`1a9b8ca`).
- **Bölüm 6 commit edildi** (kullanıcı onayladı).
- **Bölüm 7 için commit onayı alınmadı** — oturum orada kesildi.
  Önerilen mesaj:
  `feat(combat): add a deterministic stat-driven combat engine with enemy archetypes`

Bölüm 7'nin dosyaları (commit edilmemişse):

```
M  CLAUDE.md
M  lib/data/enemy_catalog.dart                (20 düşmana arketip)
M  lib/features/adventure/adventure_screen.dart
M  lib/features/home/home_screen.dart
M  lib/features/inventory/inventory_screen.dart  (karakter paneli canlı statlar)
M  lib/features/profile/profile_screen.dart
M  lib/features/root/root_shell.dart          (motor bağlantısı)
M  lib/models/adventure_quest.dart            (savaş durumu)
M  lib/models/enemy.dart                      (CombatStats + arketip)
M  lib/models/item_effect.dart                (speed + luck)
M  lib/services/adventure_notification_service.dart
M  lib/services/game_storage.dart             (şema v14 + taşıma)
M  lib/widgets/hero_progress_rings.dart
M  test/adventure_progress_test.dart
M  test/adventure_quest_test.dart
M  test/golden/goldens/adventure_{320,390}.png
M  test/golden/goldens/streak_bonus_{320,390}.png
?? lib/core/utils/base_combat_stats.dart
?? lib/core/utils/combat_engine.dart
?? lib/core/utils/effective_stats.dart
?? lib/core/utils/enemy_stats.dart
?? lib/models/combat_stats.dart
?? test/combat_balance_test.dart              (21)
?? test/combat_engine_test.dart               (32)
?? test/combat_persistence_test.dart          (9)
```

`git status --short` ile doğrula: liste boşsa commit atılmış demektir.

## 1. ⚠️ İLK İŞ: test ortamı

```powershell
flutter test --no-test-assets
```

Bu bayrak **olmadan hiçbir test çalışmaz** (araç çöker). Gerekçe ve
`ink_sparkle.frag` kopyalama adımı için dosyadaki **"Test ortamı — testler
neden `--no-test-assets` ile çalışıyor"** bölümünü oku.

**Bash üzerinden `flutter test` bir hook tarafından engelleniyor** (Very Good
CLI istiyor). Testleri **PowerShell** aracıyla çalıştır. `flutter analyze` ve
`flutter pub get` her iki yoldan da çalışıyor.

Golden üretmek: `flutter test --no-test-assets --update-goldens <yol>`.
`pumpAndSettle` yerine sabit kare dizisi kullan (sonsuz animasyonlar var).

**Bu oturumdan çıkan iki pratik not:**
- Uzun içerikli `python - <<'PY'` heredoc'ları Bash aracında bazen
  "unexpected EOF" ile düşüyor. Büyük yamaları scratchpad'e bir `.py` dosyası
  olarak yazıp `python <dosya>` ile çalıştır.
- **Yeni test dosyası oluşturmadan önce aynı adda dosya olup olmadığını
  kontrol et.** Bu oturumda `character_catalog_test.dart` yanlışlıkla üzerine
  yazıldı ve 7 test kayboldu; toplam test sayısı beklenenden düşük çıkınca
  fark edildi. Her bölüm sonunda toplam test sayısını beklenen değerle
  karşılaştır.

## 2. SIRADAKİ İŞ — BÖLÜM 8: MACERA İKİ FAZLI OLSUN

> Kullanıcının orijinal şartnamesi, birebir. Bölüm 7'nin zemini hazır:
> güçlü oyuncu düşmanı adım hedefinden **önce** deviriyor ve bu
> `combat_balance_test.dart` içinde testle bağlı.

Şu an düşman ölünce macera bitiyor. Değişiyor: macera iki faza bölünecek.

### 8.1 Faz yapısı

- **SAVAŞ FAZI:** düşmanla mücadele, şu anki gibi.
- **YÜRÜYÜŞ FAZI:** düşman öldükten sonra başlar, macera orijinal adım
  hedefine ulaşana kadar sürer.
- Macera, ancak adım hedefi tamamlanınca gerçekten biter.

Düşmanı erken öldüren oyuncu ödülünü alır ve kalan yolu bonuslu yürür.

**Bugünkü kod durumu:** `AdventureQuest.isEnemyDefeated` düşman canına bakıyor;
`questSteps(currentSteps) >= stepGoal` de ayrı bir bilgi. İki fazın ayrımı
bu ikisinden çıkarılabilir — yeni bir `phase` alanı gerekiyorsa şemayı
artır (v14 → v15) ve migration yaz.

### 8.2 Hız ödülü

Düşman ne kadar hızlı öldürülürse savaş ödülü o kadar artar.

- "Hız" nasıl ölçülür — kullanılan round / beklenen round mu, harcanan adım /
  hedef adım mı? **Karar ver, gerekçelendir.**
  (İpucu: `expectedRoundsForTier` zaten `core/utils/enemy_stats.dart` içinde
  var ve düşmanın kilit eşiğinden geliyor.)
- Ödül çarpanı tanımla ve **TAVAN** koy (öneri: en fazla ×2).
- Oyuncuya net göster: "3 round'da bitirdin — ödül ×1.8".
- Çarpan hem XP hem coin ödülüne mi uygulanacak, sadece birine mi?
  **Karar ver, gerekçelendir.**

### 8.3 Yürüyüş fazında bonus kazanç

Yürüyüş fazı boyunca 50 adım = 1 coin yerine **30 adım = 1 coin**.
Macera tamamen bitince 50'ye geri döner.

- ⚠️ **EKONOMİ KONTROLÜ — bunu atlama:** günlük tavan (400 coin) **AYNEN
  GEÇERLİ**. Hesabını yap ve tabloyu CLAUDE.md'ye yaz: günde bir macera yapıp
  erken bitiren oyuncu günde kaç coin kazanır? Mevcut 120 coin/gün dengesi ne
  kadar bozuluyor? Sapma büyükse yürüyüş fazının uzunluğunu veya oranı ayarla
  — ama 30 adım = 1 coin hedefini koru.
  (`test/economy_pacing_test.dart` mevcut dengeyi ölçüyor; bozulursa alarm
  verir. Yeni senaryo ayrıca ölçülmeli.)
- XP oranı da değişsin mi? **Öneri: HAYIR, sadece coin.** İki kaldıracı birden
  oynatmak dengeyi zorlaştırır. Karar senin, gerekçelendir.
- Oran config'de sabit dursun, koda gömme (`GameConstants` deseni).
- Arayüzde faz ve oran net görünsün: "Yürüyüş fazı · 30 adım = 1 altın".
- Faz bitince oranın normale döndüğü bildirilsin.

**Bağlanacak yer:** `core/utils/coin_calculator.dart:calculateStepCoins` —
`stepsPerCoin` şu an `GameConstants`'tan sabit okunuyor. Çağrı noktası
`RootShell._onStepsReported`.

### 8.4 Yürüyüş görseli

Yürüyüş fazında macera ekranında karakter yürüyor gibi gösterilsin.

- **Asset hazır, yeni sanat gerekmiyor:**
  `lib/All_Assets/Avatars/Classes/Characters(100x100 split)/<Sınıf>/<Sınıf>/`
  altında 22 sınıfın hepsinde `_Walk.gif`, `_Idle.gif`, `_Hurt.gif`,
  `_Death.gif`, `_Attack01..03.gif` var. `AvatarProfile.walkAssetForClass`
  zaten yürüyüş GIF'ini çözüyor ve `avatar.characterAsset` **zaten** o.
- Savaş fazı ile yürüyüş fazı görsel olarak net ayrışsın (öneri: savaşta
  `_Idle`, yürüyüşte `_Walk`; düşman sahneden çıkar).
- `lib/GIF Animations/Soldier/` (triaj C9) ölü kopya — **kullanma**.
- Performans: animasyon 60 FPS'i düşürmesin, ölç ve raporla.
- Golden test ile iki fazı da gözle doğrula.

### 8.5 ⚠️ ZİNCİRLEME SONUÇ — STREAK VE ÇARK

**ÖNEMLİ — Bölüm 5a ve 5b hiç yapılmadı.** Seri tetikleyicisi hâlâ **2000
adım** (`GameConstants.streakStepThreshold`), çark kilidi hâlâ **3000 adım**
(`GameConstants.dailyWheelUnlockSteps`). "Bir macera tamamlamak" şartına geçiş
bu bölümde yapılacak, çünkü iki fazlı macerada "tamamlamak"ın ne demek olduğu
ancak burada cevaplanıyor.

Yapılacaklar (Bölüm 5a + 5b, orijinal şartnameden):

- **(a) Streak tetikleyicisi:** 2000 adım **değil**, günde **bir macera
  tamamlamak**. `streakStepThreshold` kullanımdan çıkacak.
  ⚠️ `EquippedBuffs.streakStepThreshold` ve `ItemStat.streakRelief` buff türü
  ona bağlı — **o buff türü yeniden anlamlandırılmalı**, yoksa ölü bir bonus
  kalır ve GD36'nın "boşta tür kalmasın" invariantı kırılır.
  "Tamamlamak" kazanmak mı bitirmek mi? Öneri: **kazan-kaybet fark etmez,
  bitirmek yeter** — kaybetmenin zaten cezası var.
  Arayüzdeki tüm "2000 adım" metinleri güncellenmeli:
  `home_screen.dart` (`_StreakCard`), `inventory_screen.dart` (karakter
  paneli), `root_shell.dart` (`_onStepsReported` tetikleyici dalı).
- **(b) Çark kilidi:** `dailyWheelUnlockSteps` (3000 adım) yerine 1 macera
  tamamlama. Tekrarlama mantığına (günlük hak, `wheelSpunToday`,
  `extraWheelSpins`) **dokunma** — sadece koşulu değiştir. Kilitliyken sessiz
  kalmasın: "Çarkı açmak için bir macera tamamla".
- **(c) İki fazlı macerada hangi an sayılır?**
  Öneri: **DÜŞMANI ÖLDÜRMEK** yeter — streak ve çark orada açılsın. Yürüyüş
  fazı bonus, zorunluluk değil. Gerekçe: streak ulaşılabilir kalmalı;
  oyuncuyu hedefin tamamını yürümeye mecbur bırakmak seriyi kırılgan yapar.
  Karar senin ama **açıkça ver**, CLAUDE.md'ye yaz ve arayüzde de net olsun —
  oyuncu streak'ini ne zaman güvenceye aldığını bilmeli.

**Dikkat:** `test/streak_test.dart` (20), `test/streak_freeze_test.dart` (21)
ve `test/streak_stat_bonus_test.dart` (25) adım eşiğine dayanıyor.
**Silme, birlikte güncelle.**

### 8.6 Test

Faz geçişi, hız ödülü çarpanı ve tavanı, yürüyüş fazında 30/1 oranı, faz
bitince 50/1'e dönüş, günlük tavanın hâlâ geçerli olması, çift sayma olmaması,
streak/çark tetikleyicisi, gün değişiminde faz durumu, kalıcılık.

## 3. BÖLÜM 9+ — kalan açık işler

Firebase gerektirenler **hariç** (⛔ arkadaşımın işi).

- **Aşama 4b — #14 canavara göre ödül.** `RootShell._rewards` hiç
  doldurulmuyor → Ödüllerim ekranı hep boş (triaj C5). `Reward.icon` bir
  `IconData`; Model Kuralları #1 gereği `String` anahtara çevrilmeli.
  Düşman yenilme hook'u hazır (`_onStepsReported`). İzlenecek örnek:
  `WheelReward` (framework tipi tutmuyor). Ayrıca `boss_battle_screen.dart`
  ölü zinciri (triaj A7) burada ya yeniden bağlanacak ya kaldırılacak —
  **silme kararı için onay gerekir** (Kural 2/6).
- **Aşama 5 — #3 slide scroll adım seçimi** (`_NumberWheel` hazır;
  `_showGoalPicker` zaten `ListWheelScrollView` kullanıyor, bu iş kısmen
  yapılmış olabilir — önce oku), **#6 VS ekranı** (arka planlar
  `lib/Backgrounds/` altında var), **#18 avatar asset** (hâlâ belirsiz: kod
  işi mi sanat işi mi).
- **Round süresi hâlâ test dengesi:** `AdventureQuest.roundDuration` = 30
  saniye, kodda "Geçici test dengesi" yorumuyla işaretli. Yayına çıkmadan
  önce gerçek değere alınmalı.
- **Itemler `speed` / `luck` vermiyor** (GD52). Ayrı bir denge geçişinin işi;
  tek yer `lib/data/item_archetypes.dart`.
- **Küçük borçlar:** C3 (`tz.setLocalLocation(tz.UTC)` sabit), C4 (hatırlatma
  metinleri iki yerde), C6 (`sideBySideWindowMinutes` ölü sabit), C7, C9, C10,
  C11, C13; iOS derleme borçları (`ios/Podfile` yok, `AppDelegate.swift`
  Windows'ta derlenmedi); GD1 (kayıt okunamazken salt-okunur oturum yok).
- **Aşama 6 — Firebase → takım savaşları. ⛔ ARKADAŞIMIN İŞİ, DOKUNMA.**

## 4. Savaş motorunu bekleyen birikim — artık bekleyen yok

Bölüm 3/4/5C'nin ürettiği savaş statlarının hepsi Bölüm 7'de canlandı:

| Kaynak | Ne üretiyor | Durum |
|---|---|---|
| Arketip (Bölüm 3) | Her itemde 1–3 savaş statı | ✅ uygulanıyor |
| Eşya seviyesi (4.2) | Seviye başına +%10 savaş statı | ✅ uygulanıyor |
| Birleştirme (4.3) | Nadirlik yükselince daha büyük stat | ✅ uygulanıyor |
| Seri bonusu (5C) | Gün başına +%1 savaş statı | ✅ uygulanıyor |

Toplama noktası **tek**: `core/utils/effective_stats.dart`. Yeni bir kaynak
eklenirse oraya bağlanmalı, beşinci bir hesap yazılmamalı.

## 5. Değişmeyen kurallar (hatırlatma)

- ⛔ **Firebase'e dokunma.**
- ⚠️ **`flutter run` çalışmıyor** (Smart App Control). Görsel iş = **golden**;
  PNG'yi üret, **oku ve gerçekten bak**, birden çok genişlik için üret.
- **Commit atma.** Bölüm bitince değişen dosyaları listele, özetle, tek satır
  conventional-commit mesajı öner; commit'i kullanıcı atıyor.
- **Arkadaşımın kodu — varsayılan: dokunma.** Yalnızca gerçek hataları düzelt.
- **Silme yok:** hiçbir dosyayı silme, mevcut testi devre dışı bırakma,
  çalışan özelliği bozma.
- Her adımdan sonra `flutter analyze` temiz + testler yeşil.
- Kararları "GERİ DÖNÜLECEK KARARLAR" başlığına gerekçesiyle yaz.

---
---
---

# Bölüm A — Macera iki fazlı oldu ✅ (2026-08-26)

Kararlar **GD55–GD61**. Şema **v16 → v17**.

## Ne değişti

| | Önce | Sonra |
|---|---|---|
| Zafer | Düşman ölünce macera biterdi | Düşman ölünce **yürüyüş fazı** başlar; macera adım taahhüdü dolunca biter |
| Zafer ödülü | Sabit XP + tohumsuz rastgele altın | **Hız çarpanıyla** ölçekli XP + altın; altın artık **tohumlu** |
| Yürüyüş kazancı | 50 adım = 1 altın | Yürüyüş fazında **30 adım = 1 altın**, faz bitince 50'ye döner |
| Seri / çark | Yalnızca adım eşiği | **Zafer ya da** adım eşiği — hangisi önce gelirse |
| Zafer sahnesi | Altınlar düşmanın **arkasında** | Altınlar düşmanın **önünde** |
| Yürüyüş görseli | Yok | Kendi sahnesi: düşman yok, karakter yürüyor, "YÜRÜYÜŞ FAZI" şeridi |

## Model

`AdventureQuest` üç kalıcı alan aldı; hepsi `revivalSteps` desenini izliyor:

| Alan | Rol |
|---|---|
| `victorySteps` | Zafer anında harcanmış macera adımı. `-1` = damga yok. **İki şeyin tek kaynağı:** yürüyüş hedefi ve hız çarpanı |
| `victoryRounds` | Düşmanı deviren round. Yalnızca gösterim |
| `walkSteps` | Yürüyüş fazında biriken adım |

Türetilenler: `walkTargetSteps`, `walkRemainingSteps`, `walkProgress`,
`isWalkPhaseActive`, `isAdventureCompleted`, `speedRewardMultiplier`,
`phase` (`AdventureQuestPhase`).

⚠️ **`isEnemyDefeated` artık "macera bitti" demek değil.** Ödül kapıları ve
ekranlar bu ayrımı gözetmeli; yeni kod `isAdventureCompleted` kullanmalı.

## Denge

| Sabit | Değer | Nereden |
|---|---|---|
| `walkPhaseStepsPerCoin` | 30 | Şartname; ekonomi ölçümü GD58'de |
| `maxVictorySpeedMultiplier` | 2.0 | Tavansız çarpan güçlü oyuncuda sınırsız büyürdü |

Referans oyuncunun (6.000 adım/gün, 2.000'lik hedef) günlük coin sapması
**+%13**. Tam tablo ve gerekçe: GD58.

## Test

- `test/walk_phase_test.dart` — **30 test**: faz geçişleri (savaş → yürüyüş →
  tamamlandı), yenilgi dalının etkilenmemesi, hedefin aşılamaması, damganın
  ikinci kez yazılmaması; hız çarpanının tavanı ve doğrusallığı (şartnamedeki
  ×1.8 örneği testli), tohumlu altının tekrarlanabilirliği; 30/1 oranı ve
  faz bitince 50/1'e dönüş, faz sınırını geçen partinin **çift saymaması** ve
  artık adımın devretmesi, aynı adımın ikinci kez paraya çevrilmemesi;
  seri/çark tetikleyicisinin iki kapısı; kayıt turu ve **eski kaydın yürüyüş
  fazına geriye dönük sokulmaması**; yürüyüş ekranının savaş ekranından
  ayrışması.
- `test/golden/walk_phase_golden_test.dart` — **3 test**: 320/390 dp golden
  (PNG'ler üretildi ve gözle doğrulandı: karakter tam görünür, düşman yok,
  taşma yok) + savaş göstergelerinin gerçekten kaybolduğu.
- `test/adventure_progress_test.dart` — **+1 iddia**: altınların ağaç
  sırasında cesetten **sonra** geldiği (A.5 regresyonu). Golden tek başına
  yetmezdi.
- `test/combat_persistence_test.dart` — güncellendi (silinmedi): zafer altını
  artık hız çarpanıyla kademe tavanını aşabiliyor.

Toplam **713 test geçiyor**, `flutter analyze` temiz.

### Yeniden üretilen golden'lar

Arkadaşımın commit'inde **8 golden kırmızıydı** ve bunlar kod regresyonu
değildi: `pubspec.yaml`'a eklenen yeni asset klasörleri (`Tutorial_Guy`,
`coins`) yüzünden test asset paketi bayattı. Paket yenilenince
`victory_scene_390` gerçek altın sprite'larını (eskiden sarı kare yer
tutucu), `blacksmith_*` / `store_card_*` / `forge_*` ise yalnızca yuvarlak
köşe anti-aliasing farkını gösterdi. Hepsi incelenip yeniden üretildi.

## Açık kalan

- **Gün değişiminde macera hâlâ düşüyor** (Aşama 0'ın açık notu). Yürüyüş
  fazı harcanan adımı daha görünür kıldı; telafi kararı hâlâ verilmedi.
- **Günde kaç macera yürüyüş bonusu alabilir** sınırı yok (GD58).
- Faz **eğitimde anlatılmıyor** — Bölüm F'nin işi. Eğitim savaşı bilerek tam
  hedefte damgalanıyor: yeni oyuncu ×2 ödül almıyor ve eğitimin ortasında
  binlerce adımlık yürüyüşe kilitlenmiyor.

---
---
---

# Bölüm B — Seri bonusunun tavanı kalktı ✅ (2026-08-26)

Kararlar **GD62–GD66**. Şema **v17 → v18**.

## Ne değişti

| | Önce | Sonra |
|---|---|---|
| Gün başına kazanç | Sabit +%1 | Basamaklı: +%0,5 → +%0,1, sonra **başa döner** |
| Stat başına tavan | +%25 | **Yok** |
| Toplam tavan | +%100 | **Yok** |
| Tavana ulaşan stat | Havuzdan çıkardı | Havuzda kalır, **ağırlığı düşer** |
| Birikim biçimi | Gün sayısı (`int`) | Binde (`int`) — 5 = +%0,5 |
| Panel | "tavan" etiketi | "Şu an: gün başına +%0,4" |

## Basamak tablosu

```
   1–100. gün : +%0,5
 101–200. gün : +%0,4
 201–300. gün : +%0,3
 301–400. gün : +%0,2
 401–500. gün : +%0,1
 501+     gün : +%0,5 — döngü baştan başlar
```

İki config sabitinden: `GameConstants.streakBonusTierLength` (100) ve
`streakBonusTierTenths` ([5, 4, 3, 2, 1]). Koda gömülü sayı yok; test tablo
değişirse hesabın da değiştiğini bağlıyor.

Bir tam tur (500 gün) toplam **+%150** savaş bonusu biriktiriyor
(100×0,5 + 100×0,4 + 100×0,3 + 100×0,2 + 100×0,1). Eski sistemin toplam
tavanı +%100'dü ve 100 günde doluyordu.

## Tavan yerine ağırlıklı çekiliş

Tek bir statın uçmasını engelleyen mekanizma artık tavan değil, çekilişin
geride kalanı kayırması: `ağırlık = 1 + min(8, enYüksek − kendisi)`.

- Lider **her zaman** çekilişte kalır (ağırlık 1) — rastgelelik gerçek.
- Geride kalan en fazla 9 kat şanslı olur.
- **Hiçbir gün boşa gitmez**: kaldırılan tavanın asıl derdi buydu.
- Ölçülen: 90 günlük seride dokuz savaş statının hepsi bonus alıyor ve lider,
  en geriden gelenin iki katını geçmiyor.

Gerekçe: **GD64**.

## Determinizm korundu

Çekiliş hâlâ tohumlu ve gün işaretli:
- Ağırlıklar kalıcı birikimden türüyor → `f(tohum, birikim)` deterministik.
- Tek bir `Random(seed).nextInt(toplamAğırlık)` çağrısı, kümülatif ağırlıkta
  yürüyüş.
- `lastStreakBonusDay` aynı oyun gününde ikinci çekilişi engelliyor →
  **kapat-aç zar attırmıyor**.
- Tohum akışı çarkınkinden ayrı (`nextStreakSeed`) → çark çevirerek sıra
  kaydırılamıyor.

## Ekonomi güvende

Havuz **hâlâ** yalnızca savaş statları (`ItemStat.isCombat`). Sekiz ekonomi
statının hepsi ayrı ayrı sıfır kontrol ediliyor. Tavansız büyüyen bir para
çarpanı ekonomiyi çökertirdi; savaş statlarında aynı risk yok çünkü onları
düşman statları dengeliyor ve motorun kendi tavanları var (kritik %60,
sıyrılma %40). Gerekçe: **GD65**.

## Şema v18 — veri kaybı yok

v17 kaydındaki her gün değeri **10 ile çarpılıyor** (1 gün = +%1 = 10 binde).
Uzun serili bir oyuncunun bonusu güncelleme sonrası onda birine düşmüyor;
`game_storage_test.dart` içinde uçtan uca testli.

## Test

- `test/streak_stat_bonus_test.dart` — **+14 test** (grup değişti, silinmedi):
  basamak tablosunun tamamı, şartnamedeki sınır günleri (1/100/101/200/201/
  300/301/400/401/500/**501**/600/601/1000/**1001**), yalnızca döngü
  başlangıcının kutlanması, tablonun tek config kaynağından okunması,
  geçersiz gün savunması, çekilişin gün kazancını taşıması; tavan yokluğu
  (tek statın sınırsız birikmesi, 160 günlük serinin tam toplamı = 740 binde,
  çekilişin hiçbir birikimde durmaması), ağırlık kuralları.
- `test/streak_bonus_shell_test.dart` — **+3 test**: 501. günün kutlanması,
  151. günün kutlanmaması ve doğru basamağı (+%0,4) göstermesi, panelde
  güncel oranın görünmesi.
- `test/game_storage_test.dart` — **+2 test**: v17 → v18 taşıması birikimi
  birebir koruyor; bonusu olmayan kayıt bozulmuyor.
- Güncellenen (silinmedi): `combat_balance_test.dart`,
  `golden/streak_bonus_golden_test.dart` (golden yeniden üretildi ve gözle
  doğrulandı), `streak_bonus_shell_test.dart`, `streak_stat_bonus_test.dart`.

Toplam **727 test geçiyor**, `flutter analyze` temiz.

## Açık kalan

- 500 günlük tur **+%150** biriktiriyor; ikinci tur +%300'e çıkarıyor. Savaş
  motoru bunu bugün taşıyor (statların kendi tavanları var) ama çok uzun
  serilerde düşman dengesi ölçülmedi. `combat_balance_test.dart` ölçüt
  oyuncuyu bonussuz ölçüyor.
- Döngü kutlaması yalnızca bildirimde; ayrı bir kutlama ekranı yok.
