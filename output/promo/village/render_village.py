"""75-second original-sprite film. Procedural scenery, actual Flutter UI captures."""
import sys,math,json,subprocess,wave,functools,argparse
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent))
import render as r
from voices import LINES,VOICES
np=r.np;Image=r.Image;D=r.ImageDraw
W,H,FPS,SECONDS=720,1280,30,75
INK='#201D36';CREAM='#FFF5DF';GOLD='#FFE09B';PINK='#FFA0C4'
CAST={'PINKY':('Pinky','Pink_Monster'),'MAVILI':('Mavili','Dude_Monster'),'KUP KUZU':('Kupkuzu','Owlet_Monster')}
def asset(who,state='Idle'):
 folder,prefix=CAST[who];n={'Idle':4,'Walk':6,'Run':6,'Push':6,'Throw':4,'Jump':8}[state]
 return r.ROOT/'lib/Tutorial_Guy'/folder/f'{prefix}_{state}_{n}.gif'
old_reg=r.actor_registration
@functools.lru_cache(None)
def reg(path):
 for who,(folder,_) in CAST.items():
  if Path(path).parent.name==folder:
   _,_,b,_=r.source_anim(str(asset(who)));return (b[0]+b[2])/2,b[3],b[3]-b[1],b[2]-b[0]
 return old_reg(path)
r.actor_registration=reg
def clamp(x):return max(0,min(1,x))
def text(im,s,x,y,size=36,color=CREAM,width=640):r.fit_text(im,s,(x,y),size,width,color)
def panel(im,box,fill=INK):r.panel(im,box,fill,fill,20)
def actor(im,who,t,x,y,h=140,state='Idle',flip=False):
 r.sprite(im,asset(who,state),t,x,y,h,flip,shadow=False)
def shadow(im,x,y,w):D.Draw(im).ellipse((x-w/2,y-6,x+w/2,y+9),fill='#68967B')
def friend(im,who,t,x,y,h=140,state='Idle',flip=False):
 shadow(im,x,y,h*.72);actor(im,who,t,x,y,h,state,flip)
def enemy(im,name,t,x,y,h=240,flip=False):r.sprite(im,r.path_for(name,'Idle',True),t,x,y,h,flip,shadow=False)

@functools.lru_cache(None)
def sky():
 yy=np.linspace(0,1,H)[:,None,None];a=np.array([134,200,215])[None,None,:];b=np.array([255,235,192])[None,None,:]
 return Image.fromarray(np.repeat(a*(1-yy)+b*yy,W,axis=1).astype('uint8'))
def house(d,x,y,s,color):
 d.rounded_rectangle((x-s*.46,y-s*.7,x+s*.46,y),12,fill='#EDD4A5',outline='#AB987A',width=3)
 d.polygon([(x-s*.59,y-s*.65),(x,y-s*1.12),(x+s*.59,y-s*.65)],fill=color)
 d.line((x-s*.57,y-s*.66,x,y-s*1.1,x+s*.57,y-s*.66),fill='#F2C69C',width=5)
 d.rounded_rectangle((x-s*.13,y-s*.37,x+s*.13,y),10,fill='#715667')
 for dx in [-.3,.3]:
  d.rounded_rectangle((x+s*(dx-.07),y-s*.46,x+s*(dx+.07),y-s*.28),4,fill='#BCE0DD',outline='#A38372',width=3)
  d.line((x+s*dx,y-s*.46,x+s*dx,y-s*.28),fill='#FFF0C7',width=2)
def basket(im,x,y,spill=False):
 d=D.Draw(im);d.arc((x-19,y-36,x+19,y+2),180,360,fill='#825B47',width=4)
 d.polygon([(x-25,y-15),(x+25,y-15),(x+18,y+13),(x-18,y+13)],fill='#BA8A56')
 for dy in [-8,0,8]:d.line((x-19,y+dy,x+19,y+dy),fill='#D9B77A',width=2)
 for i in range(3):
  dx=i*14-14+(i*21 if spill else 0);dy=23 if spill else -17
  d.ellipse((x+dx-7,y+dy-7,x+dx+7,y+dy+7),fill=['#E78177','#E6B95D','#E7A596'][i])
def tree(im,x=585,y=1010):
 d=D.Draw(im)
 d.ellipse((x-170,y-14,x+124,y+20),fill='#7FAD86')
 d.polygon([(x-32,y),(x-19,y-450),(x+29,y-450),(x+53,y),(x+14,y-18)],fill='#8E7055')
 d.line((x+7,y-110,x+2,y-409),fill='#B28B64',width=8)
 for dx,dy,rr in [(-80,-418,120),(66,-453,132),(-34,-525,135),(123,-390,97),(-139,-365,88)]:
  d.ellipse((x+dx-rr,y+dy-rr,x+dx+rr,y+dy+rr),fill='#659B74')
  d.ellipse((x+dx-rr+12,y+dy-rr+10,x+dx+rr-21,y+dy+rr-44),fill='#88BA80')
def village(t,broken=False,cast=True,close=False):
 im=sky().copy();d=D.Draw(im);pan=18*math.sin(t*.13)
 d.ellipse((485,135,607,257),fill='#FFF0C0')
 for i in range(5):
  x=(i*219-t*2)%1050-160;y=185+i%3*58
  for dx,dy,rr in [(0,10,24),(28,0,34),(59,13,25)]:d.ellipse((x+dx-rr,y+dy-rr,x+dx+rr,y+dy+rr),fill='#F8F0D7')
 for i in range(4):
  x=i*340-160-pan*.4;d.ellipse((x,330+i%2*65,x+690,950),fill=['#A0BEA0','#ABC4A0'][i%2])
 d.rectangle((0,675,W,H),fill='#A8C592')
 d.polygon([(290,640),(410,640),(800,1280),(-210,1280)],fill='#DDC49D')
 d.line((290,640,-210,1280),fill='#EEDFBB',width=8)
 for i,(x,y,s,c) in enumerate([(95,645,160,'#A47879'),(338,606,127,'#AD907B'),(610,665,177,'#778E9E')]):house(d,x-pan,y,s,c)
 # Market and fences, with clear reversible damage.
 for x in [55,185]:d.rectangle((x,680,x+8,835),fill='#897052')
 if broken:
  d.polygon([(36,812),(169,835),(211,795),(74,776)],fill='#BC8292')
 else:
  d.polygon([(27,680),(185,680),(217,722),(7,722)],fill='#BC8292')
  for i in range(5):d.polygon([(30+i*31,680),(45+i*31,680),(64+i*31,722),(42+i*31,722)],fill='#F3D9B4')
 d.rectangle((38,798,194,822),fill='#B1966E')
 for x in range(385,700,42):
  if broken and x<520:d.line((x,812,x+33,842),fill='#D6C198',width=12)
  else:d.rounded_rectangle((x,764,x+11,840),4,fill='#EAD8AC')
 d.line((390 if not broken else 535,790,708,790),fill='#DCC69C',width=8)
 for i in range(45):
  x=(i*157+19)%720;y=708+(i*59)%536
  if abs(x-360)<(y-610)*.45:continue
  d.line((x,y,x-4,y-12),fill='#7A9C72',width=2)
  if i%2==0:d.ellipse((x-8,y-20,x+2,y-10),fill=['#ECAAB2','#FFF1C0','#D4B2D1'][i%3])
 if cast:
  for i,(who,x,y,h) in enumerate([('MAVILI',94,781,68),('KUP KUZU',305,765,67),('KUP KUZU',385,791,68),('PINKY',600,830,76),('PINKY',470,736,63),('MAVILI',210,904,93)]):
   moving=who=='MAVILI';phase=t+i
   if broken:
    x+=(-1 if i%2 else 1)*min(150,(t-19)*60);x=max(28,min(692,x));state='Run' if t<22 else 'Idle'
   else:
    if moving:
     cycle=(t*h*.67+i*25)%110;x+=cycle if cycle<55 else 110-cycle
    state='Walk' if moving else ('Throw' if who=='PINKY' else 'Jump')
   facing=(cycle>=55) if moving and not broken else i%2==1
   friend(im,who,phase,x,y,h,state,flip=facing)
   if moving and not broken:basket(im,x+25,y-25)
 basket(im,175,868,broken)
 if close:tree(im)
 return im

def sleep_pinky(im,t,x=397,y=1040,h=157):
 # Rest by rotating the unmodified original idle sprite as one rigid cutout.
 frames,_=r.anim(str(asset('PINKY')));sp=frames[0];sp=sp.resize((round(sp.width*h/sp.height),h),Image.Resampling.NEAREST).rotate(80,expand=True);sp=sp.crop(sp.getbbox())
 shadow(im,x,y,sp.width*.9);im.paste(sp,(round(x-sp.width/2),round(y-sp.height)),sp)
 if t<11:
  text(im,'z',x+100,y-115,24,'#FFF3D4');text(im,'z',x+119,y-148,18,'#FFF3D4')
def particles(im,t,x=360,y=720,color=GOLD,n=25,age=.5):
 d=D.Draw(im)
 for i in range(n):
  a=i*2.399;rad=(40+i%7*19)*age;xx=x+math.cos(a)*rad;yy=y+math.sin(a)*rad-age*50
  s=2+i%4;d.rectangle((xx-s,yy-s,xx+s,yy+s),fill=color)
def screen(im,name,box=(147,172,573,1040)):
 x,y,x2,y2=box
 path=HERE/'screens'/f'{name}.png';r.ASSETS.add(str(path.relative_to(r.ROOT)))
 src=load_screen(str(path));scale=min((x2-x)/src.width,(y2-y)/src.height);ww=round(src.width*scale);hh=round(src.height*scale)
 x+=((x2-x)-ww)//2;y+=((y2-y)-hh)//2;panel(im,(x-9,y-9,x+ww+9,y+hh+9),'#100E1C')
 src=src.resize((ww,hh),Image.Resampling.LANCZOS);im.paste(src,(x,y))
@functools.lru_cache(150)
def load_screen(path):return Image.open(path).convert('RGB')
def captions(im,t):
 row=next(((a,b,w,s) for a,b,w,s in LINES if a<=t<b),None)
 if not row:return
 a,b,who,s=row;rows=r.wrap(s.replace('...','…'),610,31)
 panel(im,(32,1100,688,1153+len(rows)*39))
 text(im,'VILLAGERS' if who=='ALL' else ('KÜP KUZU' if who=='KUP KUZU' else who),360,1124,15,PINK)
 for i,row in enumerate(rows):text(im,row,360,1161+i*39,31)
def push(im,zoom,cx=360,cy=650):
 ww=W/zoom;hh=H/zoom;left=max(0,min(W-ww,cx-ww/2));top=max(0,min(H-hh,cy-hh/2))
 return im.crop((round(left),round(top),round(left+ww),round(top+hh))).resize((W,H),Image.Resampling.NEAREST)
def frame(t):
 if t<9:
  im=village(t,close=True)
  if t<4:friend(im,'PINKY',t,150+t*62,1050,157,'Walk')
  elif t<7.4:friend(im,'PINKY',t,398,1050,157,'Throw')
  else:sleep_pinky(im,t)
  im=push(im,1+.07*t/9,390,700)
 elif t<14.8:
  im=village(9,cast=False,close=True);sleep_pinky(im,t)
  shade=Image.new('RGBA',(W,H));d=D.Draw(shade);v=clamp((t-9)/2.2)
  d.ellipse((820-v*870,480,1340-v*650,1180),fill=(38,31,64,115));im=Image.alpha_composite(im.convert('RGBA'),shade).convert('RGB')
  if t>11.3:text(im,'?',500,805,54,CREAM)
  im=push(im,1.5,445,940)
 elif t<19:
  im=sky().copy();d=D.Draw(im)
  # Worm's-eye composition: sky behind looming original enemy sprites.
  d.ellipse((-410,-640,260,490),fill='#81A778');d.ellipse((570,-220,1040,820),fill='#8BB583')
  enemy(im,'Demon_A',t,170,940,520,True)
  enemy(im,'Black Knight_A',t,553,961,530,True)
  enemy(im,'Blood Monster_A',t,378,645,310,True)
  im=push(im,1+clamp((t-14.8)/4.2)*.12,360,550)
 elif t<25:
  im=village(t,True,True,False)
  enemy(im,'Black Knight_A',t,590,987,220,True);enemy(im,'Demon_A',t,689,876,181,True)
  friend(im,'PINKY',t,345,1055,159,flip=True)
  for i in range(10):
   d=D.Draw(im);x=100+i*57;y=852+math.sin(t*2+i)*17;d.ellipse((x-17,y-9,x+17,y+9),fill='#D1BE9F')
 elif t<29:
  im=village(24,True,False,True);friend(im,'PINKY',t,356,1040,219,'Push' if t<26 else 'Idle')
  im=push(im,1.15,375,875)
 elif t<31.5:
  im=village(24,True,False)
  friend(im,'PINKY',t,345,1030,310,'Walk' if t<30.8 else 'Idle')
  for at in [29.35,30.25]:
   age=t-at
   if 0<=age<.8:
    d=D.Draw(im);rad=25+age*180;d.ellipse((345-rad,1030-rad*.22,345+rad,1030+rad*.22),outline=GOLD,width=5)
  im=push(im,1.25,350,990)
 elif t<36.9:
  im=village(t,False,False)
  name='steps-742' if t<33.3 else ('steps-891' if t<35.1 else 'steps-1000')
  screen(im,name,(166,153,554,993))
  text(im,'ONE WALK. MANY STEPS.',360,108,25,INK)
  text(im,'Time passes…',360,1038,24,INK)
  friend(im,'PINKY',t,74,1067,118,'Idle');friend(im,'MAVILI',t,651,1067,88)
 elif t<44:
  # Continuous real Flutter battle frames, interrupted by story reaction cuts.
  if 38.2<=t<39.0:
   im=village(t,True,False);friend(im,'PINKY',t,200+(t-38.2)*160,1030,219,'Walk');im=push(im,1.15,355,920)
  elif 40.8<=t<41.5:
   im=village(t,True,False);friend(im,'MAVILI',t,178,982,157);friend(im,'KUP KUZU',t,347,982,149);tree(im,602,1040)
  else:
   im=Image.new('RGB',(W,H),INK)
   elapsed=(t-36.9)-(.8 if t>=39 else 0)-(.7 if t>=41.5 else 0)
   idx=min(119,max(0,int(elapsed*30)))
   screen(im,f'combat-{idx:03}',(57,74,663,1074))
   friend(im,'PINKY',t,99,1042,105,'Throw' if t>41 else 'Idle')
   if t>42:particles(im,t,360,640,age=(t-42)%1)
 elif t<56:
  im=village(t,broken=t<51,cast=True)
  if t<45.15:
   enemy(im,'Demon_A',t,555+(t-44)*160,962,179)
   particles(im,t,580,868,age=(t-44)*1.6)
  friend(im,'PINKY',t,362,1049,180,'Throw' if 52.3<t<55.7 else 'Idle')
  x=75+min(100,max(0,t-46.5)*72);friend(im,'MAVILI',t,x,1029,143,'Run' if 46.5<t<47.9 else 'Idle')
  x=625-min(90,max(0,t-44.7)*58);friend(im,'KUP KUZU',t,x,1029,133,'Walk' if 44.7<t<46.25 else 'Idle',True)
  if 49.7<t<52:particles(im,t,360,720,age=(t-49.7)*.7)
 elif t<62:
  im=village(t,False,False,False)
  for i,name in enumerate(['Demon_A','Black Knight_A','Blood Monster_A']):
   p=r.path_for(name,'Idle',True);frames,_=r.anim(str(p));sp=frames[0];sp=sp.resize((int(sp.width*65/sp.height),65),Image.Resampling.NEAREST)
   silhouette=Image.new('RGBA',sp.size,'#595A68');silhouette.putalpha(sp.getchannel('A'));im.paste(silhouette,(442+i*74,367-i%2*30),silhouette)
  friend(im,'PINKY',t,359,1050,224,'Idle',flip=t<58.7)
  friend(im,'MAVILI',t,115,983,111);friend(im,'KUP KUZU',t,599,983,110)
  im=push(im,1+clamp((t-56)/6)*.12,363,779)
 elif t<65:
  im=village(t,False,False);screen(im,'steps-1000',(310,181,675,971))
  friend(im,'PINKY',t,152,1035,217,'Throw')
 elif t<68:
  im=village(t,False,True)
  for who,x,y,h in [('MAVILI',55,985,150),('KUP KUZU',285,944,144),('PINKY',230,1060,202)]:friend(im,who,t,x+(t-65)*h*.67,y,h,'Walk')
 else:
  im=village(68,False,False)
  veil=Image.new('RGB',(W,H),INK);im=Image.blend(im,veil,.7)
  text(im,'RUSH FOR',360,222,66);text(im,'VILLAINS',360,302,88,GOLD)
  icon_path=r.ROOT/'lib/Start/Icon.png';r.ASSETS.add(str(icon_path.relative_to(r.ROOT)))
  icon=Image.open(icon_path).convert('RGBA');icon.thumbnail((160,160),Image.Resampling.LANCZOS);im.paste(icon,(360-icon.width//2,388),icon)
  for who,x,y,h in [('MAVILI',171,772,159),('KUP KUZU',553,772,153),('PINKY',362,839,223)]:friend(im,who,0 if t>=72 else t,x,y,h,'Idle' if t>=72 else 'Throw')
  text(im,'WALK. FIGHT. LEVEL UP.',360,922,36,GOLD)
  text(im,'Your next walk could',360,1000,28);text(im,'be an adventure.',360,1039,28)
  if t<72:particles(im,t,360,532,age=.9)
 if t<72:captions(im,t)
 if t<.45:im=Image.blend(Image.new('RGB',(W,H),INK),im,t/.45)
 return im

def audio():
 sr=48000;n=sr*SECONDS;music=np.zeros((n,2),np.float32);vocal=np.zeros_like(music);rng=np.random.default_rng(25)
 def add(dest,at,sig,gain=1,pan=0):
  a=int(at*sr);b=min(n,a+len(sig));s=sig[:b-a]*gain;dest[a:b,0]+=s*(1-pan*.4);dest[a:b,1]+=s*(1+pan*.4)
 # Five original musical moods, with dialogue ducking.
 for start,end,bpm,roots,gain in [(0,9,84,[261.63,329.63,392,293.66],.07),(9,29,76,[164.81,174.61,155.56,146.83],.045),(29,44,126,[196,246.94,293.66,329.63],.10),(44,56,92,[261.63,329.63,392,349.23],.065),(56,65,92,[196,220,246.94,293.66],.06),(65,75,126,[261.63,329.63,392,523.25],.1)]:
  beat=60/bpm
  for j in range(int((end-start)/beat)):
   at=start+j*beat;freq=roots[(j//4)%4];ts=np.arange(int(sr*.65))/sr
   tone=(np.sin(math.tau*freq*ts)+.35*np.sin(math.tau*freq*2*ts))*np.exp(-ts*5)*np.minimum(1,ts*60)
   add(music,at,tone,gain,(-1)**j*.3)
   add(music,at+beat*.5,np.sin(math.tau*freq*1.5*ts)*np.exp(-ts*8),gain*.45)
   if 29<=at<44 or at>=65:
    tt=np.arange(int(sr*.19))/sr;add(music,at,np.sin(math.tau*(54*tt+5*(1-np.exp(-tt*35))))*np.exp(-tt*24),.11)
 # Breeze and birds cease as the shadow arrives.
 noise=rng.normal(0,1,n).astype(np.float32);breeze=np.convolve(noise[:9*sr],np.ones(85)/85,mode='same');add(music,0,breeze,.06)
 for at in [.4,1.7,2.25,5.1,7.7]:
  tt=np.arange(int(sr*.22))/sr;add(music,at,np.sin(math.tau*(1700*tt+1400*tt*tt))*np.sin(math.pi*tt/.22)**2,.022,.6)
 for at in [19.4,20.4,21.1,29.35,30.25,37.8,39.8,41.7]:
  tt=np.arange(int(sr*.22))/sr;add(music,at,(rng.uniform(-1,1,len(tt))*.25+np.sin(math.tau*85*tt))*np.exp(-tt*24),.14)
 for at in [35.2,42.2,42.45,42.7]:
  tt=np.arange(int(sr*.45))/sr;add(music,at,np.sin(math.tau*1046.5*tt)*np.exp(-tt*9),.1)
 report=[]
 for i,(start,end,speaker,words) in enumerate(LINES):
  for k,who in enumerate(['MAVILI','KUP KUZU'] if speaker=='ALL' else [speaker]):
   path=HERE/'audio'/f'{i:02}_{who.replace(" ","_")}.mp3'
   raw=subprocess.check_output([r.FFMPEG,'-v','error','-i',str(path),'-af','silenceremove=start_periods=1:start_threshold=-48dB,areverse,silenceremove=start_periods=1:start_threshold=-48dB,areverse','-f','f32le','-ar',str(sr),'-ac','1','-'])
   sig=np.frombuffer(raw,dtype=np.float32).copy();duration=len(sig)/sr
   assert duration<=end-start, f'Line {i}: {duration:.2f}s exceeds {end-start:.2f}s; move timing, never accelerate.'
   sig*=.68/max(.1,float(np.max(np.abs(sig))));add(vocal,start,sig,.65 if speaker=='ALL' else 1,(-.6 if k==0 else .6) if speaker=='ALL' else 0)
   music[int(start*sr):int((start+duration)*sr)]*=.24
   report.append(dict(line=i,speaker=who,duration=duration,start=start,end=end,tempo=1.0))
 out=music+vocal;out*=.95/max(.95,float(np.max(np.abs(out))));out[-sr:]*=np.linspace(1,0,sr)[:,None]
 with wave.open(str(HERE/'audio/mix.wav'),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr);f.writeframes((out*32767).astype('<i2').tobytes())
 (HERE/'audio/timing-report.json').write_text(json.dumps(report,indent=2))
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--preview',action='store_true');args=parser.parse_args()
 moments=[1.8,5,8,12.5,16,21,27,30,32.6,35.7,37.5,40,43,46,50,54,58,63,66,73]
 sheet=Image.new('RGB',(1440,4*540),INK)
 for i,t in enumerate(moments):
  fr=frame(t).resize((288,512));x=i%5*288;y=i//5*540;sheet.paste(fr,(x,y));text(sheet,f'{t:g}s',x+144,y+525,17)
 sheet.save(HERE/'storyboard.jpg',quality=93);frame(73).resize((1080,1920)).save(HERE/'poster.png')
 if args.preview:return
 audio()
 cmd=[r.FFMPEG,'-y','-v','warning','-f','rawvideo','-pix_fmt','rgb24','-s','720x1280','-r','30','-i','-','-i',str(HERE/'audio/mix.wav'),'-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-preset','fast','-crf','19','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-t','75','-movflags','+faststart',str(HERE/'rush-for-villains-village-75s.mp4')]
 proc=subprocess.Popen(cmd,stdin=subprocess.PIPE)
 for i in range(FPS*SECONDS):
  proc.stdin.write(frame(i/FPS).tobytes())
  if i%150==0:print(f'Render {i//FPS}/75 seconds',flush=True)
 proc.stdin.close();assert proc.wait()==0
 def stamp(t):
  ms=round(t*1000);s,ms=divmod(ms,1000);m,s=divmod(s,60);return f'00:{m:02}:{s:02},{ms:03}'
 (HERE/'dialogue.en.srt').write_text('\n\n'.join(f'{i+1}\n{stamp(a)} --> {stamp(b)}\n{s}' for i,(a,b,w,s) in enumerate(LINES))+'\n',encoding='utf-8')
 (HERE/'asset-manifest.json').write_text(json.dumps(sorted(r.ASSETS),indent=2))
 print('Video complete',flush=True)
if __name__=='__main__':main()
