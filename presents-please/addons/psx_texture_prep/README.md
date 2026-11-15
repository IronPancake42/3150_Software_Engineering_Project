# PSX Texture Prep Lite

Version 1.0.0 · Luna Tile Works · MIT · Godot 4.7+ (tested on 4.7.2)

Batch texture preparation for a PlayStation-style look: power-of-two fitting, RGB555 or N-color palette reduction, and a baked 4×4 Bayer dither. Output is deterministic.

## Use

Enable the plugin, then right-click a folder in the FileSystem dock and choose **PSX Texture Prep: Process Folder (RGB555)** or **(16-color palette)**. PNG files are written to `<folder>_psx`; originals are never modified. Existing files in the destination are skipped (the menu does not overwrite). To process again, delete those outputs or call `PsxBatch.process_folder` with `"overwrite": true`.

From code:

```gdscript
var fitted := PsxTexturePrep.fit_pow2(img, PsxTexturePrep.MODE_NEAREST_POW2, 256)
var rgb555 := PsxTexturePrep.to_rgb555(fitted, true)
var result := PsxTexturePrep.to_palette(fitted, 16, true)   # { "image", "palette" }
var report := PsxBatch.process_folder("res://textures", "res://textures_psx", {"color_mode": "palette"})
```

## Limits

This is not a PSX shader, does not assign materials, and does not integrate with Godot's native importer. The workflow is source folder → destination folder. Free converters exist outside Godot. The editor menu has not been exercised in a running editor session. No network access, no telemetry.

## AI disclosure

The code and text were generated with the help of an AI assistant (Claude, by Anthropic) and reviewed by the author.

Processing a large folder can briefly freeze the editor (work runs on the main thread, with no progress bar).

## License

MIT. See `LICENSE`.
