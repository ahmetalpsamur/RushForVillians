import sys, asyncio, json
from pathlib import Path
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / 'tools'))
import edge_tts

# Exact supplied copy. Timing is shared by the renderer and subtitle export.
LINES = [
 (0.15, 1.75, 'Yürüyüş yapmak biraz sıkıcı mı geliyor?'),
 (1.80, 3.95, 'Peki yürürken canavarlarla savaşsaydın?'),
 (4.10, 7.90, "Rush for Villains'ta attığın her adım, maceranın bir parçası!"),
 (8.15, 9.70, "Önce class'ını seç."),
 (10.00, 12.85, 'Tarzını belirle ve macerana başla!'),
 (13.40, 15.50, 'Adımlarını tamamla…'),
 (17.00, 18.10, '…ve saldır!'),
 (20.05, 23.45, 'Ama dikkat et! Macera ilerledikçe karşına daha güçlü düşmanlar çıkacak.'),
 (23.50, 24.95, 'Kimse kolay olacağını söylemedi!'),
 (25.15, 30.65, 'Düşmanları yen, ödüller kazan ve karakterini güçlendir!'),
 (31.05, 35.50, 'Yani… bir sonraki yürüyüşün sadece bir yürüyüş olmak zorunda değil.'),
 (35.70, 37.70, 'Hazırsan, macera başlasın!'),
]

async def main():
    (HERE/'audio').mkdir(exist_ok=True)
    for i, (_, _, text) in enumerate(LINES):
        dest = HERE/'audio'/f'voice_{i:02}.mp3'
        if dest.exists() and dest.stat().st_size > 1000:
            continue
        await edge_tts.Communicate(text, 'tr-TR-EmelNeural', rate='+15%', pitch='+8Hz').save(str(dest))
        print(f'Voice {i+1}/{len(LINES)} ready', flush=True)
    (HERE/'narration.json').write_text(json.dumps(LINES, ensure_ascii=False, indent=2), encoding='utf-8')

if __name__ == '__main__':
    asyncio.run(main())
