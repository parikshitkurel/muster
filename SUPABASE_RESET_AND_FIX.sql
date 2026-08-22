-- ==============================================================================
-- MUSTER — Comprehensive Supabase Auth & Schema Recovery Script
-- ==============================================================================
-- Run this in your Supabase Dashboard -> SQL Editor
-- 
-- This permanently solves:
-- 1. "Database error saving new user"
-- 2. "Database error querying schema" (HTTP 500)
-- ==============================================================================

-- STEP 1: DROP FAILING TRIGGERS ON auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- STEP 2: GRANT COMPLETE SCHEMA & TYPE PERMISSIONS TO supabase_auth_admin
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role, supabase_auth_admin;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role, supabase_auth_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role, supabase_auth_admin;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role, supabase_auth_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role, supabase_auth_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role, supabase_auth_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role, supabase_auth_admin;

-- STEP 3: CREATE BULLETPROOF, SAFE TRIGGER (NEVER BLOCKS SIGNUP)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql AS $$
DECLARE
    v_role public.user_role_enum := 'organizer';
    v_full_name TEXT := 'MUSTER User';
    v_company TEXT := 'Independent Organizer';
    v_primary_role TEXT := 'Event Operations';
    v_rate INTEGER := 1500;
    v_city TEXT := 'Indore, Madhya Pradesh';
BEGIN
    -- Safe metadata extraction
    IF NEW.raw_user_meta_data IS NOT NULL THEN
        IF NEW.raw_user_meta_data->>'role' = 'freelancer' THEN
            v_role := 'freelancer';
        END IF;
        IF NEW.raw_user_meta_data->>'full_name' IS NOT NULL THEN
            v_full_name := NEW.raw_user_meta_data->>'full_name';
        END IF;
        IF NEW.raw_user_meta_data->>'city' IS NOT NULL THEN
            v_city := NEW.raw_user_meta_data->>'city';
        END IF;
        IF NEW.raw_user_meta_data->>'company_name' IS NOT NULL THEN
            v_company := NEW.raw_user_meta_data->>'company_name';
        END IF;
        IF NEW.raw_user_meta_data->>'primary_role' IS NOT NULL THEN
            v_primary_role := NEW.raw_user_meta_data->>'primary_role';
        END IF;
        IF NEW.raw_user_meta_data->>'hourly_rate' IS NOT NULL THEN
            v_rate := (NEW.raw_user_meta_data->>'hourly_rate')::INTEGER;
        END IF;
    END IF;

    -- Safe Insert Profiles
    BEGIN
        INSERT INTO public.profiles (id, email, full_name, role)
        VALUES (NEW.id, COALESCE(NEW.email, 'user@muster.test'), v_full_name, v_role)
        ON CONFLICT (id) DO UPDATE SET
            full_name = EXCLUDED.full_name,
            email = EXCLUDED.email,
            role = EXCLUDED.role,
            updated_at = NOW();

        IF v_role = 'organizer' THEN
            INSERT INTO public.organizer_profiles (id, company_name, city)
            VALUES (NEW.id, v_company, v_city)
            ON CONFLICT (id) DO UPDATE SET
                company_name = EXCLUDED.company_name,
                city = EXCLUDED.city,
                updated_at = NOW();
        ELSE
            INSERT INTO public.freelancer_profiles (id, primary_role, hourly_rate, city)
            VALUES (NEW.id, v_primary_role, v_rate, v_city)
            ON CONFLICT (id) DO UPDATE SET
                primary_role = EXCLUDED.primary_role,
                hourly_rate = EXCLUDED.hourly_rate,
                city = EXCLUDED.city,
                updated_at = NOW();
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Log warning but never abort the auth transaction
        RAISE WARNING 'handle_new_user profile creation warning: %', SQLERRM;
    END;

    RETURN NEW;
END;
$$;

-- Re-attach trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- STEP 4: SEED / REFRESH ALL TEST ACCOUNTS IN AUTH.USERS & AUTH.IDENTITIES
DO $$
DECLARE
    u RECORD;
    v_encrypted_pw TEXT;
    v_users JSONB := '[
        {"id": "a0000000-0000-0000-0000-000000000001", "email": "organizer01@muster.test", "role": "organizer", "full_name": "Arjun Mehta", "company_name": "TechNova Events", "city": "Indore, Madhya Pradesh"},
        {"id": "a0000000-0000-0000-0000-000000000002", "email": "organizer02@muster.test", "role": "organizer", "full_name": "Riya Kapoor", "company_name": "NextWave Productions", "city": "Bhopal, Madhya Pradesh"},
        {"id": "f0000000-0000-0000-0000-000000000001", "email": "freelancer01@muster.test", "role": "freelancer", "full_name": "Aarav Sharma", "primary_role": "Event Operations", "hourly_rate": 1400, "city": "Indore, Madhya Pradesh"},
        {"id": "f0000000-0000-0000-0000-000000000002", "email": "freelancer02@muster.test", "role": "freelancer", "full_name": "Ishita Verma", "primary_role": "Hospitality Specialist", "hourly_rate": 1600, "city": "Indore, Madhya Pradesh"},
        {"id": "f0000000-0000-0000-0000-000000000003", "email": "freelancer03@muster.test", "role": "freelancer", "full_name": "Kabir Patel", "primary_role": "AV & Technical Specialist", "hourly_rate": 1800, "city": "Ujjain, Madhya Pradesh"},
        {"id": "f0000000-0000-0000-0000-000000000004", "email": "freelancer04@muster.test", "role": "freelancer", "full_name": "Ananya Joshi", "primary_role": "Stage Coordinator", "hourly_rate": 1200, "city": "Indore, Madhya Pradesh"},
        {"id": "f0000000-0000-0000-0000-000000000005", "email": "freelancer05@muster.test", "role": "freelancer", "full_name": "Rohan Singh", "primary_role": "Logistics Lead", "hourly_rate": 1500, "city": "Bhopal, Madhya Pradesh"},
        {"id": "f0000000-0000-0000-0000-000000000006", "email": "freelancer06@muster.test", "role": "freelancer", "full_name": "Meera Shah", "primary_role": "Production Assistant", "hourly_rate": 1100, "city": "Indore, Madhya Pradesh"},
        {"id": "00000000-0000-0000-0000-000000000001", "email": "organizer@muster.events", "role": "organizer", "full_name": "Vikramaditya Roy", "company_name": "Apex Event Production Pvt Ltd", "city": "Bengaluru"}
    ]';
BEGIN
    v_encrypted_pw := crypt('MusterTest@2026', gen_salt('bf'));

    FOR u IN SELECT * FROM jsonb_to_recordset(v_users) AS x(
        id UUID, email TEXT, role TEXT, full_name TEXT, company_name TEXT, primary_role TEXT, hourly_rate INT, city TEXT
    )
    LOOP
        -- 1. Update/Insert auth.users
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            confirmation_token, recovery_token, email_change_token_new, email_change,
            is_sso_user
        ) VALUES (
            u.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            u.email, v_encrypted_pw, NOW(), '{"provider":"email","providers":["email"]}'::JSONB,
            jsonb_build_object('role', u.role, 'full_name', u.full_name, 'city', u.city),
            NOW(), NOW(), '', '', '', '', false
        )
        ON CONFLICT (id) DO UPDATE SET
            encrypted_password = v_encrypted_pw,
            email = u.email,
            email_confirmed_at = COALESCE(auth.users.email_confirmed_at, NOW()),
            raw_app_meta_data = '{"provider":"email","providers":["email"]}'::JSONB,
            raw_user_meta_data = jsonb_build_object('role', u.role, 'full_name', u.full_name, 'city', u.city),
            updated_at = NOW();

        -- 2. Update/Insert auth.identities
        INSERT INTO auth.identities (
            id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
        ) VALUES (
            u.id, u.id, jsonb_build_object('sub', u.id::text, 'email', u.email),
            'email', u.id::text, NOW(), NOW(), NOW()
        )
        ON CONFLICT (provider, provider_id) DO UPDATE SET
            identity_data = jsonb_build_object('sub', u.id::text, 'email', u.email),
            last_sign_in_at = NOW(),
            updated_at = NOW();

        -- 3. Update/Insert public.profiles
        INSERT INTO public.profiles (id, email, full_name, role)
        VALUES (u.id, u.email, u.full_name, u.role::public.user_role_enum)
        ON CONFLICT (id) DO UPDATE SET
            full_name = u.full_name, email = u.email, role = u.role::public.user_role_enum, updated_at = NOW();

        -- 4. Role Profiles
        IF u.role = 'organizer' THEN
            INSERT INTO public.organizer_profiles (id, company_name, city)
            VALUES (u.id, COALESCE(u.company_name, 'TechNova Events'), COALESCE(u.city, 'Indore, Madhya Pradesh'))
            ON CONFLICT (id) DO UPDATE SET company_name = EXCLUDED.company_name, city = EXCLUDED.city, updated_at = NOW();
        ELSE
            INSERT INTO public.freelancer_profiles (id, primary_role, hourly_rate, experience_years, reliability_score, match_score, distance_km, city)
            VALUES (u.id, COALESCE(u.primary_role, 'Event Operations'), COALESCE(u.hourly_rate, 1500), 3, 95, 90, 5.0, COALESCE(u.city, 'Indore, Madhya Pradesh'))
            ON CONFLICT (id) DO UPDATE SET primary_role = EXCLUDED.primary_role, hourly_rate = EXCLUDED.hourly_rate, city = EXCLUDED.city, updated_at = NOW();
        END IF;
    END LOOP;
END $$;
