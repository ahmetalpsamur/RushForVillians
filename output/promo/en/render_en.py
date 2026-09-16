"""Reuse the approved Turkish animation timeline; localize voice and all copy."""
import sys, json
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent))
import render as base
from voice_en import LINES

COPY={
 'BİR SONRAKİ YÜRÜYÜŞÜN…':'YOUR NEXT WALK…',
 'BİRAZ':'FEELING', 'SIKICI MI?':'BORED?',
 'PEKİ YA CANAVARLAR?':'HOW ABOUT MONSTERS?',
 'HER ADIM BİR MACERA':'EVERY STEP, AN ADVENTURE',
 'CLASS SEÇİMİ':'CHOOSE YOUR CLASS',
 'TARZINI':'FIND YOUR', 'BELİRLE.':'STYLE.',
 'ADIMLARINI':'HIT YOUR', 'TAMAMLA.':'STEP GOAL.',
 'GÜNLÜK HEDEF':'DAILY GOAL', '/ 1000 ADIM':'/ 1000 STEPS',
 'HEDEF TAMAMLANDI':'GOAL COMPLETE',
 'VE…':'AND…', 'SALDIR!':'ATTACK!',
 'HER ADIM, BİR SONRAKİ VURUŞ.':'EVERY STEP POWERS YOUR NEXT HIT.',
 'TEHLİKE BÜYÜYOR':'THE CHALLENGE GROWS',
 'DAHA GÜÇLÜ':'TOUGHER', 'DÜŞMANLAR.':'ENEMIES.',
 'CANIN':'YOUR HP', 'KOLAY MI SANDIN?':'READY FOR A CHALLENGE?',
 'ZAFERİN':'CLAIM YOUR', 'KARŞILIĞI.':'REWARDS.',
 'ÖDÜLLERİNİ':'POWER UP', 'GÜCE ÇEVİR.':'YOUR HERO.',
 'AYNI KAHRAMAN. DAHA FAZLA GÜÇ.':'SAME HERO. MORE POWER.',
 'BİR SONRAKİ ADIM SENİN.':'TAKE YOUR NEXT STEP.',
}
original_txt=base.txt
original_fit=base.fit_text

def english_txt(im,text,xy,size=42,color=base.WHITE,anchor='mm',bold=True,stroke=0):
    translated=COPY.get(text,text)
    # Preserve the original tag's available width as English wording changes.
    maxwidth=470 if text=='PEKİ YA CANAVARLAR?' else 620
    if text in COPY:
        while base.ImageDraw.Draw(im).textlength(translated,font=base.font(size,bold))>maxwidth:size-=1
    original_txt(im,translated,xy,size,color,anchor,bold,stroke)

def english_fit(im,text,xy,size=60,maxwidth=610,color=base.WHITE):
    original_fit(im,COPY.get(text,text),xy,size,maxwidth,color)

def english_caption(im,t):
    active=next(((i,a,b,s) for i,(a,b,s) in enumerate(LINES) if a<=t<b),None)
    if active is None:return
    idx,a,b,text=active
    chunks={
        2:['In Rush for Villains,','every step is an adventure!'],
        7:['Watch out! Tougher enemies await','as you advance.'],
        9:['Defeat your enemies, claim your rewards,','and power up your hero!'],
        10:['So... your next walk could be','the start of something epic.'],
    }
    if idx in chunks:
        parts=chunks[idx];spoken=base.VOICE_DURATIONS.get(idx,b-a)
        proportion=len(parts[0].split())/sum(len(p.split()) for p in parts)
        text=parts[0 if t-a<spoken*proportion else 1]
    lines=base.wrap(text)
    top=1045;bottom=top+53+len(lines)*42
    base.panel(im,(36,top,684,bottom),'#171222','#50364F',22,2)
    base.txt(im,'PINKY',(59,top+25),16,base.PINK,anchor='lm')
    for i,line in enumerate(lines):base.txt(im,line,(360,top+65+i*42),31,base.WHITE)

def main():
    base.HERE=HERE
    base.VIDEO_NAME='rush-for-villains-en-38s-fixed.mp4'
    base.LINES=LINES
    base.txt=english_txt
    base.fit_text=english_fit
    base.caption=english_caption
    # Trim only leading/trailing silence; preserve phrasing and internal breaths.
    base.VOICE_TRIM_FILTER='silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse'
    base.main()
    # Localize the shared renderer's subtitle filename.
    subtitles=HERE/'rush-for-villains.tr.srt'
    if subtitles.exists():subtitles.replace(HERE/'rush-for-villains.en.srt')

if __name__=='__main__':main()
