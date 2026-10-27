#!/usr/bin/env python3
"""
Play Store Screenshot Generator for Speed Math
Generates 10 high-resolution (1440x2560, 9:16) Play Store screenshots
featuring Samsung S25 Ultra device frames, painterly brush badges with vector accents,
licensed handwritten Kalam fonts, and curated aesthetic color palettes.
Zero missing glyphs / zero tofu boxes guaranteed.
"""

import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# -------------------------------------------------------------------------
# Configurations & Palette Definitions
# -------------------------------------------------------------------------
CANVAS_WIDTH = 1440
CANVAS_HEIGHT = 2560

# Exact Samsung S25 Ultra frame dimensions matching 1080x2340 aspect ratio
SCREEN_WIDTH = 886
SCREEN_HEIGHT = 1920
BEZEL = 16
FRAME_WIDTH = SCREEN_WIDTH + BEZEL * 2  # 918
FRAME_HEIGHT = SCREEN_HEIGHT + BEZEL * 2 # 1952
FRAME_RADIUS = 34
SCREEN_RADIUS = 26

PHONE_X = (CANVAS_WIDTH - FRAME_WIDTH) // 2 # 261
PHONE_Y = CANVAS_HEIGHT - FRAME_HEIGHT - 54 # 554

def hex_to_rgb(hex_str):
    h = hex_str.lstrip('#').replace(' ', '')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

# 5 Color Palettes from user prompt:
PALETTE_ACID_CHARCOAL = {
    'bg': hex_to_rgb('242424'),
    'brush': hex_to_rgb('DFFF00'),
    'brush_text': hex_to_rgb('242424'),
    'headline': hex_to_rgb('F2F2E8'),
    'subtitle': hex_to_rgb('9B9E95'),
}

PALETTE_NAVY_BUTTER = {
    'bg': hex_to_rgb('263D8D'),
    'brush': hex_to_rgb('F3DEA0'),
    'brush_text': hex_to_rgb('263D8D'),
    'headline': hex_to_rgb('FAF7EE'),
    'subtitle': hex_to_rgb('A9C4E8'),
}

PALETTE_TERRACOTTA_PEACH = {
    'bg': hex_to_rgb('C45132'),
    'brush': hex_to_rgb('F1B79B'),
    'brush_text': hex_to_rgb('272233'),
    'headline': hex_to_rgb('F7EBDD'),
    'subtitle': hex_to_rgb('F7EBDD'),
}

PALETTE_FOREST_GOLD = {
    'bg': hex_to_rgb('18392B'),
    'brush': hex_to_rgb('C1A16A'),
    'brush_text': hex_to_rgb('18392B'),
    'headline': hex_to_rgb('E9E1CE'),
    'subtitle': hex_to_rgb('8CA17B'),
}

PALETTE_PLUM_BLUSH = {
    'bg': hex_to_rgb('462B52'),
    'brush': hex_to_rgb('E7C9D2'),
    'brush_text': hex_to_rgb('462B52'),
    'headline': hex_to_rgb('F5EEE8'),
    'subtitle': hex_to_rgb('A77B9E'),
}

# -------------------------------------------------------------------------
# Slide Content Definitions (All 10 Raw Screenshots - Zero Emojis in Text)
# -------------------------------------------------------------------------
SLIDES = [
    {
        'output_name': '01_home_screen.png',
        'raw_image': 'home screen.jpeg',
        'palette': PALETTE_ACID_CHARCOAL,
        'badge': 'SPEED & ACCURACY',
        'has_bolt': True,
        'headline': 'Master Mental Math',
        'subtitle': 'Daily Streaks • Habit Goals • XP Levels',
    },
    {
        'output_name': '02_learn_shortcuts.png',
        'raw_image': 'learn shortcuts topics.jpg.jpeg',
        'palette': PALETTE_NAVY_BUTTER,
        'badge': 'STEP-BY-STEP TRICKS',
        'has_bolt': False,
        'headline': '26 Rapid Shortcuts',
        'subtitle': 'Addition, Subtraction, Squares & Mental Roots',
    },
    {
        'output_name': '03_shortcut_whiteboard_mult.png',
        'raw_image': 'shortcut board-1.jpeg',
        'palette': PALETTE_TERRACOTTA_PEACH,
        'badge': 'VISUAL WHITEBOARD',
        'has_bolt': False,
        'headline': 'Criss-Cross Multiply',
        'subtitle': 'Break Down Big Calculations in 3 Simple Steps',
    },
    {
        'output_name': '04_shortcut_custom_numbers.png',
        'raw_image': 'shortcut board - 2.jpeg',
        'palette': PALETTE_FOREST_GOLD,
        'badge': 'INTERACTIVE PRACTICE',
        'has_bolt': False,
        'headline': 'Custom Number Drills',
        'subtitle': 'Try Any Numbers & See Instant Breakdown Steps',
    },
    {
        'output_name': '05_adaptive_practice_modes.png',
        'raw_image': 'practice modes.jpeg',
        'palette': PALETTE_PLUM_BLUSH,
        'badge': 'TAILORED SESSIONS',
        'has_bolt': False,
        'headline': 'Adaptive Practice Modes',
        'subtitle': 'Auto Difficulty & Weak-Area Target Drills',
    },
    {
        'output_name': '06_practice_topics_all.png',
        'raw_image': 'practice topics -2.jpeg',
        'palette': PALETTE_ACID_CHARCOAL,
        'badge': '23 PRACTICE TOPICS',
        'has_bolt': False,
        'headline': 'Comprehensive Math Drills',
        'subtitle': 'Multiplication, Squares, Cubes, Roots & More',
    },
    {
        'output_name': '07_applied_competitive_math.png',
        'raw_image': 'practice topics -1.jpeg',
        'palette': PALETTE_NAVY_BUTTER,
        'badge': 'ADVANCED & APPLIED',
        'has_bolt': False,
        'headline': 'Fractions & Percentages',
        'subtitle': 'Approximation, Simplification & Split Tricks',
    },
    {
        'output_name': '08_session_insights_mistakes.png',
        'raw_image': 'session complete coach insight - review mistakes.jpeg',
        'palette': PALETTE_TERRACOTTA_PEACH,
        'badge': 'REAL-TIME FEEDBACK',
        'has_bolt': False,
        'headline': 'Analyze Pace & Errors',
        'subtitle': 'Instant Coach Diagnosis & Detailed Question Review',
    },
    {
        'output_name': '09_ai_adaptive_coach.png',
        'raw_image': 'adaptive coach.jpeg',
        'palette': PALETTE_FOREST_GOLD,
        'badge': 'ON-DEVICE AI COACH',
        'has_bolt': False,
        'headline': 'Personal Math Coach',
        'subtitle': 'Ask Where You Are Weak & Get Targeted Advice',
    },
    {
        'output_name': '10_performance_report_score.png',
        'raw_image': 'performance report.jpeg',
        'palette': PALETTE_PLUM_BLUSH,
        'badge': 'PROGRESS TRACKING',
        'has_bolt': False,
        'headline': 'Elite Speed Score',
        'subtitle': 'Mastery Breakdown & Daily Personalized Plans',
    },
]

# -------------------------------------------------------------------------
# Painterly Brush & Device Mockup Renderers
# -------------------------------------------------------------------------
def draw_vector_bolt(draw, cx, cy, size, color):
    """Draws a crisp geometric lightning bolt with no font dependencies."""
    w = size * 0.55
    h = size
    points = [
        (cx + w * 0.15, cy - h * 0.5),
        (cx - w * 0.5, cy + h * 0.05),
        (cx - w * 0.05, cy + h * 0.05),
        (cx - w * 0.2, cy + h * 0.5),
        (cx + w * 0.5, cy - h * 0.05),
        (cx + w * 0.05, cy - h * 0.05),
    ]
    draw.polygon(points, fill=color)

def create_brush_badge(badge_text, font, brush_color, text_color, has_bolt=False):
    """Creates an organic, painterly brush badge with handwritten text and optional vector bolt."""
    dummy_draw = ImageDraw.Draw(Image.new('RGBA', (1, 1)))
    bbox = dummy_draw.textbbox((0, 0), badge_text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]

    bolt_size = 22 if has_bolt else 0
    bolt_gap = 10 if has_bolt else 0
    total_content_w = bolt_size + bolt_gap + tw

    pad_x = 44
    pad_y = 16
    bw = total_content_w + pad_x * 2
    bh = th + pad_y * 2

    scale = 3
    sw, sh = bw * scale, bh * scale
    brush = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(brush)

    # Core stroke with organic curvature
    r = int(sh * 0.44)
    bdraw.rounded_rectangle([scale * 4, scale * 3, sw - scale * 4, sh - scale * 3], radius=r, fill=brush_color)

    # Subtle organic edge variations
    edge_w = int(22 * scale)
    bdraw.ellipse([scale * 2, int(sh * 0.15), scale * 2 + edge_w, int(sh * 0.85)], fill=brush_color)
    bdraw.ellipse([sw - scale * 2 - edge_w, int(sh * 0.15), sw - scale * 2, int(sh * 0.85)], fill=brush_color)

    # Smooth antialiasing
    final_brush = brush.resize((bw, bh), Image.Resampling.LANCZOS)
    fdraw = ImageDraw.Draw(final_brush)

    # Render vector lightning bolt if requested
    start_x = (bw - total_content_w) // 2
    if has_bolt:
        bolt_cx = start_x + bolt_size // 2
        bolt_cy = bh // 2
        draw_vector_bolt(fdraw, bolt_cx, bolt_cy, bolt_size, text_color)

    # Render text cleanly centered
    tx = start_x + bolt_size + bolt_gap
    ty = (bh - th) // 2 - bbox[1] - 2
    fdraw.text((tx, ty), badge_text, font=font, fill=text_color)

    return final_brush

def build_s25_ultra_mockup(raw_image_path):
    """Builds a pixel-perfect Samsung Galaxy S25 Ultra titanium device mockup."""
    phone = Image.new('RGBA', (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(phone)

    # Outer titanium chassis with subtle metallic highlight
    draw.rounded_rectangle(
        [0, 0, FRAME_WIDTH - 1, FRAME_HEIGHT - 1],
        radius=FRAME_RADIUS,
        fill=(26, 28, 32, 255),
        outline=(68, 72, 80, 255),
        width=2
    )
    # Inner display rim
    draw.rounded_rectangle(
        [2, 2, FRAME_WIDTH - 3, FRAME_HEIGHT - 3],
        radius=FRAME_RADIUS - 2,
        outline=(14, 16, 18, 255),
        width=2
    )

    # Load and scale full screenshot without cropping
    raw = Image.open(raw_image_path).convert('RGBA')
    scaled_ss = raw.resize((SCREEN_WIDTH, SCREEN_HEIGHT), Image.Resampling.LANCZOS)

    # Corner radius mask for screen
    screen_mask = Image.new('L', (SCREEN_WIDTH, SCREEN_HEIGHT), 0)
    smdraw = ImageDraw.Draw(screen_mask)
    smdraw.rounded_rectangle(
        [0, 0, SCREEN_WIDTH, SCREEN_HEIGHT],
        radius=SCREEN_RADIUS,
        fill=255
    )

    # Paste screenshot inside bezel
    phone.paste(scaled_ss, (BEZEL, BEZEL), screen_mask)

    # Front camera hole punch (S25 Ultra centered top camera)
    cam_x = FRAME_WIDTH // 2
    cam_y = BEZEL + 18
    cam_r = 10
    draw.ellipse(
        [cam_x - cam_r, cam_y - cam_r, cam_x + cam_r, cam_y + cam_r],
        fill=(8, 9, 11, 255),
        outline=(26, 30, 36, 255),
        width=1
    )
    # Subtle camera lens reflection
    draw.ellipse(
        [cam_x - 3, cam_y - 3, cam_x - 1, cam_y - 1],
        fill=(46, 54, 68, 255)
    )

    return phone

def render_slide(slide_info, raw_dir, output_dir, fonts):
    """Renders a single high-resolution Play Store screenshot slide."""
    palette = slide_info['palette']
    canvas = Image.new('RGB', (CANVAS_WIDTH, CANVAS_HEIGHT), palette['bg'])
    draw = ImageDraw.Draw(canvas)

    # 1. Category Badge with painterly brush (ZERO EMOJI GLYPHS - NO BOXES)
    brush_badge = create_brush_badge(
        slide_info['badge'],
        fonts['badge'],
        palette['brush'],
        palette['brush_text'],
        has_bolt=slide_info.get('has_bolt', False)
    )
    bx = (CANVAS_WIDTH - brush_badge.width) // 2
    by = 105
    canvas.paste(brush_badge, (bx, by), brush_badge)

    # 2. Main Headline (Bold, Impactful)
    headline_text = slide_info['headline']
    h_box = draw.textbbox((0, 0), headline_text, font=fonts['headline'])
    hw = h_box[2] - h_box[0]
    hx = (CANVAS_WIDTH - hw) // 2 - h_box[0]
    hy = 210
    draw.text((hx, hy), headline_text, font=fonts['headline'], fill=palette['headline'])

    # 3. Descriptive Subtitle (Kalam Handwritten Style)
    subtitle_text = slide_info['subtitle']
    s_box = draw.textbbox((0, 0), subtitle_text, font=fonts['subtitle'])
    sw = s_box[2] - s_box[0]
    sx = (CANVAS_WIDTH - sw) // 2 - s_box[0]
    sy = 338
    draw.text((sx, sy), subtitle_text, font=fonts['subtitle'], fill=palette['subtitle'])

    # 4. Realistic Drop Shadow behind Phone
    shadow_pad = 80
    shadow_img = Image.new('RGBA', (FRAME_WIDTH + shadow_pad * 2, FRAME_HEIGHT + shadow_pad * 2), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_img)
    sdraw.rounded_rectangle(
        [shadow_pad, shadow_pad + 20, shadow_pad + FRAME_WIDTH, shadow_pad + FRAME_HEIGHT + 20],
        radius=FRAME_RADIUS,
        fill=(0, 0, 0, 130)
    )
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(34))
    canvas.paste(shadow_img, (PHONE_X - shadow_pad, PHONE_Y - shadow_pad), shadow_img)

    # 5. Build and Paste Phone Mockup
    raw_img_path = os.path.join(raw_dir, slide_info['raw_image'])
    phone_mockup = build_s25_ultra_mockup(raw_img_path)
    canvas.paste(phone_mockup, (PHONE_X, PHONE_Y), phone_mockup)

    # 6. Save Output
    out_path = os.path.join(output_dir, slide_info['output_name'])
    canvas.save(out_path, 'PNG', optimize=True)
    print(f"✓ Generated: {slide_info['output_name']}")

# -------------------------------------------------------------------------
# Main Execution
# -------------------------------------------------------------------------
def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    raw_dir = os.path.join(base_dir, 'assets', 'Feature graphics', 'raw screen shots')
    out_dir = os.path.join(base_dir, 'assets', 'Feature graphics', 'edited screenshots')
    fonts_dir = os.path.join(base_dir, 'assets', 'fonts')

    os.makedirs(out_dir, exist_ok=True)

    # Load Fonts
    fonts = {
        'badge': ImageFont.truetype(os.path.join(fonts_dir, 'Kalam-Bold.ttf'), 34),
        'headline': ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 74),
        'subtitle': ImageFont.truetype(os.path.join(fonts_dir, 'Kalam-Bold.ttf'), 38),
    }

    print(f"Starting Play Store screenshot generation for {len(SLIDES)} slides (Zero-box fix applied)...")
    for idx, slide in enumerate(SLIDES, 1):
        print(f"[{idx}/{len(SLIDES)}] Processing {slide['raw_image']}...")
        render_slide(slide, raw_dir, out_dir, fonts)

    print("\nAll 10 Play Store screenshots successfully generated in:")
    print(out_dir)

if __name__ == '__main__':
    main()
