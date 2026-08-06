# Curated runtime assets

Only assets referenced by the production game are stored here. Binary files are tracked with Git LFS; the original bulk source packs remain ignored.

- Runtime files: 314
- Runtime bytes: 80247467
- Unique license texts: 5

`asset_license_manifest.json` maps every shipped binary to its source path, SHA-256 digest, size, and included license text. `resource_index.json` is the source-free runtime lookup index included in exports.

The prompt specifications, canonical references, output paths, and hashes for the generated Act 1/2 and Act 3/4 panoramas plus traversal kits are recorded in `docs/assets/ACT1_ACT2_GENERATED_PANORAMAS.md`, `docs/assets/ACT3_ACT4_GENERATED_PANORAMAS.md`, and `docs/assets/ACT1_ACT2_GENERATED_TRAVERSAL_KITS.md`.

To recurate from an asset-populated maintainer checkout, run `python tools/curate_runtime_assets.py`, then rerun `python tools/inventory_runtime_assets.py --check`.
