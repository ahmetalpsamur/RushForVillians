"""Replace only narration/mix; stream-copy every original encoded video frame."""
import json,subprocess,re
import render_story as s
from voice_story import VOICE
HERE=s.HERE
source=HERE/'rush-for-villains-pinky-adventure-en.mp4'
output=HERE/'rush-for-villains-pinky-adventure-en-adult-voice.mp4'
s.audio()
timing=json.loads((HERE/'audio/timing-report.json').read_text())
for line in timing:
 assert line['start']+line['fitted_seconds']<=line['end']+.035,line
 assert line['tempo']<=1.22,line
subprocess.run([s.r.FFMPEG,'-y','-v','warning','-i',str(source),'-i',str(HERE/'audio/mix.wav'),
 '-map','0:v:0','-map','1:a:0','-c:v','copy','-c:a','aac','-b:a','192k','-ar','48000',
 '-t','40','-movflags','+faststart',str(output)],check=True)
def video_hash(path):
 return subprocess.check_output([s.r.FFMPEG,'-v','error','-i',str(path),'-map','0:v:0','-c:v','copy','-f','hash','-hash','sha256','-'],text=True).strip()
old_hash=video_hash(source);new_hash=video_hash(output)
assert old_hash==new_hash,'The encoded picture stream changed'
decode=subprocess.run([s.r.FFMPEG,'-hide_banner','-i',str(output),'-f','null','-'],capture_output=True,text=True)
assert decode.returncode==0,decode.stderr
assert '1080x1920' in decode.stderr and '00:00:40.00' in decode.stderr and re.search(r'frame=\s*1200',decode.stderr),decode.stderr
report={'file':output.name,'voice':VOICE,'pitch_adjustment_hz':0,'seconds':40,'resolution':'1080x1920','fps':30,'frames':1200,
 'encoded_video_unchanged':True,'video_hash':new_hash,'full_decode':'passed','complete_voice_lines':len(timing),
 'maximum_tempo_fit':max(x['tempo'] for x in timing),'bytes':output.stat().st_size}
(HERE/'adult-voice-verification.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
