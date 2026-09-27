#!/usr/bin/env bash
# Tests for scripts/test.sh, run against a copy with its own test files.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

# Creates a temp dir holding a copy of scripts/test.sh and a scripts/tests/
# folder with one test file per argument: "pass" or "fail". Prints the dir.
make_runner() {
  local dir outcome i=0
  dir=$(mktemp -d "$TEST_TMP/runner.XXXXXX")
  mkdir -p "$dir/scripts/tests"
  cp "$REPO_ROOT/scripts/test.sh" "$dir/scripts/"
  for outcome in "$@"; do
    i=$((i + 1))
    if [ "$outcome" = pass ]; then
      echo 'echo "ran-'"$i"'"' > "$dir/scripts/tests/t$i.test.sh"
    else
      printf 'echo "ran-%s"\nexit 1\n' "$i" > "$dir/scripts/tests/t$i.test.sh"
    fi
  done
  echo "$dir"
}

test_runner_passes_when_every_test_file_passes() {
  local dir
  dir=$(make_runner pass pass)
  "$dir/scripts/test.sh" >/dev/null 2>&1
}

test_runner_fails_and_still_runs_the_rest_when_one_file_fails() {
  local dir output status
  dir=$(make_runner fail pass)
  status=0
  output=$("$dir/scripts/test.sh" 2>&1) || status=$?
  assert_eq "runner exit status" "1" "$status"
  assert_eq "test files run" "ran-1 ran-2" "$(echo "$output" | grep -o 'ran-[0-9]' | tr '\n' ' ' | sed 's/ $//')"
}

run_tests
