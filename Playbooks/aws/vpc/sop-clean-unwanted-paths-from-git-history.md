---
title: "SOP - Clean unwanted paths from Git history"
tags:
  - sop
  - git
  - security
aliases:
  - "Remove unwanted paths from git history"
  - "Remove unwanted commits for folders"
created: 2026-02-20
---

# SOP - Clean unwanted paths from Git history (macOS)

Use this when you accidentally committed files you never want in history (examples: `.obsidian/`, `tmp/`, `.env`, keys).

> [!danger] History rewrite
> This rewrites history (commit hashes change). Coordinate with teammates before force-pushing.

> [!warning] Secrets
> If secrets were committed, rotate them even after cleaning history.

## Quick checklist

- [ ] Identify unwanted paths and branch
- [ ] Stop tracking going forward (`.gitignore` + `git rm --cached`)
- [ ] Rewrite history to remove paths everywhere
- [ ] Prune old refs/objects
- [ ] Verify paths are gone
- [ ] Force-push and coordinate (if remote)

## Inputs

- Unwanted paths: `.obsidian/`, `tmp/` (edit as needed)
- Target: current branch, or `--all` history

## 1) Find commits that touched a path

List commits that touched either `.obsidian/` or `tmp/`:

```bash
git log --oneline -- .obsidian tmp
```

Show commit + changed files:

```bash
git log --name-status -- .obsidian tmp
```

Find objects still reachable (useful to verify after cleanup):

```bash
git rev-list --objects --all | grep -E '/\.obsidian/|[[:space:]]\.obsidian/|[[:space:]]tmp/' || true
```

## 2) Stop tracking going forward (optional but recommended)

Add the paths to `.gitignore`, then untrack them (keep on disk):

```bash
git rm -r --cached -- .obsidian tmp
git commit -m "chore: stop tracking unwanted paths"
```

This does **not** remove past commits. Continue to the next step to remove from history.

## 3) Make a backup branch (recommended)

```bash
git branch backup/pre-history-rewrite-$(date +%F)
```

## 4) Rewrite history to remove paths everywhere

Preferred tool: `git filter-repo` (recommended by Git).

If `git filter-repo` is available:

```bash
git filter-repo --force --path .obsidian --path tmp --invert-paths
```

Fallback (built-in, but has caveats): `git filter-branch`:

```bash
git filter-branch --force --index-filter \
  "git rm -r --cached --ignore-unmatch .obsidian tmp" \
  --prune-empty --tag-name-filter cat -- --all
```

## 5) Remove old references and prune unreachable objects

After a rewrite, the old commits may still be referenced by backup refs/reflogs unless you clean them:

```bash
rm -rf .git/refs/original .git/logs/refs/original
git reflog expire --expire=now --all
git gc --prune=now
```

## 6) Verify it worked

These should produce no output:

```bash
git log --oneline -- .obsidian tmp
git rev-list --objects --all | grep -E '/\.obsidian/|[[:space:]]\.obsidian/|[[:space:]]tmp/' || true
```

## 7) Push rewritten history (if you have a remote)

```bash
git push --force-with-lease --all
git push --force-with-lease --tags
```

Tell collaborators to re-clone, or to reset their local branches to the new history.
