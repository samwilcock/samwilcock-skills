# Shared helpers for scripts/tests/*.test.sh. Each test runs the real scripts
# against a throwaway git repo, so tests only see what a person running the
# scripts would see: files, output and exit status.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tests_failed=0

# Every temp dir a test creates lives under TEST_TMP, removed when the file exits.
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

# Creates a temp git repo with two plugins (dev-team then test-team in
# marketplace.json), a CHANGELOG.md with one released section each, and this
# repo's scripts copied in. origin/main points at that initial commit, and a
# "feature" branch is checked out. Prints the repo path.
make_repo() {
  local dir
  dir=$(mktemp -d "$TEST_TMP/repo.XXXXXX")
  (
    cd "$dir"
    git init -q
    mkdir -p scripts .claude-plugin dev-team-plugin/.claude-plugin test-team-plugin/.claude-plugin
    cp "$REPO_ROOT"/scripts/*.sh scripts/
    cat > .claude-plugin/marketplace.json <<'JSON'
{
  "name": "test-marketplace",
  "plugins": [
    { "name": "dev-team", "source": "./dev-team-plugin" },
    { "name": "test-team", "source": "./test-team-plugin" }
  ]
}
JSON
    printf '{\n  "name": "dev-team",\n  "version": "1.0.0"\n}\n' > dev-team-plugin/.claude-plugin/plugin.json
    printf '{\n  "name": "test-team",\n  "version": "2.0.0"\n}\n' > test-team-plugin/.claude-plugin/plugin.json
    cat > CHANGELOG.md <<'MD'
# Changelog

Intro paragraph.

## [test-team 2.0.0] - 2026-01-02

### Added
- Released test-team change.

## [dev-team 1.0.0] - 2026-01-01

### Added
- Released dev-team change.
MD
    git add -A
    git -c user.name=test -c user.email=test@example.com commit -qm initial
    git update-ref refs/remotes/origin/main HEAD
    git checkout -qb feature
  )
  echo "$dir"
}

# Prints the CHANGELOG.md version headings in <dir>, one per line, without dates.
headings() {
  grep '^## \[' "$1/CHANGELOG.md" | sed 's/ - .*//'
}

# assert_eq <description> <expected> <actual>
assert_eq() {
  if [ "$2" = "$3" ]; then
    return 0
  fi
  echo "    $1" >&2
  echo "    expected:" >&2; printf '%s\n' "$2" | sed 's/^/      /' >&2
  echo "    actual:" >&2;   printf '%s\n' "$3" | sed 's/^/      /' >&2
  return 1
}

# Runs every function named test_* in the calling file, each in a subshell so a
# failure can't leak state, and prints ok/FAIL per test. The subshell's status is
# read on its own line: bash ignores set -e inside an if condition, which would
# let a failed assert_eq be overridden by a later one that passes.
run_tests() {
  local name status
  for name in $(declare -F | awk '{print $3}' | grep '^test_'); do
    ( set -e; "$name" )
    status=$?
    if [ "$status" -eq 0 ]; then
      echo "ok: $name"
    else
      echo "FAIL: $name" >&2
      tests_failed=1
    fi
  done
  return "$tests_failed"
}
