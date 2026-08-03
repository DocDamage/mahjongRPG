# Q4 content tooling and advisory trial

**Date:** 2026-08-03
**Production mutation:** none from the formatter/linter trial
**Authoritative engine:** Godot 4.7.1

## Shared validation

`tools/validate_content.gd` invokes `ContentValidationReport`, which calls the same `QuestDefinitionValidator` and `DialogueSequenceValidator` used by runtime registration/presentation. The report includes malformed/unsupported catalogs, invalid definitions, duplicate IDs, missing item/interaction/speaker/portrait/localization/sequence references, unreachable dialogue nodes, quests requiring a newer save schema, and GDScript file-size warnings/errors.

The current repository result is `0 error(s), 5 warning(s), 213 GDScript file(s) checked`. The five warnings are existing 250–300 line files; no file exceeds the 300-line policy. `tools/validate_repository.py` additionally parses every JSON file under `data/` and `tests/fixtures/`. CI runs the production content entry point after Godot import and before native tests.

## Advisory pre-commit behavior

`.pre-commit-config.yaml` uses `pre-commit-hooks` v6.0.0 for conflict markers, JSON syntax, and case conflicts. Local checks cover lower-snake-case project filenames, oversized newly added handwritten files, repository validation, and production content validation. Generated/imported/third-party content, assets, exports, artifacts, Godot cache, scenes/resources, and UID/binary files are excluded.

The configuration is opt-in. `gdformat` and `gdlint` are restricted to the manual hook stage, so neither can block an ordinary commit or CI. `gdformat` also receives `--check` and cannot rewrite files.

## Non-mutating gdtoolkit 4.5.0 trial

The trial used an ignored virtual environment under `artifacts/local/` and ran:

```powershell
gdformat --check src tests tools
gdlint src tests tools
```

Results:

- `gdformat --check`: exit 1; 178 files would be reformatted and 35 would be unchanged.
- `gdlint`: exit 1; 1,041 findings.
- Finding classes: 977 `max-line-length`, 50 `class-definitions-order`, 7 `max-returns`, 2 `max-public-methods`, 2 `unused-argument`, 1 `duplicated-load`, and 1 `function-preload-variable-name`.
- No formatter was run without `--check`; gameplay/content files were not rewritten.

This is not a clean repository-wide report, so formatting and lint remain advisory. The dominant false-positive/migration class is the toolkit's 100-character line default against the repository's established compact GDScript style. Enabling either as a blocking gate would require a separately reviewed formatting/style migration with no gameplay diff.

## Rollback

Remove `.pre-commit-config.yaml`, the three contributor scripts/checks, the CI content-validation step, and the contributor/tooling documents. Runtime content and save/release artifacts remain valid because gameplay does not depend on pre-commit or gdtoolkit.
