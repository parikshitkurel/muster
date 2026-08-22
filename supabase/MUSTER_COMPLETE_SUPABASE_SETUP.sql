-- ==============================================================================
-- MUSTER — Complete Supabase Database Setup & Schema Infrastructure
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

-- 3.5 Events Table
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
    status event_status_enum NOT NULL DEFAULT 'published',
    description TEXT NOT NULL DEFAULT '',
    applicant_count INTEGER NOT NULL DEFAULT 0 CHECK (applicant_count >= 0),
    total_cost_allocated INTEGER NOT NULL DEFAULT 0 CHECK (total_cost_allocated >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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

-- 3.9 Confirmed Crews Table (with crew_type & total_members)
CREATE TABLE IF NOT EXISTS public.crews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    crew_type TEXT NOT NULL DEFAULT 'Production Crew',
    total_members INTEGER NOT NULL DEFAULT 1 CHECK (total_members > 0),
    total_cost INTEGER NOT NULL CHECK (total_cost >= 0),
    confirmed_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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

-- 4. INDEXES
CREATE INDEX IF NOT EXISTS idx_events_organizer ON public.events(organizer_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON public.events(status);
CREATE INDEX IF NOT EXISTS idx_events_city ON public.events(city);
CREATE INDEX IF NOT EXISTS idx_event_roles_event ON public.event_roles(event_id);
CREATE INDEX IF NOT EXISTS idx_event_skills_role ON public.event_skills(event_role_id);
CREATE INDEX IF NOT EXISTS idx_applications_event ON public.applications(event_id);
CREATE INDEX IF NOT EXISTS idx_applications_freelancer ON public.applications(freelancer_id);
CREATE INDEX IF NOT EXISTS idx_crews_event ON public.crews(event_id);
CREATE INDEX IF NOT EXISTS idx_crew_members_crew ON public.crew_members(crew_id);
CREATE INDEX IF NOT EXISTS idx_crew_members_freelancer ON public.crew_members(freelancer_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_event ON public.match_recommendations(event_id);
CREATE INDEX IF NOT EXISTS idx_rec_members_rec ON public.recommendation_members(recommendation_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);

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
