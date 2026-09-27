#!/usr/bin/env bash
# For every plugin declared in .claude-plugin/marketplace.json, publishes a
# GitHub release for each version its plugin.json has ever had that isn't
# tagged yet. The tag is "<plugin name>-v<version>" on the commit that first
# set that version, and the release notes are that version's CHANGELOG.md
# section. Fails if a version to release has no changelog section.
#
# Needs full git history and tags (fetch-depth: 0) and an authenticated gh.
# Set DRY_RUN=1 to print what would be released without creating anything.
#
# Usage: ./scripts/release.sh
set -euo pipefail

cd "$(dirname "$0")/.."
DRY_RUN="${DRY_RUN:-0}"

fail=0
plugin_dirs=$(jq -r '.plugins[].source' .claude-plugin/marketplace.json | sed 's#^\./##')

for dir in $plugin_dirs; do
  manifest="$dir/.claude-plugin/plugin.json"
  name=$(jq -r .name "$manifest")
  echo "-- releasing plugin: $name --"

  # Walk the manifest's history oldest first, keeping the first commit at each version.
  seen=" "
  while read -r commit; do
    version=$(git show "$commit:$manifest" | jq -r .version)
    case "$seen" in *" $version "*) continue ;; esac
    seen="$seen$version "

    tag="$name-v$version"
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
      echo "ok: $tag already released"
      continue
    fi

    notes=$(./scripts/changelog-section.sh "$dir" "$version")
    if [ -z "$notes" ]; then
      echo "FAIL: $tag has no \"## [$version]\" section in $dir/CHANGELOG.md" >&2
      fail=1
      continue
    fi

    if [ "$DRY_RUN" = "1" ]; then
      echo "dry run: would release $tag at ${commit:0:7}"
      continue
    fi

    gh release create "$tag" --target "$commit" --title "$name $version" --notes "$notes"
    echo "ok: released $tag at ${commit:0:7}"
  done < <(git log --reverse --format=%H -- "$manifest")
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi
