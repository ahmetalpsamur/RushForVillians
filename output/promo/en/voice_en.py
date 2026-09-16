"""English adaptation: short, inviting phrases preserve clear articulation at 38s."""
import asyncio, json, sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'tools'))
import edge_tts

VOICE='en-US-AvaMultilingualNeural'
RATES=['-12%','-10%','-8%','+3%','-10%','-10%','+3%','+3%','-10%','-12%','-15%','-10%']
LINES=[
    (0.15,1.75,'Walks feeling a little dull?'),
    (1.80,3.95,'What if you battled monsters?'),
    (4.10,7.90,'In Rush for Villains, every step is an adventure!'),
    (8.15,9.70,'First, choose your class.'),
    (10.00,12.85,'Find your style. Start your adventure!'),
    (13.40,15.50,'Hit your step goal...'),
    (17.00,18.10,'And attack!'),
    (20.05,23.45,'Watch out! Tougher enemies await as you advance.'),
    (23.50,24.95,'Ready for a challenge?'),
    (25.15,30.65,'Defeat your enemies, claim your rewards, and power up your hero!'),
    (31.05,35.50,'So... your next walk could be the start of something epic.'),
    (35.70,37.70,"Let's start your adventure!"),
]

async def main():
    (HERE/'audio').mkdir(exist_ok=True)
    for i,(_,_,text) in enumerate(LINES):
        dest=HERE/'audio'/f'voice_{i:02}.mp3'
        settings={'voice':VOICE,'rate':RATES[i],'pitch':'+3Hz','text':text}
        cache=dest.with_suffix('.json')
        if dest.exists() and cache.exists() and json.loads(cache.read_text())==settings:continue
        await edge_tts.Communicate(text,VOICE,rate=RATES[i],pitch='+3Hz').save(str(dest))
        cache.write_text(json.dumps(settings),encoding='utf-8')
        print(f'English voice {i+1}/{len(LINES)} ready',flush=True)
    (HERE/'narration.json').write_text(json.dumps(LINES,ensure_ascii=False,indent=2),encoding='utf-8')

if __name__=='__main__':asyncio.run(main())
