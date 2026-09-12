#!/usr/bin/env bash
# Fails if agents/, skills/, viz/, or .claude-plugin/ changed relative to
# $BASE_REF without a version bump in .claude-plugin/plugin.json, or if the
# new version isn't a valid single-step semver bump (major.minor.patch) over
# the old one. Keeps installed copies of the plugin from silently going
# stale, and keeps version numbers meaningful rather than arbitrary.
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

changed=$(git diff --name-only "$BASE_REF"...HEAD -- agents/ skills/ viz/ .claude-plugin/ || true)
if [ -z "$changed" ]; then
  echo "ok: no agent/skill/viz/manifest changes, no version bump required"
  exit 0
fi

version_changed=$(git diff --name-only "$BASE_REF"...HEAD -- .claude-plugin/plugin.json || true)
if [ -z "$version_changed" ]; then
  echo "FAIL: these files changed but .claude-plugin/plugin.json's version was not bumped:" >&2
  echo "$changed" | sed 's/^/  /' >&2
  exit 1
fi

old_version=$(git show "$BASE_REF:.claude-plugin/plugin.json" | jq -r .version)
new_version=$(jq -r .version .claude-plugin/plugin.json)

if [ "$old_version" = "$new_version" ]; then
  echo "FAIL: plugin.json changed but version is still $old_version — bump it" >&2
  exit 1
fi

if ! [[ "$old_version" =~ $SEMVER_RE ]]; then
  echo "FAIL: base version \"$old_version\" in plugin.json isn't valid major.minor.patch semver" >&2
  exit 1
fi
if ! [[ "$new_version" =~ $SEMVER_RE ]]; then
  echo "FAIL: new version \"$new_version\" in plugin.json isn't valid major.minor.patch semver (e.g. 1.4.2)" >&2
  exit 1
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
  echo "FAIL: $old_version -> $new_version isn't a valid single-step semver bump." >&2
  echo "  From $old_version, the next version must be exactly one of:" >&2
  echo "    $expected_major (major — breaking change to agents/skills)" >&2
  echo "    $expected_minor (minor — new agent/skill or capability, backwards compatible)" >&2
  echo "    $expected_patch (patch — fix or tweak to existing behavior)" >&2
  exit 1
fi

echo "ok: version bumped $old_version -> $new_version ($bump)"
