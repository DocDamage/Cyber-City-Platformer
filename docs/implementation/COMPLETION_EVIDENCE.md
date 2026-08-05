# Full-completion implementation evidence

This document maps the completion plan to committed production evidence. Commands are also consolidated in `docs/TESTING.md`.

## Foundation and production core

- Clean-clone asset tracking: 182 curated binaries, five license texts, Git LFS, zero runtime-critical inventory blockers.
- State architecture: validated 20-stage campaign schema, independent run and campaign-progress models, deterministic final route.
- Player: 12 explicit states, coyote/buffer/variable jump, wall movement, dash, melee phases/combo, ranged energy/cooldown/lifetime, and upgrades.
- Enemies/mechanics: 22 scenes across 10 attack archetypes; per-act live balance profiles; resettable multi-wave encounters; moving, breakaway, conveyor, hazard, gravity, camera/visibility, turret, terminal, switch, and gate systems.
- Camera: stage-provided horizontal/vertical bounds, look-ahead, smoothing, clamping, and settings-scaled shake.

## Campaign and bosses

- All 20 layouts use production `CampaignStage`; obsolete prototype guides/builders and duplicate preview/runtime scenes have been removed.
- Each standard stage has at least two explicitly authored traversal sections and two authored combat encounters, plus stage-specific mechanics, checkpoints/objectives, collectibles, camera bounds, ambient presentation, and a connected exit.
- Helix Warden, Assembly Colossus, Lunar Oracle, and Void Cerberus use distinct scripts, rosters, patterns, phases, hazards, rewards, retry cleanup, and exit gates.
- Automated traversal visits `1-1` through `4-5` in order, fires completion once, reaches ending, and returns to title.

## Shell, persistence, and accessibility

- Title: New Game with overwrite confirmation, Continue, Stage Select, Settings, Credits, and Quit.
- Pause: resume, checkpoint restart, stage restart, settings, and title routes.
- Atomic versioned saves use a checksum, temporary file, primary/backup rotation, recovery, migration, and reset.
- Settings persist separately and apply volume, display, VSync, shake, vibration, deadzone, reduced flashing, contrast, hold interaction, UI scale, and persistent family-preserving remaps.
- HUD exposes health, energy, score, objectives, upgrades, boss state, interaction prompts, and non-color hazard cues.

## Verification and release engineering

- The headless runner executes 18 isolated import/resource/unit/system/campaign/shell processes with per-test logs and timeouts. It treats Godot `ERROR:` and `SCRIPT ERROR:` output as failure even when the process exits zero.
- The performance gate indexes 182 assets without gameplay recursion, fixes audio at 10 SFX/2 BGM players, releases 64 projectiles/32 VFX, and verifies stage release.
- GitHub Actions defines import, resource, unit, systems/shell, campaign, and Windows-export jobs using official Godot 4.7.1 artifacts and Git LFS.
- The Windows preset excludes tests, builders, editor plugin, completion plan, local source mirrors, and developer-only manifests.
- The release tool rejects forbidden PCK markers/machine paths/dirty release trees, packages all required files and licenses, and records source/artifact hashes.
- Clean clone `2fa1ab023d3f18c8c9120774b29bbf2cf1c8aced` passed the 392-dependency inventory and all 18 strict tests on 2026-08-04. Its `1.0.0-rc.2` Windows export passed forbidden-content packaging, extracted successfully, and launched headlessly with no engine errors.

`docs/RELEASE_CHECKLIST.md` deliberately keeps physical input/display/performance observations and the remote green CI run separate. Those gates cannot be truthfully replaced by headless automation.
