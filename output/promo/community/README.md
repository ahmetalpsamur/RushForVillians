# Rush for Villains — Android Closed Beta community Reel

**rush-for-villains-android-beta-community.mp4** — 76 seconds, vertical 1080 × 1920, 30 fps, H.264/AAC.

This cut follows the supplied full dialogue rather than compressing it into the earlier gameplay ad's length. It introduces the three friends, explains Android Closed Beta, asks for testing support, shows how to join through Instagram bio links, thanks the community, and closes with a shared three-voice line. The final CTA remains fully readable with no further dialogue for at least 7.9 seconds.

Cast and synthetic English voices:
- Pinky (female): `en-US-AvaMultilingualNeural`, natural pitch, retaining the adult voice selected after the earlier childlike-voice revision.
- Mavili (male): `en-US-AndrewMultilingualNeural`, natural pitch.
- Küp Kuzu (female): `en-US-JennyNeural`, slightly brighter (+3 Hz), no child voice.

Pinky, Mavili and Küp Kuzu use only their original project GIFs. Shared idle-based pivots and scales preserve alignment between Run, Idle, Throw and Jump. Existing poses represent waving and pointing without drawing new limbs or faces. Class art also comes from the project; no replacement characters were generated.

The profile scene is an intentionally generic illustration: **no Instagram handle, account statistics or URL is invented**. The request for a handle was optional; the default version labels Rush for Villains and highlights “Links in bio.” No social account was accessed or posted to. Beta availability and platform plans are the facts supplied in the brief. Android Closed Beta is labeled available now; Android + iOS are shown as the full-launch goal.

Game snippets reuse the project's original assets and the previously produced staged game animation. They are not raw live gameplay captures. Original synthesized music supports the speech, softens for the thank-you scene, and returns to the energetic theme for the finale. The logo is a typographic game title.

Outputs include the poster, storyboard, English SRT with speaker names, narration/voice timing JSON, original-asset manifest, placement audit, decoded-video review and technical verification.

Reproduce from the project root with the existing environment:

```powershell
python output/promo/community/voices.py
python output/promo/community/render_community.py --audit
python output/promo/community/verify.py
```

The cut reuses helpers and media under `output/promo` and `output/promo/story`. Prior video versions and game source files are preserved.
