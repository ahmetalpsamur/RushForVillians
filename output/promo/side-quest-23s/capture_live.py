import asyncio, json, sys, time, threading, http.server, functools
from pathlib import Path
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
sys.path.insert(0,str(HERE.parent/'tools'))
from playwright.async_api import async_playwright

async def main():
    handler=functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(ROOT/'build/web'))
    server=http.server.ThreadingHTTPServer(('127.0.0.1',8877),handler)
    threading.Thread(target=server.serve_forever,daemon=True).start()
    (HERE/'raw').mkdir(exist_ok=True)
    async with async_playwright() as p:
        browser=await p.chromium.launch(channel='chrome',headless=True,args=['--autoplay-policy=no-user-gesture-required'])
        opts={}
        if (HERE/'browser-state.json').exists(): opts['storage_state']=str(HERE/'browser-state.json')
        context=await browser.new_context(viewport={'width':432,'height':768},device_scale_factor=2,locale='en-US',record_video_dir=str(HERE/'raw'),record_video_size={'width':864,'height':1536},**opts)
        page=await context.new_page()
        page.on('pageerror',lambda e: print('PAGE ERROR:',e,flush=True))
        await page.goto('http://127.0.0.1:8877')
        started=time.monotonic()
        await page.wait_for_timeout(8000)
        await page.screenshot(path=str(HERE/'live.png'))
        print('READY',flush=True)
        last=(HERE/'command.json').read_text(encoding='utf-8-sig') if (HERE/'command.json').exists() else ''
        if '--replay' in sys.argv and not opts:
            previous=[json.loads(line) for line in (HERE/'events.jsonl').read_text().splitlines()]
            for cmd in previous:
                if cmd['id']>34:break
                if cmd['action']=='click': await page.mouse.click(cmd['x'],cmd['y'])
                if cmd['action']=='type': await page.keyboard.type(cmd['text'])
                await page.wait_for_timeout(max(1100,cmd.get('wait',650)))
                await context.storage_state(path=str(HERE/'browser-state.json'))
                print('REPLAY',cmd['id'],flush=True)
            await page.screenshot(path=str(HERE/'live.png'))
            print('REPLAY READY',flush=True)
        while True:
            f=HERE/'command.json'
            if f.exists():
                try: raw=f.read_text(encoding='utf-8-sig')
                except (PermissionError,OSError):
                    await asyncio.sleep(.2)
                    continue
                if raw!=last:
                    last=raw
                    try:
                        cmd=json.loads(raw); action=cmd['action']
                        print('COMMAND',cmd,'AT',round(time.monotonic()-started,3),flush=True)
                        if action=='stop': break
                        if action=='click': await page.mouse.click(cmd['x'],cmd['y'])
                        if action=='type': await page.keyboard.type(cmd['text'])
                        if action=='key': await page.keyboard.press(cmd['key'])
                        if action=='scroll': await page.mouse.wheel(0,cmd['dy'])
                        if action=='semantics':
                            await page.locator('flt-semantics-placeholder').click(force=True)
                        if action=='textclick': await page.get_by_text(cmd['text'],exact=True).click()
                        await page.wait_for_timeout(cmd.get('wait',650))
                        await page.screenshot(path=str(HERE/'live.png'))
                        await context.storage_state(path=str(HERE/'browser-state.json'))
                        (HERE/'dom.txt').write_text(await page.locator('body').inner_text(),encoding='utf-8')
                        with (HERE/'events.jsonl').open('a',encoding='utf-8') as out:out.write(json.dumps({'elapsed':time.monotonic()-started,**cmd})+'\n')
                        print('DONE',cmd.get('id'),flush=True)
                    except Exception as e:print('ERROR',repr(e),flush=True)
            await asyncio.sleep(.15)
        await context.close()
        await browser.close()
        print('SAVED',flush=True)

asyncio.run(main())
