-- ==============================================================================
-- MUSTER — Complete Supabase Database Setup & RLS Migration Script
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. ENUM DEFINITIONS
DO $$ BEGIN
    CREATE TYPE user_role_enum AS ENUM ('organizer', 'freelancer');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE event_status_enum AS ENUM ('draft', 'published', 'optimized', 'crew_confirmed', 'in_progress', 'completed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE application_status_enum AS ENUM ('pending', 'shortlisted', 'selected', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE notification_type_enum AS ENUM ('ai_match_ready', 'application_update', 'candidate_applied', 'system_alert');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2. UPDATED_AT TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. TABLES DEFINITION

-- 3.1 Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role user_role_enum NOT NULL DEFAULT 'organizer',
    avatar_url TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.2 Organizer Profiles Table
CREATE TABLE IF NOT EXISTS public.organizer_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL DEFAULT 'Independent Organizer',
    city TEXT NOT NULL DEFAULT 'Bengaluru',
    gst_number TEXT,
    billing_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.3 Freelancer Profiles Table
CREATE TABLE IF NOT EXISTS public.freelancer_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    primary_role TEXT NOT NULL DEFAULT 'Event Operations',
    hourly_rate INTEGER NOT NULL DEFAULT 1500 CHECK (hourly_rate >= 0),
    experience_years INTEGER NOT NULL DEFAULT 3 CHECK (experience_years >= 0),
    reliability_score INTEGER NOT NULL DEFAULT 95 CHECK (reliability_score >= 0 AND reliability_score <= 100),
    match_score INTEGER NOT NULL DEFAULT 90 CHECK (match_score >= 0 AND match_score <= 100),
    distance_km NUMERIC NOT NULL DEFAULT 5.0 CHECK (distance_km >= 0),
    city TEXT NOT NULL DEFAULT 'Bengaluru',
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.4 Freelancer Skills Table
CREATE TABLE IF NOT EXISTS public.freelancer_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    freelancer_id UUID NOT NULL REFERENCES public.freelancer_profiles(id) ON DELETE CASCADE,
    skill_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(freelancer_id, skill_name)
);

-- 3.5 Events Table (Includes matching weights columns)
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'Conference',
    date TEXT NOT NULL,
    venue TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'Bengaluru',
    budget INTEGER NOT NULL CHECK (budget > 0),
    proximity_km INTEGER NOT NULL DEFAULT 25 CHECK (proximity_km >= 0),
    skill_weight NUMERIC NOT NULL DEFAULT 0.40 CHECK (skill_weight >= 0 AND skill_weight <= 1.0),
    reliability_weight NUMERIC NOT NULL DEFAULT 0.35 CHECK (reliability_weight >= 0 AND reliability_weight <= 1.0),
    proximity_weight NUMERIC NOT NULL DEFAULT 0.15 CHECK (proximity_weight >= 0 AND proximity_weight <= 1.0),
    rate_weight NUMERIC NOT NULL DEFAULT 0.10 CHECK (rate_weight >= 0 AND rate_weight <= 1.0),
    status event_status_enum NOT NULL DEFAULT 'published',
    description TEXT NOT NULL DEFAULT '',
    applicant_count INTEGER NOT NULL DEFAULT 0 CHECK (applicant_count >= 0),
    total_cost_allocated INTEGER NOT NULL DEFAULT 0 CHECK (total_cost_allocated >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure columns exist if adding to pre-existing database
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS skill_weight NUMERIC NOT NULL DEFAULT 0.40;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS reliability_weight NUMERIC NOT NULL DEFAULT 0.35;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS proximity_weight NUMERIC NOT NULL DEFAULT 0.15;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS rate_weight NUMERIC NOT NULL DEFAULT 0.10;

-- 3.6 Event Requirements / Roles Table
CREATE TABLE IF NOT EXISTS public.event_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    role_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    max_rate_per_hour INTEGER NOT NULL CHECK (max_rate_per_hour > 0),
    min_experience_years INTEGER NOT NULL DEFAULT 1 CHECK (min_experience_years >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.7 Event Role Skills Table
CREATE TABLE IF NOT EXISTS public.event_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_role_id UUID NOT NULL REFERENCES public.event_roles(id) ON DELETE CASCADE,
    skill_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(event_role_id, skill_name)
);

-- 3.8 Applications Table
CREATE TABLE IF NOT EXISTS public.applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    freelancer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    applied_role TEXT NOT NULL,
    proposed_rate INTEGER NOT NULL CHECK (proposed_rate >= 0),
    status application_status_enum NOT NULL DEFAULT 'pending',
    feedback TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(event_id, freelancer_id)
);

-- 3.9 Confirmed Crews Table (Includes crew_type & total_members)
CREATE TABLE IF NOT EXISTS public.crews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    crew_type TEXT NOT NULL DEFAULT 'Production Crew',
    total_members INTEGER NOT NULL DEFAULT 1 CHECK (total_members > 0),
    total_cost INTEGER NOT NULL CHECK (total_cost >= 0),
    confirmed_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS crew_type TEXT NOT NULL DEFAULT 'Production Crew';
ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS total_members INTEGER NOT NULL DEFAULT 1;

-- 3.10 Crew Members Table
CREATE TABLE IF NOT EXISTS public.crew_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crew_id UUID NOT NULL REFERENCES public.crews(id) ON DELETE CASCADE,
    freelancer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    match_score INTEGER NOT NULL CHECK (match_score >= 0 AND match_score <= 100),
    reliability_score INTEGER NOT NULL CHECK (reliability_score >= 0 AND reliability_score <= 100),
    allocated_cost INTEGER NOT NULL CHECK (allocated_cost >= 0),
    rationale TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(crew_id, freelancer_id)
);

-- 3.11 AI Match Recommendations Table
CREATE TABLE IF NOT EXISTS public.match_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    option_title TEXT NOT NULL,
    option_strategy TEXT NOT NULL,
    overall_match_score INTEGER NOT NULL CHECK (overall_match_score >= 0 AND overall_match_score <= 100),
    total_cost INTEGER NOT NULL CHECK (total_cost >= 0),
    budget_remaining INTEGER NOT NULL,
    requirement_coverage NUMERIC NOT NULL CHECK (requirement_coverage >= 0 AND requirement_coverage <= 1),
    is_valid_budget BOOLEAN NOT NULL DEFAULT true,
    permutation_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.12 Recommendation Members Table
CREATE TABLE IF NOT EXISTS public.recommendation_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recommendation_id UUID NOT NULL REFERENCES public.match_recommendations(id) ON DELETE CASCADE,
    freelancer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    match_score INTEGER NOT NULL CHECK (match_score >= 0 AND match_score <= 100),
    reliability_score INTEGER NOT NULL CHECK (reliability_score >= 0 AND reliability_score <= 100),
    allocated_cost INTEGER NOT NULL CHECK (allocated_cost >= 0),
    rationale TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.13 Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    type notification_type_enum NOT NULL DEFAULT 'system_alert',
    related_event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. AUTOMATIC NEW USER REGISTRATION TRIGGER
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_role user_role_enum;
    v_full_name TEXT;
    v_company_name TEXT;
    v_primary_role TEXT;
    v_hourly_rate INT;
    v_city TEXT;
BEGIN
    v_role := COALESCE((NEW.raw_user_meta_data->>'role')::user_role_enum, 'organizer'::user_role_enum);
    v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1));
    v_city := COALESCE(NEW.raw_user_meta_data->>'city', 'Bengaluru');

    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (NEW.id, NEW.email, v_full_name, v_role)
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        updated_at = NOW();

    IF v_role = 'organizer' THEN
        v_company_name := COALESCE(NEW.raw_user_meta_data->>'company_name', 'Independent Organizer');
        INSERT INTO public.organizer_profiles (id, company_name, city)
        VALUES (NEW.id, v_company_name, v_city)
        ON CONFLICT (id) DO UPDATE SET
            company_name = EXCLUDED.company_name,
            city = EXCLUDED.city,
            updated_at = NOW();
    ELSE
        v_primary_role := COALESCE(NEW.raw_user_meta_data->>'primary_role', 'Event Operations');
        v_hourly_rate := COALESCE((NEW.raw_user_meta_data->>'hourly_rate')::INT, 1500);
        INSERT INTO public.freelancer_profiles (id, primary_role, hourly_rate, city)
        VALUES (NEW.id, v_primary_role, v_hourly_rate, v_city)
        ON CONFLICT (id) DO UPDATE SET
            primary_role = EXCLUDED.primary_role,
            hourly_rate = EXCLUDED.hourly_rate,
            city = EXCLUDED.city,
            updated_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. ATOMIC RPC FUNCTION: APPROVE CREW TRANSACTION
CREATE OR REPLACE FUNCTION public.approve_crew_transaction(
    p_event_id UUID,
    p_total_cost INTEGER,
    p_members JSONB,
    p_crew_type TEXT DEFAULT 'Production Crew',
    p_total_members INTEGER DEFAULT 1
)
RETURNS JSONB AS $$
DECLARE
    v_crew_id UUID;
    v_member JSONB;
    v_freelancer_id UUID;
    v_role TEXT;
    v_match_score INTEGER;
    v_rel_score INTEGER;
    v_cost INTEGER;
    v_rationale TEXT;
    v_event_name TEXT;
    v_calculated_members INTEGER;
BEGIN
    SELECT name INTO v_event_name FROM public.events WHERE id = p_event_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event not found with ID: %', p_event_id;
    END IF;

    v_calculated_members := GREATEST(p_total_members, jsonb_array_length(p_members));

    INSERT INTO public.crews (event_id, total_cost, crew_type, total_members, confirmed_date)
    VALUES (p_event_id, p_total_cost, COALESCE(p_crew_type, 'Production Crew'), v_calculated_members, NOW())
    RETURNING id INTO v_crew_id;

    FOR v_member IN SELECT * FROM jsonb_array_elements(p_members)
    LOOP
        v_freelancer_id := (v_member->>'freelancer_id')::UUID;
        v_role := v_member->>'role';
        v_match_score := (v_member->>'match_score')::INTEGER;
        v_rel_score := (v_member->>'reliability_score')::INTEGER;
        v_cost := (v_member->>'allocated_cost')::INTEGER;
        v_rationale := COALESCE(v_member->>'rationale', 'Selected by AI Optimization Engine');

        INSERT INTO public.crew_members (
            crew_id, freelancer_id, role, match_score, reliability_score, allocated_cost, rationale
        ) VALUES (
            v_crew_id, v_freelancer_id, v_role, v_match_score, v_rel_score, v_cost, v_rationale
        )
        ON CONFLICT (crew_id, freelancer_id) DO UPDATE 
        SET role = EXCLUDED.role, allocated_cost = EXCLUDED.allocated_cost;

        UPDATE public.applications
        SET status = 'selected',
            feedback = 'Confirmed in final roster.',
            updated_at = NOW()
        WHERE event_id = p_event_id AND freelancer_id = v_freelancer_id;

        INSERT INTO public.notifications (user_id, title, message, type, related_event_id)
        VALUES (
            v_freelancer_id,
            'Confirmed in Event Crew!',
            'You have been officially confirmed for ' || v_role || ' in ' || v_event_name || '.',
            'application_update',
            p_event_id
        );
    END LOOP;

    UPDATE public.events
    SET status = 'crew_confirmed',
        total_cost_allocated = p_total_cost,
        updated_at = NOW()
    WHERE id = p_event_id;

    RETURN jsonb_build_object(
        'success', true,
        'crew_id', v_crew_id,
        'event_id', p_event_id,
        'crew_type', COALESCE(p_crew_type, 'Production Crew'),
        'total_members', v_calculated_members,
        'status', 'crew_confirmed'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.freelancer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.freelancer_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Profiles Select" ON public.profiles;
CREATE POLICY "Public Profiles Select" ON public.profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Profiles Insert" ON public.profiles;
CREATE POLICY "Profiles Insert" ON public.profiles FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Profiles Update" ON public.profiles;
CREATE POLICY "Profiles Update" ON public.profiles FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Organizer Profiles Select" ON public.organizer_profiles;
CREATE POLICY "Organizer Profiles Select" ON public.organizer_profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Organizer Profiles Write" ON public.organizer_profiles;
CREATE POLICY "Organizer Profiles Write" ON public.organizer_profiles FOR ALL USING (true);

DROP POLICY IF EXISTS "Freelancer Profiles Select" ON public.freelancer_profiles;
CREATE POLICY "Freelancer Profiles Select" ON public.freelancer_profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Freelancer Profiles Write" ON public.freelancer_profiles;
CREATE POLICY "Freelancer Profiles Write" ON public.freelancer_profiles FOR ALL USING (true);

DROP POLICY IF EXISTS "Freelancer Skills Select" ON public.freelancer_skills;
CREATE POLICY "Freelancer Skills Select" ON public.freelancer_skills FOR SELECT USING (true);
DROP POLICY IF EXISTS "Freelancer Skills Write" ON public.freelancer_skills;
CREATE POLICY "Freelancer Skills Write" ON public.freelancer_skills FOR ALL USING (true);

DROP POLICY IF EXISTS "Events Select" ON public.events;
CREATE POLICY "Events Select" ON public.events FOR SELECT USING (true);
DROP POLICY IF EXISTS "Events Write" ON public.events;
CREATE POLICY "Events Write" ON public.events FOR ALL USING (true);

DROP POLICY IF EXISTS "Event Roles Select" ON public.event_roles;
CREATE POLICY "Event Roles Select" ON public.event_roles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Event Roles Write" ON public.event_roles;
CREATE POLICY "Event Roles Write" ON public.event_roles FOR ALL USING (true);

DROP POLICY IF EXISTS "Event Skills Select" ON public.event_skills;
CREATE POLICY "Event Skills Select" ON public.event_skills FOR SELECT USING (true);
DROP POLICY IF EXISTS "Event Skills Write" ON public.event_skills;
CREATE POLICY "Event Skills Write" ON public.event_skills FOR ALL USING (true);

DROP POLICY IF EXISTS "Applications Select" ON public.applications;
CREATE POLICY "Applications Select" ON public.applications FOR SELECT USING (true);
DROP POLICY IF EXISTS "Applications Write" ON public.applications;
CREATE POLICY "Applications Write" ON public.applications FOR ALL USING (true);

DROP POLICY IF EXISTS "Crews Select" ON public.crews;
CREATE POLICY "Crews Select" ON public.crews FOR SELECT USING (true);
DROP POLICY IF EXISTS "Crews Write" ON public.crews;
CREATE POLICY "Crews Write" ON public.crews FOR ALL USING (true);

DROP POLICY IF EXISTS "Crew Members Select" ON public.crew_members;
CREATE POLICY "Crew Members Select" ON public.crew_members FOR SELECT USING (true);
DROP POLICY IF EXISTS "Crew Members Write" ON public.crew_members;
CREATE POLICY "Crew Members Write" ON public.crew_members FOR ALL USING (true);

DROP POLICY IF EXISTS "Recommendations Select" ON public.match_recommendations;
CREATE POLICY "Recommendations Select" ON public.match_recommendations FOR SELECT USING (true);
DROP POLICY IF EXISTS "Recommendations Write" ON public.match_recommendations;
CREATE POLICY "Recommendations Write" ON public.match_recommendations FOR ALL USING (true);

DROP POLICY IF EXISTS "Rec Members Select" ON public.recommendation_members;
CREATE POLICY "Rec Members Select" ON public.recommendation_members FOR SELECT USING (true);
DROP POLICY IF EXISTS "Rec Members Write" ON public.recommendation_members;
CREATE POLICY "Rec Members Write" ON public.recommendation_members FOR ALL USING (true);

DROP POLICY IF EXISTS "Notifications Select" ON public.notifications;
CREATE POLICY "Notifications Select" ON public.notifications FOR SELECT USING (true);
DROP POLICY IF EXISTS "Notifications Write" ON public.notifications;
CREATE POLICY "Notifications Write" ON public.notifications FOR ALL USING (true);

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;
