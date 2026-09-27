#!/usr/bin/env bash
# Runs every scripts/tests/*.test.sh and reports each result. Exits non-zero
# if any test fails.
#
# Usage: ./scripts/test.sh
set -euo pipefail

cd "$(dirname "$0")/.."

failed=0
for test_file in scripts/tests/*.test.sh; do
  if ! bash "$test_file"; then
    failed=1
  fi
done

echo ""
if [ "$failed" -ne 0 ]; then
  echo "Some tests failed." >&2
  exit 1
fi
echo "All tests passed."
