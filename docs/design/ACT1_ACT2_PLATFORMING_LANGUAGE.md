# Act 1–2 platforming language rebuild

## Visual-study conclusions

The rebuild studies the *design language* of three side-scrolling action games without copying their art, layouts, characters, or assets:

- **Castlevania: Symphony of the Night** — platforming is embedded in recognizable rooms: a tower, gallery, bridge, machine, or chapel has a readable structural purpose before it becomes a route. The Clock Tower is especially useful as a reference for layered vertical architecture and landmark-scale mechanisms. [Developer interview](https://shmuplations.com/symphony/) · [Clock Tower reference gallery](https://fantasyanime.com/valhalla/castlevaniasotn/castlevsotn_shots10.htm)
- **Mega Man X** — a stage mechanic is presented as a full apparatus with a top surface, housing, motor/rail/brace, and a clear danger or motion cue. The Storm Eagle route is a useful reference for high-altitude scaffolding, moving-platform telegraphing, and readable airspace. [Storm Eagle reference](https://www.honestgamers.com/guides/mega-man-x/8/read/145.html)
- **Strider** — fast traversal needs continuous lead lines, large framing structures, and collision paths that appear to belong to the same city-scale system. Its 2D action identity is explicitly tied to high speed and instantly responsive input. [Producer interview](https://gamingbolt.com/strider-interview-how-hiryu-is-making-a-cracking-return-to-next-gen-consoles)

## Non-negotiable rules

1. A collision deck is the load-bearing top of a structure, never a luminous rectangle floating in front of a background.
2. Every traversal beat needs an identity from the surrounding district: rooftop catwalk, billboard service frame, antenna shaft, skybridge, conveyor housing, cargo lift, furnace catwalk, crane runway, or crusher bay.
3. A special movement or hazard must visually expose its cause: a lift has rails, a conveyor has rollers and a motor, a dash gap is a broken bridge, and a crusher route has a safety cage/pistons.
4. Vertical routes use a single room-scale landmark with several embedded ledges; they do not read as a stack of unrelated platforms.
5. Optional paths are visibly elevated or offset from the critical route and terminate in a recognizable perch, service gantry, or bypass.
6. Safety color is reserved for affordance: hazard stripes, powered mechanisms, and interaction edges. It is not used as a substitute for volume or support.
7. A vertical collision face is a wall, not a stretched horizontal deck: it carries shaft art and a cap/perch, never a repeated floor tile skin.
8. Static set dressing snaps to real terrain surfaces; mechanical locks use framed emitters and an energy curtain instead of a flat debug-colour rectangle.

## Act 1 — Cyber City

| Stage | Route beat | Structural language |
|---|---|---|
| 1-1 Rooftop Alley | Jump tutorial, wall-climb lesson, optional reward roof | Parapeted roof modules; a service antenna shaft; billboard maintenance bypass. |
| 1-2 Billboard Highway | Lift timing, dash break, optional upper route | Billboard lift carriage, suspended sign frame, and broken skybridge trusses. |
| 1-3 Communication Spire | Full-height wall shaft and climb | Antenna tower as the room landmark; embedded spire ledges and crown perch. |
| 1-4 Skybridge Junction | Carriage crossing and dash bridge | Skybridge trusses and a rail-guided carriage, preserving a long cityward lead line. |

## Act 2 — Mega Robot Factory

| Stage | Route beat | Structural language |
|---|---|---|
| 2-1 Sub-Level Intake | Conveyor introduction and steam timing | Drive-motor conveyor housings, intake gantries, and a guarded heat/service walk. |
| 2-2 Conveyor Assembly | Reversing lane and cargo transfer | Reversible rollers, a rail-guided cargo lift, and an overhead crane runway. |
| 2-3 Smelting Core | Furnace climb and laser forge | Furnace-side catwalks, hoist runway, and a heat-shielded laser walk. |
| 2-4 Robotic Maintenance | Crusher timing and reward bypass | Safety-caged crusher bay and elevated maintenance gantry bypass. |

## Enforcement

`FirstTwoActsProductionTest.gd` verifies all 18 authored traversal sections remain physically landable. It now also requires an authored architecture assembly, at least one visible load-bearing structure, an environment-correct tile surface on every collision deck, context-correct safety marks, and 41 standard/dash route links within the player’s actual movement envelope. Moving routes are separately verified as live mechanics with their own physical assemblies.
