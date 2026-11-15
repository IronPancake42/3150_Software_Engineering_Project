@tool
extends EditorPlugin
## Adds FileSystem dock context-menu entries that run PsxBatch on a folder.
## The output goes to a sibling folder named "<folder>_psx"; originals are never touched.

const _Batch = preload("./psx_batch.gd")

var _menu: EditorContextMenuPlugin


class PsxMenu extends EditorContextMenuPlugin:
	var owner_plugin: EditorPlugin

	func _popup_menu(paths: PackedStringArray) -> void:
		if paths.size() != 1:
			return
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(paths[0])):
			return
		#add_context_menu_item("PSX Texture Prep: Process Folder (RGB555)", _on_rgb555)
		add_context_menu_item("PSX Texture Prep: Process Folder (16-color palette)", _on_palette)
		add_context_menu_item("PSX Texture Prep: Process Folder (8-color palette)", _on_palette8)
		add_context_menu_item("PSX Texture Prep: Process Folder (4-color palette)", _on_palette4)

	func _on_rgb555(paths: PackedStringArray) -> void:
		owner_plugin.run_on_folder(paths[0], {"color_mode": "rgb555"}, "_psx555")

	func _on_palette(paths: PackedStringArray) -> void:
		owner_plugin.run_on_folder(paths[0], {"color_mode": "palette", "palette_colors": 16, "overwrite": true}, "_psx")
	func _on_palette8(paths: PackedStringArray) -> void:
		owner_plugin.run_on_folder(paths[0], {"color_mode": "palette", "palette_colors": 8, "overwrite": true}, "_psx")
	func _on_palette4(paths: PackedStringArray) -> void:
		owner_plugin.run_on_folder(paths[0], {"color_mode": "palette", "palette_colors": 4, "overwrite": true}, "_psx")


func _enter_tree() -> void:
	_menu = PsxMenu.new()
	_menu.owner_plugin = self
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _menu)


func _exit_tree() -> void:
	if _menu:
		remove_context_menu_plugin(_menu)
		_menu = null


func run_on_folder(path: String, options: Dictionary, suffix: String) -> void:
	var src := path.trim_suffix("/")
	if src == "res:" or src.is_empty():
		push_warning("PSX Texture Prep: choose a sub-folder, not the project root.")
		return
	var dst := src + suffix
	var report := _Batch.process_folder(src, dst, options)
	if not report["ok"]:
		push_warning("PSX Texture Prep: %s" % report["error"])
		return
	print("PSX Texture Prep: %d processed, %d omitted, %d errors -> %s" % [
		report["processed"].size(), report["omitted"].size(), report["errors"].size(), dst])
	for e in report["errors"]:
		push_warning("PSX Texture Prep: %s: %s" % [e["path"], e["error"]])
	EditorInterface.get_resource_filesystem().scan()
