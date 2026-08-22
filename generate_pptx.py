import os
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

def create_presentation():
    prs = Presentation()
    # Set 16:9 Widescreen dimensions
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6] # Blank slide layout

    # Colors
    MIT_CRIMSON = RGBColor(163, 31, 52)
    MIT_AMBER = RGBColor(217, 119, 6)
    SLATE_900 = RGBColor(15, 23, 42)
    SLATE_800 = RGBColor(30, 41, 59)
    SLATE_700 = RGBColor(51, 65, 85)
    SLATE_600 = RGBColor(71, 85, 105)
    SLATE_500 = RGBColor(100, 116, 139)
    SLATE_200 = RGBColor(226, 232, 240)
    SLATE_100 = RGBColor(241, 245, 249)
    SLATE_50 = RGBColor(248, 250, 252)
    PURE_WHITE = RGBColor(255, 255, 255)
    EMERALD = RGBColor(67, 109, 79)
    EMERALD_LIGHT = RGBColor(235, 242, 238)
    CRIMSON_LIGHT = RGBColor(253, 242, 244)
    RED_ERROR = RGBColor(192, 57, 43)

    FONT_HEADING = "Inter"
    FONT_BODY = "Inter"
    FONT_MONO = "Consolas"

    def add_header(slide, slide_num, total_slides=12, dark=False):
        # Header background bar
        hdr = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.333), Inches(0.65))
        hdr.fill.solid()
        hdr.fill.fore_color.rgb = SLATE_900
        hdr.line.color.rgb = SLATE_800
        hdr.line.width = Pt(1)

        # Top progress gradient bar
        prog_w = Inches(13.333 * (slide_num / total_slides))
        prog = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), prog_w, Inches(0.05))
        prog.fill.solid()
        prog.fill.fore_color.rgb = MIT_CRIMSON
        prog.line.fill.background()

        # Logo text badge
        badge = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.6), Inches(0.14), Inches(1.1), Inches(0.36))
        badge.fill.solid()
        badge.fill.fore_color.rgb = MIT_CRIMSON
        badge.line.fill.background()
        tf = badge.text_frame
        tf.word_wrap = False
        p = tf.paragraphs[0]
        p.text = "MUSTER"
        p.font.name = FONT_HEADING
        p.font.size = Pt(11)
        p.font.bold = True
        p.font.color.rgb = PURE_WHITE
        p.alignment = PP_ALIGN.CENTER

        # Subtitle track
        tx = slide.shapes.add_textbox(Inches(1.85), Inches(0.12), Inches(8.5), Inches(0.4))
        tf = tx.text_frame
        p = tf.paragraphs[0]
        p.text = "MIT India Hackathon 2026 · Problem Statement: PSE15"
        p.font.name = FONT_BODY
        p.font.size = Pt(11)
        p.font.color.rgb = SLATE_400 = RGBColor(148, 163, 184)
        p.alignment = PP_ALIGN.LEFT

        # Slide Number Counter
        cnt = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(11.8), Inches(0.14), Inches(0.9), Inches(0.36))
        cnt.fill.solid()
        cnt.fill.fore_color.rgb = SLATE_800
        cnt.line.color.rgb = MIT_AMBER
        cnt.line.width = Pt(1)
        tf = cnt.text_frame
        p = tf.paragraphs[0]
        p.text = f"{slide_num:02d} / {total_slides:02d}"
        p.font.name = FONT_MONO
        p.font.size = Pt(10)
        p.font.bold = True
        p.font.color.rgb = MIT_AMBER
        p.alignment = PP_ALIGN.CENTER

    def set_slide_bg(slide, dark=False):
        bg = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0.65), Inches(13.333), Inches(6.85))
        bg.fill.solid()
        bg.fill.fore_color.rgb = SLATE_900 if dark else SLATE_50
        bg.line.fill.background()

    # ==========================================
    # SLIDE 01: COVER
    # ==========================================
    slide1 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide1, dark=True)
    add_header(slide1, 1, dark=True)

    # Logo image
    if os.path.exists("MUSTER_LOGO.png"):
        slide1.shapes.add_picture("MUSTER_LOGO.png", Inches(1.2), Inches(1.8), Inches(1.6), Inches(1.6))

    # Main Titles
    tx = slide1.shapes.add_textbox(Inches(3.1), Inches(1.6), Inches(9.0), Inches(2.2))
    tf = tx.text_frame
    tf.word_wrap = True
    
    p0 = tf.paragraphs[0]
    p0.text = "MIT INDIA HACKATHON 2026 · PSE15"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(13)
    p0.font.bold = True
    p0.font.color.rgb = MIT_AMBER

    p1 = tf.add_paragraph()
    p1.text = "MUSTER"
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(56)
    p1.font.bold = True
    p1.font.color.rgb = PURE_WHITE

    p2 = tf.add_paragraph()
    p2.text = "AI-Powered Crew Assembly for Event Staffing"
    p2.font.name = FONT_BODY
    p2.font.size = Pt(22)
    p2.font.color.rgb = RGBColor(203, 213, 225)

    # 3 Metadata Pills
    pill_data = [
        "Flutter Web + Android + iOS",
        "Supabase PostgreSQL + RLS",
        "Google Gemini API (Edge)"
    ]
    for i, p_text in enumerate(pill_data):
        pill = slide1.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.2 + (i * 3.7)), Inches(4.8), Inches(3.4), Inches(0.9))
        pill.fill.solid()
        pill.fill.fore_color.rgb = SLATE_800
        pill.line.color.rgb = SLATE_700
        pill.line.width = Pt(1)
        tf = pill.text_frame
        p = tf.paragraphs[0]
        p.text = p_text
        p.font.name = FONT_MONO
        p.font.size = Pt(12)
        p.font.bold = True
        p.font.color.rgb = PURE_WHITE
        p.alignment = PP_ALIGN.CENTER

    # ==========================================
    # SLIDE 02: THE PROBLEM
    # ==========================================
    slide2 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide2, dark=False)
    add_header(slide2, 2)

    # Title & Subtitle
    tx = slide2.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "THE REALITY OF EVENT STAFFING"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_CRIMSON

    p1 = tf.add_paragraph()
    p1.text = "Finding a crew is harder than it looks."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(32)
    p1.font.bold = True
    p1.font.color.rgb = SLATE_900

    p2 = tf.add_paragraph()
    p2.text = "Organizers have to balance all of these at once."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(16)
    p2.font.color.rgb = SLATE_600

    # Left Container: Balance Factors
    factors = [
        ("Skills & Specific Roles Needed", MIT_CRIMSON),
        ("Strict Financial Budget Cap", MIT_AMBER),
        ("Date & Shift Availability", SLATE_700),
        ("Location & Travel Distance", EMERALD),
        ("Historical Reliability Record", SLATE_700)
    ]
    left_card = slide2.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0), Inches(2.4), Inches(5.4), Inches(4.3))
    left_card.fill.solid()
    left_card.fill.fore_color.rgb = SLATE_100
    left_card.line.color.rgb = SLATE_200

    for i, (f_title, f_color) in enumerate(factors):
        sub_card = slide2.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.3), Inches(2.65 + (i * 0.76)), Inches(4.8), Inches(0.6))
        sub_card.fill.solid()
        sub_card.fill.fore_color.rgb = PURE_WHITE
        sub_card.line.color.rgb = SLATE_200
        tf = sub_card.text_frame
        p = tf.paragraphs[0]
        p.text = f"• {f_title}"
        p.font.name = FONT_HEADING
        p.font.size = Pt(13)
        p.font.bold = True
        p.font.color.rgb = f_color

    # Right Containers: Real-world pain points
    pains = [
        ("Single Missing Role = Event Failure", "Missing just one Dante sound engineer or stage coordinator puts the entire live event at risk.", RED_ERROR),
        ("Unmonitored Rate Spikes = Budget Overruns", "Hiring people one by one through phone calls creates rate compounding that breaches the organizer's financial ceiling.", RED_ERROR),
        ("No-Show Risk on Event Morning", "Unvetted freelance contacts suffer high no-show rates with zero accountability or standby alternatives.", RED_ERROR)
    ]
    for i, (title, desc, color) in enumerate(pains):
        card = slide2.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(6.8), Inches(2.4 + (i * 1.45)), Inches(5.5), Inches(1.28))
        card.fill.solid()
        card.fill.fore_color.rgb = PURE_WHITE
        card.line.color.rgb = SLATE_200
        
        # Left accent stripe
        stripe = slide2.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(6.8), Inches(2.4 + (i * 1.45)), Inches(0.12), Inches(1.28))
        stripe.fill.solid()
        stripe.fill.fore_color.rgb = color
        stripe.line.fill.background()

        tf = card.text_frame
        tf.margin_left = Inches(0.3)
        p0 = tf.paragraphs[0]
        p0.text = title
        p0.font.name = FONT_HEADING
        p0.font.size = Pt(14)
        p0.font.bold = True
        p0.font.color.rgb = color

        p1 = tf.add_paragraph()
        p1.text = desc
        p1.font.name = FONT_BODY
        p1.font.size = Pt(11)
        p1.font.color.rgb = SLATE_600

    # ==========================================
    # SLIDE 03: WHY CURRENT METHODS ARE SLOW
    # ==========================================
    slide3 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide3, dark=False)
    add_header(slide3, 3)

    tx = slide3.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "CURRENT PRACTICES"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_CRIMSON

    p1 = tf.add_paragraph()
    p1.text = "Too much manual work."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(32)
    p1.font.bold = True
    p1.font.color.rgb = SLATE_900

    p2 = tf.add_paragraph()
    p2.text = "When organizers hire manually across fragmented chats, it takes days and errors are easy to make."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(16)
    p2.font.color.rgb = SLATE_600

    # Flow Banner: WhatsApp + Spreadsheets + Calls + Manual Math
    flow_items = ["WhatsApp Chats", "+", "Spreadsheets", "+", "Phone Calls", "+", "Manual Math"]
    flow_box = slide3.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0), Inches(2.4), Inches(11.3), Inches(1.1))
    flow_box.fill.solid()
    flow_box.fill.fore_color.rgb = SLATE_900
    flow_box.line.fill.background()
    tf = flow_box.text_frame
    p = tf.paragraphs[0]
    p.text = "   WhatsApp Chats   +   Spreadsheets   +   Phone Calls   +   Manual Math"
    p.font.name = FONT_MONO
    p.font.size = Pt(16)
    p.font.bold = True
    p.font.color.rgb = PURE_WHITE
    p.alignment = PP_ALIGN.CENTER

    # 3 Comparison Cards
    cards_data = [
        ("Slow Confirmation", "Takes 3 to 5 days to assemble a 6-person crew. Candidates drop out while waiting for responses.", MIT_CRIMSON),
        ("Unchecked Rates", "Manual rate calculations often overlook overtime, lead fees, or transit stipends, blowing the budget.", MIT_AMBER),
        ("Zero Accountability", "No verified reliability score. Organizers rely on blind trust with short-notice freelancers.", SLATE_700)
    ]
    for i, (title, desc, color) in enumerate(cards_data):
        card = slide3.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0 + (i * 3.9)), Inches(3.8), Inches(3.6), Inches(2.8))
        card.fill.solid()
        card.fill.fore_color.rgb = PURE_WHITE
        card.line.color.rgb = SLATE_200

        top_bar = slide3.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(1.0 + (i * 3.9)), Inches(3.8), Inches(3.6), Inches(0.1))
        top_bar.fill.solid()
        top_bar.fill.fore_color.rgb = color
        top_bar.line.fill.background()

        tf = card.text_frame
        tf.margin_top = Inches(0.3)
        p0 = tf.paragraphs[0]
        p0.text = title
        p0.font.name = FONT_HEADING
        p0.font.size = Pt(16)
        p0.font.bold = True
        p0.font.color.rgb = SLATE_900

        p1 = tf.add_paragraph()
        p1.text = desc
        p1.font.name = FONT_BODY
        p1.font.size = Pt(12)
        p1.font.color.rgb = SLATE_600

    # ==========================================
    # SLIDE 04: OUR SOLUTION
    # ==========================================
    slide4 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide4, dark=True)
    add_header(slide4, 4, dark=True)

    tx = slide4.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "THE MUSTER PLATFORM"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_AMBER

    p1 = tf.add_paragraph()
    p1.text = "Meet MUSTER."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(36)
    p1.font.bold = True
    p1.font.color.rgb = PURE_WHITE

    p2 = tf.add_paragraph()
    p2.text = "MUSTER helps organizers find and assemble the right crew for an event."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(18)
    p2.font.color.rgb = RGBColor(203, 213, 225)

    # 2 Big Cards: Organizers & Freelancers
    org_card = slide4.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0), Inches(2.5), Inches(5.4), Inches(4.2))
    org_card.fill.solid()
    org_card.fill.fore_color.rgb = SLATE_800
    org_card.line.color.rgb = MIT_AMBER
    org_card.line.width = Pt(1.5)
    tf = org_card.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "FOR EVENT ORGANIZERS"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(13)
    p0.font.bold = True
    p0.font.color.rgb = MIT_AMBER

    points_org = [
        "Post role quotas, transit radius, and budget limits.",
        "Receive custom hourly bids from vetted freelancers.",
        "Deterministic solver calculates valid crew rosters in seconds.",
        "Plain-English AI explanations for each recommendation."
    ]
    for pt in points_org:
        p = tf.add_paragraph()
        p.text = f"✓  {pt}"
        p.font.name = FONT_BODY
        p.font.size = Pt(12)
        p.font.color.rgb = PURE_WHITE

    free_card = slide4.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(6.9), Inches(2.5), Inches(5.4), Inches(4.2))
    free_card.fill.solid()
    free_card.fill.fore_color.rgb = SLATE_800
    free_card.line.color.rgb = EMERALD
    free_card.line.width = Pt(1.5)
    tf = free_card.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "FOR FREELANCERS"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(13)
    p0.font.bold = True
    p0.font.color.rgb = RGBColor(110, 231, 183)

    points_free = [
        "Discover shifts within daily travel radius.",
        "Submit custom hourly rate bids directly.",
        "Live status updates on application review.",
        "Verified digital QR dispatch entry pass on selection."
    ]
    for pt in points_free:
        p = tf.add_paragraph()
        p.text = f"✓  {pt}"
        p.font.name = FONT_BODY
        p.font.size = Pt(12)
        p.font.color.rgb = PURE_WHITE

    # ==========================================
    # SLIDE 05: HOW IT WORKS
    # ==========================================
    slide5 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide5, dark=False)
    add_header(slide5, 5)

    tx = slide5.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "THE 5-STEP WORKFLOW"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_CRIMSON

    p1 = tf.add_paragraph()
    p1.text = "How it works."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(32)
    p1.font.bold = True
    p1.font.color.rgb = SLATE_900

    p2 = tf.add_paragraph()
    p2.text = "A clear step-by-step path from an open brief to confirmed on-site staff."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(16)
    p2.font.color.rgb = SLATE_600

    # 5 Flow Steps
    steps = [
        ("1. Create Event", "Set roles, budget cap, and location.", MIT_CRIMSON),
        ("2. Freelancers Apply", "Verified crew bid custom hourly rates.", SLATE_700),
        ("3. Compare Pool", "Filter by role, skills, distance, and rate.", SLATE_700),
        ("4. Find Best Crew", "Solver prunes budget violations with AI rationale.", MIT_AMBER),
        ("5. Approve Roster", "Lock shifts with atomic PostgreSQL RPC.", EMERALD)
    ]
    for i, (s_title, s_desc, color) in enumerate(steps):
        step_box = slide5.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0 + (i * 2.3)), Inches(2.5), Inches(2.1), Inches(4.1))
        step_box.fill.solid()
        step_box.fill.fore_color.rgb = PURE_WHITE
        step_box.line.color.rgb = SLATE_200

        top_tag = slide5.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(1.0 + (i * 2.3)), Inches(2.5), Inches(2.1), Inches(0.12))
        top_tag.fill.solid()
        top_tag.fill.fore_color.rgb = color
        top_tag.line.fill.background()

        tf = step_box.text_frame
        tf.margin_top = Inches(0.25)
        p0 = tf.paragraphs[0]
        p0.text = s_title
        p0.font.name = FONT_HEADING
        p0.font.size = Pt(14)
        p0.font.bold = True
        p0.font.color.rgb = color

        p1 = tf.add_paragraph()
        p1.text = s_desc
        p1.font.name = FONT_BODY
        p1.font.size = Pt(11)
        p1.font.color.rgb = SLATE_600

    # ==========================================
    # SLIDE 06: WHAT MUSTER LOOKS AT
    # ==========================================
    slide6 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide6, dark=False)
    add_header(slide6, 6)

    tx = slide6.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "MULTI-CRITERIA MATCHING WEIGHTS"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_CRIMSON

    p1 = tf.add_paragraph()
    p1.text = "The cheapest person isn't always the best fit."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(32)
    p1.font.bold = True
    p1.font.color.rgb = SLATE_900

    p2 = tf.add_paragraph()
    p2.text = "MUSTER balances multiple operational factors together."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(16)
    p2.font.color.rgb = SLATE_600

    weights = [
        ("40%", "Skills & Experience", "Direct alignment with equipment, sound consoles, stage management, and certifications.", MIT_CRIMSON),
        ("35%", "Reliability Rating", "Verified historical punctuality, event completion track record, and organizer reviews.", EMERALD),
        ("15%", "Transit Proximity", "Distance from venue to guarantee timely arrival without transit risk.", SLATE_700),
        ("10%", "Rate Efficiency", "Candidate hourly proposal relative to the event budget allocation.", MIT_AMBER)
    ]
    for i, (pct, title, desc, color) in enumerate(weights):
        card = slide6.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0 + (i * 2.9)), Inches(2.5), Inches(2.7), Inches(3.4))
        card.fill.solid()
        card.fill.fore_color.rgb = PURE_WHITE
        card.line.color.rgb = SLATE_200

        tf = card.text_frame
        p0 = tf.paragraphs[0]
        p0.text = pct
        p0.font.name = FONT_HEADING
        p0.font.size = Pt(36)
        p0.font.bold = True
        p0.font.color.rgb = color

        p1 = tf.add_paragraph()
        p1.text = title
        p1.font.name = FONT_HEADING
        p1.font.size = Pt(14)
        p1.font.bold = True
        p1.font.color.rgb = SLATE_900

        p2 = tf.add_paragraph()
        p2.text = desc
        p2.font.name = FONT_BODY
        p2.font.size = Pt(11)
        p2.font.color.rgb = SLATE_600

    # Summary box
    bot_box = slide6.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0), Inches(6.1), Inches(11.3), Inches(0.8))
    bot_box.fill.solid()
    bot_box.fill.fore_color.rgb = EMERALD_LIGHT
    bot_box.line.color.rgb = EMERALD
    tf = bot_box.text_frame
    p = tf.paragraphs[0]
    p.text = "Result: Reliable, skilled crew members who arrive on time and stay within budget."
    p.font.name = FONT_HEADING
    p.font.size = Pt(13)
    p.font.bold = True
    p.font.color.rgb = EMERALD
    p.alignment = PP_ALIGN.CENTER

    # ==========================================
    # SLIDE 07: WHERE AI FITS
    # ==========================================
    slide7 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide7, dark=True)
    add_header(slide7, 7, dark=True)

    tx = slide7.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "HONEST ARCHITECTURAL SEPARATION"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_AMBER

    p1 = tf.add_paragraph()
    p1.text = "AI helps. The system checks."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(32)
    p1.font.bold = True
    p1.font.color.rgb = PURE_WHITE

    p2 = tf.add_paragraph()
    p2.text = "The matching engine checks the rules. Gemini explains the result."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(16)
    p2.font.color.rgb = RGBColor(203, 213, 225)

    # 2 Comparison Columns
    engine_box = slide7.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0), Inches(2.5), Inches(5.4), Inches(4.3))
    engine_box.fill.solid()
    engine_box.fill.fore_color.rgb = SLATE_800
    engine_box.line.color.rgb = SLATE_600
    tf = engine_box.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "DETERMINISTIC MATCHING ENGINE"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(12)
    p0.font.bold = True
    p0.font.color.rgb = MIT_AMBER

    p1 = tf.add_paragraph()
    p1.text = "Guarantees Hard Rules"
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(20)
    p1.font.bold = True
    p1.font.color.rgb = PURE_WHITE

    rules = [
        "100% Budget Compliance Guarantee (Cost ≤ Budget)",
        "Zero Missing Roles: Fulfills exact role quota requirements",
        "Geographic distance constraint enforcement",
        "Deterministic: Zero hallucination of fake candidates"
    ]
    for r in rules:
        p = tf.add_paragraph()
        p.text = f"•  {r}"
        p.font.name = FONT_BODY
        p.font.size = Pt(12)
        p.font.color.rgb = RGBColor(226, 232, 240)

    ai_box = slide7.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(6.9), Inches(2.5), Inches(5.4), Inches(4.3))
    ai_box.fill.solid()
    ai_box.fill.fore_color.rgb = SLATE_800
    ai_box.line.color.rgb = MIT_CRIMSON
    tf = ai_box.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "GOOGLE GEMINI 3.6 FLASH (EDGE)"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(12)
    p0.font.bold = True
    p0.font.color.rgb = RGBColor(253, 164, 175)

    p1 = tf.add_paragraph()
    p1.text = "Generates Human Explanations"
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(20)
    p1.font.bold = True
    p1.font.color.rgb = PURE_WHITE

    ai_roles = [
        "Synthesizes plain-English rationale for each candidate chosen",
        "Explains trade-offs between cost savings and senior experience",
        "Assists organizer with NLP brief parameter extraction",
        "Securely isolated server-side inside Supabase Edge Function"
    ]
    for a in ai_roles:
        p = tf.add_paragraph()
        p.text = f"•  {a}"
        p.font.name = FONT_BODY
        p.font.size = Pt(12)
        p.font.color.rgb = RGBColor(226, 232, 240)

    # ==========================================
    # SLIDE 08: BUDGET
    # ==========================================
    slide8 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide8, dark=False)
    add_header(slide8, 8)

    tx = slide8.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "BUDGET ALLOCATION & PERMUTATIONS"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_CRIMSON

    p1 = tf.add_paragraph()
    p1.text = "The crew must fit the budget."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(32)
    p1.font.bold = True
    p1.font.color.rgb = SLATE_900

    p2 = tf.add_paragraph()
    p2.text = "Organizers can compare different valid crews before deciding."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(16)
    p2.font.color.rgb = SLATE_600

    permutations = [
        ("OPTION 1 · BALANCED FIT", "₹94,000", "92% Match Score", "Highest multi-factor balance across skills, reliability, and proximity. Saves ₹6,000 under budget.", MIT_CRIMSON),
        ("OPTION 2 · COST SAVER", "₹84,000", "85% Match Score", "Prioritizes competitive rate bids while meeting all core role requirements. Saves ₹16,000 under budget.", MIT_AMBER),
        ("OPTION 3 · TOP RELIABILITY", "₹98,500", "96% Reliability Avg", "Selects top-rated 98%+ reliability crew members for mission-critical keynotes and VIP stages.", EMERALD)
    ]
    for i, (tag, price, match, desc, color) in enumerate(permutations):
        card = slide8.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0 + (i * 3.9)), Inches(2.5), Inches(3.6), Inches(4.3))
        card.fill.solid()
        card.fill.fore_color.rgb = PURE_WHITE
        card.line.color.rgb = SLATE_200

        top_tag = slide8.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(1.0 + (i * 3.9)), Inches(2.5), Inches(3.6), Inches(0.12))
        top_tag.fill.solid()
        top_tag.fill.fore_color.rgb = color
        top_tag.line.fill.background()

        tf = card.text_frame
        tf.margin_top = Inches(0.25)
        p0 = tf.paragraphs[0]
        p0.text = tag
        p0.font.name = FONT_MONO
        p0.font.size = Pt(10)
        p0.font.bold = True
        p0.font.color.rgb = color

        p1 = tf.add_paragraph()
        p1.text = price
        p1.font.name = FONT_HEADING
        p1.font.size = Pt(32)
        p1.font.bold = True
        p1.font.color.rgb = SLATE_900

        p2 = tf.add_paragraph()
        p2.text = match
        p2.font.name = FONT_HEADING
        p2.font.size = Pt(13)
        p2.font.bold = True
        p2.font.color.rgb = color

        p3 = tf.add_paragraph()
        p3.text = desc
        p3.font.name = FONT_BODY
        p3.font.size = Pt(12)
        p3.font.color.rgb = SLATE_600

    # ==========================================
    # SLIDE 09: PRODUCT DEMO
    # ==========================================
    slide9 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide9, dark=False)
    add_header(slide9, 9)

    tx = slide9.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "WORKING PRODUCT EVIDENCE"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_CRIMSON

    p1 = tf.add_paragraph()
    p1.text = "From brief to confirmed crew."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(32)
    p1.font.bold = True
    p1.font.color.rgb = SLATE_900

    p2 = tf.add_paragraph()
    p2.text = "Real working screens from the running MUSTER Flutter application."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(16)
    p2.font.color.rgb = SLATE_600

    # 4 Product Screenshots
    shot_items = [
        ("screenshots/02_organizer_dashboard.png", "1. Active Dashboard"),
        ("screenshots/03_apply_modal.png", "2. Applicant Pool"),
        ("screenshots/05_solver_recommendation.png", "3. AI Optimizer Modal"),
        ("screenshots/06_final_crew.png", "4. Confirmed Crew")
    ]
    for i, (path, label) in enumerate(shot_items):
        x_pos = Inches(1.0 + (i * 2.9))
        if os.path.exists(path):
            slide9.shapes.add_picture(path, x_pos, Inches(2.5), Inches(2.7), Inches(3.6))
        
        lbl = slide9.shapes.add_shape(MSO_SHAPE.RECTANGLE, x_pos, Inches(6.2), Inches(2.7), Inches(0.4))
        lbl.fill.solid()
        lbl.fill.fore_color.rgb = SLATE_900
        lbl.line.fill.background()
        tf = lbl.text_frame
        p = tf.paragraphs[0]
        p.text = label
        p.font.name = FONT_HEADING
        p.font.size = Pt(10)
        p.font.bold = True
        p.font.color.rgb = PURE_WHITE
        p.alignment = PP_ALIGN.CENTER

    # ==========================================
    # SLIDE 10: TECH STACK
    # ==========================================
    slide10 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide10, dark=True)
    add_header(slide10, 10, dark=True)

    tx = slide10.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "SYSTEM ARCHITECTURE"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_AMBER

    p1 = tf.add_paragraph()
    p1.text = "Built for Web, Android and iOS."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(32)
    p1.font.bold = True
    p1.font.color.rgb = PURE_WHITE

    p2 = tf.add_paragraph()
    p2.text = "Clean cross-platform client talking to Supabase and Gemini Edge Functions."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(16)
    p2.font.color.rgb = RGBColor(203, 213, 225)

    stack_cards = [
        ("FRONTEND CLIENT", "Flutter (Web & Mobile)", "Single responsive codebase with Riverpod state management and Lucide vector icons.", RGBColor(96, 165, 250)),
        ("BACKEND ENGINE", "Supabase PostgreSQL", "13 relational tables with Row Level Security (RLS) and real-time pub/sub subscriptions.", RGBColor(52, 211, 153)),
        ("EDGE FUNCTION", "Deno Edge Runtime", "Server-side function `muster-ai` coordinates with Gemini without exposing API keys.", MIT_AMBER),
        ("AI LAYER", "Google Gemini 3.6 Flash", "Generates natural language requirement parsing and transparent hiring explanations.", RGBColor(244, 114, 182))
    ]
    for i, (tag, title, desc, color) in enumerate(stack_cards):
        card = slide10.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0 + (i * 2.9)), Inches(2.5), Inches(2.7), Inches(4.3))
        card.fill.solid()
        card.fill.fore_color.rgb = SLATE_800
        card.line.color.rgb = SLATE_700

        top_tag = slide10.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(1.0 + (i * 2.9)), Inches(2.5), Inches(2.7), Inches(0.12))
        top_tag.fill.solid()
        top_tag.fill.fore_color.rgb = color
        top_tag.line.fill.background()

        tf = card.text_frame
        tf.margin_top = Inches(0.25)
        p0 = tf.paragraphs[0]
        p0.text = tag
        p0.font.name = FONT_MONO
        p0.font.size = Pt(10)
        p0.font.bold = True
        p0.font.color.rgb = color

        p1 = tf.add_paragraph()
        p1.text = title
        p1.font.name = FONT_HEADING
        p1.font.size = Pt(15)
        p1.font.bold = True
        p1.font.color.rgb = PURE_WHITE

        p2 = tf.add_paragraph()
        p2.text = desc
        p2.font.name = FONT_BODY
        p2.font.size = Pt(11)
        p2.font.color.rgb = RGBColor(203, 213, 225)

    # ==========================================
    # SLIDE 11: WHY MUSTER
    # ==========================================
    slide11 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide11, dark=False)
    add_header(slide11, 11)

    tx = slide11.shapes.add_textbox(Inches(1.0), Inches(1.0), Inches(11.3), Inches(1.2))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "KEY ADVANTAGES"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(11)
    p0.font.bold = True
    p0.font.color.rgb = MIT_CRIMSON

    p1 = tf.add_paragraph()
    p1.text = "Why MUSTER."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(32)
    p1.font.bold = True
    p1.font.color.rgb = SLATE_900

    p2 = tf.add_paragraph()
    p2.text = "Built to solve the operational realities of live event staffing."
    p2.font.name = FONT_BODY
    p2.font.size = Pt(16)
    p2.font.color.rgb = SLATE_600

    pillars = [
        ("Constraint-aware", "Strictly works within real event requirements, transit limits, and budget caps.", MIT_CRIMSON),
        ("Explainable", "Shows clear natural-language reasons why candidates were chosen for each shift.", MIT_AMBER),
        ("Human-controlled", "AI recommends options and highlights trade-offs; the organizer always decides.", EMERALD),
        ("Cross-platform", "One clean codebase deployable immediately to Web, Android phones, and iOS devices.", SLATE_700)
    ]
    for i, (title, desc, color) in enumerate(pillars):
        x = Inches(1.0 if (i % 2 == 0) else 6.9)
        y = Inches(2.5 if (i < 2) else 4.7)
        card = slide11.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, x, y, Inches(5.4), Inches(2.0))
        card.fill.solid()
        card.fill.fore_color.rgb = PURE_WHITE
        card.line.color.rgb = SLATE_200

        stripe = slide11.shapes.add_shape(MSO_SHAPE.RECTANGLE, x, y, Inches(0.15), Inches(2.0))
        stripe.fill.solid()
        stripe.fill.fore_color.rgb = color
        stripe.line.fill.background()

        tf = card.text_frame
        tf.margin_left = Inches(0.3)
        p0 = tf.paragraphs[0]
        p0.text = title
        p0.font.name = FONT_HEADING
        p0.font.size = Pt(18)
        p0.font.bold = True
        p0.font.color.rgb = color

        p1 = tf.add_paragraph()
        p1.text = desc
        p1.font.name = FONT_BODY
        p1.font.size = Pt(13)
        p1.font.color.rgb = SLATE_600

    # ==========================================
    # SLIDE 12: CLOSING
    # ==========================================
    slide12 = prs.slides.add_slide(blank_layout)
    set_slide_bg(slide12, dark=True)
    add_header(slide12, 12, dark=True)

    tx = slide12.shapes.add_textbox(Inches(1.2), Inches(1.5), Inches(10.5), Inches(2.4))
    tf = tx.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "MIT INDIA HACKATHON 2026 · PSE15"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(13)
    p0.font.bold = True
    p0.font.color.rgb = MIT_AMBER

    p1 = tf.add_paragraph()
    p1.text = "From applicants\nto the right crew."
    p1.font.name = FONT_HEADING
    p1.font.size = Pt(48)
    p1.font.bold = True
    p1.font.color.rgb = PURE_WHITE

    p2 = tf.add_paragraph()
    p2.text = "MUSTER · AI-Powered Crew Assembly for Event Staffing"
    p2.font.name = FONT_BODY
    p2.font.size = Pt(20)
    p2.font.color.rgb = RGBColor(203, 213, 225)

    deliverable_box = slide12.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.2), Inches(4.3), Inches(10.5), Inches(2.2))
    deliverable_box.fill.solid()
    deliverable_box.fill.fore_color.rgb = SLATE_800
    deliverable_box.line.color.rgb = SLATE_700
    tf = deliverable_box.text_frame
    tf.margin_top = Inches(0.2)
    tf.margin_left = Inches(0.4)

    p0 = tf.paragraphs[0]
    p0.text = "VERIFIED PRODUCTION DELIVERABLES"
    p0.font.name = FONT_MONO
    p0.font.size = Pt(12)
    p0.font.bold = True
    p0.font.color.rgb = MIT_AMBER

    items = [
        ("Web Application Live Build", "Vercel SPA Deployment (build/web)"),
        ("Android Release Binary", "APK/MUSTER-v1.0.apk (57.1 MB) with native network access"),
        ("Supabase Cloud Backend", "13 Relational Tables + RLS + Deno Gemini Edge Function"),
        ("Source Code Repository", "https://github.com/parikshitkurel/muster.git")
    ]
    for title, desc in items:
        p = tf.add_paragraph()
        p.text = f"•  {title}: {desc}"
        p.font.name = FONT_BODY
        p.font.size = Pt(11)
        p.font.color.rgb = RGBColor(226, 232, 240)

    # Save PPTX
    output_path = "MUSTER_PRESENTATION.pptx"
    prs.save(output_path)
    print(f"Presentation generated successfully: {output_path}")

if __name__ == "__main__":
    create_presentation()
