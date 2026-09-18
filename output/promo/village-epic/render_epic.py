"""Epic revision: matched environment plates, projected enemy shadows, persistent ruins."""
import sys,math,json,functools,subprocess,wave,argparse
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'village'))
import render_village as v
r=v.r;np=v.np;Image=v.Image;D=v.D
from PIL import ImageFilter,ImageEnhance
W,H,FPS=720,1280,30
@functools.lru_cache(None)
def plate(ruined):
 p=HERE/'assets'/('village-ruined.png' if ruined else 'village-peace.png')
 r.ASSETS.add(str(p.relative_to(r.ROOT)))
 return Image.open(p).convert('RGB').resize((W,H),Image.Resampling.LANCZOS)
def composite(im,layer):im.paste(Image.alpha_composite(im.convert('RGBA'),layer).convert('RGB'))
def contact(im,x,y,w):
 ww=math.ceil(w*1.3)+20;hh=36;layer=Image.new('RGBA',(ww,hh));d=D.Draw(layer)
 d.ellipse((ww/2-w*.55,12,ww/2+w*.55,23),fill=(12,15,22,105))
 layer=layer.filter(ImageFilter.GaussianBlur(4));im.paste(layer,(round(x-ww/2),round(y-16)),layer)
v.shadow=contact
v.tree=lambda *args,**kwargs:None
def dust(im,t,strength=1):
 layer=Image.new('RGBA',(180,320));d=D.Draw(layer)
 for i in range(17):
  x=(i*137+t*(12+i%4*4))%960-120;y=550+(i*67)%290-((t*7)%45)
  rr=42+i%4*23;d.ellipse(((x-rr)/4,(y-rr*.32)/4,(x+rr)/4,(y+rr*.32)/4),fill=(191,167,136,int(22*strength)))
 composite(im,layer.filter(ImageFilter.GaussianBlur(4)).resize((W,H),Image.Resampling.BILINEAR))
def world(t,broken=False,cast=True,close=False):
 ruined=t>=19 or broken;im=plate(ruined).copy()
 if ruined:dust(im,t,.8 if t<44 else .35)
 if cast:
  positions=[('MAVILI',124,685,51),('KUP KUZU',308,682,50),('KUP KUZU',373,731,56),('PINKY',531,718,56),('PINKY',441,669,45),('MAVILI',202,816,81)]
  for i,(who,x,y,h) in enumerate(positions):
   state='Idle';flip=False
   if 19<=t<24:
    vel=(-1 if i%2 else 1)*h*.75;x+=vel*min(3,t-19);x=max(30,min(680,x));state='Run';flip=vel<0
   elif ruined:
    state='Push' if t>50 and who=='MAVILI' else 'Idle'
   elif who=='MAVILI':
    phase=(t*h*.65+i*25)%90;flip=phase>=45;x+=phase if phase<45 else 90-phase;state='Walk'
   elif who=='KUP KUZU':state='Jump'
   else:state='Throw'
   v.friend(im,who,t+i,x,y,h,state,flip)
   if who=='MAVILI' and not ruined:v.basket(im,x+19,y-16)
 return im
v.village=world
def projected_shadow(im,t):
 """Perspective-warp original enemy alpha onto the path; no circular blob."""
 allmask=Image.new('L',(W,H));progress=r.ease((t-9.35)/2.75)
 for i,name in enumerate(['Demon_A','Black Knight_A','Blood Monster_A']):
  frames,_=r.anim(str(r.path_for(name,'Idle',True)));mask=frames[0].getchannel('A')
  # The feet stay outside bottom-right frame; the head advances over Pinky.
  shift=(1-progress)*650+i*65
  quad=[(245+shift,640+i*33),(540+shift,605+i*28),(910+shift,1150),(770+shift,1150)]
  src=[(0,0),(mask.width,0),(mask.width,mask.height),(0,mask.height)]
  matrix=[];values=[]
  for (x,y),(u,w) in zip(quad,src):
   matrix.extend([[x,y,1,0,0,0,-u*x,-u*y],[0,0,0,x,y,1,-w*x,-w*y]]);values.extend([u,w])
  coeff=np.linalg.solve(np.array(matrix),np.array(values))
  warped=mask.transform((W,H),Image.Transform.PERSPECTIVE,coeff,Image.Resampling.BICUBIC)
  from PIL import ImageChops
  allmask=ImageChops.lighter(allmask,warped)
 allmask=allmask.filter(ImageFilter.GaussianBlur(3.5)).point(lambda p:int(p*.68))
 shade=Image.new('RGBA',(W,H),(15,20,36,0));shade.putalpha(allmask);composite(im,shade)
def camera(im,zoom=1.08,cx=360,cy=680):return v.push(im,zoom,cx,cy)
@functools.lru_cache(None)
def vignette():
 yy,xx=np.mgrid[:H,:W];dist=((xx-360)/480)**2+((yy-650)/870)**2
 alpha=np.clip((dist-.35)*64,0,95).astype('uint8');layer=Image.new('RGBA',(W,H),(7,12,22,0));layer.putalpha(Image.fromarray(alpha));return layer
def finish(im,t):
 composite(im,vignette())
 if t<72:v.captions(im,t)
 if t<.6:im=Image.blend(Image.new('RGB',(W,H),'#12151F'),im,t/.6)
 return im
original_captions=v.captions
def quiet_caption(*args):pass
def legacy(t):
 v.captions=quiet_caption
 try:return v.frame(t)
 finally:v.captions=original_captions
def frame(t):
 if t<9:
  im=world(t)
  if t<4:v.friend(im,'PINKY',t,267+t*57,812,114,'Walk')
  elif t<7.25:v.friend(im,'PINKY',t,495,812,114,'Throw')
  else:v.sleep_pinky(im,12,495,812,114)
  im=camera(im,1.03+t*.012,400,625)
 elif t<14.8:
  im=world(9,cast=False);v.sleep_pinky(im,12,495,812,114)
  projected_shadow(im,t)
  im=camera(im,1.7+(t-9)*.025,483,752)
 elif t<19:
  # Sky/upper oak plate gives a consistent looking-up view from Pinky's position.
  im=plate(False).crop((0,0,720,475)).resize((720,1280),Image.Resampling.LANCZOS)
  im=ImageEnhance.Brightness(im).enhance(.72)
  v.enemy(im,'Blood Monster_A',t,360,624,270,True)
  v.enemy(im,'Demon_A',t,147,1080,520,True)
  v.enemy(im,'Black Knight_A',t,574,1100,540,True)
  im=camera(im,1+(t-14.8)*.045,360,693)
 elif t<25:
  # Impact-motivated cuts: wreckage first, fleeing villagers, then Pinky.
  im=world(t,True,True)
  v.enemy(im,'Black Knight_A',t,565-(t-19)*11,924,197,True)
  v.enemy(im,'Demon_A',t,665-(t-19)*13,795,132,True)
  v.friend(im,'PINKY',t,335,1030,173,'Idle',True)
  dust(im,t,2.4 if t<22 else 1)
  for i in range(13):
   age=max(0,t-19.25-i%3*.3);x=140+i*33+math.sin(i*3)*age*23;y=620+min(210,age*age*70)
   if age<2.2:D.Draw(im).polygon([(x,y),(x+12,y+5),(x+4,y+12)],fill='#85735B')
  zoom=1.12 if t<21.6 else 1.02
  shake=max(0,1-(t-19)/3)*5
  im=camera(im,zoom,360+math.sin(t*43)*shake,650+math.sin(t*37)*shake)
 elif t<29:
  im=world(t,True,False);v.friend(im,'PINKY',t,355,1015,196,'Push' if t<25.9 else 'Idle')
  im=camera(im,1.08+(t-25)*.038,355,846)
  v.text(im,'A HOME WORTH FIGHTING FOR',360,146,23,v.GOLD)
 elif t<31.5:
  im=world(t,True,False);v.friend(im,'PINKY',t,335+(t-29)*35,1035,265,'Walk' if t<30.8 else 'Idle')
  for at in [29.35,30.25]:
   age=t-at
   if 0<=age<.85:
    x=335+(at-29)*35;rad=25+age*200;layer=Image.new('RGBA',(W,H));d=D.Draw(layer)
    d.ellipse((x-rad,1035-rad*.19,x+rad,1035+rad*.19),outline=(255,213,128,int(255*(1-age/.85))),width=5);composite(im,layer.filter(ImageFilter.GaussianBlur(1)))
  im=camera(im,1.26,370,965)
 elif t<56:
  im=legacy(t)
  if 31.5<=t<36.9:
   v.panel(im,(70,70,650,139));v.text(im,'ONE WALK. MANY STEPS.',360,108,25)
   v.panel(im,(230,1009,490,1063));v.text(im,'Time passes…',360,1038,24)
  # Existing app UI remains pixel-exact; environment plate already contains ruins.
 elif t<62:
  im=world(t,True,False)
  for i,name in enumerate(['Demon_A','Black Knight_A','Blood Monster_A']):
   p=r.path_for(name,'Idle',True);frames,_=r.anim(str(p));sp=frames[0];sp=sp.resize((int(sp.width*63/sp.height),63),Image.Resampling.NEAREST)
   silhouette=Image.new('RGBA',sp.size,'#292F3F');silhouette.putalpha(sp.getchannel('A'));im.paste(silhouette,(320+i*68,358-i%2*19),silhouette)
  v.friend(im,'MAVILI',t,140,961,123);v.friend(im,'KUP KUZU',t,585,960,117)
  v.friend(im,'PINKY',t,352,1060,208,'Idle',t<58.5)
  im=camera(im,1.05+(t-56)*.016,355,650)
 else:im=legacy(t)
 return finish(im,t)

def make_audio():
 sr=48000;n=75*sr;music=np.zeros((n,2),np.float32);vocal=np.zeros_like(music);rng=np.random.default_rng(311)
 def add(dest,at,sig,gain=1,pan=0):
  a=int(at*sr);b=min(n,a+len(sig));sig=sig[:b-a]*gain;dest[a:b,0]+=sig*(1-pan*.35);dest[a:b,1]+=sig*(1+pan*.35)
 def chord(freq,duration,brass=False):
  tt=np.arange(int(sr*duration))/sr;sig=np.zeros(len(tt))
  for ratio in [1,1.25,1.5]:
   for harmonic in range(1,7):
    sig+=np.sin(math.tau*freq*ratio*harmonic*tt+.008*np.sin(tt*31))/(harmonic**(1.1 if brass else 1.7))
  env=np.minimum(1,tt/(.17 if brass else .4))*np.minimum(1,(duration-tt)/.5)
  return sig*env/5
 sections=[(0,9,76,[196,246.94,220,261.63],.065),(9,19,65,[98,103.83,92.5,98],.052),(19,29,98,[110,130.81,98,123.47],.105),(29,44,126,[146.83,174.61,196,220],.135),(44,56,82,[196,246.94,261.63,220],.085),(56,65,98,[146.83,164.81,174.61,196],.105),(65,75,126,[196,246.94,261.63,293.66],.15)]
 for start,end,bpm,roots,gain in sections:
  beat=60/bpm
  for j,at in enumerate(np.arange(start,end,beat*2)):
   freq=roots[j%4];add(music,at,chord(freq,min(beat*2.7,end-at),start>=29 and start!=44),gain)
   if 19<=start<44 or start>=56:
    for k in range(4):
     pos=at+k*beat/2
     if pos>=end:break
     ts=np.arange(int(sr*.28))/sr
     note=freq*[1,1.5,2,1.25][k];add(music,pos,np.sin(math.tau*note*2*ts)*np.exp(-ts*10)*np.minimum(1,ts*80),.045,(-1)**k*.6)
  if start in [19,29,56,65]:
   for at in np.arange(start,end,beat):
    ts=np.arange(int(sr*.5))/sr;drum=np.sin(math.tau*(45*ts+7*(1-np.exp(-ts*15))))*np.exp(-ts*10)
    add(music,at,drum,.16 if start in [29,65] else .10)
 # Silence before reveal, then heavy impacts, debris and rises.
 music[int(14.15*sr):int(14.8*sr)]*=.13
 for at in [14.8,19,20.1,21.6,29.35,30.25,37.4,39.7,42,65,68]:
  ts=np.arange(int(sr*.8))/sr;impact=(np.sin(math.tau*48*ts)+rng.normal(0,.22,len(ts)))*np.exp(-ts*8)
  add(music,at,impact,.22)
 for at in [19.05,20.15,21.65]:
  ts=np.arange(int(sr*1.4))/sr;add(music,at,rng.normal(0,1,len(ts))*np.exp(-ts*3),.055)
 for at,duration in [(12.6,1.4),(27,2),(34.6,1.7),(63,2)]:
  ts=np.arange(int(sr*duration))/sr;sig=rng.normal(0,1,len(ts))*np.sin(np.pi*ts/duration)**2;add(music,at,sig,.025)
 for at in [.5,1.5,3,6.5,8]:
  ts=np.arange(int(sr*.25))/sr;add(music,at,np.sin(math.tau*(1600*ts+1100*ts*ts))*np.sin(math.pi*ts/.25)**2,.021,.5)
 for at in [35.2,42.2,42.5]:
  ts=np.arange(int(sr*.6))/sr;add(music,at,np.sin(math.tau*1046.5*ts)*np.exp(-ts*7),.075)
 report=[]
 for i,(a,b,speaker,words) in enumerate(v.LINES):
  for k,who in enumerate(['MAVILI','KUP KUZU'] if speaker=='ALL' else [speaker]):
   p=v.HERE/'audio'/f'{i:02}_{who.replace(" ","_")}.mp3'
   raw=subprocess.check_output([r.FFMPEG,'-v','error','-i',str(p),'-af','silenceremove=start_periods=1:start_threshold=-48dB,areverse,silenceremove=start_periods=1:start_threshold=-48dB,areverse','-f','f32le','-ar',str(sr),'-ac','1','-'])
   sig=np.frombuffer(raw,dtype=np.float32).copy();dur=len(sig)/sr;assert a+dur<=b
   sig*=.68/max(.1,float(np.max(np.abs(sig))));add(vocal,a,sig,.65 if speaker=='ALL' else 1)
   music[int(max(0,a-.15)*sr):int((a+dur+.15)*sr)]*=.28
   report.append(dict(line=i,speaker=who,duration=dur,start=a,end=b,tempo=1))
 out=music+vocal;out*=.95/max(.95,float(np.max(np.abs(out))));out[-sr:]*=np.linspace(1,0,sr)[:,None]
 with wave.open(str(HERE/'mix.wav'),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr);f.writeframes((out*32767).astype('<i2').tobytes())
 (HERE/'timing-report.json').write_text(json.dumps(report,indent=2))
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--preview',action='store_true');args=parser.parse_args()
 moments=[3,8,9.4,10.7,12.5,16,19.6,22,27,30,35.5,40,43,49,54,58,63,66,69,73]
 sheet=Image.new('RGB',(1440,2160),'#151924')
 for i,t in enumerate(moments):
  x=i%5*288;y=i//5*540;sheet.paste(frame(t).resize((288,512)),(x,y));v.text(sheet,f'{t:g}s',x+144,y+525,17)
 sheet.save(HERE/'storyboard.jpg',quality=94);frame(73).resize((1080,1920),Image.Resampling.LANCZOS).save(HERE/'poster.png')
 if args.preview:return
 make_audio();path=HERE/'rush-for-villains-epic-v2-75s.mp4'
 proc=subprocess.Popen([r.FFMPEG,'-y','-v','warning','-f','rawvideo','-pix_fmt','rgb24','-s','720x1280','-r','30','-i','-','-i',str(HERE/'mix.wav'),'-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-preset','fast','-crf','18','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-t','75','-movflags','+faststart',str(path)],stdin=subprocess.PIPE)
 for i in range(2250):
  proc.stdin.write(frame(i/30).tobytes())
  if i%150==0:print(f'Epic render {i//30}/75s',flush=True)
 proc.stdin.close();assert proc.wait()==0
 (HERE/'asset-manifest.json').write_text(json.dumps(sorted(r.ASSETS),indent=2))
 print('Epic export complete',flush=True)
if __name__=='__main__':main()
