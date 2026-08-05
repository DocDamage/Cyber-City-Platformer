# Changelog

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
