#!/usr/bin/env bash
# Tests for scripts/bump-version.sh.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

test_bumping_dev_team_then_test_team_keeps_marketplace_order() {
  local repo
  repo=$(make_repo)
  "$repo/scripts/bump-version.sh" dev-team minor >/dev/null
  "$repo/scripts/bump-version.sh" test-team minor >/dev/null
  assert_eq "headings after bumping dev-team then test-team" \
"## [dev-team 1.1.0]
## [test-team 2.1.0]
## [test-team 2.0.0]
## [dev-team 1.0.0]" "$(headings "$repo")"
}

test_bumping_test_team_then_dev_team_keeps_marketplace_order() {
  local repo
  repo=$(make_repo)
  "$repo/scripts/bump-version.sh" test-team minor >/dev/null
  "$repo/scripts/bump-version.sh" dev-team minor >/dev/null
  assert_eq "headings after bumping test-team then dev-team" \
"## [dev-team 1.1.0]
## [test-team 2.1.0]
## [test-team 2.0.0]
## [dev-team 1.0.0]" "$(headings "$repo")"
}

test_second_bump_keeps_the_first_sections_content() {
  local repo
  repo=$(make_repo)
  "$repo/scripts/bump-version.sh" dev-team minor >/dev/null
  # Fill in dev-team's section the way a contributor would.
  awk '/^## \[dev-team 1.1.0\]/ { print; print ""; print "### Changed"; print "- A dev-team change."; skip = 1; next }
       skip && /^## \[/ { skip = 0; print "" }
       !skip' "$repo/CHANGELOG.md" > "$repo/CHANGELOG.tmp" && mv "$repo/CHANGELOG.tmp" "$repo/CHANGELOG.md"
  "$repo/scripts/bump-version.sh" test-team minor >/dev/null
  assert_eq "dev-team 1.1.0 section after bumping test-team" \
"### Changed
- A dev-team change." "$("$repo/scripts/changelog-section.sh" dev-team 1.1.0)"
}

test_single_bump_goes_above_released_sections_and_updates_plugin_json() {
  local repo
  repo=$(make_repo)
  "$repo/scripts/bump-version.sh" test-team patch >/dev/null
  assert_eq "headings after one test-team bump" \
"## [test-team 2.0.1]
## [test-team 2.0.0]
## [dev-team 1.0.0]" "$(headings "$repo")"
  assert_eq "test-team version in plugin.json" \
    "2.0.1" "$(jq -r .version "$repo/test-team-plugin/.claude-plugin/plugin.json")"
}

test_bump_without_a_base_ref_still_goes_on_top() {
  local repo
  repo=$(make_repo)
  git -C "$repo" update-ref -d refs/remotes/origin/main
  "$repo/scripts/bump-version.sh" test-team patch >/dev/null
  assert_eq "first heading when origin/main is missing" \
    "## [test-team 2.0.1]" "$(headings "$repo" | head -1)"
}

run_tests
