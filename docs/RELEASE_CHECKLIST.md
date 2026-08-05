# Release-candidate checklist

Candidate: `1.0.0-rc.2`

Engine: Godot `4.7.1.stable.official.a13da4feb`

## Automated and packaging gates

- [x] Clean clone imports and launches.
- [x] Runtime inventory reports zero critical tracking blockers.
- [x] All headless test groups pass.
- [x] All twenty production stage IDs load and traverse in order.
- [x] Campaign completion fires exactly once and reaches the ending/title flow.
- [x] Missing-audio, corrupt-save, settings/remap persistence, encounter reset, boss retry, and cleanup fault paths pass.
- [x] Windows release export succeeds with test, builder, editor-plugin, plan, and local source-mirror content excluded.
- [x] Package contains executable, PCK, documentation, version, source SHA, asset manifest, and all license texts.
- [x] Extracted package launches headlessly without dependency or parse errors.

## Manual input matrix

- [ ] Keyboard traversal and combat.
- [ ] Xbox-compatible controller traversal and combat.
- [ ] Controller disconnect/reconnect with keyboard fallback.
- [ ] Persistent remapped keyboard and controller controls.

## Manual display/performance matrix

- [ ] Windowed 1280×720.
- [ ] Windowed/fullscreen 1920×1080 at stable 60 FPS.
- [ ] 2560×1440.
- [ ] Ultrawide behavior where hardware supports it.
- [ ] Reduced flashing, high contrast, UI scale, screen-shake zero, and vibration zero.

## Manual progression and recovery matrix

- [ ] New game and overwrite confirmation.
- [ ] Continue after checkpoint and after relaunch.
- [ ] All checkpoints, stages, bosses, ending, credits, and stage-select unlock.
- [ ] Death during standard encounter and during every boss.
- [ ] Quit during stage and after checkpoint.
- [ ] Audio-device change where practical.

Promotion to `v1.0.0` requires every applicable manual item above, a green remote CI run on the release commit, no open critical/high defect, and approval of any documented medium defect.
