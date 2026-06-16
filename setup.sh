#!/usr/bin/env bash
# setup.sh — one-shot project setup for Dokkho.
# Generates the dependency lockfile and commits it so every deploy is reproducible.
# Run from inside the project folder:  bash setup.sh
#
# This is safe to run more than once. It won't overwrite your code or secrets.

set -e  # stop on first error

# ── pretty output ──
bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

bold "Dokkho setup"
echo

# ── 1. Check we're in the right place ──
if [ ! -f package.json ]; then
  err "No package.json here. Run this from inside the 'dokkho' project folder:"
  echo "    cd dokkho && bash setup.sh"
  exit 1
fi
ok "Found package.json"

# ── 2. Check Node + npm are installed ──
if ! command -v node >/dev/null 2>&1; then
  err "Node.js is not installed."
  echo "    Install the LTS version from https://nodejs.org , reopen your terminal, and run this again."
  exit 1
fi
NODE_V=$(node -v)
ok "Node.js found ($NODE_V)"

if ! command -v npm >/dev/null 2>&1; then
  err "npm is not installed (it normally comes with Node.js). Reinstall Node from https://nodejs.org"
  exit 1
fi
ok "npm found ($(npm -v))"

# ── 3. Install dependencies + create the lockfile ──
echo
bold "Installing dependencies (this creates package-lock.json)…"
if npm install; then
  ok "Dependencies installed"
else
  err "npm install failed. Check your internet connection and try again."
  exit 1
fi

if [ ! -f package-lock.json ]; then
  err "package-lock.json was not created. Something went wrong with npm install."
  exit 1
fi
ok "Lockfile created"

# ── 4. Commit + push the lockfile (only if this is a git repo) ──
echo
if [ -d .git ]; then
  if git diff --quiet --exit-code package-lock.json 2>/dev/null && git ls-files --error-unmatch package-lock.json >/dev/null 2>&1; then
    ok "Lockfile already committed and unchanged — nothing to push"
  else
    bold "Committing the lockfile…"
    git add package-lock.json
    if git commit -m "Add package-lock.json for reproducible builds"; then
      ok "Committed"
      bold "Pushing to GitHub…"
      if git push; then
        ok "Pushed — your deploy will run automatically"
      else
        warn "Push failed. Run 'git push' yourself once your GitHub remote is set up."
      fi
    else
      warn "Nothing to commit (lockfile may already be committed)."
    fi
  fi
else
  warn "This folder isn't a git repo yet, so the lockfile wasn't pushed."
  echo "    Once you've connected it to GitHub, run:"
  echo "        git add package-lock.json && git commit -m 'Add lockfile' && git push"
fi

# ── 5. Friendly summary ──
echo
bold "Done. What's next:"
echo "  • The lockfile is in place — deploys are now reproducible."
echo "  • To check everything before deploying:   bash verify.sh"
echo "  • Using accounts? Set up email sending:    see SMTP-SETUP.md"
echo
