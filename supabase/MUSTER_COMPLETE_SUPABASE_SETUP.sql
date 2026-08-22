-- ==============================================================================
-- MUSTER — Complete All-in-One Supabase PostgreSQL Setup Script
-- ==============================================================================
-- MIT India Hackathon 2026: AI-Powered Crew Assembly & Optimization
-- 
-- INSTRUCTIONS FOR SUPABASE CONSOLE:
-- 1. Open your Supabase Project Dashboard (https://app.supabase.com)
-- 2. Click on "SQL Editor" in the left sidebar
-- 3. Click "+ New Query"
-- 4. Paste this ENTIRE file into the editor and click "RUN" (or Ctrl+Enter)
-- 5. Everything (Tables, Enums, RLS Policies, Functions, Triggers, Storage, Seed Data)
--    will execute with 100% success!
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. CUSTOM ENUMS
DO $$ BEGIN
    CREATE TYPE user_role_enum AS ENUM ('organizer', 'freelancer');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE event_status_enum AS ENUM ('draft', 'published', 'optimized', 'crew_confirmed', 'in_progress', 'completed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE application_status_enum AS ENUM ('pending', 'shortlisted', 'selected', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE notification_type_enum AS ENUM ('ai_match_ready', 'application_update', 'candidate_applied', 'system_alert');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. TABLES DEFINITION

-- 3.1 Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role user_role_enum NOT NULL DEFAULT 'organizer',
    avatar_url TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.2 Organizer Profiles
CREATE TABLE IF NOT EXISTS public.organizer_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL DEFAULT 'Independent Organizer',
    city TEXT NOT NULL DEFAULT 'Bengaluru',
    gst_number TEXT,
    billing_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.3 Freelancer Profiles
CREATE TABLE IF NOT EXISTS public.freelancer_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    primary_role TEXT NOT NULL DEFAULT 'Event Operations',
    hourly_rate INTEGER NOT NULL DEFAULT 1500,
    experience_years INTEGER NOT NULL DEFAULT 3,
    reliability_score INTEGER NOT NULL DEFAULT 95 CHECK (reliability_score BETWEEN 0 AND 100),
    match_score INTEGER NOT NULL DEFAULT 90 CHECK (match_score BETWEEN 0 AND 100),
    distance_km NUMERIC(5,2) NOT NULL DEFAULT 5.0,
    city TEXT NOT NULL DEFAULT 'Bengaluru',
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.4 Freelancer Skills
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
    proximity_km INTEGER NOT NULL DEFAULT 25,
    status event_status_enum NOT NULL DEFAULT 'published',
    description TEXT NOT NULL DEFAULT '',
    applicant_count INTEGER NOT NULL DEFAULT 0,
    total_cost_allocated INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.6 Event Requirements / Roles
CREATE TABLE IF NOT EXISTS public.event_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    role_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    max_rate_per_hour INTEGER NOT NULL CHECK (max_rate_per_hour > 0),
    min_experience_years INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(event_id, role_name)
);

-- 3.7 Event Skills per Role
CREATE TABLE IF NOT EXISTS public.event_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_role_id UUID NOT NULL REFERENCES public.event_roles(id) ON DELETE CASCADE,
    skill_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(event_role_id, skill_name)
);

-- 3.8 Applications (With Anti-Duplicate Constraint)
CREATE TABLE IF NOT EXISTS public.applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    freelancer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    applied_role TEXT NOT NULL,
    proposed_rate INTEGER NOT NULL,
    status application_status_enum NOT NULL DEFAULT 'pending',
    feedback TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(event_id, freelancer_id)
);

-- 3.9 Confirmed Crews
CREATE TABLE IF NOT EXISTS public.crews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    total_cost INTEGER NOT NULL,
    confirmed_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.10 Crew Members
CREATE TABLE IF NOT EXISTS public.crew_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crew_id UUID NOT NULL REFERENCES public.crews(id) ON DELETE CASCADE,
    freelancer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    match_score INTEGER NOT NULL,
    reliability_score INTEGER NOT NULL,
    allocated_cost INTEGER NOT NULL,
    rationale TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(crew_id, freelancer_id)
);

-- 3.11 AI Matching Recommendations
CREATE TABLE IF NOT EXISTS public.match_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    option_title TEXT NOT NULL,
    option_strategy TEXT NOT NULL,
    overall_match_score INTEGER NOT NULL,
    total_cost INTEGER NOT NULL,
    budget_remaining INTEGER NOT NULL,
    requirement_coverage NUMERIC(3,2) NOT NULL,
    is_valid_budget BOOLEAN NOT NULL DEFAULT true,
    permutation_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.12 Recommendation Members
CREATE TABLE IF NOT EXISTS public.recommendation_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recommendation_id UUID NOT NULL REFERENCES public.match_recommendations(id) ON DELETE CASCADE,
    freelancer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    match_score INTEGER NOT NULL,
    reliability_score INTEGER NOT NULL,
    allocated_cost INTEGER NOT NULL,
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
    related_event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_events_organizer ON public.events(organizer_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON public.events(status);
CREATE INDEX IF NOT EXISTS idx_applications_event ON public.applications(event_id);
CREATE INDEX IF NOT EXISTS idx_applications_freelancer ON public.applications(freelancer_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_freelancer_skills_freelancer ON public.freelancer_skills(freelancer_id);

-- 5. ROW LEVEL SECURITY (RLS) POLICIES
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

-- 5.1 Public Read Policies for directory browsing
DROP POLICY IF EXISTS "Public profiles read" ON public.profiles;
CREATE POLICY "Public profiles read" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public freelancer profiles read" ON public.freelancer_profiles;
CREATE POLICY "Public freelancer profiles read" ON public.freelancer_profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public freelancer skills read" ON public.freelancer_skills;
CREATE POLICY "Public freelancer skills read" ON public.freelancer_skills FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public organizer profiles read" ON public.organizer_profiles;
CREATE POLICY "Public organizer profiles read" ON public.organizer_profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public events read" ON public.events;
CREATE POLICY "Public events read" ON public.events FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public event roles read" ON public.event_roles;
CREATE POLICY "Public event roles read" ON public.event_roles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public event skills read" ON public.event_skills;
CREATE POLICY "Public event skills read" ON public.event_skills FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public match recommendations read" ON public.match_recommendations;
CREATE POLICY "Public match recommendations read" ON public.match_recommendations FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public recommendation members read" ON public.recommendation_members;
CREATE POLICY "Public recommendation members read" ON public.recommendation_members FOR SELECT USING (true);

-- 5.2 User modification policies
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Freelancers can update own profile" ON public.freelancer_profiles;
CREATE POLICY "Freelancers can update own profile" ON public.freelancer_profiles FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Organizers can manage events" ON public.events;
CREATE POLICY "Organizers can manage events" ON public.events FOR ALL USING (auth.uid() = organizer_id);

DROP POLICY IF EXISTS "Applications access" ON public.applications;
CREATE POLICY "Applications access" ON public.applications FOR ALL USING (
    auth.uid() = freelancer_id OR 
    EXISTS (SELECT 1 FROM public.events WHERE events.id = applications.event_id AND events.organizer_id = auth.uid())
);

DROP POLICY IF EXISTS "Notifications access" ON public.notifications;
CREATE POLICY "Notifications access" ON public.notifications FOR ALL USING (auth.uid() = user_id);

-- 6. FUNCTIONS & TRIGGERS

-- 6.1 Auto-profile creation on auth.users sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_role user_role_enum := 'organizer';
    v_full_name TEXT := 'Muster User';
    v_company TEXT := 'Independent Organizer';
    v_primary_role TEXT := 'Event Crew';
    v_rate INTEGER := 1500;
BEGIN
    IF NEW.raw_user_meta_data->>'role' = 'freelancer' THEN
        v_role := 'freelancer';
    END IF;

    IF NEW.raw_user_meta_data->>'full_name' IS NOT NULL THEN
        v_full_name := NEW.raw_user_meta_data->>'full_name';
    END IF;

    -- Insert Base Profile
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (NEW.id, NEW.email, v_full_name, v_role)
    ON CONFLICT (id) DO UPDATE 
    SET full_name = EXCLUDED.full_name, updated_at = NOW();

    -- Insert Role-Specific Profile
    IF v_role = 'organizer' THEN
        IF NEW.raw_user_meta_data->>'company_name' IS NOT NULL THEN
            v_company := NEW.raw_user_meta_data->>'company_name';
        END IF;

        INSERT INTO public.organizer_profiles (id, company_name, city)
        VALUES (NEW.id, v_company, COALESCE(NEW.raw_user_meta_data->>'city', 'Bengaluru'))
        ON CONFLICT (id) DO NOTHING;
    ELSE
        IF NEW.raw_user_meta_data->>'primary_role' IS NOT NULL THEN
            v_primary_role := NEW.raw_user_meta_data->>'primary_role';
        END IF;
        IF NEW.raw_user_meta_data->>'hourly_rate' IS NOT NULL THEN
            v_rate := (NEW.raw_user_meta_data->>'hourly_rate')::INTEGER;
        END IF;

        INSERT INTO public.freelancer_profiles (id, primary_role, hourly_rate, city)
        VALUES (NEW.id, v_primary_role, v_rate, COALESCE(NEW.raw_user_meta_data->>'city', 'Bengaluru'))
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6.2 Atomic RPC Function: Approve Crew Transaction
CREATE OR REPLACE FUNCTION public.approve_crew_transaction(
    p_event_id UUID,
    p_total_cost INTEGER,
    p_members JSONB
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
BEGIN
    -- 1. Get Event Name
    SELECT name INTO v_event_name FROM public.events WHERE id = p_event_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event not found with ID: %', p_event_id;
    END IF;

    -- 2. Create Crew Record
    INSERT INTO public.crews (event_id, total_cost, confirmed_date)
    VALUES (p_event_id, p_total_cost, NOW())
    RETURNING id INTO v_crew_id;

    -- 3. Insert each approved member
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
        );

        -- Update Application Status to 'selected'
        UPDATE public.applications
        SET status = 'selected',
            feedback = 'Confirmed in final roster by AI optimizer.',
            updated_at = NOW()
        WHERE event_id = p_event_id AND freelancer_id = v_freelancer_id;

        -- Send Confirmation Notification to Freelancer
        INSERT INTO public.notifications (
            user_id, title, message, type, related_event_id
        ) VALUES (
            v_freelancer_id,
            'Crew Selection Confirmed',
            format('Congratulations! You have been confirmed for %s as %s.', v_event_name, v_role),
            'application_update',
            p_event_id
        );
    END LOOP;

    -- 4. Update Event Status to 'crew_confirmed'
    UPDATE public.events
    SET status = 'crew_confirmed',
        total_cost_allocated = p_total_cost,
        updated_at = NOW()
    WHERE id = p_event_id;

    RETURN jsonb_build_object(
        'success', true,
        'crew_id', v_crew_id,
        'event_id', p_event_id,
        'status', 'crew_confirmed'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. SEED DATA

-- 7.1 Seed Demo Organizer Profile
INSERT INTO public.profiles (id, email, full_name, role)
VALUES ('00000000-0000-0000-0000-000000000001', 'organizer@muster.events', 'Vikramaditya Roy', 'organizer')
ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;

INSERT INTO public.organizer_profiles (id, company_name, city)
VALUES ('00000000-0000-0000-0000-000000000001', 'Apex Event Production Pvt Ltd', 'Bengaluru')
ON CONFLICT (id) DO NOTHING;

-- 7.2 Seed Demo Freelancer Profiles
INSERT INTO public.profiles (id, email, full_name, role) VALUES
('00000000-0000-0000-0000-000000000002', 'rohan.mehta@muster.events', 'Rohan Mehta', 'freelancer'),
('00000000-0000-0000-0000-000000000003', 'ananya.sharma@muster.events', 'Ananya Sharma', 'freelancer'),
('00000000-0000-0000-0000-000000000004', 'karthik.raman@muster.events', 'Karthik Raman', 'freelancer'),
('00000000-0000-0000-0000-000000000005', 'pooja.hegde@muster.events', 'Pooja Hegde', 'freelancer'),
('00000000-0000-0000-0000-000000000006', 'arjun.deshmukh@muster.events', 'Arjun Deshmukh', 'freelancer'),
('00000000-0000-0000-0000-000000000007', 'aditi.nair@muster.events', 'Aditi Nair', 'freelancer'),
('00000000-0000-0000-0000-000000000008', 'siddharth.pillai@muster.events', 'Siddharth Pillai', 'freelancer')
ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;

INSERT INTO public.freelancer_profiles (id, primary_role, hourly_rate, experience_years, reliability_score, match_score, distance_km, city) VALUES
('00000000-0000-0000-0000-000000000002', 'Sound Engineer', 1800, 5, 98, 98, 4.2, 'Bengaluru'),
('00000000-0000-0000-0000-000000000003', 'Lighting Specialist', 1650, 4, 96, 95, 6.8, 'Bengaluru'),
('00000000-0000-0000-0000-000000000004', 'Stage Coordinator', 1100, 3, 99, 94, 3.5, 'Bengaluru'),
('00000000-0000-0000-0000-000000000005', 'Stage Coordinator', 1150, 3, 94, 92, 8.1, 'Bengaluru'),
('00000000-0000-0000-0000-000000000006', 'Sound Engineer', 1900, 4, 95, 93, 5.0, 'Bengaluru'),
('00000000-0000-0000-0000-000000000007', 'Lighting Specialist', 1750, 4, 93, 91, 9.4, 'Bengaluru'),
('00000000-0000-0000-0000-000000000008', 'Stage Coordinator', 1050, 2, 91, 89, 12.0, 'Bengaluru')
ON CONFLICT (id) DO NOTHING;

-- 7.3 Seed Events
INSERT INTO public.events (id, organizer_id, name, type, date, venue, city, budget, proximity_km, status, applicant_count, description) VALUES
('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000001', 'TechSparks 2026', 'Conference', '2026-09-15', 'KTPO Whitefield, Bengaluru', 'Bengaluru', 150000, 25, 'published', 18, 'Flagship annual tech keynote conference. Requiring sound engineers, lighting designers, stage managers, and registration coordinators for multi-track auditoriums.'),
('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000001', 'Sunburn Arena Bangalore', 'Concert', '2026-10-02', 'Manpho Convention Centre', 'Bengaluru', 280000, 30, 'published', 24, 'Massive electronic music festival tour stop. Requires heavy audio engineers, lasers technicians, and safety crew.'),
('33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000001', 'Global Fintech Summit 2026', 'Corporate Summit', '2026-11-10', 'Jio World Convention Centre, Mumbai', 'Mumbai', 350000, 20, 'draft', 0, 'High-level corporate fintech summit hosting global central bankers and founders.')
ON CONFLICT (id) DO NOTHING;

-- 7.4 Seed Event Requirements
INSERT INTO public.event_roles (event_id, role_name, quantity, max_rate_per_hour, min_experience_years) VALUES
('11111111-1111-1111-1111-111111111111', 'Sound Engineer', 2, 2200, 3),
('11111111-1111-1111-1111-111111111111', 'Lighting Specialist', 2, 2000, 3),
('11111111-1111-1111-1111-111111111111', 'Stage Coordinator', 3, 1200, 2)
ON CONFLICT (event_id, role_name) DO NOTHING;

-- 7.5 Seed Applications
INSERT INTO public.applications (event_id, freelancer_id, applied_role, proposed_rate, status, feedback) VALUES
('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000002', 'Sound Engineer', 1800, 'selected', 'Optimal algorithmic fit selected for FOH main stage audio dispatch.')
ON CONFLICT (event_id, freelancer_id) DO NOTHING;

-- 7.6 Seed Notifications
INSERT INTO public.notifications (user_id, title, message, type, related_event_id) VALUES
('00000000-0000-0000-0000-000000000001', 'Optimization Engine Completed', 'AI crew solver generated 3 Pareto-optimal allocations for TechSparks 2026.', 'ai_match_ready', '11111111-1111-1111-1111-111111111111'),
('00000000-0000-0000-0000-000000000002', 'Crew Selection Confirmed', 'Congratulations! You have been confirmed for TechSparks 2026 as Lead Sound Engineer.', 'application_update', '11111111-1111-1111-1111-111111111111')
ON CONFLICT DO NOTHING;
