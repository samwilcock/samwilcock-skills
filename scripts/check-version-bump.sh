#!/usr/bin/env bash
# For every plugin declared in .claude-plugin/marketplace.json, fails if that
# plugin's agents/, skills/, viz/, templates/, or .claude-plugin/ changed
# relative to $BASE_REF without a version bump in its plugin.json, or if the new version
# isn't a valid single-step semver bump (major.minor.patch) over the old one.
# Keeps installed copies of a plugin from silently going stale, and keeps
# version numbers meaningful rather than arbitrary.
#
# Usage: BASE_REF=origin/main ./scripts/check-version-bump.sh
set -euo pipefail

cd "$(dirname "$0")/.."
BASE_REF="${BASE_REF:-origin/main}"
SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "skip: base ref \"$BASE_REF\" not found (not enough git history in this checkout)"
  exit 0
fi

fail=0
plugin_dirs=$(jq -r '.plugins[].source' .claude-plugin/marketplace.json | sed 's#^\./##')

for dir in $plugin_dirs; do
  echo "-- checking plugin: $dir --"

  changed=$(git diff --name-only "$BASE_REF"...HEAD -- "$dir/agents/" "$dir/skills/" "$dir/viz/" "$dir/templates/" "$dir/.claude-plugin/" || true)
  if [ -z "$changed" ]; then
    echo "ok: no agent/skill/viz/manifest changes in $dir, no version bump required"
    continue
  fi

  version_changed=$(git diff --name-only "$BASE_REF"...HEAD -- "$dir/.claude-plugin/plugin.json" || true)
  if [ -z "$version_changed" ]; then
    echo "FAIL: these files changed but $dir/.claude-plugin/plugin.json's version was not bumped:" >&2
    echo "$changed" | sed 's/^/  /' >&2
    fail=1
    continue
  fi

  if ! git cat-file -e "$BASE_REF:$dir/.claude-plugin/plugin.json" 2>/dev/null; then
    new_version=$(jq -r .version "$dir/.claude-plugin/plugin.json")
    if [[ "$new_version" =~ $SEMVER_RE ]]; then
      echo "ok: $dir/.claude-plugin/plugin.json is new on this branch, starting at $new_version"
    else
      echo "FAIL: $dir/.claude-plugin/plugin.json's version \"$new_version\" isn't valid major.minor.patch semver" >&2
      fail=1
    fi
    continue
  fi

  old_version=$(git show "$BASE_REF:$dir/.claude-plugin/plugin.json" | jq -r .version)
  new_version=$(jq -r .version "$dir/.claude-plugin/plugin.json")

  if [ "$old_version" = "$new_version" ]; then
    echo "FAIL: $dir/.claude-plugin/plugin.json changed but version is still $old_version — bump it" >&2
    fail=1
    continue
  fi

  if ! [[ "$old_version" =~ $SEMVER_RE ]]; then
    echo "FAIL: base version \"$old_version\" in $dir/.claude-plugin/plugin.json isn't valid major.minor.patch semver" >&2
    fail=1
    continue
  fi
  if ! [[ "$new_version" =~ $SEMVER_RE ]]; then
    echo "FAIL: new version \"$new_version\" in $dir/.claude-plugin/plugin.json isn't valid major.minor.patch semver (e.g. 1.4.2)" >&2
    fail=1
    continue
  fi

  IFS='.' read -r old_major old_minor old_patch <<< "$old_version"
  IFS='.' read -r new_major new_minor new_patch <<< "$new_version"

  expected_major="$((old_major + 1)).0.0"
  expected_minor="${old_major}.$((old_minor + 1)).0"
  expected_patch="${old_major}.${old_minor}.$((old_patch + 1))"

  if [ "$new_version" = "$expected_major" ]; then
    bump="major"
  elif [ "$new_version" = "$expected_minor" ]; then
    bump="minor"
  elif [ "$new_version" = "$expected_patch" ]; then
    bump="patch"
  else
    echo "FAIL: $dir: $old_version -> $new_version isn't a valid single-step semver bump." >&2
    echo "  From $old_version, the next version must be exactly one of:" >&2
    echo "    $expected_major (major — breaking change to agents/skills)" >&2
    echo "    $expected_minor (minor — new agent/skill or capability, backwards compatible)" >&2
    echo "    $expected_patch (patch — fix or tweak to existing behavior)" >&2
    fail=1
    continue
  fi

  echo "ok: $dir version bumped $old_version -> $new_version ($bump)"
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi
