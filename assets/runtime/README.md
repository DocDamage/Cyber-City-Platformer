# Curated runtime assets

Only assets referenced by the production game are stored here. Binary files are tracked with Git LFS; the original bulk source packs remain ignored.

- Runtime files: 182
- Runtime bytes: 39063439
- Unique license texts: 5

`asset_license_manifest.json` maps every shipped binary to its source path, SHA-256 digest, size, and included license text. `resource_index.json` is the source-free runtime lookup index included in exports.

To recurate from an asset-populated maintainer checkout, run `python tools/curate_runtime_assets.py`, then rerun `python tools/inventory_runtime_assets.py --check`.
