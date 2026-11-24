class_name BeamSaveMigrator
extends RefCounted
## Upgrades save data one version at a time.
##
## Register one step per version: the step added for version n turns a
## v(n) save into a v(n + 1) save. A save newer than this build is refused
## rather than overwritten, because every web build on one site shares the
## same browser storage.
##
## Rules-layer code: no nodes, no scenes, no engine singletons.

const VERSION_KEY := "save_version"

var current_version: int
var last_error: String = ""
var _steps: Dictionary = {}


func _init(p_current_version: int) -> void:
	current_version = p_current_version


func add_step(from_version: int, step: Callable) -> void:
	_steps[from_version] = step


## Returns the migrated save, or an empty Dictionary on failure (see last_error).
func migrate(save: Dictionary) -> Dictionary:
	last_error = ""
	var data: Dictionary = save.duplicate(true)
	var version: int = int(data.get(VERSION_KEY, 1))

	if version > current_version:
		last_error = "Save is v%d but this build reads up to v%d." % [version, current_version]
		return {}

	while version < current_version:
		if not _steps.has(version):
			last_error = "No migration step from v%d." % version
			return {}
		data = _steps[version].call(data)
		version += 1
		data[VERSION_KEY] = version

	return data


## Stamps a fresh save with the current version.
func stamp(save: Dictionary) -> Dictionary:
	var data: Dictionary = save.duplicate(true)
	data[VERSION_KEY] = current_version
	return data
