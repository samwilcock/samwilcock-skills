#!/usr/bin/env bash
# Prints the body of one version's section from a plugin's CHANGELOG.md: the
# lines after its "## [<version>]" heading, up to the next "## [" heading, with
# leading and trailing blank lines trimmed. Prints nothing if the file or the
# section is missing. Used as release notes and by check-version-bump.sh.
#
# Usage: ./scripts/changelog-section.sh <plugin-dir> <version>
set -euo pipefail

dir="$1"
version="$2"
changelog="$dir/CHANGELOG.md"

[ -f "$changelog" ] || exit 0

awk -v heading="## [$version]" '
  index($0, heading) == 1 { found = 1; next }
  found && /^## \[/ { exit }
  found { lines[++n] = $0 }
  END {
    first = 1; while (first <= n && lines[first] ~ /^[[:space:]]*$/) first++
    last = n;  while (last >= first && lines[last] ~ /^[[:space:]]*$/) last--
    for (i = first; i <= last; i++) print lines[i]
  }
' "$changelog"
