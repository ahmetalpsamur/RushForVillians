"""Deterministic 38-second vertical trailer using only the project's character art.
Run with Python 3.13; Pillow plus dependencies in tools/. No game files are changed.
"""
import sys, math, json, subprocess, wave, functools, argparse
from pathlib import Path
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE/'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageSequence, ImageFilter
import imageio_ffmpeg
from voice import LINES

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
W, H, FPS, DURATION = 720, 1280, 30, 38
PINK = '#FF80BC'; GOLD = '#FFE58A'; WHITE = '#FFF8F0'; MINT = '#A9FFCE'
INK = '#13111C'; MUTED = '#B6A9CB'
CLASS = ROOT/'lib/All_Assets/Avatars/Classes/Characters(100x100 split)'
ENEMY = ROOT/'lib/All_Assets/Enemies/Characters(100x100 split)'
PINKY = ROOT/'lib/Tutorial_Guy/Pinky'
ASSETS = set()
VOICE_DURATIONS = {}
VIDEO_NAME = 'rush-for-villains-38s-fixed.mp4'
VOICE_TRIM_FILTER = 'silenceremove=start_periods=1:start_threshold=-45dB:stop_periods=-1:stop_duration=0.15:stop_threshold=-45dB'

@functools.lru_cache(None)
def font(size, bold=True):
    return ImageFont.truetype('C:/Windows/Fonts/'+('seguisb.ttf' if bold else 'segoeui.ttf'), size)

def ease(x):
    x = min(1, max(0, x)); return 1-(1-x)**3

def txt(im, text, xy, size=42, color=WHITE, anchor='mm', bold=True, stroke=0):
    ImageDraw.Draw(im).text(xy, text, font=font(size,bold), fill=color, anchor=anchor,
                            stroke_width=stroke, stroke_fill=INK)

def fit_text(im, text, xy, size=60, maxwidth=610, color=WHITE):
    while ImageDraw.Draw(im).textlength(text,font=font(size)) > maxwidth: size -= 1
    txt(im,text,xy,size,color)

def wrap(text, width=590, size=31):
    lines=[]; line=''; d=ImageDraw.Draw(Image.new('RGB',(1,1)))
    for word in text.split():
        candidate=(line+' '+word).strip()
        if d.textlength(candidate,font=font(size)) > width and line:
            lines.append(line); line=word
        else: line=candidate
    if line: lines.append(line)
    return lines

def panel(im,box,fill='#211A33',outline='#59436B',radius=24,width=2):
    ImageDraw.Draw(im).rounded_rectangle(tuple(map(int,box)),radius,fill=fill,outline=outline,width=width)

@functools.lru_cache(None)
def source_anim(path):
    path=Path(path); ASSETS.add(str(path.relative_to(ROOT)).replace('\\','/'))
    frames=[]; durations=[]
    with Image.open(path) as src:
        for fr in ImageSequence.Iterator(src):
            frames.append(fr.convert('RGBA').copy()); durations.append(fr.info.get('duration',100)/1000)
    boxes=[fr.getbbox() for fr in frames if fr.getbbox()]
    union=(min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes))
    return [fr.crop(union) for fr in frames],durations,union,src.size

def anim(path):
    frames,durations,_,_=source_anim(path)
    return frames,durations

@functools.lru_cache(None)
def actor_registration(path):
    """All actions share the idle scale and the original sprite-canvas pivot.

    Weapon trails and hurt/death poses must never recenter or resize the body.
    """
    path=Path(path)
    if path.parent==PINKY:
        reference=pink_path()
    elif path.parent.parent.parent in (CLASS,ENEMY):
        reference=path.parent/f'{path.parent.name}_Idle.gif'
    else:
        reference=path
    _,_,box,size=source_anim(str(reference))
    pivot_x=size[0]/2 if size==(100,100) else (box[0]+box[2])/2
    return pivot_x,box[3],box[3]-box[1],box[2]-box[0]

def path_for(name, state='Idle', enemy=False):
    return (ENEMY if enemy else CLASS)/name/name/f'{name}_{state}.gif'

def pink_path(state='Idle'):
    return PINKY/f'Pink_Monster_{state}_{dict(Idle=4,Walk=6,Run=6,Attack1=4,Jump=8)[state]}.gif'

@functools.lru_cache(1600)
def sized_frame(path, idx, height, flip):
    frames,_=anim(path); frame=frames[idx]
    if flip: frame=frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    _,_,reference_height,_=actor_registration(path)
    scale=height/reference_height
    return frame.resize((round(frame.width*scale),round(frame.height*scale)),Image.Resampling.NEAREST)

def sprite_placement(path,idx,cx,bottom,height,flip=False):
    sp=sized_frame(str(path),idx,int(height),flip)
    pivot_x,ground_y,reference_height,reference_width=actor_registration(str(path))
    _,_,crop,_=source_anim(str(path))
    scale=int(height)/reference_height
    dx=pivot_x-crop[2] if flip else crop[0]-pivot_x
    pos=(round(cx+dx*scale),round(bottom+(crop[1]-ground_y)*scale))
    return sp,pos,reference_width*scale

def sprite(im,path,t,cx,bottom,height,flip=False,shadow=True,once=False):
    frames,durations=anim(str(path)); total=sum(durations)
    phase=min(max(t,0),total-0.001) if once else t%total
    idx=0
    while idx<len(frames)-1 and phase>=durations[idx]: phase-=durations[idx]; idx+=1
    sp,pos,reference_width=sprite_placement(path,idx,cx,bottom,height,flip)
    if shadow:
        ImageDraw.Draw(im).ellipse((cx-reference_width*.3,bottom-12,cx+reference_width*.3,bottom+12), fill='#0D091A')
    im.paste(sp,pos,sp)

@functools.lru_cache(None)
def background(scene):
    yy,xx=np.mgrid[0:H,0:W]
    glow=np.exp(-((xx-390)**2/(440**2)+(yy-540)**2/(580**2)))
    colors=[(68,23,70),(35,37,88),(50,26,88),(21,58,64),(77,21,40),(58,46,24),(58,24,66)]
    col=colors[scene]
    a=np.zeros((H,W,3),np.uint8)
    for k,base in enumerate([14,12,23]): a[:,:,k]=base+glow*col[k]
    im=Image.fromarray(a)
    d=ImageDraw.Draw(im)
    for y in range(140,1020,48):
        for x in range(24,720,48): d.rectangle((x,y,x+1,y+1),fill='#433147')
    # Perspective grid occupies only the stage floor.
    for j in range(9):
        y=810+j*j*3;d.line((0,y,720,y),fill='#3A294F',width=1)
    for x in range(-1000,1800,135): d.line((360,785,x,1140),fill='#39284D',width=1)
    return im

def stage(im,t,scene):
    im.paste(background(scene))
    d=ImageDraw.Draw(im)
    for i in range(18):
        x=(i*103+29)%720;y=220+(i*151-t*(12+i%4*7))%760
        c=['#745174','#635B72','#807363'][i%3]
        d.rectangle((x,y,x+3,y+3),fill=c)
    txt(im,'RUSH FOR VILLAINS',(48,64),20,MUTED,anchor='lm')
    d.rectangle((48,95,672,97),fill='#514059')
    d.rectangle((48,95,48+624*t/DURATION,98),fill=PINK)

def tag(im,text,y=158,color=PINK):
    fit_text(im,text,(360,y),22,620,color)

def headline(im,a,b='',y=246,size=73):
    fit_text(im,a,(360,y),size)
    if b: fit_text(im,b,(360,y+size+6),size,color=PINK)

def logo(im,y,scale=1):
    # No game-logo bitmap is present: an animated typographic title is used.
    txt(im,'RUSH',(360,y),round(110*scale),GOLD,stroke=2)
    fit_text(im,'FOR VILLAINS',(360,y+90*scale),round(64*scale),620,GOLD)

def bar(im,x,y,w,pct,color,label):
    txt(im,label,(x,y-18),19,WHITE,anchor='lm')
    panel(im,(x,y,x+w,y+15),'#30243E','#644764',7,1)
    ImageDraw.Draw(im).rounded_rectangle((x+2,y+2,x+max(4,(w-2)*max(0,pct)),y+13),5,fill=color)

def caption(im,t):
    active=next(((a,b,s) for a,b,s in LINES if a<=t<b),None)
    if not active:return
    a,b,s=active
    # Split long narration into readable timed caption chunks.
    split={2:["Rush for Villains'ta attığın her adım,",'maceranın bir parçası!'],
           7:['Ama dikkat et! Macera ilerledikçe','karşına daha güçlü düşmanlar çıkacak.'],
           9:['Düşmanları yen, ödüller kazan','ve karakterini güçlendir!'],
           10:['Yani… bir sonraki yürüyüşün','sadece bir yürüyüş olmak zorunda değil.']}
    idx=LINES.index(active)
    if idx in split:
        chunks=split[idx]
        spoken=VOICE_DURATIONS.get(idx,b-a)
        first_weight=len(chunks[0].split())/sum(len(chunk.split()) for chunk in chunks)
        s=chunks[0 if t-a<spoken*first_weight else 1]
    lines=wrap(s)
    top=1045; bottom=top+53+len(lines)*42
    panel(im,(36,top,684,bottom),'#171222','#50364F',22,2)
    txt(im,'PINKY',(59,top+25),16,PINK,anchor='lm')
    for i,line in enumerate(lines):txt(im,line,(360,top+65+i*42),31,WHITE)

def frame(t):
    scene=sum(t>=b for b in [4,8,13,20,25,31])
    im=Image.new('RGB',(W,H));stage(im,t,scene)
    d=ImageDraw.Draw(im)
    if scene==0:
        tag(im,'BİR SONRAKİ YÜRÜYÜŞÜN…')
        headline(im,'BİRAZ','SIKICI MI?',size=79)
        if t>1.65:
            sprite(im,path_for('Black Knight_A',enemy=True),t,505,852,260,True)
            txt(im,'!',(550,505),100,GOLD,stroke=3)
        cx=-150+480*ease(t/0.65)
        sprite(im,pink_path('Run' if t<0.65 else 'Idle'),t,cx,910,370,flip=1.7<t<2.2)
        if t>2.20:
            panel(im,(120,945,600,1000),PINK,PINK,10)
            txt(im,'PEKİ YA CANAVARLAR?',(360,972),29,INK)
    elif scene==1:
        u=t-4;tag(im,'HER ADIM BİR MACERA')
        logo(im,270,0.88+0.12*ease(u/0.4))
        for i,name in enumerate(['Black Knight_A','Demon_A','Flame Golem']):
            sprite(im,path_for(name,enemy=True),t+i,130+220*i,835,[230,240,225][i],True)
        labels=['WALK','FIGHT','EARN','UPGRADE']
        for i,label in enumerate(labels):
            x=40+164*i;active=u>=0.4+i*.35
            panel(im,(x,897,x+149,965),GOLD if active else '#211A33',GOLD if active else '#59436B',12)
            txt(im,label,(x+74,931),22,INK if active else MUTED)
            if i<3:txt(im,'›',(x+156,930),22,GOLD)
    elif scene==2:
        u=t-8;names=['Knight','Archer','Wizard','Swordsman'];idx=min(3,int(u/1.25))
        tag(im,'CLASS SEÇİMİ');headline(im,'TARZINI','BELİRLE.',size=76)
        # Fixed thumbnail slots keep the selection changes from rearranging the cast.
        for j in range(4):
            x=95+j*170
            panel(im,(x-63,458,x+89,598),'#211A33',PINK if j==idx else '#59436B',16,3 if j==idx else 1)
            sprite(im,path_for(names[j],'Walk'),t,x,574,88)
        d.ellipse((172,620,548,910),outline='#885179',width=3)
        sprite(im,path_for(names[idx],'Walk'),t,330,891,270)
        panel(im,(186,927,534,990),PINK,PINK,11)
        txt(im,names[idx].upper(),(360,957),31,INK)
        for i in range(4):d.ellipse((316+i*25,1010,325+i*25,1019),fill=PINK if idx==i else '#59436B')
    elif scene==3:
        u=t-13
        tag(im,'WALK → FIGHT',color=MINT)
        if u<3.6:
            headline(im,'ADIMLARINI','TAMAMLA.',size=66)
            panel(im,(124,420,596,992),'#11101C','#756787',42,3)
            panel(im,(302,442,418,458),'#5B4B6B','#5B4B6B',8)
            steps=742 if u<.8 else (891 if u<2.0 else 1000)
            txt(im,'GÜNLÜK HEDEF',(360,519),23,MUTED)
            txt(im,str(steps),(360,610),86,MINT if steps==1000 else WHITE)
            txt(im,'/ 1000 ADIM',(360,682),29,MUTED)
            panel(im,(165,736,555,751),'#30253D','#30253D',7)
            panel(im,(165,736,165+390*steps/1000,751),MINT,MINT,7)
            sprite(im,path_for('Knight','Walk'),t,360,922,129)
            if steps==1000:txt(im,'HEDEF TAMAMLANDI',(360,962),22,MINT)
        else:
            headline(im,'VE…','SALDIR!',size=80)
            bar(im,62,466,244,1,MINT,'KNIGHT')
            hp=max(.25,1-max(0,u-4.5)*1.6)
            bar(im,414,466,244,hp,'#FF6B6B','BLACK KNIGHT')
            lunge=80*max(0,1-abs(u-4.65)/.5)
            sprite(im,path_for('Knight','Attack01' if 4<u<5.6 else 'Idle'),max(0,u-4.2),228+lunge,867,290)
            sprite(im,path_for('Black Knight_A','Hurt' if 4.5<u<5.2 else 'Idle',True),t,508,867,285,True)
            if 4.45<u<5.8:
                txt(im,'HIT!',(392,630-40*(u-4.45)),91,GOLD,stroke=5)
                for k in range(7):
                    a=k*math.tau/7;r=50+(u-4.45)*70
                    d.line((414+math.cos(a)*r,710+math.sin(a)*r,414+math.cos(a)*(r+35),710+math.sin(a)*(r+35)),fill=GOLD,width=5)
            tag(im,'HER ADIM, BİR SONRAKİ VURUŞ.',962,MINT)
    elif scene==4:
        u=t-20;tag(im,'TEHLİKE BÜYÜYOR',color='#FF8B8B')
        headline(im,'DAHA GÜÇLÜ','DÜŞMANLAR.',size=64)
        enemies=['Black Knight_A','Demon_A','Flame Golem'];idx=min(2,int(u/1.05))
        name=enemies[idx]
        if u<3.4:
            sprite(im,path_for(name,'Attack01' if u>2.4 else 'Idle',True),max(0,u-2.4) if u>2.4 else t,390,901,300+idx*42,True)
            for i in range(3):d.polygon([(252+i*82,971),(280+i*82,945),(308+i*82,971),(280+i*82,997)],fill='#FF7979' if i<=idx else '#402337')
            if u>2.5:
                bar(im,72,462,255,max(.4,1-(u-2.5)*1.1),'#FF7777','CANIN')
                sprite(im,path_for('Knight','Hurt'),t,145,880,210)
        else:
            sprite(im,path_for('Flame Golem',enemy=True),t,527,835,210,True)
            sprite(im,pink_path(),t,311,938,362)
            txt(im,'KOLAY MI SANDIN?',(360,983),35,GOLD)
    elif scene==5:
        u=t-25;tag(im,'EARN → UPGRADE',color=GOLD)
        if u<1.7:
            headline(im,'ZAFERİN','KARŞILIĞI.',size=69)
            sprite(im,path_for('Black Knight_A','Death',True),u,492,854,230,True,once=True)
            sprite(im,path_for('Knight'),t,219,864,280)
            for i in range(14):
                age=max(0,u-.15);angle=i*2.4
                x=360+math.cos(angle)*min(290,age*210)*(0.5+i%3*.22)
                y=690+math.sin(angle)*age*220-120*age+100*age*age
                sprite(im,ROOT/'lib/All_Assets/coins/coin_gold_medium_shine.gif',t+i,x,y,34+(i%3)*9,shadow=False)
            txt(im,'+ COINS',(360,485),48,GOLD,stroke=3)
            txt(im,'+ XP',(360,551),47,MINT,stroke=3)
        elif u<4.5:
            headline(im,'ÖDÜLLERİNİ','GÜCE ÇEVİR.',y=215,size=57)
            screen=Image.open(HERE/'screens/forge.png').convert('RGB')
            screen=screen.crop((0,0,390,766)).resize((332,653),Image.Resampling.LANCZOS)
            panel(im,(179,330,541,1013),'#100E17','#917695',30,3)
            im.paste(screen,(194,345))
            # Existing equipment art floats beside the actual game screen.
            for i,item in enumerate(['swords/aqua_sword.png','shields/blue_round_shield.png']):
                sp=Image.open(ROOT/'lib/Items'/item).convert('RGBA');ASSETS.add('lib/Items/'+item)
                box=sp.getbbox();sp=sp.crop(box);sp.thumbnail((90,100))
                sp=sp.resize((sp.width*2,sp.height*2),Image.Resampling.NEAREST)
                x=90 if i==0 else 625
                panel(im,(x-59,582+i*146,x+59,700+i*146),'#30223D','#C7A272',18)
                im.paste(sp,(x-sp.width//2,635+i*146-sp.height//2),sp)
        else:
            headline(im,'LEVEL','UP!',size=92)
            for i,name in enumerate(['Archer','Knight','Wizard']):
                x=115+225*i
                d.ellipse((x-88,790,x+88,832),outline=MINT,width=3)
                sprite(im,path_for(name),t,x,833,160+(i==1)*45)
                txt(im,'↑ LEVEL UP',(x,907),23,MINT)
            tag(im,'AYNI KAHRAMAN. DAHA FAZLA GÜÇ.',984,GOLD)
    else:
        u=t-31;tag(im,'BİR SONRAKİ ADIM SENİN.')
        if u<4.7:
            logo(im,250,.90)
            fit_text(im,'WALK. FIGHT. LEVEL UP.',(360,435),30,630,WHITE)
            for i,name in enumerate(['Archer','Knight','Wizard']):
                sprite(im,path_for(name),t+i,105+240*i,785,140)
            for i,name in enumerate(['Black Knight_A','Demon_A']):
                sprite(im,path_for(name,enemy=True),t+i,223+270*i,610,120,True)
            sprite(im,pink_path(),t,360,1000,205)
        else:
            logo(im,274,1)
            fit_text(im,'WALK. FIGHT. LEVEL UP.',(360,452),31,630,WHITE)
            sprite(im,pink_path('Jump'),t-35.7,360,802,243)
            panel(im,(105,862,615,966),GOLD,GOLD,18)
            txt(im,'COMING SOON',(360,911),44,INK)
    caption(im,t)
    # A short opening fade and 5-frame scene-change flash preserve trailer pace.
    if t<.25:im=Image.blend(Image.new('RGB',(W,H),'black'),im,t/.25)
    for cut in [4,8,13,16.6,20,25,31,35.7]:
        if 0<=t-cut<.10:im=Image.blend(im,Image.new('RGB',(W,H),GOLD),.22*(1-(t-cut)/.10))
    return im

def audio():
    sr=48000;n=sr*DURATION;out=np.zeros((n,2),np.float32);rng=np.random.default_rng(17)
    def add(at,signal,gain=1,pan=0):
        if at>=DURATION:return
        start=int(at*sr);end=min(n,start+len(signal));signal=signal[:end-start]*gain
        out[start:end,0]+=signal*(1-pan*.5);out[start:end,1]+=signal*(1+pan*.5)
    # Original synthesized 144 BPM arcade score: no third-party music required.
    beat=60/144; roots=[130.8128,103.826,155.563,116.541]
    for j in range(math.ceil(DURATION/beat)):
        at=j*beat;r=roots[(j//8)%4];ts=np.arange(int(sr*.22))/sr
        kick=np.sin(math.tau*(48*ts+8*(1-np.exp(-ts*23))))*np.exp(-ts*22)
        add(at,kick,.15 if at>=4 else .07)
        if j%2:
            noise=rng.uniform(-1,1,len(ts))*np.exp(-ts*26);add(at,noise,.055)
        bass=np.sin(math.tau*r*ts)*np.minimum(1,ts*90)*np.exp(-ts*8);add(at,bass,.065)
        for k in range(2):
            tt=np.arange(int(sr*.14))/sr
            freq=r*2*[1,1.25,1.5,2][(j+k)%4]
            tone=(np.sin(math.tau*freq*tt)+.25*np.sin(math.tau*freq*3*tt))*np.exp(-tt*21)*np.minimum(1,tt*160)
            add(at+k*beat/2,tone,.038 if at>=4 else .015,(-1)**j*.6)
    for at in [4,8,13,16.6,20,25,31,35.7]:
        tt=np.arange(int(sr*.25))/sr
        add(at,rng.uniform(-1,1,len(tt))*np.sin(math.pi*tt/.25)**2,.08)
    for at in [17.48,22.6]:
        tt=np.arange(int(sr*.3))/sr
        add(at,(rng.uniform(-1,1,len(tt))*.4+np.sin(math.tau*(90*tt-90*tt*tt)))*np.exp(-tt*17),.26)
    for at in [25.20,25.4,25.6,29.7]:
        tt=np.arange(int(sr*.35))/sr
        add(at,(np.sin(math.tau*1046.5*tt)+np.sin(math.tau*1568*tt))*.5*np.exp(-tt*13),.14)
    report=[]
    # Every complete voice line is time-fitted; no spoken text is truncated.
    for i,(start,end,text) in enumerate(LINES):
        mp3=HERE/'audio'/f'voice_{i:02}.mp3'
        pcm=subprocess.check_output([FFMPEG,'-v','error','-i',str(mp3),'-af',VOICE_TRIM_FILTER,'-f','f32le','-ac','1','-ar',str(sr),'-'])
        raw=np.frombuffer(pcm,dtype=np.float32);duration=len(raw)/sr
        tempo=max(1,duration/(end-start-.035)); filters=[];factor=tempo
        while factor>2:filters.append('atempo=2');factor/=2
        filters.append(f'atempo={factor:.7f}')
        fitted=subprocess.check_output([FFMPEG,'-v','error','-f','f32le','-ar',str(sr),'-ac','1','-i','-','-af',','.join(filters),'-f','f32le','-'],input=pcm)
        sig=np.frombuffer(fitted,dtype=np.float32).copy()
        peak=np.max(np.abs(sig));sig*=.76/max(.1,peak)
        fade=min(240,len(sig)//4);sig[:fade]*=np.linspace(0,1,fade);sig[-fade:]*=np.linspace(1,0,fade)
        a=int(start*sr);b=min(n,a+len(sig));out[a:b]*=.45
        add(start,sig)
        report.append(dict(line=i+1,text=text,start=start,end=end,source_seconds=round(duration,3),tempo=round(tempo,3),fitted_seconds=round(len(sig)/sr,3)))
        VOICE_DURATIONS[i]=len(sig)/sr
    out[:sr//4]*=np.linspace(0,1,sr//4)[:,None]
    out[-sr//5:]*=np.linspace(1,0,sr//5)[:,None]
    out*=.95/max(.95,np.max(np.abs(out)))
    with wave.open(str(HERE/'audio/mix.wav'),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr);f.writeframes((out*32767).astype('<i2').tobytes())
    (HERE/'audio/timing-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')

def timestamp(t):
    return f'00:00:{int(t):02},{round((t%1)*1000):03}'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--preview',action='store_true');args=parser.parse_args()
    if not args.preview:audio()
    moments=[1,3,5.8,8.8,10.7,14.4,15.8,17.7,21.4,23.9,25.7,27.9,30.1,32.8,36.7]
    sheet=Image.new('RGB',(5*216,3*410),'#100C17')
    for i,t in enumerate(moments):
        fr=frame(t);fr.thumbnail((216,384));x=i%5*216;y=i//5*410
        sheet.paste(fr,(x,y));txt(sheet,f'{t:.1f}s',(x+108,y+395),15)
    sheet.save(HERE/'storyboard.jpg',quality=95)
    frame(36.7).resize((1080,1920),Image.Resampling.LANCZOS).save(HERE/'poster.png')
    if args.preview:return
    cmd=[FFMPEG,'-y','-v','warning','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','-',
         '-i',str(HERE/'audio/mix.wav'),'-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-preset','fast','-crf','19',
         '-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-ar','48000','-t',str(DURATION),'-movflags','+faststart',
         str(HERE/VIDEO_NAME)]
    proc=subprocess.Popen(cmd,stdin=subprocess.PIPE)
    for i in range(FPS*DURATION):
        proc.stdin.write(frame(i/FPS).tobytes())
        if i%(FPS*2)==0:print(f'Rendering {i//FPS}/{DURATION}s',flush=True)
    proc.stdin.close()
    if proc.wait():raise RuntimeError('FFmpeg render failed')
    (HERE/'asset-manifest.json').write_text(json.dumps(sorted(ASSETS),ensure_ascii=False,indent=2),encoding='utf-8')
    srt='\n\n'.join(f'{i+1}\n{timestamp(a)} --> {timestamp(b)}\n{s}' for i,(a,b,s) in enumerate(LINES))
    (HERE/'rush-for-villains.tr.srt').write_text(srt+'\n',encoding='utf-8')
    print('Render complete',flush=True)

if __name__=='__main__':main()
