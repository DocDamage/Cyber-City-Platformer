# Version 1.0 feature contract

Status values are locked to: **Not started**, **Foundation only**, **Implemented**, **Verified**, and **Deferred after v1.0**. A file or class by itself never qualifies as implementation evidence.

| Feature | Current status | Owner phase/task | Required verification / evidence |
|---|---|---|---|
| Player movement | Implemented | CCP-300/301 | `PlayerStateTest` verifies transitions and movement helpers; frame-rate/controller hardware matrix remains manual. |
| Combat | Verified | CCP-302/303 | Production player/enemy and boss smoke tests cover damage, energy, projectiles, cleanup, and defeat. |
| Character creation | Verified | MV-001–MV-005 | `CharacterCreationFlowTest` covers slot selection, all profile fields, live layered preview, initial equipment, WorldRoot entry, and save/load round trip. |
| Player upgrades | Verified | CCP-304/MV-6–MV-9 | State/save and regional production tests cover upgrades plus Magnetic Rail, Phase Barrier, Ground Break, Gravity Anchor, Chain Teleport, Corruption Resistance, and Energy Field. |
| Enemy behavior | Verified | CCP-400/404 | `EnemyContractTest` validates 22 schema-2 contracts and 10 archetypes across live region assignments, navigation/leash, attack windows, stagger/resistance, drops, animation/collision, audio/VFX, act/elite variants, and the shared source-only roster lab. |
| Bosses | Verified | CCP-1000/1001/MV-6–MV-9 | Four unique bosses pass system tests and also stream in their connected-world arenas with persistent rewards and no respawn after reload. |
| Stage/world mechanics | Verified | CCP-501/506/MV-6–MV-9 | Tests cover moving/breakaway/conveyor platforms, gravity, corruption, nine hazard classes, camera/visibility zones, turrets, terminals, switches, persistent gates, shortcuts, and warps. |
| Checkpoints | Verified | CCP-202/403 | Campaign runtime and save tests verify every checkpoint plus persisted recovery/reset behavior. |
| Camera | Verified | CCP-500 | All 20 stage bounds and clamped start/midpoint/exit positions pass campaign runtime assertions. |
| Save/load | Verified | CCP-1101 | Atomic primary/backup, checksum, corruption recovery, migration schema, reset, and restart data pass. |
| Menus | Verified | CCP-1100/1102 | Shell flow covers six title routes and six pause tabs, including fourteen weapon items, Equipment sort/filter/stat comparison/live preview, six curated family icons plus a locked fallback, separated Inventory taxonomy, confirmation, stage select, ending, and focus setup. |
| Settings | Verified | CCP-1103 | Independent atomic persistence, immediate application, and keyboard/controller-family remaps pass. |
| Controller support | Implemented | CCP-301/1100/1103 | Twenty-one actions are rebindable, sixteen have explicit dual-input access, and sixteen simultaneous controller signatures are unique; live prompts, focus, vibration, keyboard fallback, and family-preserving remaps pass. Physical-device/disconnect matrix remains manual. |
| Accessibility | Implemented | CCP-1104 | Dialogue/menu pause, text/subtitle/bark controls, five-bus volume, reduced flashing, shake, vibration, contrast, aim assist, teleport hold/tap, hold interaction, separate movement/phase-aim deadzone and aim response, non-color cues, and UI scale persist; physical/visual matrix remains manual. |
| Audio | Verified | CCP-102/1203 | Clean/missing manifests, independent Music/SFX/UI/Ambience/Voice buses, four generated regional ambience profiles, 17 procedural SFX fallbacks, fixed pools, routed UI cues, crossfade behavior, and licenses pass. |
| VFX | Verified | CCP-103/1201/1202 | Clean load, reduced-effects response, and bounded one-shot cleanup pass; final visibility check remains manual. |
| World progression | Verified | MV-4–MV-9 | The unique 202-room graph covers twenty districts with 162 critical and forty optional rooms; its 103 expansion rooms have unique platform signatures, stable layout provenance, and twenty district spatial rhythms. A twenty-profile art bible supplies distinct palettes, skylines, landmarks, paired props, atmosphere, foreground framing, and platform trim; all rooms instantiate it and representative OpenGL renders have been reviewed. Map links, all 21 main-objective room targets, service markers, and regional/overall completion calculation are validated. All five relay destinations execute with story/boss/cutscene locks, and regional tests verify persistent abilities, caches, shortcuts, four bosses, and save-safe traversal. `FullGameProgressionTest` validates the complete critical route for all six starting families. |
| Stage progression | Verified | CCP-201/202/1303 | Clean-state traversal visits all 20 legacy production stage IDs in order and completes exactly once. The Acts 1–2 gate validates ten handoffs/objective exits, both regional finales, seven distinct hero panoramas, and boss HUD bounds; the Acts 3–4 gate validates the remaining ten stages through objectives, persistence, bosses, handoffs, and ending with ten distinct panoramas, 43 traversal decks, and 28 regional assemblies. |
| Ending/results | Verified | CCP-1105/MV-9 | Final world completion reaches a skippable personalized ending with name/pronouns/portrait/live visual, saved completion state, credits/title, and explicit post-game continuation. |
| Credits | Implemented | CCP-1105/1402 | Credits route/focus and complete runtime attribution exist; physical-controller observation remains manual. |
| Export | Verified | CCP-1401/1402 | Command-line Windows export, forbidden-content scan, archive extraction, and packaged headless launch pass locally. |
| CI | Implemented | CCP-1300/1302 | Six pinned jobs, blocking dependencies, logs, and Windows artifact are committed; remote green run requires push/PR. |
| Performance | Implemented | CCP-1400 | All 202 room loads, representative transitions, UI opens, saves, three-room memory, player-layer/enemy/audio counts, all 286 registry-managed plus 28 direct runtime paths, bounded 64-projectile/32-VFX stress, and release cleanup pass; GPU frame-time/draw-call capture remains manual. |
| Licensing | Verified | CCP-101/1203/1402 | All 314 runtime binaries map by hash to one of five included license texts, with seventeen generated panoramas and twelve generated traversal-kit assets carrying stable `generated://` provenance; Godot MIT attribution ships. |

## Locked v1.0 definition

All items in the plan's final release definition of done are in scope. No listed system is deferred after v1.0. Manual clean-machine and hardware checks must be recorded separately because headless automation cannot substitute for those observations.

The user's instruction to implement `CYBER_CITY_PLATFORMER_FULL_COMPLETION_PLAN.md` is the approval for this feature contract. The connected-world expansion now enforces the plan's general eight-to-fourteen critical-room and two-to-five optional-room guidance for every district. Any later scope change must be reflected here and in the completion plan.
