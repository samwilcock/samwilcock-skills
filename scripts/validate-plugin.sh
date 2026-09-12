#!/usr/bin/env bash
# Validates this repo's plugin/marketplace manifests and agent frontmatter.
# Run locally with: ./scripts/validate-plugin.sh
# Used by .github/workflows/validate-plugin.yml on every PR.
set -euo pipefail

cd "$(dirname "$0")/.."
fail=0

err() { echo "FAIL: $1" >&2; fail=1; }
ok() { echo "ok: $1"; }

# ---------- plugin.json ----------
PLUGIN_JSON=".claude-plugin/plugin.json"
if [ ! -f "$PLUGIN_JSON" ]; then
  err "$PLUGIN_JSON is missing"
else
  if ! jq empty "$PLUGIN_JSON" 2>/dev/null; then
    err "$PLUGIN_JSON is not valid JSON"
  else
    for field in name version description; do
      val=$(jq -r --arg f "$field" '.[$f] // empty' "$PLUGIN_JSON")
      [ -n "$val" ] || err "$PLUGIN_JSON is missing required field \"$field\""
    done
    ok "$PLUGIN_JSON is valid JSON with required fields"
  fi
fi

# ---------- marketplace.json ----------
MARKET_JSON=".claude-plugin/marketplace.json"
if [ ! -f "$MARKET_JSON" ]; then
  err "$MARKET_JSON is missing"
else
  if ! jq empty "$MARKET_JSON" 2>/dev/null; then
    err "$MARKET_JSON is not valid JSON"
  else
    plugin_count=$(jq '.plugins | length' "$MARKET_JSON")
    if [ "$plugin_count" -eq 0 ]; then
      err "$MARKET_JSON declares no plugins"
    else
      ok "$MARKET_JSON is valid JSON declaring $plugin_count plugin(s)"
    fi
    # every declared plugin's source path must exist
    while IFS= read -r source; do
      resolved="${source#./}"
      if [ ! -e "$resolved" ] && [ "$resolved" != "" ]; then
        err "marketplace plugin source \"$source\" does not resolve to an existing path"
      else
        ok "marketplace plugin source \"$source\" resolves"
      fi
    done < <(jq -r '.plugins[].source' "$MARKET_JSON")
  fi
fi

# ---------- agent frontmatter ----------
if [ -d agents ]; then
  for f in agents/*.md; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .md)
    name=$(awk '/^name:/{print $2; exit}' "$f")
    desc=$(awk '/^description:/{found=1; sub(/^description: */, ""); print; exit}' "$f")

    if [ "$name" != "$base" ]; then
      err "$f: frontmatter name \"$name\" does not match filename \"$base\""
    fi
    if [ -z "$desc" ]; then
      err "$f: missing or empty description in frontmatter"
    fi
    if ! head -1 "$f" | grep -q '^---$'; then
      err "$f: does not start with YAML frontmatter (---)"
    fi
  done
  ok "checked agent frontmatter in agents/"
fi

# ---------- skill frontmatter ----------
if [ -d skills ]; then
  for f in skills/*/SKILL.md; do
    [ -e "$f" ] || continue
    dir=$(basename "$(dirname "$f")")
    name=$(awk '/^name:/{print $2; exit}' "$f")
    desc=$(awk '/^description:/{found=1; sub(/^description: */, ""); print; exit}' "$f")

    if [ "$name" != "$dir" ]; then
      err "$f: frontmatter name \"$name\" does not match directory \"$dir\""
    fi
    if [ -z "$desc" ]; then
      err "$f: missing or empty description in frontmatter"
    fi
  done
  ok "checked skill frontmatter in skills/"
fi

if [ "$fail" -ne 0 ]; then
  echo "" >&2
  echo "Validation failed. Fix the issues above before merging." >&2
  exit 1
fi

echo ""
echo "All checks passed."
