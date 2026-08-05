# Performance budget

The production target is 60 FPS at 1920×1080 on a modest 64-bit Windows gaming PC. The automated test is a regression bound, not a substitute for GPU frame-time capture on release hardware.

## Automated bounds

`tests/integration/PerformanceBudgetTest.gd` verifies:

- all 182 runtime assets are served from a committed source-free index;
- no recursive asset-registry scan method remains in gameplay code;
- audio stays at a fixed pool of ten SFX and two BGM players;
- the production Act 4 mastery stage remains under 2,000 scene nodes;
- 64 simultaneous projectiles and 32 simultaneous VFX all release by their bounded lifetimes;
- an unloaded production stage is no longer retained after transition cleanup;
- the complete headless stress pass finishes within ten seconds.

The reference run on 2026-08-04 with Godot 4.7.1 completed in 1.14 seconds. Runtime projectiles cap their own lifetime at three to four seconds, one-shot VFX use signal plus timer cleanup, and the audio manager reuses its fixed player pool.

## Manual release capture

Before `v1.0.0`, record 1080p frame-time observations for a dense standard encounter and each boss's highest phase. Check windowed/fullscreen pacing, particle visibility, dynamic lights, parallax overdraw, stage-load transitions, and save-write moments. Any recurring spike or sub-60-FPS sequence on the agreed target PC blocks release or must be explicitly approved and documented.
