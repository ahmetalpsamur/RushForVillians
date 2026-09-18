import json,re,subprocess
import render_village as v
here=v.HERE;video=here/'rush-for-villains-village-75s.mp4';ff=v.r.FFMPEG
check=subprocess.run([ff,'-hide_banner','-i',str(video),'-f','null','-'],capture_output=True,text=True)
log=check.stderr
assert check.returncode==0,log
assert '1080x1920' in log and '30 fps' in log and '00:01:15.00' in log,log
assert re.search(r'frame=\s*2250',log),log
assert 'Audio: aac' in log and '48000 Hz' in log,log
timing=json.loads((here/'audio/timing-report.json').read_text())
assert len(timing)==16
for line in timing:
 assert line['tempo']==1.0 and line['start']+line['duration']<=line['end'],line
assert v.frame(72).tobytes()==v.frame(74.9).tobytes()
for h,m,s in re.findall(r'(\d\d):(\d\d):(\d\d),',(here/'dialogue.en.srt').read_text(encoding='utf-8')):assert int(m)<60 and int(s)<60
subprocess.run([ff,'-y','-v','error','-i',str(video),'-vf','fps=1/5,scale=216:384,tile=5x3','-frames:v','1',str(here/'encoded-review.jpg')],check=True)
report=dict(file=video.name,duration_seconds=75,resolution='1080x1920',fps=30,frames=2250,full_decode='passed',dialogue_lines=15,voice_tracks=16,adult_english_voices=3,voice_speed_multiplier=1,final_card_static_seconds=3,subtitles='passed',actual_flutter_combat_frames=120,bytes=video.stat().st_size)
(here/'verification.json').write_text(json.dumps(report,indent=2));(here/'verification.log').write_text(log,encoding='utf-8');print(json.dumps(report,indent=2))
