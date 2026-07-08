#!/bin/bash
# Double-click this file to push ToneVault to GitHub.
# It creates a local git repo (if needed) and pushes to a new GitHub repo.
# If the GitHub CLI (gh) is installed & logged in, this is fully hands-free.

set -e
cd "$(dirname "$0")"
echo "== ToneVault → GitHub =="
echo "Working dir: $(pwd)"
echo

# Clear any stale git lock files (harmless if none exist).
rm -f .git/index.lock .git/HEAD.lock .git/objects/maintenance.lock 2>/dev/null || true

# 1. Local repo
if [ ! -d .git ]; then
  git init -b main
fi
git add -A
if git diff --cached --quiet; then
  echo "Nothing new to commit."
else
  git commit -m "ToneVault 1.0 — offline guitar tone vault (app, tests, docs, App Store assets)"
fi

REPO_NAME="tonevault"

# 2. Remote + push
if git remote get-url origin >/dev/null 2>&1; then
  echo "Remote 'origin' already set: $(git remote get-url origin)"
  git push -u origin main
elif command -v gh >/dev/null 2>&1; then
  echo "Using GitHub CLI to create the repo and push…"
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
else
  cat <<'EOF'

The GitHub CLI (gh) isn't installed, so I can't create the remote automatically.
Do this once:
  1) Create an empty repo at https://github.com/new  (name it: tonevault, no README/.gitignore)
  2) Back in this window run:
       git remote add origin https://github.com/<your-username>/tonevault.git
       git push -u origin main
  (Or install gh:  brew install gh  →  gh auth login  → re-run this script.)
EOF
fi

echo
echo "Done. Press any key to close."
read -n 1 -s
