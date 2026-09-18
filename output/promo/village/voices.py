import sys,json,asyncio
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'tools'))
import edge_tts
VOICES={'PINKY':'en-US-AvaMultilingualNeural','MAVILI':'en-US-AndrewMultilingualNeural','KUP KUZU':'en-US-JennyNeural'}
LINES=[
 (3.7,8.1,'PINKY','Ahh. Sunshine, good friends... perfect.'),
 (11.4,14.4,'PINKY','Hmm? Who stole my sunshine?'),
 (15.8,18.9,'PINKY',"Oh. That's... definitely not a cloud."),
 (20,22.3,'MAVILI','Everyone! This way!'),
 (22.5,24.6,'KUP KUZU','Pinky! Help!'),
 (25,28.8,'PINKY',"Okay. Looks like it's up to me."),
 (32.1,34.1,'PINKY','One step at a time.'),
 (39,41.3,'PINKY','You picked the wrong village.'),
 (45.3,46.8,'KUP KUZU','You did it!'),
 (47.1,49.4,'MAVILI','You saved our village!'),
 (49.7,51.9,'ALL','Thank you, Pinky!'),
 (52.3,55.7,'PINKY','Heh. Just getting my steps in.'),
 (57,61.8,'PINKY',"But our adventure? It's just getting started."),
 (62.1,64.8,'PINKY','Come on. Walk with me!'),
 (68,71.2,'PINKY','Rush for Villains!'),
]
async def main():
 (HERE/'audio').mkdir(exist_ok=True)
 for i,(a,b,speaker,words) in enumerate(LINES):
  for who in (['MAVILI','KUP KUZU'] if speaker=='ALL' else [speaker]):
   dest=HERE/'audio'/f'{i:02}_{who.replace(" ","_")}.mp3'
   if dest.exists() and dest.stat().st_size>1000:continue
   await edge_tts.Communicate(words,VOICES[who],rate='-3%',pitch='+0Hz').save(str(dest))
   print(f'Voice {i+1}/{len(LINES)} {who}',flush=True)
 (HERE/'narration.json').write_text(json.dumps(LINES,indent=2),encoding='utf-8')
if __name__=='__main__':asyncio.run(main())
