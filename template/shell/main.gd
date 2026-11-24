extends Control
## Placeholder title screen. Shows the build's version so every web
## and desktop build can be identified at a glance.


func _ready() -> void:
	$Version.text = "v" + BeamVersion.current()
