# Testing

All automation is pinned to Godot `4.7.1.stable.official.a13da4feb`. Each of the 36 commands runs in an isolated headless process and returns a meaningful exit code. The runner also fails a command if Godot prints `ERROR:` or `SCRIPT ERROR:` despite returning zero. On Windows, it resolves the small official console launcher to the real process and uses Godot log files so timeouts are reliable.

## Complete local gate

```text
python tools/run_headless_suite.py --group all --log-dir build/test-logs
python tools/inventory_runtime_assets.py --check
```

Available repeatable groups are `import`, `resource`, `unit`, `systems`, `campaign`, `world`, and `shell`. Combine groups by repeating `--group`. Override the engine with `GODOT_BIN` or `--godot`; the per-command timeout defaults to 120 seconds.

The full gate covers import/parse validation, dependency/provenance checks, schema/state transitions, player combat and movement, all six weapon families and fourteen weapon items, their six curated family icons and locked/unknown fallback, schema-2 contracts for all 22 enemies, production encounters, live per-act balance, bosses, corruption/gravity/teleport mechanics, expanded performance bounds, all twenty legacy stages, and all 202 connected-world rooms. The first-two-acts gate completes the ten Cyber City/Robot Factory stages in order, validates each manifest-driven entry card, real rightward movement and jumping from every authored spawn, actual CharacterBody2D landings on all eighteen authored traversal sections, regular and boss objectives, exit messaging, checkpoint/collectible budgets, boss HUD bounds, the Act 2→3 handoff, save progression, and seven distinct production panoramas. The last-two-acts gate completes Neon Moon Protocol and Abyssal Night from real player movement through checkpoints, collectibles, objectives, bosses, handoffs, and the ending while verifying ten distinct 1672×941 panoramas, forty-three traversal decks, and twenty-eight regional assemblies. Connected-world coverage includes 103 unique expansion layout IDs/static-geometry signatures, twenty district art profiles with unique skylines/landmarks and forty prop assignments, the 162-room twenty-district critical route, optional-cache collection/save persistence, quest progression and legacy reconstruction, 21 valid main-objective map destinations plus regional/overall completion calculation, four regional boss rewards, all five warp destinations plus story/boss/cutscene locks, personalized ending/post-game flow, atomic save recovery, exact save-slot character reconstruction, five-bus audio settings plus four regional ambience profiles, dual-input navigation/remap persistence, categorized equipment/inventory presentation, dialogue pause safety, every shell route, and missing-audio fallbacks. The world group also instantiates production rooms and player collision for seven authored traversal probes: near-limit jump, wall jump, dash follow-through, teleport range/clearance, low gravity, moving-platform timing, and fall recovery.

The final Acts 1–2 composition review also checks the shared runtime traversal decks: all 70 collision surfaces have their correct district tile surface, architecture assemblies, and context-sensitive safety cues without altering independently tested collision geometry. It additionally validates the 41 authored non-moving route links against the player’s actual normal-jump and dash envelope.

## Legacy Acts 1–2 visual capture

`scripts/testing/LegacyActCapture.gd` uses the real renderer to save start, signature, and finish frames for stages `1-1` through `2-5`; the start pass re-presents the manifest-driven entry card so its composition can be checked with the production HUD. Set `CCP_LEGACY_CAPTURE_DIR` to a writable build directory and run Godot without `--headless`, using `--audio-driver Dummy --rendering-method gl_compatibility --script res://scripts/testing/LegacyActCapture.gd`. Optionally set `CCP_LEGACY_CAPTURE_STAGES` to a comma-separated subset such as `1-5,2-5`. The harness forces off-screen draws so it does not depend on `frame_post_draw`, which is unavailable under Godot's dummy headless renderer. The source-only harness and generated images are excluded from exports.

## Neon Moon and Abyssal Night presentation gate

`tests/integration/LastTwoActsProductionTest.gd` is the deterministic production gate for stages `3-1` through `4-5`. It verifies that each stage uses its own high-resolution panorama and restrained per-layer atmospheric treatment, that the vertical Security Grid Shaft has adequate background overscan, and that regional lunar/abyssal structural assemblies replace legacy Cyber City/Factory architecture. It also exercises traversal, objectives, persistence, all later-act bosses, campaign handoffs, and the ending. Prompt records, output paths, and SHA-256 hashes are in `docs/assets/ACT3_ACT4_GENERATED_PANORAMAS.md`.

## District art capture

`scripts/testing/DistrictArtCapture.gd` uses the real renderer to save one representative 960×540 room from every district. Set `CCP_ART_CAPTURE_DIR` to a writable build directory and run Godot with `--script res://scripts/testing/DistrictArtCapture.gd --rendering-method gl_compatibility`. The source-only capture script and generated images are excluded from exports; the 202-room structural test independently validates the same profile, prop, skyline, landmark, atmosphere, foreground, and platform-trim contract.

## Packaged interaction pass

The 2026-08-05 local Windows pass exercised the exported game in a real 1280×720 window: Title → New Game → slot 1 → name edit/randomization → Begin Prologue → personalized dialogue → playable `WorldRoot`; occupied-slot live reconstruction; keyboard movement/jump/dash; Map, Equipment, and Inventory presentation; a streamed room transition; cutscene autosave; process termination; and Continue without sequence replay. Export-excluded captures are stored under `build/manual-qa/` for local review.

That pass found and fixed four rendered/runtime gaps that headless state tests had not proved: clipped creator actions/live preview, a duplicate world-space room title under the HUD, tutorial/objective overlap, and a missing final cutscene autosave. `CharacterCreationFlowTest`, `WorldContentAuditTest`, and `NarrativeServicesTest` now enforce the corresponding viewport, HUD-band, and disk-persistence contracts. This is meaningful local keyboard/mouse evidence, not a substitute for the remaining full-route, controller, independent-machine, display, audio, and target-GPU matrices.

## Export gate

```text
godot --headless --path . --export-release "Windows Desktop" build/windows/CyberCityPlatformer.exe
python tools/package_release.py --allow-dirty
```

Omit `--allow-dirty` for an actual release. The packager rejects missing files, forbidden test/editor/source markers in the PCK, absolute developer paths in release documents, and an unclean Git worktree. It records the source SHA and SHA-256 hashes for the executable and PCK.

GitHub Actions runs six required jobs on pushes and pull requests targeting `main`: import, resource validation, unit tests, systems/shell smoke, campaign smoke, and Windows export. Every job uploads logs; the export job uploads the temporary Windows build.
