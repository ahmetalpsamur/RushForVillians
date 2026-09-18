"""Three adult, youthful-sounding friends. No child voice or pitch-shifted clone."""
import sys,json,asyncio
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'tools'))
import edge_tts
VOICES={'PINKY':('en-US-AvaMultilingualNeural','+0Hz'),'MAVILI':('en-US-AndrewMultilingualNeural','+0Hz'),'KÜP KUZU':('en-US-JennyNeural','+3Hz')}
LINES=[
 (.6,4.9,'PINKY','Hey, adventurers! We have something REALLY exciting to tell you!'),
 (5.1,6.6,'MAVILI',"We're getting closer!"),
 (6.8,8.5,'KÜP KUZU','Like… REALLY close!'),
 (8.55,9.2,'PINKY','Ha ha!'),
 (9.6,13.5,'PINKY','Rush for Villains is currently in Closed Beta on Android!'),
 (13.8,17.4,'MAVILI','And right now, we need more adventurers to join us!'),
 (17.7,19.5,'KÜP KUZU','Yep! That means YOU!'),
 (19.8,27.6,'PINKY','With enough support and testers, we can complete this stage and get closer to bringing Rush for Villains to everyone!'),
 (27.9,28.9,'MAVILI','Android…'),
 (29.1,30.25,'KÜP KUZU','…AND iOS!'),
 (31.1,32.6,'PINKY','Want to help us?'),
 (32.8,35.6,'MAVILI','Check the links in our Instagram bio…'),
 (35.85,38.8,'KÜP KUZU','…and join our Android Closed Beta!'),
 (41.3,44.7,'PINKY','Every person who joins means so much to us.'),
 (45,47.4,'MAVILI',"You're not just testing a game…"),
 (47.7,49.8,'KÜP KUZU',"You're helping us build it!"),
 (50.2,55,'PINKY','So help us bring Rush for Villains to both Android and iOS!'),
 (59.2,60.8,'PINKY','Join the Closed Beta!'),
 (61,62.3,'MAVILI','Help us grow!'),
 (62.55,64.4,'KÜP KUZU','And join the adventure!'),
 (65,68.1,'ALL','SEE YOU IN RUSH FOR VILLAINS!'),
]
async def main():
 (HERE/'audio').mkdir(parents=True,exist_ok=True)
 for i,(a,b,speaker,text) in enumerate(LINES):
  members=list(VOICES) if speaker=='ALL' else [speaker]
  for who in members:
   suffix='_'+who.lower().replace(' ','_') if speaker=='ALL' else ''
   dest=HERE/'audio'/f'voice_{i:02}{suffix}.mp3';meta=dest.with_suffix('.json')
   voice,pitch=VOICES[who]
   spoken=text.replace('REALLY','really').replace('YOU','you').replace('…','...')
   if speaker=='ALL':spoken='See you in Rush for Villains!'
   config={'text':spoken,'voice':voice,'pitch':pitch,'rate':'+0%'}
   if dest.exists() and meta.exists() and json.loads(meta.read_text())==config:continue
   await edge_tts.Communicate(**config).save(str(dest))
   meta.write_text(json.dumps(config),encoding='utf-8')
   print(f'{i+1}/{len(LINES)} {who} ready',flush=True)
 (HERE/'narration.json').write_text(json.dumps(LINES,ensure_ascii=False,indent=2),encoding='utf-8')
if __name__=='__main__':asyncio.run(main())
