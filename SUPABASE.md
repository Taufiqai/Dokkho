# Accounts, sync & analytics setup (Supabase)

This is **optional**. Without it, Dokkho works fully in local mode — progress and
certificates live on the device. Add Supabase to unlock:

- **Real accounts** (passwordless email login)
- **Cross-device sync** — start on a phone, continue on a library PC
- **Usage analytics** — see which tools/tracks people use, and spot abuse

Takes about 10 minutes.

## 1. Create a Supabase project
Go to https://supabase.com → New project (the free tier is enough). Pick a region
close to your users (Singapore/Mumbai for Bangladesh). Wait for it to provision.

## 2. Create the database tables
In the Supabase dashboard → **SQL Editor** → New query → paste the entire contents
of `supabase/schema.sql` from this repo → **Run**. This creates:
- `learner_state` — one row per user (profile, progress, certificates), locked so
  each user can only read/write their own row.
- `events` — analytics. Anyone can write an event; nobody can read them through the
  public API (you read them in the dashboard), so users can't scrape each other.
- Two ready-made views: `usage_by_action` and `high_volume_devices`.

## 3. Turn on email login
Dashboard → **Authentication → Providers → Email** → make sure it's enabled.
Magic links work out of the box for testing.

> **⚠️ Required before launch — custom email sender.** Supabase's built-in email
> service is rate-limited to a few messages per hour and is for testing only. Once
> real learners start signing in, magic-link emails will silently fail. Set up your
> own SMTP under **Authentication → Emails → SMTP Settings** using any free-tier
> provider (Resend, Brevo, Mailgun, Amazon SES). Send yourself a test link to
> confirm delivery. Until you do this, only a handful of people can sign in per hour.

## 4. Add the keys to your app
Dashboard → **Settings → API**. Copy:
- **Project URL** → `VITE_SUPABASE_URL`
- **anon / public key** → `VITE_SUPABASE_ANON_KEY`

Set both in Vercel → Settings → Environment Variables (and in `.env.local` for local
dev). These are *public* values — safe in the browser because row-level security
guards the data. **Never** put the `service_role` key in the frontend.

Redeploy. The Profile tab now shows an "Account" card; signing in syncs everything.

## 5. Reading your analytics
Dashboard → **SQL Editor**, then for example:

```sql
-- What people actually use (last 30 days)
select * from usage_by_action;

-- Funnel: opens vs completes per track
select props->>'track' as track,
       count(*) filter (where name = 'open_lesson')     as opened,
       count(*) filter (where name = 'complete_lesson')  as completed
from events
where created_at > now() - interval '30 days'
group by 1;

-- Possible abuse: very high-volume devices in the last 24h
select * from high_volume_devices;

-- Daily active devices
select date_trunc('day', created_at) as day,
       count(distinct device_id) as devices
from events group by 1 order by 1 desc;
```

### What gets logged
Only lightweight signals — **never the content** of proposals, messages, or lessons:
`view_tab`, `open_tool`, `run_tool`, `copy_result`, `rate_limited`, `open_track`,
`download_course`, `open_lesson`, `complete_lesson`, `ask_tutor`, `take_quiz`,
`earn_cert`, `open_coursera`, `sign_in`, `request_login_link`, `save_profile`.
Each carries an anonymous device id (and the user id once signed in) plus small
props like which tool or track. This is enough to understand usage and catch abuse
without storing anything sensitive.

## Privacy note
Tell your users, in plain language, what you collect. A short line in the app or a
linked page is good practice (and required in many places): you store their
progress and certificates against their email, and anonymous usage counts to improve
the app. No message content is stored.
