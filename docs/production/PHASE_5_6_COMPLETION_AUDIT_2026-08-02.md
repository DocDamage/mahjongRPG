# Phase 5–6 completion audit

**Scope:** Bridlewood farm expansion and ranch legacy/open-ended farm on the P1–P4 foundation.

## Delivered player path

1. Complete First Lantern and use the Bridlewood trail. The first access registers the region and then enters the Ranch; pre-P5 saves remain locked until this action.
2. Plant any of the active crops, fulfill the carrot-and-potato ranch order, challenge Ada Rook or Gideon Shaw, inspect the Silas ledger, and repair the damaged barn with harvested beans and wheat.
3. Open the Bridlewood–Wayward shortcut, use the ranch shops to add named launch animals after capacity is repaired, and assign the ranch hand to feed them.
4. Build and repair a machine through the farm construction palette, collect animal products, and process eligible milk at the cheese press.
5. Raise Daisy/Clover's named goat lineage to Sprout, then continue the calendar until retirement without losing the farm route or save continuity.

## Code and automated evidence

| Requirement | Evidence |
| --- | --- |
| Bridlewood route, order, shortcut, shops/actions, clue, schedules, opponents 4–5 | `data/regions/bridlewood/region.json`, `src/world/bridlewood.tscn`, opponent/schedule catalogs |
| Ten-crop P5 expansion and all supplied P6 crops | `data/crops/vertical_slice_crops.json`, scrollable `crop_picker.gd`, `test_crop_catalog.gd`, `test_phase_five_six.gd` |
| Repairable barn/coop/machines, processing, dense route safety | `farm_service.gd`, `processing_service.gd`, construction/processing catalogs, farm/P5-P6 tests |
| Named variants, breeding, lineage, capacity, aging, retirement, quality/products | `animal_care_service.gd`, animal catalog, `test_phase_five_six.gd`, `test_animal_care_service.gd` |
| Horse identity/location persistence | `horse_travel_state.gd`, `test_horse_travel_state.gd` |
| P5/P6 save continuity | schema-11 migrator, `test_phase_five_six.gd`, existing save/session tests |

On 2026-08-02, `python tools/validate_repository.py`, the Godot 4.7.1 native runner (**40 suites**), runtime smoke, and headless editor initialization passed. The outstanding evidence gates are manual: the physical Bridlewood/crop-order/table/repair/shortcut walkthrough; the named-lineage-to-retirement walkthrough; keyboard/controller-only operation; two save/load cycles in the new loop; and display/audio sanity. This document intentionally does not claim those player-observed gates have been run.
