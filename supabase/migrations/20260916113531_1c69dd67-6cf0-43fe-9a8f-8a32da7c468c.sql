CREATE TABLE IF NOT EXISTS public.app_secrets (
  key text PRIMARY KEY,
  value text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.app_secrets ENABLE ROW LEVEL SECURITY;
GRANT ALL ON public.app_secrets TO service_role;

INSERT INTO public.app_secrets (key, value)
VALUES ('mail_secret', 'ba943c61b0f14061ed468fe286e4edca903b8af8abd0837a')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

CREATE TABLE IF NOT EXISTS public.password_reset_tokens (
  token text PRIMARY KEY,
  user_id uuid NOT NULL,
  email text NOT NULL,
  expires_at timestamptz NOT NULL DEFAULT (now() + '10 minutes'::interval),
  used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.password_reset_tokens ENABLE ROW LEVEL SECURITY;
GRANT ALL ON public.password_reset_tokens TO service_role;

CREATE OR REPLACE FUNCTION public.create_password_reset_token(_email text, _secret text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_user uuid;
  v_token text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.app_secrets WHERE key = 'mail_secret' AND value = _secret) THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  SELECT id INTO v_user FROM auth.users WHERE lower(email) = lower(_email) LIMIT 1;
  IF v_user IS NULL THEN
    RETURN NULL;
  END IF;

  v_token := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  INSERT INTO public.password_reset_tokens (token, user_id, email)
  VALUES (v_token, v_user, lower(_email));
  RETURN v_token;
END;
$$;

REVOKE ALL ON FUNCTION public.create_password_reset_token(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_password_reset_token(text, text) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.redeem_password_reset(_token text, _new_password text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  r public.password_reset_tokens%ROWTYPE;
BEGIN
  IF _new_password IS NULL OR length(_new_password) < 8 THEN
    RAISE EXCEPTION 'Password must be at least 8 characters.';
  END IF;

  SELECT * INTO r FROM public.password_reset_tokens
  WHERE token = _token AND used_at IS NULL AND expires_at > now();

  IF r.token IS NULL THEN
    RAISE EXCEPTION 'This password reset link is invalid or has expired.';
  END IF;

  UPDATE auth.users
     SET encrypted_password = extensions.crypt(_new_password, extensions.gen_salt('bf')),
         updated_at = now()
   WHERE id = r.user_id;

  UPDATE public.password_reset_tokens SET used_at = now() WHERE token = r.token;
  RETURN r.email;
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_password_reset(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_password_reset(text, text) TO anon, authenticated, service_role;