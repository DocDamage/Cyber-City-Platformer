# Performance budget

The production target is 60 FPS at 1920×1080 on a modest 64-bit Windows gaming PC. The automated test is a regression bound, not a substitute for GPU frame-time capture on release hardware.

## Automated bounds

`tests/integration/PerformanceBudgetTest.gd` verifies:

- all 314 licensed runtime assets are present in the source-free index and all 286 AssetRegistry lookup-root paths are indexed (voice and equipment catalogs load their 28 assets directly);
- no recursive asset-registry scan method remains in gameplay code;
- audio stays at a fixed pool of ten SFX and two BGM players, with no more than 32 total runtime audio players;
- all 202 production rooms stream successfully, each stays below 650 nodes, and the slowest synchronous room build stays below 200 ms;
- representative cold cross-region fade/load transitions stay below 1.2 seconds;
- map and inventory opening each stay below 250 ms;
- two consecutive atomic save writes, including backup rotation, each stay below 250 ms;
- a connected current-plus-two-adjacent-room set stays below 512 MiB of Godot static memory;
- the layered player stays at or below ten render surfaces, used as the headless proxy for its draw-call budget;
- authored resident/wave enemy concurrency stays at or below twelve;
- the production Act 4 mastery stage remains under 2,000 scene nodes;
- 64 simultaneous projectiles and 32 simultaneous VFX all release by their bounded lifetimes;
- an unloaded production stage is no longer retained after transition cleanup;
- the complete expanded headless stress pass finishes within fifteen seconds.

The final 2026-08-05 Godot 4.7.1 reference run completed the performance body in 3.70 seconds while streaming all 202 rooms with the four-act backdrop/traversal pass, seventeen hero panoramas, vertical-stage overscan, regional assemblies, collision-bound structures, and framed lockdown gates. Its slowest room build was 11.41 ms (99 nodes), slowest representative transition was 306.82 ms, map/inventory opens were 7.52/8.54 ms, peak save time was 8.65 ms, and the three-room memory observation was 231.3 MiB with a 2.7 MiB observed delta. It counted ten player render surfaces, two authored simultaneous enemies, and sixteen runtime audio players, including the bounded regional ambience player. Runtime projectiles cap their own lifetime at three to four seconds, one-shot VFX use signal plus timer cleanup, and the audio manager reuses its fixed player pool.

## Manual release capture

Headless mode cannot provide truthful GPU frame time or rendered draw-call counts. Before `v1.0.0`, record 1080p and 1440p frame-time/draw-call observations for the ten-layer player, a dense standard encounter, and each boss's highest phase. Check windowed/fullscreen pacing, particle visibility, dynamic lights, parallax overdraw, stage-load transitions, and save-write moments. Any recurring spike or sub-60-FPS sequence on the agreed target PC blocks release or must be explicitly approved and documented.
