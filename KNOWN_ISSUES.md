# Known issues

No critical or high-severity software defect is open in the automated release-candidate pass.

- The Windows executable is not code-signed. Windows SmartScreen may show an unknown-publisher warning on first launch.
- The game is authored for a 16:9 viewport. Wider windows are supported by the expanding canvas, but composition outside the central play area is not individually authored for every ultrawide aspect ratio.
- GPU frame pacing, controller disconnect/reconnect behavior, vibration strength, and audio-device switching require observation on the target hardware; record those results in `docs/RELEASE_CHECKLIST.md` before promoting the candidate to `v1.0.0`.
