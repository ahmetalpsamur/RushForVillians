import sys,json,asyncio
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'tools'))
import edge_tts
VOICES={'PINKY':('en-US-JennyNeural','+0Hz'),'MAVILI':('en-US-GuyNeural','+0Hz')}
LINES=[
(.5,2.3,'PINKY','Okay… walking is great.'),
(3,4.5,'PINKY','But walking with THIS?'),
(5,6.3,'PINKY','Obviously better.'),
(8.9,9.65,'MAVILI','Cute.'),
(10.3,11.1,'PINKY','…Cute?'),
(11.8,13.4,'MAVILI','Mine has better stats.'),
(14.3,17.4,'MAVILI','Find equipment. Upgrade it. Get stronger.'),
(17.9,18.55,'PINKY','Wow.'),
(19.1,20.65,'PINKY','You discovered upgrading.'),
(21,22.35,'MAVILI','I was explaining it.'),
(22.5,24.7,'PINKY','You were explaining it very slowly.'),
(26,28.65,'PINKY',"And when being powerful isn't enough…"),
(29,32.1,'PINKY',"…you make sure everyone KNOWS you're powerful."),
(32.5,33.6,'MAVILI','Very humble.'),
(33.8,34.65,'PINKY','Thank you.'),
(35.2,36.85,'MAVILI',"That wasn't a compliment."),
(37.1,38,'PINKY','I know.'),
(39.5,42.15,'PINKY','And THIS is my reward showcase.'),
(43.2,44.5,'MAVILI','So basically…'),
(45.4,47.5,'MAVILI','…a museum about yourself?'),
(48.3,49.1,'PINKY','Exactly.'),
(49.7,51.6,'PINKY','And admission is free.'),
(53.2,55.65,'PINKY','Walk. Fight. Earn better equipment.'),
(55.8,56.75,'MAVILI','Upgrade it.'),
(57,58.1,'PINKY','Unlock titles.'),
(58.2,59.35,'MAVILI','Collect rewards.'),
(59.6,60.9,'ALL','GET STRONGER.'),
(62.4,64.55,'PINKY',"Although… I'm obviously stronger."),
(64.7,65.65,'MAVILI',"No, you're not."),
(65.75,66.6,'PINKY','Yes, I am.'),
(66.7,68.05,'MAVILI',"No. I'M stronger."),
(68.15,69.1,'PINKY','Based on what?'),
(69.2,70.2,'MAVILI','Look at me.'),
(71.2,72.25,'PINKY',"…I'm looking."),
(72.3,72.9,'MAVILI','And?'),
(73,74.05,'PINKY','Still stronger.'),
(74.1,75.4,'MAVILI',"No, I'M stronger!"),
(75.5,76.05,'PINKY','ME!'),
(76.1,76.65,'MAVILI','ME!'),
(76.7,77.1,'PINKY','Me!'),
(77.15,77.55,'MAVILI','Me!'),
(77.6,78.1,'PINKY','ME!'),
(78.15,78.65,'MAVILI','ME!'),
(78.9,80.55,'PINKY',"I'm literally stronger!"),
(80.7,82,'MAVILI','According to WHO?!'),
(82.1,82.7,'PINKY','ME!'),
(83.3,85.9,'MAVILI',"We're checking the stats after this!"),
(86.1,88.8,'PINKY','Sure. Prepare to be disappointed.'),
]
# Spoken interjections replace ellipses. These are voiced, never stage directions
# sent literally to the synthesizer. Dialogue remains in idiomatic English.
ACTING={
 0:'Ah, okay! Walking is great.',
 4:'Hmm. Cute?',
 11:"And when being powerful isn't enough, hmm?",
 12:"Well, you make sure everyone knows you're powerful.",
 18:'Hmm. So, basically,',
 19:'Oh! A museum about yourself?',
 20:'Exactly!',
 27:"Heh! Although, I'm obviously stronger.",
 33:"Hmm. I'm looking.",
 44:'According to who?',
 47:'Ha! Sure. Prepare to be disappointed.',
}
LINES=[(a,b,who,ACTING.get(i,s)) for i,(a,b,who,s) in enumerate(LINES)]
async def main():
 (HERE/'audio').mkdir(parents=True,exist_ok=True)
 for i,(a,b,speaker,text) in enumerate(LINES):
  for who in (list(VOICES) if speaker=='ALL' else [speaker]):
   suffix='_'+who.lower() if speaker=='ALL' else ''
   dest=HERE/'audio'/f'voice_{i:02}{suffix}.mp3';meta=dest.with_suffix('.json')
   voice,pitch=VOICES[who]
   spoken=text.replace('…','...').replace('THIS','this').replace('KNOWS','knows').replace("I'M","I'm").replace('WHO','who').replace('GET STRONGER','Get stronger').replace('ME!','Me!')
   # English-specific voices, unshifted adult pitch and a clearer speaking pace.
   rate='-8%' if who=='PINKY' else '-7%'
   if i in (8,10,13,15,18,19,33,47):rate='-12%'
   if 37<=i<=42:rate=['+0%','+0%','+4%','+4%','+7%','+7%'][i-37]
   config={'text':spoken,'voice':voice,'pitch':pitch,'rate':rate}
   if dest.exists() and meta.exists() and json.loads(meta.read_text())==config:continue
   for retry in range(3):
    try:
     await edge_tts.Communicate(**config).save(str(dest));break
    except Exception:
     if retry==2:raise
   meta.write_text(json.dumps(config),encoding='utf-8')
   print(f'{i+1}/{len(LINES)} {who} ready',flush=True)
 (HERE/'narration.json').write_text(json.dumps(LINES,ensure_ascii=False,indent=2),encoding='utf-8')
 (HERE/'dialogue.en.txt').write_text('\n\n'.join(f'{who}: {text}' for _,_,who,text in LINES)+'\n',encoding='utf-8')
if __name__=='__main__':asyncio.run(main())
