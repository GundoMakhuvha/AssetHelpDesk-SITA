# New deployment checklist (e.g. SITA)

## 1. Create and connect your backend
- Create a new project at supabase.com.
- Copy the Project URL and anon/publishable key (Project Settings → API).
- Copy `.env.example` → fill in `VITE_SUPABASE_*` and `SUPABASE_*`.

## 2. Run the schema
- Open `supabase/portable/20261003000000_baseline_schema.sql` and review it
  (the header lists the 3 differences from the original deployment).
- Run it once in Supabase → SQL Editor. (Or copy it into an empty
  `supabase/migrations/` folder and run `supabase db push`.)
- Do **not** run the older files in `supabase/migrations/` — they are the
  original deployment's history and are fully replaced by the baseline.

## 3. Password-reset secret
- Generate a random string: `openssl rand -hex 24`.
- Set it as `APP_MAIL_SECRET` in your host.
- In the SQL Editor run:
  `insert into public.app_secrets (key, value) values ('mail_secret', '<same value>');`

## 4. Create the first admin
- Deploy the app, open it and sign up with your own email (or create the user
  in Supabase → Authentication → Users).
- The very first account automatically becomes **admin**; later accounts
  start as **requestor**. Add everyone else from Setup → Users & Roles.

## 5. Auth redirect URLs
In Supabase → Authentication → URL Configuration:
- Site URL: your `VITE_APP_URL`
- Redirect URLs: `https://your-domain/*` (covers `/login`, `/set-password`, `/reset-password`)
- Optional: turn off "Confirm email" if admins create all users.

## 6. Email
- Create a Resend account, verify your sending domain (DNS records).
- Set `RESEND_API_KEY`, `RESEND_FROM`, `SERVICE_DESK_EMAILS`.

## 7. Branding
- Put your logo in `/public` and set `VITE_ORG_LOGO_URL`, plus the other
  `VITE_ORG_*` values. Redeploy after changing any variable.
- In the app: Setup → Help Desk to set organisation name, support email,
  business hours, timezone, and SLA targets.
