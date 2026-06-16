# Operator dashboard

A private control room at **`/dashboard`** (e.g. `https://your-app.vercel.app/dashboard`).
It shows live usage analytics, abuse signals, cost levers, and a catalog of every
feature in the app. It's password-protected and reads data server-side, so analytics
are never exposed to regular users.

## What it shows

- **Overview** — headline numbers (active devices, tools run, lessons completed,
  certificates, rate-limited calls) and a 14-day activity trend.
- **Usage** — which freelance tools and which learning tracks people actually use,
  plus a full breakdown of every tracked action.
- **Abuse & cost** — devices with unusually high volume in the last 24h, and your
  levers for controlling API spend.
- **Features** — a catalog of all tools, tracks, and platform capabilities, with
  real usage counts next to each.

## Setup (one time)

The dashboard works in **two modes**:

### Minimum — password only (shows demo data)
Set one environment variable in Vercel → Settings → Environment Variables:

| Variable         | Value                          |
|------------------|--------------------------------|
| `ADMIN_PASSWORD` | any strong password you choose |

Visit `/dashboard`, enter the password, and you'll see the full dashboard populated
with **sample data** — useful to explore the layout immediately.

### Full — real analytics
To show real usage, the dashboard needs to read your `events` table. Add two more
**secret** variables (these must NOT start with `VITE_` and are never sent to the
browser):

| Variable                    | Where to get it                                   |
|-----------------------------|---------------------------------------------------|
| `SUPABASE_URL`              | Supabase → Settings → API → Project URL           |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Settings → API → **service_role** key  |

> The service_role key bypasses row-level security, which is exactly why it lives
> only on the server (in the `/api/admin` function) and never in frontend code.
> Treat it like a password.

Requires that you've already set up Supabase and run `supabase/schema.sql`
(see SUPABASE.md). Redeploy after adding the variables.

## Security notes

- The dashboard page is marked `noindex` so search engines don't list it.
- All analytics reads go through `/api/admin`, which checks `ADMIN_PASSWORD` on
  every request. The browser never receives the service key or raw event rows it
  isn't authorized to see.
- The password is held in the browser's session storage only (cleared when the tab
  closes). For stronger protection later, swap the password gate for real admin
  accounts (Supabase Auth with an allow-list).

## Deploy

No extra steps — the dashboard builds and deploys with the rest of the app. The
existing GitHub Actions → Vercel workflow ships it automatically. After deploy it's
live at `/dashboard`.
