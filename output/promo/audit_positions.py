from PIL import Image, ImageDraw, ImageSequence
import render as r

sheet=Image.new('RGB',(1200,900),'#31283b')
d=ImageDraw.Draw(sheet)
for row,(name,enemy) in enumerate([('Knight',False),('Black Knight_A',True),('Flame Golem',True)]):
    for col,state in enumerate(['Idle','Walk','Attack01','Hurt']):
        src=Image.open(r.path_for(name,state,enemy))
        frames=[f.convert('RGBA').copy() for f in ImageSequence.Iterator(src)]
        boxes=[f.getbbox() for f in frames]
        print(name,state,src.size,boxes)
        fr=frames[len(frames)//2].resize((250,250),Image.Resampling.NEAREST)
        sheet.paste(fr,(col*300,row*300+35),fr)
        d.text((col*300,row*300),name+' '+state,fill='white')
        d.line((col*300+125,row*300+35,col*300+125,row*300+285),fill='red')
sheet.save(r.HERE/'pivot-audit.png')
