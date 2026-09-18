# Rush for Villains — Pinky's village adventure

75-second vertical sprite-animated advertisement, 1080 × 1920, 30 fps, H.264/AAC. English subtitles are burned in; a separate SRT is included. The final card holds completely still from 72–75 seconds.

The supplied seven-part story is staged with original Pinky, Mavili, Küp Kuzu, enemy and class GIFs. The app icon is the existing `lib/Start/Icon.png`; the game title is typeset because `StartLogo.png` is the studio splash, not a Rush for Villains wordmark. The village scenery and props are procedural animation artwork. No replacement character images were generated.

The phone screens and 120 combat frames are rendered directly from `AdventureScreen` with loaded fonts, English localization and controlled demonstration state. They show 742, 891 and 1000 steps, the actual two-attack presentation, decreasing enemy health, and victory with coins and XP. This is app-rendered demonstration footage, not a recording of a live pedometer session. The walking montage explicitly marks elapsed time. App capture aspect ratios are preserved.

Synthetic adult English voices: Pinky — Ava Multilingual; Mavili — Andrew Multilingual; Küp Kuzu — Jenny. Voice playback is never accelerated. A duration check preserves every complete line. Original synthesized music changes from calm to suspense, action, celebration and anticipation, with breeze, birds, impacts and reward chimes.

Animation scope: this is a 2D sprite cut using the poses available in the repository. It does not add facial rigs or newly drawn eyelids, lip-sync, or bespoke head poses. Pinky's resting pose is a rigid rotation of her original sprite. The monster POV is staged by low-angle composition and close framing; the existing enemy art limits precise eye contact. Naturalistic facial acting and fully articulated cinematography would need additional approved animation assets. Character action changes use shared idle-based pivots and scales.

Files:
- `rush-for-villains-village-75s.mp4`: finished cut.
- `poster.png`, `storyboard.jpg`, `encoded-review.jpg`: visual review.
- `dialogue.en.srt`, `narration.json`: dialogue and captions.
- `verification.json`, `audio/timing-report.json`: technical checks.
- `asset-manifest.json`: source assets used.
- `capture_test.dart`, `voices.py`, `render_village.py`, `verify.py`: reproducible source.

Run from the repository root with the existing Flutter/Python installations:

```powershell
flutter test output/promo/village/capture_test.dart --update-goldens
python output/promo/village/voices.py
python output/promo/village/render_village.py
python output/promo/village/verify.py
```

Dependencies are reused from `output/promo/tools`. Prior videos and app source are preserved.
