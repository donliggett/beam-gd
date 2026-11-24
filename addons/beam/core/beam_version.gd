class_name BeamVersion
extends RefCounted
## The game's version string, stamped into project.godot by the release workflow.


static func current() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0-dev"))
