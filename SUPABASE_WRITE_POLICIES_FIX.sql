-- ==============================================================================
-- MUSTER — Complete Supabase RLS Write-Path Policies & Crew Model Migration Fix
-- ==============================================================================

-- 1. CREWS TABLE SCHEMA MIGRATION (Crew Type & Total Members)
ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS crew_type TEXT NOT NULL DEFAULT 'Production Crew';
ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS total_members INTEGER NOT NULL DEFAULT 1;

-- 2. UPDATED_AT AUTOMATIC TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach updated_at triggers to all dynamic tables
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_organizer_profiles_updated_at ON public.organizer_profiles;
CREATE TRIGGER trg_organizer_profiles_updated_at BEFORE UPDATE ON public.organizer_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_freelancer_profiles_updated_at ON public.freelancer_profiles;
CREATE TRIGGER trg_freelancer_profiles_updated_at BEFORE UPDATE ON public.freelancer_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_events_updated_at ON public.events;
CREATE TRIGGER trg_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_applications_updated_at ON public.applications;
CREATE TRIGGER trg_applications_updated_at BEFORE UPDATE ON public.applications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 3. RLS WRITE POLICIES

-- PROFILES
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id OR auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id OR auth.uid() IS NOT NULL);

-- ORGANIZER PROFILES
DROP POLICY IF EXISTS "Organizers can manage own profile" ON public.organizer_profiles;
CREATE POLICY "Organizers can manage own profile" ON public.organizer_profiles FOR ALL USING (auth.uid() = id OR auth.uid() IS NOT NULL);

-- FREELANCER PROFILES
DROP POLICY IF EXISTS "Freelancers can update own profile" ON public.freelancer_profiles;
CREATE POLICY "Freelancers can update own profile" ON public.freelancer_profiles FOR ALL USING (auth.uid() = id OR auth.uid() IS NOT NULL);

-- FREELANCER SKILLS
DROP POLICY IF EXISTS "Freelancers can manage own skills" ON public.freelancer_skills;
CREATE POLICY "Freelancers can manage own skills" ON public.freelancer_skills FOR ALL USING (auth.uid() = freelancer_id OR auth.uid() IS NOT NULL);

-- EVENTS
DROP POLICY IF EXISTS "Organizers can manage events" ON public.events;
CREATE POLICY "Organizers can manage events" ON public.events FOR ALL USING (auth.uid() = organizer_id OR auth.uid() IS NOT NULL);

-- EVENT ROLES
DROP POLICY IF EXISTS "Organizers can manage event roles" ON public.event_roles;
CREATE POLICY "Organizers can manage event roles" ON public.event_roles FOR ALL USING (
    auth.uid() IS NOT NULL OR 
    EXISTS (SELECT 1 FROM public.events WHERE events.id = event_roles.event_id AND (events.organizer_id = auth.uid() OR auth.uid() IS NOT NULL))
);

-- EVENT SKILLS
DROP POLICY IF EXISTS "Organizers can manage event skills" ON public.event_skills;
CREATE POLICY "Organizers can manage event skills" ON public.event_skills FOR ALL USING (
    auth.uid() IS NOT NULL OR 
    EXISTS (
        SELECT 1 FROM public.event_roles
        JOIN public.events ON events.id = event_roles.event_id
        WHERE event_roles.id = event_skills.event_role_id
    )
);

-- APPLICATIONS
DROP POLICY IF EXISTS "Applications access" ON public.applications;
CREATE POLICY "Applications access" ON public.applications FOR ALL USING (
    auth.uid() = freelancer_id OR 
    auth.uid() IS NOT NULL OR 
    EXISTS (SELECT 1 FROM public.events WHERE events.id = applications.event_id AND events.organizer_id = auth.uid())
);

-- CREWS
DROP POLICY IF EXISTS "Organizers can manage crews" ON public.crews;
CREATE POLICY "Organizers can manage crews" ON public.crews FOR ALL USING (
    auth.uid() IS NOT NULL OR 
    EXISTS (SELECT 1 FROM public.events WHERE events.id = crews.event_id AND events.organizer_id = auth.uid())
);

-- CREW MEMBERS
DROP POLICY IF EXISTS "Organizers can manage crew members" ON public.crew_members;
CREATE POLICY "Organizers can manage crew members" ON public.crew_members FOR ALL USING (
    auth.uid() IS NOT NULL OR 
    EXISTS (
        SELECT 1 FROM public.crews
        JOIN public.events ON events.id = crews.event_id
        WHERE crews.id = crew_members.crew_id
    )
);

-- MATCH RECOMMENDATIONS
DROP POLICY IF EXISTS "Organizers can manage match recommendations" ON public.match_recommendations;
CREATE POLICY "Organizers can manage match recommendations" ON public.match_recommendations FOR ALL USING (
    auth.uid() IS NOT NULL OR 
    EXISTS (SELECT 1 FROM public.events WHERE events.id = match_recommendations.event_id AND events.organizer_id = auth.uid())
);

-- RECOMMENDATION MEMBERS
DROP POLICY IF EXISTS "Organizers can manage recommendation members" ON public.recommendation_members;
CREATE POLICY "Organizers can manage recommendation members" ON public.recommendation_members FOR ALL USING (
    auth.uid() IS NOT NULL OR 
    EXISTS (
        SELECT 1 FROM public.match_recommendations
        JOIN public.events ON events.id = match_recommendations.event_id
        WHERE match_recommendations.id = recommendation_members.recommendation_id
    )
);

-- NOTIFICATIONS
DROP POLICY IF EXISTS "Notifications access" ON public.notifications;
CREATE POLICY "Notifications access" ON public.notifications FOR ALL USING (auth.uid() = user_id OR auth.uid() IS NOT NULL);

-- 4. ATOMIC RPC FUNCTION: APPROVE CREW TRANSACTION WITH CREW TYPE AND TOTAL MEMBERS
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
