# Manual device, display, and accessibility matrix

Run this matrix against the Windows debug export on a clean profile before a demo handoff. Record date, build commit, tester, device, and result in the release evidence log; an unchecked row is not a passed gate.

| Area | Required observation | Status |
| --- | --- | --- |
| Keyboard only | Start new game, open title/accessibility, plant a crop, finish First Lantern, save/load, and return to Riverbend without mouse input. | Pending manual evidence |
| Controller only | Navigate title, accessibility, pause/settings, crop picker, Brand picker, and Mahjong controls with focus visible throughout. | Pending manual evidence |
| Mayor Bell keyboard | Complete `meet`, `favor`, and `resolve` using only keyboard; cancel and reopen one sequence; verify visible focus and that rapid Enter does not skip or commit twice. Automated event/focus contracts pass; physical observation is still required. | Pending manual evidence |
| Mayor Bell controller | Complete all three Mayor Bell sequences using only a physical controller; cancel and reopen one sequence; verify visible focus and that rapid confirm does not skip or commit twice. Automated controller-event/focus contracts pass; physical observation is still required. | Pending manual evidence |
| Controller hot-plug | Switch input prompt/glyph presentation after connect and disconnect without losing focus or input. | Pending manual evidence |
| Windowed | Launch, alt-tab, save/load, and confirm 960×540 readability. | Pending manual evidence |
| Borderless / fullscreen | Change display mode, relaunch, and confirm the mode persisted. | Pending manual evidence |
| Text/UI scale | Cycle both scales, relaunch, and confirm settings persisted and controls remain reachable. | Pending manual evidence |
| Accessibility | Verify subtitles default on, dialogue speed, hold/toggle, reduced motion, and glyph-base selection persist and have visible values. | Pending manual evidence |
| Mayor Bell dialogue accessibility | Inspect Mayor Bell at two dialogue speeds and two text/UI scales, then with reduced motion and high contrast; confirm the centered panel remains readable/reachable and reveal behavior matches the selected preference. Automated preference/layout contracts pass; physical observation is still required. | Pending manual evidence |
| Mayor Bell persistence boundary | While each sequence is open, verify save, load, new game, and session restore are unavailable/rejected; after cancel or terminal commit, verify they work again and the next load begins from the first node of the last committed stage. | Pending manual evidence |
| Release accessibility | With keyboard and controller separately, complete a fishing catch using relaxed timing, disable vibration without losing text feedback, enable high contrast, and read the postgame journal without relying on color or sound. | Pending manual evidence |
| Save recovery | Corrupt a copied primary slot, load it, and confirm `.backup` recovery plus understandable feedback. | Pending manual evidence |
| Clean profile | Launch the debug export with a new AppData profile, complete the P1 checkpoint, relaunch, and load. | Pending manual evidence |
| Release install/resume | Install the packaged RC on a clean Windows machine, complete a representative loop plus finale/postgame transition, quit, relaunch, and resume without loss. | Pending manual evidence |
