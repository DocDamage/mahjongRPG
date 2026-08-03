# Runtime smoke validation

Run this after a Godot editor import to verify project wiring beyond the pure unit suites:

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
```

The smoke test fails when a required autoload, input action, main scene, vertical-slice data table, or generated player/horse asset is missing or unreadable. It is intentionally asset-light so it can run without proprietary archive inputs or a Windows export template.
