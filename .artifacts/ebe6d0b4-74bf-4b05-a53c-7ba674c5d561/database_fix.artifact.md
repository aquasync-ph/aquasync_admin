# Supabase SQL Fix (with DROP FUNCTION)

I-paste at i-run ang na-update na SQL script sa Supabase SQL Editor:

```sql
-- 1. Enable pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Drop existing function signature to avoid return type error
DROP FUNCTION IF EXISTS public.create_user_account(text, text, text, text, text, text);
DROP FUNCTION IF EXISTS public.create_user_account;

-- 3. Create the function with correct security & return type
CREATE OR REPLACE FUNCTION public.create_user_account(
    p_email text,
    p_password text,
    p_full_name text,
    p_role text,
    p_phone text DEFAULT NULL,
    p_address text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id uuid;
BEGIN
    new_user_id := gen_random_uuid();

    -- Insert sa auth.users
    INSERT INTO auth.users (
        id, instance_id, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at, role, aud
    ) VALUES (
        new_user_id, '00000000-0000-0000-0000-000000000000',
        p_email, crypt(p_password, gen_salt('bf')), now(),
        '{"provider":"email","providers":["email"]}',
        jsonb_build_object('full_name', p_full_name, 'role', p_role),
        now(), now(), 'authenticated', 'authenticated'
    );

    -- Insert sa public.profiles
    INSERT INTO public.profiles (
        id, full_name, phone, address, role, is_archived, created_at, updated_at
    ) VALUES (
        new_user_id, p_full_name, p_phone, p_address, p_role, false, now(), now()
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        phone = EXCLUDED.phone,
        address = EXCLUDED.address,
        role = EXCLUDED.role,
        updated_at = now();

    RETURN new_user_id;
END;
$$;

-- 4. Enable RLS and add policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read profiles" ON public.profiles;
CREATE POLICY "Allow public read profiles" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow authenticated insert profiles" ON public.profiles;
CREATE POLICY "Allow authenticated insert profiles" ON public.profiles FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated update profiles" ON public.profiles;
CREATE POLICY "Allow authenticated update profiles" ON public.profiles FOR UPDATE USING (true) WITH CHECK (true);
```
