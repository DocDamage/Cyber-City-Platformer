# Failure audit

The baseline at commit `380d88d5e181924aa0cf42fdde550af1a0e8479a` recorded five critical, seven high, and four medium reproducible failures. No critical or high item remains open after the production implementation and automated regression pass.

| Baseline area | Resolution evidence |
|---|---|
| Audio and VFX autoload failures | Curated tracked resources, safe fallback loading, clean-clone gate, and missing-audio injection test. |
| Main scene, terrain, campaign art | Local title startup plus 314 Git-LFS-managed runtime assets; all 20 stages and 22 enemies instantiate, including seventeen stage-specific hero panoramas and later-act regional assemblies. |
| Reproducibility and broken smoke tests | The inventory/report tooling and one isolated cross-platform runner execute every gate; fresh-clone confirmation remains a release-promotion gate. |
| Camera, enemy behavior, progression | Per-stage bounds, 10 attack archetypes, resettable encounters, and deterministic 20-stage traversal tests. |
| Missing shell and save recovery | Title/pause/settings/stage-select/ending/credits scenes plus versioned atomic primary/backup saves. |
| Coupled/prototype/duplicate systems | Run/campaign state models, production `CampaignStage` scenes, tools isolated under `tools/`, and one AudioManager. |
| Export and CI absent | Pinned Windows preset, validated archive tool, extracted-build launch, and six-job GitHub Actions workflow. |

The 2026-08-05 connected-world and four-act campaign pass is locally green across 36 isolated processes, including all twenty sequential legacy stages. Acts 1–2 have seven distinct hero panoramas and real-renderer composition review; Acts 3–4 have ten distinct hero panoramas, 43 traversal decks, 28 regional assemblies, and a deterministic ending-flow gate. The delivery also validates 202 rooms, 103 unique expansion geometry/landmark contracts, the 162-room route for all six starting families, forty optional rooms with persistent cache coverage, fourteen weapon items, 22 complete enemy contracts, four streamed bosses, four persistent quests, seven real-geometry traversal probes, exact occupied-slot character reconstruction, and the personalized ending. No automated severity-1 or critical-path failure is currently known.

A subsequent real 1280×720 exported-build interaction pass reproduced and resolved four additional issues before release promotion: clipped Character Creator actions/live preview, duplicate world-space room titles beneath the HUD, tutorial/objective overlap, and cutscene progression that was not committed after the final endpoint. Viewport/scroll, room-HUD band, and disk-level cutscene autosave assertions now cover those regressions, and the complete suite remains green.

Release promotion is still blocked by the unchecked hardware/manual observations in `docs/RELEASE_CHECKLIST.md`, a remote CI run, a post-integration clean-clone/export rerun, and human full playthroughs. The delivery branch now includes the previously unintegrated production paths; the next distribution-state proof is a clean-clone dependency/export rerun, not a reproduced runtime defect. If any observation reproduces a defect, add its severity, exact location, reproduction, and observed result here before release promotion.
