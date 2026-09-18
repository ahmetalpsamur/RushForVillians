"""23s Reels: unmodified app recording + original character sprites.
No product code or gameplay values are changed by this renderer.
"""
import sys,math,json,subprocess,wave,functools,io,hashlib
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE/'tools'))
import numpy as np
sys.path.insert(0,str(HERE.parent))
import render as r
Image,ImageDraw,ImageFont=r.Image,r.ImageDraw,r.ImageFont
FF=r.FFMPEG
W,H,FPS=1080,1920,30
INK='#151120';WHITE='#FFF8EF';PINK='#F3A0DF';GOLD='#FFE69A';MINT='#ACEDD6'
SRC=HERE/'raw/page@b634b8f3e003245e5cbe5e5302c52441.webm'
PINKY=r.PINKY
BLUE=r.ROOT/'lib/Tutorial_Guy/Mavili/Dude_Monster_Idle_4.gif'
ENEMY=r.path_for('Black Knight',enemy=True)
TIMING=json.loads((HERE/'audio/timing.json').read_text())

@functools.lru_cache(None)
def font(n,bold=True):return ImageFont.truetype('C:/Windows/Fonts/'+('seguisb.ttf' if bold else 'segoeui.ttf'),n)
def txt(im,s,x,y,n=48,color=WHITE,anchor='mm'):
 ImageDraw.Draw(im).text((x,y),s,font=font(n),fill=color,anchor=anchor)
def fit(im,s,x,y,n=64,width=790,color=WHITE):
 while ImageDraw.Draw(im).textlength(s,font=font(n))>width:n-=1
 txt(im,s,x,y,n,color)
def panel(im,box,color=INK,radius=24):ImageDraw.Draw(im).rounded_rectangle(box,radius,fill=color)
def caption(im,lines,who='PINKY',y=1300):
 panel(im,(90,y,880,y+76+len(lines)*58))
 txt(im,who,120,y+28,25,PINK if who=='PINKY' else MINT,'lm')
 for j,line in enumerate(lines):fit(im,line,485,y+80+j*58,48,740)

def park(t,moving=False):
 im=Image.new('RGB',(270,480),'#BCE4DB');d=ImageDraw.Draw(im)
 d.rectangle((0,0,270,140),fill='#DCEBCF')
 d.rectangle((0,140,270,250),fill='#C8E5D5')
 d.rectangle((0,250,270,330),fill='#A5D4BD')
 d.rectangle((0,330,270,480),fill='#568B7E')
 d.rectangle((208,60,237,88),fill='#FFF0B4')
 for x,y in [(14,112),(120,155),(218,138)]:
  d.rectangle((x,y,x+30,y+7),fill='#EFF3DD');d.rectangle((x+7,y-6,x+22,y+8),fill='#EFF3DD')
 travel=t*15 if moving else 0
 for i in range(6):
  x=round((i*64-travel*.3)%360-35);y=250+(i%2)*18
  d.rectangle((x,y-30,x+8,y+88),fill='#69785B')
  d.rectangle((x-16,y-44,x+24,y+5),fill='#74B199')
  d.rectangle((x-23,y-31,x+31,y-1),fill='#74B199')
  d.rectangle((x-12,y-48,x+11,y-28),fill='#90C4A5')
 d.polygon([(0,282),(270,282),(270,379),(0,409)],fill='#D5BE9B')
 d.rectangle((0,280,270,285),fill='#EBDBC1')
 for i in range(20):
  x=round((i*39-travel)%285-9);y=300+(i*17)%70
  d.rectangle((x,y,x+3,y+1),fill='#BAA789')
 d.rectangle((0,412,270,480),fill='#304D48')
 return im.resize((W,H),Image.Resampling.NEAREST)

def base():
 im=Image.new('RGB',(W,H),INK);d=ImageDraw.Draw(im)
 for i in range(15):
  x=(i*151+32)%W;y=(i*173+42)%H
  d.rectangle((x,y,x+4,y+4),fill='#40334D')
 return im

def p(state='Idle'):return r.pink_path(state)
def actor(im,path,t,x,ground,height,flip=False):r.sprite(im,path,t,x,ground,height,flip)

CLIPS={}
def load_clips():
 # Playwright pads recordings larger than the CSS viewport; remove that padding.
 for name,start,duration in [('selection',214,2),('details',260,2),('progress',302,2.5),('strike',334,0.8),('result',350,3.2),('final',380,4)]:
  folder=HERE/'frames'/name;folder.mkdir(parents=True,exist_ok=True)
  if len(list(folder.glob('*.png')))!=round(duration*FPS):
   subprocess.run([FF,'-y','-v','error','-ss',str(start),'-i',str(SRC),'-t',str(duration),'-vf','crop=432:768:0:0,fps=30','-frames:v',str(round(duration*FPS)),str(folder/'%04d.png')],check=True)
  CLIPS[name]=[Image.open(f).convert('RGB') for f in sorted(folder.glob('*.png'))]
 (HERE/'source-cuts.json').write_text(json.dumps({'source':str(SRC.name),'crop':[0,0,432,768],'selection':[214,216],'details':[260,262],'progress':[302,304.5],'strike':[334,334.8],'result':[350,353.2],'final':[380,384],'input':'Actual local web application; built-in demo steps, not physical walking'},indent=2),encoding='utf-8')

def clip(name,t):return CLIPS[name][min(len(CLIPS[name])-1,max(0,int(t*FPS)))].copy()
def paste_app(im,name,t,crop,box):
 fr=clip(name,t).crop(crop);x,y,w,h=box
 im.paste(fr.resize((w,h),Image.Resampling.LANCZOS),(x,y))
def source_label(im,y=1490):txt(im,'IN-APP FOOTAGE · DEMO STEPS',485,y,27,'#C8BED3')

def opening(t,variant):
 im=park(t,True)
 txt(im,'RUSH FOR VILLAINS',485,244,29,'#35554A')
 hooks={'a':('Your walk.','A side quest.'),'b':('Your steps.','A side quest.'),'c':('Daily walk.','Quest accepted.')}
 h1,h2=hooks[variant];fit(im,h1,485,340,89,color=INK);fit(im,h2,485,445,86,color='#664287')
 state='Walk' if t<.45 else 'Idle'
 x=310+min(t,.45)*130
 actor(im,p('Walk' if variant=='c' else state),t,380+80*t if variant=='c' else x,1184,426,flip=.55<t<.90)
 if variant!='c':
  actor(im,ENEMY,t,746+max(0,.42-t)*260,1184,210,True)
  if t>.55:txt(im,'...',730,899,67,INK)
 lines={'a':['Apparently, my walk','has a boss fight.'],'b':['What if your steps','could defeat monsters?'],'c':['I gave my daily walk a quest.']}
 caption(im,lines[variant],y=1290)
 return im

def frame(t,variant='a'):
 if t<2:return opening(t,variant)
 if t<6:
  im=base();txt(im,'YOUR DAILY WALK BECOMES A SIDE QUEST',485,235,26,MINT)
  if t<4:
   fit(im,'This is Rush for Villains.',485,319,60)
   paste_app(im,'selection',t-2,(12,65,420,600),(90,410,790,1036))
  else:
   fit(im,'Pick your adventure.',485,319,63)
   paste_app(im,'details',t-4,(12,0,420,530),(90,410,790,1026))
  source_label(im)
 elif t<7.25:
  im=park(t,True);fit(im,'Pick an adventure.',485,325,75,color=INK)
  actor(im,p('Walk'),t,380+(t-6)*90,1190,400)
  txt(im,'A little fresh air. A little XP.',485,1410,42,WHITE)
 elif t<9.75:
  im=base();fit(im,'Walk. See how it ends.',485,290,60)
  txt(im,'DURING THE WALK',485,368,29,MINT)
  paste_app(im,'progress',t-7.25,(12,155,420,692),(90,425,790,1040))
  source_label(im,1510)
 elif t<11:
  im=park(t+12,True);fit(im,'Later in the walk...',485,325,66,color=INK)
  actor(im,p('Walk' if t<10.55 else 'Idle'),t,400+min(.8,t-9.75)*90,1190,400)
  txt(im,'Time passes. The quest continues.',485,1410,37,WHITE)
 elif t<15:
  im=base();fit(im,'Battle won. Walk continues.',485,290,56)
  if t<11.8:
   paste_app(im,'strike',t-11,(12,45,420,645),(90,380,790,1162))
  else:
   paste_app(im,'result',t-11.8,(12,55,420,650),(90,380,790,1152))
  source_label(im,1580)
  if t>=14.25:actor(im,p('Jump' if t<14.65 else 'Idle'),t-14.25,825,1405,175)
 elif t<19:
  im=park(0);fit(im,'A very normal walk.',485,320,69,color=INK)
  actor(im,BLUE,t,307,1190,365)
  actor(im,p('Idle'),t,690,1190-(12 if 17.05<t<17.30 else 0),385,True)
  if t<16.65:caption(im,['You went around the block.'],'MAVILI',1300)
  elif t>=17.05:caption(im,['A legendary block.'],'PINKY',1300)
 else:
  im=base();fit(im,'Rush for Villains',485,290,80)
  fit(im,'Your daily walk becomes a side quest.',485,387,40,color=PINK)
  paste_app(im,'final',t-19,(16,18,416,380),(90,500,650,588))
  actor(im,p('Idle'),t,791,1170,225,True)
  source_label(im,1190)
  panel(im,(90,1260,880,1470),'#352644')
  fit(im,'Android closed beta',485,1325,56,color=GOLD)
  fit(im,'Join through the link in bio',485,1410,43)
 return im

def audio(variant):
 sr=48000;n=sr*23;out=np.zeros((n,2),np.float32);rng=np.random.default_rng(41)
 def add(at,sig,gain=1):
  i=round(at*sr);end=min(n,i+len(sig));out[i:end]+=sig[:end-i,None]*gain
 def bell(at,f,gain=.035):
  ts=np.arange(round(sr*.30))/sr
  add(at,(np.sin(math.tau*f*ts)+.2*np.sin(math.tau*f*2*ts))*np.exp(-ts*14)*np.minimum(1,ts*140),gain)
 for j in range(46):
  at=j*.5;root=[130.81,164.81,146.83,110][j//8%4]
  bell(at,root*4*[1,1.25,1.5,1.25][j%4],.024)
  ts=np.arange(round(sr*.4))/sr;add(at,np.sin(math.tau*root*ts)*np.exp(-ts*8)*np.minimum(1,ts*60),.025)
 for a,b in [(0,.5),(6,7.25),(9.75,10.6)]:
  for at in np.arange(a,b,.35):
   ts=np.arange(2400)/sr;add(at,rng.uniform(-1,1,len(ts))*np.exp(-ts*80),.025)
 bell(.4,370,.065)
 for j,f in enumerate([659.25,830.61,987.77]):bell(11.85+j*.09,f,.07)
 active=[x for x in TIMING if x['name'] not in ['a','b','c'] or x['name']==variant]
 for line in active:
  with wave.open(str(HERE/'audio'/f"{line['name']}.wav")) as f:sig=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(np.float32)/32768
  sig*=.70/max(.1,float(np.max(np.abs(sig))))
  start=round(line['start']*sr);end=min(n,start+len(sig));out[start:end]*=.25
  add(line['start'],sig)
 out[round(16.60*sr):round(17.05*sr)]*=.18
 out[-4800:]*=np.linspace(1,0,4800)[:,None]
 out*=.89/max(.89,float(np.max(np.abs(out))))
 path=HERE/'audio'/f'mix-{variant}.wav'
 with wave.open(str(path),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr);f.writeframes((out*32767).astype('<i2').tobytes())
 return path

def render_segment(name,variant,start,duration,mix):
 path=HERE/name
 proc=subprocess.Popen([FF,'-y','-v','error','-f','rawvideo','-pix_fmt','rgb24','-s','1080x1920','-r','30','-i','-',
  '-ss',str(start),'-i',str(mix),'-map','0:v','-map','1:a','-c:v','libx264','-preset','fast','-crf','18','-pix_fmt','yuv420p',
  '-c:a','aac','-b:a','192k','-ar','48000','-t',str(duration),'-movflags','+faststart',str(path)],stdin=subprocess.PIPE)
 for i in range(round(duration*FPS)):
  proc.stdin.write(frame(start+i/FPS,variant).tobytes())
  if i%90==0:print(name,i//FPS,'/',duration,flush=True)
 proc.stdin.close();assert proc.wait()==0
 return path

def main():
 global ENEMY
 if not ENEMY.exists():ENEMY=r.path_for('Black Knight_A',enemy=True)
 load_clips()
 moments=[0,.8,2.5,4.7,6.5,8.3,10.3,11.3,12.8,14.5,15.6,17.7,19.1,22.9]
 sheet=Image.new('RGB',(1400,760),INK)
 for i,t in enumerate(moments):
  fr=frame(t).resize((200,356),Image.Resampling.LANCZOS);x=i%7*200;y=i//7*380;sheet.paste(fr,(x,y));txt(sheet,f'{t:.1f}s',x+100,y+368,17)
 sheet.save(HERE/'storyboard.jpg',quality=95);frame(22).save(HERE/'poster.png')
 if '--preview' in sys.argv:return
 mixes={v:audio(v) for v in 'abc'}
 render_segment('common-02-23.mp4','a',2,21,mixes['a'])
 for v in 'abc':
  render_segment(f'opening-{v.upper()}-2s.mp4',v,0,2,mixes[v])
  # Render all finals from identical common frames/audio, avoiding concatenation padding.
  render_segment(f'rush-for-villains-{v.upper()}-23s.mp4',v,0,23,mixes[v])
 (HERE/'asset-manifest.json').write_text(json.dumps(sorted(r.ASSETS),indent=2),encoding='utf-8')
 for v in 'abc':
  lines=[x for x in TIMING if x['name'] not in ['a','b','c'] or x['name']==v]
  srt='\n\n'.join(f"{j+1}\n{r.timestamp(x['start'])} --> {r.timestamp(x['end'])}\n{x['text']}" for j,x in enumerate(lines))
  (HERE/f'subtitles-{v.upper()}.srt').write_text(srt+'\n',encoding='utf-8')
 print('COMPLETE',flush=True)
if __name__=='__main__':main()
