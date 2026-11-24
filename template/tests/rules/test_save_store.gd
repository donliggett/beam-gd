extends GutTest
## Tests for Beam's JSON save store, using a throwaway slot.

const SLOT := "__beam_test"


func _store() -> BeamSaveStore:
	var m := BeamSaveMigrator.new(2)
	m.add_step(1, func(d: Dictionary) -> Dictionary:
		d["gold"] = d.get("coins", 0)
		d.erase("coins")
		return d
	)
	return BeamSaveStore.new(m)


func after_each() -> void:
	_store().erase(SLOT)


func test_round_trip_stamps_the_version() -> void:
	var store := _store()
	assert_true(store.write(SLOT, {"gold": 7}), store.last_error)
	var out := store.read(SLOT)
	assert_eq(int(out["save_version"]), 2)
	assert_eq(int(out["gold"]), 7)


func test_overwrites_an_existing_save() -> void:
	var store := _store()
	store.write(SLOT, {"gold": 1})
	assert_true(store.write(SLOT, {"gold": 2}), store.last_error)
	assert_eq(int(store.read(SLOT)["gold"]), 2)


func test_migrates_an_old_save_on_read() -> void:
	var store := _store()
	DirAccess.make_dir_recursive_absolute(BeamSaveStore.DIR)
	var file := FileAccess.open(store.path_for(SLOT), FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 1, "coins": 3}))
	file.close()
	var out := store.read(SLOT)
	assert_eq(int(out["gold"]), 3)
	assert_false(out.has("coins"))


func test_refuses_a_save_from_a_newer_build() -> void:
	var store := _store()
	DirAccess.make_dir_recursive_absolute(BeamSaveStore.DIR)
	var file := FileAccess.open(store.path_for(SLOT), FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 9}))
	file.close()
	assert_eq(store.read(SLOT), {})
	assert_ne(store.last_error, "")


func test_missing_slot_reads_empty() -> void:
	var store := _store()
	assert_eq(store.read(SLOT), {})
	assert_ne(store.last_error, "")


func test_rejects_unsafe_slot_names() -> void:
	var store := _store()
	assert_false(store.write("../escape", {}))
	assert_ne(store.last_error, "")


func test_lists_slots() -> void:
	var store := _store()
	store.write(SLOT, {})
	assert_true(SLOT in store.slots())
