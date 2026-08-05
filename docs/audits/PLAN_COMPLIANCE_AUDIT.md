# Full completion plan compliance audit

Audit date: 2026-08-04

Branch: `feature/full-game-completion`

Target: `1.0.0-rc.2` on Godot `4.7.1.stable.official.a13da4feb`

This audit maps every implementation task in `CYBER_CITY_PLATFORMER_FULL_COMPLETION_PLAN.md` to production evidence. “Automated verified” means the implementation and its production wiring pass a headless gate. It does not stand in for the plan's explicitly required human or hardware observations.

## Evidence anchors

- `python tools/inventory_runtime_assets.py --check`: tracked runtime dependency and license gate.
- `python tools/run_headless_suite.py --group all`: 18 isolated import/resource/unit/system/campaign/shell commands; engine error lines fail even when Godot returns zero.
- `tests/campaign/CampaignContentTest.gd`: all 20 blueprints, required stage evidence IDs, live act balance, 23 mechanic kinds, two traversal/combat sections per standard stage, and four distinct bosses.
- `tests/campaign/CampaignRuntimeTest.gd`: production scene structure, metadata, checkpoints, exits, encounters, and camera bounds.
- `tests/campaign/CampaignTraversalTest.gd`: deterministic `1-1` through `4-5`, boss bypass hooks, one completion event, ending, and title return.
- `tests/integration/StageMechanicsTest.gd`: independent moving-platform, conveyor, gate/switch, gravity, turret, and eight-hazard contracts.
- `scripts/BossSystemsSmokeTest.gd`: unique rosters, phase thresholds, retry cleanup, defeat, reward, HUD, and exit behavior.
- `tests/integration/SaveSettingsTest.gd` and `ShellFlowTest.gd`: atomic saves, recovery/migration, settings/remaps, title/pause/routes, results, and credits.
- `tests/integration/PerformanceBudgetTest.gd`: bounded runtime pools and stage release.
- `.github/workflows/ci.yml`, `export_presets.cfg`, and `tools/package_release.py`: remote gates, strict Windows export, content scan, and archive metadata.

## Foundation and architecture

| Task | State | Production evidence / remaining gate |
|---|---|---|
| CCP-000 | Verified | Baseline SHA, clean-clone reproduction, engine version, failures, and branch are recorded in `CLEAN_CLONE_BASELINE.md`; the audit was committed separately from implementation. |
| CCP-001 | Verified | `FEATURE_MATRIX.md` uses the locked five-state contract, owner task, and verification evidence for every required feature. |
| CCP-100 | Verified | The rerunnable inventory extracts dependencies from all required source/resource formats and emits Markdown plus JSON classifications. |
| CCP-101 | Verified | Curated runtime assets, Git LFS rules, source-free paths, hash-to-license manifest, and five shipped license texts pass inventory validation. |
| CCP-102 | Automated verified | One safe `AudioManager` provides buses, mute/volume, crossfades, fixed pools, warnings, and 17 procedural SFX fallbacks; forced-missing audio passes. |
| CCP-103 | Automated verified | Twenty stages, 22 enemies, four bosses, player animation resources, terrain collision, and procedural diagnostic fallback load without ignored source art or Godot-icon gameplay fallback. |
| CCP-104 | Automated verified | Import and clean-clone gates instantiate autoloads, main scene, all campaign actors/stages, and required streams with strict engine-error detection. Final RC2 clean-clone rerun is part of candidate packaging. |
| CCP-200 | Automated verified | `RunState`, `CampaignProgress`, and orchestration responsibilities are split; schema/save tests cover new game, transitions, serialization, continue, and stage flags without live nodes. |
| CCP-201 | Automated verified | The campaign manifest validates every required field, uniqueness, deterministic order, dependencies, paths, counts, bounds, and final completion route. |
| CCP-202 | Automated verified | `StageBase` exports direct critical node paths; `StageController` initializes spawn/camera/music/checkpoints/encounters/exits/boss/HUD/restart without group or fuzzy critical lookup. |
| CCP-203 | Automated verified | Prototype builders/guides, enemy preview catalog, duplicate bullet/exit scenes, and stale scripts are removed; export filters exclude tools/tests and production stages contain no prototype labels. |

## Player, enemies, and shared mechanics

| Task | State | Production evidence / remaining gate |
|---|---|---|
| CCP-300 | Automated verified | Twelve explicit player states and incompatible-action locks pass state/combat/death/respawn tests. |
| CCP-301 | Implemented; manual gate open | Coyote time, buffering, variable jump, acceleration, air/wall control, swept dash, landing feedback, deadzone, vibration, and recovery buffering exist. Physical keyboard/controller checks at 30/60/120/144 FPS remain required. |
| CCP-302 | Automated verified | Ground/air combo data, startup/active/recovery, per-swing target deduplication, knockback, hit stun, cancels, feedback, and boss damage pass production tests. |
| CCP-303 | Automated verified | Spawn/collision/lifetime/rate/energy/HUD/boss interaction and the bounded projectile pool pass state, boss, and performance gates. |
| CCP-304 | Automated verified | Compact health/energy/regen/melee/ranged/dash upgrades alter measured values, persist, reset on new game, and are displayed in HUD/pause. |
| CCP-400 | Automated verified | All 22 production enemy scenes receive body, hurtbox, contact, floor/wall, sprite, VFX anchor, and configured detection; actual scenes detect and chase in tests. |
| CCP-401 | Automated verified | The library maps every enemy to one of 10 required archetypes; every act uses at least three, with flying/ranged logic, sized hitboxes, and telegraphs. |
| CCP-402 | Automated verified | Telegraph/attack/recovery/hurt/stunned/dead flow delegates timed attacks to `EnemyAttackController`; interruption and inactive hitboxes are tested. |
| CCP-403 | Automated verified | Explicit activation regions, arena barriers, waves/reinforcements, required completion, and death reset are used by at least two encounters in every standard stage. |
| CCP-404 | Automated verified | Per-act profiles tune health, damage, speed, frequency, detection, score, resistance, combinations, and elite rate; live initialized enemies are asserted and standard health scale is capped at 1.16. Final feel remains part of manual stage playtests. |
| CCP-500 | Automated verified | Full-stage bounds, vertical/camera zones, boss overrides/restoration, look-ahead/smoothing, locks, and respawn repositioning are implemented; every stage start/midpoint/exit is asserted. |
| CCP-501 | Implemented; manual gate open | Multi-point linear/ping-pong/loop paths, waits, triggers, speed, passenger-safe `AnimatableBody2D`, and deterministic reset pass mechanics tests. Physical passenger feel/input parity remains required. |
| CCP-502 | Automated verified | Ground, reversible, timed, hazardous conveyors provide frame-independent velocity, arrows, pooled motion audio, reset, and Act 2 traversal/combat usage. |
| CCP-503 | Automated verified | Reusable damage/kill/knockback/timing/telegraph/reset/audio/VFX behavior and separate laser, steam, electrical, falling, crusher, toxic, and void implementations pass independent tests. |
| CCP-504 | Automated verified | Low/high/zero-gravity zones affect players and compatible enemies, restore safely on exit/death, and appear as core Act 3 traversal/encounter mechanics. |
| CCP-505 | Automated verified | Tracking, burst, and rotating modes; destructible variants; LOS; world-colliding shots; telegraphs; terminals; persistence; and Act 3 usage are covered. |
| CCP-506 | Automated verified | Keyboard/controller prompts, terminals/switches/lore, timed/multi-switch gates, target validation, deterministic reset, and checkpoint/save persistence are covered. |

## Campaign content

All standard-stage rows below satisfy automated Stage Definition of Done checks for tracked assets, colliding terrain, spawn, bounds, two authored traversal sections, two authored encounters, mechanics, checkpoints, death zone, exit/next route, music, ambient presentation, collectible route, and absence of prototype/missing-resource residue. Every row still requires the plan's manual start-to-exit playtest.

| Task | State | Authored distinction |
|---|---|---|
| CCP-610 | Implemented; manual gate open | Tutorial prompts, jump/wall schools, melee/ranged introductions, checkpoint, optional roof collectibles, and fixed camera. |
| CCP-611 | Implemented; manual gate open | Multi-point billboard lifts, timed electrical signs, two encounters, high route, and two checkpoints. |
| CCP-612 | Implemented; manual gate open | Vertical/wall-jump routes, rotating signal lasers, flying encounters, midpoint checkpoint, and vertical camera zone. |
| CCP-613 | Implemented; manual gate open | Moving/breakaway bridges, mixed encounters, dash gap, and two-wave pre-boss gauntlet. |
| CCP-614 | Implemented; manual gate open | Helix Warden air arena, projectile arcs, dash, summoned zones, three phases, intro/defeat/exit, Act 2 unlock, and post-boss save. |
| CCP-710 | Implemented; manual gate open | Safe and combat conveyors, armored introduction, steam timing, factory presentation/music, and checkpoint. |
| CCP-711 | Implemented; manual gate open | Reversible/hazard belts, cargo platforms, falling parts, arena, and multiple waves. |
| CCP-712 | Implemented; manual gate open | Heat, steam, smelter pool, laser gates, and vertical machinery route. |
| CCP-713 | Implemented; manual gate open | Crushers, broken-machinery route, repair terminal/gate alternative, heavy/ranged crossfire, and pre-boss checkpoint. |
| CCP-714 | Implemented; manual gate open | Assembly Colossus ground/conveyor arena, slam/shockwave, machinery phase, vulnerability windows, three phases, Act 3 unlock/save. |
| CCP-810 | Implemented; manual gate open | Low/zero-gravity teaching, long gaps, compatible enemies, safe restoration, and checkpoint. |
| CCP-811 | Implemented; manual gate open | Security gate/terminal puzzle, laser cycles, ranged encounters, and optional lore terminal. |
| CCP-812 | Implemented; manual gate open | Vertical shaft, tracking/burst turrets, rotating grid, wall/low-gravity combination, and camera transition. |
| CCP-813 | Implemented; manual gate open | Heavy/inverse gravity, containment pool, ambushes, multi-switch route, and pre-boss checkpoint. |
| CCP-814 | Implemented; manual gate open | Lunar Oracle repositioning, inversion, patterns, laser sweep, arena hazards, three phases, Act 4 unlock/save. |
| CCP-910 | Implemented; manual gate open | Prior-mechanic escalation, corruption zones, elite variants, lift, and checkpoint. |
| CCP-911 | Implemented; manual gate open | Floating platforms, void pits, limited visibility, dash/wall mastery, and midpoint checkpoint. |
| CCP-912 | Implemented; manual gate open | Organic crushers, ambush nests, destructible corruption nodes, and linked route gate. |
| CCP-913 | Implemented; manual gate open | Conveyor/laser/gravity/platform mastery sequence, elites, and final pre-boss checkpoint. |
| CCP-914 | Implemented; manual gate open | Void Cerberus multi-head roster, corruption, dash/spread/breath sweep, distinct desperation phase, one-shot ending transition. |

## Bosses, shell, presentation, tests, and release

| Task | State | Production evidence / remaining gate |
|---|---|---|
| CCP-1000 | Automated verified | Dedicated controllers select unique authored rosters from projectile, dash, slam, shockwave, laser, summon, teleport, arena, gravity, and vulnerability attacks; phase/defeat assertions pass. |
| CCP-1001 | Automated verified | Intro lock/title/HUD/camera/music/phase feedback/defeat/exit/save and retry cleanup are production-wired; music returns after defeat. Presentation observation remains in boss playtests. |
| CCP-1100 | Automated verified | New/continue/stage-select/settings/credits/quit, overwrite confirmation, save-dependent availability, and initial focus pass shell tests. |
| CCP-1101 | Automated verified | Version/current stage/checkpoint/progress/bosses/upgrades/collectibles/scores/settings/completion/playtime use atomic temp/backup/checksum storage, recovery, migration, reset, and no live nodes. |
| CCP-1102 | Automated verified | Resume/checkpoint/stage/settings/title routes, pause behavior, focus confinement, and cleanup pass. |
| CCP-1103 | Automated verified | Independent persistent audio/display/VSync/shake/vibration/remapping settings apply immediately where possible and reject invalid display values. |
| CCP-1104 | Implemented; manual gate open | Reduced shake/flashing, contrast, remaps, deadzone, hold interaction, text equivalents, non-color cues, and UI scale persist. Resolution/visual accessibility matrix remains required. |
| CCP-1105 | Automated verified | Final transition, saved score/time/collectibles, credits/title, completion flag, stage-select unlock, and one-shot completion pass traversal/shell tests. |
| CCP-1200 | Automated verified | Signal-bound health/energy/score/upgrades/checkpoint/boss/prompt/objective HUD scales through anchors/settings and binds the explicit stage boss. Visual overlap is a manual matrix item. |
| CCP-1201 | Automated verified | Hit sparks/flash/freeze, scaled shake/vibration, boss phase feedback, and low-health indication use bounded effects and reduced-effects settings. Visual intensity remains a manual observation. |
| CCP-1202 | Implemented; manual gate open | Every stage installs act/stage-varied parallax assets, lighting palette, motes, pulse animation, foreground framing, and hazard language; adjacent-stage/readability checks remain visual playtests. |
| CCP-1203 | Implemented; manual gate open | Four act tracks, four boss mappings, movement/conveyor/combat/UI/hazard/checkpoint/clear/ending cues, fixed pooling, safe transitions, and complete attribution exist. Clipping/listening pass remains required. |
| CCP-1300 | Automated verified | Documented grouped CLI entrypoints cover import/parse/resources/unit/systems/campaign/traversal/save/export with timeouts, isolated logs, meaningful exits, and strict engine-error parsing. |
| CCP-1301 | Automated verified | Production coverage includes all listed detection/camera/exit/checkpoint/boss/retry/completion/audio/save/settings/player/hazard/InputMap gaps. |
| CCP-1302 | Implemented; external gate open | Six PR/main jobs, blocking export dependencies, pinned engine action, LFS, logs, and Windows artifact are committed. A remote green run requires pushing the release commit. |
| CCP-1303 | Automated verified | Clean-state traversal visits all 20 IDs in order, bypasses authored conditions only through test hooks, defeats bosses, reaches ending, returns to title, and completes once. |
| CCP-1400 | Implemented; manual gate open | Registry index, fixed 10-SFX/2-BGM players, bounded 64-projectile/32-VFX stress, node budget, and stage release pass. 1080p target-GPU frame pacing still requires capture. |
| CCP-1401 | Automated verified; clean-machine gate open | Strict Windows preset/version/icon/filtering exports by CLI and writes `user://` saves. Local extracted launch passes; an independent clean Windows machine remains required. |
| CCP-1402 | Automated verified | Packager requires executable/PCK/docs/controls/licenses/changelog/issues/version, scans forbidden content and absolute paths, writes SHA/hashes, validates ZIP, and has produced an extracted runnable candidate. RC2 is regenerated after the final commit. |
| CCP-1403 | Hardware/manual gate open | Automated corruption/missing-audio/save/encounter/boss/export paths pass, but the complete keyboard/controller/disconnect/remap, resolution/fullscreen/ultrawide, progression, failure-recovery, audio-device, and clean-machine matrix is not yet observed. |

## Release conclusion

The production software and automated verification requested by the plan are implemented. Milestones A through E meet their automated criteria. Milestone F and the `v1.0.0` tag remain intentionally blocked on:

1. The full manual start-to-exit campaign and input/display/accessibility/audio matrix.
2. Physical controller disconnect/reconnect and vibration observations.
3. Target-hardware 1080p frame-time capture.
4. A green remote GitHub Actions run for the release commit.
5. An independent clean-Windows-machine launch.

Until those observations are recorded in `docs/RELEASE_CHECKLIST.md`, the honest release state is `1.0.0-rc.2`, not final `v1.0.0`.
