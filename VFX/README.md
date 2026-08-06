# VFX

`SourceArt` mirrors every supplied VFX pack and its subfolders. Each production stage has a dedicated `VFX` node for effect instances. Existing combat particle scenes remain under `res://scenes/vfx`, and any supplied PNG sheet can be resolved by relative path with `AssetRegistry.get_vfx_texture()` for custom `AnimatedSprite2D`, particles, or shader effects.
