import sys,json,subprocess,re,wave
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'tools'))
import imageio_ffmpeg,numpy as np
ff=imageio_ffmpeg.get_ffmpeg_exe();video=HERE/'rush-for-villains-natural-voices.mp4'
timeline=json.loads((HERE/'timeline.json').read_text(encoding='utf-8'));duration=timeline['duration'];frames=round(duration*30)
result=subprocess.run([ff,'-hide_banner','-i',str(video),'-f','null','-'],capture_output=True,text=True)
assert result.returncode==0,result.stderr
assert '1080x1920' in result.stderr and '30 fps' in result.stderr
assert re.search(r'frame=\s*'+str(frames),result.stderr)
assert 'Audio: aac' in result.stderr and '48000 Hz' in result.stderr
timing=json.loads((HERE/'audio/timing-report.json').read_text(encoding='utf-8'))
assert len(timing)==49 and len(timeline['lines'])==48
for line in timing:
 assert line['spoken_end']<=min(line['slot_end'],duration)+.025,line
 assert line['tempo']==1.0,line
positions=json.loads((HERE/'position-audit.json').read_text())
assert not positions['out_of_bounds'],positions['out_of_bounds'][:8]
subtitles=(HERE/'rush-for-villains-rivalry.en.srt').read_text(encoding='utf-8')
assert subtitles.count(' --> ')==48 and '00:01:' in subtitles
assert '00:00:60' not in subtitles
with wave.open(str(HERE/'audio/mix.wav')) as f:
 pcm=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(np.float32)/32768
assert np.max(np.abs(pcm))<.99
subprocess.run([ff,'-y','-v','error','-i',str(video),'-vf','fps=1/5,scale=216:384,tile=5x4','-frames:v','1',str(HERE/'encoded-review.jpg')],check=True)
report=dict(file=video.name,duration_seconds=duration,resolution='1080x1920',aspect_ratio='9:16',fps=30,frames=frames,full_decode='passed',dialogue_lines=48,voice_tracks=49,voice_timing='passed',subtitle_timecodes='passed',peak_audio=round(float(np.max(np.abs(pcm))),3),sprite_placements_checked=positions['placements'],out_of_bounds=0,bytes=video.stat().st_size)
(HERE/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(HERE/'verification.log').write_text(result.stderr,encoding='utf-8')
print(json.dumps(report,indent=2))
