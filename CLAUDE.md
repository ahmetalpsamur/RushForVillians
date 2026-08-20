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

### GD14. "Alabileceklerim" süzgeci sahip olunanları eliyor (2026-08-20)
- **Nerede:** `xp_store_screen.dart:_visibleEquipment`
- Süzgeç yalnızca seviye + paraya bakıyordu; zaten sahip olunan item de
  "alabileceklerim" listesinde çıkıyordu. Süzgecin sözü "bugün satın
  alabileceklerim" — alınamayacak bir şey orada olmamalı.

---
---

# OTURUM KAPANIŞI — 2026-08-19

> **Sonraki oturum buradan başlasın.** Bu bölüm, hiçbir şey sormadan devam
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

> **Sonraki oturum buradan başlasın.** Hiçbir şey sormadan devam edebilmek
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
