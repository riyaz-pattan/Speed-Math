#!/usr/bin/env python3
"""
Play Store Feature Graphic Generator (Pure Typographic & Graphic-Vector Edition)
Zero screenshots used — 100% vector shapes, licensed handwritten Kalam typography,
mathematical symbols, and vibrant color palettes for pristine Full HD clarity at 1024x500.

Features:
- Option 1 (Primary): Acid Charcoal Edition (Deep Charcoal, Acid Lime, Butter Gold)
- Option 2: Midnight Navy Edition (Royal Navy, Butter Gold, Cream)
- Pure vector math symbols: ×, ÷, √, %, ±, x²
- Licensed handwritten typography: Kalam-Bold & Kalam-Regular
- 4x Ultra HD Master rendering (4096x2000) with 16x SSAA downsampling + micro-contrast edge boost
"""

import os
import shutil
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SCALE = 4
CANVAS_W = 1024 * SCALE
CANVAS_H = 500 * SCALE

def hex_to_rgb(hex_str):
    h = hex_str.lstrip('#').replace(' ', '')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def make_shadow(img, blur, offset_y, opacity=140):
    """Creates a smooth Gaussian drop shadow from image alpha channel."""
    pad = int(blur * 2.5 + abs(offset_y))
    shadow = Image.new('RGBA', (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    alpha = img.split()[3]
    sdraw.bitmap((pad, pad + offset_y), alpha, fill=(0, 0, 0, opacity))
    return shadow.filter(ImageFilter.GaussianBlur(blur)), pad

def build_feature_graphic(palette, out_prefix, base_dir, fonts_dir, out_dir):
    """Renders a pure typographic and graphic-vector feature graphic at 4K master and downsamples."""
    canvas = Image.new('RGB', (CANVAS_W, CANVAS_H), palette['bg_base'])
    draw = ImageDraw.Draw(canvas)

    # Ambient Radial Glow
    glow = Image.new('RGBA', (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([480 * SCALE, -60 * SCALE, 1100 * SCALE, 560 * SCALE], fill=palette['glow_top'])
    gdraw.ellipse([680 * SCALE, 180 * SCALE, 1060 * SCALE, 520 * SCALE], fill=palette['glow_bottom'])
    glow = glow.filter(ImageFilter.GaussianBlur(90 * SCALE))
    canvas.paste(glow, (0, 0), glow)

    # Floating Ambient Math Symbols
    font_kalam_bg = ImageFont.truetype(os.path.join(fonts_dir, 'Kalam-Bold.ttf'), 52 * SCALE)
    bg_symbols = [
        ('×', 530, 40, 40),
        ('+', 940, 30, 35),
        ('√', 500, 420, 35),
        ('%', 950, 420, 40),
        ('÷', 730, 20, 30),
        ('²', 750, 435, 35)
    ]
    for sym, sx, sy, op in bg_symbols:
        s_im = Image.new('RGBA', (120 * SCALE, 120 * SCALE), (0, 0, 0, 0))
        s_draw = ImageDraw.Draw(s_im)
        s_draw.text((20 * SCALE, 15 * SCALE), sym, font=font_kalam_bg, fill=(*palette['accent_glow'], op))
        s_im = s_im.filter(ImageFilter.GaussianBlur(2 * SCALE))
        canvas.paste(s_im, (sx * SCALE, sy * SCALE), s_im)

    # -------------------------------------------------------------------------
    # Left Section: Brand & Core Identity
    # -------------------------------------------------------------------------
    left_x = 48 * SCALE

    # 1. App Icon with squircle corners and subtle glow
    icon_path = os.path.join(base_dir, 'assets', 'logo', 'icon_main.png')
    if not os.path.exists(icon_path):
        icon_path = os.path.join(base_dir, 'assets', 'logo', 'icon_main-512.png')

    if os.path.exists(icon_path):
        icon_img = Image.open(icon_path).convert('RGBA')
        icon_size = 78 * SCALE
        icon_img = icon_img.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        imask = Image.new('L', (icon_size, icon_size), 0)
        idraw = ImageDraw.Draw(imask)
        idraw.rounded_rectangle([0, 0, icon_size - 1, icon_size - 1], radius=18 * SCALE, fill=255)

        icon_shadow = Image.new('RGBA', (icon_size + 20 * SCALE, icon_size + 20 * SCALE), (0, 0, 0, 0))
        isdraw = ImageDraw.Draw(icon_shadow)
        isdraw.rounded_rectangle(
            [4 * SCALE, 6 * SCALE, icon_size + 4 * SCALE, icon_size + 6 * SCALE],
            radius=18 * SCALE,
            fill=(0, 0, 0, 150)
        )
        icon_shadow = icon_shadow.filter(ImageFilter.GaussianBlur(8 * SCALE))
        canvas.paste(icon_shadow, (left_x - 4 * SCALE, 38 * SCALE), icon_shadow)
        canvas.paste(icon_img, (left_x, 40 * SCALE), imask)

    # Brand Title & Category Label
    font_brand = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 30 * SCALE)
    font_category = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-SemiBold.ttf'), 11 * SCALE)
    text_x = left_x + 94 * SCALE
    draw.text((text_x, 44 * SCALE), 'Speed Math', font=font_brand, fill=palette['brand_title'])
    draw.text((text_x, 82 * SCALE), 'MENTAL CALCULATION WITH AI', font=font_category, fill=palette['brand_cat'])

    # Pill Badge (⚡ 26 RAPID SHORTCUTS)
    font_badge = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 14 * SCALE)
    badge_text = '⚡ 26 RAPID SHORTCUTS'
    bbox = draw.textbbox((0, 0), badge_text, font=font_badge)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    bw = tw + 34 * SCALE
    bh = th + 16 * SCALE
    badge_y = 144 * SCALE

    b_im = Image.new('RGBA', (bw, bh), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(b_im)
    b_draw.rounded_rectangle([0, 0, bw - 1, bh - 1], radius=bh // 2, fill=palette['pill_bg'])
    b_draw.text((17 * SCALE, (bh - th) // 2 - bbox[1] - 1 * SCALE), badge_text, font=font_badge, fill=palette['pill_text'])
    canvas.paste(b_im, (left_x, badge_y), b_im)

    # Main Headline
    font_title = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 42 * SCALE)
    draw.text((left_x, 202 * SCALE), 'Master Mental Math', font=font_title, fill=palette['headline'])

    # Subtitle in Kalam-Bold (Gold Butter / Warm Tint)
    font_sub = ImageFont.truetype(os.path.join(fonts_dir, 'Kalam-Bold.ttf'), 23 * SCALE)
    draw.text((left_x, 262 * SCALE), 'Calculate 5X Faster in Your Head', font=font_sub, fill=palette['subtitle'])

    # Feature Chips
    font_chip = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-SemiBold.ttf'), 13 * SCALE)
    chips = [
        '✓ Visual Whiteboard Steps',
        '✓ 100% Offline Practice'
    ]
    cx = left_x
    cy = 340 * SCALE
    chip_h = 36 * SCALE
    for chip in chips:
        c_box = draw.textbbox((0, 0), chip, font=font_chip)
        cw = c_box[2] - c_box[0] + 26 * SCALE
        draw.rounded_rectangle(
            [cx, cy, cx + cw, cy + chip_h],
            radius=10 * SCALE,
            fill=palette['chip_bg'],
            outline=palette['chip_border'],
            width=1 * SCALE
        )
        tx = cx + 13 * SCALE - c_box[0]
        ty = cy + (chip_h - (c_box[3] - c_box[1])) // 2 - c_box[1] - 1 * SCALE
        draw.text((tx, ty), chip, font=font_chip, fill=palette['chip_text'])
        cx += cw + 12 * SCALE

    chip3 = '✓ Daily Habit Streaks & XP Goals'
    c_box3 = draw.textbbox((0, 0), chip3, font=font_chip)
    cw3 = c_box3[2] - c_box3[0] + 26 * SCALE
    cy3 = 390 * SCALE
    draw.rounded_rectangle(
        [left_x, cy3, left_x + cw3, cy3 + chip_h],
        radius=10 * SCALE,
        fill=palette['chip_bg'],
        outline=palette['chip_border'],
        width=1 * SCALE
    )
    tx3 = left_x + 13 * SCALE - c_box3[0]
    ty3 = cy3 + (chip_h - (c_box3[3] - c_box3[1])) // 2 - c_box3[1] - 1 * SCALE
    draw.text((tx3, ty3), chip3, font=font_chip, fill=palette['chip_text'])

    # -------------------------------------------------------------------------
    # Right Section: 4 Interactive Topic Cards in 2x2 Grid (Pure Typographic & Math Symbols)
    # -------------------------------------------------------------------------
    card_w = 222 * SCALE
    card_h = 194 * SCALE
    gap_x = 16 * SCALE
    gap_y = 16 * SCALE
    start_x = 512 * SCALE
    start_y = 44 * SCALE

    font_tag = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-SemiBold.ttf'), 10 * SCALE)
    font_card_title = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 15 * SCALE)
    font_card_calc = ImageFont.truetype(os.path.join(fonts_dir, 'Kalam-Bold.ttf'), 22 * SCALE)
    font_card_sub = ImageFont.truetype(os.path.join(fonts_dir, 'Kalam-Regular.ttf'), 13 * SCALE)
    font_card_sym = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 26 * SCALE)

    for t in palette['topics']:
        px = start_x + t['col'] * (card_w + gap_x)
        py = start_y + t['row'] * (card_h + gap_y)

        c_im = Image.new('RGBA', (card_w, card_h), (0, 0, 0, 0))
        cdraw = ImageDraw.Draw(c_im)

        # Card body with frosted background and crisp boundary
        cdraw.rounded_rectangle(
            [0, 0, card_w - 1, card_h - 1],
            radius=15 * SCALE,
            fill=palette['card_bg'],
            outline=palette['card_border'],
            width=max(2, int(1.5 * SCALE))
        )

        # Category Tag Pill
        t_box = cdraw.textbbox((0, 0), t['tag'], font=font_tag)
        tw = t_box[2] - t_box[0] + 18 * SCALE
        th = t_box[3] - t_box[1] + 10 * SCALE
        cdraw.rounded_rectangle([14 * SCALE, 14 * SCALE, 14 * SCALE + tw, 14 * SCALE + th], radius=th // 2, fill=palette['tag_bg'])
        cdraw.text((14 * SCALE + 9 * SCALE - t_box[0], 14 * SCALE + 5 * SCALE - t_box[1] - 1 * SCALE), t['tag'], font=font_tag, fill=t['tag_color'])

        # Top-Right Math Symbol
        cdraw.text((card_w - 36 * SCALE, 12 * SCALE), t['sym'], font=font_card_sym, fill=t['tag_color'])

        # Card Topic Title
        cdraw.text((14 * SCALE, 50 * SCALE), t['title'], font=font_card_title, fill=palette['card_title'])

        # Handwritten Mental Math Calculation (Kalam-Bold)
        cdraw.text((14 * SCALE, 86 * SCALE), t['calc'], font=font_card_calc, fill=palette['card_calc'])

        # Handwritten Step Breakdown (Kalam-Regular)
        cdraw.text((14 * SCALE, 134 * SCALE), '⚡ ' + t['sub'], font=font_card_sub, fill=palette['card_sub'])
        cdraw.text((14 * SCALE, 158 * SCALE), '✓ Step-by-step trick', font=font_card_sub, fill=palette['card_foot'])

        # Soft drop shadow
        c_shadow, s_pad = make_shadow(c_im, blur=14 * SCALE, offset_y=8 * SCALE, opacity=120)
        canvas.paste(c_shadow, (px - s_pad, py - s_pad), c_shadow)
        canvas.paste(c_im, (px, py), c_im)

    # -------------------------------------------------------------------------
    # Save Multi-Tier High-Definition Outputs
    # -------------------------------------------------------------------------
    # 1. 4K Ultra HD Master
    uhd_path = os.path.join(out_dir, f'{out_prefix}_4096x2000.png')
    canvas.save(uhd_path, 'PNG', optimize=True)

    # 2. 2K Full HD Graphic
    fhd = canvas.resize((2048, 1000), Image.Resampling.LANCZOS)
    fhd_path = os.path.join(out_dir, f'{out_prefix}_2048x1000.png')
    fhd.save(fhd_path, 'PNG', optimize=True)

    # 3. 1024x500 Play Store Graphic (Lanczos 16x SSAA + Micro-Contrast Unsharp Mask)
    p1024 = canvas.resize((1024, 500), Image.Resampling.LANCZOS)
    p1024_sharp = p1024.filter(ImageFilter.UnsharpMask(radius=1.0, percent=85, threshold=1))
    p1024_path = os.path.join(out_dir, f'{out_prefix}_1024x500.png')
    p1024_sharp.save(p1024_path, 'PNG', optimize=True)

    print(f"✓ Generated {out_prefix}: 1024x500 ({os.path.getsize(p1024_path)/1024:.1f} KB), 2K ({os.path.getsize(fhd_path)/1024:.1f} KB), 4K ({os.path.getsize(uhd_path)/1024:.1f} KB)")
    return canvas

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    fonts_dir = os.path.join(base_dir, 'assets', 'fonts')
    out_dir = os.path.join(base_dir, 'assets', 'Feature graphics')

    # Common Topics Definition
    topics_charcoal = [
        {
            'tag': 'MULTIPLICATION',
            'tag_color': hex_to_rgb('DFFF00'),
            'sym': '×',
            'title': 'Criss-Cross 2-Digit',
            'calc': '43 × 21 = 903',
            'sub': '3 simple mental steps',
            'col': 0, 'row': 0
        },
        {
            'tag': 'SQUARES',
            'tag_color': hex_to_rgb('F1B79B'),
            'sym': 'x²',
            'title': 'Numbers Ending in 5',
            'calc': '35² = 1,225',
            'sub': 'Multiply n × (n+1) | 25',
            'col': 1, 'row': 0
        },
        {
            'tag': 'NEAR 100 BASE',
            'tag_color': hex_to_rgb('C1A16A'),
            'sym': '±',
            'title': 'Base Complements',
            'calc': '96 × 97 = 9,312',
            'sub': '(-4) × (-3) = 12',
            'col': 0, 'row': 1
        },
        {
            'tag': 'ROOTS & %',
            'tag_color': hex_to_rgb('E7C9D2'),
            'sym': '√',
            'title': 'Roots & Split %',
            'calc': '√4,096 = 64',
            'sub': '15% of 240 = 36',
            'col': 1, 'row': 1
        }
    ]

    topics_navy = [
        {
            'tag': 'MULTIPLICATION',
            'tag_color': hex_to_rgb('F3DEA0'),
            'sym': '×',
            'title': 'Criss-Cross 2-Digit',
            'calc': '43 × 21 = 903',
            'sub': '3 simple mental steps',
            'col': 0, 'row': 0
        },
        {
            'tag': 'SQUARES',
            'tag_color': hex_to_rgb('F1B79B'),
            'sym': 'x²',
            'title': 'Numbers Ending in 5',
            'calc': '35² = 1,225',
            'sub': 'Multiply n × (n+1) | 25',
            'col': 1, 'row': 0
        },
        {
            'tag': 'NEAR 100 BASE',
            'tag_color': hex_to_rgb('DFFF00'),
            'sym': '±',
            'title': 'Base Complements',
            'calc': '96 × 97 = 9,312',
            'sub': '(-4) × (-3) = 12',
            'col': 0, 'row': 1
        },
        {
            'tag': 'ROOTS & %',
            'tag_color': hex_to_rgb('E7C9D2'),
            'sym': '√',
            'title': 'Roots & Split %',
            'calc': '√4,096 = 64',
            'sub': '15% of 240 = 36',
            'col': 1, 'row': 1
        }
    ]

    # Palette 1: Acid Charcoal Edition
    palette_charcoal = {
        'bg_base': hex_to_rgb('16181D'),
        'glow_top': (32, 44, 64, 150),
        'glow_bottom': (42, 56, 26, 120),
        'accent_glow': hex_to_rgb('DFFF00'),
        'brand_title': (248, 248, 244),
        'brand_cat': (158, 164, 176),
        'pill_bg': hex_to_rgb('DFFF00'),
        'pill_text': hex_to_rgb('1C1E22'),
        'headline': (255, 255, 255),
        'subtitle': hex_to_rgb('F3DEA0'),
        'chip_bg': (30, 34, 42),
        'chip_border': (68, 76, 92),
        'chip_text': (240, 244, 248),
        'card_bg': (26, 30, 38, 235),
        'card_border': (70, 80, 98, 255),
        'tag_bg': (38, 46, 58, 255),
        'card_title': (244, 246, 250),
        'card_calc': hex_to_rgb('F3DEA0'),
        'card_sub': (175, 184, 198),
        'card_foot': (130, 140, 155),
        'topics': topics_charcoal
    }

    # Palette 2: Midnight Navy Edition
    palette_navy = {
        'bg_base': hex_to_rgb('141B3D'),
        'glow_top': (38, 61, 141, 170),
        'glow_bottom': (55, 78, 160, 130),
        'accent_glow': hex_to_rgb('F3DEA0'),
        'brand_title': (250, 247, 238),
        'brand_cat': (169, 196, 232),
        'pill_bg': hex_to_rgb('F3DEA0'),
        'pill_text': hex_to_rgb('1C2B5E'),
        'headline': (255, 255, 255),
        'subtitle': hex_to_rgb('F3DEA0'),
        'chip_bg': (26, 38, 78),
        'chip_border': (58, 80, 140),
        'chip_text': (244, 248, 255),
        'card_bg': (22, 34, 72, 235),
        'card_border': (58, 82, 142, 255),
        'tag_bg': (32, 48, 96, 255),
        'card_title': (248, 250, 255),
        'card_calc': hex_to_rgb('FAF7EE'),
        'card_sub': (185, 205, 235),
        'card_foot': (145, 170, 210),
        'topics': topics_navy
    }

    print("Generating Option 1: Acid Charcoal Typographic Edition...")
    charcoal_canvas = build_feature_graphic(palette_charcoal, 'feature_graphic_typographic_charcoal', base_dir, fonts_dir, out_dir)

    print("Generating Option 2: Midnight Navy Typographic Edition...")
    build_feature_graphic(palette_navy, 'feature_graphic_typographic_navy', base_dir, fonts_dir, out_dir)

    # Save Option 1 as primary feature_graphic_1024x500.png for official Play Store upload
    p1024 = charcoal_canvas.resize((1024, 500), Image.Resampling.LANCZOS)
    p1024_sharp = p1024.filter(ImageFilter.UnsharpMask(radius=1.0, percent=85, threshold=1))
    play_primary_path = os.path.join(out_dir, 'feature_graphic_1024x500.png')
    p1024_sharp.save(play_primary_path, 'PNG', optimize=True)
    print(f"✓ Primary Google Play Store graphic updated: {play_primary_path} (1024x500, {os.path.getsize(play_primary_path)/1024:.1f} KB)")

if __name__ == '__main__':
    main()
