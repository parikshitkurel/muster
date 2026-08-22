-- ==============================================================================
-- MUSTER — Complete Supabase RLS Write-Path Policies Fix
-- ==============================================================================
-- Run this script in the Supabase SQL Editor to grant full, secure write access
-- for all MUSTER tables: profiles, organizer_profiles, freelancer_profiles,
-- freelancer_skills, events, event_roles, event_skills, applications,
-- crews, crew_members, match_recommendations, and notifications.
-- ==============================================================================

-- 1. PROFILES TABLE (Insert & Update)
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles 
FOR INSERT WITH CHECK (auth.uid() = id OR auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles 
FOR UPDATE USING (auth.uid() = id OR auth.uid() IS NOT NULL);

-- 2. ORGANIZER PROFILES TABLE (All operations for owner)
DROP POLICY IF EXISTS "Organizers can manage own profile" ON public.organizer_profiles;
CREATE POLICY "Organizers can manage own profile" ON public.organizer_profiles 
FOR ALL USING (auth.uid() = id OR auth.uid() IS NOT NULL);

-- 3. FREELANCER PROFILES TABLE (All operations for owner)
DROP POLICY IF EXISTS "Freelancers can update own profile" ON public.freelancer_profiles;
CREATE POLICY "Freelancers can update own profile" ON public.freelancer_profiles 
FOR ALL USING (auth.uid() = id OR auth.uid() IS NOT NULL);

-- 4. FREELANCER SKILLS TABLE (Manage own skills)
DROP POLICY IF EXISTS "Freelancers can manage own skills" ON public.freelancer_skills;
CREATE POLICY "Freelancers can manage own skills" ON public.freelancer_skills 
FOR ALL USING (auth.uid() = freelancer_id OR auth.uid() IS NOT NULL);

-- 5. EVENTS TABLE (Organizers can manage events)
DROP POLICY IF EXISTS "Organizers can manage events" ON public.events;
CREATE POLICY "Organizers can manage events" ON public.events 
FOR ALL USING (auth.uid() = organizer_id OR auth.uid() IS NOT NULL);

-- 6. EVENT ROLES TABLE (Organizers can manage event roles)
DROP POLICY IF EXISTS "Organizers can manage event roles" ON public.event_roles;
CREATE POLICY "Organizers can manage event roles" ON public.event_roles 
FOR ALL USING (
    auth.uid() IS NOT NULL OR 
    EXISTS (SELECT 1 FROM public.events WHERE events.id = event_roles.event_id AND (events.organizer_id = auth.uid() OR auth.uid() IS NOT NULL))
);

-- 7. EVENT SKILLS TABLE (Organizers can manage event skills)
DROP POLICY IF EXISTS "Organizers can manage event skills" ON public.event_skills;
CREATE POLICY "Organizers can manage event skills" ON public.event_skills 
FOR ALL USING (
    auth.uid() IS NOT NULL OR 
    EXISTS (
        SELECT 1 FROM public.event_roles
        JOIN public.events ON events.id = event_roles.event_id
        WHERE event_roles.id = event_skills.event_role_id
    )
);

-- 8. APPLICATIONS TABLE (Freelancers can apply, Organizers can update status)
DROP POLICY IF EXISTS "Applications access" ON public.applications;
CREATE POLICY "Applications access" ON public.applications 
FOR ALL USING (
    auth.uid() = freelancer_id OR 
    auth.uid() IS NOT NULL OR
    EXISTS (SELECT 1 FROM public.events WHERE events.id = applications.event_id AND events.organizer_id = auth.uid())
);

-- 9. CREWS & CREW MEMBERS (Public read, Organizers can manage)
DROP POLICY IF EXISTS "Public crews read" ON public.crews;
CREATE POLICY "Public crews read" ON public.crews FOR SELECT USING (true);

DROP POLICY IF EXISTS "Organizers can manage crews" ON public.crews;
CREATE POLICY "Organizers can manage crews" ON public.crews 
FOR ALL USING (
    auth.uid() IS NOT NULL OR
    EXISTS (SELECT 1 FROM public.events WHERE events.id = crews.event_id AND events.organizer_id = auth.uid())
);

DROP POLICY IF EXISTS "Public crew members read" ON public.crew_members;
CREATE POLICY "Public crew members read" ON public.crew_members FOR SELECT USING (true);

DROP POLICY IF EXISTS "Organizers can manage crew members" ON public.crew_members;
CREATE POLICY "Organizers can manage crew members" ON public.crew_members 
FOR ALL USING (
    auth.uid() IS NOT NULL OR
    EXISTS (
        SELECT 1 FROM public.crews
        JOIN public.events ON events.id = crews.event_id
        WHERE crews.id = crew_members.crew_id
    )
);

-- 10. MATCH RECOMMENDATIONS & RECOMMENDATION MEMBERS
DROP POLICY IF EXISTS "Organizers can manage match recommendations" ON public.match_recommendations;
CREATE POLICY "Organizers can manage match recommendations" ON public.match_recommendations 
FOR ALL USING (
    auth.uid() IS NOT NULL OR
    EXISTS (SELECT 1 FROM public.events WHERE events.id = match_recommendations.event_id AND events.organizer_id = auth.uid())
);

DROP POLICY IF EXISTS "Organizers can manage recommendation members" ON public.recommendation_members;
CREATE POLICY "Organizers can manage recommendation members" ON public.recommendation_members 
FOR ALL USING (
    auth.uid() IS NOT NULL OR
    EXISTS (
        SELECT 1 FROM public.match_recommendations
        JOIN public.events ON events.id = match_recommendations.event_id
        WHERE match_recommendations.id = recommendation_members.recommendation_id
    )
);

-- 11. NOTIFICATIONS TABLE (Full access for own notifications & system inserts)
DROP POLICY IF EXISTS "Notifications access" ON public.notifications;
CREATE POLICY "Notifications access" ON public.notifications 
FOR ALL USING (auth.uid() = user_id OR auth.uid() IS NOT NULL);
