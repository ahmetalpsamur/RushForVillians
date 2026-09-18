"""Community-first 76-second Reel; original cast, no fabricated account links."""
import sys,json,math,functools,subprocess,wave,argparse
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent));sys.path.insert(0,str(HERE.parent/'story'))
import render as r
import render_story as game
from voices import LINES,VOICES
np=r.np;Image=r.Image;D=r.ImageDraw
W,H,FPS,DURATION=720,1280,30,76
INK='#241D3C';WHITE='#FFF9EE';GOLD='#FFE48D';PINK='#FF93C7';BLUE='#8FD7FF';MINT='#AEF0D4'
COLORS={'PINKY':PINK,'MAVILI':BLUE,'KÜP KUZU':GOLD,'ALL':MINT}
CAST={'PINKY':('Pinky','Pink_Monster'),'MAVILI':('Mavili','Dude_Monster'),'KÜP KUZU':('Kupkuzu','Owlet_Monster')}
VOICE_DURATIONS={};NOW=0;AUDIT=False;BOUNDS=[]
original_registration=r.actor_registration
game.subtitles=lambda im,t:None

def asset(who,state='Idle'):
 folder,prefix=CAST[who]
 return r.ROOT/'lib/Tutorial_Guy'/folder/f'{prefix}_{state}_{dict(Idle=4,Run=6,Walk=6,Throw=4,Push=6,Jump=8)[state]}.gif'

@functools.lru_cache(None)
def registration(path):
 pp=Path(path)
 for who,(folder,_) in CAST.items():
  if pp.parent.name==folder and 'Tutorial_Guy' in pp.parts:
   _,_,box,_=r.source_anim(str(asset(who)))
   return (box[0]+box[2])/2,box[3],box[3]-box[1],box[2]-box[0]
 return original_registration(path)
r.actor_registration=registration

def text(im,s,x,y,size=38,color=WHITE,width=620):r.fit_text(im,s,(x,y),size,width,color)
def panel(im,box,fill=INK,outline=None,radius=25):r.panel(im,box,fill,outline or fill,radius)
def active(t):return next(((i,a,b,who,s) for i,(a,b,who,s) in enumerate(LINES) if a<=t<b),None)

def sprite(im,path,t,x,y,h,flip=False):
 if AUDIT:
  frames,durations=r.anim(str(path));phase=t%sum(durations);idx=0
  while idx<len(frames)-1 and phase>=durations[idx]:phase-=durations[idx];idx+=1
  sp,pos,_=r.sprite_placement(path,idx,x,y,h,flip);box=sp.getbbox()
  if box:BOUNDS.append((round(NOW,3),Path(path).name,[pos[k%2]+box[k] for k in range(4)]))
 r.sprite(im,path,t,x,y,h,flip)

def friend(im,who,t,x,y,h,state='Idle',flip=False):sprite(im,asset(who,state),t,x,y,h,flip)

@functools.lru_cache(None)
def backdrop(warm=False):
 yy,xx=np.mgrid[0:H,0:W];v=np.exp(-((xx-360)**2/450**2+(yy-520)**2/680**2))
 if warm:
  a=np.stack([245+v*10,223+v*15,204+v*19],axis=2).astype(np.uint8)
 else:
  a=np.stack([31+v*38,23+v*22,55+v*48],axis=2).astype(np.uint8)
 im=Image.fromarray(a);d=D.Draw(im)
 d.ellipse((-190,820,910,1560),fill='#E6CFC0' if warm else '#3E2D61')
 d.ellipse((-140,830,860,1180),outline='#D9B1B4' if warm else '#695183',width=2)
 return im

def background(t,warm=False):
 im=backdrop(warm).copy();d=D.Draw(im)
 for i in range(18):
  x=(i*133+t*(3+i%3))%760-20;y=158+(i*157-t*10)%820
  color=['#AC88B5','#92749D','#AD94B2'][i%3] if not warm else ['#C98B9E','#E6AD79','#9AB3A4'][i%3]
  if i%3==0:
   d.line((x-4,y,x+4,y),fill=color,width=2);d.line((x,y-4,x,y+4),fill=color,width=2)
  else:d.ellipse((x,y,x+3,y+3),fill=color)
 text(im,'RUSH FOR VILLAINS',360,99,20,INK if warm else '#CEC0E2')
 return im

def heading(im,first,second='',warm=False,y=217,size=63):
 text(im,first,360,y,size,INK if warm else WHITE)
 if second:text(im,second,360,y+size+15,size,'#A23F76' if warm else PINK)

def label(im,s,x,y,width=270,color=MINT):
 panel(im,(x-width/2,y-27,x+width/2,y+27),color,radius=13)
 text(im,s,x,y,21,INK,width-18)

def trio(im,t,y=991,height=213,celebrate=False):
 talking=active(t);speaker=talking[3] if talking else None
 for who,x in [('MAVILI',145),('PINKY',360),('KÜP KUZU',575)]:
  state='Jump' if celebrate else ('Throw' if who==speaker else 'Idle')
  friend(im,who,t,x,y,height+(12 if who=='PINKY' else 0),state)
  if speaker in (who,'ALL'):
   D.Draw(im).ellipse((x-7,y-height-46,x+7,y-height-32),fill=COLORS[who])

def captions(im,t):
 row=active(t)
 if row is None:return
 i,a,b,who,s=row
 if i==3:return # Pinky's short laugh is acting, not an extra instruction.
 chunks={0:['Hey, adventurers!','We have something REALLY exciting','to tell you!'],
 4:['Rush for Villains is currently','in Closed Beta on Android!'],
 5:['And right now, we need more','adventurers to join us!'],
 7:['With enough support and testers,','we can complete this stage','and get closer to bringing','Rush for Villains to everyone!'],
 16:['So help us bring Rush for Villains','to both Android and iOS!']}.get(i,[s])
 span=VOICE_DURATIONS.get(i,b-a);elapsed=max(0,t-a);total=sum(len(c.split()) for c in chunks);cursor=0
 for part in chunks:
  cursor+=len(part.split())/total*span;s=part
  if elapsed<cursor:break
 rows=r.wrap(s,590,31);top=1073
 panel(im,(34,top,686,1120+len(rows)*42),INK,'#8C698F',22)
 r.txt(im,'ALL THREE' if who=='ALL' else who,(55,top+24),16,COLORS[who],anchor='lm')
 for j,row in enumerate(rows):text(im,row,360,top+62+j*42,31)

def heart(im,x,y,size,color):
 d=D.Draw(im);s=size
 d.ellipse((x-s,y-s,x,y),fill=color);d.ellipse((x,y-s,x+s,y),fill=color)
 d.polygon([(x-s,y-s/2),(x+s,y-s/2),(x,y+s*.9)],fill=color)

def game_phone(im,t):
 x,y,w,h=202,354,316,552
 panel(im,(x-9,y-9,x+w+9,y+h+9),'#0A0A17','#A79ABF',32)
 u=t-9.4
 if u<1.1:
  shot=Image.open(HERE.parent/'story/screens/adventure.png').convert('RGB')
 elif u<3.0:shot=game.frame(11.4+(u-1.1)*1.2)
 elif u<5.1:shot=game.frame(20.55+(u-3))
 elif u<6.4:shot=game.frame(24.0+u-5.1)
 else:shot=game.montage(game.world(34),33.4)
 shot=shot.resize((w-20,h-20),Image.Resampling.LANCZOS);im.paste(shot,(x+10,y+10))
 panel(im,(x+w*.36,y+8,x+w*.64,y+18),'#080911',radius=5)

def community(im,t):
 n=min(10,max(2,int((t-20)*1.35)+2))
 classes=['Archer','Knight','Wizard','Swordsman','Priest','Soldier','Armored Axeman','Knight Templar','Archer','Wizard']
 for i in range(n):
  row=i//5;x=93+(i%5)*128;y=651+row*118
  sprite(im,r.path_for(classes[i]),t+i,x,y,79)

def profile(im,t):
 # Deliberately generic: no invented handle, follower count, URL, or account connection.
 panel(im,(87,256,633,746),'#FFFCF7','#E0C8D4',30)
 text(im,'Instagram',360,297,25,INK)
 D.Draw(im).ellipse((116,327,236,447),fill='#EFD3E8',outline='#B26CAA',width=3)
 friend(im,'PINKY',t,176,427,73)
 text(im,'Rush for Villains',425,362,29,INK,325)
 text(im,'Game · Community',423,408,18,'#766678',325)
 for j,s in enumerate(['Turn your walks into adventures.','Android Closed Beta','Help us build what comes next.']):text(im,s,360,483+j*34,23 if j!=1 else 25,INK)
 pulse=3+int(2*(1+math.sin(t*6)))
 r.panel(im,(113,619,607,711),GOLD,'#B4528C',18,pulse)
 text(im,'LINKS IN BIO',360,649,29,INK)
 text(im,'Closed Beta · Join here',360,684,21,INK)
 # Animated arrow highlights the exact bio link block.
 d=D.Draw(im);x=630;y=662
 d.line((685,565,685,y,x,y),fill=PINK,width=8)
 d.polygon([(x-5,y),(x+15,y-13),(x+15,y+13)],fill=PINK)
 for j,(a,b) in enumerate([('INSTAGRAM','BIO'),('CLOSED','BETA'),('JOIN THE','ADVENTURE')]):
  x=120+j*240
  panel(im,(x-97,792,x+97,876),MINT if j==2 else '#4A355D','#8D729F',15)
  text(im,a,x,818,19,INK if j==2 else WHITE,177);text(im,b,x,851,21,INK if j==2 else WHITE,177)
  if j<2:text(im,'→',x+119,834,27,GOLD)

def final_card(im,t):
 r.logo(im,218,.88)
 panel(im,(58,359,662,464),MINT,radius=19)
 text(im,'ANDROID CLOSED BETA',360,395,33,INK)
 text(im,'AVAILABLE NOW',360,436,27,INK)
 text(im,'HELP US REACH',360,514,24)
 text(im,'ANDROID + iOS',360,561,43,GOLD)
 trio(im,t,y=861,height=174,celebrate=65<=t<68.1)
 panel(im,(47,914,673,1050),GOLD,radius=20)
 text(im,'JOIN THROUGH THE LINKS',360,951,30,INK)
 text(im,'IN OUR INSTAGRAM BIO',360,1007,33,INK)

def frame(t):
 global NOW
 NOW=t
 warm=41<=t<55
 im=background(t,warm)
 if t<9.4:
  heading(im,'HEY,','ADVENTURERS!',y=218,size=63)
  if t<4.8:
   v=r.ease(t/.9);friend(im,'PINKY',t,360,995,145+115*v,'Run' if t<.9 else 'Throw')
  else:
   friend(im,'PINKY',t,360,995,230,'Jump' if t>8.5 else 'Idle')
   v=r.ease((t-4.8)/.6);friend(im,'MAVILI',t,-95+240*v,995,210,'Run' if v<1 else 'Throw')
   if t>=6.35:
    v=r.ease((t-6.35)/.6);friend(im,'KÜP KUZU',t,815-240*v,995,210,'Run' if v<1 else 'Throw',flip=v<1)
  label(im,'WE HAVE NEWS!',360,472,278,GOLD)
 elif t<17.7:
  heading(im,'ANDROID',y=177,size=54);text(im,'CLOSED BETA',360,238,52,PINK)
  label(im,'AVAILABLE NOW',360,302,257,MINT)
  game_phone(im,t)
  for who,x in [('MAVILI',116),('PINKY',360),('KÜP KUZU',604)]:
   friend(im,who,t,x,1045,115,'Throw' if who==(active(t)[3] if active(t) else None) else 'Idle')
 elif t<30.8:
  if t<19.8:
   heading(im,'YEP.','THAT MEANS YOU!',y=218,size=59)
   friend(im,'KÜP KUZU',t,360,992,291,'Throw')
   friend(im,'PINKY',t,121,1020,119);friend(im,'MAVILI',t,600,1020,119)
  elif t<27.9:
   heading(im,'YOUR SUPPORT','MATTERS.',y=205,size=56)
   text(im,'Help us take the next step.',360,402,29)
   community(im,t);trio(im,t,y=1039,height=171)
  else:
   text(im,'OUR FULL LAUNCH GOAL',360,230,34,GOLD)
   for x,label_,when in [(193,'Android',27.9),(527,'iOS',29.1)]:
    panel(im,(x-141,331,x+141,495),'#423154','#A88AAF',23)
    if t>=when:text(im,label_,x,413,49,WHITE,264)
   text(im,'+',360,412,41,PINK)
   text(im,'YOUR SUPPORT HELPS US GET THERE.',360,584,24)
   trio(im,t,celebrate=True)
 elif t<41:
  heading(im,'HOW TO JOIN',y=184,size=53)
  profile(im,t)
  for who,x in [('MAVILI',145),('PINKY',360),('KÜP KUZU',575)]:friend(im,who,t,x,1040,132,'Throw')
 elif t<55:
  heading(im,'THANK YOU,','ADVENTURERS.',True,y=218,size=58)
  if t<50.2:
   text(im,'YOU’RE HELPING US BUILD IT.',360,456,28,INK)
   for i in range(7):heart(im,100+i*88,610+math.sin(t*1.5+i)*38,12+4*(i%2),['#CB7197','#D59963','#8FA891'][i%3])
  else:
   label(im,'FULL LAUNCH GOAL',360,467,340,PINK)
   text(im,'Android + iOS',360,551,43,INK)
  trio(im,t,y=1008,height=224)
 elif t<59:
  k=min(7,int((t-55)*2));u=(t-55)%0.5
  if k==0:im=game.frame(11.0+u)
  elif k==1:im=game.frame(14.4+u)
  elif k==2:im=game.montage(game.world(t),33.8)
  elif k==3:im=game.frame(20.6+u)
  elif k==4:im=game.frame(23.7+u)
  elif k==5:im=game.frame(26.0+u)
  elif k==6:im=game.montage(game.world(t),33.4)
  else:im=background(t);trio(im,t,celebrate=True)
  label(im,'ANDROID CLOSED BETA',360,112,468,MINT)
 elif t<65:
  r.logo(im,233,.91)
  line='JOIN THE CLOSED BETA!' if t<61 else ('HELP US GROW!' if t<62.55 else 'JOIN THE ADVENTURE!')
  text(im,line,360,490,43,MINT)
  label(im,'LINKS IN OUR INSTAGRAM BIO',360,615,574,GOLD)
  trio(im,t,y=1033,height=215)
 else:final_card(im,t)
 captions(im,t)
 if t<.22:im=Image.blend(Image.new('RGB',(W,H),INK),im,t/.22)
 for cut in [9.4,17.7,30.8,41,55,59,65]:
  if 0<=t-cut<.09:im=Image.blend(im,Image.new('RGB',(W,H),GOLD),.13*(1-(t-cut)/.09))
 return im

def audio():
 sr=48000;n=sr*DURATION;music=np.zeros((n,2),np.float32);vocal=np.zeros_like(music);rng=np.random.default_rng(81)
 def add(dest,at,sig,gain=1,pan=0):
  if at>=DURATION:return
  a=int(at*sr);b=min(n,a+len(sig));sig=sig[:b-a]*gain
  dest[a:b,0]+=sig*(1-pan*.35);dest[a:b,1]+=sig*(1+pan*.35)
 beat=60/140
 for j in range(math.ceil(DURATION/beat)):
  at=j*beat;root=[130.81,164.81,174.61,146.83][(j//8)%4];warm=41<=at<55;level=.43 if warm else .8
  ts=np.arange(int(sr*.25))/sr
  if not warm:
   add(music,at,np.sin(math.tau*(48*ts+7*(1-np.exp(-ts*24))))*np.exp(-ts*24),.10*level)
   if j%2:add(music,at,rng.uniform(-1,1,len(ts))*np.exp(-ts*30),.035*level)
  add(music,at,np.sin(math.tau*root*ts)*np.exp(-ts*9)*np.minimum(1,ts*130),.05*level)
  for k in range(2):
   tt=np.arange(int(sr*.25))/sr;f=root*4*[1,1.25,1.5,2][(j+k)%4]
   bell=(np.sin(math.tau*f*tt)+.18*np.sin(math.tau*2*f*tt))*np.exp(-tt*14)*np.minimum(1,tt*180)
   add(music,at+k*beat/2,bell,.028*level,(-1)**j*.4)
 for at in [9.4,17.7,29.1,30.8,41,55,59,65]:
  ts=np.arange(int(sr*.20))/sr;add(music,at,rng.uniform(-1,1,len(ts))*np.sin(math.pi*ts/.20)**2,.065)
 report=[]
 for i,(start,end,speaker,wording) in enumerate(LINES):
  speakers=list(VOICES) if speaker=='ALL' else [speaker];longest=0
  for k,who in enumerate(speakers):
   suffix='_'+who.lower().replace(' ','_') if speaker=='ALL' else ''
   dest=HERE/'audio'/f'voice_{i:02}{suffix}.mp3'
   raw=subprocess.check_output([r.FFMPEG,'-v','error','-i',str(dest),'-af','silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse','-f','f32le','-ar',str(sr),'-ac','1','-'])
   source=np.frombuffer(raw,dtype=np.float32);dur=len(source)/sr;tempo=max(1,dur/(end-start-.06))
   fitted=subprocess.check_output([r.FFMPEG,'-v','error','-f','f32le','-ar',str(sr),'-ac','1','-i','-','-af',f'atempo={tempo:.8f}','-f','f32le','-'],input=raw)
   sig=np.frombuffer(fitted,dtype=np.float32).copy();sig*=.72/max(.1,float(np.max(np.abs(sig))))
   fade=min(180,len(sig)//4);sig[:fade]*=np.linspace(0,1,fade);sig[-fade:]*=np.linspace(1,0,fade)
   add(vocal,start,sig,.48 if speaker=='ALL' else 1,(k-1)*.6 if speaker=='ALL' else 0)
   longest=max(longest,len(sig)/sr)
   report.append({'line':i+1,'speaker':who,'text':wording,'start':start,'end':end,'source_seconds':round(dur,3),'tempo':round(tempo,3),'fitted_seconds':round(len(sig)/sr,3)})
   if tempo>1.23:print(f'PACE REVIEW line {i+1} {who}: {tempo:.3f}',flush=True)
  VOICE_DURATIONS[i]=longest
  a=int(start*sr);b=min(n,a+int(longest*sr));music[a:b]*=.24
 out=music+vocal;out*=.94/max(.94,float(np.max(np.abs(out))));out[-sr:]*=np.linspace(1,0,sr)[:,None]
 with wave.open(str(HERE/'audio/mix.wav'),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr);f.writeframes((out*32767).astype('<i2').tobytes())
 (HERE/'audio/timing-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')

def main():
 global AUDIT
 parser=argparse.ArgumentParser();parser.add_argument('--preview',action='store_true');parser.add_argument('--audit',action='store_true');args=parser.parse_args()
 if not args.preview:audio()
 moments=[2,5.7,7.6,10.8,15.3,18.5,24,29.6,33.3,39.5,43.3,48.8,53.5,61.5,72]
 sheet=Image.new('RGB',(1080,1230),INK)
 for i,t in enumerate(moments):
  fr=frame(t).resize((216,384),Image.Resampling.LANCZOS);x=i%5*216;y=i//5*410;sheet.paste(fr,(x,y));r.txt(sheet,f'{t:.1f}s',(x+108,y+397),15)
 sheet.save(HERE/'storyboard.jpg',quality=96);frame(72).resize((1080,1920),Image.Resampling.LANCZOS).save(HERE/'poster.png')
 if args.preview:return
 AUDIT=args.audit
 path=HERE/'rush-for-villains-android-beta-community.mp4'
 proc=subprocess.Popen([r.FFMPEG,'-y','-v','warning','-f','rawvideo','-pix_fmt','rgb24','-s','720x1280','-r',str(FPS),'-i','-',
  '-i',str(HERE/'audio/mix.wav'),'-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-preset','fast','-crf','19','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-t',str(DURATION),'-movflags','+faststart',str(path)],stdin=subprocess.PIPE)
 for i in range(FPS*DURATION):
  proc.stdin.write(frame(i/FPS).tobytes())
  if i%(FPS*4)==0:print(f'Community Reel {i//FPS}/{DURATION}s',flush=True)
 proc.stdin.close();assert proc.wait()==0
 if AUDIT:
  bad=[{'time':t,'asset':name,'box':box} for t,name,box in BOUNDS if (box[0]<0 or box[2]>W or box[1]<0 or box[3]>1066) and not (4.8<=t<5.4 or 6.35<=t<6.95)]
  (HERE/'position-audit.json').write_text(json.dumps({'placements':len(BOUNDS),'out_of_bounds':bad},indent=2))
 def stamp(t):
  ms=round(t*1000);hours,ms=divmod(ms,3600000);minutes,ms=divmod(ms,60000);seconds,ms=divmod(ms,1000)
  return f'{hours:02}:{minutes:02}:{seconds:02},{ms:03}'
 srt='\n\n'.join(f'{i+1}\n{stamp(a)} --> {stamp(b)}\n{who}: {s}' for i,(a,b,who,s) in enumerate(LINES))
 # General timestamp helper supports the longer community cut.
 (HERE/'rush-for-villains-community.en.srt').write_text(srt+'\n',encoding='utf-8')
 (HERE/'asset-manifest.json').write_text(json.dumps(sorted(r.ASSETS),indent=2),encoding='utf-8')
 print('Community Reel complete',flush=True)
if __name__=='__main__':main()
