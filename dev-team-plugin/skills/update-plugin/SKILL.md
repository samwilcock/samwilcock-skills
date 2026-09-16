---
name: update-plugin
description: Pull the latest dev-team plugin source from its marketplace repo and remind the user to reload plugins. Use when the user explicitly asks to update, refresh, or pull the latest dev-team plugin, or invokes /dev-team:update-plugin.
disable-model-invocation: true
---

# Update dev-team plugin

This does the `git pull` half of what `/plugin update dev-team` does, so you don't have to leave the session to check for and pull updates. It cannot do the other half — reloading the running session's plugin registry is a CLI-level action only `/reload-plugins` (typed by the user) can perform. Always tell the user to run that afterward; never claim the update is "live" until they do.

## Steps

1. **Locate the marketplace repo.** Don't hardcode a path — it varies by install. This plugin now ships from a multi-plugin marketplace repo (`samwilcock-skills`), where the top-level `.claude-plugin/marketplace.json` lists a plugin named `dev-team` whose `source` points at a subdirectory (e.g. `./dev-team-plugin`), and that subdirectory has its own `.claude-plugin/plugin.json`. Search `~/.claude/plugins/marketplaces/*/` for a directory whose `.claude-plugin/marketplace.json` lists a plugin with `"name": "dev-team"`, then resolve that entry's `source` against the marketplace directory to get the plugin's actual path. If none is found, tell the user the plugin doesn't look like it was installed from a marketplace clone (e.g. it's a packaged/cache-only install) and stop — there's nothing to pull.
   - If you instead find an old-style install (a marketplace directory whose `.claude-plugin/plugin.json`, not `marketplace.json`, directly has `"name": "dev-team"` at its root — the pre-restructure single-plugin layout), tell the user this looks like a stale marketplace from before the repo became multi-plugin, and that they'll need to remove it and re-add `samwilcock-skills` (`/plugin marketplace remove <old-name>` then `/plugin marketplace add samwilcock/samwilcock-skills`) rather than pulling in place — a plain `git pull` there would fetch a repo whose remote history has moved on to a different layout. Stop; don't attempt the pull yourself in that case.

2. **Check it's a clean git repo.** Run `git status --porcelain` in the marketplace root (not the plugin subdirectory — that's not its own git repo).
   - If it fails (not a git repo), tell the user and stop.
   - If it reports uncommitted changes, stop and show them — don't pull over local edits. Ask whether to stash them first; only proceed if they say yes.

3. **Fetch and fast-forward.** In the marketplace root, run `git fetch origin` then `git merge --ff-only origin/<current-branch>` (use whatever branch is actually checked out, not an assumed `main`). If the fast-forward fails (local commits not on origin), stop and explain — don't force anything.

4. **Report and remind.** Summarize what changed under the plugin's subdirectory specifically (`git log --oneline <old-sha>..<new-sha> -- <plugin-subdirectory>`, or "already up to date"), then tell the user to run `/reload-plugins` to pick it up in this session. If nothing changed, just say so — no need to mention reloading.

Keep this to a handful of commands — it's a maintenance utility, not a pipeline stage. Don't touch any other repo or fall back to searching broadly if the marketplace directory isn't found.
