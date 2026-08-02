# Manual device, display, and accessibility matrix

Run this matrix against the Windows debug export on a clean profile before a demo handoff. Record date, build commit, tester, device, and result in the release evidence log; an unchecked row is not a passed gate.

| Area | Required observation | Status |
| --- | --- | --- |
| Keyboard only | Start new game, open title/accessibility, plant a crop, finish First Lantern, save/load, and return to Riverbend without mouse input. | Pending manual evidence |
| Controller only | Navigate title, accessibility, pause/settings, crop picker, Brand picker, and Mahjong controls with focus visible throughout. | Pending manual evidence |
| Controller hot-plug | Switch input prompt/glyph presentation after connect and disconnect without losing focus or input. | Pending manual evidence |
| Windowed | Launch, alt-tab, save/load, and confirm 960×540 readability. | Pending manual evidence |
| Borderless / fullscreen | Change display mode, relaunch, and confirm the mode persisted. | Pending manual evidence |
| Text/UI scale | Cycle both scales, relaunch, and confirm settings persisted and controls remain reachable. | Pending manual evidence |
| Accessibility | Verify subtitles default on, dialogue speed, hold/toggle, reduced motion, and glyph-base selection persist and have visible values. | Pending manual evidence |
| Save recovery | Corrupt a copied primary slot, load it, and confirm `.backup` recovery plus understandable feedback. | Pending manual evidence |
| Clean profile | Launch the debug export with a new AppData profile, complete the P1 checkpoint, relaunch, and load. | Pending manual evidence |
