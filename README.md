# Beam

A build scaffold for Godot 4 games: one project, desktop builds plus a versioned web build per release, laid out for an AI-agent build loop.

Beam is genre-neutral. Game-specific frameworks (an RPG kit, for example) go in each game's own `addons/`, not here.

## What's in it

| Part | Path | How a game uses it |
| --- | --- | --- |
| Addon | `addons/beam/` | Copied into the game and pinned; update it deliberately |
| Release workflow | `.github/workflows/release.yml` | Called by the game's workflow at a Beam tag |
| Template | `template/` | Copied once when a game is created |
| Tools | `tools/` | Create a new game from the template |

The addon currently provides:

- `BeamVersion.current()`: the version stamped from the release tag
- `BeamSaveMigrator`: step-by-step save migration that refuses saves from newer builds

## Game layout

```
data/      JSON content
maps/      Tiled sources
rules/     pure GDScript logic: no nodes or scenes
shell/     scenes, UI, input, audio
tests/     rules/ (GUT) and web/ (Playwright)
docs/      spec.md, the build spec
```

The one hard rule: nothing in `rules/` depends on `shell/`.

## Requirements

- Godot 4.7.x (the template targets the Compatibility renderer, which web export requires)
- [GUT](https://github.com/bitwes/Gut) in the game's `addons/gut/`, for rule tests
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

Then in the new game:

1. Add GUT to `addons/gut/`.
2. Set `application/bundle_identifier` in the macOS export preset.
3. Write `docs/spec.md`.

## Release flow

Push a tag such as `v0.1.0` in the game repo. The workflow:

1. Installs the pinned Godot version and export templates
2. Stamps the tag into `project.godot`
3. Runs the gates: rule tests, all exports, web smoke test
4. Publishes desktop builds to GitHub Releases
5. Uploads the web build as an artifact, ready to deploy to `/vX.Y.Z/` and `/latest/`

If any gate fails, nothing ships.

## Local commands

Run from the game's folder, with Godot on PATH as `godot`.

### Windows (PowerShell)

```
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/rules -gexit
godot --headless --export-release "Web" build/web/index.html
python -m http.server 8000 -d build/web
```

### Linux / macOS (bash)

```
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/rules -gexit
godot --headless --export-release "Web" build/web/index.html
python3 -m http.server 8000 -d build/web
```

The web build has to be served over HTTP; opening `index.html` directly from disk won't run it.

## Saves and versions

Every web build on one site shares the browser's save storage, so old and new builds can see each other's saves. Stamp every save with `BeamSaveMigrator.stamp()`, load it through `migrate()`, and add a migration step whenever the save format changes.
