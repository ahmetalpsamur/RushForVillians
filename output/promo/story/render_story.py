"""40s mascot-led story cut. Original sprites, stable pivots, real app captures."""
import sys,math,json,subprocess,wave,functools,argparse
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent))
import render as r
from voice_story import LINES
np=r.np
Image=r.Image
ImageDraw=r.ImageDraw
W,H,FPS,DURATION=720,1280,30,40
WHITE='#FFF9EF';INK='#201A36';PINK='#FF86BF';GOLD='#FFE791';MINT='#AEFFDB'
CUTS=[6.4,10,17.7,23.6,28,32.5,35.2]
HITS=[20.80,21.65,22.65,23.30]
SPEECH={}
PLACEMENTS=[]
AUDIT=False
NOW=0

def p(state='Idle'):
 return r.PINKY/f'Pink_Monster_{state}_{dict(Idle=4,Walk=6,Run=6,Push=6,Jump=8,Throw=4,Attack1=4)[state]}.gif'
def text(im,s,x,y,size=40,color=WHITE):r.fit_text(im,s,(x,y),size,640,color)
def panel(im,box,color=INK,outline=None,radius=24):r.panel(im,box,color,outline or color,radius)
def mix(a,b,v):return Image.blend(a,b,max(0,min(1,v)))
def clamp(x):return max(0,min(1,x))

def actor(im,path,phase,x,ground,height,flip=False,once=False):
 if AUDIT:
  frames,durations=r.anim(str(path));elapsed=min(max(phase,0),sum(durations)-.001) if once else phase%sum(durations);idx=0
  while idx<len(frames)-1 and elapsed>=durations[idx]:elapsed-=durations[idx];idx+=1
  sp,pos,_=r.sprite_placement(path,idx,x,ground,height,flip);box=sp.getbbox()
  if box:PLACEMENTS.append((round(NOW,3),Path(path).name,tuple(pos[k%2]+box[k] for k in range(4))))
 r.sprite(im,path,phase,x,ground,height,flip,once=once)

@functools.lru_cache(None)
def sky():
 yy=np.linspace(0,1,H)[:,None,None]
 a=np.array([144,218,245])[None,None,:];b=np.array([255,242,205])[None,None,:]
 arr=np.repeat(a*(1-yy)+b*yy,W,axis=1).astype(np.uint8)
 return Image.fromarray(arr)

def park(t,travel=True):
 im=sky().copy();d=ImageDraw.Draw(im);v=t*36 if travel else 0
 d.ellipse((504,136,648,280),fill='#FFF2AE')
 for i in range(5):
  x=(i*255-v*.08)%1050-165;y=180+(i%3)*92
  for dx,dy,rr in [(0,12,30),(36,0,44),(78,14,34)]:d.ellipse((x+dx-rr,y+dy-rr,x+dx+rr,y+dy+rr),fill='#F5FDFA')
 # Far hills, middle trees and foreground path move at different speeds.
 for i in range(5):
  x=i*330-(v*.12)%330-230
  d.ellipse((x,540+(i%2)*50,x+620,1040),fill='#ADD4C4')
 for i in range(8):
  x=i*175-(v*.4)%175-130;y=635+(i%3)*38
  d.rounded_rectangle((x-9,y,x+9,920),8,fill='#8A8373')
  d.ellipse((x-72,y-170,x+73,y+18),fill=['#68B9A0','#7FC5A5','#92D0A8'][i%3])
  d.ellipse((x-60,y-183,x+38,y-67),fill='#A0D9AB')
 d.rectangle((0,865,W,H),fill='#A4D39C')
 d.polygon([(0,902),(W,902),(W,1115),(0,1220)],fill='#EACDA7')
 d.line((0,899,W,899),fill='#F3E6BC',width=10)
 for i in range(24):
  x=(i*99-v*1.1)%790-30;y=940+(i*83)%200
  d.ellipse((x,y,x+8,y+3),fill='#C8B293')
 for i in range(14):
  x=(i*143-v*.7)%840-60;y=878+(i%2)*-20
  d.line((x,y,x-6,y-12),fill='#508E78',width=3)
  d.ellipse((x-8,y-17,x-2,y-11),fill='#FFEDAD' if i%2 else '#F7A5BC')
 return im

@functools.lru_cache(None)
def landscape(night):
 path=r.ROOT/'lib/Backgrounds'/('versionA1_platform.png' if night else 'versionA_platform.png')
 r.ASSETS.add(str(path.relative_to(r.ROOT)).replace('\\','/'))
 return Image.open(path).convert('RGB').resize((1440,1080),Image.Resampling.NEAREST)

def world(t,night=False):
 source=landscape(night);x=int(310+110*math.sin(t*.11))
 im=Image.new('RGB',(W,H),'#251D37' if night else '#373349')
 im.paste(source.crop((x,0,x+W,1080)))
 # Foreground continues the game's platform below the camera framing.
 d=ImageDraw.Draw(im)
 d.polygon([(0,939),(W,939),(W,1084),(0,1132)],fill='#5B4757' if night else '#88766D')
 d.line((0,936,W,936),fill='#AE8F82' if night else '#C7AE91',width=5)
 for i in range(30):
  x=(i*73-t*34)%780-30;y=1110+(i*47)%170
  d.line((x,y,x+25,y-12),fill='#493B4D',width=2)
 return im

def motes(im,t,count=18,color=GOLD,origin=None,age=None):
 d=ImageDraw.Draw(im)
 for i in range(count):
  if origin is not None:
   angle=i*2.399;x=origin[0]+math.cos(angle)*age*(130+i%6*29);y=origin[1]+math.sin(angle)*age*210+age*age*70
  else:x=(i*139+t*13)%720;y=160+(i*163-t*27)%840
  s=2+i%4;d.rectangle((x-s,y-s,x+s,y+s),fill=color)

def emote(im,s,x,y):
 panel(im,(x-35,y-40,x+35,y+36),WHITE,radius=20)
 text(im,s,x,y,48,INK)

def subtitles(im,t):
 active=next(((i,a,b,s) for i,(a,b,s) in enumerate(LINES) if a<=t<b),None)
 if not active:return
 i,a,b,s=active
 parts={1:['Wait… walking is way more fun','with this!'],3:['Every step gets me closer','to my next battle!'],8:["HAHA! That's what my walk gets me!"],10:['Your next walk could be','an adventure too!']}.get(i,[s])
 if len(parts)>1:
  span=SPEECH.get(i,b-a);weight=len(parts[0].split())/sum(len(x.split()) for x in parts)
  s=parts[0 if t-a<span*weight else 1]
 lines=r.wrap(s,width=604,size=32)
 panel(im,(33,1080,687,1130+44*len(lines)),INK,'#AE729D',24)
 r.txt(im,'PINKY',(55,1104),15,PINK,anchor='lm')
 for j,line in enumerate(lines):text(im,line,360,1143+44*j,32)

def phone(im,path,x=143,y=195,width=434,height=813,tap=False):
 panel(im,(x-9,y-9,x+width+9,y+height+9),'#0A0C18','#B0A9CC',37)
 screen=Image.open(path).convert('RGB').resize((width-24,height-24),Image.Resampling.LANCZOS)
 im.paste(screen,(x+12,y+12))
 panel(im,(x+width*.35,y+10,x+width*.65,y+22),'#090C15',radius=6)
 if tap:
  tx=x+width*.66;ty=y+height*.947
  d=ImageDraw.Draw(im)
  for radius in [18,33,48]:d.ellipse((tx-radius,ty-radius,tx+radius,ty+radius),outline=GOLD,width=4)

def tiny_phone(im,x,y,scale=1):
 w=75*scale;h=136*scale
 panel(im,(x-w/2,y-h,x+w/2,y),'#231D3D','#FFF1D9',12)
 panel(im,(x-w*.4,y-h*.91,x+w*.4,y-h*.1),'#7C5CFF',radius=5)
 text(im,'R',x,y-h*.52,int(36*scale),GOLD)

def steps(im,t,compact=False):
 milestones=[(10,120),(11.4,340),(12.8,580),(14.2,820),(16.1,1000)]
 current=max((entry for entry in milestones if t>=entry[0]),default=milestones[0])
 value=current[1];pulse=1-clamp((t-current[0])/.45)
 box=(87,180,633,410) if not compact else (145,210,575,399)
 panel(im,box,'#211B3B','#A791DA',30)
 text(im,'EVERY STEP COUNTS',360,222,21,MINT)
 text(im,str(value),360,306,int(85+10*pulse),GOLD if value==1000 else WHITE)
 text(im,'/ 1000 STEPS',360,366,23,WHITE)
 d=ImageDraw.Draw(im);d.rounded_rectangle((116,438,604,454),8,fill='#45395A')
 d.rounded_rectangle((116,438,116+488*value/1000,454),8,fill=MINT)
 for i in range(5):d.ellipse((145+i*102,482,159+i*102,496),fill=GOLD if value>=milestones[i][1] else '#685671')
 if pulse>0:motes(im,t,10,MINT,(360,315),(1-pulse)*.9)

def health(im,x,y,w,pct,label,color):
 panel(im,(x-9,y-43,x+w+9,y+24),'#21162E','#796383',12)
 r.bar(im,x,y,w,pct,color,label)

def battle(im,t,montage=False):
 u=t-17.7
 health(im,63,304,240,max(.58,1-clamp((t-21.68)/.25)*.42),'KNIGHT',MINT)
 hp=1-.29*clamp((t-20.8)/.18)-.35*clamp((t-22.65)/.18)-.36*clamp((t-23.3)/.18)
 health(im,420,304,237,hp,'ASH GUARDIAN','#FF8B9B')
 x=188;y=950;hero_state='Idle';enemy_state='Idle';hero_phase=t;enemy_phase=t
 for attack in [20.6,22.45,23.10]:
  if attack<=t<attack+.55:
   hero_state='Attack01';hero_phase=t-attack;x+=48*math.sin(math.pi*clamp((t-attack)/.55))
 if 21.43<=t<22.05:enemy_state='Attack01';enemy_phase=t-21.43
 if 21.65<=t<21.95:hero_state='Hurt';hero_phase=t-21.65
 if any(a<=t<a+.22 for a in [20.8,22.65,23.3]):enemy_state='Hurt';enemy_phase=t
 actor(im,r.path_for('Knight',hero_state),hero_phase,x,y,208,once=hero_state!='Idle')
 actor(im,r.path_for('Black Knight_A',enemy_state,True),enemy_phase,536,y,295,True,once=enemy_state!='Idle')
 for hit in HITS:
  age=t-hit
  if 0<=age<.34:
   cx=239 if hit==21.65 else 493
   motes(im,t,13,GOLD,(cx,701),age+.08)
   text(im,'HIT!' if hit!=21.65 else '!',cx,553-age*90,48 if hit!=23.3 else 70,GOLD)
 if not montage:
  panel(im,(20,363,186,543),'#211B3B','#AE729D',40)
  actor(im,p('Idle' if t<20.55 else 'Attack1'),t,102,525,132)
  if 17.9<t<19.3:emote(im,'?',226,433)
  if 19.7<t<20.6:emote(im,'!',226,433)

def rewards(im,t):
 u=t-23.6
 panel(im,(108,163,612,284),INK,'#AE729D',24);text(im,'VICTORY!',360,227,73,GOLD)
 if u<1.25:
  actor(im,r.path_for('Knight'),t,239,950,207)
  actor(im,r.path_for('Black Knight_A','Death',True),u,541,950,295,True,once=True)
  panel(im,(20,509,186,705),'#211B3B','#AE729D',40)
  actor(im,p('Jump'),u,104,691,132)
  text(im,'+ COINS',360,358,44,GOLD);text(im,'+ XP',360,415,39,MINT)
 else:
  phone(im,HERE.parent/'en/screens/forge.png',337,355,316,655)
  actor(im,p('Jump' if u<2.5 else 'Idle'),max(0,u-1.25),156,1000,222)
  panel(im,(43,405,278,493),'#211B3B','#AE729D',18);text(im,'+ COINS',160,449,30,GOLD)
  text(im,'LEVEL UP!',166,596,30,MINT)
  r.bar(im,61,639,202,clamp((u-1.25)/1.1),MINT,'XP')
 for i in range(20):
  age=clamp((u-i*.023)/1.8);theta=i*2.399
  burstx=360+math.cos(theta)*250;bursty=650+math.sin(theta)*220
  if u<1.4:
   x=360+(burstx-360)*age;y=735+(bursty-735)*age
  else:
   v=r.ease((u-1.4)/1.3);x=burstx+(491-burstx)*v;y=bursty+(525-bursty)*v
  if u<2.7:r.sprite(im,r.ROOT/'lib/All_Assets/coins/coin_gold_medium_shine.gif',t+i,x,y,29+i%3*7,shadow=False)

def montage(im,t):
 k=min(6,int((t-32.5)/(.3857)))
 if k==0:
  im=world(t);actor(im,p('Run'),t,320,976,270);text(im,'WALK.',360,261,79)
 elif k==1:
  im=world(t);steps(im,16.2);actor(im,p('Walk'),t,342,987,263)
 elif k==2:
  im=world(t,True);text(im,'FIND YOUR CLASS.',360,245,47)
  for i,name in enumerate(['Archer','Knight','Wizard','Swordsman']):actor(im,r.path_for(name,'Walk'),t,94+i*165,950,116)
 elif k==3:
  im=world(t,True);text(im,'FIGHT.',360,222,72)
  for i,name in enumerate(['Demon_A','Flame Golem','Black Knight_A']):actor(im,r.path_for(name,enemy=True),t,140+i*225,950,198,True)
 elif k==4:
  im=world(t,True);battle(im,22.75,True)
 elif k==5:
  im=world(t);rewards(im,24.35)
 else:
  im=world(t,True);text(im,'LEVEL UP.',360,265,73,GOLD)
  actor(im,r.path_for('Knight'),t,345,950,235);actor(im,p('Jump'),t,119,950,151)
  text(im,'+ XP',546,716,39,MINT)
 return im

def frame(t):
 global NOW
 NOW=t
 if t<6.4:
  travel=min(t,3.05);im=park(travel)
  text(im,'JUST A LITTLE WALK…',360,163,24,INK)
  state='Walk' if t<3.05 else ('Idle' if t<4.55 else 'Push')
  actor(im,p(state),t,312+7*math.sin(t*2) if t<3.05 else 312,931,274)
  if 3.15<t<4.45:emote(im,'…',449,589)
  if t>=4.55:
   v=r.ease((t-4.55)/.35);tiny_phone(im,455,914+90*(1-v),1.05)
   motes(im,t,8,'#FFF9DF',(451,796),min(.5,t-4.55))
 elif t<10:
  u=t-6.4;im=park(3.05).filter(r.ImageFilter.GaussianBlur(6))
  im=mix(im,Image.new('RGB',(W,H),INK),.23)
  text(im,'RUSH FOR VILLAINS',360,123,34,WHITE)
  shot='adventure.png' if u<1.05 else 'start-adventure.png'
  phone(im,HERE/'screens'/shot,164,222,405,782,tap=9.05<t<9.4)
  panel(im,(184,161,552,218),INK,'#AE729D',14)
  actor(im,r.path_for('Knight'),t,212,207,32);text(im,'MY CLASS · KNIGHT',390,188,19)
  actor(im,p('Push' if t>9 else 'Idle'),t,100,1034,142)
  if t>9.35:
   v=clamp((t-9.35)/.65);im=mix(im,world(t),v)
   d=ImageDraw.Draw(im);radius=int(40+v*860)
   d.ellipse((360-radius,630-radius,360+radius,630+radius),outline=GOLD,width=20)
   motes(im,t,42,GOLD,(360,630),v*2)
 elif t<17.7:
  im=world(t);steps(im,t)
  actor(im,p('Jump' if t>=16.1 else ('Run' if t>13.8 else 'Walk')),max(0,t-16.1) if t>=16.1 else t,335,962,264)
  if t>=16.1:
   panel(im,(62,565,658,697),INK,'#D6B6E1',24)
   text(im,'ADVENTURE',360,604,39,GOLD);text(im,'COMPLETE!',360,658,47,GOLD)
   motes(im,t,34,GOLD,(360,723),min(1.25,t-16.1))
 elif t<23.6:
  im=world(t,True);panel(im,(202,135,518,208),INK,radius=17);text(im,'ENCOUNTER!',360,176,33,GOLD)
  battle(im,t)
  if t<18.1:im=mix(im,Image.new('RGB',(W,H),'#281938'),(18.1-t)*.65)
 elif t<28:
  im=world(t);rewards(im,t)
 elif t<32.5:
  im=world(t);u=t-28
  actor(im,p('Walk' if u<.45 or u>3.1 else 'Idle'),t,202+max(0,u-3.1)*63,970,244,flip=.9<u<1.25)
  for i,name in enumerate(['Black Knight_A','Demon_A','Flame Golem']):
   appear=.25+i*.38
   if u>=appear:actor(im,r.path_for(name,enemy=True),t,440+i*80,950,100+i*20,True)
  if .55<u<1.45:emote(im,'…',277,601)
  if u>2.1:motes(im,t,12)
 elif t<35.2:im=montage(world(t),t)
 else:
  im=mix(world(t,True),r.background(6),.85);motes(im,t,20)
  r.logo(im,265,.94)
  text(im,'WALK. FIGHT. LEVEL UP.',360,441,30)
  actor(im,p('Throw' if t<38 else 'Jump'),t-35.2 if t<38 else t-38,345,885,273)
  panel(im,(126,939,594,1021),GOLD,radius=17)
  text(im,'COMING SOON',360,978,39,INK)
 # Gentle impact camera move applies to the whole scene, not individual sprite anchors.
 for impact in HITS:
  if 0<=t-impact<.13:
   dx=round(math.sin((t-impact)*95)*6*(1-(t-impact)/.13))
   shifted=Image.new('RGB',(W,H),INK);shifted.paste(im,(dx,0));im=shifted
 subtitles(im,t)
 if t<.25:im=mix(Image.new('RGB',(W,H),'#BDE4ED'),im,t/.25)
 for cut in [17.7,23.6,32.5,35.2]:
  if 0<=t-cut<.10:im=mix(im,Image.new('RGB',(W,H),GOLD),.18*(1-(t-cut)/.10))
 return im

def audio():
 sr=48000;n=sr*DURATION;out=np.zeros((n,2),np.float32);rng=np.random.default_rng(92)
 def add(at,sig,gain=1,pan=0):
  if at>=DURATION:return
  start=int(at*sr);end=min(n,start+len(sig));sig=sig[:end-start]*gain
  out[start:end,0]+=sig*(1-pan*.4);out[start:end,1]+=sig*(1+pan*.4)
 def bell(at,freq,gain=.08):
  tt=np.arange(int(sr*.45))/sr;add(at,(np.sin(math.tau*freq*tt)+.18*np.sin(math.tau*freq*2*tt))*np.exp(-tt*11)*np.minimum(1,tt*220),gain)
 beat=60/144
 for j in range(math.ceil(DURATION/beat)):
  at=j*beat;root=[130.81,164.81,110,146.83][(j//8)%4]
  level=.30 if at<9.35 else (.90 if at<17.7 else 1.1)
  if 28.4<at<29.15:level=.06
  if 29.15<=at<32.5:level=.5+(at-29.15)*.18
  ts=np.arange(int(sr*.26))/sr
  if at>9.35:
   add(at,np.sin(math.tau*(49*ts+8*(1-np.exp(-ts*25))))*np.exp(-ts*24),.13*level)
   if j%2:add(at,rng.uniform(-1,1,len(ts))*np.exp(-ts*28),.05*level)
  add(at,np.sin(math.tau*root*ts)*np.exp(-ts*8)*np.minimum(1,ts*80),.045*level)
  for k in range(2):bell(at+k*beat/2,root*4*[1,1.25,1.5,2][(j+k)%4],.021*level)
 for start,end in [(0,3),(10,16.1),(28,28.45),(31.1,32.5)]:
  for at in np.arange(start,end,.34):
   ts=np.arange(int(sr*.07))/sr;add(float(at),rng.uniform(-1,1,len(ts))*np.exp(-ts*75),.024)
 for at in [11.4,12.8,14.2,16.1]:
  bell(at,880,.11);bell(at+.075,1174.7,.09)
 for at in [9.1,9.35,17.7,23.6,32.5,35.2]:
  ts=np.arange(int(sr*.28))/sr;add(at,rng.uniform(-1,1,len(ts))*np.sin(math.pi*ts/.28)**2,.065)
 for at in HITS:
  ts=np.arange(int(sr*.25))/sr;add(at,(rng.uniform(-1,1,len(ts))*.5+np.sin(math.tau*(93*ts-90*ts*ts)))*np.exp(-ts*17),.19)
 for at in [16.1,23.6]:
  for i,f in enumerate([659.25,830.6,987.8,1318.5]):bell(at+i*.095,f,.12)
 for at in [24,24.15,24.3,25.3,25.45,25.6]:bell(at,1568,.07)
 report=[]
 for i,(start,end,wording) in enumerate(LINES):
  raw=subprocess.check_output([r.FFMPEG,'-v','error','-i',str(HERE/'audio'/f'voice_{i:02}.mp3'),'-af','silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse','-f','f32le','-ac','1','-ar',str(sr),'-'])
  source=np.frombuffer(raw,dtype=np.float32);duration=len(source)/sr;tempo=max(1,duration/(end-start-.04))
  if tempo>1.22:print(f'VOICE PACE REVIEW line {i+1}: {tempo:.3f}',flush=True)
  fitted=subprocess.check_output([r.FFMPEG,'-v','error','-f','f32le','-ar',str(sr),'-ac','1','-i','-','-af',f'atempo={tempo:.8f}','-f','f32le','-'],input=raw)
  sig=np.frombuffer(fitted,dtype=np.float32).copy();sig*=.73/max(.1,float(np.max(np.abs(sig))))
  fade=min(200,len(sig)//4);sig[:fade]*=np.linspace(0,1,fade);sig[-fade:]*=np.linspace(1,0,fade)
  startidx=int(start*sr);endidx=min(n,startidx+len(sig));out[startidx:endidx]*=.30;add(start,sig)
  SPEECH[i]=len(sig)/sr
  report.append({'line':i+1,'text':wording,'start':start,'end':end,'source_seconds':round(duration,3),'tempo':round(tempo,3),'fitted_seconds':round(len(sig)/sr,3)})
 out[-sr//15:]*=np.linspace(1,0,sr//15)[:,None];out*=.94/max(.94,float(np.max(np.abs(out))))
 with wave.open(str(HERE/'audio/mix.wav'),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr);f.writeframes((out*32767).astype('<i2').tobytes())
 (HERE/'audio/timing-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')

def main():
 global AUDIT
 parser=argparse.ArgumentParser();parser.add_argument('--preview',action='store_true');parser.add_argument('--audit',action='store_true');args=parser.parse_args()
 if not args.preview:audio()
 moments=[1.5,4.8,7,8.4,10.7,14.6,16.65,18.7,20.9,21.8,24.1,26,29,31.6,36.2]
 sheet=Image.new('RGB',(1080,1230),INK)
 for i,t in enumerate(moments):
  fr=frame(t).resize((216,384),Image.Resampling.LANCZOS);x=i%5*216;y=i//5*410
  sheet.paste(fr,(x,y));r.txt(sheet,f'{t:.2f}s',(x+108,y+397),15)
 sheet.save(HERE/'storyboard.jpg',quality=96)
 frame(39.8).resize((1080,1920),Image.Resampling.LANCZOS).save(HERE/'poster.png')
 if args.preview:return
 AUDIT=args.audit
 output=HERE/'rush-for-villains-pinky-adventure-en.mp4'
 proc=subprocess.Popen([r.FFMPEG,'-y','-v','warning','-f','rawvideo','-pix_fmt','rgb24','-s','720x1280','-r',str(FPS),'-i','-',
  '-i',str(HERE/'audio/mix.wav'),'-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-preset','fast','-crf','19','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-t','40','-movflags','+faststart',str(output)],stdin=subprocess.PIPE)
 for i in range(FPS*DURATION):
  proc.stdin.write(frame(i/FPS).tobytes())
  if i%(FPS*2)==0:print(f'Story render {i//FPS}/40 seconds',flush=True)
 proc.stdin.close()
 assert proc.wait()==0,'Render failed'
 (HERE/'asset-manifest.json').write_text(json.dumps(sorted(r.ASSETS),indent=2),encoding='utf-8')
 srt='\n\n'.join(f'{i+1}\n{r.timestamp(a)} --> {r.timestamp(b)}\n{s}' for i,(a,b,s) in enumerate(LINES))
 (HERE/'rush-for-villains-pinky.en.srt').write_text(srt+'\n',encoding='utf-8')
 if AUDIT:
  bad=[{'time':t,'asset':name,'bounds':box} for t,name,box in PLACEMENTS if box[0]<0 or box[2]>W or box[1]<0 or box[3]>1075]
  (HERE/'position-audit.json').write_text(json.dumps({'placements':len(PLACEMENTS),'out_of_bounds':bad},indent=2),encoding='utf-8')
 print('Story complete',flush=True)
if __name__=='__main__':main()
