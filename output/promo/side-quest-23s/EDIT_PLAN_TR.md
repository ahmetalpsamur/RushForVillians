# Rush for Villains — 23 saniyelik Reels kurgu paketi

Durum: Bu dosya ilk kurgu planıdır. Kullanıcının devam talebi üzerine uygulama çalıştırılıp ekranı kaydedildi ve A/B/C videoları üretildi. Güncel teslim, gerçek kayıt kaynağı, demo adım açıklaması ve son kurgu için `README_FINAL_TR.md` dosyasına bakın. Aşağıdaki eksik kayıt listesi ilk incelemeyi belgeler; güncel teslim durumu değildir.

## Kaynak kontrolü

- Pinky: `lib/Tutorial_Guy/Pinky/Pink_Monster_Idle_4.gif`, `Pink_Monster_Walk_6.gif`, `Pink_Monster_Jump_8.gif`.
- Mavili: `lib/Tutorial_Guy/Mavili/Dude_Monster_Idle_4.gif`.
- Düşman: projedeki özgün düşman sprite'larından seçilecek; son tasarım referansla karşılaştırılacak. Konuşmayacak.
- `output/promo/story/README.md`: önceki videonun adım ve savaş sahneleri tanıtım animasyonu; uygulama görselleri örnek durumlarla oluşturulmuş Flutter ekranları.
- `output/promo/community/README.md`: oyun kesitleri sahnelenmiş animasyon, ham oynanış kaydı değil.
- Test golden'ları ve önceki tanıtımlar, kullanıcının istediği gerçek ekran kaydının yerine geçmez.

## Zaman çizelgesi

| Süre | Görüntü ve kurgu | Konuşma / metin / ses |
|---|---|---|
| 0.00–2.00 | Açıkça kurgusal piksel park sahnesi. İlk karede Pinky yürüyüş hareketindedir; hemen durup kameraya yönelir. Küçük özgün düşman kadraja girer, beklentiyle bekler. Kamera uygulaması, gerçek görüntü üzerine canavar bindirmesi, AR işareti veya savaş arayüzü yok. | Pinky: “Apparently, my walk has a boss fight.” İlk kareden itibaren “Your walk. A side quest.” Hafif ayak sesi, küçük komik giriş efekti. |
| 2.00–4.00 | Gerçek uygulama kaydı: macera listesi ve seçilen macera. Kesme ile doğrudan büyük uygulama görüntüsü. | Pinky 2.25–4.15: “This is Rush for Villains.” Üstte temiz tipografiyle uygulama adı. |
| 4.00–6.00 | Aynı kaydın devamı: seçili macera ve gerçek adım hedefi en az 2 saniye okunur. Sayı değiştirilmeyecek. | “Choose your adventure” editoryal başlığı. Hedefi kapatmayan altyazı. |
| 6.00–7.25 | Pinky kurgusal park yolunda yürür, çevresine bakar. Elinde telefon yok. | Pinky 6.10–9.40: “Pick an adventure. Walk. See how it ends.” |
| 7.25–8.50 | Gerçek adım ilerleme kaydının erken anı. Sayılar kayıttan gelir. | “During the walk” metni. |
| 8.50–9.75 | Aynı yürüyüşün daha sonraki gerçek ilerleme anına kesme. Süre geçtiği açıkça belirtilir. Sayaç yapay olarak hızlandırılmaz. | “Later in the walk” metni. Gerçek zaman damgaları varsa ayrıca kullanılabilir; süre uydurulmaz. |
| 9.75–11.00 | Pinky farklı bir park noktasına ulaşır ve durur. Telefon gösterilecekse ancak tam durduktan sonra bakar. | Konuşma yok. Müzik devam eder. |
| 11.00–14.25 | Aynı tamamlanmış yürüyüşün gerçek savaş sonucu. Ödül varsa kayıttaki sırayla ve gerçek değeriyle gösterilir. Dört saniyeye sığmıyorsa sonuç okunurluğu korunur, isteğe bağlı ödül bölümü çıkarılır. | Konuşma yok. Gerçek sonuç belirince kısa özgün oyun efekti. Zafer doğrulanmadıkça “Victory”, altın veya ekipman eklenmez. |
| 14.25–15.00 | Sonuç ekranı büyük kalır. Pinky boş bir köşede küçük tepki katmanı olarak gururlu bir poza geçer; sonuç/ödül alanını örtmez. | Abartılı gurur görsel oyunculukla verilir; ek replik yok. |
| 15.00–16.55 | Kurgusal parkta ikili plan. Mavili Pinky'ye döner; Pinky ciddi durur. | Mavili: “You went around the block.” Sakin, kuru mizah. |
| 16.55–16.95 | Aynı plan, göz teması. | 0.40 saniye komedi duraklaması. Müzik hafifçe azalır. |
| 16.95–18.20 | Pinky çok küçük bir gurur hareketi yapar. | Pinky: “A legendary block.” Son sözcükte hafif vurgu; gülmez. |
| 18.20–19.00 | Mavili'nin ifadesi değişmez; Pinky ciddi kalır. | Sessiz tepki payı. |
| 19.00–23.00 | Final kompozisyonu ilk kareden tam görünür. Başlık üstte; gerçek uygulamanın okunabilir seçili macera görüntüsü merkezde; Pinky yanında küçük bir alanda. Telefon maketi kullanılmaz. Alt bölümde iki satır CTA; uygulama görüntüsüyle çakışmaz. | Pinky 19.10–22.65: “Join the Android closed beta. Link in bio.” Metin: “Rush for Villains” / “Android closed beta” / “Join through the link in bio”. Bütün metinler 4 saniye sabit. |

Gerçek uygulama görüntüsü için ayrılan süre: 2–6 = 4 sn; 7.25–9.75 = 2.5 sn; 11–15 = 4 sn; 19–23 = 4 sn. Toplam **14.5 saniye**. Bu, planlanan süredir; kayıtlar henüz mevcut değildir.

## B ve C: yalnızca 0–2 saniye değişir

- B: Pinky yürüyüşe başlar, küçük düşmanı fark edip kameraya merakla bakar. “What if your steps could defeat monsters?” Ekran: “Your steps. A side quest.” Canavarın adımlarla eşzamanlı hasar aldığı gösterilmez.
- C: Pinky kameraya bilmiş bir bakış atar, yürüyüşe yönelir. “I gave my daily walk a quest.” Ekran: “Daily walk → Side quest”. Görev arayüzü icat edilmez.
- Her açılış 60 kare / 2.000 saniyedir. 2.000 saniyeden sonraki görüntü, ses ve altyazı tek bir ortak master'dan gelir. Açılışa özel yankı, geçiş veya ses kuyruğu ortak bölüme taşmaz.
- Açılış replikleri sıkıdır: 2 saniyelik ayrı oyuncu okumalarıyla denenmeli. Neşeli, kısa bir giriş gibi okunmalı; kelime yutma ve dijital hızlandırma kullanılmamalı. Doğallık sağlanamıyorsa seslendirme bu zamanlama şartını karşılamış sayılmaz; metin/süre değişikliği ayrıca kararlaştırılmalıdır. Buradaki zamanlar ses kaydıyla doğrulanmış değildir.

## Görsel ve ses kuralları

- 1080 × 1920, 9:16, 30 fps, tam 690 kare. H.264 MP4, AAC 48 kHz; alternatif açılışlar tam 60 kare.
- Kritik metinler için muhafazakâr çalışma alanı: x=90–880, y=240–1480. Bu bir kurgu payıdır; Reels arayüzünde yayın öncesi önizlemeyle doğrulanmalıdır.
- Altyazı en fazla iki satır, yaklaşık 48–56 px, yüksek kontrastlı sade sans serif, koyu arkalık. Başlık yaklaşık 64–76 px. Piksel fontu uzun metinde kullanılmaz.
- Metin, uygulama adı ve altyazı yalnızca kurgu aşamasında eklenir. UI'ye üretken görsel müdahale uygulanmaz. Yakınlaşma sırasında macera adı, hedef, ilerleme ve sonuç bağlamı korunur.
- Piksel sprite'ları nearest-neighbor ile ölçekle; renk, oran ve silueti koru. Yeni yüz, el, kıyafet veya yapay ağız animasyonu ekleme. Oyunculuk mevcut pozlar, yön değiştirme ve küçük beklemelerle sağlanır.
- Pinky: yetişkin kadın, doğal İngilizce, neşeli ve kendinden emin, hafif alaycı. Mavili: yetişkin erkek, sakin, kuru. Başka konuşan karakter yok.
- Hafif özgün oyun müziği; konuşma sırasında belirgin biçimde kısılır. Adım, kısa giriş ve sonuç efekti özgün sentez veya kullanım hakkı doğrulanmış kayıttan gelir. Eski seslerin izinleri varsayılmaz. Yaklaşık −14 LUFS-I ve en fazla −1 dBTP kurgu hedefi; son miks kulakla da kontrol edilir.
- Ses kapalı kontrolde açılış fikri, macera/hedef, geçen zaman, gerçek sonuç ve Android beta çağrısı anlaşılmalıdır.

## Eksik gerçek kayıtlar

1. Android uygulamasında macera listesi → macera seçimi → gerçek adım hedefini gösteren kesintisiz kayıt.
2. Aynı maceranın, gerçek yürüyüşün farklı anlarındaki erken ve sonraki adım ilerlemesi. Kronolojiyi doğrulayacak kaynak zamanları gerekli; zaman değeri ekranda uydurulmayacak.
3. Aynı yürüyüşün tamamlanması → savaş sonucu → varsa ödül akışının kesintisiz kaydı. Sıra ve sonuç değiştirilmeyecek.
4. Final için okunabilir seçili macera kaydı veya yukarıdaki gerçek kayıttan alınacak sabit kare; ayrıca yeni bir kayıt zorunlu değil.

Kaynaklar gelene kadar montajdaki ilgili alanlarda açıkça şu editoryal kartlar kullanılmalı: “PLACEHOLDER — actual adventure selection recording required”, “PLACEHOLDER — actual walking progress recording required”, “PLACEHOLDER — actual battle result recording required”. Böyle bir montaj yayınlanabilir nihai video değildir. Golden ekranı veya sahnelenmiş savaş ile boşluk kapatılmaz.

## Instagram açıklaması

Your daily walk becomes a side quest. A legendary block still counts. ⚔️ Rush for Villains is in Android closed beta. Join through the link in bio.
