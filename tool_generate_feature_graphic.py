#!/usr/bin/env python3
"""
Play Store Feature Graphic Generator (High-Definition 1024x500 Redesign)
Specifically engineered for crystal-clear legibility and sharpness at 1024x500 px.

Key Architectural Improvements for 1024x500 Clarity:
1. Replaced 3 shrunken miniature phones with 2 large, prominent hero devices (taking up 94% of vertical height),
   making math formulas, whiteboard steps, and UI cards 2.5x larger and instantly legible.
2. Bold, high-contrast typography hierarchy (44px Poppins-Bold headline, 23px Kalam-Bold subtitle, 30px App title).
3. 4x Ultra HD Master rendering (4096x2000) with 16x SSAA downsampling + targeted micro-contrast edge unsharp mask.
4. Generates both Option 1 (Dual Prominent Phones) and Option 2 (Single Bold Hero Phone) in 1024x500, 2K, and 4K.
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

def build_s25_device(raw_path, target_h, bezel, corner_r):
    """Builds a crisp, high-resolution Samsung S25 Ultra titanium device mockup."""
    raw = Image.open(raw_path).convert('RGBA')
    target_w = int(target_h * (1080.0 / 2340.0))
    sw = target_w - bezel * 2
    sh = target_h - bezel * 2

    ss_resized = raw.resize((sw, sh), Image.Resampling.LANCZOS)
    phone = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(phone)

    # Titanium chassis with crisp highlight border
    pdraw.rounded_rectangle(
        [0, 0, target_w - 1, target_h - 1],
        radius=corner_r,
        fill=(22, 24, 28, 255),
        outline=(82, 88, 98, 255),
        width=max(2, int(bezel * 0.4))
    )
    # Inner display rim
    pdraw.rounded_rectangle(
        [bezel // 2, bezel // 2, target_w - 1 - bezel // 2, target_h - 1 - bezel // 2],
        radius=max(2, corner_r - 2),
        outline=(14, 16, 18, 255),
        width=max(1, bezel // 3)
    )

    mask = Image.new('L', (sw, sh), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=max(2, corner_r - bezel // 2), fill=255)
    phone.paste(ss_resized, (bezel, bezel), mask)

    # Front camera hole punch
    cx = target_w // 2
    cy = bezel + int(bezel * 0.8)
    cr = max(3, int(bezel * 0.45))
    pdraw.ellipse(
        [cx - cr, cy - cr, cx + cr, cy + cr],
        fill=(8, 9, 11, 255),
        outline=(30, 34, 40, 255),
        width=max(1, cr // 3)
    )
    return phone

def make_shadow(img, blur, offset_y, opacity=140):
    """Creates a smooth Gaussian drop shadow from image alpha channel."""
    pad = int(blur * 2.5 + abs(offset_y))
    shadow = Image.new('RGBA', (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    alpha = img.split()[3]
    sdraw.bitmap((pad, pad + offset_y), alpha, fill=(0, 0, 0, opacity))
    return shadow.filter(ImageFilter.GaussianBlur(blur)), pad

def draw_branding_left(canvas, base_dir, fonts_dir, title_text, subtitle_text):
    """Renders bold, high-contrast branding and copy on the left side."""
    draw = ImageDraw.Draw(canvas)
    left_x = 52 * SCALE

    # 1. High-Res App Icon (from full 1024px master)
    icon_path = os.path.join(base_dir, 'assets', 'logo', 'icon_main.png')
    if not os.path.exists(icon_path):
        icon_path = os.path.join(base_dir, 'assets', 'logo', 'icon_main-512.png')

    if os.path.exists(icon_path):
        icon_img = Image.open(icon_path).convert('RGBA')
        icon_size = 80 * SCALE
        icon_img = icon_img.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        imask = Image.new('L', (icon_size, icon_size), 0)
        idraw = ImageDraw.Draw(imask)
        idraw.rounded_rectangle([0, 0, icon_size - 1, icon_size - 1], radius=18 * SCALE, fill=255)

        icon_shadow = Image.new('RGBA', (icon_size + 20 * SCALE, icon_size + 20 * SCALE), (0, 0, 0, 0))
        isdraw = ImageDraw.Draw(icon_shadow)
        isdraw.rounded_rectangle([4 * SCALE, 6 * SCALE, icon_size + 4 * SCALE, icon_size + 6 * SCALE], radius=18 * SCALE, fill=(0, 0, 0, 150))
        icon_shadow = icon_shadow.filter(ImageFilter.GaussianBlur(8 * SCALE))
        canvas.paste(icon_shadow, (left_x - 4 * SCALE, 38 * SCALE), icon_shadow)
        canvas.paste(icon_img, (left_x, 40 * SCALE), imask)

    # Brand Title & Category Label
    font_brand = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 30 * SCALE)
    font_category = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-SemiBold.ttf'), 12 * SCALE)
    text_x = left_x + 96 * SCALE
    draw.text((text_x, 44 * SCALE), 'Speed Math', font=font_brand, fill=(246, 246, 240))
    draw.text((text_x, 82 * SCALE), 'MENTAL CALCULATION WITH AI', font=font_category, fill=(160, 166, 178))

    # Vibrant Acid Lime Pill Badge
    font_badge = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 15 * SCALE)
    badge_text = '⚡ 26 RAPID SHORTCUTS'
    bbox = draw.textbbox((0, 0), badge_text, font=font_badge)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    bw = tw + 36 * SCALE
    bh = th + 18 * SCALE
    badge_y = 148 * SCALE

    b_im = Image.new('RGBA', (bw, bh), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(b_im)
    b_draw.rounded_rectangle([0, 0, bw - 1, bh - 1], radius=bh // 2, fill=hex_to_rgb('DFFF00'))
    b_draw.text((18 * SCALE, (bh - th) // 2 - bbox[1] - 1 * SCALE), badge_text, font=font_badge, fill=hex_to_rgb('1C1E22'))
    canvas.paste(b_im, (left_x, badge_y), b_im)

    # Main Headline (Large & Impactful)
    font_title = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 44 * SCALE)
    draw.text((left_x, 206 * SCALE), title_text, font=font_title, fill=(255, 255, 255))

    # Subtitle in Kalam-Bold (Warm Butter Gold)
    font_sub = ImageFont.truetype(os.path.join(fonts_dir, 'Kalam-Bold.ttf'), 23 * SCALE)
    draw.text((left_x, 268 * SCALE), subtitle_text, font=font_sub, fill=hex_to_rgb('F3DEA0'))

    # Two Main Feature Chips (Row 1)
    font_chip = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-SemiBold.ttf'), 14 * SCALE)
    chips = [
        '✓ Visual Whiteboard Tricks',
        '✓ 100% Offline Practice'
    ]
    cx = left_x
    cy = 348 * SCALE
    chip_h = 38 * SCALE
    for chip in chips:
        c_box = draw.textbbox((0, 0), chip, font=font_chip)
        cw = c_box[2] - c_box[0] + 28 * SCALE
        draw.rounded_rectangle(
            [cx, cy, cx + cw, cy + chip_h],
            radius=10 * SCALE,
            fill=(32, 36, 44),
            outline=(74, 82, 98),
            width=1 * SCALE
        )
        tx = cx + 14 * SCALE - c_box[0]
        ty = cy + (chip_h - (c_box[3] - c_box[1])) // 2 - c_box[1] - 1 * SCALE
        draw.text((tx, ty), chip, font=font_chip, fill=(244, 246, 250))
        cx += cw + 14 * SCALE

    # Secondary Feature Chip (Row 2)
    chip3 = '✓ Daily Habit Streaks & XP'
    c_box3 = draw.textbbox((0, 0), chip3, font=font_chip)
    cw3 = c_box3[2] - c_box3[0] + 28 * SCALE
    cy3 = 398 * SCALE
    draw.rounded_rectangle(
        [left_x, cy3, left_x + cw3, cy3 + chip_h],
        radius=10 * SCALE,
        fill=(32, 36, 44),
        outline=(74, 82, 98),
        width=1 * SCALE
    )
    tx3 = left_x + 14 * SCALE - c_box3[0]
    ty3 = cy3 + (chip_h - (c_box3[3] - c_box3[1])) // 2 - c_box3[1] - 1 * SCALE
    draw.text((tx3, ty3), chip3, font=font_chip, fill=(244, 246, 250))

def generate_option1_dual_hero(base_dir, fonts_dir, raw_dir, out_dir):
    """Option 1: Dual Prominent Samsung S25 Ultra Phones + 3D Math Ambient Depth."""
    canvas = Image.new('RGB', (CANVAS_W, CANVAS_H), hex_to_rgb('1C1E22'))
    draw = ImageDraw.Draw(canvas)

    # Ambient Glow
    glow = Image.new('RGBA', (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([600 * SCALE, -50 * SCALE, 1100 * SCALE, 550 * SCALE], fill=(36, 52, 78, 160))
    gdraw.ellipse([750 * SCALE, 250 * SCALE, 1050 * SCALE, 520 * SCALE], fill=(50, 65, 30, 100))
    glow = glow.filter(ImageFilter.GaussianBlur(90 * SCALE))
    canvas.paste(glow, (0, 0), glow)

    # Ambient 3D Math Symbols
    font_symbol = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 54 * SCALE)
    for sym, sx, sy, op in [('×', 560, 80, 50), ('+', 940, 60, 45), ('%', 540, 390, 40), ('=', 960, 410, 45)]:
        s_im = Image.new('RGBA', (120 * SCALE, 120 * SCALE), (0, 0, 0, 0))
        s_draw = ImageDraw.Draw(s_im)
        s_draw.text((20 * SCALE, 10 * SCALE), sym, font=font_symbol, fill=(223, 255, 0, op))
        s_im = s_im.filter(ImageFilter.GaussianBlur(2 * SCALE))
        canvas.paste(s_im, (sx * SCALE, sy * SCALE), s_im)

    # Back Phone: Home Screen Dashboard (Height = 445 * SCALE)
    p_back_raw = os.path.join(raw_dir, 'home screen.jpeg')
    p_back = build_s25_device(p_back_raw, target_h=445 * SCALE, bezel=6 * SCALE, corner_r=14 * SCALE)
    p_back_rot = p_back.rotate(6.5, expand=True, resample=Image.Resampling.BICUBIC)
    s_back, pad_b = make_shadow(p_back_rot, blur=18 * SCALE, offset_y=12 * SCALE, opacity=120)
    bx, by = 770 * SCALE, 28 * SCALE
    canvas.paste(s_back, (bx - pad_b, by - pad_b), s_back)
    canvas.paste(p_back_rot, (bx, by), p_back_rot)

    # Front Hero Phone: Criss-Cross Whiteboard (Height = 468 * SCALE)
    p_front_raw = os.path.join(raw_dir, 'shortcut board-1.jpeg')
    p_front = build_s25_device(p_front_raw, target_h=468 * SCALE, bezel=6 * SCALE, corner_r=14 * SCALE)
    p_front_rot = p_front.rotate(-3.0, expand=True, resample=Image.Resampling.BICUBIC)
    s_front, pad_f = make_shadow(p_front_rot, blur=26 * SCALE, offset_y=16 * SCALE, opacity=170)
    fx, fy = 605 * SCALE, 16 * SCALE
    canvas.paste(s_front, (fx - pad_f, fy - pad_f), s_front)
    canvas.paste(p_front_rot, (fx, fy), p_front_rot)

    # Left Copy & Branding
    draw_branding_left(canvas, base_dir, fonts_dir, 'Master Mental Math', 'Calculate 5X Faster in Your Head')

    # Save Multi-Resolution Outputs
    save_multi_res(canvas, out_dir, 'feature_graphic_option1_dual_hero')
    return canvas

def generate_option2_single_hero(base_dir, fonts_dir, raw_dir, out_dir):
    """Option 2: Single Ultra-Prominent Hero Phone + Floating 3D Feature Cards."""
    canvas = Image.new('RGB', (CANVAS_W, CANVAS_H), hex_to_rgb('181A1E'))
    draw = ImageDraw.Draw(canvas)

    # Ambient Glow
    glow = Image.new('RGBA', (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([580 * SCALE, -40 * SCALE, 1080 * SCALE, 540 * SCALE], fill=(32, 48, 70, 170))
    gdraw.ellipse([720 * SCALE, 200 * SCALE, 1020 * SCALE, 510 * SCALE], fill=(45, 60, 30, 110))
    glow = glow.filter(ImageFilter.GaussianBlur(95 * SCALE))
    canvas.paste(glow, (0, 0), glow)

    # Massive Hero Phone (Height: 476 * SCALE - 95% of vertical height)
    p_raw = os.path.join(raw_dir, 'shortcut board-1.jpeg')
    p_hero = build_s25_device(p_raw, target_h=476 * SCALE, bezel=6 * SCALE, corner_r=14 * SCALE)
    p_rot = p_hero.rotate(-1.5, expand=True, resample=Image.Resampling.BICUBIC)
    s_hero, pad = make_shadow(p_rot, blur=28 * SCALE, offset_y=16 * SCALE, opacity=175)
    px, py = 705 * SCALE, 12 * SCALE
    canvas.paste(s_hero, (px - pad, py - pad), s_hero)
    canvas.paste(p_rot, (px, py), p_rot)

    # Floating Glass Card 1 (Top Left): '⚡ 3-Step Visual Trick'
    f_im1 = Image.new('RGBA', (190 * SCALE, 52 * SCALE), (0, 0, 0, 0))
    f_draw1 = ImageDraw.Draw(f_im1)
    f_draw1.rounded_rectangle([0, 0, 190 * SCALE - 1, 52 * SCALE - 1], radius=14 * SCALE, fill=(30, 36, 46, 235), outline=(100, 112, 132, 255), width=2 * SCALE)
    font_float = ImageFont.truetype(os.path.join(fonts_dir, 'Poppins-Bold.ttf'), 15 * SCALE)
    f_draw1.text((16 * SCALE, 14 * SCALE), '⚡ 3-Step Visual Trick', font=font_float, fill=hex_to_rgb('DFFF00'))
    f_s1, f_pad1 = make_shadow(f_im1, blur=14 * SCALE, offset_y=8 * SCALE, opacity=130)
    fx1, fy1 = 565 * SCALE, 60 * SCALE
    canvas.paste(f_s1, (fx1 - f_pad1, fy1 - f_pad1), f_s1)
    canvas.paste(f_im1, (fx1, fy1), f_im1)

    # Floating Glass Card 2 (Bottom Left): '🎯 Instant Breakdown'
    f_im2 = Image.new('RGBA', (190 * SCALE, 52 * SCALE), (0, 0, 0, 0))
    f_draw2 = ImageDraw.Draw(f_im2)
    f_draw2.rounded_rectangle([0, 0, 190 * SCALE - 1, 52 * SCALE - 1], radius=14 * SCALE, fill=(30, 36, 46, 235), outline=(100, 112, 132, 255), width=2 * SCALE)
    f_draw2.text((16 * SCALE, 14 * SCALE), '🎯 Instant Breakdown', font=font_float, fill=(246, 246, 240))
    f_s2, f_pad2 = make_shadow(f_im2, blur=14 * SCALE, offset_y=8 * SCALE, opacity=130)
    fx2, fy2 = 565 * SCALE, 380 * SCALE
    canvas.paste(f_s2, (fx2 - f_pad2, fy2 - f_pad2), f_s2)
    canvas.paste(f_im2, (fx2, fy2), f_im2)

    # Left Copy & Branding
    draw_branding_left(canvas, base_dir, fonts_dir, 'Calculate 5X Faster', '26 Rapid Shortcuts • AI Adaptive Coach')

    # Save Multi-Resolution Outputs
    save_multi_res(canvas, out_dir, 'feature_graphic_option2_single_hero')
    return canvas

def save_multi_res(canvas_4k, out_dir, prefix):
    """Saves 4K Ultra HD, 2K Full HD, and 1024x500 Google Play Store with micro-contrast edge boost."""
    # 1. 4K Ultra HD Master
    uhd_path = os.path.join(out_dir, f'{prefix}_4096x2000.png')
    canvas_4k.save(uhd_path, 'PNG', optimize=True)

    # 2. 2K Full HD Graphic
    fhd = canvas_4k.resize((2048, 1000), Image.Resampling.LANCZOS)
    fhd_path = os.path.join(out_dir, f'{prefix}_2048x1000.png')
    fhd.save(fhd_path, 'PNG', optimize=True)

    # 3. 1024x500 Play Store Graphic with High-Contrast Micro-Sharpening
    p1024 = canvas_4k.resize((1024, 500), Image.Resampling.LANCZOS)
    p1024_sharp = p1024.filter(ImageFilter.UnsharpMask(radius=1.0, percent=85, threshold=1))
    p1024_path = os.path.join(out_dir, f'{prefix}_1024x500.png')
    p1024_sharp.save(p1024_path, 'PNG', optimize=True)

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    fonts_dir = os.path.join(base_dir, 'assets', 'fonts')
    raw_dir = os.path.join(base_dir, 'assets', 'Feature graphics', 'raw screen shots')
    out_dir = os.path.join(base_dir, 'assets', 'Feature graphics')

    # Backup original graphic if not already backed up
    orig_path = os.path.join(out_dir, 'feature_graphic_1024x500.png')
    backup_path = os.path.join(out_dir, 'feature_graphic_1024x500_original.png')
    if os.path.exists(orig_path) and not os.path.exists(backup_path):
        shutil.copyfile(orig_path, backup_path)
        print(f"✓ Preserved original graphic at: {backup_path}")

    print("Generating Option 1 (Dual Prominent Phones Showcase)...")
    opt1_canvas = generate_option1_dual_hero(base_dir, fonts_dir, raw_dir, out_dir)

    print("Generating Option 2 (Single Bold Hero Phone + Floating 3D Cards)...")
    generate_option2_single_hero(base_dir, fonts_dir, raw_dir, out_dir)

    # Set Option 1 as the primary feature_graphic_1024x500.png for Google Play Store upload
    opt1_1024 = opt1_canvas.resize((1024, 500), Image.Resampling.LANCZOS)
    opt1_1024_sharp = opt1_1024.filter(ImageFilter.UnsharpMask(radius=1.0, percent=85, threshold=1))
    play_primary_path = os.path.join(out_dir, 'feature_graphic_1024x500.png')
    opt1_1024_sharp.save(play_primary_path, 'PNG', optimize=True)
    print(f"✓ Primary Google Play Store graphic updated: {play_primary_path} (1024x500, {os.path.getsize(play_primary_path) / 1024:.1f} KB)")

if __name__ == '__main__':
    main()
