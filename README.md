# Cyber City Platformer

Cyber City Platformer is a Godot 4.7.1 neon action-platformer rebuilt as one continuous 202-room metroidvania. Its twenty districts span Cyber City, Mega Robot Factory, Neon Moon Protocol, and Abyssal Night, with character creation, six starting weapon families, universal phase teleport, persistent abilities/shortcuts/warps/caches, four regional bosses, a personalized ending, and post-game exploration. The 103 expansion rooms carry unique static geometry derived from twenty district-specific spatial rhythms and rendered landmark silhouettes. The original twenty-stage campaign remains available as a validated legacy mode; all four acts now have production presentation, traversal, objective, boss, completion, and persistence coverage, including seventeen stage-specific hero panoramas.

## Play the Windows build

Extract the complete release archive, keep the executable and PCK together, then run `CyberCityPlatformer.exe`. The unsigned build targets 64-bit Windows 10/11. Saves and settings are stored by Godot in the current user's application-data directory, never beside the executable.

See `CONTROLS.md` for the complete keyboard/controller map and `KNOWN_ISSUES.md` for release notes that can affect first launch.

## Developer setup

Prerequisites:

- Godot `4.7.1.stable` standard build
- Git LFS
- Python 3.11 or newer for repository tooling

Clone with LFS assets, import once, and run the complete non-UI suite:

```text
git lfs pull
godot --headless --path . --import
python tools/run_headless_suite.py --group all
```

Create the Windows build and release archive:

```text
godot --headless --path . --export-release "Windows Desktop" build/windows/CyberCityPlatformer.exe
python tools/package_release.py
```

The startup scene is `res://scenes/ui/TitleScreen.tscn`. The connected-world manifest lives in `res://data/world/world_manifest.json`; legacy campaign metadata lives in `res://Stages/campaign_manifest.json`. Runtime assets live under `res://assets/runtime` and are tracked with Git LFS. Original asset-pack mirrors and builder tools are development-only and excluded from exports.

Detailed test, architecture, performance, asset, and release evidence is under `docs/`. Start with `docs/implementation/DELIVERY_SUMMARY.md` for the current delivery state.
