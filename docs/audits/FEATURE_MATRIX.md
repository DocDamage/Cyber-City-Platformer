# Version 1.0 feature contract

Status values are locked to: **Not started**, **Foundation only**, **Implemented**, **Verified**, and **Deferred after v1.0**. A file or class by itself never qualifies as implementation evidence.

| Feature | Baseline status | Owner phase/task | Required verification |
|---|---|---|---|
| Player movement | Foundation only | CCP-300/301 | State-transition tests plus keyboard/controller playtest at 30/60/120/144 FPS. |
| Combat | Foundation only | CCP-302/303 | Active-frame, single-hit, projectile-wall, cleanup, energy, enemy, and boss tests. |
| Player upgrades | Not started | CCP-304 | Upgrade effect, reset, save, load, and boss-compatibility tests. |
| Enemy behavior | Foundation only | CCP-400/404 | Instantiate production scenes; verify detection, archetype attacks, reset, and balance envelope. |
| Bosses | Foundation only | CCP-1000/1001 | Unique-roster, phase-threshold, retry, cleanup, defeat, save, and exit-unlock tests. |
| Stage-specific mechanics | Not started | CCP-501/506 | Production-stage tests for platforms, conveyors, hazards, gravity, turrets, terminals, and gates. |
| Checkpoints | Foundation only | CCP-202/403 | Every production checkpoint registers, persists, restores, and resets encounter/hazard state. |
| Camera | Foundation only | CCP-500 | Start/midpoint/exit and vertical-zone assertions for all 20 stages. |
| Save/load | Not started | CCP-1101 | Restart persistence, atomic write, backup recovery, corruption, migration, and reset tests. |
| Menus | Not started | CCP-1100/1102 | Keyboard/controller focus and every title/pause route in production scenes. |
| Settings | Not started | CCP-1103 | Persistence and immediate audio/display/input application tests. |
| Controller support | Foundation only | CCP-301/1100/1103 | Xbox-compatible controller, deadzone, reconnect, focus, vibration, and remap matrix. |
| Accessibility | Not started | CCP-1104 | Persisted reduced-effects, flashing, contrast, deadzone, toggle, cue, and UI-scale checks. |
| Audio | Foundation only | CCP-102/1203 | Clean clone with and without optional files, bus settings, crossfade, pooling, and license audit. |
| VFX | Foundation only | CCP-103/1201/1202 | Clean-clone load, bounded lifetime, reduced-effects response, and visibility playtest. |
| Stage progression | Foundation only | CCP-201/202/1303 | Deterministic traversal of all 20 production stage IDs in order. |
| Ending/results | Not started | CCP-1105 | Final defeat triggers once; values are accurate; title return and continue behavior remain valid. |
| Credits | Not started | CCP-1105/1402 | Controller-accessible credits plus complete runtime attribution cross-check. |
| Export | Not started | CCP-1401/1402 | Clean command-line Windows export and extracted-package launch. |
| CI | Not started | CCP-1300/1302 | Required jobs run on pushes/PRs, fail correctly, and publish logs/build artifact. |
| Performance | Not started | CCP-1400 | Profiled 1080p frame-time, bounded pools/effects, transition release, and no gameplay scans. |
| Licensing | Foundation only | CCP-101/1203/1402 | Every shipped third-party file maps to an included license; no unknown asset ships. |

## Locked v1.0 definition

All items in the plan's final release definition of done are in scope. No listed system is deferred after v1.0. Manual clean-machine and hardware checks must be recorded separately because headless automation cannot substitute for those observations.

The user's instruction to implement `CYBER_CITY_PLATFORMER_FULL_COMPLETION_PLAN.md` is the approval for this feature contract. Any later scope change must be reflected here and in the completion plan.
