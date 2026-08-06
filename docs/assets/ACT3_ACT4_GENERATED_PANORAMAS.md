# Act 3–4 generated environment panoramas

Generation date: 2026-08-05

Generator: OpenAI image generation, built-in mode

All ten outputs are 1672×941 PNG hero backgrounds. They contain no gameplay collision, characters, logos, watermarks, or legible text. Production stages place authored terrain, props, enemies, checkpoints, hazards, and exits above these non-interactive backgrounds.

The files are recorded in `asset_license_manifest.json` with stable `generated://openai-imagegen/2026-08-05/...` provenance and the included project asset-license text. They were created as original environment illustrations; project assets informed only high-level stage identity and side-scrolling readability.

## Shared prompt direction

Create a richly layered 16:9 hero panorama for a premium side-scrolling cyberpunk metroidvania. Use hand-painted modern HD pixel art, crisp readable silhouettes, deliberate foreground separation, a dark lower gameplay band, controlled dithering, restrained emissive bloom, no characters, no UI, no words, no logos, and no watermark.

## Neon Moon Protocol

| Stage | Output | Art direction | SHA-256 |
|---|---|---|---|
| Lunar Surface Arrival | `res://assets/runtime/environments/Act3_NeonMoon/Generated/lunar_surface_arrival_panorama_v1.png` | Blue lunar craters, cyan crystals, landing pod, distant research towers, and a ringed planet. | `ca0d0260bcc46cccfb2498ed1f22def4092e3175c43c48059c8182aed4c9b713` |
| Research Cleanrooms | `res://assets/runtime/environments/Act3_NeonMoon/Generated/research_cleanrooms_panorama_v1.png` | Mint containment cells, specimen tanks, immaculate catwalks, violet diagnostics, and an orbital window. | `584a272690fae12b5f82b86b5ed3661f5e02e477523670c60312bb7fd9cd604c` |
| Security Grid Shaft | `res://assets/runtime/environments/Act3_NeonMoon/Generated/security_grid_shaft_panorama_v1.png` | Vertical orbital-defense shaft, suspended security pods, cyan emitters, and magenta warning rings. | `4e1006c7ac70c4c1189c022511ac50c1dd290f875479b7f5c92017f180594873` |
| Bio-Tech Labs | `res://assets/runtime/environments/Act3_NeonMoon/Generated/bio_tech_labs_panorama_v1.png` | Breached biotech chamber, violet culture vessels, organic egg clusters, and a glowing gravity core. | `702fe64200d7e378b7aea2dec5e8c5bab8d46c4e448b5e3c4714aac353fc3826` |
| Orbital Command | `res://assets/runtime/environments/Act3_NeonMoon/Generated/orbital_command_panorama_v1.png` | Symmetrical command ring, suspended telemetry orb, blue planet vista, cyan systems, and gold command accents. | `be430d17cf2fc3385d079724a315f02148916763b5287c08e2f7ac03666da4ab` |

## Abyssal Night

| Stage | Output | Art direction | SHA-256 |
|---|---|---|---|
| Corrupted Outpost | `res://assets/runtime/environments/Act4_AbyssalNight/Generated/corrupted_outpost_panorama_v1.png` | Ruined purifier tower, green corruption crystal, magenta conduits, storm-light, and wet industrial debris. | `d089d1af4ef654af54dfe4bb4f1e32969b9d34c4633089de2dbe72e4b45f616a` |
| The Dark Chasm | `res://assets/runtime/environments/Act4_AbyssalNight/Generated/the_dark_chasm_panorama_v1.png` | Bottomless blue-black canyon, fossil lift, cable platforms, rib-like rock, and isolated cyan beacons. | `c73a5381bcb4744341d9537e4b82941f67ea232c3b6910669e7491014ae8c3ce` |
| Bio-Mechanical Nest | `res://assets/runtime/environments/Act4_AbyssalNight/Generated/bio_mechanical_nest_panorama_v1.png` | Organic-machine hatchery, crimson membranes, transparent brood vats, neural cable, and a central hatch. | `5d70c61c1c6646bc213ec5649e68ba1b20bce585d6e687d1a375079f7d903d5e` |
| Abyssal Sanctuary | `res://assets/runtime/environments/Act4_AbyssalNight/Generated/abyssal_sanctuary_panorama_v1.png` | Ancient-tech sanctuary, lavender phase reliquary, sentinel idol, runic archways, and gravity fragments. | `bb5da2bfd3c8fe31688d57f7cd7a25e9d503824b91399aed09618d61d4942033` |
| Heart of the Void | `res://assets/runtime/environments/Act4_AbyssalNight/Generated/heart_of_the_void_panorama_v1.png` | Final boss chamber with a scarlet void heart, concentric reactor rings, corruption crystals, portals, and black reflections. | `08ffde34b895480b562d9b245dbe61db82a9fe8281994b2b5723080a8db57d88` |

## Integration and verification

`CampaignStage.gd` supports independent far/middle/front tints so each hero panorama remains readable while native parallax silhouettes preserve depth. `StageArchitectureDressing.gd` and `AuthoredTraversal.gd` supply Neon Moon and Abyssal Night with region-native structural assemblies instead of borrowing Cyber City or Factory scenery.

`LastTwoActsProductionTest.gd` verifies the ten exact panorama paths, source resolution floor, stage handoffs, HUD and objective flow, regional traversal assemblies, and both boss finales.
