---
name: update-plugin
description: Pull the latest dev-team plugin source from its marketplace repo and remind the user to reload plugins. Use when the user explicitly asks to update, refresh, or pull the latest dev-team plugin, or invokes /dev-team:update-plugin.
disable-model-invocation: true
---

# Update dev-team plugin

This does the `git pull` half of what `/plugin update dev-team` does, so you don't have to leave the session to check for and pull updates. It cannot do the other half — reloading the running session's plugin registry is a CLI-level action only `/reload-plugins` (typed by the user) can perform. Always tell the user to run that afterward; never claim the update is "live" until they do.

## Steps

1. **Locate the marketplace repo.** Don't hardcode a path — it varies by install. Search `~/.claude/plugins/marketplaces/*/` for a directory whose `.claude-plugin/plugin.json` has `"name": "dev-team"`. If none is found, tell the user the plugin doesn't look like it was installed from a marketplace clone (e.g. it's a packaged/cache-only install) and stop — there's nothing to pull.

2. **Check it's a clean git repo.** Run `git status --porcelain` in that directory.
   - If it fails (not a git repo), tell the user and stop.
   - If it reports uncommitted changes, stop and show them — don't pull over local edits. Ask whether to stash them first; only proceed if they say yes.

3. **Fetch and fast-forward.** Run `git fetch origin` then `git merge --ff-only origin/<current-branch>` (use whatever branch is actually checked out, not an assumed `main`). If the fast-forward fails (local commits not on origin), stop and explain — don't force anything.

4. **Report and remind.** Summarize what changed (`git log --oneline <old-sha>..<new-sha>`, or "already up to date"), then tell the user to run `/reload-plugins` to pick it up in this session. If nothing changed, just say so — no need to mention reloading.

Keep this to a handful of commands — it's a maintenance utility, not a pipeline stage. Don't touch any other repo or fall back to searching broadly if the marketplace directory isn't found.
