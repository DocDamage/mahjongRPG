# Content validation and advisory tooling

Use the same Godot 4.7.1 production validators locally and in CI. The command is read-only: it does not rewrite JSON or GDScript.

```powershell
$env:GODOT_4_7_1 = "C:\path\to\Godot_v4.7.1-stable_win64_console.exe"
pwsh -NoProfile -File tools/run_content_validation.ps1
```

Success ends with `Repository validation passed.`, `Content validation report`, and `0 error(s)`. Diagnostics include the source file, JSON path, and reason. Fix every error before opening a pull request; review-threshold file-size entries remain warnings until they cross 300 lines.

The optional pre-commit setup is advisory and does not replace CI:

```powershell
python -m pip install pre-commit
pre-commit install
pre-commit run --all-files
```

It checks conflict markers, JSON syntax, case conflicts, lower-snake-case project filenames, oversized newly added handwritten files, repository constraints, and production content. Generated/imported/third-party files, scenes/resources, UID files, exports, and assets are excluded.

Formatting and lint remain non-blocking manual trials:

```powershell
pre-commit run --hook-stage manual gdlint --all-files
pre-commit run --hook-stage manual gdformat --all-files
```

`gdformat` is configured with `--check`, so this command reports differences without modifying files. Godot 4.7.1 import, native tests, smoke, and Windows export preflight remain the authoritative gates regardless of advisory results.

To add or edit an ordinary linear dialogue sequence:

1. Add localized line keys under `locales.<locale>.lines`.
2. Add an acyclic sequence with stable sequence/node/speaker IDs, a valid start node, supported portrait expressions, and exactly one reachable terminal path.
3. Reference its stable ID from the matching community stage's `dialogue_sequence_id`.
4. Run the command above; do not add script paths, commands, expressions, or side effects to content.
