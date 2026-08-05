# Version 1.0 feature contract

Status values are locked to: **Not started**, **Foundation only**, **Implemented**, **Verified**, and **Deferred after v1.0**. A file or class by itself never qualifies as implementation evidence.

| Feature | Current status | Owner phase/task | Required verification / evidence |
|---|---|---|---|
| Player movement | Implemented | CCP-300/301 | `PlayerStateTest` verifies transitions and movement helpers; frame-rate/controller hardware matrix remains manual. |
| Combat | Verified | CCP-302/303 | Production player/enemy and boss smoke tests cover damage, energy, projectiles, cleanup, and defeat. |
| Player upgrades | Verified | CCP-304 | State/save tests cover award levels, reset, save, recovery, and load. |
| Enemy behavior | Verified | CCP-400/404 | 22 production scenes and 10 archetypes instantiate, detect, attack, and reset in campaign/system tests. |
| Bosses | Verified | CCP-1000/1001 | Four unique rosters, phases, retry, cleanup, defeat, reward, HUD, and exit gates pass boss smoke. |
| Stage-specific mechanics | Verified | CCP-501/506 | Production runtime test covers moving/breakaway/conveyor platforms, hazards, gravity, turrets, terminals, and gates. |
| Checkpoints | Verified | CCP-202/403 | Campaign runtime and save tests verify every checkpoint plus persisted recovery/reset behavior. |
| Camera | Verified | CCP-500 | All 20 stage bounds and clamped start/midpoint/exit positions pass campaign runtime assertions. |
| Save/load | Verified | CCP-1101 | Atomic primary/backup, checksum, corruption recovery, migration schema, reset, and restart data pass. |
| Menus | Verified | CCP-1100/1102 | Shell flow covers six title routes, pause routes, confirmation, stage select, ending, and focus setup. |
| Settings | Verified | CCP-1103 | Independent atomic persistence, immediate application, and keyboard/controller-family remaps pass. |
| Controller support | Implemented | CCP-301/1100/1103 | Bindings, deadzone, focus, vibration, reconnect-safe keyboard fallback, and persistent remap exist; hardware matrix remains manual. |
| Accessibility | Implemented | CCP-1104 | Reduced flashing, shake, vibration, contrast, hold interaction, deadzone, cues, and UI scale persist; visual matrix remains manual. |
| Audio | Verified | CCP-102/1203 | Clean/missing manifests, 14 procedural fallbacks, fixed pools, crossfade behavior, and licenses pass. |
| VFX | Verified | CCP-103/1201/1202 | Clean load, reduced-effects response, and bounded one-shot cleanup pass; final visibility check remains manual. |
| Stage progression | Verified | CCP-201/202/1303 | Clean-state traversal visits all 20 production stage IDs in order and completes exactly once. |
| Ending/results | Verified | CCP-1105 | Final completion reaches results once with title/continue behavior covered by traversal and shell tests. |
| Credits | Implemented | CCP-1105/1402 | Credits route/focus and complete runtime attribution exist; physical-controller observation remains manual. |
| Export | Verified | CCP-1401/1402 | Command-line Windows export, forbidden-content scan, archive extraction, and packaged headless launch pass locally. |
| CI | Implemented | CCP-1300/1302 | Six pinned jobs, blocking dependencies, logs, and Windows artifact are committed; remote green run requires push/PR. |
| Performance | Implemented | CCP-1400 | Runtime index, fixed pools, bounded 64-projectile/32-VFX stress and transition release pass; 1080p GPU capture remains manual. |
| Licensing | Verified | CCP-101/1203/1402 | All 182 runtime binaries map by hash to one of five included license texts; Godot MIT attribution ships. |

## Locked v1.0 definition

All items in the plan's final release definition of done are in scope. No listed system is deferred after v1.0. Manual clean-machine and hardware checks must be recorded separately because headless automation cannot substitute for those observations.

The user's instruction to implement `CYBER_CITY_PLATFORMER_FULL_COMPLETION_PLAN.md` is the approval for this feature contract. Any later scope change must be reflected here and in the completion plan.
