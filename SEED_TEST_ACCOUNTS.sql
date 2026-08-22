-- ==============================================================================
-- MUSTER — Seed 8 Real Test Accounts (Supabase Auth & PostgreSQL Schema)
-- ==============================================================================
-- MIT India Hackathon 2026 | Track: PSE15
-- 
-- INSTRUCTIONS:
-- 1. Open Supabase Dashboard (https://app.supabase.com) -> SQL Editor
-- 2. Click "+ New Query", paste this script, and click "Run" (Ctrl+Enter)
-- 3. All 8 accounts will be created in auth.users and public tables with password:
--    Password for all test accounts: MusterTest@2026
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. SEED AUTH.USERS (Password: MusterTest@2026)
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
    updated_at
) VALUES 
-- Organizer 01 (Arjun Mehta - Indore)
(
    'a0000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'organizer01@muster.test',
    crypt('MusterTest@2026', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"organizer","full_name":"Arjun Mehta","company_name":"TechNova Events","city":"Indore, Madhya Pradesh"}',
    NOW(),
    NOW()
),
-- Organizer 02 (Riya Kapoor - Bhopal)
(
    'a0000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'organizer02@muster.test',
    crypt('MusterTest@2026', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"organizer","full_name":"Riya Kapoor","company_name":"NextWave Productions","city":"Bhopal, Madhya Pradesh"}',
    NOW(),
    NOW()
),
-- Freelancer 01 (Aarav Sharma - Indore)
(
    'f0000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'freelancer01@muster.test',
    crypt('MusterTest@2026', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"freelancer","full_name":"Aarav Sharma","primary_role":"Event Operations","city":"Indore, Madhya Pradesh"}',
    NOW(),
    NOW()
),
-- Freelancer 02 (Ishita Verma - Indore)
(
    'f0000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'freelancer02@muster.test',
    crypt('MusterTest@2026', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"freelancer","full_name":"Ishita Verma","primary_role":"Hospitality Specialist","city":"Indore, Madhya Pradesh"}',
    NOW(),
    NOW()
),
-- Freelancer 03 (Kabir Patel - Ujjain)
(
    'f0000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'freelancer03@muster.test',
    crypt('MusterTest@2026', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"freelancer","full_name":"Kabir Patel","primary_role":"AV & Technical Specialist","city":"Ujjain, Madhya Pradesh"}',
    NOW(),
    NOW()
),
-- Freelancer 04 (Ananya Joshi - Bhopal)
(
    'f0000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'freelancer04@muster.test',
    crypt('MusterTest@2026', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"freelancer","full_name":"Ananya Joshi","primary_role":"Stage Coordinator","city":"Bhopal, Madhya Pradesh"}',
    NOW(),
    NOW()
),
-- Freelancer 05 (Rohan Singh - Dewas)
(
    'f0000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'freelancer05@muster.test',
    crypt('MusterTest@2026', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"freelancer","full_name":"Rohan Singh","primary_role":"Crowd & Security Lead","city":"Dewas, Madhya Pradesh"}',
    NOW(),
    NOW()
),
-- Freelancer 06 (Meera Shah - Indore)
(
    'f0000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'freelancer06@muster.test',
    crypt('MusterTest@2026', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"freelancer","full_name":"Meera Shah","primary_role":"Registration Coordinator","city":"Indore, Madhya Pradesh"}',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET 
    encrypted_password = EXCLUDED.encrypted_password,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    updated_at = NOW();

-- 3. SEED PUBLIC.PROFILES
INSERT INTO public.profiles (id, email, full_name, role) VALUES
('a0000000-0000-0000-0000-000000000001', 'organizer01@muster.test', 'Arjun Mehta', 'organizer'),
('a0000000-0000-0000-0000-000000000002', 'organizer02@muster.test', 'Riya Kapoor', 'organizer'),
('f0000000-0000-0000-0000-000000000001', 'freelancer01@muster.test', 'Aarav Sharma', 'freelancer'),
('f0000000-0000-0000-0000-000000000002', 'freelancer02@muster.test', 'Ishita Verma', 'freelancer'),
('f0000000-0000-0000-0000-000000000003', 'freelancer03@muster.test', 'Kabir Patel', 'freelancer'),
('f0000000-0000-0000-0000-000000000004', 'freelancer04@muster.test', 'Ananya Joshi', 'freelancer'),
('f0000000-0000-0000-0000-000000000005', 'freelancer05@muster.test', 'Rohan Singh', 'freelancer'),
('f0000000-0000-0000-0000-000000000006', 'freelancer06@muster.test', 'Meera Shah', 'freelancer')
ON CONFLICT (id) DO UPDATE SET 
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    updated_at = NOW();

-- 4. SEED ORGANIZER PROFILES
INSERT INTO public.organizer_profiles (id, company_name, city, gst_number) VALUES
('a0000000-0000-0000-0000-000000000001', 'TechNova Events', 'Indore, Madhya Pradesh', '23AAACT1234F1Z5'),
('a0000000-0000-0000-0000-000000000002', 'NextWave Productions', 'Bhopal, Madhya Pradesh', '23AABCN5678K1Z2')
ON CONFLICT (id) DO UPDATE SET 
    company_name = EXCLUDED.company_name,
    city = EXCLUDED.city,
    updated_at = NOW();

-- 5. SEED FREELANCER PROFILES & METRICS
INSERT INTO public.freelancer_profiles (
    id, primary_role, hourly_rate, experience_years, reliability_score, match_score, distance_km, city, bio
) VALUES
-- Freelancer 01: Aarav Sharma (Senior, Indore, Balanced)
('f0000000-0000-0000-0000-000000000001', 'Event Operations', 1500, 5, 96, 94, 4.5, 'Indore, Madhya Pradesh', 'Senior operations and registration lead for mega festivals and conferences across MP.'),
-- Freelancer 02: Ishita Verma (Intermediate, Indore, Hospitality)
('f0000000-0000-0000-0000-000000000002', 'Hospitality Specialist', 1125, 3, 92, 90, 6.0, 'Indore, Madhya Pradesh', 'Guest relations, VIP delegate management, and smooth attendee onboarding specialist.'),
-- Freelancer 03: Kabir Patel (Senior AV, Ujjain, High Reliability)
('f0000000-0000-0000-0000-000000000003', 'AV & Technical Specialist', 1875, 6, 98, 96, 55.0, 'Ujjain, Madhya Pradesh', 'Audio consoles, stage lighting synchronization, and digital live streaming tech engineer.'),
-- Freelancer 04: Ananya Joshi (Intermediate, Bhopal, Coordination)
('f0000000-0000-0000-0000-000000000004', 'Stage Coordinator', 1250, 4, 91, 88, 190.0, 'Bhopal, Madhya Pradesh', 'Stage management, speaker cues, and run-of-show scheduling for high-profile summits.'),
-- Freelancer 05: Rohan Singh (Senior Security, Dewas, Top Reliability)
('f0000000-0000-0000-0000-000000000005', 'Crowd & Security Lead', 1750, 7, 99, 93, 38.0, 'Dewas, Madhya Pradesh', 'Venue perimeter security, crowd egress flow management, and emergency response coordinator.'),
-- Freelancer 06: Meera Shah (Junior, Indore, Budget / Closest)
('f0000000-0000-0000-0000-000000000006', 'Registration Coordinator', 875, 2, 85, 86, 3.0, 'Indore, Madhya Pradesh', 'Front-desk badge printing, attendee accreditation, and social media coordination.')
ON CONFLICT (id) DO UPDATE SET 
    primary_role = EXCLUDED.primary_role,
    hourly_rate = EXCLUDED.hourly_rate,
    experience_years = EXCLUDED.experience_years,
    reliability_score = EXCLUDED.reliability_score,
    match_score = EXCLUDED.match_score,
    distance_km = EXCLUDED.distance_km,
    city = EXCLUDED.city,
    bio = EXCLUDED.bio,
    updated_at = NOW();

-- 6. SEED FREELANCER SKILLS
DELETE FROM public.freelancer_skills WHERE freelancer_id IN (
    'f0000000-0000-0000-0000-000000000001',
    'f0000000-0000-0000-0000-000000000002',
    'f0000000-0000-0000-0000-000000000003',
    'f0000000-0000-0000-0000-000000000004',
    'f0000000-0000-0000-0000-000000000005',
    'f0000000-0000-0000-0000-000000000006'
);

INSERT INTO public.freelancer_skills (freelancer_id, skill_name) VALUES
-- Aarav Sharma
('f0000000-0000-0000-0000-000000000001', 'Event Management'),
('f0000000-0000-0000-0000-000000000001', 'Registration'),
('f0000000-0000-0000-0000-000000000001', 'Crowd Management'),
-- Ishita Verma
('f0000000-0000-0000-0000-000000000002', 'Hospitality'),
('f0000000-0000-0000-0000-000000000002', 'Guest Management'),
('f0000000-0000-0000-0000-000000000002', 'Registration'),
-- Kabir Patel
('f0000000-0000-0000-0000-000000000003', 'Technical Support'),
('f0000000-0000-0000-0000-000000000003', 'AV'),
('f0000000-0000-0000-0000-000000000003', 'Event Technology'),
-- Ananya Joshi
('f0000000-0000-0000-0000-000000000004', 'Hospitality'),
('f0000000-0000-0000-0000-000000000004', 'Coordination'),
('f0000000-0000-0000-0000-000000000004', 'Guest Management'),
-- Rohan Singh
('f0000000-0000-0000-0000-000000000005', 'Security'),
('f0000000-0000-0000-0000-000000000005', 'Crowd Management'),
('f0000000-0000-0000-0000-000000000005', 'Event Operations'),
-- Meera Shah
('f0000000-0000-0000-0000-000000000006', 'Registration'),
('f0000000-0000-0000-0000-000000000006', 'Social Media'),
('f0000000-0000-0000-0000-000000000006', 'Event Coordination');

-- 7. SEED SEPARATE EVENTS FOR ORGANIZER ISOLATION TESTING

-- Event A: Owned by Organizer 01 (Arjun Mehta - Indore)
INSERT INTO public.events (
    id, organizer_id, name, type, date, venue, city, budget, proximity_km, status, applicant_count, description
) VALUES (
    'e0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'Indore Tech Leaders Summit 2026',
    'Conference',
    '2026-10-15',
    'Brilliant Convention Centre, Indore',
    'Indore, Madhya Pradesh',
    120000,
    60,
    'published',
    6,
    'Premier tech leadership conclave in MP. Requiring technical AV leads, registration staff, hospitality and crowd management.'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, budget = EXCLUDED.budget;

-- Event B: Owned by Organizer 02 (Riya Kapoor - Bhopal)
INSERT INTO public.events (
    id, organizer_id, name, type, date, venue, city, budget, proximity_km, status, applicant_count, description
) VALUES (
    'e0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000002',
    'Bhopal Media & Design Conclave',
    'Exhibition',
    '2026-11-20',
    'Minto Hall Convention Centre, Bhopal',
    'Bhopal, Madhya Pradesh',
    95000,
    40,
    'published',
    2,
    'Design and media exhibition showcasing central Indian creative technology and media production.'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, budget = EXCLUDED.budget;

-- 8. SEED EVENT REQUIREMENTS FOR EVENT A (Indore Tech Leaders Summit)
INSERT INTO public.event_roles (event_id, role_name, quantity, max_rate_per_hour, min_experience_years) VALUES
('e0000000-0000-0000-0000-000000000001', 'AV & Technical Specialist', 1, 2200, 3),
('e0000000-0000-0000-0000-000000000001', 'Event Operations', 1, 1800, 3),
('e0000000-0000-0000-0000-000000000001', 'Registration Coordinator', 1, 1200, 1)
ON CONFLICT (event_id, role_name) DO NOTHING;

-- 9. SEED APPLICATIONS FROM ALL 6 FREELANCERS TO EVENT A (Indore Tech Leaders Summit)
INSERT INTO public.applications (event_id, freelancer_id, applied_role, proposed_rate, status, feedback) VALUES
-- Aarav Sharma
('e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', 'Event Operations', 1500, 'pending', 'Senior MP event operations specialist available for full shift.'),
-- Ishita Verma
('e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002', 'Registration Coordinator', 1125, 'pending', 'Hospitality & registration desk lead with 3 years conference experience.'),
-- Kabir Patel
('e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000003', 'AV & Technical Specialist', 1875, 'pending', 'High-reliability audio console and visual stream specialist.'),
-- Ananya Joshi
('e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000004', 'Event Operations', 1250, 'pending', 'Stage and speaker coordinator travelling from Bhopal.'),
-- Rohan Singh
('e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000005', 'Event Operations', 1750, 'pending', 'Top-tier 99% reliability score crowd and operations veteran from Dewas.'),
-- Meera Shah
('e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000006', 'Registration Coordinator', 875, 'pending', 'Closest proximity in Indore (3 km) offering budget-friendly registration support.')
ON CONFLICT (event_id, freelancer_id) DO UPDATE SET 
    proposed_rate = EXCLUDED.proposed_rate,
    status = EXCLUDED.status,
    updated_at = NOW();

-- 10. SEED INITIAL NOTIFICATIONS
INSERT INTO public.notifications (user_id, title, message, type, related_event_id) VALUES
('a0000000-0000-0000-0000-000000000001', 'New Shift Applications', '6 freelance specialists have applied for Indore Tech Leaders Summit 2026.', 'candidate_applied', 'e0000000-0000-0000-0000-000000000001'),
('f0000000-0000-0000-0000-000000000001', 'Application Submitted', 'Your application for Indore Tech Leaders Summit 2026 is under review.', 'application_update', 'e0000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;
