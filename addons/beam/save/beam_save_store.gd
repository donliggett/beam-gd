class_name BeamSaveStore
extends RefCounted
## Reads and writes JSON save files in user://saves/, through a BeamSaveMigrator.
##
## JSON keeps saves readable and safe: loading one never runs code, unlike
## loading a .tres save. Every write is stamped with the current save version;
## every read is migrated up to it, and saves from newer builds are refused.
##
## JSON has a single number type, so whole numbers read back as floats.
## Convert with int() where it matters.

const DIR := "user://saves"

var migrator: BeamSaveMigrator
var last_error: String = ""

var _slot_pattern := RegEx.create_from_string("^[A-Za-z0-9_-]+$")


func _init(p_migrator: BeamSaveMigrator) -> void:
	migrator = p_migrator


func path_for(slot: String) -> String:
	return DIR.path_join(slot + ".json")


func exists(slot: String) -> bool:
	return _valid(slot) and FileAccess.file_exists(path_for(slot))


## Writes through a temporary file, so a crash mid-write never leaves a half-written save.
func write(slot: String, data: Dictionary) -> bool:
	last_error = ""
	if not _valid(slot):
		return false
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := path_for(slot)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = "Cannot write %s (error %d)." % [temp, FileAccess.get_open_error()]
		return false
	file.store_string(JSON.stringify(migrator.stamp(data), "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var error := DirAccess.rename_absolute(temp, path)
	if error != OK:
		last_error = "Cannot replace %s (error %d)." % [path, error]
		return false
	return true


## Returns the migrated save, or an empty Dictionary on failure (see last_error).
func read(slot: String) -> Dictionary:
	last_error = ""
	if not _valid(slot):
		return {}
	var path := path_for(slot)
	if not FileAccess.file_exists(path):
		last_error = "No save in slot \"%s\"." % slot
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Save in slot \"%s\" is not valid JSON." % slot
		return {}
	var data := migrator.migrate(parsed)
	if data.is_empty():
		last_error = migrator.last_error
	return data


func erase(slot: String) -> bool:
	if not exists(slot):
		return false
	return DirAccess.remove_absolute(path_for(slot)) == OK


func slots() -> PackedStringArray:
	var names := PackedStringArray()
	var dir := DirAccess.open(DIR)
	if dir == null:
		return names
	for file_name in dir.get_files():
		if file_name.get_extension() == "json":
			names.append(file_name.get_basename())
	return names


func _valid(slot: String) -> bool:
	if _slot_pattern.search(slot) == null:
		last_error = "Slot names may use letters, digits, - and _ only."
		return false
	return true
