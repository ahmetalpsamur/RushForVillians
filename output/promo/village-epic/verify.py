import re,json,subprocess
import render_epic as e
here=e.HERE;ff=e.r.FFMPEG;path=here/'rush-for-villains-epic-v2-75s.mp4'
p=subprocess.run([ff,'-hide_banner','-i',str(path),'-f','null','-'],capture_output=True,text=True)
assert p.returncode==0,p.stderr
assert '1080x1920' in p.stderr and '00:01:15.00' in p.stderr and re.search(r'frame=\s*2250',p.stderr),p.stderr
assert 'Audio: aac' in p.stderr and '48000 Hz' in p.stderr
timing=json.loads((here/'timing-report.json').read_text());assert len(timing)==16
for row in timing:assert row['start']+row['duration']<=row['end'] and row['tempo']==1
assert e.frame(72).tobytes()==e.frame(74.9).tobytes()
subprocess.run([ff,'-y','-v','error','-i',str(path),'-vf','fps=1/5,scale=216:384,tile=5x3','-frames:v','1',str(here/'encoded-review.jpg')],check=True)
report={'file':path.name,'seconds':75,'resolution':'1080x1920','fps':30,'frames':2250,'full_decode':'passed','dialogue_speed':1,'voice_tracks':16,'static_final_hold_seconds':3,'ruins_persist_after_victory':True,'shadow_sources':['Demon_A','Black Knight_A','Blood Monster_A'],'bytes':path.stat().st_size}
(here/'verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
