# DESIGN SYSTEM: SPEED MATH (EXPRESSIVE TACTILE)

## 1. Design Philosophy
- **Style**: Modern Expressive Tactile (Material 3 Expressive + Clean Micro-Tactility).
- **Tone**: Bright, calm, highly motivating, focused, and non-childish. Designed for ambitious students preparing for competitive quantitative speed tests.
- **Theme**: Light Mode Only. Crisp white and slate surfaces with vibrant accent grounding.
- **Performance**: Zero blur filters, zero heavy draw loops, zero layout thrashing. Guaranteed smooth 60fps on low-end devices.

## 2. Color Palette & Contrast (WCAG AA / AAA)
- **Primary**: `#4F46E5` (Indigo 600) — authoritative, scholarly, focused.
- **Primary Light / Accent**: `#6366F1` (Indigo 500).
- **Primary Container / Tint**: `#EEF2FF` (Indigo 50).
- **Secondary**: `#0EA5E9` (Sky 500) — energetic calm for secondary highlights.
- **Success / Mastery**: `#10B981` (Emerald 500) — growth and streak progress.
- **Warning / Milestone**: `#F59E0B` (Amber 500) — achievements and stars.
- **Error / Mistake**: `#EF4444` (Rose 500) — mistake tracking (never flashing).
- **Background**: `#F8FAFC` (Slate 50) — clean, soothing, glare-free canvas.
- **Card Surface**: `#FFFFFF` (Pure white).
- **Card Secondary Surface**: `#F1F5F9` (Slate 100).
- **Border / Outline**: `#E2E8F0` (Slate 200, 1.2dp border width).
- **Border Subtle**: `#CBD5E1` (Slate 300).
- **Text Primary**: `#0F172A` (Slate 900 — 14.8:1 contrast on white).
- **Text Secondary**: `#475569` (Slate 600 — 5.8:1 contrast on white).
- **Text Tertiary / Muted**: `#94A3B8` (Slate 400).
- **Text on Primary / Dark**: `#FFFFFF`.

### Topic Signature Colors (Preserved with Refined Contrast)
- Addition: `#10B981` (Emerald)
- Subtraction: `#F97316` (Vibrant Orange)
- Multiplication: `#2563EB` (Vivid Blue)
- Division: `#DB2777` (Pink 600)
- Squares: `#7C3AED` (Purple 600)
- Cubes: `#0D9488` (Teal 600)
- Square Roots: `#D97706` (Amber 600)
- Cube Roots: `#0891B2` (Cyan 600)
- Exponents: `#DC2626` (Red 600)
- Percentages: `#4D7C0F` (Lime 700)
- Fractions: `#E11D48` (Rose 600)
- Simplification: `#4F46E5` (Indigo 600)
- Averages: `#C2410C` (Orange 700)
- Missing Number: `#475569` (Slate 600)
- Number Series: `#0284C7` (Sky 600)
- Approximation: `#B45309` (Amber 700)
- Mixed Practice: `#7C3AED` (Violet 600)

## 3. Typography Scale (Poppins Bundled Font)
- **Display Large**: 34pt, w900, height 1.15, letterSpacing -0.5 (Active math input, big scores).
- **Screen Hero Title**: 24pt, w800, height 1.25, letterSpacing -0.3.
- **Card Header Title**: 18pt, w700, height 1.3, letterSpacing -0.2.
- **Section Subheading**: 15pt, w700, height 1.35, letterSpacing 0.1.
- **Body Large**: 15pt, w500, height 1.45.
- **Body Medium**: 13pt, w400, height 1.5.
- **Caption / Tag**: 11pt, w600, height 1.4, letterSpacing 0.3.
- **Button / Pill**: 14pt–16pt, w700, height 1.2, letterSpacing 0.2.

## 4. Spacing, Radius & Elevation Tokens
- **Spacing**: 4dp (2xs), 8dp (xs), 12dp (sm), 16dp (md), 20dp (lg), 24dp (xl), 32dp (2xl).
- **Corner Radii**:
  - `xs`: 8dp (small tags, indicators)
  - `sm`: 12dp (chips, segmented buttons)
  - `md`: 16dp (standard buttons, list items)
  - `lg`: 20dp (standard cards, dialogs)
  - `xl`: 24dp (question cards, hero banners)
  - `pill`: 999dp (stadium buttons, bottom nav indicators)
- **Elevations (Ambient Light Soft Shadows)**:
  - Card Shadow: `BoxShadow(color: Color(0x080F172A), blurRadius: 16, offset: Offset(0, 4))`
  - Floating Sticky Bar: `BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, -3))`
  - Primary CTA Glow: `BoxShadow(color: Color(0x284F46E5), blurRadius: 12, offset: Offset(0, 4))`

## 5. Component Design Rules
- **Header Banners**: Consistent illustrated headers drawn with lightweight Flutter primitives (soft gradient mesh, decorative geometry circles/arcs at 6–10% opacity, title, subtitle, and circular 40x40 action icons).
- **Cards**: Pure white surface, subtle 1.2dp border (`#E2E8F0`), 20dp corner radius, ambient drop shadow.
- **Buttons**:
  - Primary: Filled pill (`StadiumBorder` or 16dp radius), vibrant Indigo or topic gradient, height 50–54dp, bold white text, tactile press response.
  - Secondary: Soft slate tint (`#F1F5F9`), crisp border (`#CBD5E1`), Slate 900 text.
- **Chips**: Checkmark-free chips with solid saturated topic fill when selected and white text/icon; outlined subtle slate tint when unselected.
- **Segmented Controls**: `AppSegmentedControl` with smooth sliding pill indicator, labels guaranteed on one line (`FittedBox`).
- **Bottom Navigation**: Floating pill navigation bar with active animated pill indicator (`#EEF2FF` container with `#4F46E5` icon + label), clean top hairline border (`#E2E8F0`).
- **Toasts**: Floating top overlay toast (`AppToast`), sliding in with cubic-bezier ease, auto-dismiss, no heavy SnackBars.
- **Empty States**: Warm friendly illustration container (circular tinted icon container, clear title, 1-line guidance message, actionable CTA button).

## 6. Motion & Micro-Interactions
- **Curves**: `Curves.easeOutCubic` for transitions; `Curves.easeInOut` for subtle indicators.
- **Durations**: Fast 180–220ms for micro-interactions; 250–300ms for screen / modal transitions.
- **Tactile Response**: Subtle scale factor `0.975` on press for interactive cards and primary buttons.
- **Practice Session**: Strictly zero typing animation delays, zero screen shake or red flash on wrong tries.
