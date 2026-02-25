#!/usr/bin/env bash
set -e

git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not a git repository." >&2; exit 1; }

default_branch="main"
git rev-parse --verify refs/heads/main &>/dev/null || default_branch="master"

git branch --merged "$default_branch" \
  | grep -Fv "$default_branch" \
  | grep -vF '*' \
  | grep -vF '+' \
  | xargs git branch -d \
  && git fetch \
  && git remote prune origin \
  && git branch -v \
  | grep -F '[gone]' \
  | grep -vF '*' \
  | grep -vF '+' \
  | awk '{print $1}' \
  | xargs git branch -D
