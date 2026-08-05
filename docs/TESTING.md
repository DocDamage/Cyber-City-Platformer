# Testing

All automation is pinned to Godot `4.7.1.stable.official.a13da4feb`. Each GDScript test runs in an isolated headless process and returns a meaningful exit code. On Windows, the Python runner resolves the small official console launcher to the real process and uses Godot log files so timeouts are reliable.

## Complete local gate

```text
python tools/run_headless_suite.py --group all --log-dir build/test-logs
python tools/inventory_runtime_assets.py --check
```

Available repeatable groups are `import`, `resource`, `unit`, `systems`, `campaign`, and `shell`. Combine groups by repeating `--group`. Override the engine with `GODOT_BIN` or `--godot`; the per-command timeout defaults to 120 seconds.

The full gate covers import/parse validation, clean-clone dependencies, schema/state transitions, player combat and movement, production encounters, bosses, stage mechanics, performance bounds, all twenty production scenes, deterministic campaign traversal, atomic save recovery, settings/remap persistence, every shell route, and missing-audio fallbacks.

## Export gate

```text
godot --headless --path . --export-release "Windows Desktop" build/windows/CyberCityPlatformer.exe
python tools/package_release.py --allow-dirty
```

Omit `--allow-dirty` for an actual release. The packager rejects missing files, forbidden test/editor/source markers in the PCK, absolute developer paths in release documents, and an unclean Git worktree. It records the source SHA and SHA-256 hashes for the executable and PCK.

GitHub Actions runs six required jobs on pushes and pull requests targeting `main`: import, resource validation, unit tests, systems/shell smoke, campaign smoke, and Windows export. Every job uploads logs; the export job uploads the temporary Windows build.
