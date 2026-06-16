# SMTP setup — make login emails actually send

You only need this if you turned on accounts (Supabase). It takes ~15 minutes,
most of which is waiting for DNS to verify. Two parts: get credentials from an
email provider, then paste them into Supabase.

We'll use **Resend** (simplest free tier: ~3,000 emails/month, ~100/day). Brevo,
Mailgun, and Amazon SES work identically — any provider gives you the same four
values: host, port, username, password.

---

## Part A — Get SMTP credentials from Resend

1. Go to **https://resend.com** and sign up (Google login or email).

2. **Add your domain.** Left sidebar → **Domains** → **Add Domain**. Type the
   domain you'll send from, e.g. `yourdomain.com`. (You need to own a domain. If
   you don't have one yet, buy a cheap one — Namecheap, Cloudflare, Porkbun — for
   a few dollars a year. You can't reliably send login emails from a free address
   like gmail.com.)

3. **Verify the domain.** Resend shows you a few DNS records (usually 3: an MX-style
   record and two for DKIM/SPF). Copy each one into your domain registrar's DNS
   settings:
   - Registrar dashboard → DNS / DNS records → Add record.
   - For each Resend record, match the **Type** (TXT, MX, or CNAME), **Name/Host**,
     and **Value** exactly. Leave TTL default.
   - Save, then go back to Resend and click **Verify**. It may say "pending" —
     that's normal. DNS can take a few minutes to a few hours. Re-check until all
     records show a green check.

4. **Create the SMTP credentials.** Left sidebar → **API Keys** → **Create API Key**
   (give it any name, e.g. "dokkho-login"). Copy the key now — you won't see it
   again. This key is your SMTP **password**.

5. Your four values are:
   | Field    | Value                              |
   |----------|------------------------------------|
   | Host     | `smtp.resend.com`                  |
   | Port     | `465`                              |
   | Username | `resend`                           |
   | Password | the API key you just copied        |

   And a **sender address** on your verified domain, e.g. `login@yourdomain.com`.

---

## Part B — Paste them into Supabase

1. Supabase dashboard → your project → **Authentication** (left sidebar) →
   **Emails** → **SMTP Settings**.

2. Toggle **Enable Custom SMTP** on.

3. Fill in:
   - **Sender email:** `login@yourdomain.com` (must be on the verified domain)
   - **Sender name:** `Dokkho`
   - **Host:** `smtp.resend.com`
   - **Port number:** `465`
   - **Username:** `resend`
   - **Password:** your Resend API key

4. Click **Save**.

---

## Part C — Test it

1. Open your live app (the Vercel URL).
2. Go to the **Me** tab → the **Account** card.
3. Enter your own email → **Send login link**.
4. Check your inbox. A magic-link email should arrive within a minute. Tap the link
   — it should log you in and the card should switch to "Syncing across your
   devices ✓".

If it doesn't arrive:
- Check spam/junk.
- Confirm the **Sender email** domain exactly matches the domain you verified in
  Resend (a mismatch is the #1 cause of silent failures).
- In Resend → **Logs**, you can see whether the email was accepted or bounced.
- If your app shows "Too many requests, try again in a few minutes," custom SMTP
  isn't active yet — recheck that the toggle in Part B is on and saved.

---

## Optional: friendlier email text

Supabase → Authentication → Emails → **Magic Link** template. You can edit the
subject and body (and translate it to Bangla) so the login email feels like it
comes from Dokkho, not a generic system. Keep the `{{ .ConfirmationURL }}`
placeholder — that's the actual login link.
