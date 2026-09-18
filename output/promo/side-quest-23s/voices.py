import asyncio,json,sys,subprocess
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'tools'))
import edge_tts,imageio_ffmpeg
FF=imageio_ffmpeg.get_ffmpeg_exe()
LINES=[
 ('a','PINKY','Apparently, my walk has a boss fight.',0,2),
 ('b','PINKY','What if your steps could defeat monsters?',0,2),
 ('c','PINKY','I gave my daily walk a quest.',0,2),
 ('intro','PINKY','This is Rush for Villains.',2.15,4.4),
 ('walk','PINKY','Pick an adventure. Walk. See how it ends.',6.05,10.6),
 ('block','MAVILI','You went around the block.',15.0,16.65),
 ('legend','PINKY','A legendary block.',17.05,18.5),
 ('cta','PINKY','Join the Android closed beta. Link in bio.',19.1,22.85),
]
async def main():
 (HERE/'audio').mkdir(exist_ok=True)
 report=[]
 for name,who,text,start,end in LINES:
  voice='en-US-AvaMultilingualNeural' if who=='PINKY' else 'en-US-AndrewMultilingualNeural'
  for rate in ([-35,-25,-15,0] if name=='block' else ([15,25,35,45,55] if name in 'abc' else [0,10,20,30])):
   mp3=HERE/'audio'/f'{name}-{rate}.mp3'
   if not mp3.exists():await edge_tts.Communicate(text,voice,rate=f'{rate:+d}%',pitch='+0Hz').save(str(mp3))
   wav=HERE/'audio'/f'{name}.wav'
   subprocess.run([FF,'-y','-v','error','-i',str(mp3),'-af','silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse','-ac','1','-ar','48000',str(wav)],check=True)
   import wave
   with wave.open(str(wav)) as f:duration=f.getnframes()/f.getframerate()
   if duration<=end-start-.025:break
  if duration>end-start:raise RuntimeError(f'{name} exceeds slot: {duration}')
  report.append(dict(name=name,speaker=who,text=text,start=start,end=end,seconds=duration,tts_rate=rate))
  print(name,duration,rate,flush=True)
 (HERE/'audio/timing.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
asyncio.run(main())
