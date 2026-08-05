# Failure audit

The baseline at commit `380d88d5e181924aa0cf42fdde550af1a0e8479a` recorded five critical, seven high, and four medium reproducible failures. No critical or high item remains open after the production implementation and automated regression pass.

| Baseline area | Resolution evidence |
|---|---|
| Audio and VFX autoload failures | Curated tracked resources, safe fallback loading, clean-clone gate, and missing-audio injection test. |
| Main scene, terrain, campaign art | Title startup plus 182 Git-LFS runtime assets; all 20 stages and 22 enemies instantiate in a clean clone. |
| Reproducibility and broken smoke tests | Runtime inventory has zero critical blockers; one isolated cross-platform runner executes every gate. |
| Camera, enemy behavior, progression | Per-stage bounds, 10 attack archetypes, resettable encounters, and deterministic 20-stage traversal tests. |
| Missing shell and save recovery | Title/pause/settings/stage-select/ending/credits scenes plus versioned atomic primary/backup saves. |
| Coupled/prototype/duplicate systems | Run/campaign state models, production `CampaignStage` scenes, tools isolated under `tools/`, and one AudioManager. |
| Export and CI absent | Pinned Windows preset, validated archive tool, extracted-build launch, and six-job GitHub Actions workflow. |

Remaining unchecked items in `docs/RELEASE_CHECKLIST.md` are hardware/manual observations and a remote CI run, not known software failures. If any observation reproduces a defect, add its severity, exact location, reproduction, and observed result here before release promotion.
