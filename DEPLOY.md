# Deploy guide — GitHub Actions → Vercel

This sets up automatic deploys so you push to GitHub and your live site updates
on its own. You only touch the Vercel dashboard once, to create the project and
get three IDs.

## ⚠️ Before you start — two things to do once

**1. Generate a lockfile (run once, locally).** This isn't committed yet because it
must be created on a machine with internet so npm can resolve exact versions. Run:

```bash
npm install            # creates package-lock.json
git add package-lock.json && git commit -m "Add lockfile" && git push
```

Why it matters: with a lockfile, every build installs the *exact* same dependency
versions (`npm ci`), so a deploy that works today still works in six months. The
deploy workflow runs fine without it (it falls back to `npm install`), but builds
won't be reproducible until you commit it. Do this before sharing the app widely.

**2. If you turn on accounts (Supabase), set up email sending.** Supabase's built-in
email sender has a low rate limit (a handful of magic-link emails per hour) meant
only for testing. The moment real users start signing in, those emails silently stop.
Before launch, configure your own SMTP sender:

- Supabase dashboard → **Authentication → Emails → SMTP Settings** → enable custom SMTP.
- Use any provider's free tier — e.g. Resend, Brevo (Sendinblue), Mailgun, or
  Amazon SES. Paste the host, port, username, and password they give you.
- Send yourself a test magic link to confirm it arrives.

Skip this only if you're not using accounts at all (the app works in local-only mode
without Supabase — see SUPABASE.md).

---

## One-time setup

### 1. Create the Vercel project (once)
The simplest path is to link the project locally so Vercel generates the IDs:

```bash
npm install -g vercel
vercel login
vercel link        # answer the prompts; pick "create new project" if needed
```

This creates a `.vercel/project.json` file containing your **orgId** and
**projectId**. Open it and note both values:

```bash
cat .vercel/project.json
```

### 2. Create a Vercel access token
Go to https://vercel.com/account/tokens → "Create Token". Copy it (you won't see
it again).

### 3. Add the secrets to GitHub
In your GitHub repo: **Settings → Secrets and variables → Actions → New repository secret**.
Add these:

| Secret name          | Value                                             |
|----------------------|---------------------------------------------------|
| `VERCEL_TOKEN`       | the access token from step 2                      |
| `VERCEL_ORG_ID`      | `orgId` from `.vercel/project.json`               |
| `VERCEL_PROJECT_ID`  | `projectId` from `.vercel/project.json`           |

### 4. Add the app's environment variables in Vercel
In the Vercel dashboard → your project → **Settings → Environment Variables**, add:

| Variable               | Required? | Notes                                                    |
|------------------------|-----------|----------------------------------------------------------|
| `ANTHROPIC_API_KEY`    | **Yes**   | your key from console.anthropic.com                      |
| `AUTH_SECRET`          | Recommended | random string: `openssl rand -hex 32`                  |
| `DAILY_LIMIT`          | No        | AI calls per device per day (default 60)                 |
| `BURST_LIMIT`          | No        | AI calls per device per minute (default 8)               |
| `UPSTASH_REDIS_REST_URL`  | No     | for shared rate limiting across instances (see below)    |
| `UPSTASH_REDIS_REST_TOKEN`| No     | paired with the URL above                                |

> The GitHub Action builds and deploys; the runtime secrets above live in Vercel
> and are injected at run time. Keep `ANTHROPIC_API_KEY` in Vercel, not in the
> Action, so it's never exposed in build logs.

## After setup

- **Every push to `main`** triggers a deploy automatically.
- You can also deploy manually: GitHub repo → **Actions** tab → "Deploy to Vercel"
  → "Run workflow".
- No more dashboard visits needed for routine deploys.

---

## How the security layer works

### Anonymous device auth
The app calls `/api/token` once on first load and receives a signed token (an
HMAC — it can't be forged without your `AUTH_SECRET`). That token is stored on the
device and sent with every AI request. The proxy rejects any request without a
valid token, so random scrapers who find your URL can't burn your API budget.

This is **not** user login — there are no passwords or accounts. It's a gate plus a
per-device meter. When you're ready for paid tiers or saving progress to the cloud,
swap this for real accounts (the token check is the natural place to plug them in).

### Rate limiting
Each device gets a daily cap (`DAILY_LIMIT`) and a short-window burst cap
(`BURST_LIMIT`). Two modes:

- **Best-effort (default):** counts are kept in each serverless instance's memory.
  Good enough for small scale and costs nothing.
- **Shared (recommended once you have real traffic):** set the two `UPSTASH_*`
  variables. Create a free Redis database at https://upstash.com, copy its REST URL
  and token. Now limits are enforced accurately across all instances.

If the limiter backend is ever unreachable, the proxy **fails open** (lets the
request through) rather than blocking everyone — availability over strictness.

### Tuning costs
Every AI call is billed. The offline course download caches lessons so re-reading
is free. If costs climb, lower `DAILY_LIMIT`, rely on the offline cache, and
consider reserving the larger models only for proposal writing (where quality most
directly converts to a learner's income).
