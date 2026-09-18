import sys,subprocess,io
from pathlib import Path
H=Path(__file__).resolve().parent
sys.path.insert(0,str(H.parent/'tools'))
from PIL import Image,ImageDraw,ImageFont
import imageio_ffmpeg
FF=imageio_ffmpeg.get_ffmpeg_exe()
src=H/'raw/page@b634b8f3e003245e5cbe5e5302c52441.webm'
moments=[214,218,255,260,300,305,331.5,332,332.5,333,333.5,334,335,337,340,350,375,380]
out=Image.new('RGB',(1200,1197),'#171323');d=ImageDraw.Draw(out)
for i,t in enumerate(moments):
 raw=subprocess.check_output([FF,'-v','error','-ss',str(t),'-i',str(src),'-frames:v','1','-vf','scale=200:356','-f','image2pipe','-vcodec','png','-'])
 im=Image.open(io.BytesIO(raw));x=i%6*200;y=i//6*399
 out.paste(im,(x,y));d.text((x+10,y+361),str(t),fill='white',font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',23))
out.save(H/'raw-review.jpg')
