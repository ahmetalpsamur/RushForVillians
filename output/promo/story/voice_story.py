import asyncio,json,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'tools'))
import edge_tts
VOICE='en-US-AvaMultilingualNeural'
LINES=[
 (.35,2.9,'Okayyy! Time for my little walk!'),
 (3.15,6.15,'Wait… walking is way more fun with this!'),
 (6.65,9.6,"Rush for Villains… let's gooo!"),
 (10.2,13.55,'Every step gets me closer to my next battle!'),
 (14.05,15.65,'Come on… come on…'),
 (16.8,17.5,'YESSS!'),
 (18.0,19.55,'Ohhh… you wanna fight?'),
 (19.8,20.55,'Bad choice!'),
 (24.0,27.55,"HAHA! That's what my walk gets me!"),
 (29.1,32.15,'Ohhh… this walk just got interesting.'),
 (35.25,37.85,'Your next walk could be an adventure too!'),
 (37.95,39.95,"Come on! Let's go!"),
]
# Normalize elongated spelling for pronunciation, retaining the supplied captions.
SPOKEN=['Okay! Time for my little walk!',LINES[1][2],"Rush for Villains... let's go!",LINES[3][2],
        'Come on... come on...', 'Yes!', 'Oh... you wanna fight?', 'Bad choice!',
        "Ha ha! That's what my walk gets me!", 'Oh... this walk just got interesting.',LINES[10][2],LINES[11][2]]
RATES=['+0%','+0%','-5%','+0%','-3%','+0%','+0%','+0%','-5%','-5%','+0%','+0%']
async def main():
 (HERE/'audio').mkdir(parents=True,exist_ok=True)
 for i,(_,_,text) in enumerate(LINES):
  config={'voice':VOICE,'text':SPOKEN[i],'rate':RATES[i],'pitch':'+0Hz'}
  dest=HERE/'audio'/f'voice_{i:02}.mp3';meta=dest.with_suffix('.json')
  if dest.exists() and meta.exists() and json.loads(meta.read_text())==config:continue
  await edge_tts.Communicate(config['text'],VOICE,rate=config['rate'],pitch=config['pitch']).save(str(dest))
  meta.write_text(json.dumps(config),encoding='utf-8')
  print(f'Pinky voice {i+1}/12 ready',flush=True)
 (HERE/'narration.json').write_text(json.dumps(LINES,ensure_ascii=False,indent=2),encoding='utf-8')
if __name__=='__main__':asyncio.run(main())
