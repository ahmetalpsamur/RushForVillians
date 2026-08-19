# CLAUDE.md

Bu dosyadaki kurallar tüm oturumlarda geçerlidir.

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

# Arkadaşımla Konuşulacak — mimari farklılıklar (2026-08-19)

Bu maddeler **hata değil**; takım arkadaşımın (`e902185` + `f28f510` merge +
`feec7db`) bilinçli tercihleri. Çalışıyorlar, bu yüzden dokunulmadı. Ama
CLAUDE.md'de yazılı bir kararı değiştirdikleri ya da ileride bizi kesecekleri
için konuşulmaları gerekiyor.

### K1. Gün sınırı 04:00 → 00:00'a çekildi
- **Dosya:** `lib/core/utils/game_day.dart` (`dayStartHour = 0`)
- **Neden yapılmış:** adım halkası takvim günüyle kapansın ve arşivlensin
  (`DailyStepRecord.dateKey` takvim günü).
- **Ne kaybettik:** Aşama 1a'da 04:00 tam da "gece yarısını geçmiş ama hâlâ
  ayakta olan kullanıcının serisi haksız yere kırılmasın" diye seçilmişti.
  Ayrıca 04:00, çarkın gece yarısı açığını kapatıyordu: şimdi 23:59'da çevirip
  00:01'de tekrar çevirmek mümkün. (Açık 04:00'da da vardı ama kimsenin ayakta
  olmadığı bir saatteydi.)
- **Öneri:** ikisi ayrılabilir — adım geçmişi arşivi takvim gününü kullanmaya
  devam etsin, seri ve çark 04:00 sınırında kalsın. Bu, `GameDay`'e ikinci bir
  sınır kavramı eklemek demek; **karar arkadaşımla birlikte verilmeli.**

### K2. Round süresi adımdan bağımsız sabit 20 dakikaya çevrildi
- **Dosya:** `lib/models/adventure_quest.dart`
  (`roundDuration`, `briskWalkingStepsPerMinute`/`syncGraceMinutes` kaldırıldı)
- Eski model "adım/100 dk + 1 dk senkron payı" idi; yenisi her round için sabit
  20 dk. Testler birlikte güncellenmiş, silinmemiş. Denge kararı, kod hatası
  değil.

### K3. Round erken tamamlanınca anında kazanılıyor
- **Dosya:** `adventure_quest.dart:resolveRound`
- `resolveExpiredRound` artık `resolveRound`'a yönlendiren bir kabuk.
  `isDefeated` erken çıkışı kaldırıldı; yerine `roundTargetSteps <= 0`
  koruması var (düşman ölünce hedef 0'a düşüyor, döngü orada duruyor).
  İncelendi, sonsuz döngü yok.

### K4. Kalıcı round durumu `AdventureQuest` üzerinde büyüdü
- `currentRound`, `lastResolvedRound`, `roundOutcomeSerial`,
  `presentedRoundOutcomeSerial`, `lastRoundWon` diske yazılıyor.
  `presentedRoundOutcomeSerial` bir **sunum** durumu (animasyon oynatıldı mı);
  model katmanında duruyor. Model Kuralları #1'i ihlal etmiyor (int), ama
  sunum/model sınırını bulanıklaştırıyor.

### K5. Ekran, model nesnesini doğrudan değiştiriyor
- **Dosya:** `adventure_screen.dart:_markRoundOutcomePresented`,
  `_playRoundVictory` (`adventure.deathAnimationPlayed = true`)
- `AdventureScreen`, `RootShell`'in state nesnesini mutasyona uğratıp
  `onAdventureUpdated()` ile kaydettiriyor. Mevcut `setState` mimarisinde
  çalışıyor; Riverpod/Bloc'a geçişte ilk kırılacak yer burası olur.

### K6. Yeni düşmanlar kataloğun **başına** eklendi
- **Dosya:** `lib/data/enemy_catalog.dart` — `border_scout` (500),
  `forest_raider` (1000), `blood_apprentice` (1500).
- Testler `EnemyCatalog.enemies[0]` yerine `byId(...)` kullanacak şekilde
  güncellenmiş; sıraya bağlı kod kalmamış. İyi.

### K7. Açılış sesi için özel platform kanalı
- **Dosyalar:** `lib/services/launch_sound.dart`, `MainActivity.kt`,
  `AppDelegate.swift` (`rush_for_villains/launch_sound`)
- `audioplayers` gibi bir paket yerine elle kanal yazılmış. Kotlin tarafı
  düzgün (release, onCompletion/onError, onDestroy). **Küçük sızıntı:**
  `prepare()` fırlatırsa `MediaPlayer` release edilmiyor — süreç başına bir
  kez, zararsız. iOS tarafı Windows'ta derlenemedi.

### K8. `_stepHistory` sınırsız büyüyor
- **Dosya:** `root_shell.dart:_archiveDailySteps`
- Her gün bir kayıt; 5 yılda ~1.800 satır (~180 KB SharedPreferences).
  Bugün sorun değil, ama bir üst sınır (ör. son 730 gün) ya da aylık özet
  konuşulmalı.

---

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

