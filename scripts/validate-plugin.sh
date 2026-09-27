#!/usr/bin/env bash
# Validates the root marketplace manifest, every plugin's manifest/agent/skill
# frontmatter, and the format of CHANGELOG.md in this repo.
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

# ---------- CHANGELOG.md ----------
# Every "## " heading must be "## [<plugin> <major.minor.patch>] - <YYYY-MM-DD>"
# for a plugin in marketplace.json, appear once, and have at least one bullet.
# "### " headings must be Added, Changed, Fixed or Removed, with content under
# them. Keeps release notes consistent and catches unfilled bump-version.sh stubs.
echo ""
echo "-- checking CHANGELOG.md --"
if [ ! -f CHANGELOG.md ]; then
  err "CHANGELOG.md is missing"
else
  plugin_names=$(jq -r '.plugins[].name' "$MARKET_JSON" | tr '\n' ' ')
  changelog_errors=$(awk -v names=" $plugin_names" '
    function close_sub() {
      if (sub_heading != "" && !sub_has_content)
        print "line " sub_line ": \"" sub_heading "\" has nothing under it - fill it in or delete it"
      sub_heading = ""
    }
    function close_section() {
      close_sub()
      if (section != "" && !bullets)
        print "line " section_line ": \"" section "\" has no bullet points"
      section = ""
    }
    /^## / {
      close_section()
      section = $0; section_line = NR; bullets = 0
      if ($0 !~ /^## \[[a-z0-9-]+ [0-9]+\.[0-9]+\.[0-9]+\] - [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) {
        print "line " NR ": \"" $0 "\" should look like \"## [<plugin> <version>] - <YYYY-MM-DD>\""
        next
      }
      split(substr($0, 5), parts, /[] ]/)
      if (index(names, " " parts[1] " ") == 0)
        print "line " NR ": \"" parts[1] "\" is not a plugin in marketplace.json"
      key = parts[1] " " parts[2]
      if (key in seen) print "line " NR ": \"" key "\" also appears on line " seen[key]
      else seen[key] = NR
      next
    }
    /^### / {
      close_sub()
      sub_heading = $0; sub_line = NR; sub_has_content = 0
      if ($0 !~ /^### (Added|Changed|Fixed|Removed)$/)
        print "line " NR ": \"" $0 "\" should be one of ### Added, ### Changed, ### Fixed, ### Removed"
      next
    }
    /^[[:space:]]*$/ { next }
    {
      if (sub_heading != "") sub_has_content = 1
      if (section != "" && /^- /) bullets = 1
    }
    END { close_section() }
  ' CHANGELOG.md)
  if [ -n "$changelog_errors" ]; then
    while IFS= read -r line; do err "CHANGELOG.md $line"; done <<< "$changelog_errors"
  else
    ok "CHANGELOG.md headings and sections are well formed"
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo "" >&2
  echo "Validation failed. Fix the issues above before merging." >&2
  exit 1
fi

echo ""
echo "All checks passed."
