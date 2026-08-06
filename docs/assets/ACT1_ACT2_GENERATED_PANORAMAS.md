# Act 1–2 generated environment panoramas

Generation date: 2026-08-05

Generator: OpenAI image generation, built-in mode

All seven outputs are 1672×941 PNG hero backgrounds. They contain no gameplay collision, characters, logos, watermarks, or legible text. Production stages place authored terrain, props, enemies, checkpoints, hazards, and exits above these non-interactive backgrounds.

## Canonical project references

- Factory family: `res://assets/runtime/environments/Act2_RobotFactory/Mega Robot Factory/CENA (!)/BACKGROUD/BACKGROUND (1).png`
- Cyber City family: `res://assets/runtime/environments/parallax/Rooftops 2/back.png`, `middle.png`, and `front.png`

The references are covered by `res://assets/runtime/licenses/LICENSE-0ddffeed82b7.txt`. Generated outputs are recorded in `asset_license_manifest.json` with stable `generated://openai-imagegen/2026-08-05/...` provenance and the same included CC0 text.

## Shared prompt direction

Create a production-quality 2D side-scrolling environment panorama matching the supplied Cyber City Platformer project reference: polished hand-authored 16/32-bit pixel art, orthographic 16:9 composition, strong layered depth, a deliberately darker and quieter central gameplay band, crisp large forms, navy shadow structure, controlled neon accents, no characters, no gameplay platforms, no legible text, no logos, and no watermark. The image must read behind bright player sprites, terrain, hazards, and HUD at a 960×540 internal viewport.

## Stage variants

### Communication Spire

Apply the shared Cyber City direction to a huge vertical communications spire with stacked antenna arrays, satellite dishes, relay structures, and a dense distant skyline. Use cyan, magenta, violet, and restrained red aviation lights. Preserve an uncluttered traversal band while making the tower the unmistakable landmark.

Output: `res://assets/runtime/environments/Act1_CyberCity/Generated/communication_spire_panorama_v1.png`

SHA-256: `c9f401c44228625aed9f88606c3f0f2cce5222b6e7ed32f883c53a15d1ac8028`

### Skybridge Junction

Apply the shared Cyber City direction to suspended skybridges crossing a deep city canyon, with layered bridge silhouettes, tower supports, distant traffic-light trails, and strong horizontal perspective. Use deep navy, violet, cyan, and magenta while keeping the central gameplay band quiet.

Output: `res://assets/runtime/environments/Act1_CyberCity/Generated/skybridge_junction_panorama_v1.png`

SHA-256: `1063a364b9987735bd1a97d5c7762a6479a776e230a6006a45c63373c6cd44e0`

### Executive Helipad

Apply the shared Cyber City direction to a high corporate helipad above tower crowns under dramatic predawn storm clouds. Leave open central sky for boss readability, with violet and crimson clouds, cyan runway accents, distant lightning, and a premium executive-district silhouette.

Output: `res://assets/runtime/environments/Act1_CyberCity/Generated/executive_helipad_panorama_v1.png`

SHA-256: `aec63e50b239eb7134d202d133ad54630988f21cf1ad386a1e1768dad46890ca`

### Mega Robot Factory master

Create a gigantic automated robot assembly complex in the canonical factory style, with layered gantries, robot silhouettes, pipes, suspended machinery, and distant production bays. Use navy structure with cyan and orange industrial light. Exclude hotel, city-street, and moon imagery.

Output: `res://assets/runtime/environments/Act2_RobotFactory/Generated/mega_robot_factory_panorama_v1.png`

SHA-256: `eda76e9639fa4834732662e59a432dc77e1e30c9bf860dd2f0c1329e80d877f3`

### Smelting Core

Apply the shared factory direction to a furnace and crucible district centered on a molten smelting core, vertical pipes, suspended vats, heat-lit machinery, and deep production shafts. Use orange and amber heat against navy structure, with a dark readable gameplay band.

Output: `res://assets/runtime/environments/Act2_RobotFactory/Generated/smelting_core_panorama_v1.png`

SHA-256: `80c07454b39ea731513f12103863f0759b5aa7e4d887c5bf25ebf6e24507bc04`

### Robotic Maintenance

Apply the shared factory direction to a robotic maintenance hall with repair cradles, articulated tool arms, dormant robot silhouettes, diagnostics, cables, and clean service bays. Use teal, cyan, mint, and deep blue for a distinct cool technical identity.

Output: `res://assets/runtime/environments/Act2_RobotFactory/Generated/robotic_maintenance_panorama_v1.png`

SHA-256: `87dc755450ea4a60cd751c5fdb40a9571c03809ece2d45f3b3af088c16db4b8c`

### Assembly Engine

Apply the shared factory direction to a monumental, near-symmetrical boss chamber dominated by a central assembly turbine/reactor, heavy vertical machinery, claws, conduits, and deep mechanical architecture. Use navy, violet, magenta, and restrained orange core light, preserving a clear central arena silhouette.

Output: `res://assets/runtime/environments/Act2_RobotFactory/Generated/assembly_engine_panorama_v1.png`

SHA-256: `e5a097e234e9a37a8dcf241cc75190fca820da2cd369083e5517a63fcc29fa6e`

## Verification

`FirstTwoActsProductionTest.gd` asserts the production paths, seven unique resources, and a minimum 1600×900 source resolution. `LegacyActCapture.gd` renders start, signature, and finish frames for all ten stages so composition and foreground separation can be reviewed with the production HUD and gameplay layers present.
