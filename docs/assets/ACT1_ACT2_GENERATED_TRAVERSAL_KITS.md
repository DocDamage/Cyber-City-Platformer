# Act 1–2 generated traversal kits

## Purpose

These twelve transparent foreground props replace the former generic traversal strips with original, load-bearing structures. They are deliberately small enough to layer with the supplied rooftop and factory tiles while making the collision edge read as a functional part of the world.

| District | Files | Gameplay use |
|---|---|---|
| Cyber City | `cyber_rooftop_catwalk_v1.png`, `cyber_billboard_gantry_v1.png`, `cyber_antenna_shaft_v1.png`, `cyber_skybridge_truss_v1.png`, `cyber_elevator_cage_v1.png`, `cyber_antenna_perch_v1.png` | Roof routes, billboard lifts, service shafts, spire climbs, and broken bridges. |
| Mega Robot Factory | `factory_conveyor_v1.png`, `factory_maintenance_gantry_v1.png`, `factory_furnace_catwalk_v1.png`, `factory_cargo_lift_v1.png`, `factory_crane_runway_v1.png`, `factory_crusher_bay_v1.png` | Conveyors, transfer lifts, smelter routes, maintenance bypasses, and crusher timing. |

## Provenance

- Generator: OpenAI built-in image generation, 2026-08-05.
- Treatment: generated on a flat magenta chroma background, locally alpha-matted, then cropped into individual runtime PNGs.
- Visual constraints: original cyberpunk/factory architecture only; no characters, logos, text, or copied game art/layouts; high-level design reference was limited to functional, readable action-platformer architecture.

## Prompt specifications

**Cyber City:** six modular, side-view load-bearing structures: parapeted rooftop catwalk, billboard service gantry, radio-spire ladder shaft, broken skybridge truss, elevator carriage on guide rails, and antenna perch. Dark teal steel, violet shadows, restrained amber safety accents, crisp pixel-art edges.

**Mega Robot Factory:** six modular, side-view machinery structures: roller conveyor with drive motor, maintenance gantry, furnace catwalk, cargo lift cage, crane runway, and crusher bay. Navy machinery, cool steel, yellow safety accents, furnace-orange indicators, crisp pixel-art edges.

## Integration

`AuthoredTraversal.gd` owns the architecture assembly for each route and layers the appropriate prop behind the collision-backed terrain deck. `FirstTwoActsProductionTest.gd` verifies every authored route has that visible assembly and the correct act tile surface.
