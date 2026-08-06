# SFX

`Library` mirrors the complete supplied SFX tree. `AudioManager` maps laser, melee, jump, dash, explosion, pickup, checkpoint, and hurt events to real library sounds, with generated fallbacks retained only if a source file cannot be loaded.

Resolve any additional relative path with `AssetRegistry.get_sfx_stream()` and assign the returned `AudioStream` to an audio player.
