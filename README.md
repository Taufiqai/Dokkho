# দক্ষ — Dokkho

A freelancing co-pilot and adaptive skills academy for Bangladeshi youth.
Bilingual (বাংলা / English), mobile-first, and works offline once a course is downloaded.

- **Get Work** — AI help with Upwork/Fiverr proposals, client replies, English polishing, and quality-checking.
- **Learn** — an adaptive AI tutor for Coding, Digital Marketing, English, and Customer Service, with quizzes and certificates.
- **Offline** — download a whole course and study with no internet (cached in the browser via IndexedDB; the app shell is a PWA).
- **Accounts & sync** — optional passwordless login syncs progress and certificates across devices (see SUPABASE.md).
- **Analytics** — optional, privacy-light usage tracking so you can see what people use and spot abuse (see SUPABASE.md).
- **Coursera links** — each learning track links to verified, recognized Coursera courses to go deeper.
- **Operator dashboard** — a private `/dashboard` showing usage analytics, abuse signals, and a feature catalog (see DASHBOARD.md).

---

## What you need before deploying

1. A free **GitHub** account.
2. A free **Vercel** account (sign in with GitHub).
3. An **Anthropic API key** from https://console.anthropic.com/settings/keys (this is the only secret; it powers the AI).

You do **not** need to know how to code to deploy this. Follow the steps.

> **Quick start helpers** (run from inside the project folder):
> - `bash setup.sh` — installs dependencies, creates the lockfile, and commits it for you.
> - `bash verify.sh` — checks everything is configured correctly before you deploy.
> - **SMTP-SETUP.md** — click-by-click guide to make login emails send (only if using accounts).

> **Want automatic deploys** (push to GitHub → site updates itself, no dashboard)?
> See **DEPLOY.md** for the GitHub Actions setup. The steps below are the manual path.

> **Security:** this build includes anonymous device auth + per-device rate limiting,
> so it's safe to share the URL publicly. See the "How the security layer works"
> section in DEPLOY.md.

---

## Deploy to Vercel (recommended, ~15 minutes)

### 1. Put the code on GitHub
- Create a new repository on GitHub (e.g. `dokkho`), keep it private if you like.
- Upload all the files in this folder to it. Easiest way without tools: on the repo page, "Add file" → "Upload files" → drag everything in, commit.
  - If you use the command line instead:
    ```bash
    git init
    git add .
    git commit -m "Dokkho initial"
    git branch -M main
    git remote add origin https://github.com/YOUR_NAME/dokkho.git
    git push -u origin main
    ```

### 2. Import the project on Vercel
- Go to https://vercel.com → "Add New… → Project".
- Pick your `dokkho` repo. Vercel auto-detects Vite — leave the build settings as they are.
- **Before clicking Deploy**, open "Environment Variables" and add:
  - Name: `ANTHROPIC_API_KEY`
  - Value: your key (`sk-ant-...`)
- Click **Deploy**. In about a minute you get a live URL like `https://dokkho.vercel.app`.

That's it. Every time you push a change to GitHub, Vercel rebuilds automatically.

---

## Run it on your own computer first (optional)

```bash
npm install
cp .env.example .env.local      # then paste your real key into .env.local
npm run dev                     # open the printed localhost URL
```

> Note: the AI proxy at `/api/chat` runs on Vercel/Netlify. For full local testing
> of the API, use `vercel dev` (install the Vercel CLI: `npm i -g vercel`). Plain
> `npm run dev` serves the frontend; the academy lessons need the API to be reachable.

---

## Deploy to Netlify instead (alternative)

1. Move the proxy: this project already includes `netlify/functions/chat.js`, and
   `netlify.toml` maps `/api/chat` to it — no code change needed.
2. On https://netlify.com → "Add new site → Import an existing project" → pick the repo.
3. Add the environment variable `ANTHROPIC_API_KEY` under Site settings → Environment.
4. Deploy.

---

## How it's put together

```
dokkho/
  api/chat.js               Vercel serverless proxy — holds your API key
  netlify/functions/chat.js Netlify version of the same proxy
  src/
    Dokkho.jsx              the whole app (UI + logic)
    storage.js              IndexedDB storage (offline course cache)
    main.jsx                React entry point
  public/                   icons + favicon (PWA install assets)
  index.html                page shell
  vite.config.js            build + PWA service worker config
  vercel.json / netlify.toml host configs
```

**The key never touches the browser.** The app calls your own `/api/chat`
endpoint; that endpoint adds the secret key and forwards to Anthropic.

---

## Costs to keep in mind

Every proposal, lesson, tutor answer, and quiz is a paid Anthropic API call.
The offline download generates a course's lessons once and caches them, which is
your main lever for controlling cost — a downloaded course costs nothing to
re-read. For real scale, add user accounts and per-user rate limits so one person
can't run up the bill, and consider caching common tutor questions.

---

## Going further (not required to launch)

- **Verified certificates:** add a database and a public `/verify/:id` page so a
  certificate means something to an employer.
- **Resumable downloads:** if a download drops mid-way, resume instead of restart.
- **Content versioning:** the cache already stores a version (`v: 1`); bump it when
  you update a course and prompt learners to re-download only the changed parts.
- **Analytics & payments:** integrate bKash for any paid tiers, and basic usage
  analytics to see which tracks land.
