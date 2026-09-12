#!/usr/bin/env bash
# Fails if agents/, skills/, or .claude-plugin/ changed relative to $BASE_REF
# without a version bump in .claude-plugin/plugin.json. Keeps installed
# copies of the plugin from silently going stale for other users.
#
# Usage: BASE_REF=origin/main ./scripts/check-version-bump.sh
set -euo pipefail

cd "$(dirname "$0")/.."
BASE_REF="${BASE_REF:-origin/main}"

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "skip: base ref \"$BASE_REF\" not found (not enough git history in this checkout)"
  exit 0
fi

changed=$(git diff --name-only "$BASE_REF"...HEAD -- agents/ skills/ .claude-plugin/ || true)
if [ -z "$changed" ]; then
  echo "ok: no agent/skill/manifest changes, no version bump required"
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

echo "ok: version bumped $old_version -> $new_version"
