# Connected-world narrative production bible

This document is the narrative source-of-truth companion to the runtime data in `data/narrative/`. Runtime strings remain in JSON so presentation, persistence, and localization work do not require editing gameplay code.

## Premise and themes

A customizable phase runner follows a corrupted Helix signal from Cyber City's rooftops through the factory that manufactured its defenses, the lunar protocol that rehearsed the city's failure, and the living Abyss that learned from every failed defense. The protagonist is not a prophesied fixed hero; their chosen identity becomes the stable phase signature that links the world's relays and gives them agency inside systems built to classify people as replaceable inputs.

Core themes are identity versus classification, infrastructure as remembered history, recovery through connection, and mastery without surrendering player expression. The ending restores dawn without erasing damage and leaves the completed world open for recovery, optional weapons, records, and traversal routes.

## Region outline

| Region | Narrative movement | Resolution |
|---|---|---|
| Cyber City | Mara helps the newly created runner trace a corporate signal through Rooftop Alley, Billboard Highway, Communication Spire, and Skybridge Junction. | Helix Warden falls, exposing the factory descent and granting Phase Barrier. |
| Mega Robot Factory | Intake and assembly systems reveal that the factory built seed infrastructure for the Neon Moon rather than ordinary machines. | Assembly Colossus falls, restoring the orbital lift and exposing the protocol's destination. |
| Neon Moon Protocol | Cleanroom records and Protocol Echo reveal that the Oracle trained on failed timelines and helped cause the disaster it claimed to predict. | Lunar Oracle falls, opening the Abyssal breach and granting Chain Teleport. |
| Abyssal Night | Corrupted systems contain copied behavior from every prior region; cleansing the Nest reveals a single organism fed by the Oracle's failures. | Void Cerberus falls, the convergence collapses, and the personalized hero returns to a recovering city. |

## Character and speaker roster

| Speaker | Function | Portrait rule | Voice rule |
|---|---|---|---|
| Player (`{player_name}`) | Custom protagonist and player viewpoint. | Use the selected fixed portrait plus live layered visual where space permits. | Use the selected voice profile for barks; story dialogue is text-first. |
| Mara | Relay engineer, guide, and emotional anchor. | `portrait_08`; expressions may change without changing identity. | Text dialogue; bark/audio expansion must not change meaning. |
| Protocol Echo | Lunar system intelligence and archival antagonist voice. | `portrait_10`. | Even, system-like delivery; subtitles required for intelligible audio. |
| Relay Keeper | Service/warp-network voice. | Assigned fixed NPC portrait in the dialogue database. | Short functional lines with full text equivalents. |
| System | Pickups, abilities, and neutral status records. | `portrait_12`. | UI/system cue; no required speech. |
| Regional bosses | Helix Warden, Assembly Colossus, Lunar Oracle, and Void Cerberus. | Live boss presentation and HUD title rather than dialogue portrait. | Unique battle music and telegraphed combat cues. |

## Protagonist dialogue rules

- Never assume body, clothing, voice, portrait, or weapon family in prose.
- Resolve `{player_name}`, `{subject}`, `{subject_cap}`, `{object}`, `{possessive_adjective}`, `{possessive}`, `{reflexive}`, `{be}`, and `{have}` through `PronounResolver`.
- Use the singular/plural verb forms supplied by the chosen pronoun set; do not concatenate pronouns manually in gameplay code.
- The fixed portrait preserves chosen identity and palette; the live `PlayerVisual` is authoritative for exact clothing and weapon appearance.
- Every meaningful voiced phrase requires the same information in subtitles or visible text.
- Player lines should express intent and competence without prescribing personality beyond the immediate action.

## Quest list

`data/narrative/quests.json` is authoritative. `QuestDatabase` validates and reconciles it against saved story flags, inventory, abilities, and warp activation.

| Quest | Type | Contract |
|---|---|---|
| Phasebound | Main, sequential | Twenty-one objectives from the creation prologue through every district and the personalized ending. |
| Lost Arsenal | Side, collection | Recover all twelve optional weapon signals across the four regions. |
| Relay Network | Side, collection | Activate all five discovered-only warp relays. |
| Phase Mastery | Side, collection | Install all seven major progression abilities. |

Quest state is schema-v2 save data. HUD objectives and the Journal read the same reconciled state; neither maintains a separate hardcoded progression list.

## Cutscene and trigger list

Every runtime sequence is one-shot, data-authored, and has a skip endpoint. Standard skip endpoints apply the same story flag as the played sequence and restore player control. The ending endpoint applies completion state and calls the same finish-game route.

| Region | Sequences and resulting state |
|---|---|
| Cyber City | `prologue_rooftop_arrival` → `prologue_complete`; `rooftop_district_exit` → `rooftop_alley_complete`; `billboard_helix_clue` → `billboard_highway_complete`; `spire_orbital_reveal` → `spire_signal_revealed`; `skybridge_warp_intro` → `warp_tutorial_seen`; `helix_warden_warning` → warning seen; `cyber_city_complete` → region complete. |
| Factory | `factory_intake_arrival` → intake reached; `conveyor_assembly_complete` → sort line overridden; `factory_smelting_warning`; `factory_smelting_breakthrough` → core cleared; `factory_purpose_reveal`; `factory_engine_warning`; `assembly_colossus_warning`; `robot_factory_complete`. |
| Neon Moon | `moon_surface_arrival`; `neon_moon_protocol_reveal`; `moon_cleanroom_record`; `security_grid_mastered`; `biotech_corruption_glimpse`; `oracle_origin_reveal`; `biotech_access_component`; `lunar_oracle_warning`; `neon_moon_complete`. |
| Abyss | `abyssal_breach_arrival`; `outpost_cleansed`; `chasm_signal_record`; `nest_evidence_reveal`; `nest_core_cleansed`; `sanctuary_arrival`; `void_cerberus_preparation`; `void_cerberus_warning`; `abyssal_ending`. |

Boss arena presentation supplies the encounter title/introduction. Each region's warning sequence is the skippable pre-boss story beat, and each post-boss region-complete sequence records the defeat consequence.

## Portrait and voice assignment

- Portrait catalog: `data/characters/portrait_catalog.json`; twelve selectable protagonist identities.
- Player portrait: the saved `portrait_id`, with the live layered renderer used by creator, gameplay, pause customization, and ending.
- NPC assignments: stored per line in `data/narrative/dialogue.json`; Mara uses `portrait_08`, Protocol Echo uses `portrait_10`, and System uses `portrait_12`.
- Voice event table: `data/characters/voice_profiles.json`; five profiles map damage, exertion, greeting, and confirmation categories to normalized runtime audio.
- Playback policy: bounded player pool, category cooldown/priority, bark mute, and optional bark subtitles.

## Localization glossary

| Term | Meaning / handling |
|---|---|
| Phase marker | Thrown traversal marker; never call it a warp relay. |
| Phase / teleport | Short-range personal traversal to a validated marker. |
| Warp relay | Discovered-room fast travel; distinct from teleport. |
| Phasebound | The protagonist's stable signature and the main quest title; preserve as a setting term. |
| Helix | Corporate defense network and its residual signal. |
| Neon Moon Protocol | Proper name for the lunar program. |
| Abyssal Night | Proper name for the corrupted final region/state. |
| Convergence | The living system combining copied failures from all regions. |
| Magnetic Rail, Phase Barrier, Kinetic Ground Break, Gravity Anchor, Chain Teleport, Abyssal Filter, Null Energy Field | Progression ability names; preserve capitalization in UI. |

Variable tokens must remain intact in localized strings. Translators may reorder complete tokens to match grammar but must not split braces or replace them with hardcoded pronouns.
