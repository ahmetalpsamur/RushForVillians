"""Original game assets and actual Flutter screens, with playful competitive dialogue."""
import sys,json,math,functools,subprocess,wave,argparse
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent));sys.path.insert(0,str(HERE.parent/'community'))
# Resolve this advertisement's voice script before importing reusable art helpers.
sys.path.insert(0,str(HERE))
from voices import LINES,VOICES
import render as r
import render_community as c
np=r.np;Image=r.Image;D=r.ImageDraw
W,H,FPS=720,1280,30
INK='#21182F';WHITE='#FFF9EE';PINK='#FF91C6';BLUE='#91DAFF';GOLD='#FFE18A';MINT='#B7F3CD'
COLORS={'PINKY':PINK,'MAVILI':BLUE,'ALL':GOLD}
REWARDS=json.loads((HERE/'rewards.json').read_text())
STATS=json.loads((HERE/'stats.json').read_text())
REAL_LINES=[];TIME_MAP=[];DURATION=89;AUDIT=False;BOUNDS=[];NOW=0

def text(im,s,x,y,size=38,color=WHITE,width=620):r.fit_text(im,s,(x,y),size,width,color)
def panel(im,box,fill=INK,outline='#74577F',radius=25):r.panel(im,box,fill,outline,radius)
def active(t):return next(((i,a,b,who,s) for i,(a,b,who,s) in enumerate(LINES) if a<=t<b),None)
def label(im,s,x,y,width=310,color=GOLD):
 panel(im,(x-width/2,y-27,x+width/2,y+27),color,color,13);text(im,s,x,y,22,INK,width-20)

@functools.lru_cache(None)
def screen(name):return Image.open(HERE/'screens'/f'{name}.png').convert('RGB')
@functools.lru_cache(None)
def icon(path,size):
 p=r.ROOT/path;r.ASSETS.add(path);im=Image.open(p).convert('RGBA');box=im.getbbox()
 if box:im=im.crop(box)
 scale=size/max(im.size);return im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.NEAREST)
def item(im,path,x,y,size=90):
 sp=icon(path,size);im.paste(sp,(round(x-sp.width/2),round(y-sp.height/2)),sp)

def actor(im,who,t,x,y,h=245,state='Idle',flip=False):
 path=c.asset(who,state)
 if AUDIT:
  frames,durations=r.anim(str(path));phase=t%sum(durations);idx=0
  while idx<len(frames)-1 and phase>=durations[idx]:phase-=durations[idx];idx+=1
  sp,pos,_=r.sprite_placement(path,idx,x,y,h,flip);box=sp.getbbox()
  if box:BOUNDS.append((round(NOW,3),who,state,[pos[k%2]+box[k] for k in range(4)]))
 r.sprite(im,path,t,x,y,h,flip)

def duo(im,t,y=991,height=255,zoom=None,scale=1):
 row=active(t);who=row[3] if row else None
 for name,x in [('PINKY',208),('MAVILI',512)]:
  x=360+(x-360)*scale
  h=height*scale+(22 if zoom==name else 0)
  face=(name=='MAVILI') if t<71.2 or t>=74.1 else False
  actor(im,name,t,x,y,h,'Idle',face)
  if who in (name,'ALL'):
   d=D.Draw(im);color=COLORS[name]
   d.line((x-30,y+19,x+30,y+19),fill=color,width=5)
   for j in [-1,0,1]:
    hh=7+8*(.5+.5*math.sin(t*19+j*2));xx=x+j*10
    d.line((xx,y-h-28-hh,xx,y-h-28),fill=color,width=4)

def heading(im,title,sub=None):
 text(im,title,360,174,51,GOLD)
 if sub:text(im,sub,360,232,25,WHITE)

def phone(im,name,t,x=360,y=600,w=352,crop=None):
 shot=screen(name)
 if crop:shot=shot.crop(crop)
 h=round(w*shot.height/shot.width)
 xx=round(x-w/2);yy=round(y-h/2)
 panel(im,(xx-12,yy-12,xx+w+12,yy+h+12),'#0C0912','#AD8CBD',29)
 shot=shot.resize((w,h),Image.Resampling.LANCZOS)
 mask=Image.new('L',(w,h));D.Draw(mask).rounded_rectangle((0,0,w,h),18,fill=255)
 im.paste(shot,(xx,yy),mask)

def gear(im,t,y=480):
 for i,(path,name) in enumerate([('lib/Items/swords/aqua_sword.png','AQUA SWORD'),('lib/Items/shields/blue_round_shield.png','BLUE ROUND SHIELD')]):
  x=218+i*284;panel(im,(x-115,y-127,x+115,y+123),'#352544','#896485',24)
  item(im,path,x,y-21+math.sin(t*2+i)*5,116)
  text(im,name,x,y+80,19,WHITE,214)

def shine(im,t,cx,cy,radius=230):
 d=D.Draw(im)
 for j in range(12):
  a=j*math.tau/12+t*.15
  d.line((cx+math.cos(a)*radius*.55,cy+math.sin(a)*radius*.55,cx+math.cos(a)*radius,cy+math.sin(a)*radius),fill='#685044',width=3)

def stat_pop(im,t):
 panel(im,(137,825,583,928),'#213C3C','#86C9AE',18)
 text(im,'AQUA SWORD · LEVEL 3 → 4',360,848,21,MINT)
 progress=r.ease((t-15.65)/.65)
 for j,(before,after) in enumerate(zip(STATS['3'],STATS['4'])):
  value=100*(before['value']+(after['value']-before['value'])*progress)
  text(im,f'{before["stat"].upper()} +{value:.1f}%',249+j*222,894,23,WHITE,210)

def collection(im,t,small=False):
 # Actual collectible art; fixed display cards, with a small cinematic horizontal pan.
 xoff=math.sin((t-43)*.24)*15
 for i,reward in enumerate(REWARDS):
  col=i%3;row=i//3;x=152+col*208+xoff;y=382+row*193
  panel(im,(x-91,y-82,x+91,y+91),'#382840','#A6885C',18)
  D.Draw(im).ellipse((x-40,y+38,x+40,y+53),fill='#5D4351')
  item(im,reward['asset'],x,y-9,90)
  text(im,'EARNED',x,y+70,15,GOLD,158)

def caption(im,t):
 row=active(t)
 if row is None:return
 i,a,b,who,s=row
 rows=r.wrap(s,588,31);top=1080
 panel(im,(33,top,687,1122+len(rows)*40),'#1B1328',COLORS[who],22)
 r.txt(im,'BOTH' if who=='ALL' else who,(56,top+24),16,COLORS[who],anchor='lm')
 for j,line in enumerate(rows):text(im,line,360,top+63+j*40,31)

def old_time(real):
 for a,b,ra,rb in TIME_MAP:
  if real<ra:return a-(ra-real)
  if real<=rb:return a+(real-ra)*(b-a)/(rb-ra)
 return 89-(DURATION-real)

def frame(real):
 global NOW
 NOW=real;t=old_time(real)
 im=c.background(t);d=D.Draw(im)
 if t<14:
  heading(im,'EQUIP YOUR HERO')
  if t<3:
   text(im,'A normal walk.',360,400,46)
   text(im,'A perfectly normal ego.',360,457,26,PINK)
   v=r.ease(t/.85);actor(im,'PINKY',t,100+260*v,992,272,'Walk' if t<.85 else 'Idle')
  elif t<7:
   phone(im,'equipment',t,y=565,w=326,crop=(0,35,390,735))
   actor(im,'PINKY',t,115,1000,188)
   label(im,'EQUIPPED',568,944,173,MINT)
  else:
   gear(im,t,y=466)
   actor(im,'PINKY',t,208,991,258)
   v=r.ease((t-7)/.65);actor(im,'MAVILI',t,820-308*v,991,258,'Walk' if v<1 else 'Idle',True)
   if 7.65<t<8.9:text(im,'…',507,653,65,BLUE)
   if 9.65<t<11.3:label(im,'CUTE?',213,650,177,PINK)
   if t>=11.8:label(im,'BETTER STATS.',506,653,238,BLUE)
 elif t<25.5:
  heading(im,'UPGRADE YOUR GEAR')
  if t<17.9:
   phone(im,'upgrade-before' if t<16 else 'upgrade-after',t,y=535,w=508,crop=(0,0,390,424))
   stat_pop(im,t)
   actor(im,'PINKY',t,114,1025,145);actor(im,'MAVILI',t,604,1025,145,flip=True)
  else:
   phone(im,'upgrade-after',t,y=446,w=503,crop=(12,74,378,288))
   label(im,'POWER ↑',360,661,235,MINT)
   if t>24.2:
    actor(im,'PINKY',t,170,1005,155)
    actor(im,'MAVILI',t,469,1015,326,flip=True)
   else:duo(im,t,height=247)
   if 18.55<=t<19.1:text(im,'…',208,703,43,PINK)
 elif t<39:
  heading(im,'EARN YOUR TITLES')
  if t<29:
   phone(im,'titles',t,y=519,w=528,crop=(0,0,390,390))
   actor(im,'PINKY',t,211,1001,229);actor(im,'MAVILI',t,527,1001,180,flip=True)
  else:
   shine(im,t,245,620,236)
   label(im,'LIVING LEGEND',267,428,382,GOLD)
   text(im,'EQUIPPED TITLE',267,481,18,GOLD)
   for j,title in enumerate(['First Step','Forge Master','Storm Walker']):
    label(im,title,156+j*204,282,187,'#DAC5E7')
   duo(im,t,height=274,zoom='PINKY' if t<32.5 else None)
   if t>35.2:label(im,'VERY HUMBLE.',360,587,308,BLUE)
 elif t<53:
  heading(im,'YOUR REWARD SHOWCASE')
  if t<43.2:
   phone(im,'showcase',t,y=601,w=350)
   actor(im,'PINKY',t,97,1022,130);actor(im,'MAVILI',t,624,1022,130,flip=True)
  else:
   collection(im,t)
   if t>=49.7:label(im,'ADMISSION: FREE',360,725,338,MINT)
   duo(im,t,height=217,y=1020)
   if 44.5<t<45.4:text(im,'…',519,747,43,BLUE)
 elif t<62.2:
  if t<55.8:
   heading(im,'BETTER EQUIPMENT');gear(im,t,465);duo(im,t,height=236)
  elif t<57:
   heading(im,'UPGRADE');phone(im,'upgrade-after',t,y=491,w=520,crop=(10,74,380,288));duo(im,t,height=236)
  elif t<58.2:
   heading(im,'UNLOCK TITLES');label(im,'LIVING LEGEND',360,457,435);duo(im,t,height=260)
  elif t<59.6:
   heading(im,'COLLECT REWARDS');collection(im,t);duo(im,t,height=215,y=1035)
  else:
   heading(im,'GET STRONGER',"Together. Technically.");duo(im,t,height=282)
   if t>=60.9:text(im,'…',360,520,72,GOLD)
 elif t<78.9:
  heading(im,'FRIENDLY COMPETITION')
  label(im,'LIVING LEGEND',205,332,290,PINK);label(im,'FORGE MASTER',516,332,280,BLUE)
  gear(im,t,y=538)
  row=active(t);who=row[3] if row else None
  if t>=75.5 and who:
   actor(im,'PINKY',t,208,1000,307 if who=='PINKY' else 205)
   actor(im,'MAVILI',t,512,1000,307 if who=='MAVILI' else 205,flip=True)
  else:duo(im,t,height=268,zoom=who if 68.15<=t<74.1 else None)
  if 70.2<=t<71.2:text(im,'…',211,706,47,PINK)
  if t>=75.5 and who:label(im,'ME!',208 if who=='PINKY' else 512,691,165,COLORS[who])
 elif t<83:
  u=r.ease((t-78.9)/4.1);r.logo(im,278,.91)
  text(im,'EQUIP. UPGRADE.',360,453,35,GOLD);text(im,'EARN. SHOW OFF.',360,503,35,GOLD)
  duo(im,t,y=999-55*u,height=265,scale=1-.42*u)
 else:
  im=Image.new('RGB',(W,H),'#09070F');r.logo(im,315,.91)
  text(im,'EQUIP. UPGRADE.',360,511,38,GOLD);text(im,'EARN. SHOW OFF.',360,565,38,GOLD)
  text(im,'Build your hero.',360,716,30)
  text(im,'Earn your titles.',360,760,30)
  text(im,'Show your journey.',360,804,30)
 caption(im,t)
 for cut in [14,25.5,39,53,55.8,57,58.2,59.6]:
  if 0<=t-cut<.085:im=Image.blend(im,Image.new('RGB',(W,H),GOLD),.14*(1-(t-cut)/.085))
 return im

def prepare_audio():
 global DURATION
 sr=48000;records=[];offset=0;report=[]
 for i,(a,b,speaker,wording) in enumerate(LINES):
  members=list(VOICES) if speaker=='ALL' else [speaker];signals=[]
  for who in members:
   suffix='_'+who.lower() if speaker=='ALL' else ''
   dest=HERE/'audio'/f'voice_{i:02}{suffix}.mp3'
   raw=subprocess.check_output([r.FFMPEG,'-v','error','-i',str(dest),'-f','f32le','-ar',str(sr),'-ac','1','-'])
   # Trim only outer silence with a generous phoneme/breath margin. Preserve all
   # inner pauses and unvoiced consonants; never time-compress the performance.
   samples=np.frombuffer(raw,dtype=np.float32)
   voiced=np.flatnonzero(np.abs(samples)>.001)
   if len(voiced):
    lo=max(0,int(voiced[0])-.12*sr);hi=min(len(samples),int(voiced[-1])+.18*sr)
    raw=samples[int(lo):int(hi)].tobytes()
   signals.append((who,raw,len(raw)/4/sr))
  slot=max(b-a,max(d for _,_,d in signals)+.08);start=a+offset;end=start+slot
  TIME_MAP.append((a,b,start,end));REAL_LINES.append((start,end,speaker,wording));offset+=slot-(b-a)
  for who,raw,dur in signals:
   tempo=1.0
   fitted=raw
   sig=np.frombuffer(fitted,dtype=np.float32).copy();sig*=.70/max(.1,float(np.max(np.abs(sig))))
   fade=min(150,len(sig)//4);sig[:fade]*=np.linspace(0,1,fade);sig[-fade:]*=np.linspace(1,0,fade)
   gain=.52 if speaker=='ALL' else (.57 if a>=78.9 else 1)
   records.append((start,sig,gain,(-.25 if who=='PINKY' else .25)))
   report.append(dict(line=i+1,speaker=who,text=wording,start=round(start,3),slot_end=round(end,3),source_seconds=round(dur,3),tempo=round(tempo,3),spoken_end=round(start+len(sig)/sr,3)))
 DURATION=math.ceil((records[-1][0]+len(records[-1][1])/sr+.07)*FPS)/FPS
 n=round(sr*DURATION);music=np.zeros((n,2),np.float32);vocal=np.zeros_like(music);rng=np.random.default_rng(243)
 def add(dest,at,sig,gain=1,pan=0):
  a=round(at*sr)
  if a>=n:return
  b=min(n,a+len(sig));sig=sig[:b-a]*gain
  dest[a:b,0]+=sig*(1-pan*.4);dest[a:b,1]+=sig*(1+pan*.4)
 beat=60/144
 for j in range(math.ceil(DURATION/beat)):
  at=j*beat;t=old_time(at)
  if t>=83 or 60.9<t<62.2 or 7.65<t<8.9 or 44.5<t<45.4 or 70.2<t<71.2:continue
  root=[130.81,155.56,174.61,146.83][(j//8)%4];ts=np.arange(round(sr*.25))/sr
  add(music,at,np.sin(math.tau*(49*ts+6*(1-np.exp(-ts*25))))*np.exp(-ts*24),.085)
  if j%2:add(music,at,rng.uniform(-1,1,len(ts))*np.exp(-ts*33),.027)
  add(music,at,np.sin(math.tau*root*ts)*np.exp(-ts*9)*np.minimum(1,ts*140),.046)
  for k in range(2):
   f=root*4*[1,1.25,1.5,2][(j+k)%4];sig=np.sin(math.tau*f*ts)*np.exp(-ts*14)*np.minimum(1,ts*160)
   add(music,at+k*beat/2,sig,.024,(-1)**j*.5)
 for start,sig,gain,pan in records:
  add(vocal,start,sig,gain,pan);a=round(start*sr);b=min(n,a+len(sig));music[a:b]*=.25
 out=vocal+music;out*=.94/max(.94,float(np.max(np.abs(out))))
 with wave.open(str(HERE/'audio/mix.wav'),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr);f.writeframes((out*32767).astype('<i2').tobytes())
 (HERE/'audio/timing-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 (HERE/'timeline.json').write_text(json.dumps(dict(duration=DURATION,time_map=TIME_MAP,lines=REAL_LINES),ensure_ascii=False,indent=2),encoding='utf-8')
 print(f'Voice mix: {DURATION:.2f}s; maximum tempo {max(x["tempo"] for x in report):.3f}',flush=True)

def real_time(t):
 for a,b,ra,rb in TIME_MAP:
  if t<a:return ra-(a-t)
  if t<=b:return ra+(t-a)*(rb-ra)/(b-a)
 return DURATION-(89-t)

def main():
 global AUDIT,DURATION
 parser=argparse.ArgumentParser();parser.add_argument('--preview',action='store_true');parser.add_argument('--reuse-audio',action='store_true');args=parser.parse_args()
 if args.reuse_audio:
  data=json.loads((HERE/'timeline.json').read_text());DURATION=data['duration'];TIME_MAP.extend(data['time_map']);REAL_LINES.extend(data['lines'])
 else:prepare_audio()
 moments=[1.9,4,8.2,10.7,15,20,27,30.5,36,40.8,46.2,50.4,59.9,69.6,76,81,85]
 sheet=Image.new('RGB',(1080,1640),INK)
 for i,t in enumerate(moments):
  fr=frame(real_time(t)).resize((216,384),Image.Resampling.LANCZOS);x=i%5*216;y=i//5*410;sheet.paste(fr,(x,y));r.txt(sheet,f'{real_time(t):.1f}s',(x+108,y+396),15)
 sheet.save(HERE/'storyboard.jpg',quality=95);frame(real_time(30.5)).resize((1080,1920),Image.Resampling.LANCZOS).save(HERE/'poster.png')
 if args.preview:return
 AUDIT=True
 target=HERE/'rush-for-villains-natural-voices.mp4'
 proc=subprocess.Popen([r.FFMPEG,'-y','-v','warning','-f','rawvideo','-pix_fmt','rgb24','-s','720x1280','-r',str(FPS),'-i','-',
 '-i',str(HERE/'audio/mix.wav'),'-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-preset','fast','-crf','19','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-t',str(DURATION),'-movflags','+faststart',str(target)],stdin=subprocess.PIPE)
 for i in range(round(FPS*DURATION)):
  proc.stdin.write(frame(i/FPS).tobytes())
  if i%(FPS*5)==0:print(f'Rivalry Reel {i//FPS}/{DURATION:.1f}s',flush=True)
 proc.stdin.close();assert proc.wait()==0
 bad=[dict(time=t,who=who,state=state,box=box) for t,who,state,box in BOUNDS if (box[0]<0 or box[2]>W or box[1]<0 or box[3]>1066) and not (7<=old_time(t)<7.65)]
 (HERE/'position-audit.json').write_text(json.dumps(dict(placements=len(BOUNDS),out_of_bounds=bad),indent=2))
 def stamp(t):
  ms=round(t*1000);h,ms=divmod(ms,3600000);m,ms=divmod(ms,60000);s,ms=divmod(ms,1000)
  return f'{h:02}:{m:02}:{s:02},{ms:03}'
 (HERE/'rush-for-villains-rivalry.en.srt').write_text('\n\n'.join(f'{i+1}\n{stamp(a)} --> {stamp(min(b,DURATION))}\n{who}: {s}' for i,(a,b,who,s) in enumerate(REAL_LINES))+'\n',encoding='utf-8')
 (HERE/'asset-manifest.json').write_text(json.dumps(sorted(r.ASSETS),indent=2),encoding='utf-8')
 print('Rivalry Reel complete',flush=True)
if __name__=='__main__':main()
