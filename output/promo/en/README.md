# Rush for Villains — English edition

**rush-for-villains-en-38s-fixed.mp4**: 38 seconds, 1080 × 1920, 30 fps, H.264 / AAC.

Position correction: shared actor pivots and idle-relative scales prevent recentering/resizing between actions. Class thumbnails stay in fixed slots and cast lineups no longer overlap. The original MP4 is retained. Narration, music, timings and character designs are unchanged.

This edition reuses the approved animation timeline, original character assets, music and effects. All advertising copy, burned-in captions and the actual Flutter blacksmith screen are in English. The original Turkish MP4 is preserved.

Pinky uses a synthetic American English voice (`en-US-AvaMultilingualNeural`), with short, inviting phrases and scene-specific speaking rates. Internal pauses are retained. The reward and closing lines have a more relaxed delivery. No real person's voice was cloned.

Files:
- `rush-for-villains.en.srt`: English captions.
- `poster.png`, `storyboard.jpg`: poster and scene preview.
- `encoded-review.jpg`, `verification.json`: decoded-video inspection and technical checks.
- `narration.json`: adapted script and scene timing.
- `audio/timing-report.json`: measured speech durations and fitting factors.

Reproduce from the project root with the same local Python/Flutter setup as the Turkish version:

```powershell
python output/promo/en/voice_en.py
python output/promo/en/prepare_capture_en.py
flutter test output/promo/en/capture_en_test.dart --update-goldens --reporter expanded
python output/promo/en/render_en.py
python output/promo/en/verify_en.py
```
