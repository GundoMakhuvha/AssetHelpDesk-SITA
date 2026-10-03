# Project rules

- All organisation-specific values (name, logo, emails, app URL, file prefixes) come from `src/lib/org-config.ts` via `VITE_ORG_*` / `VITE_APP_URL` env vars — so a deployment can be rebranded without code edits.
- Backend URL/keys are read only from env vars, never hard-coded — so each deployment can point at its own backend.
- `supabase/portable/` holds the clean from-scratch baseline schema for new deployments; keep it in sync when schema changes — so new organisations can be provisioned without replaying history.
- Server-function files must not use the `*.client.ts` suffix under src/lib — TanStack import protection rejects it.
