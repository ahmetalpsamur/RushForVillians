# CLAUDE.md — Rush For Villains

> **Bu dosya bir görev listesi değil, bir referans kitabıdır.** Projede
> "sıradaki iş" yok; sistemler kurulu ve çalışıyor. Buradaki amaç, projeyi hiç
> görmemiş bir oturumun **oyunun ne olduğunu, nasıl kurulduğunu ve hangi
> kararların neden verildiğini** tek dosyadan anlaması.
>
> **Okuma sırası:**
> 1. **§1 Çalışma Kuralları** ve **§2 Model Kuralları** — zorunlu, kısa.
> 2. **§5.2 Test ortamı** — bu bayrak olmadan hiçbir test çalışmaz.
> 3. Sonra ne üzerinde çalışacaksan onun **§6** alt bölümü.
> 4. Verilmiş bir kararı değiştirmeden önce **§11 (GD1–GD81)** içinde
>    gerekçesini ara. **Koddaki yorumlar bu numaralara atıf yapıyor**
>    (`bkz. GD15`, `GD40` gibi) — numaraları değiştirme.

---

# §1 — Çalışma Kuralları

1. **MEVCUT KODA SAYGI.** Bu projede yazılmış, çalışan kod var. Hiçbir dosyayı
   "daha iyisini yazayım" diye baştan yazma. Mevcut yapıyı, isimlendirmeyi,
   mimariyi ve kod stilini benimse ve üstüne ekle.
2. **SIFIRDAN YAZMA YASAĞI.** Bir dosyayı tamamen değiştirmen gerektiğini
   düşünüyorsan ÖNCE sor, nedenini açıkla, onay bekle.
3. **ÖNCE OKU.** Değişiklikten önce ilgili mevcut kodu oku. Aynı işi yapan bir
   fonksiyon zaten varsa onu kullan, ikincisini yazma.
4. **KÜÇÜK ADIMLAR.** Her adımdan sonra `flutter analyze` çalıştır; hata varsa
   devam etme.
5. **BOZMA.** Çalışan bir özelliği bozacaksan önce söyle. **Var olan testi
   silme veya devre dışı bırakma** — davranış bilerek değiştiyse testi
   *güncelle*.
6. **EMİN DEĞİLSEN SOR.**
7. **ARKADAŞIMIN KODU — varsayılan: dokunma.** Bu proje iki kişiyle
   geliştiriliyor. Başkasının yazdığı bir yerde yalnızca **gerçek hataları**
   düzelt; mimari uyum için refactor etme, isim/stil değiştirme.
8. **SİLME YOK.** Dosya silme, klasör temizleme, ölü kod kaldırma — hepsi
   onaya tabi.
9. **COMMIT ATMA.** `git commit` çağırma, `/commit` çalıştırma. İş bitince:
   değişen dosyaları listele, ne yaptığını özetle, tek satırlık
   conventional-commit mesajı öner. Commit'i kullanıcı atıyor.
10. **⛔ FIREBASE'E DOKUNMA.** `firebase_options.dart`, Firestore, Auth, Cloud
    Functions, `google-services.json`, `GoogleService-Info.plist` — hiçbirine.
    pubspec'e firebase paketi ekleme. Backend arkadaşımın alanı (§13).

---

# §2 — Model Kuralları

1. **KALICI MODELDE FRAMEWORK TİPİ YOK.** Diske ya da ileride Firebase'e
   yazılacak hiçbir modelde `IconData`, `Color`, `Widget`, `TextStyle`
   tutulmaz. Yerine `String` / `int` anahtar tutulur, görsel karşılığı
   katalogdan çözülür.
   **Sebep:** release build'de `--tree-shake-icons`, sabit olmayan `IconData`
   üretimini bozar; serileştirilmiş ikon kodu geri yüklendiğinde ikon kaybolur.
   İyi örnek: `models/enemy.dart` ve `models/owned_item.dart`.
2. **Serileştirme elle yazılır.** Proje `build_runner` kullanmıyor;
   `freezed` / `json_serializable` **getirme**. Desen: `AvatarProfile`,
   `UserProfile`, `GameState`, `OwnedItem`.
3. **Gün hesabı tek yerden:** `lib/core/utils/game_day.dart`. Hiçbir yerde
   ikinci bir `a.day == b.day` karşılaştırması yazma.
4. **Şimdiki zaman tek yerden:** `lib/core/utils/game_clock.dart`. Gün, seri,
   çark ve savaş hesaplarında `DateTime.now()` **yazma**; `GameClock.now()`
   kullan.
5. **Devre dışı kontrol sessiz kalmaz.** Kilitli bir buton/kart neden kilitli
   olduğunu söylemeli: kilit ikonu + dokununca **tam sebep**. "Yükseltilemiyor"
   tek başına cevap değil; *hangi* tavanın bağladığı yazılmalı.
6. **Şema alanı eklersen sürümü artır ve migration yaz** (§7).

---

# §3 — Oyun nedir

**Rush For Villains**, adım sayar tabanlı bir Flutter RPG'si. Oyuncunun
**gerçek adımları** oyunun tek yakıtıdır: para, XP, savaş hasarı, günlük seri
ve çark hakkı — hepsi yürümekten gelir. Telefonu cebinde tutup yürüyen biri
oyunu ilerletir; oturan biri ilerletmez.

## Ana döngü

```
gerçek adım
   ├─► coin           (50 adım = 1 · yürüyüş fazında 30 adım = 1)
   ├─► XP → seviye    (2 adım = 1 XP)
   ├─► günlük seri    (2000 adım ya da bir zafer)
   ├─► çark hakkı     (3000 adım ya da bir zafer)
   └─► macera roundu  (round hedefi tutarsa vurursun, tutmazsa yersin)
                             │
                             ▼
                     düşman devrilir
                             │
              ┌──────────────┴───────────────┐
              ▼                              ▼
      zafer ödülü (XP + altın)        YÜRÜYÜŞ FAZI
      × hız çarpanı (≤ ×2)            30 adım = 1 altın
                                      taahhüt bitene kadar
```

Kazanılan coin **mağazadan ekipman ve ünvan** alır; ekipman **kuşanılır**,
buff'ları hem ekonomiyi hem savaş statlarını büyütür; aynı eşyanın birkaç
adedi **demircide birleştirilip** bir üst nadirliğe çıkar ve coin harcanarak
**seviye atlatılır**. Günlük seri her gün rastgele bir savaş statını kalıcı
olarak büyütür. Toplanan 1.244 parçalık **ödül koleksiyonu** ve 65 parçalık
**ünvan sistemi** uzun vadeli hedefleri taşır.

## Ne var, ne yok

| Var | Yok (bilerek) |
|---|---|
| Gerçek pedometer (Android + iOS kanalı) | Backend / çevrimiçi (§13) |
| Deterministik savaş motoru | Takım savaşı (ekran bir önizleme) |
| Yerel kalıcılık, şema v20 + migration | Firebase |
| 784 ekipman · 65 ünvan · 1.244 koleksiyon ödülü · 20 düşman · 18 sınıf | Reklam / IAP |
| 29 adımlık eğitim + dolaşan rehber | İngilizce çeviri tamamlanmadı (altyapı hazır) |

---

# §4 — Mimari

## 4.1 Klasör haritası

```
lib/
├── main.dart                  # servis init → RushForVilliansApp
├── app.dart                   # MaterialApp + açılış yönlendirmesi
├── core/
│   ├── constants/
│   │   ├── game_constants.dart    # BÜTÜN denge sabitleri — tek dosya
│   │   └── attack_config.dart     # 6 saldırı hedefi × 5 round tablosu
│   ├── theme/app_theme.dart       # AppColors + AppTheme.dark
│   └── utils/                     # SAF FONKSİYONLAR (aşağıda)
├── data/                      # SABİT VERİ (kod değil, tablo)
├── models/                    # düz Dart sınıfları, elle toJson/fromJson
├── services/                  # platform, kalıcılık, katalog
├── features/<özellik>/…       # ekranlar
├── widgets/                   # paylaşılan UI parçaları
└── <Asset klasörleri>         # All_Assets, Items, Rewards, Backgrounds, …
```

### `core/utils/` — saf fonksiyon katmanı

Bu projenin en önemli mimari kararı: **kural, ekrandan ve state'ten ayrı, saf
ve test edilebilir bir fonksiyonda yaşar.** Yeni bir kural yazarken buraya bak,
aynı deseni izle.

| Dosya | Ne hesaplar |
|---|---|
| `game_day.dart` | Oyun günü (sınır **04:00**), gün farkı, sıfırlamaya kalan süre |
| `game_clock.dart` | Enjekte edilebilir "şimdi"; geriye alınan cihaz saatini emer |
| `coin_calculator.dart` | Adım → coin (oran parametreli, yürüyüş fazı için) |
| `xp_calculator.dart` | Adım → XP |
| `step_rate_limiter.dart` | "İnsan bu adımı bu sürede atabilir mi" |
| `step_history.dart` | Günlük halka arşivi + 400 gün kırpması |
| `item_rules.dart` | Dosya yolundan item türetme: ad, nadirlik, seviye, fiyat, buff |
| `item_leveling.dart` | Eşya seviyesi: iki tavan, maliyet eğrisi, stat ölçekleme |
| `item_merging.dart` | Birleştirme: adet, ücret, hangi örneklerin yanacağı |
| `item_comparison.dart` | "Bunu kuşanırsan ne değişir" farkı |
| `equipped_buffs.dart` | Kuşanma + ünvan etkilerinin **tek toplama noktası** + tavan kırpması |
| `effective_stats.dart` | Taban + ekipman + seri + koşullu → nihai savaş statı |
| `base_combat_stats.dart` | Seviyeden gelen taban statlar |
| `enemy_stats.dart` | Kademe + arketipten düşman statı türetme |
| `combat_engine.dart` | **Saf, deterministik savaş motoru** |
| `streak_bonus.dart` | Günlük seri stat çekilişi (ağırlıklı, tohumlu) |
| `wheel_rewards.dart` | Çark havuzu ve kazanan dilim (tohumlu) |
| `title_rules.dart` | Ünvan koşulu ilerlemesi |
| `reward_calculator.dart`, `gif_timing.dart` | Yardımcılar |

### `data/` — tablo, kod değil

Hiçbirinde `switch (id)` yok; hepsi veri yapısı.

| Dosya | İçerik |
|---|---|
| `item_definitions.dart` | 166 temel item'ın Türkçe adı + nadirliği |
| `item_archetypes.dart` | Arketip çarkları, savaş stat sıraları, bütçeler |
| `item_effects.dart` | Elle tasarlanmış (imzalı) itemlerin lore'u ve özel etkileri |
| `enemy_catalog.dart` | 20 düşman: kademe, arketip, asset yolları |
| `title_catalog.dart` | 65 ünvan |
| `reward_catalog.dart` + `reward_assets.g.dart` | 1.244 koleksiyon ödülü |
| `wheel_odds.dart` | Çarkın **bütün** oranları |
| `pet_sayings.dart` | Rehberin bağlama duyarlı sözleri |
| `mock_data.dart` | 4 mağaza yükseltmesi + demo takım |

## 4.2 State yönetimi — `RootShell`

**State management paketi yok.** Tüm oyun state'i tek bir `StatefulWidget`
içinde: `lib/features/root/root_shell.dart` (~2.300 satır), `setState` ile
yönetiliyor. Alt ekranlar `StatelessWidget` ve state'i `final` alan +
callback (`ValueChanged`, `VoidCallback`) ile alıyor.

Bu bilinçli bir tercih değil, **büyümüş bir prototip**. Dosyanın kendi
yorumunda "ileride Riverpod/Bloc'a taşınabilir" notu var. Bugün çalışıyor;
dokunma.

**Bilmen gereken iki tuzak:**

- **`_push` ile itilen ekran `RootShell`'in alt ağacında değildir** →
  `setState` onu tazelemez (GD11). Mağaza bu yüzden **sekmeye** taşındı.
- **İtilen ama canlı olması gereken ekranlar** `_revision`
  (`ValueNotifier<int>`) + `readState()` desenini kullanır (GD27): ekran veri
  tutmaz, her çizimde `RootShell`'den okur. Envanter, demirci ve ünvan
  ekranları böyle. Yeni bir canlı ekran eklersen ya sekmeye al ya bu deseni
  kullan.

### Sekmeler

`NavigationBar`, 5 sekme: **Ana Sayfa · Macera · Mağaza · Taverna · Profil**.
İtilen (sekme olmayan) ekranlar: envanter, demirci, ünvanlar, çark,
koleksiyon, adım geçmişi, karakter düzenleme.

## 4.3 Açılış akışı

```
main.dart
  └─ bildirim servisi init (hata yutulur, açılış durmaz)
     └─ RushForVilliansApp (app.dart)
        ├─ CharacterStorage.load()  ┐ ikisi de try/catch içinde;
        └─ GameStorage.load()       ┘ hata olursa temiz varsayılan + SnackBar (GD1)
           │
           ├─ yükleniyor          → StartScreen (markalı açılış + ses)
           ├─ rehber seçilmemiş   → GuideSelectionScreen
           ├─ avatar yok          → CharacterCreationScreen (7 adımlı sihirbaz)
           └─ hepsi var           → RootShell (ilk açılışta eğitim başlar)
```

**Açılış hiçbir koşulda kilitlenmez.** Platform kanalı düşse bile oyun temiz
varsayılanla açılır ve kullanıcı bir kez uyarılır.

## 4.4 Kod stili

- **Kod dili İngilizce, kullanıcıya görünen metin ve yorumlar Türkçe.**
  Sınıf/değişken/dosya adları İngilizce (`AdventureQuest`, `remainingHealth`),
  dartdoc ve UI stringleri Türkçe. **Bu ayrımı bozma.**
- Dosya adları `snake_case`, ekranlar `<özellik>_screen.dart`.
- **İstisna:** asset klasörleri PascalCase, boşluklu ve bazen Türkçe
  (`All_Assets/Enemies/Characters(100x100 split)/Black Knight_A/`) — dokunma.
- Alanlar `final <Tip> <ad>;`, `const` constructor tercih edilir, parametreler
  `required` named.
- Statik yardımcılar private constructor ile kapatılır:
  `class GameConstants { GameConstants._(); … }` ya da `abstract final class`.
- Ekran içi yardımcı widget'lar aynı dosyada `_` prefix'li private sınıf.
- Dart 3 kullanılıyor: switch expression, extension, record, pattern.
- Renkler `AppColors` üzerinden. Tekrar eden UI için `SectionCard`, `StatBar`,
  `RarityBadge`, `ArchetypeBadge`, `TitleBadge` hazır — yenisini yazmadan önce
  bunlara bak.
- **Yazım notu:** repo adı ve `RushForVilliansApp` sınıfı "Villians" (hatalı),
  paket adı `rush_for_villains` (doğru). Bilerek bırakıldı.

---

# §5 — Ortam

## 5.1 Build zinciri

**Flutter 3.47.0 gerekiyor.** Eski sürüm kullanan takım üyesi `flutter upgrade`
yapmalı.

| Dosya | Ne | Sürüm |
|---|---|---|
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle | 8.14.3 |
| `android/settings.gradle.kts` | AGP | 8.11.1 |
| `android/settings.gradle.kts` | Kotlin | 2.2.20 |

- **JDK 25 kullananlar:** Gradle 8.14.3 Java 25'i desteklemiyor →
  `flutter config --jdk-dir=<jdk-21-yolu>`.
- **AGP 9 / Gradle 9 geçişi ertelendi:** Flutter Gradle eklentisi AGP 9'un yeni
  DSL'iyle uyumsuz.
- Android: `multiDexEnabled`, `coreLibraryDesugaring 2.1.4`,
  `applicationId com.heapchiStudios.rush_for_villains`.
- Platform klasörleri yalnızca `android/` ve `ios/`.

## 5.2 ⚠️ TEST ORTAMI — testler `--no-test-assets` ile çalışır

```powershell
flutter test --no-test-assets
```

**Bu bayrak olmadan hiçbir test çalışmaz — araç çöker.**

**Sebep:** bu makinede Smart App Control `impellerc.exe`'yi engelliyor. Flutter,
test asset paketini kurarken Material'ın `ink_sparkle.frag` shader'ını derlemek
zorunda; derleyici çalışmayınca araç çöküyor ve testler başlamıyor bile.
Flutter'ın bu durum için bir tutamacı var (`_SecurityPolicyBlockException`) ama
yalnızca Windows hata kodu **1260** için; bu makinede gelen kod **4551**.
Flutter tarafında bir eksik, bizim kodumuzda değil.

**Bir kereye mahsus kurulum** (`build/unit_test_assets/shaders/` boşsa):

```powershell
copy build\app\intermediates\flutter\debug\flutter_assets\shaders\ink_sparkle.frag `
     build\unit_test_assets\shaders\ink_sparkle.frag
```

`--no-test-assets` "asset yok" demek değil, "asset paketini **yeniden kurma**"
demek. `build/unit_test_assets/` zaten dolu.

⚠️ **`pubspec.yaml`'a yeni asset eklenirse paket bayatlar.** O zaman bir kez
normal `flutter test` çalıştırılır (çökecek ama paketi yazacak), shader tekrar
kopyalanır, sonra `--no-test-assets` ile devam edilir. *Bayat paket golden
testlerini sahte sebeplerle kırar — bir golden beklenmedik yerde kırmızıysa
önce bunu kontrol et.*

`flutter analyze` ve `flutter pub get` etkilenmiyor.

**Bash üzerinden `flutter test` bir hook tarafından engelleniyor** (Very Good
CLI istiyor). Testleri **PowerShell** aracıyla çalıştır.

## 5.3 ⚠️ `flutter run` çalışmıyor → görsel doğrulama golden ile

Aynı Smart App Control kısıtı yüzünden uygulama bu makinede çalıştırılamıyor.
**Cihazda gözle doğrulama yok.** Görsel bir iş yaptıysan:

1. Golden üret: `flutter test --no-test-assets --update-goldens <yol>`
2. **PNG'yi oku ve gerçekten bak.**
3. Birden çok genişlik için üret (320 / 360 / 390 / 412 / 800 dp).

**Golden kuralları:**
- `pumpAndSettle` **kullanılamaz** — sonsuz tekrar eden animasyonlar var.
  Sabit kare dizisi kullan: `pump(Duration)` × N. Bu aynı zamanda golden'ları
  tekrarlanabilir kılar.
- Test ortamında gerçek font yok; **bütün yazılar dolu kutu** çiziliyor. Bu
  hizalama ve taşma denetimi için avantaj (metin sınırları birebir görünür) ama
  "yazı doğru mu" sorusunu golden cevaplayamaz — `find.text` ile ayrıca
  doğrula.
- Golden dosyaları `test/golden/goldens/` altında ve **repoya giriyor**.
  `**/failures/` gitignore'da.

## 5.4 Paketler ve izinler

| Paket | Sürüm | Ne için |
|---|---|---|
| `pedometer` | ^4.2.0 | Android adım sensörü |
| `permission_handler` | ^13.0.1 | Runtime izinler |
| `shared_preferences` | ^2.5.3 | Tüm kalıcılık |
| `flutter_local_notifications` | ^19.5.0 | Macera hatırlatmaları |
| `timezone` | ^0.10.1 | Bildirim zamanlaması |
| `flutter_localizations` | Flutter SDK | Material/Cupertino yerelleştirme delegeleri |
| `intl` | SDK'nın sabitlediği sürüm | Sayı, tarih ve saat biçimlendirme |
| `flutter_lints` | ^5.0.0 (dev) | Analiz |

State management, HTTP, serialization, mocking paketi **yok** ve
getirilmeyecek.

| Platform | İzin |
|---|---|
| Android | `ACTIVITY_RECOGNITION` (manifest + runtime) |
| Android | `POST_NOTIFICATIONS` |
| Android | `stepcounter`/`stepdetector` uses-feature `required=false` |
| iOS | `NSMotionUsageDescription` |

**Reddedilme hiçbir yolda exception fırlatmaz.** `StepPermissionStatus` beş
durum taşır; ana ekranda açıklayıcı kart, kalıcı reddedildiyse "Ayarları Aç"
düğmesi çıkar. Macera, mağaza, çark, profil çalışmaya devam eder.

---

# §6 — Sistemler

## 6.1 Zaman ve gün döngüsü

### Gün sınırı **04:00**

`GameDay.dayStartHour = 4`. İki gerekçe:
1. Gece yarısını geçmiş ama hâlâ ayakta olan kullanıcı gün ortasında
   kesilmiyor, serisi haksız yere kırılmıyor.
2. Çarkın gece yarısı açığını kapatıyor (23:59'da çevir, 00:01'de tekrar
   çevir).

`GameDay` API'si: `isSameGameDay`, `daysBetween`, `startOf`, `nextResetAfter`,
`timeUntilReset`. Adım halkası arşivi de **oyun gününü** anahtarlar, ham
tarihi değil (GD4) — 04:00 sınırında ham tarih bir sonraki takvim gününü
gösterir ve kayıt yanlış güne düşerdi.

**Kabul edilen takas:** 02:00'de atılan adım önceki günün halkasında görünür.
Apple Health / Google Fit gece yarısında keser; biz kesmiyoruz — halka günlük
**hedefe** göre ölçülüyor ve hedef 04:00'te sıfırlanıyor.

### `GameClock` — enjekte edilebilir ve monoton

İki işi var:

1. **Test edilebilirlik.** `GameClock.useSource(...)` ile sahte saat verilir.
   İleride sunucu saatine geçilirken yalnızca bu çağrı değişecek.
2. **Geriye alınan cihaz saatini yakalamak.** En son güvenilen okuma
   `UserProfile.lastSeenAt` olarak **UTC** yazılır. Cihaz saati ondan 5 dk
   (`backwardTolerance`) fazla geriye giderse `now()` **son güvenilen zamanı
   döndürür** — yani ilerleme donar. Ayrı bir "şüpheli saat" bayrağı yok:
   `now()` donunca seri de, çark hakkı da, gün değişimi de kendiliğinden
   donuyor.

**Monotonluk kontrolü UTC üzerinden, gün sınırı yerel saate göre.** Seyahat
eden kullanıcının yerel saati kayar ama UTC'si kaymaz → seyahat şüpheli
sayılmaz; 04:00 ise nerede olursan ol 04:00'tür.

**Bilinçli açıklar** (yerelde kapatmaya çalışmak sahte güvenlik olurdu):
- **İleri alınan saat yakalanamıyor** — ileri gitmek, gerçek zamanın
  geçmesinden yerelde ayırt edilemez. Kullanıcı bir gün ileri alıp fazladan
  çark hakkı kazanabilir.
- **Doğuya seyahat, saati ileri almakla aynı görünür.**
- **Batıya seyahat gün sınırını kullanıcıyla taşır**; o gün 24 saatten uzun
  sürer. "04:00 her yerde 04:00" kararının doğrudan sonucu.
- **Gerçek saat dilimi değişimi test edilemiyor** — Dart'ta süreç içinde yerel
  saat dilimini değiştiren desteklenen API yok. Mekanizma UTC üzerinden
  doğrulandı; gerçek geçiş cihazda elle doğrulanmalı.

## 6.2 Adım hattı

Üç katman, hiçbiri diğerinin işini yapmaz:

| Katman | Dosya | Sorumluluk |
|---|---|---|
| Ham sensör | `services/raw_step_sensor.dart` | Platform verisi. Değer **azalabilir**; düzeltmez |
| Sıfırlanma emme | `services/pedometer_step_source.dart` | Azalan ham değeri `StepSource`'un **azalmayan** sözleşmesine çevirir |
| Hız kontrolü | `core/utils/step_rate_limiter.dart` | Saf domain kuralı: "insan bu adımı bu sürede atabilir mi" |

**`RootShell` hiçbir koşulda azalan bir kümülatif değer görmez.** İhlal
kaynağın içinde emilir.

### Kritik risk ve çözümü

Android'de `TYPE_STEP_COUNTER` cihaz açılışından beri sayar ve **cihaz yeniden
başlayınca sıfırlanır**. Ekonomi `totalSteps - lastRewardedStepCount`
deltasından para ürettiği için ham değer geriye giderse ya adımlar kaybolur ya
bir anda tavan dolusu coin kazanılır.

Çözüm: artış her zaman `ham - öncekiHam` üzerinden; sıfırlanma tespiti
**offset'e değil, bir önceki ham okumaya** göre. Üç kalıcı alan:

| Alan | Anlamı |
|---|---|
| `lastReportedStepCount` | Kaynağın raporladığı son kümülatif değer |
| `lastSensorReading` (`int?`) | En son görülen **ham** sensör değeri |
| `lastStepReportAt` (UTC) | Hız kontrolünün "aradan ne kadar geçti" hesabı |

**`lastSensorReading` nullable olmak zorunda:** varsayılan 0 olsaydı, cihaz
açılışından beri birikmiş milyonlarca adım ilk okumada tek seferde
kredilenirdi. `null` = referans henüz kurulmadı.

**Sıfırlanma: reboot mu, arıza mı** — ayrımı oturum bağlamı yapar:

| Durum | Varsayım | Davranış |
|---|---|---|
| Soğuk açılışın **ilk** okuması düşük | Cihaz kapalıyken yeniden başlatılmış | Ham değer telafi edilir (≤ `maxResetRecoverySteps` = 10.000) |
| **Oturum içi** düşüş (8000 → 50) | Sensör arızası | Hiçbir şey kredilenmez |

Arıza dalındaki asıl tehlike **toparlanma**: 8000 → 50 → 8010 dizisinde
normalize sayaç fırlar; bu sıçrama hız kontrolünde yanar.

### Hız kontrolü

`limitStepBatch(reportedSteps, elapsed)` — saf fonksiyon.
İzin = `max(stepBurstAllowance, elapsed × maxStepsPerMinute)`.

| Sabit | Değer | Gerekçe |
|---|---|---|
| `maxStepsPerMinute` | 250 | Yarış yürüyüşü ~200/dk, koşu ~180/dk. Telefon sallamak 400+ üretir |
| `stepBurstAllowance` | 100 | Aynı saniyede gelen tek bir sensör partisi kırpılmasın |
| `maxResetRecoverySteps` | 10.000 | Sensör arızasının ekonomiyi patlatmasını engeller |

Hesap **milisaniye** üzerinden (saniyeye yuvarlamak kısa aralıklarda gerçek
adımları kırpıyordu). `StepSource.isPhysical` false olan demo kaynağı muaf.

**Bilinen sızıntı:** toparlanma sıçramasının `stepBurstAllowance` kadarı
(100 adım = 2 coin) kredilenir. Sensör arızası başına bir kez; ölçülü takas.

### Platform farkı

- **Android:** `pedometer` paketi → `TYPE_STEP_COUNTER`. Uygulama kapalıyken de
  artar, yani kapalıyken atılan adımlar baseline aritmetiğinden gelir. Arka
  plan servisi yok.
- **iOS:** `pedometer` paketi **kullanılmadı** — iOS'ta sayacı son cihaz
  açılışından başlatıyor ve `CMPedometer` yalnızca 7 gün geçmiş tuttuğu için
  uzun süre yeniden başlatılmamış cihazda değer oturumlar arasında **düşüyor**
  → sahte sıfırlanma → her açılışta bedava adım. Yerine
  `ios/Runner/AppDelegate.swift` içinde kendi kanalımız var: başlangıç anını
  Dart veriyor. `RawStepSensor.isBootCumulative` iki aritmetiği ayırıyor.
  ⚠️ **iOS kodu Windows'ta derlenmedi ve test edilmedi.**

### Demo kaynağı

Ana ekrandaki "Adım Kaynağı" kartı aktif kaynağı yazar ve debug'da bir
anahtarla değiştirir. **Debug varsayılanı manuel** (emülatör kutudan çıkar
çıkmaz çalışsın), **release varsayılanı pedometer**. Gerçek sensör aktifken
demo butonları kilitli ve nedenini söylüyor. `ManualStepSource` testlerin ve
emülatörün tek adım üretme yolu — **kaldırma**.

## 6.3 Ekonomi

### Coin

**50 adım = 1 coin** (`stepsPerCoin`). Mağaza fiyatlarından türetildi: 6.000
adım/gün = 120 coin/gün = 840 coin/hafta → haftada 1–2 anlamlı satın alma.

**Günlük coin tavanı kaldırıldı** (eski `maxDailyStepCoins = 400` yalnızca eski
API ve eski `dailyCoinCap` item etkilerini dönüştürmek için duruyor). Ekonomi
koruması artık `maxStepsPerMinute` fiziksel hız denetimine dayanıyor.

**Çift sayma yasağı:** para **delta**dan kazanılır, toplamdan değil:
`bekleyen = totalSteps - lastRewardedStepCount`. İşaretçi yalnızca **paraya
çevrilmiş** adım kadar ilerler; bir coin'e yetmeyen artık adımlar sonraki
hesaba kalır. Kapat-aç, gün değişimi, macera seçimi ve aynı değerin tekrar
bildirilmesi — dördü de testle bağlı.

**Yürüyüş fazında oran 30 adım = 1 coin** (`walkPhaseStepsPerCoin`, §6.11).
Hesap **iki geçişli**, çünkü bir parti faz sınırını geçebilir: önce bonuslu
pay 30/1 ile, sonra kalanı 50/1 ile. İşaretçi her geçişte yalnızca tüketilen
adım kadar ilerler.

### XP ve seviye eğrisi

**2 adım = 1 XP** (`stepsPerXp`). Seviye maliyeti `baseXpPerLevel * level` —
seviye başına **doğrusal** artar, kümülatif maliyet karesel olur:

```
N. seviyeye ulaşmak için gereken toplam XP = 500 · N · (N−1)
```

**Üstel eğri bilerek seçilmedi:** girdisi gerçek hayattan gelen bir oyunda
üstel maliyet bir noktada "aylarca sürecek seviye" üretir ve sayı durmuş gibi
görünür.

| Günlük adım | XP/gün | 10. seviye | 20. seviye |
|---|---|---|---|
| 3.000 | 1.500 | 30 gün | 127 gün |
| **6.000 (referans)** | 3.000 | **15 gün** | 63 gün |
| 10.000 | 5.000 | 9 gün | 38 gün |
| 20.000 | 10.000 | 4,5 gün | 19 gün |

**XP'nin günlük tavanı yok** — harcanacak bir yeri olmadığı için ekonomi
koruması gerekmiyor.

**Para ve XP işaretçileri ayrı** (`lastRewardedStepCount` /
`lastXpRewardedStepCount`): iki ekonominin birbirine bağlanmaması gerekiyor ve
artık-adım davranışları farklı (50 vs 2).

**Seviye atlama tek noktadan yayınlanır:** `RootShell._awardXp` XP veren
**tek** yol; `services/level_events.dart` bir `Stream<LevelUpEvent>` yayar. Tek
ödülle birden fazla seviye atlanırsa **tek** olay çıkar (`levelsGained > 1`).

### Ekonomi hizalama ölçümü

`test/economy_pacing_test.dart` seviye kapısı ile fiyat kapısını
karşılaştırır. Ölçümün açık varsayımı: **oyuncu katman başına 2 item alır**
(GD20). Referans oyuncu 6.000 adım/gün.

| Nadirlik | Adet | Medyan sv. | Seviyeye ulaşma | Medyan fiyat | Biriktirme (2 item) | Oran |
|---|---|---|---|---|---|---|
| Sıradan | 371 | 2 | 0,3 gün | 100 | 1,7 gün | *ölçüm dışı* |
| Az Bulunur | 271 | 5 | 3,3 gün | 325 | 5,4 gün | 1,63 |
| Nadir | 81 | 10 | 15,0 gün | 825 | 13,8 gün | 0,92 |
| Epik | 43 | 17 | 45,3 gün | 2.600 | 43,3 gün | 0,96 |
| Efsanevi | 18 | 27 | 117,0 gün | 8.450 | 140,8 gün | 1,20 |

Kabul bandı [0,5 – 1,8]: altında para hiç kısıt olmaz, üstünde seviye hiç kısıt
olmaz. Sıradan katman **mutlak** ölçütle bağlı: günlük hedefini tutturan oyuncu
**ilk akşam** bir item alabilmeli.

`stepsPerCoin`, `stepsPerXp`, `baseXpPerLevel`, `_costBase` ya da `_levelBand`
değişirse bu test alarm verir.

## 6.4 Seri (streak)

### Tetikleyici

Günde **2000 adım** (`streakStepThreshold`) **ya da bir düşman devirmek**
(§6.11). Hangisi önce gelirse seriyi güvenceye alır (GD59). İki kapı da
duruyor: macera oynamayan ama gerçekten yürüyen oyuncu cezalanmamalı ve
`ItemStat.streakRelief` buff'ı eşiğe bağlı.

Eşik günlük hedeften bilinçli olarak bağımsız ve düşük: seri "yürüdüm"
demeli ama 20.000 adımlık hedefe bağlanırsa çoğu gün kırılır.

### API — `UserProfile`

| Üye | İş |
|---|---|
| `registerStreakDay(now)` | Koşul sağlanınca çağrılır; aynı oyun gününde ikinci çağrı hiçbir şey yapmaz |
| `refreshStreak(now)` | Aktivite gerektirmez; gün atlanmışsa seriyi sıfırlar. `StreakDayOutcome` döner: `unchanged / broken / frozen` |
| `streakCompletedOn(now)` | Bugünkü seri tamamlandı mı |
| `longestStreak` | Seri kırılsa da korunur |
| `reachedStreakMilestone` / `nextStreakMilestone` | 7 / 30 / 100 gün |

Gün farkı `GameDay.daysBetween` ile **takvim günü** üzerinden hesaplanır — yaz
saati geçişlerinde bir gün 23 ya da 25 saat sürebilir, saat farkını güne bölmek
yanlış sonuç verir.

`lastActiveDay` seri kırılınca **bilerek silinmez**: sonraki
`registerStreakDay` aradaki boşluğu oradan görüp seriyi 1'den başlatır.

### Dondurma hakkı (streak freeze)

Bir günlük kaçırmayı telafi eden jeton. **Otomatik ve geriye dönük**: seri
kırılacakken jeton varsa 1'i harcanır, seri **korunur ama artmaz**.

| Sınır | Nasıl |
|---|---|
| Yalnızca **tek** kaçırılan gün | `gap == 2` şartı. İki gün üst üste kaçıran, iki jetonu olsa bile serisini kaybeder — jeton da boşa gitmez |
| Stok ≤ 2 | `maxStreakFreezes`; `fromJson` savunma amaçlı kırpar |
| Art arda en fazla 1 gün | Son aktif gün zaten jetonla kapatıldıysa (`lastFreezeUsedOn`) ikinci jeton kullanılamaz |

**Neden otomatik:** manuel bir kurtarma penceresi konsaydı, o pencereyi
kaçıran kullanıcı iki kez cezalanırdı. Serinin amacı alışkanlık, ceza değil.

Kazanım: 7 günlük kilometre taşında 1 adet + mağazadan 600 coin. Stok doluysa
**satış yapılmaz ve para harcanmaz**, nedeni söylenir.

Aktif (`registerStreakDay`) ve pasif (`refreshStreak`) yolların ikisi de aynı
private yardımcıdan (`_bridgeWithFreeze`) geçer; iki yolun aynı sonucu verdiği
testle bağlı.

### Seri savaş stat bonusu

**Her seri günü, savaş statlarından biri kalıcı olarak büyür.**

Kazanç basamaklı ve **döngüsel** (GD62) — koda gömülü sayı yok, iki config
sabitinden gelir (`streakBonusTierLength` = 100, `streakBonusTierTenths` =
[5,4,3,2,1]):

```
   1–100. gün : +%0,5      301–400. gün : +%0,2
 101–200. gün : +%0,4      401–500. gün : +%0,1
 201–300. gün : +%0,3      501+     gün : +%0,5 — döngü baştan
```

Bir tam tur (500 gün) toplam **+%150** biriktirir.

- **Tavan yok** — ne stat başına ne toplamda. Sabit tavan uzun seride her günü
  boşa çıkarıyordu.
- Tek statın uçmasını **ağırlıklı çekiliş** engeller (GD64):
  `ağırlık = 1 + min(streakBonusBalanceWeight, enYüksek − kendisi)`. Lider her
  zaman 1 ağırlıkla çekilişte kalır (rastgelelik gerçek), geride kalan en fazla
  9 kat şanslı olur. Ölçülen: 90 günlük seride dokuz savaş statının **hepsi**
  bonus alıyor ve lider en geridekinin iki katını geçmiyor.
- **Havuz elle yazılmadı:** `ItemStat.isCombat` üzerinden türetiliyor. Yeni bir
  savaş statı eklenirse havuz kendiliğinden genişler.
- **Ekonomi statları havuzda yok** (GD65): tavansız büyüyen bir para çarpanı
  ekonomiyi çökertirdi. Sekiz ekonomi statının hepsi ayrı ayrı sıfır kontrol
  ediliyor.
- **Birikim binde cinsinden `int`** (GD63): `0.005`'i yüz kez toplamak `0.5`
  etmiyor.
- **Seri kırılınca birikimin tamamı gider.** Bilerek: seriyi değerli kılan ve
  600 coin'lik dondurma hakkını haklı çıkaran şey bu. Jeton köprü kurduğunda
  birikim **korunur**.
- **Rastgelelik hem tohumlu hem kalıcı** (GD45): çekiliş yol bağımlı olduğu
  için tek başına tohum yetmez; sonuç diske yazılır ve gün `lastStreakBonusDay`
  ile işaretlenir → kapat-aç zar attırmaz, çark çevirmek sırayı değiştirmez
  (tohum akışı çarkınkinden ayrı).

## 6.5 Item sistemi

### Katalog nasıl üretiliyor

**Sanat klasörü doğruluk kaynağı, kod ona anlam veriyor.**

```
lib/Items/swords/fire_sword_variant_03.png
   └─ kategori: swords · temel kimlik: swords/fire_sword
      └─ item_definitions.dart → ("Ateş Kılıcı", nadir)
         └─ item_rules.dart → seviye kilidi · fiyat · arketip · buff · varyant sıfatı
            └─ "Yıpranmış Ateş Kılıcı"
```

| Dosya | Rol |
|---|---|
| `models/item.dart` | `Item`, `ItemCategory` (10), `ItemRole` (4), `ItemArchetype` (4), `ItemBuff` |
| `models/item_effect.dart` | `ItemStat` (15), `ItemEffectMode`, `ItemEffectTrigger` (8), `ItemEffect` |
| `data/item_definitions.dart` | 166 temel adın Türkçe adı + nadirliği |
| `data/item_archetypes.dart` | Arketip tabloları (veri) |
| `data/item_effects.dart` | İmzalı itemlerin lore'u ve elle yazılmış etkileri |
| `core/utils/item_rules.dart` | Saf türetme |
| `services/item_catalog.dart` | `AssetManifest` taraması + süzgeçler |

**784 görselin hepsi oyunda.** Toplam 1,8 MB, yani APK maliyeti yok; nadirlik
ve seviye kilidi zaten 784 item'ı uzun bir ilerlemeye yayıyor.

**Model Kuralları #1 temiz:** `Item` diske hiç yazılmıyor. Envanter yalnızca
`String` kimlik + seviye + nadirlik tutar; item her açılışta katalogdan
çözülür.

### Denge tablosu

| Nadirlik | Adet | Seviye kilidi | Fiyat | Eşya sv. tavanı | Birleştirme adedi |
|---|---|---|---|---|---|
| Sıradan | 371 | 1–3 | 100–125 | 10 | 3 |
| Az Bulunur | 271 | 4–7 | 300–350 | 20 | 4 |
| Nadir | 81 | 8–12 | 775–875 | 30 | 5 |
| Epik | 43 | 14–19 | 2.375–2.725 | 40 | 6 |
| Efsanevi | 18 | 22–29 | 7.550–8.825 | 50 | — |

Seviye kilidi `stableSpread` ile kimlikten türetilir — **`String.hashCode`
kullanılmadı** (GD8): sürümler arası sabit değil, bir güncelleme sonrası
oyuncunun sahip olduğu item "seviyen yetmiyor" diyebilirdi.

### Sınıf ↔ kategori dağılımı

Her sınıf **en az 3 kategori** ve **en az 150 item** görür; hiçbiri kataloğun
%60'ından fazlasını görmez. 18 oynanabilir sınıf var. Test bu iki yönü de
`AvatarProfile.playableClassIds` üzerinden bağlar (GD37) — elle yazılmış bir
sınıf listesi kullanma, ölü sınıfları doğrular.

**Sınıf kısıtı bilerek korundu:** herkes 784'ü görürse sınıf seçiminin oyun içi
karşılığı kalmaz.

### Aynı görsel, sınıfa göre farklı item (GD16)

`ItemCatalog.forCharacterClass` itemleri **uyarlanmış** döndürür: ad sınıf
lakabıyla önden genişler ve buff sınıfa göre çözülür.

```
magic/ancient_spell_book_type_1_variant_01
  Magic     → "Esrarlı Kadim Büyü Kitabı"  [adım XP · düşman XP]
  DarkMagic → "Lanetli Kadim Büyü Kitabı"  [çark XP · düşman XP]
```

**KRİTİK — `Item.id` sınıftan bağımsızdır.** Kimliğe sınıf gömülseydi, oyuncu
sınıf değiştirdiğinde `ownedItems` içindeki kimlikler katalogda karşılık
bulamaz ve **envanter sessizce boşalırdı**.

**Neden sıfat, tamlama değil:** "Şövalyenin Hançer" bozuk Türkçe; iyelik eki
ada göre değişiyor ve 166 tanımı elle çekimlemek gerekirdi.

### Varyant adları

"Hançer 4" değil **"Yıpranmış Hançer"**. 36 sıfatlık tek havuz; başlangıç
noktası `stableSpread('<baseId>|<sınıf>')` ile kayar, yani aynı görsel
Savaşçıda ve Hırsızda farklı sıfat alır. **Sınıf lakabı ve varyant sıfatı asla
birlikte uygulanmaz** — "Çelik Paslı Hançer" gibi çelişkili adlar çıkmasın
diye.

### Arketip ve buff çeşitliliği

Her item bir **arketip** taşır: **Vurucu / Muhafız / Düellocu / Çevik**.
Arketip hem savaş statlarını hem bütçe eğilimini belirler.

| Nadirlik | Ekonomi etkisi | Savaş etkisi | Toplam | Ekonomi bütçesi | Savaş bütçesi |
|---|---|---|---|---|---|
| Sıradan | 1 | 1 | 2 | %2 | 9 |
| Az Bulunur | 2 | 1 | 3 | %5 | 18 |
| Nadir | 2 | 2 | 4 | %9 | 32 |
| Epik | 3 | 2 | 5 | %15 | 55 |
| Efsanevi | 3 | 3 | 6 | %26 | 90 |

Arketip eğilimi bütçeyi kaydırır: **ekonomi ×0,85–1,00** (hiç 1,0'ı geçmez),
**savaş ×0,95–1,20**. Yani arketip sistemi ekonomiyi büyütemez.

**Ekonomi bonusu türü ağırlıklı, tekrarsız ve kararlı bir çekilişten gelir**
(GD36): sınıf imzası +8, kategori rolünün ilk üç eğilimi +4/+2/+1, her tür +1
taban. Tohum: item kimliği + sınıf.

**Ölçülen çeşitlilik:** aynı sınıf + kategori + nadirlikteki en kötü grup, 14
itemde 7 farklı buff (en sık kalıp %43). Bu sistemden önce her grup **tek**
kalıptı.

**Sınıf imzası artık her itemde değil, dağılımda okunur:** imza, sınıfın
gördüğü katalogda **en sık** birincil bonus olmalı (ölçülen %34–%50). 18 sınıf
ve 8 bonus türüyle "her sınıfın imzası ayrı" matematiksel olarak imkânsız.

### Sekiz ekonomi buff türü ve uygulama noktaları

| Tür | Etki | Nerede uygulanıyor |
|---|---|---|
| `stepCoin` | Adım parası +%X | `calculateStepCoins` çarpanı |
| `stepXp` | Adım XP +%X | `calculateStepXp` çarpanı |
| `wheelXp` | Çark XP +%X | `_spinWheel` → `_awardXp` |
| `enemyXp` | Düşman XP +%X | `_onStepsReported` düşman yenilme dalı |
| `streakFreezeCap` | Dondurma stoğu +N | `grantStreakFreeze(1, cap)` |
| `wheelSpinCap` | Çark hakkı stoğu +N | `grantExtraWheelSpin(1, cap)` |
| `streakRelief` | Seri eşiği −N adım | `_onStepsReported` eşik kontrolü |
| `dailyCoinCap` | *(emekli)* | `EquippedBuffs` bunu adım-parası oranına dönüştürür |

### İmzalı (elle tasarlanmış) itemler

**Bütün 18 efsanevi + 31 epik temel item + 12 seçilmiş nadir** elle yazılmış
etkiler ve bir **lore cümlesi** taşır. Geri kalan kural türetmesinde kalır.

> *Her item özelse hiçbiri özel değil.* 784 el yapımı etki hem bakımı imkânsız
> hem de efsanevileri sıradanlaştırır.

Yedi etki tipinin hepsi katalogda gerçekten kullanılıyor (testle bağlı): sabit
artış, yüzdesel artış, koşullu (`lowHealth`), tetiklenen (`onHit`), eşikli
(`untouchedRounds`), oyun dışı (`nightWalk`, `streakActive`), çift etkili
(bir artı + bir eksi, ör. `+%50 saldırı, −%18 savunma`).

**İmzalı itemler sınıfa göre değişmez** (GD22): "Azrailin Tırpanı" her sınıfta
Azrailin Tırpanı'dır. Zaten bir karakteri var; sınıfa göre yeniden yazmak onu
silerdi.

### Kuşanma

**Slot = item kategorisi** (GD26). Yeni bir kavram uydurulmadı; `ItemCategory`
doğrudan slot anahtarı. Sınıf başına 3–5 slot düşüyor.

`_refreshEquipment` her çözümlemede dört şeyi temizler ve **sahiplik kaydına
hiç dokunmaz** (GD28):
1. Katalogdan kalkmış kimlik,
2. Artık sahip olunmayan kimlik (satılmış),
3. Sınıfın kullanamadığı kategori (sınıf değişimi),
4. Yanlış slota yazılmış kimlik.

Sınıf değiştiren oyuncu itemlerini kaybetmez; yalnızca kullanamadıklarını
kuşanmaz. Slot boşalınca envanterdeki slot tahtası "Boş" gösterir.

### Ekonomi tavanları — dört katman

| Sınır | Değer | Nasıl |
|---|---|---|
| Tek item, koşulsuz ekonomi oranı | +%15 | `maxSingleItemEconomyBonus` — tasarım disiplini, testle taranıyor |
| Tek ünvan | +%25 (seyrek olayda +%50) | `maxTitleEconomyBonus` / `maxTitleRareEventBonus` |
| **Kuşanma + ünvan toplamı** | **+%50** | `maxEquippedEconomyBonus` — `EquippedBuffs.from` içinde **sert kırpma**, kodla zorlanıyor (GD25) |
| Stok bonusu / seri eşiği indirimi | +2 / −1000 adım | Ayrı kırpmalar |

**Ölçülen en kötü kuşanma: +%29** — kırpma bugün hiç devreye girmiyor. Kırpma
bir **sigorta**, tasarım aracı değil.

**Koşullu etki çarpana hiç girmez.** "Gece yürüyüşlerinde +%25" kuşanıldığı an
pasif bir bonusa dönüşmez; `conditionalEffects` içinde taşınır ve yalnızca
koşul sağlanınca `effectiveCombatStats` üzerinden açılır.

### Satış

`sellValueFor(cost)` = fiyatın **%40'ı**, 5'in katına yuvarlı, en az 5
(`itemSellRatio`).

- **Neden tam iade değil:** itemleri bir "depo" hâline getirirdi.
- **Neden çok düşük değil:** yanlış alınan item kalıcı bir ceza olmamalı.
- **Onay şart:** satış geri alınamaz; diyalog hem geri gelecek parayı hem
  tekrar almanın maliyetini söyler. Kuşanılı item satılırsa önce çıkarılır ve
  bu söylenir.
- Alım-satım(-birleştirme) döngüsünün **para üretemediği** testle bağlı.

## 6.6 Demirci

`features/inventory/blacksmith_screen.dart` — envanterin AppBar'ındaki örs
düğmesinden açılır. Envanter **kimlik + nadirlik** gruplarına bölünür.

### Eşya seviyesi

Her örnek **Sv. 1**'de başlar; otomatik seviye atlama yok. Oyuncu **coin**
harcayarak yükseltir.

**İki tavan, ikisi de geçerli:**
1. **Nadirlik tavanı** — 10 / 20 / 30 / 40 / 50 (`itemLevelCapByRarity`).
   Nadirlik böylece kalıcı bir üstünlük; sıradan bir eşya sonuna kadar
   yükseltilse bile efsanevi bir eşyaya yetişemez.
2. **Oyuncunun kendi seviyesi** — eşya seviyesi oyuncu seviyesini geçemez.

Hangisinin bağladığı kullanıcıya **ayrı ayrı** söylenir. "Yükseltilemiyor" tek
başına cevap değil.

**Yükseltme yalnızca savaş statlarını büyütür** (GD41): seviye başına +%10
(`itemStatGrowthPerLevel`). **Ekonomi bonusları sabit kalır** ve kural
`scaleForLevel` içinde **kodla** zorlanır (`stat.isCombat` olmayan her etki
olduğu gibi geçer). Ekonomi dikkatle dengelendi; çarpanlar eşya seviyesiyle
büyüseydi denge çökerdi.

**Maliyet tek sayıdan:** 1'den tavana çıkarmak eşya fiyatının **7 katı**
(`itemUpgradeTotalMultiplier`). Bir seviyenin payı
`itemUpgradeEarlyWeight + seviye / tavan`; ağırlıkların toplamı tam olarak
`tavan − 1` ettiği için toplam oranla birebir tutar.

| Nadirlik | 1→tavan maliyet | Coin günü (120/gün) | Oyuncu seviyesi günü |
|---|---|---|---|
| Sıradan | 675 (6,8×) | **6** | 15 |
| Az Bulunur | 2.300 | **19** | 63 |
| Nadir | 5.775 | **48** | 145 |
| Epik | 18.225 | **152** | 260 |
| Efsanevi | 59.200 | 493 | 408 |

**Okuma:** ilk dört katmanda oyuncunun kendi seviyesi coinden daha sıkı bir
kısıt. Para gerçek bir maliyet ama duvar değil — "yükseltmek mi, yeni eşya mı"
gerçekten sorulabilen bir soru.

Yükseltme her zaman grubun **en gelişmiş** adedine uygulanır; oyuncu yatırımını
tek eşyada toplasın.

### Birleştirme

Aynı eşyadan N örnek + coin → 1 örnek, **bir üst nadirlikte**.

| Geçiş | Adet | Ücret | Toplam | Doğrudan alım |
|---|---|---|---|---|
| Sıradan → Az Bulunur | 3 | 150 | 450 | 325 |
| Az Bulunur → Nadir | 4 | 350 | 1.650 | 825 |
| Nadir → Epik | 5 | 1.050 | 5.175 | 2.600 |
| Epik → Efsanevi | 6 | 3.325 | 18.925 | 8.450 |

Adetler tek config sabitinde (`itemMergeCounts`); efsanevinin haritada anahtarı
**yok** → birleştirilemez ve nedeni söylenir. Ücret hedef nadirliğin fiyatının
%50'si (`itemMergeCostRatio`) → birleştirmek doğrudan alımın ~2 katı.

**Neden pahalı olmalı:** birleştirmenin iki kalıcı avantajı var —
(1) **seviye kilidi değişmez** (GD40), yani erişemeyeceğin bir nadirliği erken
kuşanabilirsin; (2) nadirlik tavanı yükseldiği için eşya çok daha ileri
yükseltilebilir. Ücretsiz olsaydı mağaza anlamını yitirirdi.

**Sonuç Sv. 1'e döner** (GD42). Korunsaydı "üç eşyayı yükselt, sonra
birleştir" her zaman baskın strateji olurdu. Sertliği dengeleyen karar:
tüketilecek örnekler **otomatik olarak en düşük seviyeliden** seçilir ve
kuşanılı olanlar en sona atılır — dört adedi olan oyuncu birleştirdiğinde
Sv. 9 olan elinde kalır.

Onay ekranı harcanacak adetlerin **seviyelerini tek tek** yazar, kuşanılı bir
adet harcanacaksa bunu önceden söyler ve "Bu işlem geri alınamaz." der.

**İmzalı itemler karakterini korur** (GD22): elle yazılmış etkileri yeniden
türetilmez, nadirlik bütçesi oranında ölçeklenir.

## 6.7 Mağaza

`features/store/xp_store_screen.dart`. **Sekme**, itilen rota değil (GD11) —
satın alma sonrası para ve rozetler anında tazelenir.

Üç bölüm, bu sırayla:

1. **Ünvan Mağazası** (en tepede, GD78) — nadirlik çipleri, "Alabileceklerim",
   "Sendekileri gizle", sahiplik özeti.
2. **Yükseltmeler** — 4 adet:

   | Kimlik | Fiyat | Ne yapar | Tekrarlanabilir |
   |---|---|---|---|
   | `reincarnation_potion` | 2.000 | Karakter düzenlemeyi açar | Hayır |
   | `boost_double_xp` | 800 | Oyun gününün sonuna kadar 2× XP | Evet |
   | `upgrade_streak_freeze` | 600 | 1 dondurma hakkı | Evet |
   | `wheel_extra_spin` | 300 | 1 ekstra çark hakkı | Evet |

3. **Ekipman** — katalogdan, oyuncunun **kendi sınıfının** kullanabildikleri.
   Kategori süzgeci + "Alabileceklerim".

**Para birimi coin.** Sınıf/dosya adı `XpStoreScreen` olarak korundu (GD10);
yalnızca kullanıcıya görünen başlık "Mağaza".

**Aynı eşya tekrar satılır** (GD39, birleştirmenin zorunlu sonucu). Kart
"Sahipsin" yerine **"N adet"** gösterir ve düğme açık kalır.

**Kilitli kart sessiz kalmaz:** kilit ikonu, "Sv. N" etiketi ve dokununca tam
sebep — "29. seviye gerekiyor, şu an 2. seviyedesin" / "375 coin daha
gerekiyor".

**Kilit iki yerde tutulur:** ekranda (görünürlük) ve `RootShell`'de
(`_purchaseEquipment`). **Son söz state'in.**

Ekipman kartı ayrıca yatırım satırı taşır: "Yükseltilebilir · Maks Sv. 10 ·
3 tanesini birleştirince Az Bulunur olur".

**Stok doluysa satış yapılmaz ve para harcanmaz**, nedeni söylenir.

## 6.8 Ünvanlar

**65 ünvan** — oyuncunun adının yanında görünen kimlik.
`features/titles/titles_screen.dart`, `data/title_catalog.dart`.

| Kaynak | Adet |
|---|---|
| Başarım | 38 |
| Mağaza | 14 (700 – 48.000 coin) |
| Çark | 7 (çarkta en fazla **1** dilim) |
| Kilometre taşı | 6 (seri eşiklerine bağlı) |

Nadirlik: 13 sıradan · 14 az bulunur · 14 nadir · 13 epik · 11 efsanevi.

### Sahiplik ve takma

| Kavram | Alan |
|---|---|
| Sahip olunanlar | `ownedTitleIds` (`List<String>`) |
| Takılı olan | `equippedTitleId` (`String?`) |

**Aynı anda tek ünvan** ve kural **veri tipiyle** zorlanıyor (GD68): tek bir
`String?` ikinci değeri tutamaz. Ünvanlar tüketilmez; takılıyı değiştirmek
eskisini düşürmez. Temizlik (`normalizeEquippedTitle`) yalnızca **seçimi**
düşürür, sahipliğe dokunmaz.

Takılı ünvan görünür: ana ekran karşılama kartı, profil başlığı, profildeki
"Ünvanlar" kartı, ünvan ekranının tepesi.

### Tasarım kuralı — düz stat artışı yasak (GD69)

Her ünvan şu dördünden **en az birini** taşımak zorunda: bir tetikleyici, bir
bedel (eksi değerli ikinci etki), birden çok etki, ya da kendine ait bir metin
(`customLabel`). "+%10 saldırı" yazan çıplak bir ünvan **teste takılır**.

Örnekler:
- **Demir Yürek** — can %20 altına düşünce savunma +%60.
- **Cam Top** — saldırı +%70, can −%30.
- **Son Nefes** — can %15 altına düşünce saldırı iki katı.
- **Gece Yürüyüşçüsü** — yalnızca gece yürüyüşlerinde adım parası +%25.

Nadirlik etki sayısını büyütür (ort. 1,7 → 3,8). En az beş ünvan çift etkili.
Yedi tetikleyicinin hepsi katalogda gerçekten kullanılıyor.

### Başarım koşulları

On koşul türü: seviye, toplam adım, en uzun seri, devrilen düşman, tamamlanan
macera, eşya adedi, en yüksek eşya seviyesi, çark çevirme, birleştirme, ömür
boyu altın.

**Sayaçların beşi saklanıyor** (`enemiesDefeated`, `adventuresCompleted`,
`wheelSpins`, `itemsMerged`, `lifetimeCoins`); envanterden okunabilenler
**türetiliyor** (GD72) — iki doğruluk kaynağı er ya da geç çelişir.

**Kazanılmış ünvan geri alınmaz** — koşul sonradan bozulsa bile. Başarım "o anı
yaşadım" demek.

**Kilitli ünvanlar da listelenir** ve nasıl kazanılacağını söyler
(`unlockHint`); başarım ünvanlarında ayrıca ilerleme çubuğu.

Ekran arama (ad, hikâye **ve etki** metninde), kaynak süzgeci, dört ölçütlü
sıralama (varsayılan · nadirlik · "az kaldı" · A→Z) ve TEMİZLE düğmesi taşır
(GD79). Liste tembel (`SliverList.separated`).

## 6.9 Günlük çark

`features/wheel/daily_wheel_screen.dart` + `core/utils/wheel_rewards.dart` +
`data/wheel_odds.dart`.

**8 dilim, boş dilim yok.** Gerçek dilimli çark grafiği; ibre kazanan dilimin
**ortasında** durur — animasyon sonucu üretmez, önceden belirlenmiş sonucu
gösterir.

### Kompozisyon — bütün oranlar `wheel_odds.dart` içinde (GD80)

| Adım | Oran |
|---|---|
| Ünvan dilimi | Uygun ünvan varken **%25** ihtimalle 1 dilim |
| Ekipman dilimi | Uygun ekipman varken **en az 1**; adet ağırlıkları 55 / 28 / 12 / 5 |
| Altın dilimi | Adet ağırlıkları 30 / 45 / 25, en fazla 3 |
| XP dilimi | Kalan dilimlerin hepsi, **en az 1** |

| Tür | Değerler | Beklenen |
|---|---|---|
| XP | 50 → 1000, 50'şer (20 değer), azalan ağırlık | **367 XP** |
| Altın | 25 · 50 · 75 · 100 · 150 · 200 · 300 · 500 | **77 altın** |
| Ekipman nadirliği | sıradan 60 · az bulunur 27 · nadir 10 | — |
| Ünvan nadirliği | 50 · 28 · 14 · 6 · 2 | — |

### Süzgeçler ve sınırlar

- **Epik ve efsanevi ekipman çarktan çıkmaz** (GD19/GD81): epik ~üç haftalık,
  efsanevi ~iki aylık birikim; günde bir dönen bir çarktan düşmeleri hem
  mağazayı hem seviye kilidini anlamsız kılardı.
- Seviye kilidi **tek kaynaktan**: `Item.isUnlockedAt`. İkinci kontrol yok.
- Sahip olunanlar elenir; aynı item iki dilimde çıkmaz.
- Ünvanlarda efsanevi kapalı değil (ağırlık 2): ünvan ekonomiye girmiyor ve
  çark kaynaklı yedi ünvandan biri efsanevi.
- Uygun item bulunamazsa dilimlerin tamamı XP olur.

### Ekonomi etkisi

Referans oyuncu için beklenen günlük katkı: **~19 altın (+%16)** ve
**~137 XP (+%5)**. Adım ekonomisinden **ayrı** bir kaynak — çark altını
`lastRewardedStepCount` işaretçisine dokunmaz, dolayısıyla
`economy_pacing_test.dart` etkilenmez. Altın ayrıca `lifetimeCoins`'e yazılır.

### Determinizm

Hem dilim havuzu hem kazanan dilim **tek bir tohumdan** çıkar.
`UserProfile.wheelSeed` diske yazılır ve her çevirmeden sonra bir adım
ilerletilir (GD18). Başlangıç tohumu oyuncuya özel:
`initialWheelSeed('<ad>|<sınıf>')` → `stableSpread`.

### Hak yönetimi

Günde 1 hak (`lastWheelSpinAt` + `GameDay`), üstüne `extraWheelSpins` jetonu.
Günlük hak dururken jeton harcanmaz. **Kilit:** 3000 adım
(`dailyWheelUnlockSteps`) **ya da** günün ilk zaferi (GD59).

## 6.10 Savaş motoru

`core/utils/combat_engine.dart` — **saf, arayüzden bağımsız, deterministik.**

### ⚠️ Determinizm şartı

**Savaş kodunda `Random()` yasak.** Rastgeleliğin tamamı dışarıdan verilen
tohumdan gelir ve tohum sonuçla birlikte geri döner; tohum macera durumuyla
diske yazılır (`AdventureQuest.combatSeed`).

**Sebep:** ileride aynı motor sunucuda çalışacak. İstemci ile sunucu aynı
girdiden farklı sonuç üretirse ya hile kapısı açılır ya da savaş sistemi ikinci
kez yazılır. Deterministik olmayan bir motoru sonradan deterministik yapmak,
motoru yeniden yazmakla aynı şey.

Savaş tohumu akışı **çark ve seri bonusundan ayrı** bir sayaç kullanır
(`nextCombatSeed`) — paylaşsalardı oyuncu çarkı çevirerek savaşın zarını
kaydırabilirdi. Tohum kurulmadan round çözülürse
`fallbackCombatSeed(enemyId, startingSteps)` devreye girer (`stableSpread`,
`hashCode` değil).

**Genel kural:** kalıcı oyun sonucunu (can, ödül, item, para, XP) etkileyen her
rastgelelik tohumdan gelmeli ve tohum durumla birlikte saklanmalı. Yalnızca
sunumu etkileyen rastgelelik (animasyon, metin seçimi, arka plan) serbest.

### Dokuz stat — hepsi iş yapıyor, süs yok

| Stat | Savaşta ne yapar |
|---|---|
| `attack` | Hasarın çıkış noktası |
| `defense` | `azalma = savunma / (savunma + 50)` — azalan getiri, asla %100 değil |
| `maxHealth` | Can tavanı |
| `critChance` | Hasarı `1 + critDamage` ile çarpma ihtimali (tavan %60) |
| `critDamage` | O çarpanın büyüklüğü |
| `lifeSteal` | Verilen hasarın bu oranı kadar can yenilenir |
| `dodge` | Gelen vuruşu tamamen boşa çıkarma ihtimali (tavan %40) |
| `speed` | İnisiyatif: turda kim önce vurur. Öldürücü turda belirleyici |
| `luck` | Kritik/sıyrılma ihtimaline katkı + hasar bandını yukarı kaydırır |

`speed` ve `luck` **itemlerden gelmiyor** (GD52): arketip tablolarına eklemek
784 item'ın buff çekilişini yeniden yapar ve ölçülmüş dengeyi geçersiz kılardı.
Kaynakları taban stat, düşman statları ve seri bonusu.

### Stat toplama — tek nokta

`core/utils/effective_stats.dart`:

```
değer = (taban + ekipmanSabit) × (1 + ekipmanOran + seriOran + koşulluOran)
```

Dört kaynak: **taban** (seviye) + **ekipman** (eşya seviyesi ve birleştirme
dâhil) + **seri bonusu** + **koşullu etkiler**. Motor ikinci bir hesap yazmaz;
karakter paneli de aynı fonksiyonu okur. **Yeni bir kaynak eklenirse buraya
bağlanmalı, beşinci bir hesap yazılmamalı.**

Sabit katkı çarpandan **önce** girer: aksi hâlde "+12 saldırı" veren bir item,
oran bonusları büyüdükçe kendiliğinden değersizleşirdi.

### Tur akışı

```
inisiyatif (speed) → sıyrılma → kritik → değişkenlik (±%12, luck bandı kaydırır)
→ savunma → can çalma
```

Savunan ilk vuruşta öldüyse ikinci vuruş yapılmaz — `speed` bu yüzden gerçek
bir stat.

**Adım ↔ savaş bağı:** `c = clamp(yürünen / roundHedefi, 0, 1)` olmak üzere:

```
oyuncuHasarı = normalOyuncuHasarı × c × mükemmelRoundÇarpanı
düşmanHasarı = normalDüşmanHasarı × (1 − c)^1,5
```

Tam round (`c=1`) = tam vuruş + **kesinlikle sıfır** düşman hasarı; hiç
yürümemek (`c=0`) = hiç vuramamak + **tam** düşman hasarı. Aradaki eğri hafif
dışbükeydir: %90→%50 tamamlama arasındaki ceza artışı, %50→%10 arasındakinden
küçüktür. Böylece az kaçıran oyuncu doğrusal formüldeki kadar sert
cezalandırılmaz; büyük ölçüde yürümemek belirgin biçimde acıtır. Üs tek denge
sabiti `missedRoundDamageExponent = 1.5` içindedir.

**Mükemmel round:** hedef deadline'dan önce tamamlanırsa oyuncu hasarı bonus
alır. Round süresinin ne kadarı kaldıysa bonus o oranda büyür. Ardışık
mükemmel roundlar erişilebilir tavanı **×1,2 → ×1,5 → ×2** yapar; üçüncüden
sonra ×2'de kalır. Kaçırılan her round seriyi sıfırlar. Seri ve son geri
bildirim v21 kaydında tutulur; yeni macera/yeni oyun gününde sıfırdan başlar.

### Altı koşullu tetikleyici — hepsi çalışıyor

`lowHealth`, `highHealth`, `untouchedRounds`, `nightWalk`, `streakActive`
durum üzerinden (`CombatConditions`); `onHit` ve `onKill` olay üzerinden,
motorun içinde.

**`onKill` özel dal** (GD54): savaş düşman ölünce bittiği için "bir sonraki
tur" yoktur.
- `lifeSteal` / `maxHealth` statlı `onKill` → **öldürme anında iyileştirir**.
- Diğerleri → **bitirici vuruşa katılır**: normal hasar yetmiyor ama bonusla
  yetiyorsa vuruş öldürücü olur. Öldürmeyeceği turda hasarı **büyütmez**.

### Oyuncunun canı

`AdventureQuest.playerMaxHealth` seviyeden ve kuşanmadan gelir (GD53).
`RootShell._syncAdventureStats` seviye atlandığında ve kuşanma değiştiğinde
tazeler.

**Bedava iyileşme yok:** tavan büyüyünce mevcut can **yükselmez**, yalnızca
tavan küçülürse kırpılır. Aksi hâlde seviye atlamak ya da eşya takıp çıkarmak
savaş ortasında tam iyileşme verirdi.

**Savaş canının tek kaynağı `AdventureQuest`.** `UserProfile.hp` / `maxHp`
sınıfta duruyor ama **persist edilmiyor** ve hiçbir savaş yolunda okunmuyor.

### Düşmanlar

**20 düşman**, kademe 500 → 10.000 adım (`minimumDailySteps`, 500'er).
Statlar **elle yazılmadı** (GD51): elle verilen tek şey **arketip** —
**Dengeli** (6) / **Dayanıklı** (4) / **Çevik** (5) / **Büyücü** (5). Can,
saldırı, savunma, hız, kritik ve sıyrılma kademeden ve arketipten türetilir
(`core/utils/enemy_stats.dart`).

İki hedef sayı:
1. **Can** = o kademeye denk seviyedeki ölçüt oyuncunun round başına hasarı ×
   beklenen round sayısı. Kilit eşiğini seçen ölçüt oyuncu maceranın sonunda
   devirir, güçlü oyuncu erken.
2. **Saldırı** = tamamen kaçırılan bir roundun oyuncu canının %15'ini
   götürmesi. Ölçülen: hiç yürümeyen oyuncu 4–12 round içinde düşüyor
   (hedef ~7).

Katalogdaki elle yazılmış `attackDamage` korunur: kademenin doğrusal
beklentisine oranlanıp çarpan olarak uygulanır — tasarımcının bilerek zayıf
bıraktığı düşman zayıf kalır.

**Düşmanın canı adımdan koparıldı** (GD49): `stepGoal` artık düşman canı ya da
kilit eşiği belirlemez; yalnızca round hedefini ve beklenen round sayısını
belirler. Adım hedefi bitip düşman hâlâ ayaktaysa round hedefi **tam boya**
döner — eski formül 0 döndürüyordu ve savaş kilitlenirdi.

**Düşman önizlemesi** savaşa girmeden can/saldırı/savunma ve arketip rozetini
gösterir + tek cümlelik davranış açıklaması.

## 6.11 Macera

`features/adventure/adventure_screen.dart` (~2.900 satır) +
`models/adventure_quest.dart`.

### Saldırı yapısı — `attack_config.dart`

Bir macera **bir saldırıdır**. Sürenin tek doğruluk kaynağı
`GameConstants.stepsPerMinute = 100`:

```
toplamSüreDakika = toplamAdım / stepsPerMinute
roundSayısı = clamp(ceil(toplamAdım / 250), 2, 5)
roundAdımı = toplamAdım / roundSayısı  // kalan adımlar ilk roundlara dağıtılır
roundSüresi = roundAdımı / stepsPerMinute
```

250, hedef round boyudur; bir düşmana elle round/süre yazılmaz. Alt sınır 2,
500 adımlık başlangıç savaşını tek roundluk gerilimsiz bir sayaç olmaktan
çıkarır. 1.000 adım **4 × 250** olarak seçilir: 2 round fazla kaba, 10–11
round tekrarlı olur. Üst sınır 5, 10.000 adımlık düşmanın 40 rounda dönüşmesini
engeller. Uzun hedeflerde round başına adım ve süre büyür, toplam kadans hep
100 adım/dakika kalır.

**Altı seçilebilir hedef:**

| Adım hedefi | Toplam süre | Düşman güç çarpanı |
|---|---|---|
| 500 | 5 dk | ×1,00 |
| 1.000 | 10 dk | ×1,15 |
| 2.000 | 20 dk | ×1,35 |
| 3.000 | 30 dk | ×1,55 |
| 5.000 | 50 dk | ×1,85 |
| 10.000 | 100 dk | ×2,40 |

### Tempo sonrası ekonomi kontrolü

Referans oyuncu günde 6.000 adım atar: macera dışında **120 coin + 3.000
XP** değişmemiştir. Aşağıdaki zafer hesabı buffsızdır; coin sütunu tohumlu
aralığı, parantez içi ortalamayı gösterir. "İlk round mükemmel" sütunu güçlü
oyuncunun ilk 250 adımda bitirdiği üst-sınır senaryosudur; kalan taahhüt 30/1
yürüyüş coinine ve mevcut hız ödülüne girer.

| Düşman | Savaş süresi | Normal günlük toplam | İlk round mükemmel üst sınırı |
|---|---:|---:|---:|
| 500 adım | 5 dk (2×250) | 127–136 coin (131,5) · 3.100 XP | en çok 147 coin · 3.150 XP |
| 1.000 adım | 10 dk (4×250) | 130–142 coin (136) · 3.175 XP | en çok 168 coin · 3.306 XP |

Eski **120 coin/gün** yürüyüş tabanı değişmedi. Normal tek macera 500'de
ortalama +%9,6, 1.000'de +%13,3 ekler; bu zaten var olan zafer damlasıdır.
Mükemmel round doğrudan coin/XP basmaz: yalnızca düşmanı erken indirmeyi
kolaylaştırıp mevcut, tavanı ×2 olan hız ödülünü ve sınırlı yürüyüş-fazı
farkını besler. En sert 1.000 adım senaryosu 120 tabanına göre +%40'tır ama
yalnızca güçlü oyuncunun ilk roundda öldürmesiyle oluşur ve mutlak fark 48
coindir. Bu nedenle ödül oranı düşürülmedi; ekonomi sapması büyürse ayarlanacak
kaldıraç tempo değil `maxVictorySpeedMultiplier`dır.

### İki faz (GD55)

**Düşman devrilince macera bitmez.** Adım taahhüdü dolana kadar bir **yürüyüş
fazı** sürer.

Faz için kalıcı bir bayrak **yok** — iki doğruluk kaynağı er ya da geç çelişir.
Zaferin geldiği nokta damgalanır ve gerisi türetilir:

| Alan | Rol |
|---|---|
| `victorySteps` | Zafer anında harcanmış macera adımı. `-1` = damga yok |
| `victoryRounds` | Düşmanı deviren round (yalnızca gösterim) |
| `walkSteps` | Yürüyüş fazında biriken adım |

Türetilenler: `walkTargetSteps` (= `stepGoal - victorySteps`),
`walkRemainingSteps`, `walkProgress`, `isWalkPhaseActive`,
`isAdventureCompleted`, `speedRewardMultiplier`, `phase`.

⚠️ **`isEnemyDefeated` "macera bitti" demek değil.** Ödül kapıları ve ekranlar
`isAdventureCompleted` kullanmalı.

**Eski kayıt yürüyüş fazına geriye dönük sokulmaz:** damgası olmayan zaferli
kayıtta `victorySteps = stepGoal` kurulur → yürüyüş hedefi 0, çarpan ×1.

**Zafer kutlaması bir kez oynar:** `deathAnimationPlayed && isWalkPhaseActive`
ise ekran doğrudan yürüyüş sahnesine düşer.

### Hız ödülü (GD56)

```
çarpan = 1 + (1 − victorySteps / stepGoal) × (maxVictorySpeedMultiplier − 1)
```

Tavan **×2**. Tam hedefte devirmek ×1, hiç adım harcamadan devirmek ×2.

**Neden adımla ölçülüyor, roundla değil:**
1. Round sayısı kaba — 500 adımlık hedefte round sayısı düşük, hız ödülü hiç
   oluşamazdı.
2. Yürüyüş fazı zaten adımla tanımlı: **harcamadığın her adım hem çarpana hem
   bonuslu yürüyüşe yazılıyor.**
3. "Beklersem bedava çarpan alırım" kaçamağı yok: motor verilen hasarı round
   tamamlanma oranıyla ölçekler, yani yürümeden düşman devrilmez.

**Hem XP'ye hem altına uygulanır.** Zafer altını da tohumlu
(`victoryCoinRoll`, GD57).

**Gösterim şart:** görünmeyen çarpan kural değil, sürprizdir. Zafer ekranında
ve yürüyüş kartında "N round · M adım — hız ödülü ×1.8" yazar.

### Yürüyüş fazının kendi sahnesi (GD60)

Savaş ekranı paylaşılmaz: düşman sahneden çıkar, karakter `_Walk.gif` ile
yürür, üstte "YÜRÜYÜŞ FAZI" şeridi, kartlar kalan taahhüdü ve bonuslu oranı
anlatır.

Karakter sahneden çıkmaz — uçtan uca gidip döner ve dönüşte yatay olarak
aynalanır. Tek yönlü sonsuz geçiş daha "yol" gibi dururdu ama karakteri zamanın
yarısında ekran dışında bırakırdı.

Yeni asset gerekmedi: `All_Assets/.../<Sınıf>_Walk.gif` zaten var.

### Round çözümü ve zaman

- `RootShell` saniyede bir `_updateAdventureClock` çalıştırır;
  `resolveExpiredRounds` **birikmiş bütün roundları** çözer (tek tur değil).
  `maxCatchUpRounds = 500` güvenlik ağı.
- Round erken tamamlanırsa anında kazanılır; `roundTargetSteps <= 0` koruması
  düşman ölünce döngüyü durdurur.
- Uygulama arka plana geçince bildirim planlanır, öne gelince iptal edilir.

### İlerleme göstergeleri (GD34)

- **Ana bar (kalın):** macera ilerlemesi `questSteps / stepGoal` — **hiç
  sıfırlanmaz** (`ValueKey('quest-progress-bar')`).
- **İkincil (ince çizgi):** round içi ilerleme
  (`ValueKey('round-progress-bar')`).
- "Macera durumu" kartındaki bar **"Günlük Adım"** etiketli — dürüst etiket.

Oyuncunun birinci sorusu "maceranın neresindeyim"; "bu roundu tutturur muyum"
ikinci soru.

### Yenilgi ve hayat yürüyüşü

Oyuncu düşerse macera bitmez: **500 adımlık hayat yürüyüşü**
(`revivalStepTarget`) ile geri dönülür. `revivalStarted` / `revivalSteps`
deseni yürüyüş fazının da izlediği şekil: hedef türetilir, ilerleme kalıcı,
ekleme kabul edileni döner.

### Macera değiştirmek veri yakmaz

`_selectAdventure` / `_chooseNewAdventure` yeni bir `DailyProgress` kurar ama
**`steps`, `date`, `coinsEarned`, `xpEarned` ve `enemyDefeated` alanlarını
taşır.** Bu, projede iki kez yaşanmış bir hata sınıfı: kap nesnesi elle
yeniden kurulur ve bir alan unutulur (önce günün adımı sıfırlandı, sonra günlük
para tavanı sıfırlandı → sınırsız coin). **Yeni bir alan eklersen bu iki
metodu kontrol et.**

## 6.12 Ödül koleksiyonu

`features/rewards/rewards_screen.dart`, `services/reward_engine.dart`,
`data/reward_catalog.dart` + `reward_assets.g.dart`.

**1.244 PNG**, merkezî ve deterministik kayıtlara dönüştürülüyor. Asset listesi
`scripts/generate_reward_assets.dart` ile üretiliyor — elle düzenlenmez.

- **17 koşul türü** (`RewardConditionType`): toplam mesafe, tek yürüyüş
  mesafesi, günlük hedef, seri, tamamlanan gün, canavar avı, belirli villain,
  villain zaferi, hasarsız zafer, galibiyet serisi, görev, seviye, XP, boss,
  nadir villain, villain keşfi, düzenli devam.
- Koşul, hedef, nadirlik ve ad **asset indeksinden deterministik olarak**
  türetilir; kimlik, ad ve asset yolu benzersizliği `assert` ile bağlı.
- `RewardStatistics` bir **veri sözleşmesi**: yeni bir istatistik kaynağı
  eklendiğinde katalog ve ekran değişmez.
- `RewardEngine.evaluate` tamamlanan koşulları **yalnızca ilk kez** damgalar
  (`earnedRewardDates`) ve yeni açılanları döner.
- Oyuncu en fazla **6 ödül sabitleyebilir** (`pinnedRewardIds`).
- Bazı ödüller gizli (`hidden`).

Bu sistemi besleyen sayaçlar `UserProfile` üzerinde: `totalXpEarned`,
`longestSingleWalkSteps`, `flawlessWins`, `currentWinStreak`, `bestWinStreak`,
`bossesDefeated`, `rareVillainsDefeated`, `villainDefeatCounts`.

## 6.13 Eğitim ve rehber

### Rehber seçimi

Oyun açılışında (avatar yaratmadan önce) oyuncu bir **yol arkadaşı** seçer:
**Mavili · Pinky · Kupkuzu** (`lib/Tutorial_Guy/`). Seçim
`TutorialGuideStorage` ile ayrı saklanır. `TutorialGuideVariant` sprite'ı,
animasyon eşlemesini ve karakteri taşır.

### Eğitim — 29 adım

`features/tutorial/tutorial_guide.dart` → `TutorialGuideStep`:
`welcome → adventurePrompt → enemyChoice → … → combatDemo → victoryCelebration
→ rewardCoins/rewardXp → shopPrompt → itemBought → equipWaiting →
blacksmithPrompt → upgradeCompleted → wheelPrompt → wheelReward → finalMotto →
onlineTeaser → ratingRequest → farewell → completed`

Oyunun tam döngüsünü uçtan uca öğretir: savaş → ödül → mağaza → kuşanma →
demirci → çark. Spotlight + etkileşim bariyeri + konuşma baloncuğu ile.

**Eğitim savaşı bilerek tam hedefte damgalanır:** yeni oyuncu ×2 ödül almaz ve
eğitimin ortasında binlerce adımlık yürüyüşe kilitlenmez. **Eğitim zaferi
gerçek zafer sayılır** — eğitimin son durağı çark, kilitli bir çarkla
karşılaşmamalı.

İlerleme `UserProfile.hasCompletedTutorial` / `tutorialStep` ile kalıcı.

**Veda çıkışı** (GD83): son adımda (`leaving`) rehber ekrandan yürüyerek
çıkmıyor — bulunduğu yerde **death animasyonunu** oynatıp soluyor ve ancak
ondan sonra eğitim kapanıyor. Sabitler `TutorialGuideOverlay` üzerinde:
`farewellDeathHold` (960 ms, tam bir GIF çevrimi) + `farewellFade` (280 ms)
= `farewellExit`. Çıkış oynarken **etkileşim bariyeri kurulmuyor**: eğitim
bitmiştir, geriye yalnızca bir animasyon kalmıştır, oyuncu kilitlenmez.
Bu, pet'i profilden kapatınca oynayan çıkışla aynı animasyon — iki yol da
aynı vedayı gösteriyor.

### Dolaşan rehber (pet companion)

`features/tutorial/pet_companion.dart` + `data/pet_sayings.dart`. Eğitim
bittikten sonra rehber ekranda dolaşmaya devam eder ve bağlama duyarlı sözler
söyler.

**Mevcut eğitim bileşeninin üstüne yazıldı** (GD75): sprite, animasyon
eşlemesi ve karakter seçimi hâlâ `TutorialGuideAssets` /
`TutorialGuideVariant` üzerinden geliyor. Eğitim akışının hiçbir parçasına
dokunulmadı.

**Konum ve ölçek dinamik** (GD82): katman `Scaffold.body` içinde duruyor,
yani `bottom: 0` alt gezinme çubuğunun tam üstü. Sabit piksel yok:

| Büyüklük | Nereden |
|---|---|
| Taban çizgisi | Body'nin alt kenarı + `MediaQuery.padding.bottom` (bar yoksa jest çubuğu payı) |
| Sprite kenarı | `spriteSizeFor(ekranGenişliği)` = genişliğin %15'i, [44, 88] arası |
| Yürüyüş şeridi payı | `marginFor` = genişliğin %3,5'i, [12, 28] arası |
| Baloncuk genişliği | `bubbleWidthFor` = genişliğin %66'sı, [180, 320] arası |

Üç cihaz profilinde (320 dp donanım tuşlu · 390 dp jest çubuklu · 800 dp
tablet) **gerçek `NavigationBar` ile** ölçülüyor: pet çubuğun içine taşmıyor,
beş sekme düğmesinin hiçbiriyle kesişmiyor, ekran dışına çıkmıyor ve iki uçta
doğru kenar GIF'inde duruyor.

**Üç sert kural, üçü de testle bağlı (GD77):**

1. **Hiçbir düğmeyi engellemez.** Bütün katman `IgnorePointer` içinde;
   rehbere dokunma davranışı **hiç eklenmedi** — engellememe garantisi
   dokunulabilirlikten değerli.
2. **Sık konuşmaz.** İki söz arası ≥ 45 sn, baloncuk 6 sn. Sekme değişimi
   bekleyişi **atlar**: yeni bağlama girildiği an rehberin söyleyecek bir şeyi
   olmalı.
3. **Tekrarlamaz.** Son cümle havuzdan elenir.

Ayrıca: **eğitim sürerken katman hiç kurulmaz** (iki anlatıcı aynı anda
konuşmasın) ve profilden **kapatılabilir** (`petCompanionEnabled`, varsayılan
açık).

**Rehber sürekli yürümez** (GD76): bitimli bir tur atar, durur, zamanlayıcı
sonrakini başlatır. Bu bir tempo tercihi değil, **teknik zorunluluk** — sonsuz
`repeat()` her karede yeni kare planlar, `pumpAndSettle` hiç dönmez ve
`RootShell`'i kuran **58 test** aynı anda zaman aşımına uğrar.

Sözler bağlama duyarlı: sekme + macera var mı + çark hakkı duruyor mu + seri
güvencede mi. Test iki yönü bağlar: hiçbir havuz boş değil **ve** hiçbir cümle
iki bağlamda birden geçmiyor.

## 6.14 Taverna

`features/team/team_screen.dart`. Eski "Takım" sekmesinin yeni adı
(`Icons.sports_bar`).

**İşlev yazılmadı** (GD74): takım modeli, "yan yana yürüme" hesabı ve
`MockData.defaultTeam()` hiç değişmedi. Sınıf adı `TeamScreen` korundu.
Ekranın tepesinde rehberin ağzından bir karşılama kartı var ve liste açıkça
"şimdilik bir önizleme" diye etiketli.

**Önizleme bilerek kaldırılmadı:** boş bir ekran, "burada bir şey olacak"
demenin en zayıf yolu. Çevrimiçi mod §13'ün konusu.

## 6.15 Bildirimler

`services/adventure_notification_service.dart`. Uygulama arka plana alınınca
10'ar dk arayla en fazla 16 hatırlatma planlar, düşman saldırı GIF'ini
attachment olarak ekler, öne gelince iptal eder.

Hatırlatma sayısı `GameClock.now()` ile hesaplanır (GD2) — iki farklı saat
kaynağını karşılaştırmak, donmuş saatte hiç hatırlatma planlanmamasına yol
açıyordu.

**Açık borç:** `tz.setLocalLocation(tz.UTC)` sabit; cihaz saat dilimi
okunmuyor (`flutter_timezone` yok). Göreli offsetlerle çalıştığı için sorun
çıkarmıyor ama **gün/saat bazlı bir bildirim eklenirse bu acil bir hataya
dönüşür.**

## 6.16 Yerelleştirme

Resmî Flutter hattı kullanılıyor: `flutter_localizations` + `intl` + ARB +
`gen_l10n`. Türkçe şablon ve varsayılan dil; İngilizce ikinci dil. ARB dosyaları
`lib/l10n/app_tr.arb` ve `app_en.arb`, üretim ayarı `l10n.yaml` içindedir.
İngilizce ARB'de bulunmayan anahtarın Türkçe şablon değeri üretilir; boş metin
ya da anahtar adı kullanıcıya sızmaz.

Dil tercihi profilde **Sistem / Türkçe / İngilizce** olarak seçilir ve
`LocalePreferenceStorage` tarafından `locale_preference_v1` anahtarına yazılır.
Bu bir oyun durumu değil uygulama tercihidir; `GameState` şemasına eklenmez ve
migration gerektirmez (GD86). Sistem seçiminde cihazın Türkçe/İngilizce dili
izlenir; desteklenmeyen cihaz dili Türkçeye düşer. Değişiklik kök
`MaterialApp.locale` üzerinden yeniden başlatmadan uygulanır. iOS iki dili
`CFBundleLocalizations` içinde ilan eder.

Sayı, tarih ve saat biçimleri `core/localization/app_formatters.dart` üzerinden
seçili locale ile üretilir. Yeni elle yazılmış binlik ayıracı, ay adı veya saat
biçimi ekleme.

**2026-09-04 Faz 2 ilerlemesi:** ana gezinme, açılış hata durumu, karakter
oluşturma, ana sayfa, profil/adım geçmişi, taverna, mağaza, envanter/demirci,
ünvanlar, ödül koleksiyonu, günlük çark, boss ve macera ekranlarının sabit UI
çerçevesi ARB'ye taşındı. ARB şu an 200'den fazla anahtar ve ICU
placeholder/plural örnekleri içeriyor. Faz 2 golden temsili `titles_en_390.png`;
Türkçe 320/390 ünvan golden'ları da yeni yerleşimle yenilendi. Kalan Türkçe
eşleşmelerin ana grubu Faz 3 kapsamındaki katalog/anlatı içeriği ile
`RootShell` olay bildirimleri; macera savaşındaki birkaç durum/ölçü satırı da
Faz 2 kapanmadan temizlenecek.

**2026-09-04 Faz 3 başlangıcı:** içerik gösterimi kalıcı model alanlarını
değiştirmeden sabit kimlik üzerinden `l10n/content_localizations.dart` ile
çözülüyor. 20 düşmanın adı, görev anlatısı ve arketipi; 3 rehber seçeneği;
öğreticinin 28 dolu karesi ve düğmeleri; 23 bağlamsal pet repliği; yerel
bildirimlerin 4 gövdesi ile kanal metinleri TR/EN ARB'ye taşındı. Bildirim
servisi artık Türkçe sabit taşımıyor: `RootShell`, arka plana geçerken seçili
dilde hazırlanmış `AdventureNotificationCopy` veriyor. Bilinmeyen düşman
kimlikleri modeldeki Türkçe kanonik alana güvenli biçimde düşer. Faz 3 devamında
sınıf adları (eski kayıt kimlikleri dahil), 1.244 koleksiyon ödülünün ad/koşul
üretimi, item/ünvan gösterimi, round süreleri ve sonuçları da aynı sabit kimlik
katmanına alındı. Faz 3 golden temsilleri `phase3_guides_en_390.png` ve
`phase3_rewards_en_390.png`.

### Faz 0 metin envanteri

| Kategori | Adet | Yer / saklama biçimi | Durum |
|---|---:|---|---|
| Arayüz bağlama noktaları | 512 aday (396 `Text`, 116 başlık/etiket/tooltip/hint) | 28 `features/` ve `widgets/` Dart dosyası | Faz 2 tamamlandı; Faz 3 katalog/model sızıntıları kapatıldı |
| Sınıf seçimi | 22 güncel/eski sınıf kimliği + seçim sözü + cinsiyet etiketleri | `AvatarProfile` kanonik değerleri gösterimde `content_localizations.dart` üzerinden çözülüyor | Faz 3 tamamlandı |
| Koleksiyon ödülleri | 1.244 görsel için 17 koşul türünden üretilen ad, açıklama ve gereksinim | Kalıcı katalog alanları değişmeden koşul türü, hedef ve villain kimliği yerelleştiriliyor | Faz 3 tamamlandı |
| Item ad üretimi | 166 temel ad + 36 varyant sıfatı + 5 nadirlik | `data/item_definitions.dart`, `core/utils/item_rules.dart`, `models/reward_rarity.dart`; gösterimde sabit asset kimliği, nadirlik ve sıfat yerelleştiriliyor | Faz 3 tamamlandı |
| Ünvanlar | 65 ad + 65 lore + 123 özel etki etiketi | `data/title_catalog.dart` içine gömülü katalog; adlar sabit kimlikten, lore/kilit/etkiler yapılandırılmış kaynaktan yerelleştiriliyor | Faz 3 tamamlandı |
| Canavarlar | 20 ad + 20 görev metni + 4 arketip | `data/enemy_catalog.dart`; gösterim sabit `id` ile | Faz 3 tamamlandı |
| Görev/macera | Round, süre, adım, savaş sonucu, ödül ve kök akış bildirimleri | `adventure_screen.dart`, `root_shell.dart`; modeldeki süre/ad alanları gösterimde locale üzerinden çözülüyor | Faz 3 tamamlandı |
| Tutorial | 28 dolu frame mesajı + düğme etiketleri | ARB; adım enum'u yalnızca kalıcı akış kimliği | Faz 3 tamamlandı |
| Pet diyalogları | 23 replik | ARB; bağlamsal havuz locale anında kuruluyor | Faz 3 tamamlandı |
| Bildirimler | 4 gövde şablonu + kanal adı/açıklaması | ARB; servise hazır locale kopyası veriliyor | Faz 3 tamamlandı |

### İngilizce oyun terimleri sözlüğü

| Türkçe | İngilizce |
|---|---|
| macera | adventure |
| seri | streak |
| çark | wheel |
| ünvan | title |
| nadirlik | rarity |
| kuşanmak | equip |
| birleştirmek | merge |
| yükseltmek | upgrade |
| tur | round |
| yürüyüş fazı | walk phase |
| seri bonusu | streak bonus |
| adım | step |
| altın | gold |
| can | health |
| demirci | blacksmith |

---

# §7 — Kalıcılık

## Katman

| Dosya | Rol |
|---|---|
| `models/game_state.dart` | Kalıcı durumun tamamını taşıyan kap. "Nerede saklandığından" bağımsız: dışarıya düz `Map<String, dynamic>` verir |
| `services/game_storage.dart` | SharedPreferences'a yazma/okuma, şema, migration |
| `services/character_storage.dart` | Avatar (`player_avatar_v1`) |
| `services/tutorial_guide_storage.dart` | Seçilen rehber |
| `core/localization/locale_preference.dart` | Oyun şemasından bağımsız dil tercihi (`locale_preference_v1`) |

**Kayıt biçimi (zarf):** `{schemaVersion, savedAt, state}` — key `game_state_v1`.

## Şema — **güncel sürüm v20**

`GameStorage.schemaVersion = 20` + `_migrations` haritası ("sürüm N → N+1").
`load()` kayıtlı sürümden güncele kadar adımları **sırayla** uygular.

**Alan eklerken: sürümü artır VE haritaya bir satır ekle** — dönüşüm içerik
değiştirmese bile (disiplin, Model Kuralları #6).

Öne çıkan migrationlar:

| Geçiş | Ne yaptı |
|---|---|
| 1 → 2 | `hp`/`maxHp` şemadan çıkarıldı (hiç azalmayan, sabit 5000 yazan alanlar) |
| 4 → 5 | `lastRewardedStepCount = totalSteps` — ekonomi yokken atılmış adımlar geriye dönük para vermesin |
| 5 → 6 | `lastXpRewardedStepCount = totalSteps` — aynı gerekçe, XP için |
| 11 → 12 | Envanter kimlik listesinden **örnek** listesine (`OwnedItem`); yükseltmeler ayrı listeye |
| 13 → 14 | Yarım macera savaş motoruna **sadakatle** taşındı: eski `stepGoal − adım` oranı yeni can tavanına uygulandı |
| 17 → 18 | Seri bonusu gün sayısından **bindeye**: her değer ×10 |
| 18 → 19 | Ejderha Pelerini → "Gece Yürüyüşçüsü" ünvanı; `title_villain_hunter` → gerçek ünvan |
| 19 → 20 | Rehberin serbest dolaşma ayarı |

**Bozuk veri:** `FormatException` / `TypeError` / genel `catch` yakalanır,
`debugPrint` ile loglanır, `null` dönülür → temiz varsayılan. **Yeni** sürümdeki
bir kayıt (downgrade) da yok sayılır.

**Yazma sıklığı:** `scheduleSave()` en fazla 2 saniyede bir yazar
(`writeInterval`). Arka plana geçişte ve `dispose`'da `flush()`.

## Ne saklanıyor

Seviye, XP, coin, `lifetimeCoins`, seri (`streakDays`, `lastActiveDay`,
`longestStreak`, `streakFreezes`, `lastFreezeUsedOn`), seri stat birikimi ve
tohumu, `totalSteps` ve üç adım işaretçisi, ham sensör okuması, `lastSeenAt`,
envanter (`ownedItems` — örnek başına seviye/nadirlik/kuşanma),
`ownedUpgradeIds`, `nextItemInstanceId`, ünvanlar (`ownedTitleIds`,
`equippedTitleId`), çark (`lastWheelSpinAt`, `extraWheelSpins`, `wheelSeed`),
`xpBoostUntil`, eğitim durumu ve rehber seçimi, `petCompanionEnabled`, başarım
sayaçları, `earnedRewardDates`, `pinnedRewardIds`, günlük ilerleme (adım,
hedef, tarih, `coinsEarned`, `xpEarned`, `enemyDefeated`), adım geçmişi
(≤ 400 gün), macera (düşman, `startingSteps`, round durumu, savaş canları,
`combatSeed`, zafer damgası, yürüyüş adımı, hayat yürüyüşü).

## Ne saklanmıyor — ve neden

| Ne | Neden |
|---|---|
| `UserProfile.hp` / `maxHp` | Onları azaltan hiçbir kod yok; savaş canı `AdventureQuest`'te |
| `RootShell._rewards` | `Reward.icon` bir `IconData` → Model Kuralları #1 |
| Takım, mağaza kataloğu, item/ünvan/ödül katalogları | Sabit veri; her açılışta türetilir |
| Kuşanılan itemin **çözülmüş hâli** | Kimlik + seviye + nadirlik yeter; buff sınıfa göre her açılışta çözülür |

## Firebase hazırlığı

`GameState.toJson()` çıktısı doğrudan bir doküman. `savedAt` zarfta hazır.
İleride yerel depo "cache" rolüne geçebilir.

---

# §8 — Assetler

| Klasör | İçerik |
|---|---|
| `lib/All_Assets/Avatars/Classes/Characters(100x100 split)/<Sınıf>/<Sınıf>/` | 18 oynanabilir sınıf. Her birinde `_Idle`, `_Walk`, `_Hurt`, `_Death`, `_Attack01..03` GIF'leri |
| `lib/All_Assets/Enemies/Characters(100x100 split)/<Düşman>/<Düşman>/` | 20 düşman, aynı animasyon seti |
| `lib/All_Assets/coins/` | Ganimet sprite'ları |
| `lib/Items/<kategori>/` | **784 PNG**, 10 kategori |
| `lib/Rewards/<kategori>/<altkategori>/` | **1.244 PNG** koleksiyon ödülü |
| `lib/Backgrounds/` | 6 savaş arka planı |
| `lib/ChanceWheel/` | Çark grafikleri |
| `lib/Tutorial_Guy/{Mavili,Pinky,Kupkuzu}/` | Rehber sprite'ları |
| `lib/Start/` | Açılış ekranı |
| `lib/SoundEffects/` | Açılış ve ödül sesleri |

**Katalog üretim deseni:** `AssetManifest` taranır, dosya yolundan anlam
türetilir. `CharacterCatalog`, `ItemCatalog` ve `RewardCatalog` üçü de bunu
yapar. **Yeni sanat = klasör + `pubspec.yaml` satırı**; kod değişmez.

Tanımsız bir item görseli eklenirse katalog onu **atmaz**: adı dosya adından
üretilir, nadirliği `fallbackRarity` (sıradan) olur. Oyun bozulmaz; item
İngilizce adıyla görünür — bu da `item_definitions.dart`'a eklenmesi
gerektiğinin işaretidir. `item_catalog_test.dart` bunu **sanat kapsamı**
grubuyla yakalar.

**Ölü asset klasörleri** (pubspec'te değil, APK'ya girmiyor): `lib/Characters/`,
`lib/Enemies/`, `lib/GIF Animations/`. Zararsız; **silme onaya tabi** (Kural 8).

---

# §9 — Test

**830 test** (`flutter test --no-test-assets`). Test, bu projede dokümantasyonun
bir parçası: denge sayıları prosa tahmini olarak bırakılmaz, **testle bağlanır**.

## Test haritası

| Alan | Dosyalar |
|---|---|
| Adım hattı | `pedometer_step_source_test`, `step_rate_limiter_test`, `step_coins_test`, `step_xp_test`, `step_history_test`, `step_history_archive_test` |
| Gün ve seri | `game_day_test`, `streak_test`, `streak_freeze_test`, `streak_stat_bonus_test`, `streak_bonus_shell_test` |
| Item | `item_catalog_test`, `item_effects_test`, `item_variety_test`, `item_leveling_test`, `item_merging_test`, `item_comparison_test`, `equipped_buffs_test` |
| Mağaza / envanter / demirci | `store_screen_test`, `store_purchase_test`, `inventory_test`, `blacksmith_test` |
| Ünvan | `title_catalog_test`, `titles_test` |
| Çark | `wheel_rewards_test`, `daily_wheel_test`, `still_gif_frame_test` |
| Savaş ve macera | `combat_engine_test`, `combat_balance_test`, `combat_persistence_test`, `adventure_quest_test`, `adventure_progress_test`, `walk_phase_test`, `revival_walk_test`, `attack_config_test`, `goal_picker_test` |
| Ödül koleksiyonu | `reward_collection_test` |
| Eğitim / rehber | `tutorial_guide_test`, `pet_companion_test`, `character_creation_test`, `character_catalog_test` |
| Kalıcılık ve açılış | `game_storage_test`, `app_boot_test` |
| Ekonomi ölçümü | `economy_pacing_test` |
| Golden | `test/golden/` — mağaza kartı, demirci, örs, ünvan, seri bonusu, yürüyüş fazı, rehber, **rehber yerleşimi** (3 cihaz profili + veda ölümü) |

## Test desenleri

- **Denge testleri ölçer, iddia etmez.** `economy_pacing_test`,
  `combat_balance_test` ve `item_leveling_test` gerçek katalogla hesaplayıp
  bandın içinde olduğunu doğrular. Bir sabit değişirse alarm verir.
- **Sanat kapsamı testleri.** `item_catalog_test` dosya sistemini okuyup 784
  görselin hepsinin item'a dönüştüğünü ve **her görselin Türkçe tanımı**
  olduğunu doğrular.
- **Widget testleri gerçek `RootShell` üzerinden.** `_purchase`,
  `_purchaseEquipment`, `_equipItem`, `_mergeItems` bir `StatefulWidget`'ın
  private metotları ve mağazanın **son söz sahibi** orası. Mantığı saf bir
  fonksiyona çıkarmak çalışan mimariye dokunmak olurdu; widget testi aynı
  garantiyi verir.
  ⚠️ **Aynı test içinde ikinci kez `pumpWidget`** çağrılınca Flutter aynı
  tipteki elemanı yeniden kullanıp `initState` yerine `didUpdateWidget`
  çalıştırır; `RootShell._profile` `late final` olduğu için eski profil
  yerinde kalır ve test **sessizce yanlış şeyi ölçer**. Her kurulum ayrı bir
  `ValueKey` almalı.
- **Taşma testlerinde hata raporunu kısa tut.** `expect(errors, isEmpty,
  reason: errors.join(' | '))` — taşan bir düzen her karede yüzlerce hata
  üretir ve hepsini birleştirmek test koşucusunu **10 dakika kilitler**.
  Yalnızca ilk iki hatayı raporla.
- **Yeni test dosyası oluşturmadan önce aynı adda dosya olup olmadığını
  kontrol et.** Bir kez `character_catalog_test.dart` üzerine yazıldı ve 7
  test kayboldu; toplam sayı beklenenden düşük çıkınca fark edildi. **Her
  birimden sonra toplam test sayısını beklenen değerle karşılaştır.**

---

# §10 — Tekrarlayan tasarım ilkeleri

Bu projede aynı sekiz karar defalarca verildi. Yeni bir şey yazarken bunlara
uy; aykırı bir şey görürsen muhtemelen bir hatadır.

1. **Kalıcı sonucu etkileyen rastgelelik tohumludur ve tohum saklanır.**
   Çark (GD18), savaş (GD50), seri bonusu (GD45), zafer altını (GD57).
   Yalnızca sunumu etkileyen rastgelelik (animasyon, metin, arka plan)
   serbest.
2. **`String.hashCode` kullanılmaz** (GD8). Sürümler arası sabit değil; kalıcı
   bir şeyin (seviye kilidi, item adı, tohum) ondan türemesi güncelleme sonrası
   sessiz veri hatası demek. Yerine `stableSpread`.
3. **Tek doğruluk kaynağı.** Gün → `GameDay`. Şimdi → `GameClock`. Stat
   toplama → `effective_stats.dart`. Buff toplama → `equipped_buffs.dart`.
   Seviye kilidi → `Item.isUnlockedAt`. İkinci bir hesap yazma.
4. **Tavan tasarım disiplini, kırpma garantidir** (GD25). İkisi birlikte
   tutulur: disiplin testle taranır, kırpma toplama noktasında kodla zorlanır.
5. **Türet, ikinci kez saklama** (GD72). İki doğruluk kaynağı er ya da geç
   çelişir. Envanterden okunabilen bir şeyi ayrı bir sayaçta tutma.
6. **Kimlik değişmez.** `Item.id` sınıftan bağımsız (GD16), `OwnedItem`
   örneğinin `instanceId`'si kalıcı bir sayaçtan (GD39). Kimliğe bağlam
   gömmek, bağlam değişince envanteri sessizce boşaltır.
7. **Temizlik sahipliğe dokunmaz** (GD28, GD68). Çözülemeyen bir kuşanma ya da
   ünvan seçimi yalnızca **slotu** boşaltır; `ownedItems` / `ownedTitleIds`
   hiç değişmez.
8. **Kilit sessiz kalmaz.** Hangi tavanın bağladığı ayrı ayrı söylenir; geri
   alınamaz işlem (satış, birleştirme) bunu önceden yazar.

---

# §11 — GERİ DÖNÜLECEK KARARLAR (GD1–GD87)

Gözetimsiz oturumlarda tek başına verilmiş, ileride tartışmaya açık kararlar.
**Koddaki yorumlar bu numaralara atıf yapıyor — numaraları değiştirme.**
Bir kararı değiştirmeden önce gerekçesini burada oku.

| # | Karar | Gerekçe |
|---|---|---|
| GD1 | Açılışta kayıt okunamazsa temiz varsayılanla devam + SnackBar | Sonsuza kadar açılış ekranında asılı kalmaktansa açılmak yeğ. **Risk:** `RootShell` `_persist()` çağırınca eski kayıt üzerine yazar; salt-okunur oturum yok |
| GD2 | Bildirim planlaması `GameClock`'a bağlandı | İki farklı saat kaynağını karşılaştırmak, donmuş saatte hiç hatırlatma planlamıyordu |
| GD3 | *(GD84 ile geçersiz)* Round sistemine dokunulmadı | Eski tempo daha sonra oynanamaz bulundu |
| GD4 | Gün sınırı 04:00; adım halkası da oyun gününü anahtarlıyor | 00:00 sınırı çarkın gece yarısı açığını geri açıyordu; ham tarihle arşivleme kaydı yanlış güne yazıyordu |
| GD5 | Adım geçmişi 400 günle sınırlı | Tek anahtarda büyüyen liste her açılışı ve **her yazmayı** yavaşlatır. Veri kaybı geri alınamaz; tüketicisi yalnızca takvim ekranı |
| GD6 | `_archiveDailySteps` saf fonksiyona taşındı | `StatefulWidget` private metodu test edilemiyordu ve sessizce yanlış veri üretebilecek türdendi |
| GD7 | 784 item'ın hepsi katalogda; ad + nadirlik elle | Sanat bedava (1,8 MB); kelime kelime çeviri Türkçede bozuk sonuç veriyor ("Ateş Kılıç") |
| GD8 | Seviye kilidi `stableSpread`'den, `hashCode`'dan değil | `hashCode` sürümler arası sabit değil; sahip olunan item kilitlenebilirdi |
| GD9 | *(aşıldı — GD17/GD38)* Buff önce yalnızca adım kazancını büyütüyordu | Savaş statları henüz tanımlı değildi |
| GD10 | `XpStoreScreen` adı korundu, başlık "Mağaza" | Yeniden adlandırma çağrı noktalarını gezmek demek; proje benzer yazım borcunu bilerek bırakıyor |
| GD11 | Mağaza itilmiyor, **sekmeye** geçiliyor | İtilen rota `RootShell`'in alt ağacında değil; `setState` onu tazelemiyordu. Ölçüldü: satın alma sonrası para güncellenmiyor, kilitler açılmıyor |
| GD12 | *(K9 ile geçersiz)* Ekipman kartı sabit yükseklikteydi | `childAspectRatio` dar ekranda satın alma düğmesini kartın dışında bırakıyordu. Kart artık esnek satırda |
| GD13 | İki yükseltme gerçekten tüketiliyor | 800 ve 300 coin alıp hiçbir şey yapmıyorlardı |
| GD14 | *(GD39 ile güncellendi)* "Alabileceklerim" sahipliğe artık bakmıyor | Aynı eşya tekrar alınabildiği için sahip olunan da "bugün alabileceklerim"e ait |
| GD15 | Her sınıf **en az 3 kategori** ve **≥150 item** görüyor | Magic tek kategori görüyordu, süzgeç işlevsizdi. Üst sınır %60: sınıf seçimi anlamını yitirmesin |
| GD16 | Aynı görsel sınıfa göre farklı ad + buff; **kimlik değişmez** | Kimliğe sınıf gömülseydi sınıf değişiminde envanter sessizce boşalırdı |
| GD17 | 8 buff türü, nadirliğe göre 1–3 ekonomi bonusu | Hepsi bugün var olan bir uygulama noktasına karşılık geliyor |
| GD18 | Çark tohumlu; tohum diske yazılıyor | Kalıcı ödül üreten rastgelelik tohumlu olmalı |
| GD19 | Çarkta epik/efsanevi ekipman yok | Aylara yayılan birikimler günlük çarktan düşerse mağaza ve seviye kilidi anlamsız |
| GD20 | Fiyat eğrisi "katman başına **2 item**"e kalibre | Tek item varsayımıyla ölçülürse para seviyeden iki kat önce birikiyor *görünür*; kesişim tam ikide |
| GD21 | Sıradan fiyat tabanı 120 → 100 | En ucuz item 125 coin'di, günlük hedefin karşılığı 120 — oyuncu **beş coin** farkla ilk gününü eli boş kapatıyordu |
| GD22 | İmzalı itemler sınıfa göre değişmez | İmzalı itemin zaten bir karakteri var; sınıfa göre yeniden yazmak onu silerdi |
| GD23 | Varyantlar numara değil **sıfat** alıyor; sıfat sınıfa göre kayıyor | Varyant numarası bir dosya indeksidir, ad değildir. Lakap + sıfat üst üste gelseydi "Çelik Paslı Hançer" çıkardı |
| GD24 | Savaş statları cömert, oyun dışı statlar sıkı | Savaş motoru o gün yoktu → cömert olmak bedava; ekonomi ise canlı ve ölçülmüştü. **Her efsanevinin en az bir canlı etkisi olması** testle şart |
| GD25 | Kuşanma tavanı **toplama noktasında**, item başına değil | Item başına %15 bir disiplin (insan hatasıyla aşılır); toplama noktasındaki kırpma bir **garanti** |
| GD26 | Slot = item kategorisi | Yeni bir kavram uydurulmadı; kategori zaten mağaza süzgeci ve sınıf başına 3–5 tanesi açık |
| GD27 | İtilen ekran veri tutmuyor: `_revision` + `readState` | GD11'in tuzağı; altıncı bir sekme alt çubuğu sıkıştırırdı. Kopya tutmak tutarsızlık üretirdi |
| GD28 | Kuşanma temizliği **sahipliğe dokunmaz** | Sınıf değiştirip geri dönen oyuncunun itemleri yerinde durmalı |
| GD29 | Satış fiyatın %40'ı ve geri alınamaz | Tam iade envanteri "depo" yapardı; çok düşük olsa yanlış alım kalıcı ceza olurdu |
| GD30 | Sınıf tanıtım ekranındaki onay doğrudan özet adımına geçiriyor | Karar karakteri incelediğin yerde verilmeli; iki onay ikincisini anlamsız kılıyordu |
| GD31 | Onaylanmamış varsayılan sınıf geçerli seçim sayılmıyor | Oyuncu hiçbir sınıfa bakmadan varsayılanla başlayabiliyordu |
| GD32 | Tanıtımdaki örnek ekipman ve saldırı animasyonu **kararlı** | Her açılışta değişen kimlik kartı sınıfı keyfî gösteriyordu; golden ile doğrulanamıyordu |
| GD33 | Haptik geri bildirim beklenmiyor (`await` kaldırıldı) | Titreşim kanalı yanıt vermezse sihirbaz **tamamen kilitleniyordu** — widget testinde birebir gözlendi |
| GD34 | Ana gösterge **macera**, ikincil gösterge **round** | Oyuncunun birinci sorusu "maceranın neresindeyim"; her round sıfırlanan tek bar bunu görünmez kılıyordu |
| GD35 | Sprite kutusu genişliği sahneden türetiliyor | 320 dp'de düşman oyuncuyu **tamamen örtüyordu** |
| GD36 | Sınıf imzası her itemde değil, **dağılımda** okunuyor | Buff türetmesi item kimliğini hiç kullanmıyordu → bir sınıfın bütün sıradan kılıçları aynıydı. 18 sınıf × 8 tür ile "her itemde imza" imkânsız |
| GD37 | Dağılım testi **canlı sınıf listesinden** (`playableClassIds`) | Elle yazılmış 8 sınıflık liste ölü sınıfları doğruluyordu; gerçek 18 sınıfın hiçbiri denetlenmiyordu |
| GD38 | Kuraldan türeyen itemler de savaş statı taşıyor (arketip) | Ekonomi bütçesi arketiple yalnızca **küçülüyor** (≤1,0), savaş bütçesi büyüyor → aynı güç farklı dağılıyor |
| GD39 | Envanter kimlik listesinden **örnek** listesine (`OwnedItem`) | Birleştirme aynı eşyadan birkaç adet ister. `instanceId` kalıcı bir sayaçtan; liste indeksi kayabilirdi |
| GD40 | Nadirlik yükselince **seviye kilidi değişmez** | Birleştiren oyuncunun elinde kuşanamayacağı bir eşya kalırdı; birleştirme bir ödül olmalı |
| GD41 | Yükseltme yalnızca **savaş** statlarını büyütür | Ekonomi ölçülmüş bir dengeye bağlı; çarpanlar seviyeyle büyüseydi denge çökerdi. Kural `scaleForLevel` içinde kodla zorlanıyor |
| GD42 | Birleştirmenin sonucu **Sv. 1**'e döner | Korunsaydı "yükselt sonra birleştir" baskın strateji olurdu. Tüketilecekler en düşük seviyeliden seçilerek dengeleniyor |
| GD43 | Birleştirme ücreti hedef nadirliğin fiyatının %50'si | Birleştirmenin iki kalıcı avantajı var (kilit değişmiyor, tavan yükseliyor); ücretsiz olsaydı mağaza anlamsızlaşırdı |
| GD44 | *(GD62–GD65 ile güncellendi)* Seri her gün **rastgele bir** savaş statını büyütür | Tek stata giden bonus 30 günlük seriyi tek sayıya indiriyordu ve "bugün ne kazandım" anı yoktu |
| GD45 | Seri çekilişi hem **tohumlu** hem **kalıcı** | Çekiliş yol bağımlı; saf `f(tohum, gün)` bütün geçmişi yeniden oynatmayı gerektirirdi. Gün işareti kapat-aç zar attırmayı kapatıyor |
| GD46 | Seri bildirimi `addPostFrameCallback`'e alındı | `_showLevelUp` `hideCurrentSnackBar()` çağırıyor; seri bildirimi kuyruğa önce girip hiç görülmeden kapanıyordu |
| GD47 | Adım partisinin **bütün** bildirimleri frame sonuna alındı | Ölçüldü: 6 günlük seriyle 5000 adım atan 1. seviye oyuncu, kazandığı dondurma hakkını duyuran tek bildirimi hiç görmüyordu |
| GD48 | `StillGifFrame` test edilebilmek için public yapıldı | Hatalı asset enjekte etmenin başka yolu yoktu; `rootBundle` mock'lamak alakasız hatalar üretirdi |
| GD49 | Düşman canı adımdan koparıldı; `stepGoal` yalnızca yürüyüş taahhüdü | "Her adım 1 hasar" modelinde 15 statın 9'u tanımlıydı ama okunmuyordu. Adım hedefi bitip düşman ayaktaysa round hedefi tam boya döner (kilitlenme kapatıldı) |
| GD50 | Savaş motoru saf, deterministik, tohumu saklanan | Aynı motor ileride sunucuda çalışacak. Tohum akışı çarktan **ayrı** — yoksa çark çevirerek savaşın zarı kaydırılırdı |
| GD51 | Düşman statları kademe + arketipten türetiliyor | 20 düşmana elle 9'ar stat yazmak tutarsız ve bakımsız olurdu. Katalogdaki elle yazılmış `attackDamage` çarpan olarak korunuyor |
| GD52 | `speed` ve `luck` eklendi ama **itemler vermiyor** | Arketip tablolarına eklemek 784 item'ın buff'ını yeniden çeker ve ölçülmüş dengeyi geçersiz kılardı |
| GD53 | Oyuncunun savaş canı sabit 100 olmaktan çıktı | Seviye + kuşanmadan geliyor. **Bedava iyileşme yok:** tavan büyüyünce mevcut can yükselmiyor |
| GD54 | `onKill` etkileri **bitirici vuruşa** katılıyor | Savaş düşman ölünce bittiği için "sonraki tur" yok; etki ölü kalırdı. Sözü tutulur hâle getirmek, sözü değiştirmekten yeğ |
| GD55 | Macera iki fazlı; faz **durumdan türetiliyor**, ayrı alan değil | İki doğruluk kaynağı er ya da geç çelişir. Eski kayıt geriye dönük yürüyüş fazına sokulmuyor |
| GD56 | Hız ödülü **adımla** ölçülüyor, roundla değil | Round sayısı 2–5 arası kaba bir ölçü. Harcamadığın her adım hem çarpana hem bonuslu yürüyüşe yazılıyor |
| GD57 | Zafer altını tohumlu | Kalıcı bir ödülü etkileyen rastgelelik tohumlu olmalı; ayrıca test edilemiyordu |
| GD58 | Yürüyüş fazı oranı 30/1; para hesabı **iki geçişli** | Bir parti faz sınırını geçebilir. Ölçülen sapma referans oyuncuda **+%13**; kazanç yapısal olarak sınırlı (`stepGoal/75`) |
| GD59 | Seri ve çark **iki kapıdan**: zafer ya da adım eşiği | Macera oynamayan ama yürüyen oyuncu cezalanmamalı; `streakRelief` buff'ı eşiğe bağlı; 66 mevcut test eşiğe dayanıyor |
| GD60 | Yürüyüş fazının kendi sahnesi var | Savaş sahnesine hiç dokunulmadı. Karakter sahneden çıkmıyor — yürüyüşe bakan biri yürüyen birini görmeli |
| GD61 | Ganimet düşmanın **önünde** | `Stack` çocukları sırayla boyanır; altınlar cesedin arkasında kalıyordu. Golden tek başına yetmez — ağaç sırası testle ölçülüyor |
| GD62 | Seri bonusu tavanı kalktı; kazanç azalıp **sıfırlanan** bir döngüye girdi | Sabit tavan uzun seride her günü boşa çıkarıyordu; monoton azalan eğri de aynı anlamsızlığa varırdı. Sıfırlanma 500. günü bir **ödül** yapıyor |
| GD63 | Birikim **binde** cinsinden `int` | `0.005`'i yüz kez toplamak `0.5` etmiyor. v17→v18 her değeri ×10 yapıyor |
| GD64 | Stat tavanı yerine **ağırlıklı çekiliş** | Sert stat tavanı, toplam tavan kalkınca hepsini tavana oturtur — kaldırılan tavanın geri gelmesi |
| GD65 | Ekonomi statları havuzda **hâlâ** yok | Tavansız büyüyen para çarpanı ekonomiyi çökertir; savaş statlarında aynı risk yok (motorun kendi tavanları var) |
| GD66 | Panel tavanı değil **güncel basamağı** gösteriyor | Oyuncu 200. günde kazancının neden küçüldüğünü, 501'de neden büyüdüğünü görmeli |
| GD67 | Pelerin silinmedi, **ünvana dönüştürüldü** | Coin iadesi "yanlış alışveriş" ilan etmek olurdu; ünvan verilmiş sözü ilk kez tutuyor |
| GD68 | Aynı anda **tek** ünvan; garanti alanın kendisinde | `String?` ikinci değeri tutamaz. Ünvanlar tüketilmiyor |
| GD69 | Ünvanlar düz stat artışı **vermiyor**; kural testle zorlanıyor | Kural üslup olarak bırakılsaydı 65 satırlık tabloya zamanla düz bonuslar sızardı |
| GD70 | Ünvan ekonomi tavanı +%25; seyrek olay statlarında +%50 | Oyuncu 3–5 item kuşanıyor ama **tek** ünvan takıyor. `wheelXp`/`enemyXp` günde/macerada bir kez uygulanıyor ve ikisi de XP |
| GD71 | Dört kazanma yolu; çarkta en fazla **bir** ünvan dilimi | Çoğunluk parayla alınsaydı ünvan bir mağaza rafına dönerdi. Süzme havuzun içinde: başka yoldan gelen ünvan çarktan çıkmaz |
| GD72 | Başarım sayaçları saklanıyor, **envanterden okunabilenler türetiliyor** | İki doğruluk kaynağı çelişir. Sayaçlar geriye gitmiyor — eksi bir sayaç ünvanı kalıcı kilitleyebilirdi |
| GD73 | *(GD78 ile geçersiz)* Ünvan bölümü mağazanın sonundaydı | Gerekçesi testlerin kaydırmamasıydı, kodda hata değil |
| GD74 | Taverna bir **ad değişikliği**; takım ekranı olduğu gibi duruyor | Boş bir ekran "burada bir şey olacak" demenin en zayıf yolu |
| GD75 | Dolaşan rehber mevcut pet bileşeninin **üstüne** yazıldı | Eğitim baloncuğu düğme taşıyor ve akışa bağlı; onu "bazen düğmesiz" yapmak eğitime dokunmak olurdu |
| GD76 | Rehber sürekli yürümüyor; tur atıp duruyor | Sonsuz `repeat()` her karede kare planlıyor → `pumpAndSettle` dönmüyor → **58 test** zaman aşımına uğradı |
| GD77 | Rehber hiçbir düğmeyi engelleyemez ve sık konuşmaz | `IgnorePointer`; dokunma davranışı hiç eklenmedi — engellememe garantisi dokunulabilirlikten değerli |
| GD78 | Ünvan rafı mağazanın **en tepesinde** | Kullanıcı bildirimi: 14 ünvan uzun ekipman ızgarasının altında görünmüyordu. Testlere `scrollStoreTo` eklendi |
| GD79 | Ünvan listesi arama + kaynak süzgeci + sıralama aldı | Oyuncu ünvanı adıyla değil **işiyle** arıyor ("kritik", "gece"); "az kaldı" sıralaması listenin en değerli bilgisi |
| GD80 | Çarkın **bütün** oranları tek tabloda (`wheel_odds.dart`) | Eski kod her gün aynı şekilli bir çark üretiyordu; ağırlıklı çekiliş çarkı çevirmeden önce de merak edilir kılıyor |
| GD81 | Çark altın veriyor; epik/efsanevi ekipman çarktan kalktı | Altın adım ekonomisinden **ayrı** bir kaynak (işaretçiye dokunmuyor). Epik/efsanevi kaldırma GD19'un geri gelmesi |
| GD82 | Rehber `Scaffold.body` içinde yaşıyor; konumu sabit pikselden çıkmıyor | Body'nin alt kenarı zaten alt gezinme çubuğunun üst kenarı → `bottom: 0` "barın hemen üstü" demek. Ölçüm, tema sorgusu ya da 96 px tahmini gerekmiyor; jest çubuğu olan/olmayan cihazda, bar gizlendiğinde ve klavye açıldığında kendiliğinden doğru |
| GD83 | Eğitim rehberi ekrandan yürüyerek çıkmıyor, **death** animasyonuyla veda ediyor | Çıkış artık pet'i kapatmakla aynı hissi veriyor. Süre sabit (960 ms): üç rehberin `*_Death_8.gif` dosyası da 8 kare × 120 ms, ve geçişi gerçek dosya okumasına bağlamak hem testlerde sahte saatle ilerletilemez hem asset okunamazsa eğitimi biteceği anda takardı |
| GD84 | Savaş temposu tek sabitten **100 adım/dk**; round sayısı 250 hedefinden 2–5 arası türetiliyor; mükemmel seri ×2 tavanlı | Eski 1.000 adım/15 dk roundu ile yüzdeli config çelişiyordu; bazı UI hedefleri sprint istiyordu. 500→2 ve 1.000→4 round gerilimi korurken, 5 tavanı uzun düşmanlarda tekrar hissini engelliyor |
| GD85 | Yerelleştirme resmî `flutter_localizations` + `intl` + ARB/`gen_l10n` hattında | Flutter SDK ile sürüm uyumlu, üçüncü parti çalışma zamanı ve ayrı anahtar üretim sistemi getirmiyor |
| GD86 | Dil tercihi `GameState` dışında ayrı SharedPreferences anahtarında | Dil bir oyun ilerlemesi değil cihaz/uygulama tercihidir; oyun kayıt şemasını ve ilerideki Firebase zarfını gereksiz yere değiştirmemeli |
| GD87 | Türkçe ARB şablon ve eksik çeviri yedeği; desteklenmeyen sistem dili de Türkçe | Mevcut Türkçe hiçbir şey kaybetmez; yarım İngilizce çeviride boş değer veya anahtar adı kullanıcıya görünmez |

## Arkadaşımın mimari tercihleri — bilinçli olarak dokunulmadı

| # | Ne | Neden dokunulmadı |
|---|---|---|
| K2 | *(GD84 ile geçersiz)* Round süresi adımdan bağımsızdı | Kullanıcı tempo dengelemesiyle süre artık tek kadans sabitinden türetiliyor |
| K3 | Round erken tamamlanınca anında kazanılıyor | Sonsuz döngü ve çift hasar yok — satır satır doğrulandı |
| K4 | Sunum durumu (`presentedRoundOutcomeSerial`) modelde | Model Kuralları #1'i ihlal etmiyor (`int`); ayırmak modeli, ekranı ve şemayı birlikte değiştirmek demek |
| K5 | Ekran, model nesnesini doğrudan değiştiriyor | Mevcut `setState` mimarisi zaten buna dayanıyor. Riverpod/Bloc geçişinde ilk kırılacak yer |
| K6 | Yeni düşmanlar kataloğun başına eklendi | Testler `byId(...)` kullanıyor; sıraya bağlı kod kalmamış |
| K7 | Açılış sesi için elle yazılmış platform kanalı | Kanala dokunulmadı; yalnızca `MediaPlayer` sızıntısı kapatıldı |
| K9 | Ekipman ızgarası esnek satıra çevrildi | GD12'nin çözdüğü sorunu **daha iyi** çözüyor ve hâlâ tembel. GD12 artık geçersiz |

---

# §12 — Bilinen açıklar ve teknik borç

## Şu an kırmızı olan testler

2026-09-04 yerelleştirme Faz 1 sonunda `flutter test --no-test-assets` →
**865 başarılı, 15 başarısız.** Başarısızların tamamı oturum başındaki kirli
çalışma ağacında zaten değişmiş ekranlara ait mevcut **golden** farklarıdır;
yerelleştirme davranış testleri (5), açılış testleri (4) ve yeni dil seçici
golden'ları (4) geçiyor.

- `character_creation_test` — sınıf ızgarası/tanıtım ekranı
- mevcut `golden/` ekranları — demirci, ünvan, pet yerleşimi vb.

Test asset paketi bu oturumda normal `flutter test` ile yenilendi ve shader
tekrar yerine kondu; kalan farklar bayat asset paketinden kaynaklanmıyor.
Yerelleştirme dışı oldukları için golden ana görüntüleri güncellenmedi.

## Zaman güvenliği

| Ne | Not |
|---|---|
| İleri alınan cihaz saati yakalanamıyor | Yerelde gerçek zamanın geçmesinden ayırt edilemez |
| Doğuya seyahat = saati ileri almak | Kasıtlı hile ile gerçek seyahat ayırt edilemiyor; ikisi de kullanıcı lehine |
| Batıya seyahat gün sınırını taşıyor | O gün 24 saatten uzun sürer; ölçülü avantaj |
| Saat dilimi değişimi test edilemiyor | Dart'ta süreç içi API yok; cihazda elle doğrulanmalı |

## Adım hattı

- Sensör arızası toparlanmasında `stepBurstAllowance` kadar (100 adım = 2 coin)
  sızıntı. Arıza başına bir kez; ölçülü takas.
- iOS `AppDelegate.swift` (pedometer + açılış sesi kanalları) **Windows'ta
  derlenmedi ve test edilmedi.**

## Macera / ekonomi

- **Gün değişiminde macera düşüyor.** Yürüyüş fazı harcanan adımı görünür
  kıldığı için telafi kararı hâlâ verilmedi. Seçenek: düşürmek yerine kısmi
  ödülle sonuçlandırmak.
- **Günde kaç macera yürüyüş bonusu alabilir sınırı yok.** Ekonomi ileride
  sıkılaştırılacaksa ilk bakılacak yer burası.
- `economy_pacing_test.dart` **buff'sız** dünyayı ölçüyor; ölçtüğü 120 coin/gün
  bir **taban**. Buff'lı senaryo ayrı ölçülmedi (tavanlar
  `equipped_buffs_test.dart` ile bağlı).
- 500 günlük tur +%150 savaş bonusu biriktiriyor; çok uzun serilerde düşman
  dengesi ölçülmedi (`combat_balance_test` ölçüt oyuncuyu bonussuz ölçüyor).

## Kod borcu

| # | Ne | Not |
|---|---|---|
| C3 | `tz.setLocalLocation(tz.UTC)` sabit | Gün/saat bazlı bildirim eklenirse **acil hataya dönüşür** |
| C4 | *(Faz 3 ile çözüldü)* Sistem bildirim kopyası serviste sabitlenmişti | Servis artık seçili dilde hazırlanmış `AdventureNotificationCopy` alıyor |
| C5 | `RootShell._rewards` hiç doldurulmuyor | Eski "Ödüllerim" zinciri; yerine `RewardEngine` koleksiyonu geldi |
| C6 | `sideBySideWindowMinutes` kullanılmıyor | Takım savaşına ait ölü sabit |
| C7 | `nextReminderAt` geçmiş bir zamanla dönerse resume'da anında hatırlatma | Tek seferlik, zararsız |
| C9 | `lib/Characters/`, `lib/Enemies/`, `lib/GIF Animations/` | pubspec'te değil, APK'ya girmiyor. **Silme onaya tabi** |
| C10 | `README.md` hâlâ "A new Flutter project." | Şablon artığı |
| C11 | Release imzası hâlâ debug key | Yayına çıkmadan önce |
| C13 | `RewardRarityX.color` model katmanında `Color` döndürüyor | Extension getter, persist edilmiyor — teknik olarak kural ihlali değil |
| A7 | `features/boss/boss_battle_screen.dart` hiçbir yerden çağrılmıyor | `models/boss_quest.dart`, `MockData.dailyDragon()`, `reward_calculator.dart` ile birlikte ölü zincir. **Silinmedi** |
| — | `ios/Podfile` yok | İlk macOS derlemesinde üretilecek; `permission_handler` `PERMISSION_*` makroları kısıtlanmalı, yoksa App Store incelemesinde sorun çıkar |
| — | `_openWheel`, `_openRewards`, `_editCharacter` hâlâ `_push` | Bugün güvenli (kendi durumlarını tutuyorlar). **Canlı state yansıtması gereken yeni bir ekran eklenirse** ya sekmeye alınmalı ya GD27 deseni kullanılmalı |
| — | Ünvan kazanımının kutlama ekranı yok | Tek SnackBar; aynı partide başka duyuru varsa kuyruğa giriyor |
| — | Ünvan ve iki fazlı macera **eğitimde anlatılmıyor** | Eğitim akışı ikisinden önce yazıldı |

---

# §13 — Bu depoda **yapılmayacak** işler

Bunlar projenin ortağının alanı. **Dokunma, planlama, önerme.**

- **Firebase** (Firestore, Auth, Cloud Functions, config dosyaları,
  `firebase_options.dart`, pubspec'e firebase paketi).
- **Çevrimiçi / çok oyunculu takım savaşları.** Taverna sekmesi bugün bir
  önizleme; gerçek işlevi bu iş geldiğinde yazılacak.
- **Sunucu saati.** `GameClock` bunun için hazırlandı (tek giriş noktası) ama
  geçişi yapan taraf o iş olacak.
- **Savaş motorunun sunucuda çalıştırılması.** Motorun determinizm şartı
  (§6.10) tam olarak bunun için var — motorun kendisi hazır, sunucu tarafı
  değil.
