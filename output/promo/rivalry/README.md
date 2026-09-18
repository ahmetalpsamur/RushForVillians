# Rush for Villains — Friendly Rivalry

Vertical English Reel with the complete supplied Pinky/Mavili dialogue.

- 1080 × 1920, 30 fps, H.264/AAC, approximately 89 seconds.
- Pinky: Ava Multilingual; Mavili: Andrew Multilingual. Adult synthetic voices, original pitch.
- Original Pinky/Mavili GIFs, original equipment and reward PNGs. No redesigned mascots or replacement characters.
- Original-canvas registration and idle-relative scaling preserve each character's ground anchor.
- Only idle/walk character animations; peaceful banter, no attacks between the friends.
- Real Flutter Inventory, Blacksmith, Titles and Reward Showcase screens, captured with staged local demo data. No user account or saved progress modified.
- Upgrade statistic overlays come from the game's resolved level 3/4 Aqua Sword data in `stats.json`.
- In-game English UI still contains some Turkish item/stat labels; screenshots preserve the actual interface.
- Original procedural background music, lowered under dialogue; deliberate silence for reaction beats.

Files: finished MP4, English SRT, complete `dialogue.en.txt`, poster, storyboard, encoded review, timing and placement verification, reproducible rendering and capture scripts.

Rebuild: run `voices.py`, Flutter `test capture_test.dart --update-goldens`, then `render_rivalry.py` and `verify.py`. Dependencies reuse `../tools` and existing promo rendering helpers. No application source changes.
