import subprocess
import render_village as v
for i,(a,b,who,words) in enumerate(v.LINES):
 for w in (['MAVILI','KUP KUZU'] if who=='ALL' else [who]):
  path=v.HERE/'audio'/f'{i:02}_{w.replace(" ","_")}.mp3'
  raw=subprocess.check_output([v.r.FFMPEG,'-v','error','-i',str(path),'-af','silenceremove=start_periods=1:start_threshold=-48dB,areverse,silenceremove=start_periods=1:start_threshold=-48dB,areverse','-f','f32le','-ar','48000','-ac','1','-'])
  dur=len(raw)/4/48000;print(i,w,round(dur,3),'slot',round(b-a,3),'OVER' if dur>b-a else 'OK')
