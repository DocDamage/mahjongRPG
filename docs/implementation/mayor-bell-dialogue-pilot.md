# Mayor Bell linear-dialogue pilot (Q3)

**Engine:** Godot 4.7.1
**Save schema:** unchanged at 21
**Dialogue catalog schema:** 4; linear sequence schema 1
**Pilot gate:** passed by automated contract/integration coverage; physical device/display walkthrough remains in the shared manual QA matrix.

## Baseline ownership and state diagram

Mayor Bell remains a `CommunityArcService` arc. Q3 does not move it into `QuestService` and adds no property or branching outcome.

```text
inactive / next action meet
  -> meet terminal acknowledgment
  -> active stage 1 / choice mayor_bell_meet / relationship +1
  -> favor terminal acknowledgment
  -> active stage 2 / choice mayor_bell_favor / relationship +1
  -> resolve terminal acknowledgment
  -> completed / choice mayor_bell_resolve / relationship +1
  -> helper mayor_bell assigned / resolved schedule presentation
```

The committed legacy save points are captured in `tests/fixtures/community/`: inactive, active stages 0/1/2, and completed. Every non-completed fixture restarts the expected sequence at `opening`, remains completable, and reaches relationship value 3 plus exactly one helper assignment. The existing choice IDs and deltas are unchanged:

| Action | Choice ID | Delta | Sequence ID |
| --- | --- | ---: | --- |
| `meet` | `mayor_bell_meet` | +1 | `mayor_bell.meet` |
| `favor` | `mayor_bell_favor` | +1 | `mayor_bell.favor` |
| `resolve` | `mayor_bell_resolve` | +1 | `mayor_bell.resolve` |

Completion still assigns helper `mayor_bell`. `OpponentSchedule` still presents `welcoming claimants to a fair hearing` in clear weather and `sharing the corrected claim file under the awning` in rain after resolution. No Q3 code mutates relationships, helpers, schedules, properties, inventory, quest state, or rewards outside `CommunityArcService` and its existing collaborators.

## Runtime and persistence contract

- The data gate is `dialogue_sequence_id` on a community stage. Only Mayor Bell has it; all other arcs retain the legacy one-action presentation path.
- `DialogueSequenceValidator` rejects unknown/side-effect fields, unstable or duplicate IDs, missing speakers/portraits/localization keys, missing targets, unreachable nodes, cycles, and unsupported schemas with file/JSON-path diagnostics.
- `DialogueSequenceRunner` owns presentation, typewriter progression, focus, cancel, portrait rendering, and accessibility preferences only.
- `CommunityDialogueCoordinator` captures the expected action/sequence and revalidates both at terminal acknowledgment before calling `CommunityArcService.advance` once. Its input lock and finished state reject repeated confirmation.
- `dialogue.seen` is constructed only after the community commit and published only when a caller supplies a positive objective-consumer predicate. Mayor Bell has no quest objective consumer, so normal pilot play publishes no event.
- While a sequence is open, save, load, new game, and direct restore are blocked by scoped counters. Cancel, committed completion, failed open, and teardown release them. Mid-sequence state is deliberately not serialized; a committed-stage restore starts at the sequence's first node.

## Accessibility and input evidence

The runner uses the existing portrait presentation and `DialogueCatalog`. It scales text and the centered panel from `text_scale`/`ui_scale`, varies reveal rate with `dialogue_speed`, shows lines immediately under reduced motion, uses an opaque high-contrast backdrop when requested, and focuses explicit Continue/Cancel buttons. Native tests exercise normal and reduced-motion presentation, two dialogue speeds, rapid confirm, cancel, keyboard Enter, controller A/Cross, focus, restriction teardown, and viewport-safe centering at scaled UI sizes.

## Before/after decision gate

Physical line counts include blank lines.

| File/responsibility | Before | After |
| --- | ---: | ---: |
| `src/world/community_arc_panel.gd` | 64 | 80 |
| `src/world/community_landmark.gd` | 31 | 53 |
| `src/community/community_arc_service.gd` | 173 | 180 |
| `src/core/game_session.gd` | 286 | 293 |
| New sequence validator | — | 147 |
| New sequence runner | — | 244 |
| New community coordinator | — | 55 |
| New generic flow | — | 82 |
| New session gate | — | 23 |

The two presentation callers grew, but their added code is generic data-gate/flow composition and contains no Mayor-specific stage branch or direct domain mutation. The old one-line direct advance remains only for unmigrated arcs. All new production files stay below the 250-line review threshold; the already-thresholded `game_session.gd` gained only gate checks while counter ownership was extracted to `session_gate.gd`.

For an ordinary multi-line action before Q3, an author needed to design presentation state, add scene/panel branching, add input/focus and cancellation behavior, decide save behavior, wire the domain commit, and add content/tests. After Q3, ordinary linear work is four data/test steps: add localization lines, add validated nodes, reference the sequence from the stage, and add the stage fixture/assertions. No engine or scene code is needed. Save behavior is automatic and uniform.

All ten decision criteria pass: data replaces Mayor branching; edits are primarily validated content; side effects retain service ownership; caller code is narrowly generic; author steps are reduced; save policy is automatic; fixture/cancel coverage is stronger; accessibility is explicit; duplicate effects are locked out; and the workflow is repeatable without engine changes.

## Rollback boundary

Remove Mayor Bell's three `dialogue_sequence_id` fields to restore the legacy action presentation during development. The sequence data, runner, and validation tooling are otherwise inert. No save-schema rollback or backward parser is required.
