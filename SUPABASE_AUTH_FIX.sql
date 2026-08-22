-- ==============================================================================
-- MUSTER — Supabase Auth & Schema Fix Script
-- ==============================================================================
-- Run this in your Supabase Dashboard -> SQL Editor
-- This fixes the "Database error querying schema" (HTTP 500) error by:
-- 1. Ensuring all required extensions and grants exist
-- 2. Populating auth.identities for GoTrue password authentication
-- 3. Synchronizing profiles, organizer_profiles, and freelancer_profiles
-- ==============================================================================

-- 1. EXTENSIONS & PERMISSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role, supabase_auth_admin;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role, supabase_auth_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role, supabase_auth_admin;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role, supabase_auth_admin;

-- 2. CREATE / REFRESH TEST USERS IN AUTH.USERS
-- Password for all accounts: MusterTest@2026

DO $$
DECLARE
    u RECORD;
    v_encrypted_pw TEXT;
    v_users JSONB := '[
        {
            "id": "a0000000-0000-0000-0000-000000000001",
            "email": "organizer01@muster.test",
            "role": "organizer",
            "full_name": "Arjun Mehta",
            "company_name": "TechNova Events",
            "city": "Indore, Madhya Pradesh"
        },
        {
            "id": "a0000000-0000-0000-0000-000000000002",
            "email": "organizer02@muster.test",
            "role": "organizer",
            "full_name": "Riya Kapoor",
            "company_name": "NextWave Productions",
            "city": "Bhopal, Madhya Pradesh"
        },
        {
            "id": "f0000000-0000-0000-0000-000000000001",
            "email": "freelancer01@muster.test",
            "role": "freelancer",
            "full_name": "Aarav Sharma",
            "primary_role": "Event Operations",
            "hourly_rate": 1400,
            "city": "Indore, Madhya Pradesh"
        },
        {
            "id": "f0000000-0000-0000-0000-000000000002",
            "email": "freelancer02@muster.test",
            "role": "freelancer",
            "full_name": "Ishita Verma",
            "primary_role": "Hospitality Specialist",
            "hourly_rate": 1600,
            "city": "Indore, Madhya Pradesh"
        },
        {
            "id": "f0000000-0000-0000-0000-000000000003",
            "email": "freelancer03@muster.test",
            "role": "freelancer",
            "full_name": "Kabir Patel",
            "primary_role": "AV & Technical Specialist",
            "hourly_rate": 1800,
            "city": "Ujjain, Madhya Pradesh"
        },
        {
            "id": "f0000000-0000-0000-0000-000000000004",
            "email": "freelancer04@muster.test",
            "role": "freelancer",
            "full_name": "Ananya Joshi",
            "primary_role": "Stage Coordinator",
            "hourly_rate": 1200,
            "city": "Indore, Madhya Pradesh"
        },
        {
            "id": "f0000000-0000-0000-0000-000000000005",
            "email": "freelancer05@muster.test",
            "role": "freelancer",
            "full_name": "Rohan Singh",
            "primary_role": "Logistics Lead",
            "hourly_rate": 1500,
            "city": "Bhopal, Madhya Pradesh"
        },
        {
            "id": "f0000000-0000-0000-0000-000000000006",
            "email": "freelancer06@muster.test",
            "role": "freelancer",
            "full_name": "Meera Shah",
            "primary_role": "Production Assistant",
            "hourly_rate": 1100,
            "city": "Indore, Madhya Pradesh"
        },
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "email": "organizer@muster.events",
            "role": "organizer",
            "full_name": "Vikramaditya Roy",
            "company_name": "Apex Event Production Pvt Ltd",
            "city": "Bengaluru"
        }
    ]';
BEGIN
    v_encrypted_pw := crypt('MusterTest@2026', gen_salt('bf'));

    FOR u IN SELECT * FROM jsonb_to_recordset(v_users) AS x(
        id UUID, email TEXT, role TEXT, full_name TEXT, 
        company_name TEXT, primary_role TEXT, hourly_rate INT, city TEXT
    )
    LOOP
        -- 2.1 Insert / Update auth.users
        INSERT INTO auth.users (
            id,
            instance_id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            recovery_token,
            email_change_token_new,
            email_change
        ) VALUES (
            u.id,
            '00000000-0000-0000-0000-000000000000',
            'authenticated',
            'authenticated',
            u.email,
            v_encrypted_pw,
            NOW(),
            '{"provider":"email","providers":["email"]}'::JSONB,
            jsonb_build_object('role', u.role, 'full_name', u.full_name, 'city', u.city),
            NOW(),
            NOW(),
            '', '', '', ''
        )
        ON CONFLICT (id) DO UPDATE SET
            encrypted_password = v_encrypted_pw,
            email = u.email,
            email_confirmed_at = COALESCE(auth.users.email_confirmed_at, NOW()),
            raw_app_meta_data = '{"provider":"email","providers":["email"]}'::JSONB,
            raw_user_meta_data = jsonb_build_object('role', u.role, 'full_name', u.full_name, 'city', u.city),
            updated_at = NOW();

        -- 2.2 Insert / Update auth.identities (CRITICAL for Supabase GoTrue Auth)
        INSERT INTO auth.identities (
            id,
            user_id,
            identity_data,
            provider,
            provider_id,
            last_sign_in_at,
            created_at,
            updated_at
        ) VALUES (
            u.id::text,
            u.id,
            jsonb_build_object('sub', u.id::text, 'email', u.email),
            'email',
            u.id::text,
            NOW(),
            NOW(),
            NOW()
        )
        ON CONFLICT (provider, provider_id) DO UPDATE SET
            identity_data = jsonb_build_object('sub', u.id::text, 'email', u.email),
            last_sign_in_at = NOW(),
            updated_at = NOW();

        -- 2.3 Insert / Update public.profiles
        INSERT INTO public.profiles (id, email, full_name, role)
        VALUES (u.id, u.email, u.full_name, u.role::user_role_enum)
        ON CONFLICT (id) DO UPDATE SET
            full_name = u.full_name,
            email = u.email,
            role = u.role::user_role_enum,
            updated_at = NOW();

        -- 2.4 Insert / Update role-specific profile
        IF u.role = 'organizer' THEN
            INSERT INTO public.organizer_profiles (id, company_name, city)
            VALUES (u.id, COALESCE(u.company_name, 'TechNova Events'), COALESCE(u.city, 'Indore, Madhya Pradesh'))
            ON CONFLICT (id) DO UPDATE SET
                company_name = COALESCE(u.company_name, 'TechNova Events'),
                city = COALESCE(u.city, 'Indore, Madhya Pradesh'),
                updated_at = NOW();
        ELSE
            INSERT INTO public.freelancer_profiles (id, primary_role, hourly_rate, experience_years, reliability_score, match_score, distance_km, city)
            VALUES (u.id, COALESCE(u.primary_role, 'Event Operations'), COALESCE(u.hourly_rate, 1500), 3, 95, 90, 5.0, COALESCE(u.city, 'Indore, Madhya Pradesh'))
            ON CONFLICT (id) DO UPDATE SET
                primary_role = COALESCE(u.primary_role, 'Event Operations'),
                hourly_rate = COALESCE(u.hourly_rate, 1500),
                city = COALESCE(u.city, 'Indore, Madhya Pradesh'),
                updated_at = NOW();
        END IF;
    END LOOP;
END $$;
