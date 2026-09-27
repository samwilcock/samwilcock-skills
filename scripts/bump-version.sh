#!/usr/bin/env bash
# Bumps one plugin's version in its plugin.json by a single semver step and adds
# a "## [<plugin> <version>] - <today>" section to CHANGELOG.md with empty
# Added/Changed/Fixed/Removed headings to fill in. The section goes above every
# released one; when this branch bumps several plugins, their sections follow
# the plugin order in marketplace.json. Delete the headings you
# don't use; CI rejects empty ones and sections without a bullet.
#
# Refuses to run if the plugin's version already differs from $BASE_REF, since
# a branch gets one bump per plugin. To change the bump level, restore the old
# version in plugin.json, delete the changelog section, and run this again.
#
# Usage: ./scripts/bump-version.sh <plugin-name> <major|minor|patch>
set -euo pipefail

cd "$(dirname "$0")/.."
BASE_REF="${BASE_REF:-origin/main}"

if [ $# -ne 2 ]; then
  echo "usage: $0 <plugin-name> <major|minor|patch>" >&2
  exit 2
fi
name="$1"
level="$2"

source=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .source' .claude-plugin/marketplace.json)
if [ -z "$source" ]; then
  echo "FAIL: no plugin named \"$name\" in .claude-plugin/marketplace.json" >&2
  exit 1
fi
manifest="${source#./}/.claude-plugin/plugin.json"
old_version=$(jq -r .version "$manifest")

if git rev-parse --verify -q "$BASE_REF" >/dev/null &&
   base_version=$(git show "$BASE_REF:$manifest" 2>/dev/null | jq -r .version) &&
   [ "$base_version" != "$old_version" ]; then
  echo "FAIL: $name is already bumped on this branch ($base_version -> $old_version)." >&2
  echo "  Edit its \"## [$name $old_version]\" section in CHANGELOG.md instead." >&2
  exit 1
fi

IFS='.' read -r major minor patch <<< "$old_version"
case "$level" in
  major) new_version="$((major + 1)).0.0" ;;
  minor) new_version="${major}.$((minor + 1)).0" ;;
  patch) new_version="${major}.${minor}.$((patch + 1))" ;;
  *) echo "FAIL: bump level must be major, minor or patch, not \"$level\"" >&2; exit 2 ;;
esac

# Build both edits in temp files first, so a failure leaves neither file changed.
manifest_tmp=$(mktemp)
changelog_tmp=$(mktemp)
trap 'rm -f "$manifest_tmp" "$changelog_tmp"' EXIT

jq --arg v "$new_version" '.version = $v' "$manifest" > "$manifest_tmp"

# Sections already added on this branch (headings not in $BASE_REF's changelog)
# sit above the released ones, in marketplace order. Insert the new section
# before the first heading that's either released or belongs to a plugin later
# in marketplace order. Without a base ref there's no way to tell which sections
# are this branch's, so every existing one counts as released and the new
# section goes on top.
HAS_BASE=0
git rev-parse --verify -q "$BASE_REF" >/dev/null && HAS_BASE=1
BASE_HEADINGS=$(git show "$BASE_REF:CHANGELOG.md" 2>/dev/null | grep '^## \[' || true)
PLUGIN_ORDER=" $(jq -r '.plugins[].name' .claude-plugin/marketplace.json | tr '\n' ' ')"
SECTION="## [$name $new_version] - $(date +%F)

### Added

### Changed

### Fixed

### Removed
" NAME="$name" HAS_BASE="$HAS_BASE" BASE_HEADINGS="$BASE_HEADINGS" PLUGIN_ORDER="$PLUGIN_ORDER" awk '
  function rank(plugin) { return index(ENVIRON["PLUGIN_ORDER"], " " plugin " ") }
  BEGIN {
    n = split(ENVIRON["BASE_HEADINGS"], lines, "\n")
    for (i = 1; i <= n; i++) released[lines[i]] = 1
  }
  !done && /^## \[/ {
    split(substr($0, 5), parts, / /)
    if (ENVIRON["HAS_BASE"] == "0" || ($0 in released) || rank(parts[1]) > rank(ENVIRON["NAME"])) {
      print ENVIRON["SECTION"]; done = 1
    }
  }
  { print }
  END { if (!done) print "\n" ENVIRON["SECTION"] }
' CHANGELOG.md > "$changelog_tmp"

mv "$manifest_tmp" "$manifest"
mv "$changelog_tmp" CHANGELOG.md

echo "ok: $name $old_version -> $new_version ($level)"
echo "Next: fill in the \"## [$name $new_version]\" section at the top of CHANGELOG.md."
