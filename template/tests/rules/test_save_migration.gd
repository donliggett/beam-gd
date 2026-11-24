extends GutTest
## Example rule tests. Replace the steps with the game's real save changes;
## keep one test per migration step.


func _migrator() -> BeamSaveMigrator:
	var m := BeamSaveMigrator.new(3)
	m.add_step(1, func(d: Dictionary) -> Dictionary:
		d["gold"] = d.get("coins", 0)
		d.erase("coins")
		return d
	)
	m.add_step(2, func(d: Dictionary) -> Dictionary:
		d["party"] = d.get("party", [])
		return d
	)
	return m


func test_migrates_one_step_at_a_time() -> void:
	var out := _migrator().migrate({"save_version": 1, "coins": 5})
	assert_eq(out["save_version"], 3)
	assert_eq(out["gold"], 5)
	assert_false(out.has("coins"))
	assert_eq(out["party"], [])


func test_refuses_saves_from_newer_builds() -> void:
	var m := _migrator()
	assert_eq(m.migrate({"save_version": 9}), {})
	assert_ne(m.last_error, "")


func test_does_not_modify_the_input() -> void:
	var save := {"save_version": 1, "coins": 5}
	_migrator().migrate(save)
	assert_true(save.has("coins"))
