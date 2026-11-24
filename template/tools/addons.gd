extends SceneTree
## Installs the addons pinned in res://addons.json into res://addons/.
##
## Usage, from the project folder on any platform:
##   godot --headless -s res://tools/addons.gd
##
## Reads the addons.json format GodotEnv uses (path, cache, and per addon:
## url, checkout, subfolder, source), so either tool can install from it.
## Remote addons must be pinned to a tag or commit, never a branch like main.

const MANIFEST := "res://addons.json"
const STAMP := ".installed"
const UNPINNED := ["", "main", "master", "develop", "HEAD"]


func _init() -> void:
	quit(_install_all())


func _install_all() -> int:
	if not FileAccess.file_exists(MANIFEST):
		printerr("No addons.json found.")
		return 1
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if typeof(manifest) != TYPE_DICTIONARY or typeof(manifest.get("addons")) != TYPE_DICTIONARY:
		printerr("addons.json must be an object with an \"addons\" object.")
		return 1

	var root := ProjectSettings.globalize_path("res://")
	var dest_root := root.path_join(str(manifest.get("path", "addons")))
	var cache_root := root.path_join(str(manifest.get("cache", ".addons")))
	DirAccess.make_dir_recursive_absolute(dest_root)
	DirAccess.make_dir_recursive_absolute(cache_root)

	var failed := 0
	for addon_name in manifest.addons:
		var spec = manifest.addons[addon_name]
		if typeof(spec) != TYPE_DICTIONARY:
			printerr("%s: entry must be an object" % addon_name)
			failed += 1
			continue
		var error := _install(str(addon_name), spec, root, dest_root, cache_root)
		if error != "":
			printerr("%s: %s" % [addon_name, error])
			failed += 1

	if failed > 0:
		printerr("%d addon(s) failed to install." % failed)
		return 1
	return 0


func _install(addon_name: String, spec: Dictionary, root: String, dest_root: String, cache_root: String) -> String:
	var url := str(spec.get("url", ""))
	var source := str(spec.get("source", "remote"))
	var checkout := str(spec.get("checkout", ""))
	var subfolder := str(spec.get("subfolder", "/")).trim_prefix("/").trim_suffix("/")
	var dest := dest_root.path_join(addon_name)
	if url == "":
		return "missing url"

	var stamp := "%s %s %s %s" % [source, url, checkout, subfolder]
	var stamp_path := dest.path_join(STAMP)
	if source == "remote" and FileAccess.file_exists(stamp_path) \
			and FileAccess.get_file_as_string(stamp_path).strip_edges() == stamp:
		print("%s: already at %s" % [addon_name, checkout])
		return ""

	var src := ""
	if source == "local":
		src = (url if url.is_absolute_path() else root.path_join(url)).simplify_path()
	elif source == "remote":
		if checkout in UNPINNED:
			return "checkout must be a tag or commit, not \"%s\"" % checkout
		src = cache_root.path_join(addon_name)
		var error := _fetch(src, url, checkout)
		if error != "":
			return error
	else:
		return "unknown source \"%s\"" % source

	if subfolder != "":
		src = src.path_join(subfolder)
	if not DirAccess.dir_exists_absolute(src):
		return "folder not found: %s" % src

	_remove_tree(dest)
	var copy_error := _copy_tree(src, dest)
	if copy_error != OK:
		return "copy failed (error %d)" % copy_error
	var file := FileAccess.open(stamp_path, FileAccess.WRITE)
	if file:
		file.store_line(stamp)
	print("%s: installed %s" % [addon_name, checkout if source == "remote" else "from " + url])
	return ""


## Fetches one commit into a reusable cache clone. The cache is updated in
## place rather than deleted, because git marks its object files read-only.
func _fetch(cache: String, url: String, checkout: String) -> String:
	DirAccess.make_dir_recursive_absolute(cache)
	var steps: Array = []
	if not DirAccess.dir_exists_absolute(cache.path_join(".git")):
		steps.append(["init", "--quiet"])
		steps.append(["remote", "add", "origin", url])
	else:
		steps.append(["remote", "set-url", "origin", url])
	steps.append(["fetch", "--quiet", "--depth", "1", "origin", checkout])
	steps.append(["checkout", "--quiet", "--force", "FETCH_HEAD"])
	for step in steps:
		var output := []
		var args: Array = ["-C", cache]
		args.append_array(step)
		if OS.execute("git", args, output, true) != 0:
			return "git %s failed: %s" % [step[0], "".join(output).strip_edges()]
	return ""


func _copy_tree(src: String, dest: String) -> Error:
	var error := DirAccess.make_dir_recursive_absolute(dest)
	if error != OK:
		return error
	var dir := DirAccess.open(src)
	if dir == null:
		return DirAccess.get_open_error()
	dir.include_hidden = true
	for file_name in dir.get_files():
		error = DirAccess.copy_absolute(src.path_join(file_name), dest.path_join(file_name))
		if error != OK:
			return error
	for dir_name in dir.get_directories():
		if dir_name == ".git":
			continue
		error = _copy_tree(src.path_join(dir_name), dest.path_join(dir_name))
		if error != OK:
			return error
	return OK


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.include_hidden = true
	for file_name in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for dir_name in dir.get_directories():
		_remove_tree(path.path_join(dir_name))
	DirAccess.remove_absolute(path)
