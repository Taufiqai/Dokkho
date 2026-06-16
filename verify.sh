#!/usr/bin/env bash
# verify.sh — pre-deploy checkup for Dokkho.
# Reports what's ready and what still needs doing. Read-only: it changes nothing.
# Run from inside the project folder:  bash verify.sh

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }
info() { printf "    %s\n" "$1"; }

PROBLEMS=0
note() { PROBLEMS=$((PROBLEMS+1)); }

bold "Dokkho pre-deploy check"
echo

# ── Project structure ──
bold "Project files"
for f in package.json index.html vite.config.js src/Dokkho.jsx api/chat.js; do
  if [ -f "$f" ]; then ok "$f"; else err "missing $f"; note; fi
done
echo

# ── Lockfile (reproducible builds) ──
bold "Lockfile"
if [ -f package-lock.json ]; then
  ok "package-lock.json present"
  if [ -d .git ] && ! git ls-files --error-unmatch package-lock.json >/dev/null 2>&1; then
    warn "Lockfile exists but isn't committed to git."
    info "Run: git add package-lock.json && git commit -m 'Add lockfile' && git push"
    note
  fi
else
  warn "No package-lock.json — builds won't be reproducible."
  info "Run: bash setup.sh"
  note
fi
echo

# ── Local env file (for local dev only; production uses host env vars) ──
bold "Local environment (optional — only for 'vercel dev')"
if [ -f .env.local ]; then
  ok ".env.local present"
  grep -q "ANTHROPIC_API_KEY=sk-" .env.local 2>/dev/null \
    && ok "ANTHROPIC_API_KEY looks set" \
    || warn "ANTHROPIC_API_KEY not set in .env.local (fine if you only deploy to Vercel)"
  if grep -q "VITE_SUPABASE_URL=https" .env.local 2>/dev/null; then
    ok "Supabase configured locally — accounts/sync/analytics will be active"
  else
    info "Supabase not set locally — app runs in local-only mode (that's OK)."
  fi
else
  info "No .env.local — that's fine; production reads secrets from your host (Vercel)."
fi
echo

# ── Secrets hygiene ──
bold "Secrets hygiene"
if [ -f .gitignore ] && grep -q ".env" .gitignore; then
  ok ".env files are gitignored"
else
  err ".env is NOT gitignored — you risk committing secrets!"
  info "Add a line '.env.local' to .gitignore"
  note
fi
if [ -d .git ] && git ls-files 2>/dev/null | grep -qE "^\.env(\.|$)"; then
  err "An .env file is tracked by git — remove it: git rm --cached .env.local"
  note
else
  ok "No .env file committed to git"
fi
echo

# ── Reminders that can't be auto-checked ──
bold "Manual reminders (can't be checked from here)"
info "□ Vercel env var ANTHROPIC_API_KEY is set (Vercel → Settings → Environment Variables)"
info "□ Using accounts? Custom SMTP is configured in Supabase  → see SMTP-SETUP.md"
info "□ Using accounts? schema.sql has been run in Supabase   → see SUPABASE.md"
info "□ Dashboard: ADMIN_PASSWORD set in Vercel (+ SUPABASE_URL & SERVICE_ROLE_KEY for live data) → see DASHBOARD.md"
echo

# ── Summary ──
if [ "$PROBLEMS" -eq 0 ]; then
  bold "All automated checks passed. Review the manual reminders above, then deploy."
else
  bold "Found $PROBLEMS thing(s) to fix above before deploying."
fi
echo
