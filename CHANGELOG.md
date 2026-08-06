# Changelog

## Unreleased — connected-world candidate

- Rebuilt the campaign as one streamed 202-room metroidvania spanning twenty districts and four regions while retaining the original twenty-stage campaign as legacy mode.
- Expanded every compact district to eight critical rooms with authored teach/test/twist/recovery traversal beats, raised every district to two optional routes, added 27 persistent currency caches and lore terminals, and preserved each district's original 15–20 minute pacing total. All 103 expansion rooms now have stable, non-duplicated static geometry contracts built from twenty district-specific spatial rhythms.
- Replaced four region-wide dressing recipes and five hashed landmark shapes with a twenty-profile district art bible: each district now has a unique palette, eight-part skyline, landmark polygon, paired licensed prop set, atmosphere, foreground framing, and platform trim. A real OpenGL capture verifies one representative rendered room per district.
- Added three save slots, a controller-navigable Character Creator, layered player rendering, twelve portraits, five voice profiles, custom name/pronouns, and persistent barber/tailor customization. Occupied save slots show both the dialogue portrait and an exact animated reconstruction of the saved character layers and equipped weapon family.
- Completed a real windowed 1280×720 New Game interaction pass and fixed the rendered issues it exposed: the Character Creator now keeps its action bar visible with a scrollable option list and uncropped live preview, streamed rooms no longer duplicate their names beneath the HUD, tutorial banners use a collision-free HUD band, and completed/skipped cutscenes atomically autosave their final story/quest state.
- Added six distinct starting weapon families, safe thrown-marker phase teleport, seven progression abilities, optional weapon routes, persistent encounters/shortcuts, save rooms, map discovery, and discovered-only warp travel.
- Added authored Cyber City, Mega Robot Factory, Neon Moon Protocol, and Abyssal Night routes with region mechanics, four persistent multi-phase bosses, data-authored quests and narrative, a personalized ending, and post-game exploration.
- Completed the map contract with main-objective destination diamonds backed by all 21 sequential quest steps, distinct service colors, and live overall plus per-region completion percentages.
- Added device-aware live prompts, independent phase-aim deadzone/response controls, regional ambience, persistent multi-terminal gates, and reversible conveyor controls.
- Completed schema-2 production contracts for all 22 enemies, including authored region use, navigation/leash rules, attack windows, stagger/resistances, drops, collision, audio/VFX, elite variants, and a shared roster lab.
- Expanded Equipment and Inventory with all 14 collectable weapon variants, exact live/portrait previews, sort/filter controls, stat comparison, move summaries, descriptions/lore, separated weapon/key-item/material taxonomy, curated family icons, a locked/unknown fallback, slot status, and immediate equip feedback.
- Remastered the first two legacy acts end to end: seven stage-specific 16:9 hero panoramas now distinguish Communication Spire, Skybridge Junction, Executive Helipad, Conveyor Assembly, Smelting Core, Robotic Maintenance, and Assembly Engine; Robot Factory no longer reuses the Neon Alley backdrop; the Sub-Level Intake lighting is readable and its conveyor/steam route clears inherited terrain; vertical-stage overscan prevents the clear color from entering camera views; manifest-driven Act and stage entry cards give every route a clear identity without crowding gameplay; regular exits communicate encounter objectives; boss HUDs no longer overlap the primary status panels; every authored traversal deck now uses its district tile surface plus an explicit load-bearing catwalk, shaft, bridge, conveyor, lift, gantry, furnace, crane, or crusher assembly without changing its collision contract; and encounter, security, and boss locks now use framed, district-aware energy gates rather than prototype magenta walls.
- Added a deterministic first-two-acts production gate covering all ten stage loads, real movement/jumping from every spawn, body-contact landings across all eighteen authored traversal sections, checkpoint/collectible budgets, stage handoffs through Act 3, regular and boss completion, exit locks/labels, campaign persistence, seven distinct production panoramas, and bounded boss HUD layout. A real-renderer harness captures start/signature/finish frames for all ten stages.
- Completed the final two campaign acts end to end: Neon Moon Protocol and Abyssal Night now each have five stage-specific 16:9 hero panoramas, per-layer atmospheric color treatment, regional support structures, and native lunar/abyssal traversal assemblies instead of Cyber City/Factory fallbacks. The new deterministic production gate exercises all ten stages from real player movement through collectibles, checkpoints, combat locks, boss completion, act handoffs, and the ending; it also verifies ten 1672×941 production panoramas, 43 traversal decks, and 28 regional assemblies.
- Expanded the strict isolated headless suite to 36 commands covering the 202-room graph, 162-room critical route for every starting family, creator-to-world flow, enemy contracts, quest migration, optional-cache persistence, regional persistence, boss rewards, dedicated Act 1–2 and Act 3–4 production gates, seven real-geometry traversal probes, ending flow, and performance bounds.
- Curated 99 additional creator, voice, weapon, inventory-icon, and district-prop assets, four native Neon Moon background layers, and seventeen AI-assisted act panoramas; the 314-binary runtime set has hash-to-license/source provenance.

## 1.0.0-rc.2 — 2026-08-04

- Replaced generic runtime stage population with explicit authored traversal, encounter, collectible, mechanic, and boss-arena blueprints for all twenty stages.
- Added production implementations for camera/visibility zones, seven distinct hazard families, multi-mode security devices, persistent terminals/gates, multi-wave encounters, and multi-point moving platforms.
- Added per-act enemy balance profiles, live detection-radius tuning, knockback resistance, movement/landing audio, low-health feedback, and act-specific environmental presentation.
- Replaced critical-node group/fuzzy lookup with exported stage node paths and direct runtime contracts.
- Removed obsolete prototype builders, preview catalog, duplicate bullet/exit scenes, and prototype residue from production stage scenes.
- Expanded the headless suite to eighteen commands and made zero-exit Godot engine errors fail validation.

## 1.0.0-rc.1 — 2026-08-04

- Completed the four-act, twenty-stage campaign and deterministic stage progression.
- Added explicit player movement/combat states, upgrades, controller support, and persistent remapping.
- Added ten enemy archetypes, resettable encounters, shared stage mechanics, and four distinct multi-phase bosses.
- Added title, continue, stage-select, pause, settings, accessibility, ending/results, and credits flows.
- Added versioned atomic saves, backup recovery, corruption handling, migration, and independent settings persistence.
- Curated 182 licensed runtime assets under Git LFS with reproducible inventory and attribution manifests.
- Added a pinned Godot 4.7.1 headless suite, GitHub Actions validation, performance regression coverage, and Windows release export/package tooling.
