# Beam

A build scaffold for Godot 4 games: one project, desktop builds plus a versioned web build per release, laid out for an AI-agent build loop.

Beam is genre-neutral. Game-specific frameworks (an RPG kit, for example) are pinned in each game's own `addons.json`, not here.

## What's in it

| Part | Path | How a game uses it |
| --- | --- | --- |
| Addon | `addons/beam/` | Pinned by tag in the game's `addons.json` |
| Release workflow | `.github/workflows/release.yml` | Called by the game's workflow at a Beam tag |
| Template | `template/` | Copied once when a game is created |
| Tools | `tools/` | Create a new game from the template |
| Self-test | `.github/workflows/self-test.yml` | Builds a game from the template and runs its tests on every push |

The addon provides:

- `BeamVersion.current()`: the version stamped from the release tag
- `BeamSaveMigrator`: step-by-step save migration that refuses saves from newer builds
- `BeamSaveStore`: JSON save slots in `user://saves/`, written safely and migrated on read

## Game layout

```
addons.json   pinned addons (Beam, GUT, anything else)
data/         content
maps/         Tiled sources
rules/        pure GDScript logic: no nodes or scenes
shell/        scenes, UI, input, audio
tests/        rules/ (GUT) and web/ (Playwright)
tools/        addons.gd, the addon installer
docs/         spec.md, the build spec
```

The one hard rule: nothing in `rules/` depends on `shell/`.

## Requirements

- Godot 4.7.x (the template targets the Compatibility renderer, which web export requires)
- Git, used by the addon installer
- Node.js and Python 3, for the local web smoke test

## Start a new game

### Windows (PowerShell)

```
.\tools\new-game.ps1 -Name my-game -Destination ..\my-game
```

### Linux / macOS (bash)

```
./tools/new-game.sh my-game ../my-game
```

The new game pins the version of Beam it was created from. Then, in the new game's folder:

1. Install the pinned addons: `godot --headless -s res://tools/addons.gd`
2. Set `application/bundle_identifier` in the macOS export preset.
3. Write `docs/spec.md`.

## Addons

A game's addons are listed in `addons.json` and installed into `addons/`, which is not committed. Each entry is pinned to a tag or commit; branch names like `main` are refused.

```json
"beam": {
  "url": "https://github.com/donliggett/beam-gd",
  "checkout": "v0.2.1",
  "subfolder": "addons/beam"
}
```

`tools/addons.gd` runs on Godot itself, so the command is the same on every platform. It reads the same `addons.json` format as [GodotEnv](https://github.com/chickensoft-games/GodotEnv), so either tool can install from the file. An entry with `"source": "local"` copies from a folder instead of fetching a repo.

To upgrade an addon, change its `checkout` and run the installer again.

## Release flow

Push a tag such as `v0.1.0` in the game repo. The workflow:

1. Installs the pinned Godot version, export templates and addons
2. Stamps the tag into `project.godot`
3. Runs the gates: rule tests, all exports, web smoke test
4. Publishes desktop builds to GitHub Releases
5. Uploads the web build as an artifact, ready to deploy to `/vX.Y.Z/` and `/latest/`

If any gate fails, nothing ships.

## Local commands

Run from the game's folder, with Godot on PATH as `godot`.

### Windows (PowerShell)

```
godot --headless -s res://tools/addons.gd
godot --headless --import
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/rules -gexit
godot --headless --export-release "Web" build/web/index.html
python -m http.server 8000 -d build/web
```

### Linux / macOS (bash)

```
godot --headless -s res://tools/addons.gd
godot --headless --import
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/rules -gexit
godot --headless --export-release "Web" build/web/index.html
python3 -m http.server 8000 -d build/web
```

Import runs twice because addons that add importers (dialogue files, for example) only take effect after the first pass. Rule tests run from `tests/rules/` and its subfolders, as set in `.gutconfig.json`.

The web build has to be served over HTTP; opening `index.html` directly from disk won't run it.

## Saves and versions

Every web build on one site shares the browser's save storage, so old and new builds can see each other's saves. Use `BeamSaveStore` with a `BeamSaveMigrator`:

```gdscript
var migrator := BeamSaveMigrator.new(2)
migrator.add_step(1, func(d: Dictionary) -> Dictionary:
	d["gold"] = d.get("coins", 0)
	d.erase("coins")
	return d
)
var saves := BeamSaveStore.new(migrator)
saves.write("slot-1", {"gold": 10})
var data := saves.read("slot-1")  # migrated; empty with saves.last_error set on failure
```

Bump the migrator's version and add a step whenever the save format changes. JSON has one number type, so whole numbers read back as floats; convert with `int()` where it matters.
