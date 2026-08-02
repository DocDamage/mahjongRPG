# Phase 1–2 completion audit

**Audited commit:** `f634a5a` (subsequent documentation commits should preserve these results)
**Scope:** P1 and P2 in `plans/mahjongrpg-completion-playable-slices.md`
**Method:** inspected runtime paths, save migrations, tests, CI logs, manifests, documentation, and current local archive directories.

## Phase 1

| Requirement | Evidence | Result |
| --- | --- | --- |
| Orange/Blue unlock and pre-match selection | `BrandLoadoutState`, `BrandLoadoutPicker`, `MahjongTable`, schema-8 snapshot, `test_phase_one_services.gd` | Implemented and automated-tested |
| Visible Mabel helper action | `HelperService`, helper catalog, Wayward Farm button, quest assignment, daily-use state | Implemented and automated-tested |
| Mounted location persistence | horse scene/position state, actor restoration, schema-7 safe dismount migration | Implemented and automated-tested |
| Four-crop planting choice | `CropPicker` offers beans, corn, tomato, and wheat | Implemented and resource-tested |
| Inspectable schedules | unavailable opponents remain interactable and report activity/window | Implemented and automated-tested |
| Localized dialogue/evidence with first Silas clue | locale-aware dialogue catalog, story evidence catalog, First Lantern reward | Implemented and automated-tested |
| Focused orchestration and migration tests | phase-one service suite plus existing progression/save suites; 33 suites green | Passed |
| Physical player checkpoint | keyboard/controller completion of the described First Lantern path | Pending manual matrix |

## Phase 2

| Requirement | Evidence | Result |
| --- | --- | --- |
| Target-engine CI | [GitHub Actions run 30770945127](https://github.com/DocDamage/mahjongRPG/actions/runs/30770945127): Linux import/validator/33 suites/smoke/editor and Windows export preflight | Passed |
| Test-to-module coverage inventory | `docs/qa/test_to_module_coverage.md` | Present |
| Complete source-archive evidence | Supplemental verification stops at missing Hero archive; master verification reports all nine split parts missing | Blocked by absent user-supplied archives |
| Correct ffmpeg requirements | README, supplemental guide, and canonical recovery/setup guide name the required Vorbis-capable `ffmpeg` | Present |
| Canonical setup/status/recovery docs | README plus `docs/release/setup_and_recovery.md`; duplicate production plan copies removed | Present |
| Manual device/display matrix | `docs/qa/manual_device_display_matrix.md` | Present; execution pending |
| Title/load/settings/accessibility shell | title shell, autosave load/recovery message, persistent text/UI scale, dialogue speed, hold/toggle, reduced motion, subtitles, glyph-base preference | Implemented and preference-tested |
| Code-license disposition | `legal/PROPRIETARY_SOURCE_NOTICE.md` | Present |
| Clean-profile player checkpoint | `tools/launch_clean_profile.ps1` documents a reproducible isolated profile launch | Script present; user-observed pass pending |

## Conclusion

All repository-controlled Phase 1–2 implementation, automation, CI, and documentation requirements have direct evidence. Neither phase should be declared fully accepted until the asset owner supplies the complete archive sets and a person records the physical device/display and clean-profile checkpoints. Those blockers are external inputs, not substitute-ready data.
