import json,subprocess,re,wave,hashlib,io
from pathlib import Path
import render_reel as r
H=r.HERE;FF=r.FF
from PIL import Image
report={'format':'1080x1920, 9:16, 30 fps, H.264/AAC','physical_steps':False,'capture':'Actual application web build; built-in demo step controls','planned_app_footage_seconds':14.5,'variants':{},'checks':{}}
mixes={v:r.audio(v) for v in 'abc'}
def pcm(path):
 with wave.open(str(path)) as f:return f.readframes(f.getnframes())
ref=pcm(mixes['a'])[2*48000*2*2:]
report['checks']['common_pcm_after_2s_identical']=all(pcm(mixes[v])[2*48000*2*2:]==ref for v in 'bc')
finals={}
for v in 'abc':
 src=H/f'rush-for-villains-{v.upper()}-23s.mp4';out=H/f'Rush-for-Villains-{v.upper()}-FINAL.mp4'
 subprocess.run([FF,'-y','-v','error','-i',str(src),'-i',str(mixes[v]),'-map','0:v:0','-map','1:a:0','-c:v','copy','-c:a','aac','-b:a','192k','-ar','48000','-t','23','-movflags','+faststart',str(out)],check=True)
 finals[v]=out
for name,path in [(v,p) for v,p in finals.items()]+[(f'opening-{v}',H/f'opening-{v.upper()}-2s.mp4') for v in 'bc']:
 result=subprocess.run([FF,'-hide_banner','-i',str(path),'-map','0:v:0','-an','-f','null','-','-progress','pipe:1','-nostats'],capture_output=True,text=True)
 frames=[int(x) for x in re.findall(r'^frame=(\d+)',result.stdout,re.M)]
 expected=60 if name.startswith('opening') else 690
 assert result.returncode==0,(name,result.stderr)
 assert frames[-1]==expected,(name,frames[-1])
 assert '1080x1920' in result.stderr and '30 fps' in result.stderr
 m=re.search(r'Duration: (\d+:\d+:\d+\.\d+)',result.stderr)
 report['variants'][name]={'file':path.name,'frames':frames[-1],'duration':m.group(1),'bytes':path.stat().st_size,'decode_errors':False,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
 print('VERIFIED',name,frames[-1],flush=True)
def small_common(path):
 raw=subprocess.check_output([FF,'-v','error','-ss','2','-i',str(path),'-an','-vf','scale=72:128,format=gray','-f','rawvideo','-'])
 return r.np.frombuffer(raw,dtype=r.np.uint8).astype(r.np.int16)
a=small_common(finals['a'])
for v in 'bc':
 b=small_common(finals[v]);assert len(a)==len(b)
 mae=float(r.np.abs(a-b).mean());assert mae<1,mae
 report['checks'][f'{v}_common_video_mean_pixel_error_0_to_255']=mae
for v,p in finals.items():
 s=subprocess.run([FF,'-hide_banner','-i',str(p),'-vn','-af','loudnorm=I=-16:TP=-1:LRA=11:print_format=json','-f','null','-'],capture_output=True,text=True)
 loud=json.loads(s.stderr[s.stderr.rfind('{'):s.stderr.rfind('}')+1]);report['variants'][v]['integrated_lufs']=loud['input_i'];report['variants'][v]['true_peak_dbtp']=loud['input_tp']
moments=[0,1,2.5,5,8,11.4,12.5,14.6,15.5,17.6,19,22.95]
sheet=Image.new('RGB',(1200,760),r.INK)
for i,t in enumerate(moments):
 raw=subprocess.check_output([FF,'-v','error','-ss',str(t),'-i',str(finals['a']),'-frames:v','1','-vf','scale=200:356','-f','image2pipe','-vcodec','png','-'])
 im=Image.open(io.BytesIO(raw));x=i%6*200;y=i//6*380;sheet.paste(im,(x,y));r.txt(sheet,f'{t:.2f}s',x+100,y+368,17)
sheet.save(H/'encoded-review.jpg',quality=95)
(H/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('ALL CHECKS PASSED',flush=True)
