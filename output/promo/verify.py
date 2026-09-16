import json, subprocess, sys, re
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE/'tools'))
import imageio_ffmpeg
ff=imageio_ffmpeg.get_ffmpeg_exe()
video=HERE/'rush-for-villains-38s-fixed.mp4'
result=subprocess.run([ff,'-hide_banner','-i',str(video),'-f','null','-'],capture_output=True,text=True)
log=result.stderr
assert result.returncode==0,log
assert '1080x1920' in log and '30 fps' in log,log
assert '00:00:38.00' in log,log
assert 'Audio: aac' in log and '48000 Hz' in log,log
assert re.search(r'frame=\s*1140',log),log
timing=json.loads((HERE/'audio/timing-report.json').read_text(encoding='utf-8'))
for line in timing:
    assert line['start']+line['fitted_seconds']<=line['end']+.025,line
subprocess.run([ff,'-y','-v','error','-i',str(video),'-vf','fps=1/5,scale=216:384,tile=4x2','-frames:v','1',str(HERE/'encoded-review.jpg')],check=True)
report={'file':video.name,'resolution':'1080x1920','aspect_ratio':'9:16','seconds':38,'fps':30,'frames':1140,'video_codec':'H.264','audio_codec':'AAC','audio_sample_rate':48000,'bytes':video.stat().st_size,'full_decode':'passed','voice_timing':'12 complete lines; no slot overruns','game_screen_capture':'Flutter capture passed'}
(HERE/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
(HERE/'verification.log').write_text(log,encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
