# P15–P16 completion audit

## Delivered player journey

1. Complete the P14 warning and interact with the Hall's Texas King table.
2. The game writes `pre_finale.json` before seating a legal, counterable Frontier Rules championship. A loss leaves the scheduled table retryable.
3. After a win, travel to King's Reach. The deliberately failed standoff branch returns directly to the standoff; it never replays Mahjong.
4. Resolve the standoff through either transparent response category and receive one of four saved endings, the father reveal, Silas's return, and credits.
5. Continue from credits into the same world. Hall Legends is repeatable, and the postgame ledger reports ending provenance and collection progress without invalidating King's Reach, farm/animals, fishing, or existing progress.

## Save compatibility

- Schema 20 adds isolated finale checkpoint/result/credits state.
- Schema 21 adds one canonical postgame state with ending provenance.
- Schema-19 saves receive safe empty P15/P16 records; schema-20 saves retain their finale result and receive inactive postgame state.
- Invalid cross-service states are rejected: a defeated Texas King requires a completed championship, and active postgame requires credits plus matching ending provenance.

## Automated evidence

Run with `C:\Users\Doc\AppData\Local\GodotPortable\4.7.1\Godot_v4.7.1-stable_win64_console.exe`:

```powershell
python tools/validate_repository.py
& $SixBrandsGodot --headless --path . --script res://tests/test_runner.gd
& $SixBrandsGodot --headless --path . --script res://tests/smoke_test.gd
& $SixBrandsGodot --headless --path . --editor --quit
```

The native runner contains 45 suites. `test_phase_fifteen_sixteen.gd` covers the scheduled match gate, dedicated checkpoint contract, retry behavior, four endings, credits, every ending-to-postgame transition, repeatable tournament, collection state, and P15/P16 migrations. Physical keyboard/controller/player-path checkpoints remain manual evidence gates.
