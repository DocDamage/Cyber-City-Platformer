# Connected-world release checklist

Validation state: integrated delivery branch; local automated gates green, remote and human release gates pending

Engine: Godot `4.7.1.stable.official.a13da4feb`

Date: 2026-08-05

## Automated implementation gates

- [x] Local import and strict parse/error scan pass.
- [x] All 36 isolated headless tests pass.
- [x] Legacy Acts 1–2 pass a dedicated ten-stage production gate covering sequential handoffs, manifest-driven entry cards, real movement/jump response from every authored spawn, live CharacterBody2D landings on all eighteen authored traversal sections, matching presentation/collision contracts across all 70 physical traversal decks, 41 movement-envelope-validated static route links, checkpoint/collectible budgets, regular and boss objective completion, exit lock/label behavior, boss HUD bounds, campaign persistence, and seven distinct production panoramas.
- [x] Legacy Acts 3–4 pass a dedicated ten-stage production gate covering real player movement/jumping, checkpoints, collectibles, encounter and boss objectives, campaign persistence, handoffs through the ending, ten distinct 1672×941 panoramas, 43 regional traversal decks, and 28 lunar/abyssal structural assemblies. Security Grid Shaft also validates vertical background overscan, and no later-act route falls back to Cyber City or Factory architecture.
- [x] Thirty real-renderer 960×540 captures cover start/signature/finish composition for stages `1-1` through `2-5`; every stage presents its Act/stage card, the elevated Sub-Level Intake conveyor/steam route is clear of inherited terrain, Robot Factory uses factory art throughout, shared traversal decks read as district-native load-bearing structures with safety cues, vertical camera zones retain full background coverage, foregrounds remain readable, and the two boss HUDs do not overlap the status or score panels.
- [x] Character Creator reaches a saved playable `WorldRoot` character.
- [x] All 202 rooms and twenty districts form one reachable graph.
- [x] The 162-room critical route validates for all six starting families.
- [x] Every district satisfies the 8–14 critical-room and 2–5 optional-room budgets; the 19 compact districts include authored teach/test/twist/recovery rooms and all districts expose two optional routes.
- [x] All 103 expansion rooms have stable layout provenance, unique static platform geometry, and one of twenty district spatial rhythms.
- [x] Every district has an authored art profile with a unique palette, eight-part skyline, landmark polygon, two exclusive licensed prop assignments, atmosphere, foreground framing, and platform trim; all 202 rooms instantiate the contract and twenty representative OpenGL captures have been visually reviewed.
- [x] All 27 new persistent currency caches instantiate, use globally unique state IDs, grant their authored value, and survive save/load.
- [x] Ability gates, persistent encounters/shortcuts, save rooms, all five warp destinations, story prerequisites, and boss/cutscene travel locks pass.
- [x] Four streamed regional bosses persist defeat/rewards and do not respawn after reload.
- [x] All four bosses reference data-authored first-view intro and defeat sequences with safe skip endpoints.
- [x] Four data-authored quests drive HUD/Journal objectives and reconcile legacy saves from persistent events.
- [x] All 21 main-quest steps target valid map rooms; the map renders the active objective plus overall and per-region completion.
- [x] Seven authored traversal probes pass against production player parameters and instantiated room collision geometry.
- [x] The custom-name/pronoun/portrait/live-visual ending and post-game continuation pass.
- [x] Save migration, checksums, backup recovery, dual-input settings/remaps, dialogue pause restoration, five mixer buses, missing-audio fallback, encounter reset, and cleanup fault paths pass.
- [x] Performance regression bounds pass: all 202 room loads, real fade transitions, UI opens, save writes, three-room memory, player surfaces, audio/enemy counts, 276 registry-managed plus 28 direct runtime paths, 64 projectiles, 32 VFX, and scene release.
- [x] Automated accessibility contract passes for keyboard/controller core actions, text/subtitle/bark controls, shake/vibration, flash/contrast, aim assist, and teleport hold/tap alternatives.
- [x] All 22 enemies satisfy the live schema-2 production contract and instantiate together in the source-only roster lab.
- [x] All fourteen weapon items appear in Equipment/Inventory with ownership filtering, family restrictions, stat comparison, description/lore, immediate equip feedback, six curated family icons, and a locked/unknown fallback; Inventory separates Weapons, Key Items, and Materials.
- [x] Four regional ambience profiles route through the Ambience bus, and the streamed world switches them with region transitions.
- [x] All 314 shipped runtime binaries have hash-to-license/source provenance, including seventeen generated panoramas and twelve generated traversal kits with stable `generated://` records.
- [x] This delivery commit tracks the previously unintegrated runtime-critical paths and the current generated-asset provenance records.
- [x] A pre-delivery local candidate exported a 55,410,492-byte PCK, passed the development-content and reviewed traversal-kit scans, and packaged to a validated Windows archive. It predates the final ten later-act panoramas and is retained only as prior packaging evidence.
- [ ] Run dependency inventory and the complete suite from a fresh clean clone of the integrated commit.
- [ ] Run remote GitHub Actions on the integrated release commit.
- [ ] Repeat export, package, scan, extraction, and headless launch from the integrated commit without `--allow-dirty`.
- [ ] Launch the package on an independent clean Windows machine.

## Manual input and weapon-family matrix

- [ ] Full critical-route keyboard/mouse playthrough with Sword.
- [ ] Full critical-route keyboard/mouse playthrough with Dagger.
- [ ] Full critical-route keyboard/mouse playthrough with Spear.
- [ ] Full critical-route keyboard/mouse playthrough with Heavy.
- [ ] Full critical-route keyboard/mouse playthrough with Bow.
- [ ] Full critical-route keyboard/mouse playthrough with Staff.
- [ ] Full critical-route Xbox-compatible controller playthrough with each family represented.
- [ ] Controller phase-aim, surface snap, recall, and invalid-destination feel/readability.
- [ ] Controller disconnect/reconnect with keyboard fallback.
- [ ] Persistent remapped keyboard and controller controls.

## Manual display, accessibility, audio, and performance matrix

- [x] Windowed 1280×720 local exported-build pass: creator, personalized prologue, keyboard movement/jump/dash, pause tabs, persistence/relaunch, and streamed room transition observed on 2026-08-05.
- [ ] Windowed/fullscreen 1920×1080 at stable 60 FPS on the agreed minimum PC.
- [ ] 2560×1440 and supported ultrawide behavior.
- [ ] Reduced flashing, high contrast, UI scale, screen-shake zero, subtitles, and vibration zero.
- [ ] Dense standard encounter and highest phase of each regional boss captured for frame-time review.
- [ ] Region music, boss transitions, voice profiles, combat cues, corruption warnings, and audio-device change listening pass.

## Manual progression and recovery matrix

- [ ] New Game, slot selection, overwrite confirmation, and all creator controls.
- [ ] All five voice previews and all twelve portraits.
- [ ] Continue after save room, reward, boss, fast travel, relaunch, and post-game completion.
- [ ] Death during a standard encounter and each regional boss; confirm fast restart and no arena softlock.
- [ ] Every optional weapon/cache route, backtracking ability gate, shortcut, and warp node.
- [ ] Map discovery and persistent state across a human start-to-ending playthrough.
- [ ] Ending skip and non-skip flows, credits/title routes, and `CONTINUE EXPLORING`.

Promotion requires every applicable manual item, a green remote CI run, clean-clone/package evidence for the integrated commit, no open severity-1 defect, and explicit approval of any remaining lower-severity issue.
