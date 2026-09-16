#!/usr/bin/env bash
# Validates the root marketplace manifest and every plugin's manifest/agent/skill
# frontmatter in this repo.
# Run locally with: ./scripts/validate-plugin.sh
# Used by .github/workflows/validate-plugin.yml on every PR.
set -euo pipefail

cd "$(dirname "$0")/.."
fail=0

err() { echo "FAIL: $1" >&2; fail=1; }
ok() { echo "ok: $1"; }

# ---------- marketplace.json ----------
MARKET_JSON=".claude-plugin/marketplace.json"
plugin_dirs=()
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
    while IFS=$'\t' read -r source market_name; do
      resolved="${source#./}"
      if [ ! -e "$resolved" ] && [ "$resolved" != "" ]; then
        err "marketplace plugin source \"$source\" does not resolve to an existing path"
        continue
      fi
      ok "marketplace plugin source \"$source\" resolves"
      plugin_dirs+=("$resolved")
      plugin_json_name=$(jq -r '.name // empty' "$resolved/.claude-plugin/plugin.json" 2>/dev/null || true)
      if [ -n "$plugin_json_name" ] && [ "$plugin_json_name" != "$market_name" ]; then
        err "marketplace entry name \"$market_name\" does not match $resolved/.claude-plugin/plugin.json's name \"$plugin_json_name\""
      fi
    done < <(jq -r '.plugins[] | [.source, .name] | @tsv' "$MARKET_JSON")
  fi
fi

# ---------- per-plugin checks ----------
for dir in "${plugin_dirs[@]}"; do
  echo ""
  echo "-- checking plugin: $dir --"

  PLUGIN_JSON="$dir/.claude-plugin/plugin.json"
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

  # ---------- agent frontmatter ----------
  if [ -d "$dir/agents" ]; then
    for f in "$dir"/agents/*.md; do
      [ -e "$f" ] || continue
      base=$(basename "$f" .md)
      name=$(awk '/^name:/{print $2; exit}' "$f")
      desc=$(awk '/^description:/{found=1; sub(/^description: */, ""); print; exit}' "$f")
      model=$(awk '/^model:/{print $2; exit}' "$f")

      if [ "$name" != "$base" ]; then
        err "$f: frontmatter name \"$name\" does not match filename \"$base\""
      fi
      if [ -z "$desc" ]; then
        err "$f: missing or empty description in frontmatter"
      fi
      if ! head -1 "$f" | grep -q '^---$'; then
        err "$f: does not start with YAML frontmatter (---)"
      fi
      case "$model" in
        sonnet|opus|haiku|fable|inherit|claude-*) ;;
        "") err "$f: missing model in frontmatter" ;;
        *) err "$f: unrecognized model \"$model\" (expected an alias like sonnet/opus/haiku/fable, \"inherit\", or a full claude-* model ID)" ;;
      esac
    done
    ok "checked agent frontmatter in $dir/agents/"
  fi

  # ---------- skill frontmatter ----------
  if [ -d "$dir/skills" ]; then
    for f in "$dir"/skills/*/SKILL.md; do
      [ -e "$f" ] || continue
      sdir=$(basename "$(dirname "$f")")
      name=$(awk '/^name:/{print $2; exit}' "$f")
      desc=$(awk '/^description:/{found=1; sub(/^description: */, ""); print; exit}' "$f")

      if [ "$name" != "$sdir" ]; then
        err "$f: frontmatter name \"$name\" does not match directory \"$sdir\""
      fi
      if [ -z "$desc" ]; then
        err "$f: missing or empty description in frontmatter"
      fi
    done
    ok "checked skill frontmatter in $dir/skills/"
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "" >&2
  echo "Validation failed. Fix the issues above before merging." >&2
  exit 1
fi

echo ""
echo "All checks passed."
