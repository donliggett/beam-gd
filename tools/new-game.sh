#!/usr/bin/env bash
# Creates a new game repo from Beam's template.
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

cp -R "$beam/template" "$dest"
mkdir -p "$dest/addons"
cp -R "$beam/addons/beam" "$dest/addons/beam"

for file in project.godot export_presets.cfg .github/workflows/release.yml docs/spec.md README.md; do
  sed -i.bak "s/__GAME_NAME__/$name/g" "$dest/$file"
  rm "$dest/$file.bak"
done

echo "Created $name at $dest"
echo "Next: add GUT to addons/gut, then run the rule tests."
