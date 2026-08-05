# Stage props

Canonical prop roots used by `AssetRegistry`:

- `CyberCityProps` — neon billboards, dishes, antennas, terminals
- `FactoryProps` — pipes, conveyors, steam vents, hazard lights
- `LunarProps` — cleanroom terminals, glass panels, forcefields
- `VoidProps` — organic roots, bio-cyber spikes, dark pillars

The supplied packs are mirrored into each folder's `SourceArt` directory. `AssetRegistry.get_prop_texture()` searches these canonical folders first; the old `res://assets` paths remain read-only compatibility fallbacks for any scene that has not yet been migrated.
