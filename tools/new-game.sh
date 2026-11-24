#!/usr/bin/env bash
# Creates a new game repo from Beam's template, pinned to this version of Beam.
# Usage: ./tools/new-game.sh my-game ../my-game

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <name> <destination>" >&2
  exit 1
fi

name="$1"
dest="$2"

if ! [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "name must be a lowercase slug, e.g. my-game" >&2
  exit 1
fi
if [ -e "$dest" ]; then
  echo "destination already exists: $dest" >&2
  exit 1
fi

beam="$(cd "$(dirname "$0")/.." && pwd)"
version="$(sed -n 's/^version="\(.*\)"/\1/p' "$beam/addons/beam/plugin.cfg" | head -n 1)"
if [ -z "$version" ]; then
  echo "cannot read Beam's version from addons/beam/plugin.cfg" >&2
  exit 1
fi
beam_version="v$version"

cp -R "$beam/template" "$dest"

for file in project.godot export_presets.cfg addons.json .github/workflows/release.yml docs/spec.md README.md; do
  sed -i.bak -e "s/__GAME_NAME__/$name/g" -e "s/__BEAM_VERSION__/$beam_version/g" "$dest/$file"
  rm "$dest/$file.bak"
done

echo "Created $name at $dest (Beam $beam_version)"
echo "Next, from the new folder: godot --headless -s res://tools/addons.gd"
