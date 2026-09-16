from pathlib import Path
HERE=Path(__file__).resolve().parent
source=(HERE.parent/'verify.py').read_text(encoding='utf-8')
source=source.replace("str(HERE/'tools')", "str(HERE.parent/'tools')")
source=source.replace('rush-for-villains-38s-fixed.mp4','rush-for-villains-en-38s-fixed.mp4')
exec(compile(source,str(HERE/'verify_en.py'),'exec'))
