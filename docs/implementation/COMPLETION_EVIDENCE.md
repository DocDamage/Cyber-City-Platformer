# Full-completion implementation evidence

This document maps the completion plan to committed production evidence. Commands are also consolidated in `docs/TESTING.md`.

## Foundation and production core

- Clean-clone asset tracking: 182 curated binaries, five license texts, Git LFS, zero runtime-critical inventory blockers.
- State architecture: validated 20-stage campaign schema, independent run and campaign-progress models, deterministic final route.
- Player: 12 explicit states, coyote/buffer/variable jump, wall movement, dash, melee phases/combo, ranged energy/cooldown/lifetime, and upgrades.
- Enemies/mechanics: 22 scenes across 10 attack archetypes; resettable encounters; moving, breakaway, conveyor, hazard, gravity, turret, terminal, and gate systems.
- Camera: stage-provided horizontal/vertical bounds, look-ahead, smoothing, clamping, and settings-scaled shake.

## Campaign and bosses

- All 20 layouts use production `CampaignStage`; prototype guides/builders are isolated from runtime exports.
- Each standard stage has production encounters, checkpoints/objectives, collectibles, mechanics, camera bounds, and a connected exit.
- Helix Warden, Assembly Colossus, Lunar Oracle, and Void Cerberus use distinct scripts, rosters, patterns, phases, hazards, rewards, retry cleanup, and exit gates.
- Automated traversal visits `1-1` through `4-5` in order, fires completion once, reaches ending, and returns to title.

## Shell, persistence, and accessibility

- Title: New Game with overwrite confirmation, Continue, Stage Select, Settings, Credits, and Quit.
- Pause: resume, checkpoint restart, stage restart, settings, and title routes.
- Atomic versioned saves use a checksum, temporary file, primary/backup rotation, recovery, migration, and reset.
- Settings persist separately and apply volume, display, VSync, shake, vibration, deadzone, reduced flashing, contrast, hold interaction, UI scale, and persistent family-preserving remaps.
- HUD exposes health, energy, score, objectives, upgrades, boss state, interaction prompts, and non-color hazard cues.

## Verification and release engineering

- The headless runner executes 16 isolated import/resource/unit/system/campaign/shell processes with per-test logs and timeouts.
- The performance gate indexes 182 assets without gameplay recursion, fixes audio at 10 SFX/2 BGM players, releases 64 projectiles/32 VFX, and verifies stage release.
- GitHub Actions defines import, resource, unit, systems/shell, campaign, and Windows-export jobs using official Godot 4.7.1 artifacts and Git LFS.
- The Windows preset excludes tests, builders, editor plugin, completion plan, local source mirrors, and developer-only manifests.
- The release tool rejects forbidden PCK markers/machine paths/dirty release trees, packages all required files and licenses, and records source/artifact hashes.
- A freshly extracted `1.0.0-rc.1` package launched headlessly with exit code 0 on 2026-08-04.

`docs/RELEASE_CHECKLIST.md` deliberately keeps physical input/display/performance observations and the remote green CI run separate. Those gates cannot be truthfully replaced by headless automation.
