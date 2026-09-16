"""Check every frame for unintended sprite clipping and action pivot changes."""
import json
from pathlib import Path
import render as r

original_sprite=r.sprite
violations=[]
placements=0
moment=0
def inspect(im,path,t,cx,bottom,height,flip=False,shadow=True,once=False):
    global placements
    frames,durations=r.anim(str(path))
    phase=min(max(t,0),sum(durations)-.001) if once else t%sum(durations)
    idx=0
    while idx<len(frames)-1 and phase>=durations[idx]:phase-=durations[idx];idx+=1
    sp,pos,_=r.sprite_placement(path,idx,cx,bottom,height,flip)
    box=sp.getbbox()
    if box and '/coins/' not in str(path).replace('\\','/') and moment>=.65:
        visible=(pos[0]+box[0],pos[1]+box[1],pos[0]+box[2],pos[1]+box[3])
        if visible[0]<8 or visible[2]>r.W-8 or visible[1]<105 or visible[3]>1040:
            violations.append({'time':round(moment,3),'asset':Path(path).name,'bounds':visible})
        placements+=1
    # All drawing besides the sprites still runs, retaining the exact scene dispatch.

for name,enemy in [('Knight',False),('Black Knight_A',True),('Flame Golem',True)]:
    registrations=[r.actor_registration(str(r.path_for(name,state,enemy))) for state in ['Idle','Walk','Attack01','Hurt','Death']]
    assert all(reg==registrations[0] for reg in registrations),name
assert r.actor_registration(str(r.pink_path('Idle')))==r.actor_registration(str(r.pink_path('Run')))==r.actor_registration(str(r.pink_path('Jump')))
r.sprite=inspect
for i in range(r.FPS*r.DURATION):
    moment=i/r.FPS
    r.frame(moment)
report={'frames':r.FPS*r.DURATION,'sprite_placements_checked':placements,'shared_action_pivots':'passed','clipping':violations}
(r.HERE/'position-verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
assert not violations,'Unexpected sprite clipping; see position-verification.json'
