# Production delivery summary

**Delivery date:** 2026-08-05
**Engine:** Godot `4.7.1.stable.official.a13da4feb`
**Branch:** `feature/full-game-completion`

## What is delivered

Cyber City Platformer now ships two coherent ways to play the same four-act story:

- A connected 202-room metroidvania spanning twenty districts in Cyber City, Mega Robot Factory, Neon Moon Protocol, and Abyssal Night. It includes character creation, six starting weapon families, phase-marker teleportation, seven progression abilities, persistent shortcuts/caches/warps, four regional bosses, four quests, a personalized ending, and post-game exploration.
- A validated twenty-stage legacy campaign. Every stage has authored content, deterministic progression, checkpoints, hazards, encounters, bosses or objective exits, and persistent handoffs.

The visual/traversal pass covers all four legacy acts. Cyber City and Robot Factory use seven bespoke 1672×941 hero panoramas and collision-bound industrial/city structures. Neon Moon Protocol and Abyssal Night use ten additional bespoke 1672×941 hero panoramas, independent atmospheric layer tints, lunar/abyssal support structures, and regional traversal assemblies rather than reusing earlier-act architecture.

## Verification snapshot

The strict isolated headless suite contains 36 commands across import, resource, unit, systems, campaign, world, and shell groups. The two campaign presentation gates cover:

- Acts 1–2: ten stages, real movement/jumps, eighteen physical traversal landings, seventy deck surfaces, forty-one reachable route links, seven panoramas, objectives, bosses, handoffs, and persistence.
- Acts 3–4: ten stages, real movement/jumps, checkpoint/collectible/encounter/boss/ending flow, ten panoramas, forty-three traversal decks, and twenty-eight regional assemblies.

The latest performance-gate reference loaded all 202 rooms with a 11.41 ms peak room build (99 nodes), 306.82 ms representative transition, 7.52/8.54 ms map/inventory opens, 8.65 ms peak save, and 231.3 MiB three-room observation (+2.7 MiB delta). These are deterministic regression metrics, not a substitute for target-hardware GPU capture.

## Asset and release truth

The runtime manifest contains 314 curated binaries under five included license texts. It records stable provenance and SHA-256 for seventeen project-authored AI-assisted panoramas and twelve project-authored traversal-kit assets. See the generated-asset records in `docs/assets/`.

All local automated implementation gates are green. This delivery is not represented as a final `v1.0.0` release: remaining release observations are physical controller and full-route playthroughs, target-hardware display/accessibility/audio/GPU checks, remote CI, a clean-clone export/package rerun, and an independent clean-machine launch. Those conditions are tracked in `docs/RELEASE_CHECKLIST.md` and `KNOWN_ISSUES.md`.

## Source-of-truth references

- `docs/implementation/COMPLETION_EVIDENCE.md` — detailed implementation evidence.
- `docs/TESTING.md` — repeatable local and packaged validation.
- `docs/PERFORMANCE.md` — budgets and latest deterministic measurements.
- `docs/audits/PLAN_COMPLIANCE_AUDIT.md` — plan crosswalk and manual-gate truth.
- `docs/design/ACT3_ACT4_PLATFORMING_LANGUAGE.md` — later-act visual/traversal language.
- `docs/narrative/PRODUCTION_BIBLE.md` — story, quest, and localization rules.
