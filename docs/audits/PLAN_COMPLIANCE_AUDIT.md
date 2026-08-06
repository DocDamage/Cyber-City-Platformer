# Full completion plan compliance audit

Audit date: 2026-08-05

Branch: `feature/full-game-completion`

Target: connected-world production validation on Godot `4.7.1.stable.official.a13da4feb`

The original twenty-stage completion contract below remains valid as legacy-mode evidence. The active `CYBER_CITY_METROIDVANIA_PRODUCTION_PLAN.md` extends it with character creation and a 202-room connected world; current evidence is summarized in `docs/implementation/COMPLETION_EVIDENCE.md`.

This audit maps every implementation task in `CYBER_CITY_PLATFORMER_FULL_COMPLETION_PLAN.md` to production evidence. “Automated verified” means the implementation and its production wiring pass a headless gate. It does not stand in for the plan's explicitly required human or hardware observations.

## Evidence anchors

- `python tools/inventory_runtime_assets.py --check`: tracked runtime dependency and license gate.
- `python tools/run_headless_suite.py --group all`: 36 isolated import/resource/unit/system/campaign/world/shell commands; engine error lines fail even when Godot returns zero.
- `tests/campaign/CampaignContentTest.gd`: all 20 blueprints, required stage evidence IDs, live act balance, 23 mechanic kinds, two traversal/combat sections per standard stage, and four distinct bosses.
- `tests/campaign/CampaignRuntimeTest.gd`: production scene structure, metadata, checkpoints, exits, encounters, and camera bounds.
- `tests/campaign/CampaignTraversalTest.gd`: deterministic `1-1` through `4-5`, boss bypass hooks, one completion event, ending, and title return.
- `tests/integration/FirstTwoActsProductionTest.gd`: all ten Act 1/2 stage loads and handoffs, manifest-driven entry cards, real spawn movement/jump response, live body-contact landings on all eighteen authored traversal sections, regular/boss objective completion, exit copy and unlocks, checkpoint/collectible budgets, boss HUD bounds, regional persistence, and seven distinct hero panoramas. `scripts/testing/LegacyActCapture.gd` supplies thirty export-excluded real-renderer start/signature/finish frames for visual review.
- `tests/integration/LastTwoActsProductionTest.gd`: all ten Act 3/4 stage loads, real movement/jump response, checkpoints, collectibles, objective/boss completion, persistence, handoffs, and ending. It verifies ten distinct 1672×941 panoramas, 43 regional traversal decks, 28 lunar/abyssal structural assemblies, Security Grid Shaft overscan, and absence of earlier-act architecture fallback.
- `tests/integration/StageMechanicsTest.gd`: independent moving-platform, conveyor, gate/switch, gravity, turret, and eight-hazard contracts.
- `tests/integration/EnemyContractTest.gd`: all 22 schema-2 definitions, actual region placement, live combat/leash/stagger/drop/collision configuration, difficulty variants, and the source-only roster lab.
- `scripts/BossSystemsSmokeTest.gd`: unique rosters, phase thresholds, retry cleanup, defeat, reward, HUD, and exit behavior.
- `tests/integration/SaveSettingsTest.gd` and `ShellFlowTest.gd`: atomic saves, recovery/migration, settings/remaps, title/pause/routes, results, and credits.
- `tests/integration/PerformanceBudgetTest.gd`: all-room streaming/load telemetry, real fade transitions, UI/save/memory/player-layer/enemy/audio budgets, bounded runtime pools, and stage release.
- `tests/integration/WorldContentAuditTest.gd`: all 202 rooms instantiate; 162 critical and forty optional rooms meet district budgets; all 103 expansion rooms have unique static geometry, stable layout provenance, and a district spatial rhythm. It also validates twenty unique art profiles, skylines, landmarks, palettes, forty exclusive prop assignments, atmosphere, foreground, and platform trim. Persistent IDs/caches, narrative/quest event sources, NPC dialogue, boss intro/defeat sequences, rewards, and cutscene skip endpoints cross-validate.
- `tests/integration/WorldTraversalProbeTest.gd`: seven authored checkpoints exercise production collision and movement parameters for standard/wall/dash/teleport/low-gravity/moving-platform/fall-recovery routes.
- `tests/integration/QuestProgressionTest.gd`: four production quests, HUD/Journal output, every authored event, save/load persistence, and empty-legacy-state reconstruction.
- `.github/workflows/ci.yml`, `export_presets.cfg`, and `tools/package_release.py`: remote gates, strict Windows export, content scan, and archive metadata.

## Connected-world plan crosswalk

This table maps the active `CYBER_CITY_METROIDVANIA_PRODUCTION_PLAN.md` by numbered production area. “Automated verified” applies only to behavior observable by deterministic local gates; it never substitutes for the plan's human, hardware, integration, or approval requirements.

| Plan area | State | Evidence / open gate |
|---|---|---|
| 5. Product decisions | Implemented | Godot 4.7.1, 960×540 internal viewport, Windows export, continuous world, legacy mode, six families, and universal marker teleport are locked. Independent hardware and final version approval remain open. |
| 6. Technical architecture | Automated verified | Split state/catalog/world/presentation systems, data-authored JSON, direct critical paths, source-free runtime index, and autoload boundaries pass import/resource/state tests. |
| 7. Save/profile model | Automated verified | Schema 2, three slots, profile/equipment/inventory/ability/world/narrative/quest state, persistent optional caches, checksum, atomic backup recovery, migration, and post-game continuation pass. |
| 8–10. Creator, portraits, voice | Automated and 1280×720 path verified; manual matrix open | Name/pronouns, layered appearance, twelve portraits, five voice profiles, exact live previews, save round trips, subtitles, responsive action visibility, real randomization, and uncropped creator rendering pass. Human review of every option, clip, and visual combination remains open. |
| 11. Weapons/equipment | Automated verified; manual gate open | Six family data sets, fourteen collectable weapon items, family-safe equip rules, live/portrait preview, move summary, sort/filter, stat comparison, descriptions/lore, and saved body/two-accessory slot state pass. All-family human boss/readability/feel runs remain open. |
| 12. Thrown-marker teleport | Automated verified; manual gate open | Hold/tap aim, throw/attach/recall/warp, full-body/forbidden/bounds/range checks, mouse/right-stick response, aim assist, high contrast, and recovery pass. Physical-stick feel and every route remain human gates. |
| 13. Progression/items | Automated verified | Seven regional abilities, six-family optional rewards, backtracking barriers/shortcuts, inventory uniqueness/stacks/currency, a schema-2 item presentation contract with six curated family icons and a robust locked/unknown fallback, and save persistence cross-validate. |
| 14. World structure | Automated verified; partial live path observed | One reachable 202-room, four-region, twenty-district graph and 162-room critical route pass for all families. Every district has 8–14 critical rooms, 2–5 optional rooms, and a 15–20 minute authored critical total; a live transition and tutorial room pass without duplicate titles or HUD overlap. Full human pacing/navigation/softlock runs remain open. |
| 15. UI/UX | Automated verified; visual gate open | Title, slots, creator, map/legend/warps, valid 21-step main-objective destinations, service markers, overall/regional completion, six pause tabs, Equipment, separated Inventory taxonomy, normalized nearest-neighbor icons, locked fallback, Abilities, Journal, Settings, ending, focus, live prompts, and immediate updates pass. Rendered overlap/readability and physical-controller navigation remain manual. |
| 16. Input/controller | Automated verified; hardware gate open | Twenty-one rebindable actions, sixteen dual-input actions, sixteen unique simultaneous controller signatures, live device-family prompts, persistent remaps, and keyboard fallback pass. Xbox/PlayStation/generic identification and disconnect/reconnect remain hardware gates. |
| 17. Enemies/encounters | Automated verified; feel gate open | Twenty-two complete schema-2 enemy contracts, ten archetypes, live leash/timing/stagger/resistance/drop/collision/audio/VFX/elite behavior, complementary waves, reset, persistence, and roster lab pass. Human formation/fairness/readability review remains open. |
| 18. Bosses | Automated verified; human gate open | Four unique three-phase bosses, arenas, intros, defeat flows, rewards, retry cleanup, saves, and ending route pass. Weapon-neutral punish fairness and spectacle/audio observation remain manual. |
| 19. District briefs | Structural and rendered evidence; human gate open | `WorldContentAuditTest` enforces a distinct required signature, 8–14 critical rooms, 2–5 optional rooms, teach/test/twist/recovery roles for the nineteen expanded districts, 103 unique expansion platform signatures derived from twenty district spatial rhythms, twenty unique art profiles with forty exclusive props, meaningful persistent optional caches, and a 900–1200-second critical budget for every district. A real OpenGL capture renders one representative room per district. Regional production tests exercise mechanics, persistent controls, bosses, and saves. Human start-to-exit pacing, navigation, combat fairness, readability, and optional-route value remain open. |
| 20. Narrative/quests | Automated plus live persistence verified; editorial gate open | Four quests, 33 story sequences, personalized dialogue, pronoun resolution, NPC states, lore records, boss sequences, skip endpoints, atomic endpoint autosaves, finale, credits, and post-game pass. A live prologue completion/relaunch proves no sequence replay and the next objective persists. Full editorial/voice listening review remains open. |
| 21. Audio | Automated verified; listening gate open | Five buses, four act tracks, four boss mappings, four generated regional ambience loops, 17 SFX plus fallbacks, voice routing, crossfades, fixed pools, settings, and attribution pass. Clipping, balance, and device-switch listening remain open. |
| 22–23. VFX, lighting, camera | Automated verified; visual gate open | Bounded effects, reduced flashing, region palettes/parallax/foregrounds, hazard cues, camera bounds/zones/look-ahead/boss overrides, and cleanup pass. Visual clarity, intensity, and motion comfort remain human gates. |
| 24. Performance | Regression verified; hardware gate open | All rooms, transitions, UI, saves, memory, player surfaces, enemy/audio counts, 64 projectiles, 32 VFX, node bounds, and cleanup pass. Truthful 1080p/1440p GPU frame time and draw calls require target hardware. |
| 25. Accessibility | Automated verified; human gate open | Text speed/instant/auto, bark controls/subtitles, five-bus volumes, shake/vibration/flash/contrast, aim assist, independent aim deadzone/response, hold/tap options, non-color cues, and UI scale persist. Comfort and legibility observation remains open. |
| 26. Testing | Locally automated verified | The strict 36-process suite is green, including separate ten-stage production gates for Acts 1–2 and Acts 3–4. Human playthrough, device, display, audio, recovery, and clean-machine matrices remain open. |
| 27–28. Build/release/workflow | Locally verified; integration gates open | Dirty validation export/PCK scan/package/extract/headless launch pass; reports, checklists, CI, and changelog exist. Source integration, clean clone, remote CI, clean package, and independent machine remain open. |
| 29. Final definition of done | Not promotable | Locally automatable software gates are green, but the open human, hardware, remote, clean-source, and independent-machine gates prevent RC/final claims. |

## Foundation and architecture

| Task | State | Production evidence / remaining gate |
|---|---|---|
| CCP-000 | Verified | Baseline SHA, clean-clone reproduction, engine version, failures, and branch are recorded in `CLEAN_CLONE_BASELINE.md`; the audit was committed separately from implementation. |
| CCP-001 | Verified | `FEATURE_MATRIX.md` uses the locked five-state contract, owner task, and verification evidence for every required feature. |
| CCP-100 | Verified | The rerunnable inventory extracts dependencies from all required source/resource formats and emits Markdown plus JSON classifications. |
| CCP-101 | Verified | All 314 curated runtime assets, Git LFS rules, source-free paths, hash-to-license manifest, seventeen panorama and twelve traversal-kit stable generated-asset provenance records, and five shipped license texts pass local asset validation. A fresh-clone inventory rerun remains a release gate. |
| CCP-102 | Automated verified | One safe `AudioManager` provides independent Music/SFX/UI/Ambience/Voice buses, mute/volume, crossfades, fixed pools, four generated regional ambience profiles, warnings, and 17 procedural SFX fallbacks; forced-missing audio passes. |
| CCP-103 | Automated verified | Twenty stages, 22 enemies, four bosses, player animation resources, terrain collision, and procedural diagnostic fallback load without ignored source art or Godot-icon gameplay fallback. |
| CCP-104 | Automated verified | Import and clean-clone gates instantiate autoloads, main scene, all campaign actors/stages, and required streams with strict engine-error detection. A final clean-clone rerun remains required after the connected-world worktree is integrated. |
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
| CCP-400 | Automated verified | All 22 production enemy scenes receive body/hurt/contact collision, floor/wall assumptions, sprite maps, VFX/audio profiles, region assignments, drops, and configured detection/leash rules; the shared roster lab and live instance checks pass. |
| CCP-401 | Automated verified | Schema 2 maps every enemy to one of 10 archetypes with health/damage/speed/stagger/resistance/navigation contracts; every act uses at least three, with flying/ranged logic, sized hitboxes, and authored telegraphs. |
| CCP-402 | Automated verified | Per-enemy telegraph/active/recovery/punish timings drive attack flow; hurt/staggered/dead states, interruption, inactive hitboxes, currency drops, and authored score values are tested. |
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

All standard-stage rows below satisfy automated Stage Definition of Done checks for tracked assets, colliding terrain, spawn, bounds, two authored traversal sections, two authored encounters, mechanics, checkpoints, death zone, exit/next route, music, ambient presentation, collectible route, and absence of prototype/missing-resource residue. Acts 1–2 additionally pass the ten-stage production test and real-renderer review, with all ten entry cards, real spawn movement/jump response, live landings on all eighteen authored traversal sections, district-native tile surfaces and visible architecture assemblies on all 70 shared traversal decks, 41 normal-movement route links checked against the player kinematics, seven stage-specific hero panoramas, corrected objective copy, readable factory lighting, framed lockdown gates, and bounded boss HUDs. Acts 3–4 additionally pass a second ten-stage production gate with real player control, full objective/boss/ending flow, ten stage-specific panoramas, 43 terrain decks, 28 regional assemblies, vertical overscan, and no earlier-act architecture fallback. Every row still requires the plan's manual start-to-exit feel playtest.

| Task | State | Authored distinction |
|---|---|---|
| CCP-610 | Implemented; manual gate open | Tutorial prompts, jump/wall schools, melee/ranged introductions, checkpoint, optional roof collectibles, and fixed camera. |
| CCP-611 | Implemented; manual gate open | Multi-point billboard lifts, timed electrical signs, two encounters, high route, and two checkpoints. |
| CCP-612 | Implemented; manual gate open | Vertical/wall-jump routes, rotating signal lasers, flying encounters, midpoint checkpoint, and vertical camera zone. |
| CCP-613 | Implemented; manual gate open | Moving/breakaway bridges, mixed encounters, dash gap, and two-wave pre-boss gauntlet. |
| CCP-614 | Implemented; manual gate open | Helix Warden air arena, projectile arcs, dash, summoned zones, three phases, intro/defeat/exit, Act 2 unlock, and post-boss save. |
| CCP-710 | Implemented; manual gate open | Safe and combat conveyors, armored introduction, terrain-clear steam timing platforms with verified player landings, factory presentation/music, and checkpoint. |
| CCP-711 | Implemented; manual gate open | Reversible/hazard belts, cargo platforms, falling parts, arena, and multiple waves. |
| CCP-712 | Implemented; manual gate open | Heat, steam, smelter pool, laser gates, and vertical machinery route. |
| CCP-713 | Implemented; manual gate open | Crushers, broken-machinery route, repair terminal/gate alternative, heavy/ranged crossfire, and pre-boss checkpoint. |
| CCP-714 | Implemented; manual gate open | Assembly Colossus ground/conveyor arena, slam/shockwave, machinery phase, vulnerability windows, three phases, Act 3 unlock/save. |
| CCP-810 | Automated verified; manual gate open | Low/zero-gravity teaching, long gaps, compatible enemies, safe restoration, distinct lunar arrival panorama/assembly, and checkpoint. |
| CCP-811 | Automated verified; manual gate open | Security gate/terminal puzzle, laser cycles, ranged encounters, optional lore terminal, and cleanroom presentation. |
| CCP-812 | Automated verified; manual gate open | Vertical shaft, tracking/burst turrets, rotating grid, wall/low-gravity combination, camera transition, and verified background overscan. |
| CCP-813 | Automated verified; manual gate open | Heavy/inverse gravity, containment pool, ambushes, multi-switch route, pre-boss checkpoint, and bio-tech presentation. |
| CCP-814 | Automated verified; manual gate open | Lunar Oracle repositioning, inversion, patterns, laser sweep, arena hazards, three phases, Act 4 unlock/save, and orbital command presentation. |
| CCP-910 | Automated verified; manual gate open | Prior-mechanic escalation, corruption zones, elite variants, lift, checkpoint, and corrupted-outpost presentation. |
| CCP-911 | Automated verified; manual gate open | Floating platforms, void pits, limited visibility, dash/wall mastery, midpoint checkpoint, and chasm presentation. |
| CCP-912 | Automated verified; manual gate open | Organic crushers, ambush nests, destructible corruption nodes, linked route gate, and biomechanical-nest presentation. |
| CCP-913 | Automated verified; manual gate open | Conveyor/laser/gravity/platform mastery sequence, elites, final pre-boss checkpoint, and sanctuary presentation. |
| CCP-914 | Automated verified; manual gate open | Void Cerberus multi-head roster, corruption, dash/spread/breath sweep, distinct desperation phase, one-shot ending transition, and heart-of-the-void presentation. |

## Bosses, shell, presentation, tests, and release

| Task | State | Production evidence / remaining gate |
|---|---|---|
| CCP-1000 | Automated verified | Dedicated controllers select unique authored rosters from projectile, dash, slam, shockwave, laser, summon, teleport, arena, gravity, and vulnerability attacks; phase/defeat assertions pass. |
| CCP-1001 | Automated verified | Intro lock/title/HUD/camera/music/phase feedback/defeat/exit/save and retry cleanup are production-wired; music returns after defeat. Presentation observation remains in boss playtests. |
| CCP-1100 | Automated verified | New/continue/stage-select/settings/credits/quit, overwrite confirmation, save-dependent availability, and initial focus pass shell tests. |
| CCP-1101 | Automated verified | Version/current stage/checkpoint/progress/bosses/upgrades/collectibles/scores/settings/completion/playtime use atomic temp/backup/checksum storage, recovery, migration, reset, and no live nodes. |
| CCP-1102 | Automated verified | Resume/checkpoint/stage/settings/title routes, six pause tabs, fourteen-item Equipment/Inventory sort/filter/stat/lore flow, weapon/key-item/material taxonomy, six family icons, locked fallback, pause behavior, focus confinement, and cleanup pass. |
| CCP-1103 | Automated verified | Independent persistent audio/display/VSync/shake/vibration/remapping settings apply immediately where possible; twenty-one rebindable actions, device-aware prompts, and independent phase-aim deadzone/response pass. |
| CCP-1104 | Implemented; manual gate open | Sixteen dual-input actions have conflict-free keyboard/controller access; dialogue and menus pause world simulation; text/subtitle/bark, five-bus audio, shake/vibration, reduced-flash, contrast, aim-assist, teleport hold/tap, remap, movement/aim deadzones, hold interaction, non-color cue, and UI-scale controls persist. Physical-device and visual accessibility observations remain required. |
| CCP-1105 | Automated verified | Final transition, saved score/time/collectibles, credits/title, completion flag, stage-select unlock, and one-shot completion pass traversal/shell tests. |
| CCP-1200 | Automated verified | Signal-bound health/energy/score/upgrades/checkpoint/boss/prompt/objective HUD scales through anchors/settings and binds the explicit stage boss. Both Act 1/2 boss panels are bounded and non-overlapping at the 960×540 internal canvas; broader display/accessibility observation remains manual. |
| CCP-1201 | Automated verified | Hit sparks/flash/freeze, scaled shake/vibration, boss phase feedback, and low-health indication use bounded effects and reduced-effects settings. Visual intensity remains a manual observation. |
| CCP-1202 | Automated verified; manual gate open | Every stage installs act/stage-varied parallax assets, lighting palette, motes, pulse animation, foreground framing, and hazard language. Acts 1–2 have real-render start/signature/finish review and seven distinct panoramas; Acts 3–4 have deterministic presentation coverage for ten additional panoramas, regional layer tints, overscan, and regional assemblies. Remaining adjacent-stage/readability feel checks stay in the human playtest matrix. |
| CCP-1203 | Implemented; manual gate open | Four act tracks, four boss mappings, four regional ambience profiles, movement/conveyor/combat/UI/hazard/checkpoint/clear/ending cues, fixed pooling, safe transitions, and complete attribution exist. Clipping/listening pass remains required. |
| CCP-1300 | Automated verified | Documented grouped CLI entrypoints cover import/parse/resources/unit/systems/campaign/traversal/save/export with timeouts, isolated logs, meaningful exits, and strict engine-error parsing. |
| CCP-1301 | Automated verified | Production coverage includes all listed detection/camera/exit/checkpoint/boss/retry/completion/audio/save/settings/player/hazard/InputMap gaps. |
| CCP-1302 | Implemented; external gate open | Six PR/main jobs, blocking export dependencies, pinned engine action, LFS, logs, and Windows artifact are committed. A remote green run requires pushing the release commit. |
| CCP-1303 | Automated verified | Clean-state traversal visits all 20 IDs in order, bypasses authored conditions only through test hooks, defeats bosses, reaches ending, returns to title, and completes once. |
| CCP-1400 | Implemented; manual gate open | All 202 room builds, representative fade transitions, map/inventory opening, atomic saves, three-room static memory, ten-layer player proxy, enemy/audio counts, fixed 10-SFX/2-BGM pools, 64-projectile/32-VFX stress, node budgets, and release cleanup pass. 1080p/1440p target-GPU frame pacing and actual draw calls still require capture. |
| CCP-1401 | Locally verified; clean-machine gate open | The strict Windows preset/version/icon/filtering exports by CLI, excludes generated `build/` content, and writes `user://` saves. The earlier dirty connected-world archive extracts and launches headlessly without engine/script errors; a clean rerun with the final later-act panoramas and an independent clean Windows machine remain required. |
| CCP-1402 | Locally verified; clean package gate open | The packager requires executable/PCK/docs/controls/licenses/changelog/issues/version, scans forbidden content and absolute paths (including roster-lab and capture/review residue), reports distinct source/archive SHA values, and validates the ZIP. The historical 55,410,492-byte PCK contains the reviewed catwalk, skybridge, conveyor, and crusher kit resources but predates the final later-act panoramas; regenerate it without `--allow-dirty` from this delivery commit. |
| CCP-1403 | Hardware/manual gate open | Automated corruption/missing-audio/save/encounter/boss/export paths pass, but the complete keyboard/controller/disconnect/remap, resolution/fullscreen/ultrawide, progression, failure-recovery, audio-device, and clean-machine matrix is not yet observed. |

## Release conclusion

The production software and automated verification requested by the legacy contract and the connected-world extension are implemented. The delivery branch is an unpromoted candidate; alpha, beta, release-candidate, and final-release gates remain intentionally blocked on:

1. The full manual start-to-exit campaign and input/display/accessibility/audio matrix.
2. Physical controller disconnect/reconnect and vibration observations.
3. Target-hardware 1080p frame-time capture.
4. A green remote GitHub Actions run for the release commit.
5. An independent clean-Windows-machine launch.
6. A fresh clean-clone suite and package rerun from this delivery commit.

Until those observations are recorded in `docs/RELEASE_CHECKLIST.md`, `VERSION` retains the inherited legacy identifier (`1.0.0-rc.2`). The historical dirty connected-world validation archive is unreleased and must not be represented as final `v1.0.0` or as an integrated RC.
