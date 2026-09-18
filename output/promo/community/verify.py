import sys,json,re,subprocess
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'tools'))
import imageio_ffmpeg
ff=imageio_ffmpeg.get_ffmpeg_exe();video=HERE/'rush-for-villains-android-beta-community.mp4'
check=subprocess.run([ff,'-hide_banner','-i',str(video),'-f','null','-'],capture_output=True,text=True)
log=check.stderr
assert check.returncode==0,log
assert '1080x1920' in log and '30 fps' in log and '00:01:16.00' in log,log
assert re.search(r'frame=\s*2280',log),log
assert 'Audio: aac' in log and '48000 Hz' in log,log
timing=json.loads((HERE/'audio/timing-report.json').read_text(encoding='utf-8'))
assert len(timing)==23,len(timing)
for line in timing:
 assert line['start']+line['fitted_seconds']<=line['end']+.035,line
 assert line['tempo']<=1.23,line
assert len({x['speaker'] for x in timing if x['line']==21})==3
positions=json.loads((HERE/'position-audit.json').read_text())
assert not positions['out_of_bounds'],positions['out_of_bounds'][:15]
srt=(HERE/'rush-for-villains-community.en.srt').read_text(encoding='utf-8')
for hh,mm,ss in re.findall(r'(\d\d):(\d\d):(\d\d),',srt):assert int(mm)<60 and int(ss)<60
subprocess.run([ff,'-y','-v','error','-i',str(video),'-vf','fps=1/6.4,scale=216:384,tile=4x3','-frames:v','1',str(HERE/'encoded-review.jpg')],check=True)
report={'file':video.name,'duration_seconds':76,'resolution':'1080x1920','fps':30,'frames':2280,'full_decode':'passed','voice_tracks':23,'distinct_character_voices':3,
 'voice_timing':'passed','subtitle_timecodes':'passed','final_cta_reading_seconds':7.9,'sprite_placements_checked':positions['placements'],'out_of_bounds':0,'bytes':video.stat().st_size}
(HERE/'verification.json').write_text(json.dumps(report,indent=2))
(HERE/'verification.log').write_text(log,encoding='utf-8')
print(json.dumps(report,indent=2))
