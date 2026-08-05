# Cyber City Platformer — Full Completion Implementation Plan

**Repository:** `DocDamage/Cyber-City-Platformer`  
**Engine target:** Godot 4.7.x  
**Primary platform:** Windows 11  
**Plan purpose:** Convert the current platformer foundation and generated campaign layouts into a complete, reproducible, tested, exportable game.

---

## 1. Completion Goal

The project is complete only when all of the following are true:

1. A clean clone of the repository opens in Godot without missing-resource, parse, import, or autoload failures.
2. The game can be launched from a title screen and completed from Act 1-1 through Act 4-5 without editor intervention.
3. All twenty campaign stages have distinct gameplay, functional camera bounds, enemies, checkpoints, hazards, progression, and exits.
4. Each act introduces and develops its promised mechanics rather than reusing only generic terrain and enemies.
5. All four bosses are distinct, fully playable encounters with reliable phase transitions and completion behavior.
6. Save/load, pause, settings, controller support, accessibility basics, campaign completion, credits, and restart flow work.
7. Automated headless tests run on every pull request and block merges when critical systems fail.
8. A Windows export can be created from a clean machine using committed configuration.
9. A release build completes a full smoke-test checklist with no critical or high-severity defects.
10. Documentation reflects the actual implementation and does not claim unverified features.

---

## 2. Current-State Summary

The repository already contains a useful foundation:

- Player movement, jumping, wall sliding, wall jumping, dash, melee, and shooting
- Health, energy, damage, death, respawn, and invulnerability
- Hitbox and hurtbox abstractions
- Collectibles and score
- Checkpoints
- HUD
- Basic enemy patrol logic
- A reusable boss base
- Scene transitions
- Campaign manifest and generated stage scenes
- Basic VFX hooks
- Headless smoke-test scripts

The project is not yet complete because:

- Required runtime assets are ignored and absent from a clean clone
- The active audio manager hard-preloads absent files
- The main scene and tilesets reference absent source art
- Most stages are generated layout passes rather than finished levels
- Campaign stages are wider than the shared camera limit
- Campaign enemy scenes lack the detection node needed for chase behavior
- Act-specific systems such as conveyors, low gravity, turrets, laser grids, moving platforms, and steam hazards are missing
- Most stages have minimal encounter design
- There is no title screen, save system, settings flow, ending, credits, export preset, CI workflow, or release
- Existing smoke tests do not validate full traversal or the actual campaign enemy scene wiring

---

# 3. Engineering Rules

These rules apply to every implementation task.

## 3.1 Source-Control Rules

- Work on a dedicated completion branch such as:
  - `feature/full-game-completion`
- Use one focused commit per completed task.
- Do not combine unrelated repairs in one commit.
- Do not rewrite the `main` branch history.
- Do not mark a task complete until its acceptance criteria pass.
- Tag stable milestones:
  - `foundation-stable`
  - `act1-complete`
  - `act2-complete`
  - `act3-complete`
  - `act4-complete`
  - `release-candidate-1`
  - `v1.0.0`

## 3.2 Code-Structure Rules

- Keep new scripts below approximately 300 lines where feasible.
- Split large systems by responsibility rather than growing existing monolithic scripts.
- Prefer typed GDScript.
- Use `class_name` only for reusable domain classes.
- Avoid hard-coded node paths when a typed exported reference or unique-name node is safer.
- Do not duplicate audio, save, camera, or settings systems.
- Remove or archive obsolete systems after their replacement is verified.
- Do not leave TODOs, stubs, disabled code paths, fake implementations, or documentation-only completion.
- Every system must fail safely and report actionable errors.

## 3.3 AI-Assisted Execution Rules

For Codex or another coding agent:

1. Start a new implementation thread for every task ID in this plan.
2. Give the agent only the current task, relevant dependencies, repository path, and acceptance criteria.
3. Require it to inspect the existing implementation before editing.
4. Require exact changed-file lists.
5. Require commands and test output.
6. Require screenshots or logs for scene-level work when practical.
7. Reject any completion claim based only on documentation or file existence.
8. Close the thread when that task is verified.
9. Begin the next task in a new thread using a generated handoff file.
10. Store task handoffs in:
   - `docs/implementation/handoffs/`

Recommended handoff filename format:

```text
CCP-<PHASE>-<TASK>_HANDOFF.md
```

---

# 4. Target Project Structure

The completed project should move toward this structure:

```text
res://
├── assets/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── characters/
│   ├── environments/
│   ├── props/
│   ├── ui/
│   └── licenses/
├── autoload/
│   ├── game_manager.gd
│   ├── save_manager.gd
│   ├── audio_manager.gd
│   ├── settings_manager.gd
│   ├── scene_transition.gd
│   └── asset_registry.gd
├── components/
│   ├── combat/
│   ├── health/
│   ├── interaction/
│   └── movement/
├── enemies/
│   ├── shared/
│   ├── act_1/
│   ├── act_2/
│   ├── act_3/
│   └── act_4/
├── bosses/
├── player/
├── stages/
│   ├── act_1/
│   ├── act_2/
│   ├── act_3/
│   └── act_4/
├── systems/
│   ├── camera/
│   ├── hazards/
│   ├── platforms/
│   ├── progression/
│   └── accessibility/
├── ui/
│   ├── title/
│   ├── pause/
│   ├── settings/
│   ├── hud/
│   ├── results/
│   └── credits/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── campaign/
├── tools/
├── docs/
└── project.godot
```

This restructuring should be incremental. Do not move everything at once. Preserve valid resource paths or update references atomically.

---

# 5. Phase 0 — Baseline, Reproduction, and Audit Lock

## CCP-000 — Create a reproducible audit baseline

### Work

- Create the completion branch.
- Record the current commit SHA.
- Clone the repository into a clean directory with no local ignored assets.
- Open the project in the target Godot version.
- Capture all import, parser, preload, missing-resource, and autoload errors.
- Run every existing smoke-test script manually.
- Record which tests cannot start and why.
- Record current project launch behavior.
- Add:
  - `docs/audits/CLEAN_CLONE_BASELINE.md`
  - `docs/audits/KNOWN_FAILURES.md`
  - `docs/audits/FEATURE_MATRIX.md`

### Acceptance Criteria

- The report distinguishes confirmed working behavior from claimed behavior.
- Every current blocker has an exact file path and reproduction step.
- No implementation changes are mixed into this task.
- The baseline commit and Godot version are recorded.

---

## CCP-001 — Define the v1.0 feature contract

### Work

Create a locked feature matrix with these states:

- Not started
- Foundation only
- Implemented
- Verified
- Deferred after v1.0

At minimum, include:

- Player movement
- Combat
- Enemy behavior
- Bosses
- Stage-specific mechanics
- Checkpoints
- Save/load
- Menus
- Settings
- Controller support
- Accessibility
- Audio
- VFX
- Stage progression
- Ending
- Credits
- Export
- CI
- Performance
- Licensing

### Acceptance Criteria

- Every feature has an owner phase and verification method.
- No feature may be marked implemented solely because a file or class exists.
- The v1.0 definition is approved before major content work begins.

---

# 6. Phase 1 — Clean-Clone and Asset Recovery

This phase is the highest priority. No gameplay completion work should proceed until the repository can reproduce its intended runtime state.

## CCP-100 — Inventory every required runtime asset

### Work

Create a script that scans:

- `.tscn`
- `.tres`
- `.gd`
- `.json`
- `project.godot`

Extract every `res://` dependency and classify each path as:

- Present and tracked
- Present but ignored
- Missing
- Optional
- Editor-only
- Runtime-critical

Generate:

- `docs/assets/RUNTIME_ASSET_INVENTORY.md`
- `docs/assets/runtime_asset_inventory.json`

### Acceptance Criteria

- Every preload and external resource is represented.
- The report identifies which missing resources prevent startup.
- The scan can be rerun from the command line.

---

## CCP-101 — Choose and implement the runtime asset distribution strategy

### Recommended Strategy

Use Git LFS for redistributable runtime assets and keep original bulk source packs outside the game repository.

Track only assets actually used by the game:

- Final player sprite sheets
- Final enemy sprite sheets
- Final boss sprite sheets
- Final stage tilesets
- Final parallax layers
- Final props
- Final music tracks
- Final SFX
- License files

Do not commit entire unused asset packs.

### Work

- Create a normalized `assets/` runtime tree.
- Copy only required files into that tree.
- Configure `.gitattributes` for large binaries.
- Update `.gitignore` so final runtime assets are not excluded.
- Add a license manifest mapping every runtime asset to its license.
- Remove direct scene references to ignored `SourceArt` paths.

### Acceptance Criteria

- A fresh clone plus Git LFS checkout contains every required runtime resource.
- No game scene references an ignored runtime path.
- All asset licenses are documented.
- No unlicensed asset is included in the release tree.

---

## CCP-102 — Replace unsafe audio preloads

### Work

Consolidate `AudioManager.gd` and `SoundManager.gd` into one active audio system.

The completed audio manager must:

- Avoid startup-fatal preloads for optional audio
- Load streams through a verified manifest or safe runtime loader
- Provide procedural fallback SFX when licensed files are unavailable
- Support music and SFX buses
- Support independent volume settings
- Support mute
- Crossfade act and boss music
- Avoid restarting the same track unnecessarily
- Work in headless test mode
- Report missing audio without crashing

Remove or archive the unused duplicate manager after verification.

### Acceptance Criteria

- The project starts with all audio files present.
- The project also starts in a test fixture with audio files intentionally absent.
- Missing audio produces warnings, not parse failures.
- Music, boss music, SFX, volume controls, and mute work.
- Only one runtime audio manager remains.

---

## CCP-103 — Make all stage and character resources self-contained

### Work

- Repoint `SpriteFrames`, TileSets, stage props, parallax layers, and player sheets to tracked runtime paths.
- Eliminate direct dependencies on ignored `SourceArt`.
- Validate every `.tscn` and `.tres` with `ResourceLoader.exists`.
- Add fallback visuals only where a missing optional resource is acceptable.
- Do not use the Godot icon as a normal gameplay fallback in release builds.

### Acceptance Criteria

- All twenty stage scenes load from a clean clone.
- Every enemy scene displays its intended sprite frames.
- The player has all required animations.
- Tilemaps display and collide correctly.
- No release scene displays the Godot icon as substitute art.

---

## CCP-104 — Clean-clone startup gate

### Work

Add a headless clean-start validation script that:

- Imports the project
- Loads all autoloads
- Instantiates the main scene
- Instantiates every campaign stage
- Instantiates every enemy and boss
- Loads every required audio stream
- Reports unresolved dependencies

### Acceptance Criteria

- Command exits with code `0`.
- No parser, preload, import, missing-resource, or invalid UID errors occur.
- This command becomes the first CI job.

---

# 7. Phase 2 — Core Architecture Stabilization

## CCP-200 — Separate run state from configuration

### Work

Refactor `GameManager` so it does not become a permanent catch-all.

Recommended split:

- `RunState`
  - Health
  - Energy
  - Score
  - Current stage
  - Checkpoint
  - Collected pickups
  - Defeated bosses
- `CampaignProgress`
  - Unlocked acts
  - Completed stages
  - Best scores
  - Completion time
- `GameManager`
  - New game
  - Continue
  - Stage transition
  - Run reset
  - Campaign completion

### Acceptance Criteria

- State can be serialized without storing live nodes.
- Stage transitions preserve only intended data.
- Starting a new game fully clears prior run state.
- Continue restores a valid saved state.

---

## CCP-201 — Formalize stage metadata

### Work

Replace loosely interpreted manifest fields with a validated stage-data resource or schema.

Each stage needs:

- Stage ID
- Display name
- Act and substage
- Scene path
- Music ID
- Mechanics used
- Expected checkpoints
- Expected boss
- Completion target
- Camera bounds
- Par time
- Collectible count
- Encounter count
- Unlock dependencies

### Acceptance Criteria

- Invalid or duplicate stage IDs fail validation.
- Missing scene paths fail validation.
- Campaign order is deterministic.
- The final stage explicitly routes to campaign completion.

---

## CCP-202 — Build a reusable stage runtime controller

### Work

Create a `StageController` responsible for:

- Stage initialization
- Player spawn
- Camera bounds
- Music selection
- Checkpoint registration
- Encounter registration
- Stage completion state
- Exit locking
- Boss integration
- Restart and reload
- Debug stage information

### Acceptance Criteria

- No stage relies on arbitrary node searches for critical setup.
- The player always spawns at a valid location.
- Stage exits remain locked until completion conditions are met.
- Boss stages unlock only after boss defeat.
- Standard stages unlock after their required encounters or objectives.

---

## CCP-203 — Remove or clearly isolate prototypes

### Work

Classify these as either production or development-only:

- `PrototypeStage`
- Generated design guides
- Enemy catalog
- Builder tools
- Old `Level2`
- Old `LevelExit`
- Duplicate bullet scenes
- Duplicate sound manager
- Smoke-test-only stages

Move development-only scenes under `tools/` or `tests/fixtures/`.

### Acceptance Criteria

- No prototype guide appears in a release build.
- No production scene depends on a test fixture.
- Duplicate systems are removed or documented with a clear reason.
- The project tree communicates what is shippable.

---

# 8. Phase 3 — Player Controller and Combat Completion

## CCP-300 — Stabilize player state handling

### Work

Replace loosely coupled booleans and timers with a clear player state model.

Required states:

- Idle
- Run
- Jump
- Fall
- Wall slide
- Wall jump
- Dash
- Melee attack
- Shoot
- Hurt
- Dead
- Disabled/cutscene

Prevent incompatible actions during locked states.

### Acceptance Criteria

- The player cannot attack while dead.
- Dash cannot bypass required collision rules.
- Hurt and respawn cannot overlap incorrectly.
- Animation and physics state cannot disagree.
- State transitions are covered by tests.

---

## CCP-301 — Improve platforming feel

### Work

Add and tune:

- Coyote time
- Jump buffering
- Variable jump height
- Better acceleration and deceleration
- Air control
- Wall-jump lockout tuning
- Dash collision handling
- Landing feedback
- Controller deadzones
- Optional vibration
- Input buffering during animation recovery

### Acceptance Criteria

- Keyboard and controller produce consistent behavior.
- Jump input shortly before landing triggers on landing.
- Jump input shortly after leaving an edge still works.
- Dash never tunnels through world collision at target frame rates.
- Controls remain responsive at 30, 60, 120, and 144 FPS.

---

## CCP-302 — Complete melee combat

### Work

Implement:

- Ground melee combo
- Air melee
- Directional hit response
- Knockback
- Enemy hit-stun
- Attack cancel rules
- Hit confirmation
- Per-attack damage data
- Optional charged strike or finisher
- Clear attack animations

### Acceptance Criteria

- Melee attacks have distinct startup, active, and recovery windows.
- Damage occurs only during active frames.
- One swing cannot damage the same target repeatedly unless designed to.
- Hit reactions do not permanently lock enemies.
- Melee works against all regular enemies and bosses.

---

## CCP-303 — Complete ranged combat

### Work

Implement:

- Reliable projectile spawn
- World collision
- Enemy collision
- Projectile lifetime
- Fire-rate limits
- Energy costs
- Muzzle feedback
- Optional upgrade tiers
- Boss interaction
- Projectile pooling if needed

### Acceptance Criteria

- Projectiles cannot pass through walls.
- Off-screen projectiles are cleaned up.
- Shooting cannot create unbounded nodes.
- Energy and HUD values stay synchronized.
- The weapon behaves consistently at different frame rates.

---

## CCP-304 — Player progression and upgrades

### Recommended v1.0 Scope

Use a compact upgrade system rather than a large skill tree.

Possible permanent campaign upgrades:

- Maximum health
- Maximum energy
- Faster energy regeneration
- Stronger melee
- Stronger ranged attack
- Longer dash
- Reduced dash cost

### Work

- Define upgrade data resources.
- Decide where upgrades are awarded.
- Persist upgrades in save data.
- Show acquired upgrades in HUD or pause menu.
- Balance progression across four acts.

### Acceptance Criteria

- Every upgrade produces a measurable gameplay change.
- Upgrades survive save/load.
- New game resets them.
- No upgrade breaks boss or hazard logic.

---

# 9. Phase 4 — Enemy System Completion

## CCP-400 — Repair campaign enemy detection wiring

### Work

Add `DetectionArea` and collision configuration to every production enemy scene.

Create an automated scene builder or reusable inherited enemy base so all enemies include:

- Body collision
- Hurtbox
- Contact hitbox
- Detection area
- Floor detection
- Wall detection
- Sprite
- Light/VFX anchor

### Acceptance Criteria

- Every campaign enemy can detect the player.
- Entering range produces chase behavior.
- Leaving range returns to patrol or idle.
- Tests instantiate actual campaign enemy scenes, not only a fallback fixture.

---

## CCP-401 — Create enemy behavior archetypes

The twenty-two enemy skins must not all be the same patrol enemy.

Required archetypes:

1. Ground chaser
2. Fast melee attacker
3. Heavy armored enemy
4. Ranged shooter
5. Flying patrol
6. Flying shooter
7. Leaping enemy
8. Shielded enemy
9. Ambush enemy
10. Hazard-spawning enemy

Map each existing enemy asset to an archetype.

### Acceptance Criteria

- Every enemy has a declared archetype.
- Each act uses at least three behavior types.
- Visual size and hitboxes match the sprite.
- Ranged and flying enemies do not use invalid ground logic.
- Enemy attacks are telegraphed.

---

## CCP-402 — Add enemy attack states

### Work

Expand enemy state logic to include:

- Telegraph
- Attack
- Recovery
- Hurt
- Stunned
- Dead

Use behavior-specific attack controllers rather than placing all logic into `EnemyBase.gd`.

### Acceptance Criteria

- Enemies stop or reposition appropriately before attacks.
- Attack hitboxes activate only during intended frames.
- Enemies cannot damage indefinitely through inactive contact areas.
- Hurt and death interrupt attacks safely.

---

## CCP-403 — Enemy encounter controller

### Work

Create encounter volumes that:

- Activate a defined group of enemies
- Lock exits or arena boundaries
- Track enemy completion
- Unlock progression when all required enemies are defeated
- Optionally spawn reinforcement groups
- Reset correctly on player death

### Acceptance Criteria

- Every standard stage has multiple authored encounters.
- Players cannot bypass mandatory encounters by walking past inactive enemies.
- Encounter state resets reliably after death.
- Encounter completion survives checkpoint activation only when intended.

---

## CCP-404 — Enemy balance pass

### Work

Define per-act balance targets for:

- Health
- Damage
- Speed
- Attack frequency
- Detection distance
- Score
- Knockback resistance
- Spawn combinations

### Acceptance Criteria

- No standard enemy is a damage sponge.
- Early enemies teach mechanics before harder combinations appear.
- Later acts increase complexity, not only health.
- Enemy combinations remain fair in narrow spaces.

---

# 10. Phase 5 — Shared Stage Mechanics

## CCP-500 — Dynamic camera bounds

### Work

Replace the hard-coded camera limit with stage-provided bounds.

Support:

- Full-stage horizontal bounds
- Vertical rooms
- Boss arenas
- Camera zones
- Look-ahead
- Smooth transitions
- Respawn repositioning
- Optional room locks

### Acceptance Criteria

- Every 4,800-pixel stage remains camera-followed to its exit.
- The camera never exposes outside-stage void unintentionally.
- Boss arenas can temporarily override normal bounds.
- Camera tests verify the start, midpoint, and exit of every stage.

---

## CCP-501 — Moving platform system

### Work

Create reusable moving platforms with:

- Linear paths
- Ping-pong motion
- Looping paths
- Wait times
- Passenger carrying
- Activation triggers
- Speed configuration

### Acceptance Criteria

- The player remains stable while standing on a platform.
- Platforms do not push the player through walls.
- Movement remains deterministic after checkpoint reload.
- Controller and keyboard movement behave identically on platforms.

---

## CCP-502 — Conveyor system

### Work

Create:

- Ground conveyors
- Reversible conveyors
- Timed conveyors
- Hazard conveyors
- Conveyor visuals and audio

### Acceptance Criteria

- Conveyors affect player and enemy velocity predictably.
- Direction is visually readable.
- Conveyor behavior is frame-rate independent.
- Act 2 uses conveyors in traversal and combat.

---

## CCP-503 — Hazard framework

Create a reusable hazard base supporting:

- Damage
- Instant death
- Knockback
- Timed activation
- Telegraph states
- Checkpoint reset
- Audio/VFX feedback

Required hazard implementations:

- Laser grid
- Steam vent
- Electrical floor
- Falling object
- Crusher
- Toxic pool
- Void pit

### Acceptance Criteria

- Hazards clearly telegraph active and inactive states.
- Damage respects invulnerability rules where appropriate.
- Instant-death hazards respawn correctly.
- Every hazard can be tested independently.

---

## CCP-504 — Low-gravity and gravity-zone system

### Work

Implement zone-based gravity modifiers for Act 3:

- Low gravity
- High gravity
- Temporary zero-gravity chamber
- Visual transition
- Player and compatible enemy effects
- Safe restoration on exit or death

### Acceptance Criteria

- Gravity returns to normal after leaving a zone.
- Respawning cannot retain an old zone modifier.
- Jump, dash, wall slide, and projectiles remain valid.
- Act 3 uses gravity changes as a core mechanic.

---

## CCP-505 — Turret and security system

### Work

Create:

- Stationary tracking turret
- Burst-fire turret
- Rotating laser turret
- Destructible and indestructible variants
- Activation terminals
- Clear aiming telegraphs

### Acceptance Criteria

- Turrets respect line of sight.
- Shots collide with the world.
- Disabled turrets remain disabled when required by checkpoint state.
- Act 3 security stages use them meaningfully.

---

## CCP-506 — Interactive terminals and gates

### Work

Build a generic interaction system for:

- Switches
- Terminals
- Locked gates
- Timed doors
- Multi-switch puzzles
- Optional lore terminals

### Acceptance Criteria

- Interaction prompts support keyboard and controller.
- Gate state is deterministic after death and reload.
- Mandatory interactions cannot become permanently unsolvable.
- Puzzle state is saveable where needed.

---

# 11. Phase 6 — Act 1 Completion: Cyber City

## Act 1 Design Goal

Teach the core movement and combat systems in a readable neon-city environment.

Primary mechanics:

- Basic platforming
- Wall jumping
- Dash gaps
- Billboards and moving signs
- Basic enemy encounters
- Simple moving platforms
- Introductory boss

## CCP-610 — Stage 1-1: Rooftop Alley

### Required Content

- Proper tutorial prompts
- Movement introduction
- Jump and wall-jump teaching
- One melee encounter
- One ranged encounter
- One checkpoint
- Optional collectible route
- Exit to 1-2
- Camera bounds fixed

### Completion Gate

A first-time player can learn the controls without external instructions.

---

## CCP-611 — Stage 1-2: Billboard Highway

### Required Content

- Moving billboard platforms
- Timed electrical signs
- Two authored enemy encounters
- One optional high-route collectible path
- Two checkpoints
- Remove prototype design-guide content

### Completion Gate

The stage is visually and mechanically different from 1-1.

---

## CCP-612 — Stage 1-3: Communication Spire

### Required Content

- Vertical platforming
- Wall-jump shafts
- Rotating signal hazards
- Flying enemies
- Mid-stage checkpoint
- Camera zones for vertical sections

### Completion Gate

The level can be completed without camera lock or off-screen traversal.

---

## CCP-613 — Stage 1-4: Skybridge Junction

### Required Content

- Moving bridges
- Breakable or timed bridge segments
- Combined ground and flying encounters
- Dash challenge
- Pre-boss difficulty ramp

### Completion Gate

The stage tests all Act 1 skills without unfair blind hazards.

---

## CCP-614 — Stage 1-5: Executive Helipad

### Boss: Helix Warden

Required distinction:

- Air-focused movement
- Projectile arcs
- Dash pass
- Summoned hazard zones
- Three readable phases
- Intro, defeat, and exit sequence

### Completion Gate

Defeating the boss unlocks Act 2 and creates a save checkpoint.

---

# 12. Phase 7 — Act 2 Completion: Robot Factory

## Act 2 Design Goal

Develop movement timing through industrial machinery and introduce environmental hazards that affect combat space.

Primary mechanics:

- Conveyors
- Crushers
- Steam vents
- Moving machinery
- Drop hazards
- Heavy enemies

## CCP-710 — Stage 2-1: Sub-Level Intake

- Introduce conveyors safely
- Introduce armored enemy
- Teach steam timing
- One checkpoint
- Factory-specific music and visuals

## CCP-711 — Stage 2-2: Conveyor Assembly

- Reversible conveyors
- Conveyor combat arena
- Moving cargo platforms
- Falling-part hazards
- Multiple enemy waves

## CCP-712 — Stage 2-3: Smelting Core

- Heat zones
- Timed steam vents
- Lava/toxic floor
- Laser gates
- Vertical machinery route

## CCP-713 — Stage 2-4: Robotic Maintenance

- Crusher timing
- Broken machinery
- Alternate repair-terminal route
- Heavy and ranged enemy combinations
- Pre-boss checkpoint

## CCP-714 — Stage 2-5: Assembly Engine

### Boss: Assembly Colossus

Required distinction:

- Heavy ground boss
- Conveyor arena
- Slam and shockwave attacks
- Machinery activation phase
- Vulnerability windows
- Three distinct phases

### Completion Gate

Defeating the boss unlocks Act 3 and stores progress.

---

# 13. Phase 8 — Act 3 Completion: Neon Moon Protocol

## Act 3 Design Goal

Change traversal physics and introduce security-system puzzles.

Primary mechanics:

- Low gravity
- Gravity transitions
- Turrets
- Laser grids
- Security terminals
- Flying combat

## CCP-810 — Stage 3-1: Lunar Surface Arrival

- Teach low-gravity movement
- Long-gap traversal
- Low-gravity enemy behavior
- Safe gravity restoration
- One checkpoint

## CCP-811 — Stage 3-2: Research Cleanrooms

- Security doors
- Terminal puzzles
- Clean-room laser cycles
- Ranged enemy encounters
- Optional lore terminal

## CCP-812 — Stage 3-3: Security Grid Shaft

- Vertical shaft
- Turrets
- Rotating laser grids
- Wall-jump and low-gravity combinations
- Camera-zone transitions

## CCP-813 — Stage 3-4: Bio-Tech Labs

- Gravity switching
- Containment hazards
- Ambush enemies
- Multi-switch route
- Pre-boss checkpoint

## CCP-814 — Stage 3-5: Orbital Command

### Boss: Lunar Oracle

Required distinction:

- Teleport or reposition behavior
- Gravity inversion events
- Projectile patterns
- Laser sweep
- Arena hazards
- Three distinct phases

### Completion Gate

Defeating the boss unlocks Act 4 and stores progress.

---

# 14. Phase 9 — Act 4 Completion: Abyssal Night

## Act 4 Design Goal

Combine all prior mechanics under higher pressure while introducing corruption and void hazards.

Primary mechanics:

- Floating platforms
- Void pits
- Corruption zones
- Mixed gravity
- Hazard combinations
- Elite enemies

## CCP-910 — Stage 4-1: Corrupted Outpost

- Reintroduce previous mechanics at higher difficulty
- Corruption damage zones
- Elite enemy variants
- One checkpoint

## CCP-911 — Stage 4-2: The Dark Chasm

- Floating moving platforms
- Void pits
- Limited-visibility sections
- Dash and wall-jump mastery
- Mid-stage checkpoint

## CCP-912 — Stage 4-3: Bio-Mechanical Nest

- Organic moving hazards
- Enemy ambush nests
- Breakable corruption nodes
- Route unlock after node destruction

## CCP-913 — Stage 4-4: Abyssal Sanctuary

- Final mastery stage
- Mixed conveyors, lasers, gravity, and moving platforms
- Elite encounter sequence
- Final pre-boss checkpoint

## CCP-914 — Stage 4-5: Heart of the Void

### Boss: Void Cerberus

Required distinction:

- Multi-part or multi-head attack logic
- Arena corruption
- Dash attacks
- Projectile spread
- Laser or breath sweep
- Final desperation phase
- No reuse of the exact same phase script as prior bosses
- Completion cinematic

### Completion Gate

Defeating the boss triggers the ending flow exactly once.

---

# 15. Phase 10 — Boss Framework Refactor

## CCP-1000 — Replace one-size-fits-all boss behavior

### Work

Split boss behavior into composable attacks:

- Projectile volley
- Dash
- Slam
- Shockwave
- Laser sweep
- Summon
- Teleport
- Arena hazard
- Gravity event
- Vulnerability window

Each boss should have a dedicated controller selecting attacks and phases.

### Acceptance Criteria

- Each boss has a unique attack roster.
- Boss phases are data-driven or explicitly authored.
- Bosses do not all follow projectile → dash → laser.
- Boss tests verify phase thresholds and defeat.

---

## CCP-1001 — Boss presentation

### Work

Add:

- Intro lock
- Boss title
- Health-bar reveal
- Arena camera
- Music transition
- Phase-change feedback
- Defeat sequence
- Exit unlock
- Checkpoint or save after victory

### Acceptance Criteria

- The player cannot leave before the encounter resolves.
- Death and retry restart the boss cleanly.
- Boss projectiles and hazards are removed on defeat or restart.
- Music returns to the correct state after the fight.

---

# 16. Phase 11 — Game Shell, Save System, and Accessibility

## CCP-1100 — Title screen

Required options:

- New Game
- Continue
- Stage Select after campaign completion
- Settings
- Credits
- Quit

### Acceptance Criteria

- Continue is disabled when no valid save exists.
- New Game asks before overwriting an existing run.
- Controller focus works from startup.

---

## CCP-1101 — Save/load system

### Save Data

- Version
- Current act and stage
- Current checkpoint
- Completed stages
- Defeated bosses
- Player upgrades
- Collectibles
- Best scores
- Settings
- Campaign completion
- Total play time

### Requirements

- Atomic save writes
- Backup save
- Corruption detection
- Migration support
- Manual debug reset
- No live-node serialization

### Acceptance Criteria

- Save survives closing and reopening the game.
- A corrupted primary save can recover from backup.
- Old save versions migrate or fail with a clear message.
- Save tests run headlessly.

---

## CCP-1102 — Pause menu

Required options:

- Resume
- Restart checkpoint
- Restart stage
- Settings
- Return to title

### Acceptance Criteria

- Gameplay pauses consistently.
- Audio pause behavior is intentional.
- Controller focus cannot escape the menu.
- Returning to title does not preserve unintended live state.

---

## CCP-1103 — Settings

Required settings:

- Master volume
- Music volume
- SFX volume
- Fullscreen/windowed
- Resolution
- VSync
- Screen shake intensity
- Controller vibration
- Input remapping
- Text speed if dialogue exists

### Acceptance Criteria

- Settings save independently from campaign progress.
- Settings apply without restarting when possible.
- Invalid display modes safely revert.

---

## CCP-1104 — Accessibility baseline

Required:

- Reduced screen shake
- Disable flashing effects
- High-contrast interactable indicators
- Rebindable controls
- Adjustable controller deadzone
- Hold/toggle options where appropriate
- Subtitles or text equivalents for critical audio cues
- Legible UI scaling

### Acceptance Criteria

- Accessibility settings persist.
- Critical progression does not depend only on color.
- Critical hazards do not depend only on sound.

---

## CCP-1105 — Ending and credits

### Work

Create:

- Final boss defeat transition
- Ending scene
- Final score and completion time
- Collectible summary
- Credits
- Return to title
- Campaign-complete save flag
- Unlock stage select

### Acceptance Criteria

- Completion cannot trigger repeatedly.
- Final results display accurate saved values.
- Returning to title leaves the game in a valid state.
- Continue after completion behaves intentionally.

---

# 17. Phase 12 — UI, Audio, VFX, and Presentation Polish

## CCP-1200 — HUD cleanup

Required HUD elements:

- Health
- Energy
- Score
- Upgrade indicators
- Checkpoint notice
- Boss health
- Interaction prompt
- Optional objective text

### Acceptance Criteria

- HUD scales at supported resolutions.
- HUD never overlaps critical action areas excessively.
- Boss UI binds to the correct boss.
- All values update through signals.

---

## CCP-1201 — Combat feedback

Add:

- Hit sparks
- Enemy hurt flash
- Impact freeze
- Camera shake scaling
- Controller vibration
- Damage numbers only if they suit the visual style
- Distinct boss feedback
- Low-health indication

### Acceptance Criteria

- Feedback is readable but not excessive.
- Reduced-effects settings disable or scale applicable effects.
- Effects do not leak nodes.

---

## CCP-1202 — Environmental presentation

For every act:

- Final parallax setup
- Lighting palette
- Ambient VFX
- Environmental animation
- Foreground framing
- Hazard visual language
- Background variety across stages

### Acceptance Criteria

- Adjacent stages are visually distinguishable.
- Important collision remains readable.
- Foreground effects do not obscure hazards.

---

## CCP-1203 — Audio pass

Required:

- Unique act music
- Unique boss tracks
- Movement sounds
- Combat sounds
- UI sounds
- Hazard sounds
- Checkpoint sound
- Stage-clear sound
- Ending audio

### Acceptance Criteria

- No missing streams.
- No clipping.
- Repeated SFX use pooling.
- Music transitions do not restart unnecessarily.
- License attribution is complete.

---

# 18. Phase 13 — Testing and Continuous Integration

## CCP-1300 — Establish command-line test entrypoints

Create documented commands for:

- Import validation
- Script parse validation
- Resource dependency validation
- Unit tests
- Systems smoke tests
- Campaign scene loading
- Full campaign transition test
- Save/load test
- Export test

### Acceptance Criteria

- Every command returns meaningful exit codes.
- Tests can run without opening the editor UI.
- Failure output identifies the scene or system involved.

---

## CCP-1301 — Repair test coverage gaps

Add tests for:

- Actual campaign enemy detection
- Camera at stage start, midpoint, and exit
- Every stage exit path
- Every checkpoint
- Every boss phase
- Boss retry
- Final campaign completion
- Missing audio fallback
- Save corruption recovery
- Settings persistence
- Player state transitions
- Hazard reset after death
- Controller actions present in InputMap

### Acceptance Criteria

- Tests use production scenes whenever possible.
- Test fixtures cannot hide production wiring defects.
- Critical regressions fail CI.

---

## CCP-1302 — GitHub Actions

Recommended jobs:

1. `godot-import`
2. `resource-validation`
3. `unit-tests`
4. `systems-smoke`
5. `campaign-smoke`
6. `windows-export`

### Acceptance Criteria

- Workflows run on pull requests and pushes to `main`.
- Failed critical jobs block merge.
- Artifacts include test logs.
- Export job uploads a temporary Windows build.

---

## CCP-1303 — Full campaign automated traversal harness

This does not need to play perfectly like a human. It must prove scene connectivity.

Validate:

- Start new game
- Load 1-1
- Trigger or bypass each completion condition in test mode
- Transition through all twenty stages
- Trigger each boss defeat in test mode
- Reach ending
- Return to title

### Acceptance Criteria

- All twenty stage IDs are visited in order.
- No invalid scene path occurs.
- Campaign completion fires once.
- The test starts from a clean run state.

---

# 19. Phase 14 — Performance, Export, and Release

## CCP-1400 — Performance budget

Target:

- 60 FPS at 1080p on a modest Windows gaming PC
- Stable frame pacing
- Bounded projectiles, VFX, and audio players
- No large runtime resource scans during gameplay

### Work

Profile:

- Stage loading
- Enemy count
- Particle count
- Parallax overdraw
- Dynamic lights
- Audio pools
- Resource registry recursion
- Save writes

### Acceptance Criteria

- No recurring gameplay frame spike above the agreed threshold.
- Asset registry does not recursively search large folders during active play.
- VFX and projectile counts remain bounded.
- Stage transitions release old scene resources.

---

## CCP-1401 — Windows export configuration

### Work

Add `export_presets.cfg` with:

- Windows Desktop target
- Correct executable name
- Version metadata
- Product icon
- Release build settings
- Included resource filters
- Excluded editor/test content

### Acceptance Criteria

- Export succeeds from command line.
- Build starts on a clean Windows machine.
- No development guide, test fixture, or builder tool appears in release.
- Save files are written to the correct user directory.

---

## CCP-1402 — Release packaging

Create:

- Executable
- Data package
- README
- Controls guide
- License/attribution file
- Changelog
- Known-issues file
- Version file

### Acceptance Criteria

- Package can be extracted and run.
- No absolute developer-machine paths remain.
- Licenses cover every shipped third-party asset and plugin.
- Release SHA is recorded.

---

## CCP-1403 — Release candidate test pass

Run the full manual matrix:

### Input

- Keyboard
- Xbox-compatible controller
- Controller disconnect/reconnect
- Remapped controls

### Display

- Windowed
- Fullscreen
- 720p
- 1080p
- Ultrawide behavior where supported

### Progression

- New game
- Continue
- All checkpoints
- All stages
- All bosses
- Ending
- Credits
- Stage select unlock

### Failure Recovery

- Death during encounter
- Death during boss
- Quit during stage
- Quit after checkpoint
- Corrupt save
- Missing controller
- Audio device change where practical

### Acceptance Criteria

- No critical or high-severity issue remains.
- Medium issues are either fixed or documented and approved.
- The final clean-machine test passes.

---

# 20. Stage Definition of Done

A stage is not complete merely because its scene loads.

Every standard stage must have:

- Valid tracked assets
- Valid terrain collision
- Correct player spawn
- Correct camera bounds
- At least two authored traversal sections
- At least two authored combat encounters
- At least one stage-specific mechanic
- At least one checkpoint
- Functional death zone
- Functional exit
- Correct next-stage path
- Music
- Ambient presentation
- Optional collectible route
- No prototype labels
- No missing resources
- Passed stage smoke test
- Passed manual start-to-exit playtest

Every boss stage must additionally have:

- Arena bounds
- Intro sequence
- Locked exit
- Boss HUD
- Unique boss attacks
- Three meaningful phases
- Retry behavior
- Defeat sequence
- Exit unlock
- Post-boss save
- No lingering boss projectiles or hazards

---

# 21. Task Completion Evidence

Every task completion report must include:

```text
Task ID:
Branch:
Commit:
Files changed:
Files added:
Files removed:
Commands run:
Test results:
Manual verification:
Known limitations:
Next dependency:
```

A task must not be marked complete when:

- Only documentation was changed for an implementation task
- Tests were not run
- Tests failed
- The implementation requires ignored local files
- The feature works only in a test fixture
- The production scene was not verified
- The agent states that something “should work” without evidence
- Acceptance criteria remain unchecked

---

# 22. Recommended Implementation Order

Execute in this order:

1. CCP-000 through CCP-104  
   Clean clone and assets
2. CCP-200 through CCP-203  
   Architecture stabilization
3. CCP-500  
   Camera repair
4. CCP-400 through CCP-404  
   Enemy production wiring
5. CCP-300 through CCP-304  
   Player and combat completion
6. CCP-501 through CCP-506  
   Shared stage mechanics
7. CCP-610 through CCP-614  
   Act 1
8. CCP-710 through CCP-714  
   Act 2
9. CCP-810 through CCP-814  
   Act 3
10. CCP-910 through CCP-914  
    Act 4
11. CCP-1000 through CCP-1001  
    Boss distinction and presentation
12. CCP-1100 through CCP-1105  
    Game shell, saves, ending
13. CCP-1200 through CCP-1203  
    Presentation polish
14. CCP-1300 through CCP-1303  
    CI and regression coverage
15. CCP-1400 through CCP-1403  
    Performance, export, release

Do not begin mass stage polishing before clean-clone startup, camera, and production enemy wiring are fixed. Otherwise, level work will be built on a broken foundation.

---

# 23. Milestones

## Milestone A — Reproducible Foundation

Complete when:

- Clean clone starts
- Required assets are tracked
- Audio no longer crashes startup
- All scenes load
- CI import validation passes

## Milestone B — Production Core

Complete when:

- Camera supports full stages
- Player controller is stable
- Campaign enemies detect and attack
- Encounters reset
- Shared stage mechanics exist

## Milestone C — Act 1 Vertical Slice

Complete when:

- Act 1 is fully playable
- Boss is distinct
- Save/load works through Act 1 completion
- Windows development export works

This milestone should be treated as the quality bar for Acts 2–4.

## Milestone D — Full Campaign Alpha

Complete when:

- All twenty stages are traversable
- All bosses are defeatable
- Ending can be reached
- Major systems are present

## Milestone E — Beta

Complete when:

- Menus, settings, accessibility, save recovery, and credits work
- All automated tests pass
- No critical or high-severity defects remain

## Milestone F — Version 1.0

Complete when:

- Release candidate passes the full manual matrix
- Clean-machine Windows build works
- Licenses and packaging are complete
- `v1.0.0` is tagged and released

---

# 24. Final Release Definition of Done

The project is ready for `v1.0.0` only when:

- [ ] Clean clone imports without error
- [ ] Clean clone launches without error
- [ ] All required runtime assets are tracked or reproducibly installed
- [ ] All twenty stages can be completed
- [ ] Every stage camera reaches its exit
- [ ] Every campaign enemy has functional detection and attacks
- [ ] Every act has its promised unique mechanics
- [ ] All four bosses are distinct and verified
- [ ] Save/load works
- [ ] Pause works
- [ ] Settings work
- [ ] Keyboard works
- [ ] Controller works
- [ ] Accessibility baseline works
- [ ] Ending and credits work
- [ ] All automated tests pass
- [ ] CI passes on the release commit
- [ ] Windows export succeeds
- [ ] Clean-machine launch succeeds
- [ ] License attribution is complete
- [ ] No critical or high-severity bugs remain
- [ ] Documentation matches the shipped game

---

## Immediate Next Task

Begin with **CCP-000: Create a reproducible audit baseline**, followed by **CCP-100: Inventory every required runtime asset**.

Do not start by polishing levels. The repository must first become self-contained, bootable, and verifiable.
