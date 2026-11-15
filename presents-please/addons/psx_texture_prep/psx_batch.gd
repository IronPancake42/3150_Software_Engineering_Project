class_name PsxBatch
extends RefCounted
## Folder-to-folder batch processing for PsxTexturePrep.

const _Prep = preload("./psx_texture_prep.gd")
const EXTENSIONS := ["png", "jpg", "jpeg", "webp"]


## Processes every png/jpg/jpeg/webp under `src` (recursive) and writes PNG files
## to `dst`, keeping the sub-folder layout. Files under `src` are never written.
##
## options (all optional):
##   mode            PsxTexturePrep.MODE_* for fit_pow2 (default MODE_NEAREST_POW2)
##   max_side        int, default 1024
##   color_mode      "rgb555" (default) or "palette"
##   palette_colors  int 2..256, default 16
##   dither          bool, default true
##   alpha_threshold float 0..1, default 0.5
##   overwrite       bool, default false (existing destination files are skipped)
##
## Returns { "ok": bool, "error": String,
##           "processed": Array[String]  (relative paths of source files written),
##           "omitted":   Array[Dictionary] ({path, reason}),
##           "errors":    Array[Dictionary] ({path, error}) }
## `ok` is false only for a fatal setup problem (see "error"); per-file errors are listed in "errors".
static func process_folder(src: String, dst: String, options: Dictionary = {}) -> Dictionary:
	var report := {"ok": false, "error": "", "processed": [], "omitted": [], "errors": []}
	var mode: int = int(options.get("mode", _Prep.MODE_NEAREST_POW2))
	var max_side: int = int(options.get("max_side", 1024))
	var color_mode: String = str(options.get("color_mode", "rgb555"))
	var colors: int = int(options.get("palette_colors", 16))
	var dither: bool = bool(options.get("dither", true))
	var athr: float = float(options.get("alpha_threshold", 0.5))
	var overwrite: bool = bool(options.get("overwrite", true))
	var one_file: String = str(options.get("one_file", ""))

	if color_mode != "rgb555" and color_mode != "palette":
		report["error"] = "Unknown color_mode '%s' (use \"rgb555\" or \"palette\")." % color_mode
		return report
	var a := _abs(src)
	var b := _abs(dst)
	if a.is_empty() or b.is_empty():
		report["error"] = "Source and destination must not be empty."
		return report
	if not DirAccess.dir_exists_absolute(a):
		report["error"] = "Source folder does not exist: %s" % src
		return report
	if a == b or b.begins_with(a + "/") or a.begins_with(b + "/"):
		report["error"] = "Destination must be a separate folder, not inside (or containing) the source."
		return report

	var files: Array = []
	_collect(a, "", files)
	var written := {}
	for rel: String in files:
		if not one_file.is_empty() and not one_file == rel:
			continue
		var out_rel := rel.get_basename() + ".png"
		var out_path := b + "/" + out_rel
		if written.has(out_rel):
			report["omitted"].append({"path": rel, "reason": "same output name as an earlier file"})
			continue
		if FileAccess.file_exists(out_path) and not overwrite:
			report["omitted"].append({"path": rel, "reason": "destination exists"})
			continue
		var img := Image.new()
		var err := img.load(a + "/" + rel)
		if err != OK or img.is_empty():
			report["errors"].append({"path": rel, "error": "cannot read image (error %d)" % err})
			continue
		var fitted: Image = _Prep.fit_pow2(img, mode, max_side)
		var result: Image
		if color_mode == "palette":
			result = _Prep.to_palette(fitted, colors, dither, athr)["image"]
		else:
			result = _Prep.to_rgb555(fitted, dither, athr)
		var dir_err := DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
		if dir_err != OK:
			report["errors"].append({"path": rel, "error": "cannot create folder (error %d)" % dir_err})
			continue
		var save_err := result.save_png(out_path)
		if save_err != OK:
			report["errors"].append({"path": rel, "error": "cannot write PNG (error %d)" % save_err})
			continue
		written[out_rel] = true
		report["processed"].append(rel)
	report["ok"] = true
	return report


static func _abs(p: String) -> String:
	if p.is_empty():
		return ""
	var s := ProjectSettings.globalize_path(p).simplify_path()
	while s.length() > 1 and s.ends_with("/"):
		s = s.substr(0, s.length() - 1)
	return s


static func _collect(root: String, rel: String, out: Array) -> void:
	var dir_path := root if rel.is_empty() else root + "/" + rel
	var dirs := DirAccess.get_directories_at(dir_path)
	var files := DirAccess.get_files_at(dir_path)
	var d := Array(files)
	d.sort()
	for f: String in d:
		if f.begins_with("."):
			continue
		if f.get_extension().to_lower() in EXTENSIONS:
			out.append(f if rel.is_empty() else rel + "/" + f)
	var sub := Array(dirs)
	sub.sort()
	for s: String in sub:
		if s.begins_with("."):
			continue
		_collect(root, s if rel.is_empty() else rel + "/" + s, out)
