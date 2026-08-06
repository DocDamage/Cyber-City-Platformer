# Cyber City Metroidvania — Exhaustive Production Plan

**Document status:** Historical approved direction; implemented delivery is recorded in `docs/implementation/DELIVERY_SUMMARY.md`
**Prepared from:** Direct inspection of the Godot project and supplied asset folders
**Audit date:** 2026-08-05
**Target engine:** Godot 4.7
**Primary platform:** Windows PC
**Input targets:** Keyboard and mouse, Xbox-compatible controllers, PlayStation-compatible controllers, and other modern controllers recognized by Godot
**Supersedes for future scope:** The linear-campaign assumptions in `CYBER_CITY_PLATFORMER_FULL_COMPLETION_PLAN.md`

> This is the retained production-design record. Its future-tense milestones describe the original approved direction; current implementation and remaining release gates are recorded in `docs/implementation/DELIVERY_SUMMARY.md` and `docs/RELEASE_CHECKLIST.md`.

---

## 1. Purpose

This document defines the complete production plan for converting the existing linear Cyber City Platformer campaign into a connected, story-driven metroidvania inspired by the exploration structure of *Castlevania: Symphony of the Night* and the action-platforming discipline of *Mega Man X* and *Strider*.

The plan is based on the actual codebase and the inspected contents of the supplied external asset folders. Existing documentation is not treated as proof that a feature works. Completion gates require code inspection, automated verification where appropriate, and human playtesting.

The intended result is one persistent world containing four major regions and twenty named districts, a single player-created protagonist, distinct weapon families, a universal thrown-marker teleport ability, SOTN-style fast travel, equipment and exploration progression, text-driven story scenes, selectable voice barks, and substantially more authored vertical and horizontal level design.

---

## 2. Locked Product Decisions

The following decisions are approved and should not be reopened without an explicit scope change.

### 2.1 Player character

- The game has one playable protagonist.
- The player creates and customizes that protagonist during New Game.
- There is no hero roster and no character switching.
- Character creation includes:
  - Player name.
  - Pronoun set.
  - Selectable voice profile.
  - Skin/body selection.
  - Face selection.
  - Hairstyle and hair color.
  - Top and bottom clothing.
  - Clothing colors.
  - Starting weapon family.
  - One of twelve mostly fixed portrait designs.
- Cosmetic editing is available later through an in-world barber and tailor.
- The exact in-game character must reflect the current appearance and equipped weapon.

### 2.2 Portraits

- Dialogue portraits are enlarged pixel-art busts rather than illustrated portraits.
- There are twelve mostly fixed portrait designs.
- Portraits support limited editing:
  - Skin-tone variants.
  - Hair-color variants.
  - A curated subset of hairstyle silhouettes.
  - Primary and secondary clothing colors.
  - Optional weapon-family overlay.
  - Background/frame accents.
- A separate live character preview in the creator, equipment menu, save menu, barber, and tailor shows the exact current character layers and equipment.
- The fixed dialogue portrait is not required to reproduce every clothing silhouette exactly. It must preserve the chosen identity, palette, and broad equipment family.

### 2.3 Weapons

- Weapon families have distinct attacks, timings, reach, hitboxes, damage profiles, and tactical roles.
- The player chooses one starting weapon family during creation.
- Other base weapon families are obtainable early in the world.
- The preferred source is:
  - `F:\Cyber City Platformer\Stage Props\Animated Weapons\Ultimate Weapon Pack – 2D Pixel Art`
- Static guns from the older Guns folder are deprioritized.
- Firearms are not required for the first complete release.
- Firearms may be added later only if convincing character poses and weapon animation can be produced without lowering visual quality.

### 2.4 Teleportation

- The player begins the game with a universal thrown-marker teleport ability.
- The ability is independent of the currently equipped combat weapon.
- The marker should be presented as a dedicated phase dagger, beacon, or equivalent story-appropriate device.
- Throwing the marker and teleporting to it is used for traversal and combat.
- SOTN-style fast travel is a separate system using discovered warp rooms/stations.
- Fast travel does not use the thrown marker and cannot be triggered anywhere in the field.

### 2.5 World structure

- The game is one persistent world from the player's perspective.
- It is not implemented as one enormous Godot scene.
- It is implemented as interconnected room scenes grouped into districts and regions.
- Existing regions and the twenty current location names are retained because they form a useful thematic progression.
- Region-scale transitions such as orbital transit may use a controlled loading transition while remaining part of the same save/world state.

### 2.6 Stage length and game length

- Each named district targets 15–20 minutes for a first critical-path traversal.
- Optional rooms, secrets, story scenes, backtracking, and bosses can extend that time.
- Twenty districts at this size imply approximately 5–7 hours of direct critical-path traversal.
- The expected first playthrough target is approximately 8–12 hours after exploration, backtracking, story, deaths, upgrades, and boss attempts are included.

### 2.7 Story and voice

- Story dialogue is text-based.
- The protagonist's custom name and pronouns are interpolated into dialogue.
- The supplied Super Dialogue Audio Pack provides selectable voice barks and reactions.
- Full spoken story dialogue is not required.
- Voice clips are used for combat, damage, death, exertion, acknowledgement, greetings, farewells, refusal, completion reactions, and carefully selected contextual events.

---

## 3. Actual Current-Code Baseline

This section records the implementation starting point found in the codebase.

### 3.1 Engine and shell

- `project.godot` targets Godot 4.7 with Forward Plus rendering.
- The internal viewport is 960×540.
- Pixel snapping and nearest-neighbor texture filtering are enabled.
- The current main scene is `scenes/ui/TitleScreen.tscn`.
- Existing autoloads include:
  - `GameManager`.
  - `SettingsManager`.
  - `CombatFeedback`.
  - `AudioManager`.
  - `VFXSpawner`.
  - `AssetRegistry`.
  - `SaveManager`.
  - `SceneTransition`.

### 3.2 Current player

- `scripts/Player.gd` is already a capable action-platformer controller.
- Existing movement includes running, jumping, coyote time, jump buffering, wall sliding, wall jumping, and dash/slide behavior.
- Existing combat includes melee, projectile shooting, buffering, energy, damage, invulnerability, and combat feedback.
- The player currently renders through one `AnimatedSprite2D`.
- `scripts/systems/player/PlayerAnimationFactory.gd` assumes a monolithic 96×96 grid and exposes only a small set of animations.
- The current visual factory cannot represent layered character-creator components or synchronized visible equipment.
- The current `Player.gd` enum does not include teleport aim, teleport throw, teleport recovery, weapon-specific attacks, casting, interaction lock, cutscene control, or equipment-change states.

### 3.3 Current progression and save model

- `scripts/SaveManager.gd` uses save version 1.
- It writes one primary save and one backup.
- A save resumes from a stage scene path.
- `scripts/state/CampaignProgress.gd` tracks completed stages, unlocked acts, scores, times, defeated bosses, and campaign completion.
- It does not track:
  - Character appearance.
  - Name or pronouns.
  - Voice selection.
  - Inventory.
  - Equipped weapon.
  - Abilities.
  - Room discovery.
  - Map completion.
  - Persistent room-object state.
  - Fast-travel nodes.
  - Story flags.
  - Quest state.
  - Barber/tailor unlocks.
  - Cutscene history.

### 3.4 Current campaign

- `Stages/campaign_manifest.json` defines four acts and twenty linear stages.
- Each stage points to the next stage.
- Current par times are approximately 3–5 minutes, much shorter than the new 15–20 minute target.
- The locations are:
  - Cyber City:
    - Rooftop Alley.
    - Billboard Highway.
    - Communication Spire.
    - Skybridge Junction.
    - Executive Helipad.
  - Mega Robot Factory:
    - Sub-Level Intake.
    - Conveyor Assembly.
    - Smelting Core.
    - Robotic Maintenance.
    - Assembly Engine.
  - Neon Moon Protocol:
    - Lunar Surface Arrival.
    - Research Cleanrooms.
    - Security Grid Shaft.
    - Bio-Tech Labs.
    - Orbital Command.
  - Abyssal Night:
    - Corrupted Outpost.
    - The Dark Chasm.
    - Bio-Mechanical Nest.
    - Abyssal Sanctuary.
    - Heart of the Void.

### 3.5 Current level-design limitation

- `scripts/campaign/AuthoredTraversal.gd` builds traversal from a small generic layout vocabulary.
- The available patterns include wall-jump shafts, basic vertical routes, high routes, dash gaps, moving-platform routes, conveyor routes, and hazard steps.
- These patterns are useful as prototypes but are not enough to carry twenty 15–20 minute districts.
- Final districts require hand-authored room geometry, unique spatial rhythms, landmarks, secrets, shortcuts, combat arenas, environmental storytelling, and art dressing.

### 3.6 Current automated-test limitation

- `tests/campaign/CampaignTraversalTest.gd` verifies scene order and completion plumbing.
- It completes non-boss objectives through a test bypass.
- It starts bosses, skips their intros, and deals 9,999 damage.
- It does not physically move a player through rooms.
- It cannot prove:
  - Jump or teleport reachability.
  - Controller feel.
  - Combat difficulty.
  - Encounter pacing.
  - Softlock prevention.
  - Checkpoint fairness.
  - Backtracking quality.
  - Map readability.
  - The absence of frustrating camera behavior.
- Human start-to-finish QA is therefore a release requirement, not an optional polish step.

### 3.7 Current menus

- Existing scene files cover:
  - Title screen.
  - Stage select.
  - Pause menu.
  - Ending screen.
  - Credits screen.
- The new scope additionally needs:
  - Character Creator.
  - Save-slot selection.
  - World map.
  - Inventory.
  - Equipment.
  - Abilities/progression.
  - Journal/objectives.
  - Dialogue presentation.
  - Cutscene overlay.
  - Warp-room selection.
  - Barber.
  - Tailor.
  - Optional item/enemy codex.
- Stage Select should be removed from the normal player flow and retained only as an optional developer/debug tool.

---

## 4. Inspected External Asset Baseline

External folders are source libraries. Assets selected for the game must be curated, renamed, normalized, copied into the repository's runtime asset structure, and recorded in the license manifest. Runtime scenes must not depend directly on absolute `F:\` paths.

### 4.1 Character Creator

Source:

`F:\Cyber City Platformer\Characters\Character Creator`

Inspected characteristics:

- 764 RGBA PNG layer sheets.
- Every gameplay layer is 800×680.
- The set uses the same 102-frame layout across compatible layers.
- Categories include skin, face, hair, clothing, and weapons.
- Hair and clothing contain color variants.
- Top/bottom layer separation supports correct front/back draw ordering.
- Native visible-weapon layers include five broad weapon types.
- A license file is present.

Implication:

- The asset set is suitable for a runtime layered character renderer.
- It is not compatible with the current 96×96 `PlayerAnimationFactory` without a new atlas map.
- All active layers must play the same animation and frame index.

### 4.2 Animated Weapons

Source:

`F:\Cyber City Platformer\Stage Props\Animated Weapons\Ultimate Weapon Pack – 2D Pixel Art`

Inspected characteristics:

- 24 Aseprite files, including 22 main weapon sources and preview/edit sources.
- 64 PNG files.
- 7 animated GIF previews.
- 22 primary sheets at 960×1920.
- 35 alternate/palette sheets at 960×1920.
- Visual coverage includes blades, bows, staves, heavy-tool/heavy-weapon attacks, projectiles, impacts, attack trails, and elemental/color variants.
- A license file is present.

Implication:

- This pack should replace the static Guns folder as the primary source for weapon motion and effects.
- Its frame grid is not automatically aligned with the Character Creator layout.
- A one-time mapping and offset-authoring pass is required for each supported family.
- A weapon is approved only after its idle, ground attack, air attack, turn, hurt, teleport, and portrait presentation are verified.

### 4.3 Stage Props

Sources include:

- `F:\Cyber City Platformer\Stage Props\Cargo, Tech & Laboratory Loot`
- `F:\Cyber City Platformer\Stage Props\Icons`
- `F:\Cyber City Platformer\Stage Props\Space Props`
- `F:\Cyber City Platformer\Stage Props\Animated Weapons`

Inspected characteristics:

- 596 cargo, technology, and laboratory props.
- 1,785 icons.
- 693 space props.
- 592 older static gun images, now deprioritized.
- Licenses are present at the Stage Props root and inside the relevant subfolders.

Implication:

- Do not import everything.
- Curate coherent district-specific prop sets.
- Normalize pixel density, palette, outline treatment, pivot, and collision behavior.
- Decorative images are not automatically gameplay traps. Interactive versions require scenes, collisions, telegraphs, audio, state, and tests.

### 4.4 Enemies

Source:

`F:\Cyber City Platformer\Enemies`

Inspected characteristics:

- The library contains existing campaign enemies plus numerous new packs.
- Formats include sprite sheets, per-frame PNGs, GIF previews, Aseprite files, and ZIP archives.
- Particularly promising additions include:
  - Dark Ninja.
  - Fantasy Forest Enemies.
  - Feudal Japan Enemies.
  - Fantasy Monsters Pack 2.
  - DuskBorne DemonKin.
  - DuskBorne ArchDemon.
  - DuskBorne Druid.
  - DuskBorne Elf.
  - Fire Mage.
  - Giant Boss Pack.
  - Goatman.
  - Infernal Axe Warrior.
  - Mutant Brute.
  - Undead Executioner.
  - Urban Fighters.
  - Water Monster.
- Licenses are present at the root and/or individual pack level.

Implication:

- Create a controlled enemy-import pipeline rather than connecting scenes to arbitrary source files.
- Normalize each enemy to a behavior archetype, animation contract, collision scale, attack contract, and region role.
- New art alone does not constitute a finished enemy.

### 4.5 Teleport prototype

Source:

`F:\Cyber City Platformer\Mechanics\Prototype_Minato`

Inspected characteristics:

- Godot 4.4 prototype.
- Throws a knife toward the cursor.
- Enables teleport after the knife overlaps terrain.
- Moves the player to the knife position.
- Supports cancel/recall through mouse/key input.
- Uses shared global references and direct position assignment.
- Does not validate player clearance or controller aiming.
- A license file is present.

Implication:

- Reuse the interaction concept and selected effects.
- Do not copy the implementation unchanged.
- Integrate teleport into the current player controller, physics layers, camera, input rebinding, combat state, save state, and safety tests.

### 4.6 Metroidvania Forge

Source:

`F:\Cyber City Platformer\Metroidvania Forge`

Inspected characteristics:

- Reference/course asset collection rather than reusable gameplay code.
- Useful assets include doors, switches, save points, map nodes, ability pickups, breakables, input prompts, UI sounds, music, tiles, and weapon smears.
- The three PDFs are boss-encounter design worksheets.
- A license file is present.

Implication:

- Selectively reuse compatible art/audio.
- Reimplement systems within this project's architecture.
- Use the boss worksheet fields as part of the boss design review: primary test, signature mechanic, purpose, telegraph, punish window, arena, spectacle, and memorable moment.

### 4.7 Voice pack

Source:

`F:\Cyber City Platformer\SFX\Super Dialogue Audio Pack v1\Step 2 - Audio Files`

Inspected characteristics:

- 545 WAV clips plus a license file.
- Five voice performers/profiles:
  - Karen Cenon.
  - Meghan Christian.
  - Alex Brodie.
  - Ian Lampert.
  - Sean Lenhart.
- Ten categories:
  - Completion: 50 clips.
  - Confirmation: 50 clips.
  - Greeting: 50 clips.
  - Farewell: 50 clips.
  - Refusal: 50 clips.
  - Miscellaneous: 97 clips.
  - Damage: 50 clips.
  - Death: 50 clips.
  - Grunting: 50 clips.
  - Shouting: 48 clips.
- A license file is present.
- The WAV container reports format code 3 for inspected files, so the import pipeline must validate or normalize the encoding before runtime integration.

Implication:

- Present five voice choices independent of body, appearance, name, or pronouns.
- Include a preview button in Character Creator and barber/tailor services if voice changes are allowed there.
- Use generic profile labels in the player-facing UI if desired; retain performer/source metadata in the license and asset manifest.
- Convert selected runtime clips to a consistent Godot-tested format when necessary.

---

## 5. Target Player Experience

### 5.1 Core loop

1. Explore connected rooms.
2. Read environmental clues and encounter story scenes.
3. Fight enemies using the selected weapon family and teleport ability.
4. Find shortcuts, save rooms, warp rooms, equipment, resources, and permanent upgrades.
5. Unlock new route permissions or traversal options.
6. Return to previously seen barriers and optional branches.
7. Defeat district guardians and regional bosses.
8. Open connections into the next major region.

### 5.2 Design pillars

- **Movement is expressive:** Running, jumping, wall movement, dash, and teleport should combine smoothly.
- **Exploration is legible:** Landmarks, room shapes, map colors, shortcuts, and warp rooms make the world understandable.
- **Weapons change playstyle:** Equipping a new family changes timing and decisions, not only damage numbers.
- **Rooms are authored:** Layouts serve a specific challenge or story purpose rather than repeating generic templates.
- **Danger is readable:** Traps and enemy attacks telegraph their timing and provide recovery or escape options.
- **Customization persists:** The player sees their chosen appearance, voice, name, pronouns, portrait, and weapon throughout the game.
- **Story respects pacing:** Cutscenes are purposeful, skippable, replayable, and do not repeatedly interrupt movement.
- **Backtracking pays off:** Returning with knowledge or an upgrade produces shortcuts, meaningful rewards, or story discoveries.

### 5.3 Pacing target per district

Each 15–20 minute first-clear district should generally include:

- 8–14 critical-path rooms.
- 2–5 optional rooms.
- 2–4 deliberate combat encounters.
- 1 traversal-teaching room.
- 1 traversal-test room.
- 1 traversal-twist or combined-pressure room.
- 1 major landmark.
- 1 shortcut unlocked from the far side.
- 1–3 secrets.
- 1 meaningful reward.
- 1 story or character beat.
- A save opportunity approximately every 8–12 minutes, adjusted for difficulty.
- A warp room based on world-network needs rather than one per district.

These are budgets, not rigid templates. Boss districts can replace some traversal rooms with approach, arena, and recovery spaces.

---

## 6. Target World Architecture

### 6.1 Player-facing world graph

```text
Cyber City
├── Rooftop Alley
├── Billboard Highway
├── Communication Spire ── Orbital Transit ── Neon Moon Protocol
├── Skybridge Junction                              ├── Lunar Surface Arrival
└── Executive Helipad                              ├── Research Cleanrooms
        │                                           ├── Security Grid Shaft
        └── descent/access route                    ├── Bio-Tech Labs
                │                                   └── Orbital Command
                ▼                                            │
        Mega Robot Factory                                  corruption breach
        ├── Sub-Level Intake                                  │
        ├── Conveyor Assembly                                 ▼
        ├── Smelting Core                              Abyssal Night
        ├── Robotic Maintenance                        ├── Corrupted Outpost
        └── Assembly Engine                            ├── The Dark Chasm
                                                        ├── Bio-Mechanical Nest
                                                        ├── Abyssal Sanctuary
                                                        └── Heart of the Void
```

The final graph must contain loops and cross-links. The diagram shows thematic adjacency, not a mandated single corridor.

### 6.2 Technical world model

Use a hierarchy:

- **World** — the complete save and map domain.
- **Region** — one major biome/theme.
- **District** — one named 15–20 minute area.
- **Room** — one streamed/instanced gameplay scene.
- **Connection** — door, shaft, elevator, exterior edge, transit sequence, warp link, or one-way drop.

Recommended runtime structure:

```text
scenes/world/
├── WorldRoot.tscn
├── rooms/
│   ├── cyber_city/
│   ├── robot_factory/
│   ├── neon_moon/
│   └── abyssal_night/
├── transitions/
├── services/
└── debug/

scripts/world/
├── WorldManager.gd
├── RoomLoader.gd
├── RoomDefinition.gd
├── RegionDefinition.gd
├── RoomConnection.gd
├── WorldProgress.gd
├── MapDiscovery.gd
├── PersistentObject.gd
└── FastTravelManager.gd

data/world/
├── regions/
├── rooms/
├── districts/
└── fast_travel/
```

### 6.3 Room loading

- Load the destination room before handing control back to the player.
- Retain the current room until the destination is ready.
- Use a short controlled transition at hard boundaries.
- Preserve player velocity only where the connection is designed for continuous movement.
- Spawn by stable connection ID, not raw coordinates saved in the file.
- Never save the player inside a transient door animation, teleport flight, boss intro, or invalid collision state.
- Keep adjacent rooms prefetched when profiling shows a benefit and memory budgets permit it.

### 6.4 Persistent room state

Every persistent object requires a stable ID unique within the world.

Persist at minimum:

- Opened chests.
- Collected permanent upgrades.
- Collected unique weapons.
- Activated switches.
- Opened permanent shortcuts.
- Broken permanent barriers.
- Boss defeats.
- Mini-boss defeats where intended.
- Story event completion.
- Discovered map rooms.
- Discovered save rooms.
- Activated warp rooms.
- NPC state changes.
- Quest state.

Do not persist normal breakable clutter or normal enemy deaths unless a room's design specifically requires it.

### 6.5 Fast travel

- Warp rooms are discovered by entering and activating them.
- Fast travel is only initiated from an active warp room.
- The destination list includes only activated nodes.
- Locked story regions cannot be reached early through the warp network.
- Boss-lock and cutscene-lock rules must be explicit and tested.
- Warp travel saves before departure and after a successful arrival.
- The map displays region, district, warp-node name, and completion information.

---

## 7. Character-Creation System

### 7.1 New Game flow

1. Select save slot.
2. Enter name.
3. Select pronouns.
4. Select voice profile and preview it.
5. Select body/skin.
6. Select face.
7. Select hairstyle and color.
8. Select top, bottom, and clothing colors.
9. Select starting weapon family and preview its role.
10. Select one of twelve portrait designs.
11. Review the character in idle, run, jump, attack, hurt, and teleport previews.
12. Confirm and begin the prologue.

### 7.2 Creator requirements

- Every option has a stable data ID.
- Save IDs, not file paths.
- Disable or hide incompatible layer combinations.
- Prevent z-order errors in both facing directions.
- Display current controls using the active input device.
- Support keyboard-only, mouse, and controller navigation.
- Provide undo/back navigation without losing earlier selections.
- Warn before abandoning an unsaved character.
- Provide randomize-all and randomize-category options.
- Provide a default valid character so New Game cannot enter an invalid state.

### 7.3 Runtime data model

Recommended resources/data classes:

```text
CharacterProfile
├── character_name
├── pronoun_set_id
├── voice_profile_id
├── portrait_id
├── appearance
├── starting_weapon_family
└── creation_complete

CharacterAppearance
├── body_id
├── skin_tone_id
├── face_id
├── hair_style_id
├── hair_color_id
├── top_id
├── top_color_id
├── bottom_id
├── bottom_color_id
└── cosmetic_flags
```

### 7.4 Pronouns and text variables

Provide a token resolver for:

- `{player_name}`.
- `{subject}` — he/she/they or custom equivalent.
- `{object}` — him/her/them.
- `{possessive_adjective}` — his/her/their.
- `{possessive_pronoun}` — his/hers/theirs.
- `{reflexive}` — himself/herself/themself.
- Capitalized variants.
- Singular/plural verb agreement when required.

Dialogue content must not manually concatenate pronouns in code.

### 7.5 Barber and tailor

Barber services:

- Hairstyle.
- Hair color.
- Supported face/cosmetic details.
- Optional voice-profile change if approved by final narrative presentation.

Tailor services:

- Top and bottom clothing.
- Clothing colors.
- Portrait selection and portrait palette options.
- Live preview before purchase/confirmation.

Service rules:

- The player can cancel without changing their saved appearance.
- A preview copy is separate from the committed profile.
- Confirming updates gameplay visuals, live preview, save summary, and future dialogue portraits immediately.
- Whether services cost currency is a balance decision made after the vertical slice. Early prototypes should make changes free.

---

## 8. Layered Character Renderer

### 8.1 Replacement requirement

Replace the single `AnimatedSprite2D` dependency with a `PlayerVisual` scene containing synchronized layers.

Recommended node shape:

```text
PlayerVisual
├── BackLayers
│   ├── HairBack
│   ├── ClothingBack
│   └── WeaponBack
├── Body
├── Face
├── FrontLayers
│   ├── ClothingFront
│   ├── HairFront
│   └── WeaponFront
├── WeaponEffects
├── TeleportMarkerVisual
└── StatusEffects
```

The exact order should be validated against the Character Creator's top/bottom files.

### 8.2 Animation synchronization

- Build one authoritative animation/frame controller.
- Child layers do not advance independently.
- Every visible layer receives:
  - Animation name.
  - Frame index.
  - Frame progress.
  - Playback direction.
  - Facing/flip state.
- Missing optional layers render transparent frames rather than breaking synchronization.
- Animation events are authored once and drive hitboxes, sounds, footsteps, trails, projectiles, and invulnerability.

### 8.3 Creator animation catalog

Create a verified mapping for all 102 source frames, including:

- Two idle sets.
- Two run sets.
- Jump.
- Fall loop.
- Three ground attacks.
- Two air attacks.
- Two casting sequences/loops.
- Hurt.
- Dying.
- Dash.
- Block.
- Roll.

The catalog must be verified visually against every active layer type. Do not hardcode unexplained coordinates throughout gameplay scripts.

### 8.4 Weapon synchronization

- Character Creator native weapon overlays should be used where they align exactly.
- Animated Weapon Pack sequences should be mounted as independent effect/weapon animations with authored offsets.
- Each weapon family requires an attachment profile for:
  - Idle.
  - Run.
  - Jump/fall.
  - Ground attacks.
  - Air attacks.
  - Block or charge.
  - Hurt/death.
  - Teleport aim/throw.
  - Portrait display.
- Validate both facing directions and all supported body/clothing combinations.

### 8.5 Performance requirements

- Avoid rebuilding `SpriteFrames` every frame.
- Cache layer frame libraries.
- Load only the selected appearance and nearby preview options.
- Profile draw calls with the maximum visible layers and status effects.
- Use nearest-neighbor filtering and pixel-aligned transforms.
- Prevent fractional scaling on gameplay sprites.

---

## 9. Portrait System

### 9.1 Twelve fixed designs

Create twelve portrait definitions. Each definition contains:

- Base pose/silhouette.
- Crop and anchor.
- Base face design.
- Supported hairstyle overlays.
- Skin-tone mask.
- Hair-color mask.
- Clothing-color masks.
- Optional weapon-family overlay anchor.
- Background and border choices.
- Dialogue speaking pulse settings.

### 9.2 Dynamic relationship to customization

- Skin, hair color, and clothing palette update automatically.
- Only portrait-supported hairstyle silhouettes are shown.
- Exact clothing cut is not guaranteed in the portrait.
- Weapon representation may show the family rather than the exact individual weapon model.
- The equipment screen shows an exact live gameplay render next to the fixed portrait.

### 9.3 Portrait uses

- Character Creator.
- Dialogue boxes.
- Save-slot summaries.
- Equipment/profile screen.
- Barber and tailor previews.
- Ending and credits summary if appropriate.

### 9.4 Portrait acceptance criteria

- All twelve are visually distinct at gameplay resolution.
- All supported skin and palette variants remain readable.
- Text never overlaps a portrait at supported aspect ratios.
- Portrait changes persist through save/load.
- Dialogue uses the saved portrait immediately after a tailor change.
- Missing overlays fall back gracefully.

---

## 10. Voice Profile System

### 10.1 Player-facing behavior

- Present five selectable voice profiles with preview buttons.
- Keep voice selection independent of pronouns and visual appearance.
- Allow preview of at least:
  - Greeting.
  - Attack/shout.
  - Damage.
  - Confirmation.
- Provide a separate voice-volume slider.
- Provide an option to disable protagonist barks without muting other sound effects.

### 10.2 Event mapping

Map gameplay events to categories:

| Event | Preferred category | Notes |
|---|---|---|
| Light attack | Grunting | Low probability; avoid every swing |
| Heavy/charged attack | Shouting | Strong cooldown |
| Teleport throw | Grunting or miscellaneous | Short clip only |
| Teleport arrival attack | Shouting | Only for offensive upgrades |
| Minor damage | Damage | Randomized, interrupt-safe |
| Critical health | Damage or miscellaneous | Long cooldown |
| Death | Death | One clip per death |
| Quest/room completion | Completion | Only for significant events |
| NPC interaction start | Greeting | Context-dependent |
| NPC interaction end | Farewell | Context-dependent |
| Confirming a prompt | Confirmation | Do not compete with UI audio |
| Invalid/refused action | Refusal | Rare; avoid annoyance |

### 10.3 Playback rules

- Use weighted random selection.
- Do not repeat the last two clips in a category when enough alternatives exist.
- Apply category cooldowns.
- Apply global protagonist-voice cooldowns.
- Damage/death can interrupt low-priority barks.
- Story text can suppress contextual barks.
- Do not play multiple protagonist clips simultaneously.
- Optional subtitles are required for intelligible spoken phrases.

### 10.4 Audio import

- Validate a representative WAV from every voice and category in Godot.
- If import is unreliable or inconsistent, batch-convert selected clips to a supported 16-bit PCM WAV or OGG Vorbis runtime format.
- Keep original sources outside the runtime folder.
- Normalize loudness conservatively without destroying attack transients.
- Trim unwanted leading/trailing silence where necessary.
- Record source actor/category/clip ID in a generated manifest.

---

## 11. Weapon and Combat System

### 11.1 Data model

Recommended `WeaponDefinition` fields:

```text
id
display_name
family_id
description
rarity
base_damage
stagger_damage
attack_speed_modifier
reach_profile
energy_costs
combo_definition
air_combo_definition
projectile_definition
element_tags
status_effect_tags
break_tags
visual_profile
audio_profile
icon
sell_value
unique_flags
```

Recommended `WeaponFamilyDefinition` fields:

- Input interpretation.
- Ground combo state graph.
- Air combo state graph.
- Charge/block behavior.
- Movement modifiers.
- Hit-stop and camera-shake profile.
- Default hitbox profiles.
- Animation-event map.
- AI/tutorial hint text.

### 11.2 Initial families

#### Sword

- Balanced speed, reach, damage, and recovery.
- Three-hit ground combo.
- Reliable air slash.
- Modest stagger.
- Recommended default for onboarding and internal testing.

#### Dagger

- Fast attacks and short recovery.
- Short reach.
- Strong aerial chaining or teleport synergy.
- Lower per-hit stagger.
- Rewards close positioning.

#### Spear

- Long forward reach.
- Narrow hit area.
- Thrust-focused attacks.
- Good anti-air or downward air attack.
- Poor coverage behind the player.

#### Axe/heavy weapon

- Slow startup and recovery.
- High damage and stagger.
- Breaks heavy objects and armored defenses.
- Strong downward air strike.
- Clear commitment and punish windows.

#### Bow

- Ranged aim and projectile travel.
- Limited mobility while charging unless upgraded.
- Elemental arrow variants.
- Requires a reliable controller aiming solution.
- Ammo should use energy or cooldown, not scarce consumable arrows, unless later balance tests justify otherwise.

#### Staff/wand

- Uses casting animations.
- Projectiles, charged shots, and area control.
- Higher energy dependence.
- Can interact with elemental/environmental objects.
- Should not duplicate the bow's tactical identity.

### 11.3 Starting weapon choice

- Show each family in a short interactive preview.
- Explain speed, range, difficulty, and resource use.
- Starting choice grants the base weapon, its tutorial, and its early upgrade path.
- Other base families appear in optional early Cyber City routes.
- No starting choice permanently locks content.
- Bosses must remain beatable by all families.

### 11.4 Equipment slots

Minimum viable slots:

- Main weapon.
- Armor/body module.
- Two accessory/module slots.

Possible later slots:

- Secondary weapon quick swap.
- Relic/ability modifier.
- Cosmetic weapon skin.

Do not add secondary weapon swapping until one-family combat is stable and the control scheme has room.

### 11.5 Combat acceptance criteria

- Each family is recognizably different within thirty seconds of play.
- Every family supports ground and air combat.
- Every family can fight flying, armored, and mobile enemies through its own tools.
- Visible weapon art matches hit timing.
- Hitboxes do not lead or lag the visual unfairly.
- Controller and keyboard inputs produce equivalent actions.
- No family invalidates teleport traversal or creates required-route softlocks.

---

## 12. Thrown-Marker Teleport System

### 12.1 Player interaction

Recommended interaction model:

1. Hold teleport input to enter aim mode.
2. Aim with mouse or right stick.
3. Release to throw the marker.
4. Marker travels and either attaches to a valid surface/anchor or returns/fails.
5. Press teleport again to warp.
6. Press cancel to recall the marker without warping.

Alternative tap-to-throw/tap-to-warp behavior can be offered as an accessibility option if it tests better.

### 12.2 Aim behavior

- Keyboard/mouse uses cursor position constrained by maximum range.
- Controller uses right-stick direction.
- Provide optional aim slowdown or time dilation only if it does not disrupt combat balance.
- Snap gently toward valid nearby surfaces/anchors.
- Show a trajectory and destination silhouette.
- Use color and shape, not color alone, to distinguish valid and invalid targets.
- Ensure the reticle remains visible against every biome.

### 12.3 Destination validation

The destination resolver must:

- Use global coordinates.
- Test the full player collision shape.
- Search along the surface normal for nearby clearance.
- Reject kill volumes.
- Reject closed gates and forbidden story barriers.
- Reject crushing geometry.
- Reject out-of-bounds destinations.
- Reject moving geometry unless explicitly supported.
- Reject rooms that are not loaded/connected.
- Prevent teleporting through permanent gate materials unless an upgrade allows it.
- Provide a safe failure/recall path.

### 12.4 Combat behavior

- Teleport can cancel only explicitly approved states.
- Damage/invulnerability rules during departure, transit, and arrival are authored and visible.
- Arrival should not automatically damage enemies until an upgrade grants that effect.
- Teleport cannot bypass boss arena locks.
- Bosses may react to repeated teleport behavior but cannot disable the core ability arbitrarily.
- Marker collision with enemies must have defined behavior: pass through, attach, bounce, or upgrade-dependent attachment.

### 12.5 Failure prevention

- Store the last safe grounded position.
- If post-warp validation fails, return the player to the last safe position.
- Never save while the marker or player is in a transient teleport state.
- Recall the marker during room transitions, death, cutscenes, fast travel, and load.
- Add a developer overlay showing trajectory, collision checks, candidate destinations, and rejection reason.

### 12.6 Teleport upgrades

The starting ability must be useful but leave room for progression. Candidate upgrades:

- Increased throw range.
- Faster projectile.
- Marker recall refund.
- Pass through designated phase grates.
- Attach to designated teleport anchors.
- Second marker or chained teleport.
- Arrival shockwave.
- Time-slow during aim.

Do not commit every candidate. Select only upgrades that create strong new routes without making room boundaries meaningless.

---

## 13. Metroidvania Progression and Items

### 13.1 Starting movement kit

The existing run, jump, wall movement, and dash are strong. Unless onboarding tests show overload, preserve them rather than removing enjoyable capabilities solely to manufacture gates.

Recommended start:

- Run.
- Jump.
- Coyote time and jump buffering.
- Wall slide/jump.
- Dash/slide.
- Universal basic teleport.
- Starting weapon family.

### 13.2 Major progression abilities

Use route permissions and advanced interactions rather than removing the current foundation. Candidate major upgrades:

- Phase teleport through marked barriers.
- Heavy ground break.
- Magnetic rail grip or ceiling travel.
- Gravity anchor for low-gravity/zero-gravity control.
- Environmental corruption resistance.
- Multi-marker/chained teleport.
- Energy-field interaction for terminals and sealed doors.

Each major ability must:

- Open at least one critical route and several optional routes.
- Receive a safe tutorial room.
- Be immediately used after acquisition.
- Produce at least one meaningful earlier-world backtracking reward.
- Appear clearly on the map legend after discovery.

### 13.3 Item categories

- Unique weapons.
- Weapon upgrade components.
- Armor/body modules.
- Accessories/passive modules.
- Health fragments.
- Energy fragments.
- Major abilities.
- Keys/access credentials.
- Map data.
- Currency/materials.
- Lore records.
- Quest items.
- Consumables only if they add real tactical value.

### 13.4 Icon policy

- Use the existing 1,785-icon library as source material.
- Define item taxonomy before selecting icons.
- Curate one consistent outline, palette, size, and lighting style.
- Normalize selected icons to standard runtime sizes.
- Do not use visually inconsistent icons merely because they exist.
- Provide an unknown/locked icon and robust fallbacks.

---

## 14. Story, Dialogue, and Cutscenes

### 14.1 Narrative constraints created by customization

- The protagonist must not depend on a fixed appearance.
- Scripts use the saved name and pronoun tokens.
- Voice barks remain generic enough to fit different names and story paths.
- Cutscenes use the live player sprite or selected portrait.
- Avoid pre-rendered cinematics that assume one protagonist appearance.

### 14.2 Dialogue system

Required features:

- Speaker name.
- Portrait and expression/variant.
- Rich text with controlled effects.
- Player-name/pronoun tokens.
- Choice prompts where narratively useful.
- Story-flag conditions.
- Item/quest rewards.
- Input-device-aware continue prompt.
- Auto-advance option.
- Text-speed option.
- Instant text option.
- Backlog/history.
- Skip previously seen sequences.
- Optional voice bark per line/beat.
- Localization-ready string IDs.

### 14.3 Cutscene director

Support commands for:

- Lock/unlock player control.
- Move player or NPC.
- Play animation.
- Change facing.
- Move/zoom/shake camera.
- Fade screen.
- Play music/stinger/SFX.
- Spawn or remove an entity.
- Change environment state.
- Wait for time, signal, animation, or dialogue.
- Set story flag.
- Start encounter or boss.
- Grant item/ability.
- Transition room/region.

Every sequence must have a safe skip endpoint that applies all required state changes.

### 14.4 Story cadence

Minimum content cadence:

- Opening creation/prologue sequence.
- Region arrival scene for each major region.
- One or more district-level story beats per district.
- Boss intro and defeat scene.
- NPC conversations that update after major events.
- Environmental lore and optional records.
- Mid-game escalation/reveal.
- Pre-final-region commitment beat.
- Ending reflecting core completion and selected major optional outcomes where feasible.

### 14.5 Narrative production deliverables

- Story premise and theme brief.
- Region-by-region outline.
- Character/NPC roster.
- Protagonist dialogue rules.
- Quest list.
- Cutscene list with triggers and skip endpoints.
- Dialogue database/string table.
- Portrait assignment table.
- Voice-bark event table.
- Localization glossary.

---

## 15. UI and Menu Plan

### 15.1 Title flow

Target options:

- Continue.
- New Game.
- Load Game.
- Settings.
- Credits.
- Quit.

Continue is disabled when no valid save exists. New Game opens save-slot selection and then Character Creator.

### 15.2 Save slots

- At least three manual campaign slots.
- Each slot summary shows:
  - Character name.
  - Portrait.
  - Playtime.
  - Current district/room.
  - Map completion percentage.
  - Last save timestamp.
  - Equipped weapon family.
- Support empty, valid, corrupted, and recoverable-backup states.
- Confirm overwrite and delete.

### 15.3 Pause root

Recommended tabs:

- Map.
- Equipment.
- Inventory.
- Abilities.
- Journal.
- System.

The pause UI must be completely controller navigable and restore focus correctly.

### 15.4 Map

- Room cells and connections.
- Region/district colors.
- Current room and player marker.
- Save rooms.
- Activated warp rooms.
- Barber/tailor/shop/NPC services.
- Known locked barriers.
- Major objective marker when appropriate.
- Player-placed markers if scope permits.
- Completion percentage by region and overall.
- Legend and zoom/pan controls.

### 15.5 Equipment

- Exact live player preview.
- Selected fixed portrait.
- Equipped weapon and slots.
- Before/after stat comparison.
- Weapon-family move summary.
- Sort/filter.
- Clear explanation of locked slots.
- Confirmation feedback and immediate visual update.

### 15.6 Inventory

- Categories aligned with item taxonomy.
- Stack counts.
- Description, lore, use/equip status.
- Key items separated from consumables/materials.
- Prevent use during invalid states.

### 15.7 Abilities

- Major traversal abilities.
- Teleport upgrades.
- Weapon-family mastery/upgrades if retained.
- Clear explanation and current controls.
- Demonstration animation or icon sequence where useful.

### 15.8 Journal

- Main objectives.
- Optional quests.
- Completed entries.
- Lore records.
- NPC hints.
- Do not reveal undiscovered secret objectives.

### 15.9 Warp room UI

- World map with activated destinations.
- Region and district names.
- Destination preview/thumbnail if available.
- Current destination disabled.
- Confirm/cancel.
- No destination softlocks.

### 15.10 Settings and accessibility

Retain current settings architecture and add:

- Full input rebinding.
- Separate protagonist-voice volume.
- Bark enable/disable.
- Text speed and instant text.
- Auto-advance.
- Screen shake strength.
- Hit-stop/flash reduction.
- Aim assist strength.
- Teleport aim behavior.
- Hold/toggle options where useful.
- Controller vibration strength/off.
- High-contrast teleport reticle.
- Subtitles for intelligible barks.

---

## 16. Input and Controller Plan

### 16.1 Existing actions to preserve or migrate

- `attack_melee`.
- `attack_shoot`.
- `interact`.
- `pause_game`.
- `slide_dash`.
- Existing movement/UI actions.

### 16.2 New actions

Candidate additions:

- `teleport`.
- `teleport_cancel`.
- `aim_left/right/up/down` or right-stick vector handling.
- `open_map`.
- `open_inventory` or a single pause root.
- `weapon_quick_swap` only if secondary weapons are approved.
- `use_item` only if field consumables are approved.

### 16.3 Controller requirements

- Test Xbox, PlayStation, and a generic SDL-compatible controller.
- Detect active input device and update prompts immediately.
- Avoid requiring a mouse for any gameplay or menu flow.
- Use deadzone and aim-response settings independently.
- Ensure right-stick teleport aiming does not interfere with camera behavior.
- All character-creator controls must work on controller.
- All lists/grids must preserve focus after closing a modal.

### 16.4 Default conceptual layout

Final button labels are determined during implementation and testing, but the conceptual grouping should be:

- Face button: primary weapon attack.
- Face button: secondary/charged/family action.
- Face button: jump.
- Face button: interact/cancel according to context.
- Shoulder/trigger: dash.
- Shoulder/trigger: teleport aim/throw/warp.
- Right stick: teleport aim.
- Menu/View: map or pause.

No final layout is accepted until it passes a human controller test across traversal, combat, menus, and Character Creator.

---

## 17. Enemy Production Plan

### 17.1 Behavior archetypes

Art packs should be assigned to deliberate gameplay roles:

- Basic ground pursuer.
- Defensive/blocking fighter.
- Ranged shooter.
- Archer/ballistic attacker.
- Flying harasser.
- Charger.
- Heavy bruiser.
- Ambusher.
- Summoner/support caster.
- Area-denial caster.
- Turret/static defense.
- Teleport-aware hunter.
- Mini-boss.
- Boss add/summon.

### 17.2 Enemy definition contract

Each imported enemy requires:

- Stable ID and display name.
- Region assignments.
- Behavior archetype.
- Health, damage, stagger, speed, and resistances.
- Detection and leash rules.
- Navigation assumptions.
- Attack definitions with telegraph, active frames, recovery, and punish window.
- Hurt/death behavior.
- Drop table.
- Animation map.
- Collision and hitbox setup.
- Audio and VFX profile.
- Difficulty variants where necessary.
- Test scene.

### 17.3 Encounter design

- Encounters are designed around complementary roles, not raw enemy count.
- Avoid placing ranged enemies where the camera hides their attacks.
- Teleport must create options without trivializing every formation.
- Arena exits and retreat rules must be clear.
- Mandatory lockdown encounters are used sparingly.
- Normal rooms respawn enemies according to a consistent rule after save/rest/room cycles.
- Unique or difficult encounters have a nearby recovery opportunity proportional to risk.

### 17.4 Enemy asset triage

For each source pack:

1. Confirm license entry.
2. Preview all animations.
3. Measure frame size and scale.
4. Identify missing actions.
5. Assign gameplay role.
6. Export/normalize runtime frames.
7. Build `SpriteFrames` and event data.
8. Build collision and attack definitions.
9. Test alone.
10. Test in a real room.

Do not import visually attractive enemies without a role and complete behavior contract.

---

## 18. Props, Traps, and Environmental Interaction

### 18.1 Prop categories

- Structural set dressing.
- Foreground silhouettes.
- Background machinery.
- Destructible clutter.
- Loot containers.
- Interactive terminals.
- Doors and security gates.
- Save/warp equipment.
- Hazard machinery.
- Story/lore props.

### 18.2 Trap families

Candidate traps appropriate to the existing regions:

- Electrical signs and exposed conduits.
- Timed laser grids.
- Rotating lasers.
- Security turrets.
- Steam vents.
- Reversible conveyors.
- Crushers and presses.
- Smelting pours and heat zones.
- Breakaway platforms.
- Moving platforms and lifts.
- Low-gravity gaps.
- Gravity fields.
- Corruption pools/nodes.
- Void pits.
- Collapsing structures.
- Alarm gates and ambush locks.
- Teleport-anchor puzzles.
- Phase barriers.
- Projectile-reflecting or blocking fields.

### 18.3 Trap scene contract

Every trap requires:

- Stable reusable scene.
- Idle, warning, active, and recovery states where applicable.
- Collision/hitbox setup.
- Visual and audio telegraph.
- Damage and knockback definition.
- Reset behavior.
- Persistence behavior if switch-controlled.
- Interaction with teleport marker.
- Interaction with enemies where relevant.
- Debug visualization.
- Automated state test.
- Human fairness test.

### 18.4 Level-design rule

Props are selected to reinforce a room's purpose and silhouette. Do not fill every surface. Interactive objects must remain visually distinct from purely decorative versions.

---

## 19. District-by-District Stage Plan

The following plans preserve existing names and mechanics while expanding them into connected districts. Exact room counts are adjusted after greybox playtests.

### 19.1 Rooftop Alley — vertical-slice district

**Purpose:** Introduce the created hero, core movement, combat weapon, universal teleport, map, save room, and world tone.

**Spatial identity:** Horizontal rooftop runs connected to short vertical building interiors, fire escapes, signs, utility shafts, and alleys.

**Required content:**

- Character-creation exit/prologue spawn.
- Safe movement onboarding.
- Teleport aim and safe-destination tutorial.
- One low-pressure combat tutorial for every possible starting family.
- Horizontal flow sequence.
- Vertical interior/shaft sequence.
- Electrical-sign trap sequence.
- One optional teleport secret.
- One early alternate-weapon route.
- First save room.
- First map reveal.
- Barber/tailor introduction or a clear path to their hub.
- First story scene and NPC interaction.
- Shortcut returning near the district entrance.
- District exit into Billboard Highway and a visible locked connection foreshadowing later backtracking.

**Acceptance gate:** A new player can create a character and reach the next district in 15–20 minutes without developer assistance, while an experienced player has room to move quickly.

### 19.2 Billboard Highway

**Purpose:** Emphasize high-speed horizontal traversal and readable moving hazards.

**Spatial identity:** Elevated billboard catwalks, traffic structures, animated signs, suspended maintenance corridors, and alternate upper/lower routes.

**Required content:**

- Moving-platform introduction/recontextualization.
- Electrical sign timing challenge.
- Long horizontal combat lanes balanced against ranged enemies.
- Teleport use across broken signage and behind cover.
- At least two route elevations with different rewards.
- A billboard landmark visible across multiple rooms.
- Early optional weapon pickup.
- Shortcut toward Rooftop Alley or Skybridge Junction.
- Story clue pointing toward corporate activity and the Communication Spire.

### 19.3 Communication Spire

**Purpose:** Deliver the first sustained vertical climb and establish orbital connection.

**Spatial identity:** Exterior antenna climb, internal signal chambers, elevators, maintenance shafts, and transmission arrays.

**Required content:**

- Multi-room vertical ascent.
- Signal hazards with clear pulses.
- Flying-enemy combat in spaces with safe recovery platforms.
- Teleport anchor puzzles.
- A fall-recovery route that avoids repeating the entire climb.
- Mid-climb shortcut/elevator.
- Orbital-transit foreshadowing.
- Major story scene or data discovery.
- Locked future route requiring a later phase/energy ability.

### 19.4 Skybridge Junction

**Purpose:** Function as a major loop and route-crossing district.

**Spatial identity:** Multiple bridges, transit platforms, broken towers, open skyline, and service tunnels.

**Required content:**

- Moving and breakaway platform combinations.
- Dash-plus-teleport sequence.
- Multiple exits or visible future connections.
- First warp room or primary fast-travel tutorial.
- Hub-like NPC/service presence where appropriate.
- A strong shortcut network.
- Optional combat challenge with a useful equipment reward.

### 19.5 Executive Helipad

**Purpose:** Conclude Cyber City with the Helix Warden boss and open the factory descent.

**Spatial identity:** Executive tower approach, rooftop security, helipad arena, and post-boss access shaft.

**Required content:**

- Short high-tension approach.
- Recovery/save opportunity before boss.
- Boss intro.
- Helix Warden fight using air hazards and projectile arcs.
- Teleport-safe arena bounds and clear invalid destinations.
- Post-boss story scene.
- Permanent world-state change and route opening.

### 19.6 Sub-Level Intake

**Purpose:** Transition from city architecture into industrial machinery.

**Spatial identity:** Waste intake, cargo lifts, water/steam infrastructure, and descending conveyors.

**Required content:**

- Conveyor onboarding within the connected-world context.
- Steam-vent timing.
- Vertical descent with recovery ledges.
- Industrial props and loot containers.
- New factory enemy role.
- Shortcut/elevator back toward Cyber City.

### 19.7 Conveyor Assembly

**Purpose:** Build moving-floor combat and route control.

**Spatial identity:** Assembly lines, reversible conveyors, sorting machinery, and suspended service routes.

**Required content:**

- Reversible conveyor switches.
- Combat encounters affected by floor motion.
- Safe visual language for drop hazards.
- Optional route requiring deliberate switch ordering.
- Weapon/module reward.
- Shortcut that changes conveyor direction permanently or semi-permanently.

### 19.8 Smelting Core

**Purpose:** Combine vertical navigation with heat and timed industrial hazards.

**Spatial identity:** Furnace shafts, molten channels, coolant paths, and heavy machinery.

**Required content:**

- Heat zones.
- Steam vents.
- Laser/security integration.
- Vertical rise/descent around the core.
- Heavy-weapon breakable opportunity.
- A safe route readable before commitment.
- Major ability or resistance upgrade candidate.

### 19.9 Robotic Maintenance

**Purpose:** Emphasize machinery control, terminals, gates, and deliberate puzzle-combat rooms.

**Spatial identity:** Repair bays, dormant robots, terminals, crushers, and maintenance tunnels.

**Required content:**

- Crushers with clear warning cycles.
- Terminals and security gates.
- Optional reactivation/disable choices.
- Enemy ambush using repair-bay props.
- Shortcut opened by maintenance control.
- Lore/story scene concerning the factory's purpose.

### 19.10 Assembly Engine

**Purpose:** Conclude the factory with the Assembly Colossus and expose the route toward later corruption.

**Required content:**

- Final conveyor/shockwave approach challenge.
- Save room before boss.
- Multi-phase Assembly Colossus encounter.
- Arena machinery with readable states.
- Weapon-family-neutral punish windows.
- Post-boss route and story-state change.

### 19.11 Lunar Surface Arrival

**Purpose:** Introduce low gravity without invalidating learned movement.

**Spatial identity:** Exterior lunar structures, landing facilities, exposed gaps, and sealed airlocks.

**Required content:**

- Safe low-gravity tutorial.
- Long-gap traversal.
- Teleport trajectory adaptation.
- Exterior/interior contrast.
- Warp/transit arrival point.
- Environmental story establishing Neon Moon Protocol.

### 19.12 Research Cleanrooms

**Purpose:** Provide precise hazard navigation and controlled laboratory exploration.

**Spatial identity:** Sterile rooms, glass chambers, security doors, experimental props, and contamination controls.

**Required content:**

- Terminals, security gates, and laser grids.
- Optional specimen/loot rooms.
- Clear foreground/background separation.
- Story records and NPC/AI communication.
- A route opened later by laboratory access or phase teleport.

### 19.13 Security Grid Shaft

**Purpose:** Deliver an advanced vertical gauntlet.

**Spatial identity:** Tall security shaft, rotating lasers, turrets, low gravity, and emergency platforms.

**Required content:**

- Sustained vertical traversal.
- Rotating-laser patterns.
- Turret pressure with safe cover.
- Teleport anchors and forbidden surfaces.
- Midpoint recovery/shortcut.
- Optional high-skill reward route.

### 19.14 Bio-Tech Labs

**Purpose:** Combine gravity manipulation, ambushes, switches, and narrative revelation.

**Spatial identity:** Organic experiments, gravity chambers, multi-switch laboratories, and damaged observation rooms.

**Required content:**

- Gravity zones.
- Multi-switch route puzzle.
- Ambush encounters with escape options.
- Significant story/cutscene beat.
- Corruption foreshadowing.
- Major upgrade or final-region access component.

### 19.15 Orbital Command

**Purpose:** Conclude Neon Moon with the Lunar Oracle and trigger the Abyssal transition.

**Required content:**

- Command-center approach.
- Laser-sweep and gravity-zone synthesis.
- Save room.
- Lunar Oracle boss with readable phases and teleport-aware patterns.
- Major story reveal.
- Permanent corruption/world-state change.

### 19.16 Corrupted Outpost

**Purpose:** Introduce corruption mechanics and the endgame enemy roster.

**Spatial identity:** Familiar technology overtaken by organic/void structures.

**Required content:**

- Corruption zones.
- Elite enemy introduction.
- Visual comparison to earlier clean areas.
- Resistance/cleansing interaction.
- Route back to a changed earlier-world location where appropriate.

### 19.17 The Dark Chasm

**Purpose:** Deliver a tense vertical descent with controlled visibility.

**Spatial identity:** Deep void shafts, broken machinery, sparse light, moving platforms, and dangerous drops.

**Required content:**

- Low-visibility presentation that preserves hazard readability.
- Moving-platform and void-pit sequences.
- Dash/teleport challenge.
- Recovery routes after partial falls.
- Optional high-risk secret.
- Strong audio/environmental storytelling.

### 19.18 Bio-Mechanical Nest

**Purpose:** Focus on organic ambushes, corruption nodes, and enemy ecology.

**Spatial identity:** Living machinery, hatching chambers, corrupted gates, and pulsing pathways.

**Required content:**

- Corruption-node interactions.
- Ambushes with fair telegraphs.
- Security gates repurposed by corruption.
- New enemy combinations.
- Optional nest-cleansing reward.
- Story evidence connecting earlier regions.

### 19.19 Abyssal Sanctuary

**Purpose:** Test mastery by combining previously learned mechanics.

**Spatial identity:** Monumental endgame structure blending factory, lunar, and void motifs.

**Required content:**

- Carefully selected conveyor, laser, gravity, platform, and elite combinations.
- No arbitrary mechanic pileup; every room has one readable primary test.
- Final major shortcut and warp room.
- Optional endgame weapon/module challenge.
- Pre-final-boss narrative preparation.

### 19.20 Heart of the Void

**Purpose:** Final approach, Void Cerberus encounter, climax, and ending.

**Required content:**

- Short, intense final approach.
- Final save/warp opportunity before the commitment point.
- Void Cerberus boss with desperation phase.
- Teleport-aware arena and anti-softlock validation.
- Skippable intro and safe restart.
- Ending sequence using custom name, pronouns, portrait, and live player visual.
- Post-game save behavior and optional continuation rules.

---

## 20. Boss Production Framework

Each boss requires a completed design sheet covering:

- Name and fantasy/goal.
- Primary player skill being tested.
- Signature mechanic.
- One-sentence pitch.
- Arena layout.
- Phase list.
- Move list.
- Purpose of every move.
- Telegraph duration and presentation.
- Active window.
- Recovery/punish window.
- Interaction with teleport.
- Interaction with every weapon family.
- Failure/restart flow.
- Spectacle and memorable moment.
- Audio and music plan.

Boss acceptance requirements:

- No unavoidable damage under intended difficulty rules.
- No weapon family is nonviable.
- Teleport cannot leave the arena or enter invalid geometry.
- Intro and defeat sequences are skippable after first viewing.
- Restart time is short.
- Boss health and damage are tested with expected upgrade ranges.
- Controller and keyboard tests are both complete.

---

## 21. Save-System Migration

### 21.1 Save version

- Increment `SAVE_VERSION` from 1 to 2 when the first new schema is implemented.
- Preserve atomic write and backup recovery behavior.
- Add slot-aware paths.
- Do not silently overwrite incompatible saves.

### 21.2 Target save schema

```text
version
saved_at_utc
slot_id
summary
├── character_name
├── portrait_id
├── play_time
├── region_id
├── district_id
├── room_id
├── map_completion
└── equipped_weapon_id
game
├── character_profile
├── player_stats
├── inventory
├── equipment
├── abilities
├── world_progress
│   ├── current_room_id
│   ├── spawn_connection_id
│   ├── last_safe_save_room_id
│   ├── discovered_rooms
│   ├── persistent_object_states
│   ├── activated_warp_nodes
│   └── defeated_bosses
├── story_flags
├── quest_states
├── seen_cutscenes
└── play_time
settings
checksum
```

### 21.3 Migration behavior

The old linear-stage save cannot map perfectly to the new world. Provide one of these explicit policies before release:

- Development-only reset while the new version is not publicly released; or
- Migration that maps the furthest completed old stage to the entrance of the corresponding new district and grants conservative equivalent progression.

Do not pretend an old stage coordinate can safely resume inside a rebuilt room.

### 21.4 Save safety

- Save only at valid grounded/spawn states.
- Save automatically at activated save rooms, major rewards, boss defeats, and successful fast travel.
- Keep manual saving restricted according to final design; SOTN-style save rooms are the recommended primary model.
- Store current health/energy according to the chosen save-room behavior.
- Validate inventory IDs and provide fallbacks for removed content.
- Validate appearance IDs and substitute safe defaults if an option is missing.

---

## 22. Asset Ingestion and Licensing Workflow

### 22.1 Source-to-runtime rule

External absolute paths are source libraries only. Selected content is copied into a self-contained repository path such as:

```text
assets/runtime/
├── characters/player_creator/
├── portraits/
├── weapons/
├── enemies/
├── props/
├── ui/icons/
├── audio/voices/
└── world/
```

### 22.2 Ingestion checklist

For every imported pack or asset group:

- [ ] Confirm source path.
- [ ] Confirm license file and original provenance record.
- [ ] Add/update `LICENSES.md` and runtime license manifest.
- [ ] Select only required assets.
- [ ] Rename to stable ASCII `snake_case` names.
- [ ] Remove duplicate previews and unused source exports from runtime.
- [ ] Normalize image mode, palette, and transparency.
- [ ] Normalize frame dimensions/pivots.
- [ ] Configure Godot import settings.
- [ ] Create typed definitions/resources.
- [ ] Add validation tests.
- [ ] Verify a clean clone resolves every runtime dependency.

### 22.3 License caution

License files are present in the inspected folders. The project should still retain the original source/store license or purchase record for third-party packs. A copied license statement should be traceable to the asset provider and should not be treated as proof of rights without provenance.

---

## 23. Testing Strategy

### 23.1 Unit tests

Add tests for:

- Appearance ID validation.
- Layer compatibility.
- Pronoun token resolution and verb agreement.
- Voice-profile/category lookup.
- Weapon stat calculations.
- Combo-state transitions.
- Inventory stacking and uniqueness.
- Equipment restrictions.
- Ability-gate checks.
- Teleport destination validation.
- Persistent-object serialization.
- Map discovery.
- Save migration and checksums.

### 23.2 Integration tests

Add tests for:

- Character Creator → confirm → gameplay visual.
- Character profile save/load round trip.
- Barber preview/cancel/confirm.
- Tailor preview/cancel/confirm.
- Starting weapon choice.
- Early alternate-weapon pickup.
- Equip and visible-weapon change.
- Teleport throw/warp/cancel.
- Invalid teleport rejection.
- Room transition and spawn connection.
- Open shortcut persists after leaving/reloading.
- Collected unique item does not respawn.
- Warp activation and destination travel.
- Dialogue name/pronoun substitution.
- Cutscene skip applies required state.
- Voice bark cooldown and priority.
- Boss lock prevents illegal exits/warps.

### 23.3 Automated traversal

Retain structural traversal tests but expand them to verify the world graph:

- Every room ID is unique.
- Every connection resolves in both expected directions unless explicitly one-way.
- Every critical district is reachable under the intended ability state.
- No critical connection requires an unobtainable ability.
- Warp nodes do not bypass story gates.
- Map cells align with room connections.
- Boss defeat opens the correct permanent route.

Automated graph reachability is not a substitute for physical playtesting.

### 23.4 Physical reachability harness

Where practical, add authored traversal probes/checkpoints that test:

- Maximum standard jump.
- Wall-jump routes.
- Dash gaps.
- Teleport range and clearance.
- Low-gravity routes.
- Moving-platform timing bounds.
- Required route fall recovery.

These tests should instantiate the real collision geometry and movement parameters rather than calling completion bypasses.

### 23.5 Human QA matrix

Every district requires:

- Keyboard/mouse first-clear playthrough.
- Controller first-clear playthrough.
- Starting-weapon-family coverage.
- Minimal-upgrade route.
- Expected-upgrade route.
- Backtracking after major abilities.
- Death/reload at every save room.
- Teleport abuse/edge-case pass.
- Map readability pass.
- Camera and motion comfort pass.
- Softlock and out-of-bounds pass.
- Timing/pacing measurement.

### 23.6 Full-game QA

Before beta:

- Complete the game start to finish without developer shortcuts.
- Complete it with every starting weapon family.
- Complete it with keyboard/mouse and controller.
- Test new game, multiple save slots, backup recovery, and post-game behavior.
- Test all mandatory cutscene skips.
- Test all warp destinations.
- Test all major ability backtracking routes.

---

## 24. Performance and Technical Budgets

Establish final budgets after the vertical slice, but measure at least:

- Frame time at target resolution and common 1080p/1440p displays.
- Peak room load time.
- Room-transition duration.
- Memory usage with current and adjacent room resources.
- Layered-player draw calls.
- Maximum simultaneous enemies/projectiles/particles.
- UI opening time for inventory and map.
- Save duration.
- Audio voice count.

Performance rules:

- No runtime dependency on external asset-library paths.
- No loading all 1,785 icons or all enemy packs at startup.
- No rebuilding character frame atlases every animation change.
- Pool high-frequency projectiles/effects only when profiling justifies it.
- Keep room scenes bounded and unload unused regions.
- Validate pixel-perfect rendering at supported window sizes.

---

## 25. Accessibility and Usability Baseline

Required baseline:

- Complete controller navigation.
- Complete keyboard navigation.
- Rebindable gameplay actions.
- Text speed options.
- Subtitle support for intelligible voice clips.
- Protagonist bark mute.
- Separate music, SFX, UI, ambience, and voice volume where practical.
- Screen-shake strength.
- Controller vibration strength/off.
- High-contrast teleport destination feedback.
- Aim-assist adjustment.
- Hold/toggle alternatives for teleport aim if feasible.
- Reduced flashing option.
- Clear boss telegraphs using shape/motion/audio, not color alone.
- Pause during dialogue and menus.

Difficulty assists to evaluate after the vertical slice:

- Damage reduction.
- Additional checkpoint health recovery.
- Wider teleport surface snap.
- Slower hazard timing.
- Boss retry assistance.

Assists should not disable story completion or shame the player.

---

## 26. Implementation Phases and Gates

### Phase MV-0 — Scope, branches, and asset registry

**Work**

- Adopt this plan as the new scope contract.
- Preserve the working linear build while the new foundation is developed.
- Define runtime asset naming and ingestion paths.
- Register licenses/provenance for selected creator, weapon, prop, enemy, Forge, mechanics, and voice assets.
- Create data-resource schemas.

**Gate**

- Existing game still runs.
- No external absolute path is used at runtime.
- Selected vertical-slice assets have traceable licenses.

### Phase MV-1 — Character laboratory

**Work**

- Build Character Creator prototype.
- Build `CharacterProfile` and `CharacterAppearance`.
- Build synchronized layered `PlayerVisual`.
- Map all 102 creator frames.
- Add one portrait prototype.
- Add five voice previews.
- Save/load the created character.

**Gate**

- A character can be created, saved, loaded, and rendered through all core animations without layer drift.

### Phase MV-2 — Weapon and teleport laboratory

**Work**

- Implement Sword family end to end.
- Build weapon definition/event pipeline.
- Port thrown-marker teleport safely.
- Add mouse and controller aim.
- Add invalid-destination feedback and recovery.
- Build traversal/combat test rooms.

**Gate**

- Sword combat and teleport can be used together for fifteen uninterrupted minutes without visual desynchronization, input conflict, softlock, or invalid warp.

### Phase MV-3 — World/save foundation

**Work**

- Build WorldRoot, room loading, stable connections, map discovery, persistent object state, and save version 2.
- Add multiple save slots.
- Add save room and warp room prototypes.
- Add dialogue/cutscene foundations.

**Gate**

- The player can move through a multi-room loop, open a shortcut, save, quit, reload, and fast travel with all state intact.

### Phase MV-4 — Rooftop Alley vertical slice

**Work**

- Build the complete 15–20 minute district.
- Integrate creator, Sword, teleport, voice barks, portrait, story, enemies, traps, props, save room, map, and first meaningful reward.
- Add barber/tailor prototype access.
- Conduct full human QA.

**Gate**

- A fresh player can start at New Game and complete the district without developer intervention.
- The district meets pacing, quality, controller, and softlock requirements.
- Measured production velocity is available for scheduling the remaining game.

### Phase MV-5 — Complete Character Creator and base weapons

**Work**

- Finish all creator options.
- Finish twelve portraits.
- Finish Dagger, Spear, Heavy, Bow, and Staff/Wand families.
- Place other families in early-world optional routes.
- Finish barber/tailor UI.

**Gate**

- All starting choices are viable through the vertical slice and early Cyber City rooms.

### Phase MV-6 — Cyber City production

**Work**

- Billboard Highway.
- Communication Spire.
- Skybridge Junction.
- Executive Helipad.
- Helix Warden.
- Cyber City story and side content.

**Gate**

- Cyber City is one connected, replayable region with shortcuts, warp access, boss progression, and backtracking hooks.

### Phase MV-7 — Mega Robot Factory production

**Work**

- Five factory districts.
- Factory-specific traps/props/enemies.
- Assembly Colossus.
- Region ability/reward progression.
- Cross-region shortcuts.

**Gate**

- Factory is complete and the world remains reachable and save-safe across Cyber City and Factory.

### Phase MV-8 — Neon Moon production

**Work**

- Orbital transit.
- Five lunar districts.
- Low-gravity and gravity systems.
- Lunar Oracle.
- Major story reveal.

**Gate**

- All three regions form a coherent save/map/fast-travel world.

### Phase MV-9 — Abyssal Night production

**Work**

- Five endgame districts.
- Corruption systems.
- Endgame enemies and elite combinations.
- Void Cerberus.
- Ending and post-game behavior.

**Gate**

- The complete game is playable from Character Creator to ending without developer shortcuts.

### Phase MV-10 — Alpha

**Work**

- All critical content present.
- All story scenes present in functional form.
- All upgrades, weapons, bosses, and rooms present.
- Full save migration and validation.
- No known critical-path blockers.

**Gate**

- Full internal playthrough completed with every starting family.

### Phase MV-11 — Beta

**Work**

- Balance.
- Accessibility.
- Performance.
- Art/lighting/audio pass.
- Controller compatibility.
- Bug fixing.
- External playtesting.

**Gate**

- Content locked.
- No severity-1 bugs.
- Save compatibility stable.
- Target performance met.

### Phase MV-12 — Release candidate

**Work**

- Clean-clone verification.
- Export/package verification.
- License and credits audit.
- Full release checklist.
- Final playthroughs.

**Gate**

- Release definition of done is satisfied.

---

## 27. Scheduling and Estimation Method

Do not estimate the entire conversion from raw stage count alone. The first vertical slice is the calibration project.

Track for the vertical slice:

- Engineering hours by system.
- Greybox hours by room.
- Art-dressing hours by room.
- Enemy setup hours per archetype.
- Weapon-family integration hours.
- Dialogue/cutscene hours per minute/sequence.
- QA and rework hours.

After Rooftop Alley is approved:

1. Calculate average production time per traversal, combat, service, story, and boss room.
2. Estimate remaining room counts by district.
3. Add region-specific system costs.
4. Add at least 25–35% integration, QA, and rework reserve.
5. Schedule content in region-complete increments.

Until that measurement exists, any calendar completion date is speculative.

---

## 28. Risk Register

| Risk | Severity | Mitigation |
|---|---:|---|
| Layered creator animations drift or misalign | High | Build authoritative frame controller and validate all layers before stage production |
| Animated weapons do not match character poses | High | Approve families individually; use authored offsets, native creator overlays, and effect-only layers where necessary |
| Teleport creates softlocks/out-of-bounds exploits | Critical | Full-body destination validation, last-safe fallback, debug overlay, edge-case test rooms, room-boundary rules |
| One-world conversion breaks current saves/progression | High | Versioned schema, explicit migration policy, development save reset before public release |
| Twenty districts become repetitive | High | One signature mechanic, landmark, shortcut, reward, and authored spatial identity per district |
| Too many new systems delay stage production | High | Build only the minimum foundation needed for Rooftop Alley, then prove it in the vertical slice |
| Custom protagonist weakens story presentation | Medium | Name/pronoun tokens, live sprite cutscenes, fixed portrait identities, generic voice barks |
| Fixed portraits fail to match customization | Medium | Limited editable portrait layers plus exact live sprite preview in profile/equipment screens |
| Voice barks become repetitive | Medium | Category cooldowns, weighted randomization, priority rules, global mute |
| External assets create inconsistent art direction | High | Curated imports, palette/scale normalization, region art bible, reject mismatched assets |
| Asset licenses lack provenance | High | Retain original source/store records and update license manifest during ingestion |
| Controller teleport aiming feels worse than mouse | High | Right-stick tuning, surface snap, aim assist options, controller-first QA |
| Generic automated traversal gives false confidence | Critical | Physical collision probes plus mandatory human full playthroughs |
| Scope grows through optional items/menus | High | Lock release taxonomy after vertical slice; defer nonessential codex/secondary swap features |

---

## 29. Stage Definition of Done

A district is not complete because its scene opens or its exit works. It is complete only when:

- [ ] Critical route is fully authored.
- [ ] Optional routes and secrets are implemented.
- [ ] Vertical and horizontal flow match the district brief.
- [ ] Signature mechanic follows teach–test–twist or another deliberate escalation.
- [ ] Combat encounters have defined roles and pacing.
- [ ] Traps have clear telegraphs and recovery behavior.
- [ ] All required weapon families can complete the district.
- [ ] Teleport cannot escape bounds or bypass prohibited gates.
- [ ] Required backtracking connections work.
- [ ] Shortcut opens from the intended side and persists.
- [ ] Save and warp behavior is correct.
- [ ] Map cells and connections are correct.
- [ ] Story triggers and skip endpoints are correct.
- [ ] Props/art establish a unique identity without obscuring gameplay.
- [ ] Audio, ambience, and voice barks are integrated.
- [ ] Performance meets budget.
- [ ] Automated structural tests pass.
- [ ] Keyboard/mouse human playthrough passes.
- [ ] Controller human playthrough passes.
- [ ] First-clear time is within target or has an approved exception.
- [ ] No known critical softlocks, unreachable rewards, or unfair checkpoints remain.

---

## 30. Feature Definition of Done

A system feature is complete only when:

- [ ] Data contract is documented in code/resources.
- [ ] Runtime implementation exists.
- [ ] Player-facing UI and feedback exist.
- [ ] Keyboard/mouse and controller input work.
- [ ] Save/load behavior is defined and tested.
- [ ] Failure/cancel/edge behavior is implemented.
- [ ] Required assets are self-contained and licensed.
- [ ] Unit/integration tests cover deterministic behavior.
- [ ] Human gameplay test covers feel and readability.
- [ ] Debug-only shortcuts are disabled or isolated from release flow.

---

## 31. Release Definition of Done

The game is ready for release only when:

- [ ] New Game reaches Character Creator and produces a valid playable character.
- [ ] All five voice profiles preview and play correctly.
- [ ] All twelve portraits work with supported customization.
- [ ] All approved weapon families are distinct, visible, balanced, and finishable.
- [ ] Universal teleport is safe and controller-ready.
- [ ] Fast travel works only through discovered warp rooms.
- [ ] All twenty districts are connected and complete.
- [ ] All four regional bosses and the ending work.
- [ ] All critical story scenes support custom name/pronouns and safe skipping.
- [ ] Multiple save slots, backups, and recovery work.
- [ ] Map and persistent state remain correct across a full playthrough.
- [ ] Full playthroughs pass with every starting weapon family.
- [ ] Full playthroughs pass on keyboard/mouse and controller.
- [ ] Performance budgets pass on the minimum target PC.
- [ ] Accessibility baseline is implemented.
- [ ] Clean-clone runtime asset validation passes.
- [ ] All runtime assets have traceable license/provenance entries.
- [ ] No severity-1 bugs remain.
- [ ] No known critical-path softlocks remain.
- [ ] Exported Windows build passes the release checklist.

---

## 32. Immediate Execution Backlog

The next implementation sequence should be performed in this order.

### MV-001 — Curate the character-creator runtime subset

- Copy one valid option from every required layer category into a runtime prototype directory.
- Preserve original source separately.
- Record IDs, layer order, and license source.
- Validate 800×680 dimensions and frame transparency.

### MV-002 — Build the 102-frame animation catalog

- Encode animation names, frame ranges, FPS, looping, and event slots.
- Add a visual test scene showing every layer and animation.
- Verify facing directions.

### MV-003 — Build `CharacterProfile` and save-version prototype

- Add name, pronouns, voice, portrait, appearance, and starting weapon family.
- Round-trip the profile through a development save.
- Do not replace public/current save flow until migration policy is selected.

### MV-004 — Build `PlayerVisual`

- Replace visual dependency in a test copy of the player scene.
- Synchronize all layers.
- Preserve current collision and movement values.
- Verify no gameplay regression.

### MV-005 — Build Character Creator UI prototype

- Name, pronouns, voice preview, basic appearance, starting Sword, portrait placeholder.
- Full controller navigation.
- Confirm/cancel/randomize.

### MV-006 — Curate Sword family art

- Select creator overlay and Animated Weapon Pack effects.
- Map ground/air attacks.
- Build hitbox events and audio/VFX hooks.

### MV-007 — Reimplement safe teleport

- Create marker projectile, aim controller, destination resolver, arrival effect, recall, and debug view.
- Add controller input and invalid-target feedback.

### MV-008 — Build the movement/combat laboratory

- Horizontal test lane.
- Vertical shaft.
- Corners and narrow clearances.
- Moving platform.
- Hazard volumes.
- Enemies at different elevations.
- Teleport exploit cases.

### MV-009 — Build world-room/save prototypes

- Three-room loop.
- Stable connection IDs.
- Persistent shortcut.
- Save room.
- Warp room.
- Map discovery.

### MV-010 — Greybox Rooftop Alley

- Build the full 15–20 minute room graph before detailed art dressing.
- Run first human keyboard/controller passes.
- Revise room sizes and traversal before importing large prop sets.

---

## 33. Final Planning Principle

The first objective is not to produce twenty larger versions of the existing generic stage template. The first objective is to prove one complete, connected, customizable-character metroidvania district from New Game through save, combat, teleport traversal, story, equipment reward, map discovery, shortcut, and exit.

Once Rooftop Alley reaches that bar, it becomes the production benchmark for the rest of the world. Its systems should be reusable; its geometry and encounter rhythm should not be copied.
