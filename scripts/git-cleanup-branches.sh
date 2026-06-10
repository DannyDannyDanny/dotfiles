#!/usr/bin/env bash
set -euo pipefail

git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not a git repository." >&2; exit 1; }

default_branch="main"
git rev-parse --verify refs/heads/main &>/dev/null || default_branch="master"

# Delete local branches already merged into the default branch.
# `|| true` because grep exits 1 when nothing matches (no branches to clean).
merged=$(git branch --merged "$default_branch" \
  | grep -Fv "$default_branch" \
  | grep -vF '*' \
  | grep -vF '+' \
  || true)
if [ -n "$merged" ]; then
  echo "$merged" | xargs git branch -d
fi

git fetch
git remote prune origin

# Delete local branches whose upstream is gone.
gone=$(git branch -v \
  | grep -F '[gone]' \
  | grep -vF '*' \
  | grep -vF '+' \
  | awk '{print $1}' \
  || true)
if [ -n "$gone" ]; then
  echo "$gone" | xargs git branch -D
fi
