# Clean-clone baseline

## Audit identity

- Audit date: 2026-08-04
- Baseline commit: `380d88d5e181924aa0cf42fdde550af1a0e8479a`
- Source branch: `agent/tilemap-enemy-foundation`
- Completion branch: `feature/full-game-completion`
- Godot: `4.7.1.stable.official.a13da4feb`
- Host: Windows 11, headless Forward+ import
- Clean-clone method: local `git clone --no-local --single-branch` with no ignored files copied

## Reproduction commands

```powershell
git clone --no-local --branch feature/full-game-completion --single-branch <repo> <clean-directory>
godot --headless --path <clean-directory> --editor --quit
godot --headless --path <clean-directory> --quit-after 120
godot --headless --path <clean-directory> --script res://scripts/AssetRegistrySmokeTest.gd
godot --headless --path <clean-directory> --script res://scripts/SystemsSmokeTest.gd
godot --headless --path <clean-directory> --script res://scripts/BossSystemsSmokeTest.gd
godot --headless --path <clean-directory> --script res://scripts/CampaignSceneSmokeTest.gd
godot --headless --path <clean-directory> --script res://scripts/GoalSmokeTest.gd
```

## Confirmed baseline behavior

- The tracked project declares Godot 4.7 and can be discovered by the editor.
- The local asset-populated working copy completes an editor import under Godot 4.7.1.
- The tracked tree contains 20 campaign stage scene paths, 22 enemy scene paths, four boss scene paths, core player/combat scripts, and five headless smoke-test entrypoints.
- The ignored local tree contains the referenced audio, character, tileset, prop, parallax, and VFX source files.
- The current startup scene is `res://scenes/Level.tscn`, not a title screen.

## Clean-clone result

The clean clone is not runnable. Godot's import command exits with code `0`, but its log contains fatal dependency and parse errors, so exit code alone is not a valid startup gate.

Primary failures:

- `res://scripts/AudioManager.gd` hard-preloads 18 absent SFX/music streams and cannot parse.
- `res://scenes/vfx/SparkBurst.tscn` references an absent VFX sheet, which also breaks `Bullet.gd` and `VFXSpawner.gd` preloads.
- `res://scenes/RooftopTileSet.tres` and `res://Stages/Act1_CyberCity/CyberCityTileSet.tres` reference an absent terrain atlas.
- `res://scenes/Level.tscn` references absent billboard and light props.
- Enemy `SpriteFrames` resources reference ignored `Characters/Enemies/SourceArt` animation strips.
- `AssetRegistry` falls back to `res://icon.svg` for missing gameplay art.
- The asset-registry smoke test times out while traversing fallback and missing-resource paths.
- Other smoke tests fail before validating their intended systems because autoload and resource parsing fails first.

## Local-versus-clean distinction

The local working copy has 31,472 ignored files under the canonical asset roots plus 16,361 ignored files under the legacy `assets/` mirror. Those files make local import results materially different from a clone. No feature that depends on those files is considered verified until its curated runtime assets are tracked and the clean-clone gate passes.

## Launch behavior

- Local asset-populated copy: editor import completes; main scene is the legacy rooftop level.
- Clean clone: process starts but logs missing resources, invalid scene dependencies, autoload parse failures, and gameplay icon fallbacks.
- Title, continue, settings, credits, ending, and stage-select flows do not exist at this baseline.

## Audit conclusion

Milestone A is not met. The first implementation dependency is a complete runtime asset inventory, followed by safe audio/resource loading and a curated tracked runtime tree.
