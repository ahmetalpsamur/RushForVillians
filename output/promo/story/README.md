# Pinky's little walk — English story cut

Latest voice revision: **`rush-for-villains-pinky-adventure-en-adult-voice.mp4`** uses the adult female `en-US-AvaMultilingualNeural` voice at its natural pitch. `replace_voice.py` rebuilds the audio mix and stream-copies the original video; a SHA-256 comparison verifies that the encoded images are identical. `adult-voice-verification.json` records the result. The original youthful-voice MP4 is retained.

`rush-for-villains-pinky-adventure-en.mp4` — 40 seconds, 1080 × 1920, 9:16, 30 fps, H.264 / AAC.

A new mascot-led cut following the supplied story: morning walk (0–6.4s), app interaction (6.4–10s), step milestones (10–17.7s), encounter and combat (17.7–23.6s), victory and equipment (23.6–28s), more enemies and reaction (28–32.5s), rapid montage (32.5–35.2s), final invitation (35.2–40s).

All Pinky, hero, enemy and coin art comes from the project. Original GIF animation frames retain their pixel colors and designs. Shared character pivots/idle-relative scales prevent action-dependent sliding or enlargement. Existing Push, Throw and Jump poses represent phone interaction, the invitation gesture and celebrations; no new face, hand or costume was generated. Reaction bubbles support the acting.

The morning park is an original code-drawn parallax scene. The magical transition reveals the project's actual daytime and nighttime background art, with a staged foreground path. Combat and step counting are promotional animations using real assets, not an unmodified gameplay recording. The app's actual English adventure selection, 1,000-step goal, enemy dialog and blacksmith screen were rendered through Flutter. These use example game state. The small class badge and tap ring are editorial overlays.

Pinky's voice is synthetic English, with individual line rates and natural pauses. The first cut used `en-US-AnaNeural`; the current voice script uses `en-US-AvaMultilingualNeural` without pitch raising. Elongated written spellings are normalized for pronunciation while captions preserve the supplied wording. Original arcade music, footsteps, milestone chimes, impacts and reward sounds were synthesized for the edit. Coming Soon retains the previously requested release CTA. The game title is typographic because the project's StartLogo.png is a studio logo.

Included: storyboard, poster, English SRT, narration and timing JSON, asset manifest, full-frame placement audit and final video verification. Earlier ad versions are preserved.

Run from the project root with the existing Python and Flutter environment:

```powershell
python output/promo/story/voice_story.py
flutter test output/promo/story/capture_story_test.dart --update-goldens --reporter expanded
python output/promo/story/render_story.py --audit
python output/promo/story/verify_story.py
```

The reusable renderer and dependencies remain in `output/promo`; the existing English blacksmith capture remains in `output/promo/en/screens`. Font paths are configured for this Windows environment.
