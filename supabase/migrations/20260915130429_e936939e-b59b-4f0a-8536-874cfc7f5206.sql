CREATE OR REPLACE FUNCTION public.admin_finalize_user(
  _user_id uuid,
  _email text,
  _full_name text,
  _department text,
  _manager_id uuid,
  _role app_role
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;

  INSERT INTO public.profiles (id, email, full_name, department, manager_id)
  VALUES (_user_id, _email, _full_name, _department, _manager_id)
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        department = EXCLUDED.department,
        manager_id = EXCLUDED.manager_id;

  DELETE FROM public.user_roles WHERE user_id = _user_id;
  INSERT INTO public.user_roles (user_id, role) VALUES (_user_id, _role);
END $$;

REVOKE ALL ON FUNCTION public.admin_finalize_user(uuid, text, text, text, uuid, app_role) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_finalize_user(uuid, text, text, text, uuid, app_role) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.admin_email_exists(_email text)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT public.has_role(auth.uid(), 'admin')
     AND EXISTS (SELECT 1 FROM public.profiles p WHERE lower(p.email) = lower(_email));
$$;

REVOKE ALL ON FUNCTION public.admin_email_exists(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_email_exists(text) TO authenticated, service_role;