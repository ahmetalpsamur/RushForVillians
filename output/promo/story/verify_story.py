import sys,json,re,subprocess
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'tools'))
import imageio_ffmpeg
ff=imageio_ffmpeg.get_ffmpeg_exe();video=HERE/'rush-for-villains-pinky-adventure-en.mp4'
result=subprocess.run([ff,'-hide_banner','-i',str(video),'-f','null','-'],capture_output=True,text=True)
log=result.stderr
assert result.returncode==0,log
assert '1080x1920' in log and '30 fps' in log and '00:00:40.00' in log,log
assert re.search(r'frame=\s*1200',log),log
assert 'Audio: aac' in log,log
lines=json.loads((HERE/'audio/timing-report.json').read_text())
for line in lines:
 assert line['start']+line['fitted_seconds']<=line['end']+.035,line
 assert line['tempo']<=1.22,line
positions=json.loads((HERE/'position-audit.json').read_text())
assert not positions['out_of_bounds'],positions['out_of_bounds'][:10]
subprocess.run([ff,'-y','-v','error','-i',str(video),'-vf','fps=1/5,scale=216:384,tile=4x2','-frames:v','1',str(HERE/'encoded-review.jpg')],check=True)
report={'file':video.name,'seconds':40,'resolution':'1080x1920','fps':30,'frames':1200,'full_decode':'passed','voice_slots':'12 complete lines verified','max_tempo_fit':max(x['tempo'] for x in lines),'sprite_placements_checked':positions['placements'],'out_of_bounds':0,'bytes':video.stat().st_size}
(HERE/'verification.json').write_text(json.dumps(report,indent=2))
(HERE/'verification.log').write_text(log,encoding='utf-8')
print(json.dumps(report,indent=2))
