# PROJECT_STATE.md — Speed Math with AI

## Current Phase: Phase 7E Complete ✅ (Version 1.9.0)

## What Is Finished

### Phase 1 — Project Setup ✅
- [x] Flutter project with `com.speedmathwithai`, minSdk 24, portrait, no INTERNET
- [x] Feature-first folder structure, Poppins font, Material 3 theme (light/dark)
- [x] go_router + bottom nav, splash screen, placeholder screens
- [x] Strings, enums, constants, FeatureFlags
- [x] SQLite database layer (sessions + attempts tables, models, repositories)

### Phase 2 — Question Engine ✅
- [x] **Question model** (`lib/domain/questions/question.dart`) — pure Dart, with topic, difficulty, displayText, operands list, correctAnswer
- [x] **QuestionGenerator interface** (`lib/domain/questions/question_generator.dart`) — abstract class with `generate()` and `generateUnique()`
- [x] **5 V1 generator classes** (Addition, Subtraction, Multiplication, Division, Squares)
- [x] **Session random utility** (`lib/domain/questions/session_random.dart`)
- [x] **Generator registry** (`lib/domain/questions/question_generator_registry.dart`)
- [x] **Score calculator** & **Session summary calculator**

### Phase 3 — Practice Flow ✅
- [x] SettingsRepository, Practice Setup, Keypad, Controller, Practice Session, Results

### Phase 4 — Stats and History ✅
- [x] Accuracy formula fix: `accuracy = correct / (correct + wrong + skipped)`
- [x] ModeValue isolation: queries strictly isolate `(topic, difficulty, mode, mode_value)`
- [x] Timer mode average time per correct answer
- [x] Stats screen, history line graph with fl_chart, session details, and debug sample data generator

### Phase 5 & 5.1 — UI Polish & Settings Changes ✅
- [x] Removed answer flash (instant transitions)
- [x] Phone dialer vs. Calculator keypad styles with live previews
- [x] Clean Home screen, redesigned Results screen with Score hero & accuracy ring
- [x] Modern design system with signature topic colors

### Phase 6A — New Topics & Skill Tracking ✅ (Version 1.1.0)
- [x] **4 New Pure Dart Question Generators** (Cubes, Square Roots, Cube Roots, Exponents)
- [x] **UI Support for 9 Topics** across Home, Practice Setup, Stats, and History
- [x] **Pure Dart Skill Tracking Engine** (`lib/domain/adaptive/`)
- [x] **Database Migration to Schema Version 3** with batched backfill
- [x] **Skill Level Card on Stats Screen**
- [x] **Rich Text Math Display** (`QuestionTextWidget`) for exponents

### Phase 6A.1 — Two Fixes & Size Check ✅ (Version 1.1.1)
- [x] **Fix 1: Wrong Answer Does NOT Advance**:
  - The question moves forward ONLY on a correct answer or Skip.
  - Zero visual change on wrong answers (no red text, no flash, no animation, no border change). Input stays intact.
  - **Auto-submit ON**: When the typed number reaches target answer length and is wrong, it is internally recorded as wrong once, plays the wrong sound and haptic once, does NOT advance, and keeps the text so the user can backspace and fix it.
  - **Auto-submit OFF**: Pressing Submit with a wrong value marks it wrong once and stays on question. Submit on empty does nothing.
  - **"First try counts"**: A question is marked wrong at most once. Subsequent wrong tries on the same question do not add extra wrongs or re-trigger sound. Correcting a previously failed question advances as usual, but scores 0 points, records `is_correct = 0`, stores the first wrong answer, and receives an adaptive skill outcome of 0.0.
  - **Skip after wrong try**: Recorded as wrong (`is_skipped = 0`, `is_correct = 0`). Skip without prior wrong try is recorded as skipped (`is_skipped = 1`).
  - **Flushing on Quit or Timer Expiry**: If the timer expires or the user quits while a question with an existing wrong try is on screen, it is automatically flushed and counted as wrong. If no wrong try was made, the question remains uncounted.
- [x] **Fix 2: Real Sounds & Non-Exclusive Playback**:
  - **Root Cause Reported**: `SystemSound.play(SystemSoundType.click)` relies on the Android OS setting "Touch sounds / Touch vibration" being enabled in device settings. When disabled (default on most modern Android devices and emulators), `SystemSound` is completely muted by the OS. Furthermore, `SystemSound` cannot differentiate pitches for correct vs wrong answers.
  - **Audio Engine**: Added `audioplayers: ^6.7.1` behind an abstract `SoundService` interface (`AppSoundService`).
  - **Sound Assets Generated**:
    * `assets/sounds/correct.wav`: 9,746 bytes (clean rising dual chime, $660 \to 880\text{ Hz}$).
    * `assets/sounds/wrong.wav`: 9,746 bytes (soft low gentle buzz, $140\text{ Hz}$ with sub-harmonics).
    * Both assets declared in `pubspec.yaml` (< 20 KB limit satisfied).
  - **Audio Focus**: Configured `AudioContextAndroid` with `AndroidAudioFocus.none` and `AudioContextIOS` with `AVAudioSessionCategory.ambient` + `mixWithOthers`, ensuring background music (Spotify, podcasts) is never paused or ducked.
  - **Sound Setting**: Live toggle; turning Sound ON in Settings plays a preview of `correct.wav`. Silent failure handling prevents any crash if audio hardware is absent.
  - **Haptic Feedback**: Retained with heavier haptic impact on wrong answers (`heavyImpact()`) vs correct answers (`lightImpact()`).
- [x] **Check 3: App Size & Safe Reductions**:
  - Baseline single fat APK: 50.8 MB (contains 3 native architectures).
  - Split-per-ABI APKs:
    * `app-arm64-v8a-release.apk`: **18.7 MB** (per-device download for ~95% of modern Android devices)
    * `app-armeabi-v7a-release.apk`: **16.2 MB**
    * `app-x86_64-release.apk`: **19.9 MB**
  - AppBundle: `app-release.aab`: **43.5 MB** (Google Play dynamically delivers the ~18 MB slice per device).
  - Safe reductions applied:
    * Enabled R8 minification (`isMinifyEnabled = true`) and resource shrinking (`isShrinkResources = true`) with custom `proguard-rules.pro`.
    * Removed unused `Poppins-Light.ttf` (saved 162 KB with zero UI impact).
    * Material icon tree-shaking verified active (99.5% icon font reduction).
  - Both per-device APK and Play Store slices are well under the **25 MB target**.
- [x] **Verification**:
  - `flutter analyze`: **0 issues found**.
  - `flutter test`: **153 of 153 tests passing** (100% pass rate).
  - Version bumped to **1.1.1** across `pubspec.yaml` and `AppConstants`.

### Phase 6B — Part A: Sound Settings & Volume ✅ (Version 1.2.0)
- [x] **Two Independent Sound Switches**:
  - "Correct answer sound" and "Wrong answer & skip sound", both default OFF.
  - Migration: legacy single Sound toggle migrated (if ON -> both ON; if OFF -> both OFF).
  - Previews: switching either switch ON in Settings plays that sound once as an instant preview.
  - Skip rule: skip without prior wrong try plays wrong sound; skip after a wrong try plays nothing extra.
- [x] **Media Volume Stream Fix**:
  - `MainActivity.kt`: Sets `volumeControlStream = AudioManager.STREAM_MUSIC` in `onCreate`.
  - `AppSoundService`: Configured with `STREAM_MUSIC` audio stream type and media usage attributes.
  - Hardware volume rocker keys adjust media volume while app is open even before sounds play.
- [x] **In-App Sound Volume Slider**:
  - 0% to 100% slider in Settings (default 100%), multiplied with device media volume.
  - Greyed out and disabled when both sound switches are OFF.
  - Releasing slider thumb plays `correct` sound preview at the selected volume.
- [x] **User MP3 Audio Files**:
  - User's `correct.mp3` and `wrong.mp3` installed in `assets/sounds/` and registered in `pubspec.yaml`.

### Phase 6B — Part B: Smart Practice Mode & Mistake Bank ✅ (Version 1.2.0)
- [x] **Database Migration to Schema Version 4**:
  - New table `mistake_bank` (id, topic, difficulty, question_text UNIQUE, operands JSON, correct_answer, stage 0-2, correct_streak, wrong_count, source, added_at, due_counter).
  - Index `idx_mistake_bank_due` on `(due_counter, stage, wrong_count)`.
  - Persisted global counter `smart_question_counter`.
  - Data reset: `SettingsRepository.resetAllData()` and `DebugSampleDataService.clearAllSampleData()` clear `mistake_bank` and reset the counter.
- [x] **Pure Dart Spaced Repetition Mistake Bank**:
  - Added on wrong answer, skipped question, or slow correct answer (> 2x target time).
  - Replay progression across 3 stages with gaps [3, 10, 25]:
    * Stage 0 -> correct -> stage 1, streak 1, due after 10 smart questions.
    * Stage 1 -> correct -> stage 2, streak 2, due after 25 smart questions.
    * Stage 2 -> correct -> streak 3 -> cleared and permanently removed from bank!
  - Replay wrong / skipped / slow resets to stage 0, streak 0, and increments wrong count.
  - Capacity eviction: hard cap of 300; evicts highest streak (stage 2) oldest items first.
- [x] **Pure Dart Smart Question Picker Engine** (`SmartQuestionPicker`):
  - 60% Weak / 30% Medium (including Not Enough Data) / 10% Strong candidate bucket mix.
  - Proportional weight redistribution when bucket classes are empty.
  - Mastery-weighted selection inside class: `w = 1.05 - mastery`.
  - Cold start unlock thresholds: Easy always unlocked; Medium/Hard unlock at 5 attempts & 0.50 mastery.
  - Difficulty nudge: 10-attempt sliding window (>= 85% accuracy nudges up; <= 60% accuracy nudges down).
  - Due mistakes interleaving: <= 1/3 of session, never 2 in a row.
  - Strict no-repeat-previous-question rule.
- [x] **Unified Question Source Abstraction** (`QuestionSource`):
  - `GeneratorQuestionSource` for single topic/difficulty practice.
  - `SmartQuestionSource` for Smart Practice.
  - `MistakeQuestionSource` for Mistake Practice.
- [x] **Practice Setup Screen**:
  - Hero "Smart Practice" card at top with multi-topic selection chips and question count selector (10, 20, 30).
  - "Practice your mistakes" card with banked mistake count badge, due questions preview, and shortcut.
  - Custom Practice section below for traditional single-topic drills.
- [x] **Mistakes Screen** (`/mistakes`):
  - Banked mistakes grouped by topic with signature topic colors.
  - Displays question text, correct answer, times wrong, and source badge.
  - Swipe-to-dismiss to manually remove resolved items.
  - "Practice these" button to drill up to 20 banked mistakes.
  - Friendly empty state when 0 mistakes are in the bank.
- [x] **Results Screen**:
  - Excludes best score / top-3 times badges for Smart and Mistake Practice.
  - Per-topic breakdown in signature topic colors (correct count, total count, avg time).
  - Mistake Bank metrics card displaying new banked mistakes, resolved mistakes, and remaining bank size.
- [x] **Home & History Integration**:
  - Last-session card handles `smart` and `mistakes` modes cleanly with `Smart Practice • Adaptive` and `Mixed (adaptive)`.
  - History screen has dedicated "Smart Practice" filter chip covering both smart and mistakes sessions.
  - Stats screen queries remain strictly isolated to standard topics and modes (Smart and Mistakes never taint best scores, top-3 times, or line graphs).
- [x] **Debug Sample Data Generator**:
  - Seeds ~15 realistic sample mistakes (stages 0, 1, 2) across topics and sources on "Generate Sample Data".
  - Cleans up `mistake_bank` on sample data reset.

### Phase 7A — Performance Report ✅ (Version 1.3.0)
- [x] **Small Fix**:
  - Smart Practice question count options include 10, 20, 30, and 50.
- [x] **Report Analyzer** (`lib/domain/report/report_analyzer.dart`):
  - Pure Dart with injectable `today` parameter for deterministic testing.
  - Uses SQL aggregates on `sessions`, `attempts`, `skill_ratings`, and `mistake_bank` tables without loading raw attempts into memory.
  - Generates structured `ReportData` comparing the last 7 days against the previous 7 days (`ReportConstants.windowDays = 7`).
  - Overall Speed Score (0-100): weighted average of mastery over all standard topic+difficulty buckets with at least 5 attempts (weight = min(attempts, 50) * 100). Categorized as Beginner (<40), Building (40-60), Strong (60-80), Elite (80+). Returns null when no bucket has >= 5 attempts.
  - Weekly summary comparison: sessions, questions answered, practice minutes, accuracy, and average time per correct answer.
  - Per-topic breakdown: level from best-attempted difficulty summary, accuracy, avg time, total attempts, days since last practiced, and trend.
  - Trend evaluation rules: requires at least 15 answered questions in EACH 7-day window. "Improving" if avg time fell by 8%+ OR accuracy rose by 5 points+. "Slipping" if time rose by 8%+ OR accuracy fell by 5 points+. Otherwise "Steady". Otherwise "Not enough data".
  - Strong areas: up to 3 buckets with mastery >= 0.80.
  - Weak areas: up to 3 buckets with attempts >= 5 and lowest mastery (strictly < 0.65).
  - Neglected topics (not practiced for 7+ days) and never-practiced topics.
  - Mistake bank summary: total count and top 3 topics by mistake count.
- [x] **Today's Plan** (`lib/domain/report/todays_plan_generator.dart`):
  - 3 focused blocks (~5 min each, ~15 min total).
  - Block 1 & 2: two weakest buckets (different topics if possible), launching 5-minute Timer sessions.
  - Block 3: Mistake Practice (if mistakes in bank), else third weakest bucket, else "Keep it sharp" Smart Practice (20Q).
  - Cached per day in SharedPreferences so it remains stable during the day; refreshed on a new day or Reset All Data.
  - Real-time Done detection: marks block Done when a completed matching session is saved today.
- [x] **Report Writer** (`lib/domain/report/report_writer.dart`):
  - Pure Dart text generator transforming `ReportData` into friendly, plain, encouraging, honest text sections.
  - Phrase bank in `assets/coach/phrases.json` with 28 situations and >= 4 variants each.
  - Deterministic date-seeded phrase selection (stable during the day, varies between days).
  - All numbers in text strictly match `ReportData` (never invented).
  - Clean regex verification guarantees zero unreplaced placeholders.
- [x] **Report Tab (UI)** (`lib/features/report/report_screen.dart`):
  - 5th bottom navigation tab: Home, Practice, Stats, Report, Settings (`AppStrings.tabReport = 'Report'`).
  - Ordered sections: Speed Score hero card with circular progress ring & label; Today's Plan with Start buttons and Done checkmarks; This week vs last week metric comparison cards; Strong areas; Needs work; Trends & Shifts; 9-Topic breakdown table in topic colors; Mistakes summary card.
  - Empty state when total questions < 20 with progress bar and "Start Smart Practice" button.
  - Async loading with loading and error states. Responsive without overflow at 360px and 1.3x text scale.
- [x] **Home Summary Card** (`lib/features/home/widgets/home_report_card.dart`):
  - Compact card above topic grid on Home: Speed Score with label, top insight sentence, "Today's plan: X of 3 done" with progress indicator, and tap-through to Report tab. Shows "Practice to unlock" when < 20 questions.
### Phase 7A.1 — Three Fixes: Idempotent Finish, Perceptual Volume Curve, Report Wording ✅ (Version 1.3.1)
- [x] **Fix 1: Results Screen Showing Twice & Duplicate Saved Data**:
  - **Root Cause Reported**: When a session completed, the controller's internal transition (`_recordCorrectAndAdvance`, `skip`, or `tick`) invoked `finishSession()`, changing state to `completed`. Concurrently, `PracticeSessionScreen`'s `ref.listen` listened for `next.status == completed` and invoked `controller.finishSession()` a second time. Without an idempotency future or navigation guard, `_saveSessionData(completed: true)` ran twice concurrently, producing duplicate rows in `sessions` and `attempts`, double-incrementing `smart_question_counter` (+20 instead of +10), duplicate writes to `skill_ratings` and `mistake_bank`, and pushing duplicate `/results` routes to the navigation stack.
  - **Controller Idempotency**: Added `_finishFuture`, `_isFinishing`, `_isFinished`, and `_cachedResultData` to `PracticeSessionController`. All actions (`tick`, `inputDigit`, `submit`, `skip`, `pause`, `resume`) are guarded. Both `finishSession()` and `quit()` return the existing `_finishFuture` if already in progress or completed, guaranteeing single execution.
  - **Navigation & Launch Guards**: Added `_hasNavigated` guard in `PracticeSessionScreen` ensuring `context.pushReplacement('/results')` runs exactly once. Added `_isLaunching` debounce guards in `PracticeSetupScreen` and `MistakesScreen` to prevent rapid double-taps from spawning parallel practice sessions.
  - **Regression Tests**: Added 6 tests in `practice_session_controller_test.dart` and 3 tests in `practice_session_fresh_db_test.dart` asserting that multiple triggers save exactly 1 session, 1 set of attempts, increment smart counter once, and update skill ratings once even on an empty database.
- [x] **Fix 2: Sound Volume Curve & Loudness Audit**:
  - **Loudness Audit Results** (via `ffmpeg volumedetect`):
    * `assets/sounds/correct.mp3`: max_volume: 0.0 dBFS (full digital saturation), mean_volume: -15.0 dBFS.
    * `assets/sounds/wrong.mp3`: max_volume: -19.9 dBFS, mean_volume: -24.4 dBFS.
    * Files were not modified.
  - **Root Cause Reported**: Hearing follows a power curve ($L \sim A^{0.33}$). A linear amplitude of 0.10 sounds like ~46% loudness, explaining why low slider values still sounded loud. Additionally, `audioplayers` `play()` calls were not directly receiving the volume parameter, which could cause Android `SoundPool` to default to 1.0 amplitude.
  - **Perceptual Volume Curve**: Added `SoundConstants.perceptualVolumeExponent = 3.0` power curve (`effectiveVolume = sliderValue^3.0`). Slider value 0.10 now maps to effective volume $0.10^3 = 0.001$, creating a soft whisper at low settings.
  - **Settings Slider & Preview**: Updated `_SoundVolumeSlider` to 20 discrete divisions (5% increments from 0% to 100%), passing `volume: effectiveVolume` directly on every `player.play()` call, and previewing audio only on slider release.
- [x] **Fix 3: Report Wording & Directionality**:
  - **Speed Comparisons**: Phrases now strictly state "fell by {speed_diff}, now {avg_time}", "{speed_diff} faster", or "dropped by {speed_diff}" when time decreases (never "up"). When time increases, phrases state "rose by {speed_diff}, now {avg_time}" or "{speed_diff} slower".
  - **Accuracy Comparisons**: Weekly accuracy comparisons strictly format differences as percentage points (e.g. `8 points`, never `8%`).
  - **Phrases Updated**: Updated all phrases across all 28 situations in `assets/coach/phrases.json` and in-memory fallback `_defaultPhrases` in `ReportWriter`.
- [x] **Test Suite & Static Analysis**:
  - 235 of 235 tests passing (100% pass rate).
  - `flutter analyze` reports 0 issues.
  - Version bumped to **1.3.1** across `pubspec.yaml` and `AppConstants`.

### Phase 7A.2 — Fixes, Unified Practice Screen & Mistakes Rework ✅ (Version 1.4.0)

#### Canonical Difficulty Ranges Table (`DifficultyRanges`)
All 9 question generators read exclusively from `DifficultyRanges` (`lib/domain/questions/difficulty_ranges.dart`):

| Topic | Easy | Medium | Hard | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Addition** | 2-digit + 2-digit ($10..99$) | 3-digit + 3-digit ($100..999$) | Three numbers of 3 to 4 digits ($100..9999$) | — |
| **Subtraction** | 2-digit − 2-digit ($10..99$) | 3-digit − 3-digit ($100..999$) | 4-digit − 4-digit ($1000..9999$) | Never negative ($a \ge b$) |
| **Multiplication** | 2-digit × 1-digit ($10..99 \times 2..9$) | 2-digit × 2-digit ($10..99 \times 10..99$) | 3-digit × 2-digit ($100..999 \times 10..99$) | — |
| **Division** | 2-digit ÷ 1-digit ($divisor \in 2..9$) | 3-digit ÷ 1-digit ($q \in 30..150$) OR 2-digit ÷ 2-digit ($d \in 11..25, q \in 3..9$) | 4-digit ÷ 2-digit ($divisor \in 11..99$) | Always exact division |
| **Squares** | $2^2$ to $20^2$ ($n \in 2..20$) | $21^2$ to $50^2$ ($n \in 21..50$, no mult 10) | $51^2$ to $99^2$ ($n \in 51..99$, no mult 10) | Multiples of 10 excluded in Med/Hard |
| **Cubes** | $2^3$ to $10^3$ ($n \in 2..10$) | $11^3$ to $20^3$ ($n \in 11..20$) | $21^3$ to $35^3$ ($n \in 21..35$, no mult 10) | Multiples of 10 excluded in Hard |
| **Square Roots** | Perfect squares up to $20^2$ ($\le 400$) | Perfect squares $21^2$ to $50^2$ ($441..2500$) | Perfect squares $51^2$ to $99^2$ ($2601..9801$) | Radical sign vector painter |
| **Cube Roots** | Perfect cubes $2^3$ to $10^3$ ($8..1000$) | Perfect cubes $11^3$ to $20^3$ ($1331..8000$) | Perfect cubes $21^3$ to $35^3$ ($9261..42875$) | Displayed as `³√n` with vector radical |
| **Exponents** | Base $2..9$, power $2..3$ | Base $2..9$, power $2..5$ | Base $2..15$, power $3..6$ | Result $\le 1,000,000$, base $\ne 1, 10$ |

#### Part A: Fixes
- [x] **A1: Difficulty Ranges Root Cause & Single Source of Truth**:
  - **Root Cause**: `PracticeConfig` / `SessionConfig` when launched via shortcuts or previous setup state could default or fall back to `Difficulty.easy` while the generator or picker used loose bounds, or `squares_generator.dart` had previously allowed lower bounds starting from 1 or arbitrary ranges.
  - **Fix**: Centralized all min/max bounds and exclusions into a single immutable domain structure: `DifficultyRanges` in `lib/domain/questions/difficulty_ranges.dart`. Refactored all 9 generators to read directly from it. 54 session-level range tests in `session_difficulty_ranges_test.dart` guarantee every question across every topic and difficulty strictly stays inside canonical bounds.
- [x] **A2: Missing Font Characters & Shared Question Widget**:
  - **Audit of Poppins Font Glyphs**:
    * Cube root character `∛` (U+221B): **Missing** in Poppins TTF files. Displayed as a broken box/fallback glyph.
    * Superscript 3 `³` (U+00B3): **Present and fully supported** in Poppins.
    * Square root radical `√` (U+221A): Present, but does not span horizontally over multi-digit radicands.
  - **Resolution**:
    * Updated `Topic.cubeRoots.symbol` from `'∛'` to `'³√'`.
    * Upgraded `QuestionTextWidget` (`lib/core/widgets/question_text_widget.dart`) with custom vector `_RadicalPainter` to draw a clean mathematical radical symbol with horizontal overline covering the radicand at any text scale.
    * Standardized math rendering across Practice Session, Results, and My Mistakes screens.
- [x] **A3: Quit Policy Rework**:
  - **3-Choice Dialog**:
    1. *Keep practicing* (cancels dialog, resumes timer/session).
    2. *End and see results* (ends session gracefully, sets `completed = 0`, saves session and attempts, updates skill ratings and mistakes, excludes from high scores/badges, and shows Results with "Ended early" badge).
    3. *Discard session* (stops immediately, saves 0 rows, deletes no prior data, returns to previous screen).
  - **Controller Idempotency**: `discard()` permanently marks session abandoned and cancels pending operations.

#### Part B: One Unified Practice Screen
- [x] **B1: Database Schema Migration to Version 5**:
  - Added `kind TEXT NOT NULL DEFAULT 'drill'` column to `sessions` table.
  - Migration backfills existing sessions: `smart` mode $\to$ `'mixed'`, `mistakes` mode $\to$ `'mistakes'`, all other sessions $\to$ `'drill'`.
  - Added index `idx_sessions_kind` on `sessions(kind)`.
- [x] **B2: Stats & High Scores Separation**:
  - `StatsRepository` queries for best scores, top-3 times, recent sessions, and graphs now enforce `WHERE kind = 'drill' AND completed = 1`.
  - Mixed sessions and mistake drills never pollute single-topic high scores or time leaderboards.
- [x] **B3 & B4: Unified Practice Setup Screen & SessionConfig**:
  - Single screen replacing duplicate tabs/modes.
  - **Weak Spots Chips**: Quick-select chips at top highlighting up to 3 weak topics (tapping selects 1 topic, Auto difficulty, Focus weak ON).
  - **Topic Selector**: Multi-select topic chips (1 to 9). "All topics" toggle chip selects/deselects all. Prevents deselecting the last remaining topic.
  - **Segmented Difficulty**: Auto, Easy, Medium, Hard with live contextual subtitle explaining the choice (e.g. "Adapts to your skill level per topic", "Single-digit drills").
  - **Focus on my weak areas switch**: Visible when multiple topics or Auto difficulty selected; automatically hidden when 1 topic + fixed difficulty selected.
  - **Target Selector**: Mode pills for Timer (1, 2, 3, 5, 10 min) and Questions (10, 20, 30, 50).
  - **Live Summary Line**: E.g., `Mixed • Auto difficulty • 20 questions` or `Addition • Easy • 5 min`.
  - **Sticky Start Button**: Anchored at bottom with clear launch action.
  - **"Practice my mistakes" Card**: Appears above Custom drill section when mistakes exist, showing count badge and direct action.
  - **Unified SessionConfig**: Encapsulates `kind`, `topics`, `difficulty`, `mode`, `modeValue`, `focusWeakAreas`, and audio preferences.
- [x] **B5 & B6: Label Updates & Launch Shortcuts**:
  - Removed "Smart Practice" terminology across all user-facing screens (`HomeScreen`, `HistoryScreen`, `SessionDetailsScreen`, `ReportScreen`, `TodaysPlanGenerator`).
  - Labeled cleanly as "Mixed" or "Mixed practice".
  - Home topic cards and Today's Plan launch pre-configured sessions into the unified practice engine.

#### Part C: Mistakes and Weak Spots
- [x] **C1: User-Facing Word Audit**:
  - Completely purged the words "bank" and "banked" from all user-visible strings, UI text, `assets/coach/phrases.json`, and fallback strings.
  - Replaced with clear, natural language: "My Mistakes", "mistakes to review", "mistake list", "Practice my mistakes".
  - Internal database tables (`mistake_bank`) and repository names (`MistakeRepository`) remain stable to preserve data integrity.
  - Verified by new automated test `test/core/strings/forbidden_strings_test.dart`.
- [x] **C2: "Practice my mistakes" Card on Practice Screen**:
  - Embedded prominently on Practice screen.
  - Shows total count of mistakes waiting for review and "See all" shortcut leading directly to `/mistakes`.
- [x] **C3: My Mistakes Screen Enhancements (`/mistakes`)**:
  - **Topic Filter Chips**: Horizontal filter chips (`All (X)`, followed by topics with mistakes). Selecting a chip filters displayed items and practice count.
  - **Grouped by Topic**: Sections with signature topic color indicators and math formatted via `QuestionTextWidget`.
  - **Practice Count Choice**: 10, 20, or All (up to 50) chips in sticky bottom bar with dynamic `Practice these (N)` button.
  - **Swipe-to-Dismiss with Undo SnackBar**: Swiping an item removes it from the list with an instant SnackBar offering an "Undo" action.


### Phase 7A.3 — UI and Behavior Fixes ✅ (Version 1.4.1)

- [x] **1. Remove Checkmarks from Chips**:
  - Removed checkmarks (`showCheckmark: false`) from ALL selectable chips across the app (`PracticeSetupScreen`, `MistakesScreen`, `HistoryScreen`, `StatsScreen`, `HistoryLineGraph`).
  - Implemented solid color fill in topic color with crisp white text, white topic symbol, and stronger font weight (`FontWeight.w600`) when selected.
  - "All topics" / "All" chip styled with solid neutral brand color (`colorScheme.primary`) and white text (`colorScheme.onPrimary`) when selected.
  - Unselected chips rendered with soft tinted background or clean outline and original topic color symbol.

- [x] **2. Reusable AppSegmentedControl**:
  - Created `AppSegmentedControl` (`lib/core/widgets/app_segmented_control.dart`) replacing Flutter's default `SegmentedButton` across the entire app (Practice Difficulty, Practice Mode, Settings Theme, Settings Keypad Style, Settings Vibration Strength, History line graph range).
  - Single-line guaranteed: labels never wrap, wrapped in `FittedBox(fit: BoxFit.scaleDown)` and `softWrap: false`.
  - Animated width flex: selected segment smoothly expands to 1.6x width over 220ms with a clean check icon next to its label, while unselected segments scale to 1.0x.
  - Responsive down to 360px screen width and 1.3x text scale with zero clipping and zero overflow errors.

- [x] **3. Base Number Invisible in Squares & Cubes (Root Cause & Fix)**:
  - **Root Cause**: `QuestionTextWidget._PowerTextWidget` rendered using raw `RichText(text: TextSpan(style: style, children: [TextSpan(text: base), ...]))`. In Flutter, unstyled `TextSpan` inside `RichText` defaults to `Color(0xFFFFFFFF)` (white). On white/light backgrounds, this resulted in white text on white background (invisible). The exponent child in `WidgetSpan` was a `Text` widget which inherited dark ink from `DefaultTextStyle.of(context)`.
  - **Fix**: Updated `QuestionTextWidget` to resolve explicit ink color from context (`style?.color ?? defaultStyle.color ?? themeColor`). Switched `_PowerTextWidget` to `Text.rich` using `resolvedStyle` across both base and exponent with consistent baseline offset.

- [x] **4. Results Screen Headline & Review Skips**:
  - "Perfect score! Zero mistakes." message appears ONLY when every question was answered and all were correct (0 wrong, 0 skipped).
  - When all questions are skipped, displays: *"You skipped every question. Try answering, even slowly, speed comes later."*
  - Included skipped questions in the Results mistake review list with their correct answers and a visible "Skipped" badge.

- [x] **5. Report Screen Unlock & Speed Score Messaging (Root Cause & Fix)**:
  - **Root Cause**: `ReportConstants.minTotalQuestionsForReport` was set to 20, locking out users who practiced a 10-question drill. Furthermore, `_getTotalQuestionsAllTime` counted all attempts instead of filtering answered questions (`WHERE is_skipped = 0`).
  - **Fix**: Reduced unlock threshold to 10 answered questions (`WHERE is_skipped = 0`).
  - Added "Early report" indicator banner when total answered questions is between 10 and 40.
  - When Speed Score has no bucket with $\ge 5$ attempts, the hero card clearly explains: *"Your Speed Score appears after 5 answers in the same topic and level (X answers still needed)"*, while keeping all other report sections visible.
  - Empty-state button updated to "Start practice".

- [x] **6. Haptics (Vibration) Motor Support (Root Cause & Fix)**:
  - **Root Cause**: Flutter's native `HapticFeedback` delegates to Android's `View.performHapticFeedback()`. When the Android OS setting "Touch feedback" / "Haptic feedback" is toggled off in device settings or battery saver is active, `performHapticFeedback` calls are silently dropped by the Android OS.
  - **Fix**: Added `vibration: ^3.1.8` and declared `<uses-permission android:name="android.permission.VIBRATE"/>` in `AndroidManifest.xml` (no INTERNET permission).
  - Created `AppHapticService` with strength scaling (Light, Medium, Strong), durations (key press ~12ms, correct ~22ms, wrong ~60ms, celebration double pulse), and safe fallback to `HapticFeedback`.
  - Added "Vibration strength" segmented control in Settings under Haptics with live preview on touch.
  - Updated Haptics setting description to *"Vibrate on key presses, answers and results"*.

- [x] **7. Exponents Hard Range Pool**:
  - Upgraded hard exponents in `lib/domain/questions/generators/exponents_generator.dart` to static precomputed pool covering bases 2 to 15, powers 3 to 6, strictly excluding bases 1 and 10 and results $> 1,000,000$.

---

### Phase 7B — On-Device AI Coach ✅ (Version 1.5.0)

- [x] **1. Pure Dart Coach Engine (`lib/domain/coach/`)**:
  - **Zero Packages & No Network**: 100% on-device, pure Dart implementation with no dependencies, no external APIs, and sub-15ms classification latency.
  - **Text Sanitization & Shorthand Mapping (`TextNormalizer`)**:
    - Converts input to lowercase, trims length to 300 characters, removes punctuation.
    - Resolves shorthand, typos, and synonyms: `mul`/`mult`/`times` $\to$ `multiplication`, `div`/`divison` $\to$ `division`, `sub`/`minus` $\to$ `subtraction`, `add`/`sum` $\to$ `addition`, `sq`/`square` $\to$ `squares`, `sqrt`/`sq root` $\to$ `square roots`, `cbrt`/`cube root` $\to$ `cube roots`, `cube` $\to$ `cubes`, `power`/`exponent`/`index` $\to$ `exponents`.
  - **Fast N-Gram & TF-IDF Classifier (`NgramIntentClassifier`)**:
    - Hybrid character 3-gram Sørensen-Dice coefficient combined with word-level TF-IDF cosine similarity.
    - Pre-indexed dictionary loaded once from `assets/coach/intents.json` (20 distinct intents with 20+ examples each).
    - Threshold confidence check (`CoachConstants.confidenceThreshold = 0.28`). Unknown queries or confidence below threshold safely fall back to friendly suggestions.
  - **Slot Extraction (`SlotExtractor`)**:
    - Topics: all 9 canonical drill topics.
    - Difficulty: Easy, Medium, Hard (and synonyms like "simple", "tough", "advanced").
    - Target Question Count: snapped to 10, 20, 30, 50.
    - Target Minutes: snapped to 1, 2, 3, 5, 10.
    - Time horizons: today, this week, last week.
  - **Contextual Follow-Up**:
    - Retains previous intent when follow-up messages provide new topics or slots (e.g. "what about cubes?" or "and subtraction").
  - **Factual Grounding (`CoachContext`)**:
    - Responses strictly derived from user's local database via `ReportAnalyzer` (`ReportData`), skill ratings, mistake count, today's plan, and recent sessions.
    - Under 10 answered questions: acknowledges early progress (X of 10) while answering general questions, tips, and practice setups normally.

- [x] **2. Grounded Answer Composer (`CoachComposer`)**:
  - Rotates through 4+ natural phrase variants per situation from `assets/coach/coach_phrases.json` without repeating the same variant twice in a row.
  - Replaces all placeholders (`{topic}`, `{percent}`, `{score}`, `{time}`, etc.) with 100% real math data; falls back to placeholder-free variants if values are missing.
  - Strict tone: honest, encouraging, short sentences. Accuracy in "points", time reductions in "faster", never uses the words "IQ" or "bank".
  - Mathematically verified tips from `assets/coach/tips.json` (27 verified math shortcuts across all 9 topics).
  - Emits interactive `CoachAction` buttons: `Start practice` (pre-filled with configured topic/difficulty/target), `Open report`, `Practice my mistakes`, `Open stats`.

- [x] **3. UI & Chat Presentation (`/coach`)**:
  - Accessible via "Ask Coach" button on Home report card and Coach icon button in Report screen header.
  - Chat layout with Coach messages on left (with avatar), User messages on right, responsive bubbles down to 360px and 1.3x text scale.
  - Top horizontally scrollable chip bar with ready-made questions (no checkmarks).
  - "Report this answer" action on coach messages with local SQLite persistence and user confirmation.
  - Chat history restored from SQLite; "Clear chat" menu in AppBar.
  - Persistent bottom disclaimer: *"Coach answers come from your practice on this phone. It cannot answer general questions."*

- [x] **4. Database Schema Version 6 (`DatabaseHelper`)**:
  - `coach_messages`: `id`, `role`, `text`, `actions` (JSON), `created_at`. Automatically pruned to the last 100 messages.
  - `coach_reports`: `id`, `created_at`, `user_message`, `coach_reply`, `reason`. Preserved locally for debugging.
  - `resetAllData()` updated to clear both Coach tables.
  - All existing user practice data, attempts, and skill ratings preserved during migration.

---

### Phase 7B.1 — Fixes, Dynamic Insights, Patterns, Weak Areas, Sound Sliders ✅ (Version 1.6.0)

- [x] **Part A: Critical Bug Fix ("0 of 10 Questions Answered") & Data Check Screen**:
  - **Root Cause Analysis**:
    1. *Stale Providers & Missing Signal Bumps*: Derived providers (`reportDataProvider`, `coachStateNotifierProvider`, `todaysPlanProvider`) were cached and only refreshed on initial load. The global `dataRevisionProvider` was previously not bumped on every SQLite write path (specifically `endSessionEarly`, `discardSession`, and certain mistake updates).
    2. *SQL Query Null Exclusions*: Attempt counts in certain queries checked `is_skipped = 0`, which in SQL silently excludes rows where `is_skipped IS NULL`.
    3. *Session Kind Filtering Discrepancies*: Several reporting surfaces filtered by `kind = 'drill'` or `completed = 1`, resulting in disagreement with the Coach which counted all attempts.
  - **Fixes Applied**:
    - Centralized query: `statsRepository.getTotalAnsweredQuestionsCount()` uses `COALESCE(is_skipped, 0) = 0` and `status != 'discarded'`, counting all valid answered questions across all session kinds and completed/early-ended states.
    - Automatic `dataRevisionProvider` invalidation directly inside repository mutating methods on every save path.
    - Added hidden **Data Check Screen** (`/settings/data-check`): accessible by navigating to **Settings > About** and **long-pressing the version number** (`v1.6.0`). Displays raw database numbers (sessions by kind/completed, attempts total/answered/skipped, mistakes, skill rows, pattern rows, schema & data revisions) alongside cache timestamps and a "Recompute now" button.

- [x] **Part B: Coach Chat UI Polish**:
  - **Claude / ChatGPT Style Sticky Composer**: Bottom container with rounded background, multiline expandable `TextField` (up to 4 lines), trailing circular Send button that activates when text is non-empty.
  - **Floating Horizontal Suggestion Chips**: Positioned above the composer with smooth slide/fade animations; hides automatically when the text field is focused or keyboard opens.
  - **Welcome Cards**: Empty chat state presents attractive prompt cards with one-tap suggestions ("Where am I weak?", "How is my division?", "Where should I focus?").
  - **New `activity` Intent**: Added support for queries like "what did I do today", "my recent practice", "summary of today" in `assets/coach/intents.json`, `CoachIntent.activity`, and `CoachComposer._composeActivity`.

- [x] **Part C: Dynamic Session Insights**:
  - Replaced hardcoded static insights with `SessionInsightGenerator` (`lib/domain/scoring/session_insight_generator.dart`).
  - Loaded from `assets/coach/insight_phrases.json` with rotational variety (never repeating the same variant twice).
  - 14 distinct situation keys: `perfect_score`, `high_accuracy`, `speed_improvement`, `personal_best`, `streak_milestone`, `weak_area_improvement`, `similar_mistakes_practice`, `mistakes_cleared`, `tough_patterns_mastered`, `balanced_practice`, `fast_pace`, `steady_progress`, `comeback`, `solid_practice`.
  - Insights quote real numbers (delta percentage, time saved in seconds, questions mastered) and fall back gracefully if data is sparse.

- [x] **Part D: Granular Pattern Tracking & Weak Area Practice**:
  - **74 Question Patterns** defined in `PatternConstants` (`lib/domain/questions/pattern_constants.dart`) covering all 9 topics and 3 difficulties.
  - **Database Migration to Schema Version 7**:
    * New `pattern_skills` table (`pattern`, `topic`, `difficulty`, `rating`, `rd`, `volatility`, `attempts_count`, `last_practiced_at`, `best_time_ms`).
    * Added `pattern` column to `attempts` table.
    * Migration backfills `pattern` for all historical attempts using `PatternConstants.patternOf(topic, difficulty, operands)` and populates initial `pattern_skills` rows.
    * `resetAllData()` and `clearAllSampleData()` updated to purge `pattern_skills`.
  - **Pattern Selection (`PatternPicker`)**:
    * 60% probability of selecting the weakest pattern; 40% uniform exploration among remaining patterns for that topic/difficulty.
    * 10-attempt diversity rule: if the same pattern has been chosen 10 consecutive times, a different pattern is forced.
    * Pure Dart fallback ensures difficulty ranges are never violated.
  - **Practice Setup Screen**:
    * "Focus on my weak areas" switch is visible in EVERY configuration (default ON, never hidden).
    * Subtitle clearly explains: *"More questions from the types you find hardest. Never goes beyond the difficulty you chose."*
  - **Diagnosis in Report & Coach**:
    * When $\ge 8$ attempts are recorded for a pattern, `PatternWeaknessHelper` diagnoses the weakest sub-skill (e.g. *"Needs work on 2-digit additions with 2 carries"*).
    * Displayed on Report weak bucket cards and included in Coach replies for weak areas and topic status.

- [x] **Part E: Mistakes Practice Fixes**:
  - **Root Cause of Topic Loss & Overwriting Question 1**: In `PracticeSessionController._initSkillRatings()`, a check `isMixed = state.config.difficulty == Difficulty.mixed` was erroneously triggered because mistake sessions set `difficulty: Difficulty.mixed`. This wiped `_questionSource` with `SmartQuestionPicker`, replacing Question 1 and all subsequent questions with mixed questions.
  - **Fix**: Added explicit guard `final isMistakes = state.config.kind == SessionKind.mistakes || state.config.mode == PracticeMode.mistakes;` to prevent `_initSkillRatings()` from touching the question source.
  - **Exact Question Count Clamping**: When the user's chosen count exceeds available mistakes, session count snaps to available mistakes without synthetic padding. Question count chip and action button show the exact count (`Practice $count question(s)`).
  - **Similar Mistakes Practice (`SimilarMistakeQuestionSource`)**: Added segmented control ("Same questions" vs "Similar questions"). When "Similar questions" is selected, generates new questions with the exact same topic, difficulty, and pattern, updates skill ratings/patterns, and preserves the original mistake in the bank for later review.

- [x] **Part F: Settings Sound Sliders**:
  - Replaced single global slider with two independent sliders:
    * "Correct answer volume" (under Correct sound switch)
    * "Wrong & skip volume" (under Wrong sound switch)
  - Expandable animated container (200ms `AnimatedCrossFade`) under each toggle.
  - Range 0% to 100% in 5% steps (divisions: 20).
  - Preview plays ONLY on release (`onChangeEnd`).
  - Cubic volume curve (`effectiveVolume = volume^3`) implemented in `SoundService` for genuinely quiet low volume on mobile speakers.

- [x] **Part G: Polish & Version**:
  - App version bumped to **1.6.0** (`1.6.0+11`) in `pubspec.yaml` and `AppConstants.appVersion`.
  - Settings About section verified to display `v1.6.0`.
  - `flutter analyze`: **0 issues found**.

---

### Complete Question Patterns Reference Table (74 Patterns)

| Topic | Difficulty | Pattern Code | Human-Readable Label |
| :--- | :--- | :--- | :--- |
| **Addition** | Easy | `add_e_no_carry` | 2-digit additions without carries |
| **Addition** | Easy | `add_e_one_carry` | 2-digit additions with 1 carry |
| **Addition** | Easy | `add_e_two_carries` | 2-digit additions with 2 carries |
| **Addition** | Medium | `add_m_no_carry` | 3-digit additions without carries |
| **Addition** | Medium | `add_m_one_carry` | 3-digit additions with 1 carry |
| **Addition** | Medium | `add_m_two_carries` | 3-digit additions with 2 carries |
| **Addition** | Medium | `add_m_three_carries` | 3-digit additions with 3 carries |
| **Addition** | Hard | `add_h_few_carries` | 3-number additions with 0 to 2 carries |
| **Addition** | Hard | `add_h_many_carries` | 3-number additions with 3 or more carries |
| **Subtraction** | Easy | `sub_e_no_borrow` | 2-digit subtractions without borrows |
| **Subtraction** | Easy | `sub_e_one_borrow` | 2-digit subtractions with 1 borrow |
| **Subtraction** | Medium | `sub_m_no_borrow` | 3-digit subtractions without borrows |
| **Subtraction** | Medium | `sub_m_one_borrow` | 3-digit subtractions with 1 borrow |
| **Subtraction** | Medium | `sub_m_two_borrows` | 3-digit subtractions with 2 borrows |
| **Subtraction** | Hard | `sub_h_few_borrows` | 4-digit subtractions with 0 to 1 borrow |
| **Subtraction** | Hard | `sub_h_two_borrows` | 4-digit subtractions with 2 borrows |
| **Subtraction** | Hard | `sub_h_three_borrows` | 4-digit subtractions with 3 borrows |
| **Multiplication** | Easy | `mul_e_small_digit` | 2-digit × 1-digit (multiplier 2 to 4) |
| **Multiplication** | Easy | `mul_e_mid_digit` | 2-digit × 1-digit (multiplier 5 to 6) |
| **Multiplication** | Easy | `mul_e_high_digit` | 2-digit × 1-digit (multiplier 7 to 9) |
| **Multiplication** | Medium | `mul_m_small_ones` | 2-digit × 2-digit (smaller factor ending in 0 to 3) |
| **Multiplication** | Medium | `mul_m_mid_ones` | 2-digit × 2-digit (smaller factor ending in 4 to 6) |
| **Multiplication** | Medium | `mul_m_high_ones` | 2-digit × 2-digit (smaller factor ending in 7 to 9) |
| **Multiplication** | Hard | `mul_h_small_ones` | 3-digit × 2-digit (multiplier ending in 0 to 3) |
| **Multiplication** | Hard | `mul_h_mid_ones` | 3-digit × 2-digit (multiplier ending in 4 to 6) |
| **Multiplication** | Hard | `mul_h_high_ones` | 3-digit × 2-digit (multiplier ending in 7 to 9) |
| **Division** | Easy | `div_e_small_divisor` | 2-digit ÷ 1-digit (divisor 2 to 4) |
| **Division** | Easy | `div_e_mid_divisor` | 2-digit ÷ 1-digit (divisor 5 to 6) |
| **Division** | Easy | `div_e_large_divisor` | 2-digit ÷ 1-digit (divisor 7 to 9) |
| **Division** | Medium | `div_m_single_digit` | 3-digit ÷ 1-digit |
| **Division** | Medium | `div_m_two_digit` | 2-digit ÷ 2-digit |
| **Division** | Hard | `div_h_small_divisor` | 4-digit ÷ 2-digit (divisor 11 to 30) |
| **Division** | Hard | `div_h_mid_divisor` | 4-digit ÷ 2-digit (divisor 31 to 60) |
| **Division** | Hard | `div_h_large_divisor` | 4-digit ÷ 2-digit (divisor 61 to 99) |
| **Squares** | Easy | `sq_e_ends_in_5` | Squares ending in 5 (up to 20) |
| **Squares** | Easy | `sq_e_lower_half` | Squares from 2 to 10 |
| **Squares** | Easy | `sq_e_upper_half` | Squares from 11 to 20 |
| **Squares** | Medium | `sq_m_ends_in_5` | Squares ending in 5 (21 to 50) |
| **Squares** | Medium | `sq_m_lower_half` | Squares from 21 to 35 |
| **Squares** | Medium | `sq_m_upper_half` | Squares from 36 to 50 |
| **Squares** | Hard | `sq_h_ends_in_5` | Squares ending in 5 (51 to 99) |
| **Squares** | Hard | `sq_h_lower_half` | Squares from 51 to 75 |
| **Squares** | Hard | `sq_h_upper_half` | Squares from 76 to 99 |
| **Cubes** | Easy | `cube_e_lower` | Cubes from 2 to 5 |
| **Cubes** | Easy | `cube_e_upper` | Cubes from 6 to 10 |
| **Cubes** | Medium | `cube_m_ends_in_5` | Cube of 15 |
| **Cubes** | Medium | `cube_m_lower` | Cubes from 11 to 14 |
| **Cubes** | Medium | `cube_m_upper` | Cubes from 16 to 20 |
| **Cubes** | Hard | `cube_h_ends_in_5` | Cubes ending in 5 (25, 35) |
| **Cubes** | Hard | `cube_h_lower` | Cubes from 21 to 28 |
| **Cubes** | Hard | `cube_h_upper` | Cubes from 29 to 35 |
| **Square Roots** | Easy | `sqrt_e_ends_in_5` | Square roots ending in 5 (up to 20) |
| **Square Roots** | Easy | `sqrt_e_lower` | Square roots from 2 to 10 |
| **Square Roots** | Easy | `sqrt_e_upper` | Square roots from 11 to 20 |
| **Square Roots** | Medium | `sqrt_m_ends_in_5` | Square roots ending in 5 (21 to 50) |
| **Square Roots** | Medium | `sqrt_m_lower` | Square roots from 21 to 35 |
| **Square Roots** | Medium | `sqrt_m_upper` | Square roots from 36 to 50 |
| **Square Roots** | Hard | `sqrt_h_ends_in_5` | Square roots ending in 5 (51 to 99) |
| **Square Roots** | Hard | `sqrt_h_lower` | Square roots from 51 to 75 |
| **Square Roots** | Hard | `sqrt_h_upper` | Square roots from 76 to 99 |
| **Cube Roots** | Easy | `cbrt_e_lower` | Cube roots from 2 to 5 |
| **Cube Roots** | Easy | `cbrt_e_upper` | Cube roots from 6 to 10 |
| **Cube Roots** | Medium | `cbrt_m_ends_in_5` | Cube root of 3375 (root 15) |
| **Cube Roots** | Medium | `cbrt_m_lower` | Cube roots from 11 to 14 |
| **Cube Roots** | Medium | `cbrt_m_upper` | Cube roots from 16 to 20 |
| **Cube Roots** | Hard | `cbrt_h_ends_in_5` | Cube roots ending in 5 (25, 35) |
| **Cube Roots** | Hard | `cbrt_h_lower` | Cube roots from 21 to 28 |
| **Cube Roots** | Hard | `cbrt_h_upper` | Cube roots from 29 to 35 |
| **Exponents** | Easy | `exp_e_squared` | Powers with exponent 2 (squares) |
| **Exponents** | Easy | `exp_e_cubed` | Powers with exponent 3 (cubes) |
| **Exponents** | Medium | `exp_m_low_power` | Exponents with power 2 or 3 |
| **Exponents** | Medium | `exp_m_high_power` | Exponents with power 4 or 5 |
| **Exponents** | Hard | `exp_h_small_base` | Exponents with bases 2 to 5 |
| **Exponents** | Hard | `exp_h_large_base` | Exponents with bases 6 to 15 |

---

### How to Add a New Intent

Adding a new intent to the Coach is designed to be modular and require changes in only 4 places:

1. **Add Examples to `assets/coach/intents.json`**:
   Add a new key under `"intents"` with at least 20 natural phrasing examples, including typos, abbreviations, and informal speech:
   ```json
   "my_new_intent": [
     "how do i do X",
     "tell me about X",
     "explain X to me",
     ...
   ]
   ```

2. **Add Enum Value in `lib/domain/coach/coach_intent.dart`**:
   Add the enum case to `CoachIntent` and map it in `CoachIntent.fromKey`:
   ```dart
   enum CoachIntent {
     ...
     myNewIntent;

     static CoachIntent fromKey(String key) {
       switch (key) {
         ...
         case 'my_new_intent':
           return CoachIntent.myNewIntent;
       }
     }
   }
   ```

3. **Add Response Variants to `assets/coach/coach_phrases.json`**:
   Define at least 4 natural response variants with optional placeholders:
   ```json
   "my_new_intent": [
     "Here is how X works for your practice: {detail}.",
     "Looking at your numbers, {detail}.",
     "Regarding X, {detail} is what you should keep in mind.",
     "Let's look at X: {detail}."
   ]
   ```

4. **Add Handler in `CoachComposer` (`lib/domain/coach/coach_composer.dart`)**:
   Add a `case CoachIntent.myNewIntent:` in the `compose()` method and wire up the handler method using real data from `context`:
   ```dart
   case CoachIntent.myNewIntent:
     return _composeMyNewIntent(slots, context);
   ```

### Phase 7C — Five New Practice Topics ✅ (Version 1.7.0)
- [x] **Five Pure Dart Question Generators** (`lib/domain/questions/generators/`):
  - **Percentages**:
    * Easy: $x\%$ of $N$ ($x \in \{10, 20, 25, 50\}$, $N \in [20, 400]$ multiples of 20).
    * Medium: $x\%$ of $N$ ($x \in [5, 95]$ step 5, $N \in [100, 1000]$ multiples of 20, integer answer).
    * Hard: $x\%$ of $A \pm y\%$ of $B$ ($x, y$ step 5, $A, B \in [200, 1500]$ multiples of 20, whole positive result).
  - **Fractions**:
    * Easy: $\frac{a}{b}$ of $N$ ($b \in \{2, 3, 4, 5, 6, 8, 10\}$, $a < b$, $N \in [2, 200]$ multiples of $b$).
    * Medium: $\frac{a}{b}$ of $N$ ($b \in [2, 12]$, $N \in [100, 1000]$ multiples of $b$).
    * Hard: $\frac{a}{b}$ of $N \pm \frac{c}{d}$ of $M$ (irreducible fractions, positive whole result).
  - **Simplification (BODMAS)**:
    * Easy: Two-operation expressions ($a + b \times c$, $a \times b - c$, strictly non-negative).
    * Medium: Brackets and multi-ops ($(a + b) \times c - d$, $a \times b + c \times d$).
    * Hard: Expression with square and exact division ($A^2 - B / C + D \times E$).
  - **Averages**:
    * Easy: Average of 3 two-digit numbers (sum divisible by 3).
    * Medium: Average of 5 numbers of 2 to 3 digits (sum divisible by 5).
    * Hard: "Average of 5 numbers is A. Four of them are w, x, y, z. Find the fifth."
  - **Missing Number**:
    * Easy: $? + a = b$, $a \times ? = b$, $b - ? = a$.
    * Medium: $? \times a = b$, $? / a = b$, $a - ? = b$.
    * Hard: $? \times a - b = c$, $(? + a) \times b = c$.
  - All answers across all 5 topics are guaranteed to be **WHOLE POSITIVE NUMBERS** (no decimals, keypad has no decimal key).
  - Registered in `QuestionGeneratorRegistry` with deterministic seed mixing and no back-to-back repeats.
- [x] **Question Display & Stacked Fractions** (`QuestionTextWidget`):
  - Stacked fractions rendered via custom Flutter drawing (`_StackedFractionWidget`) with a clean horizontal divider bar (no unicode glyphs or font fallback issues).
  - Powers and exponents cleanly parsed and rendered inline (`_createPowerSpan`).
  - Adaptive font scaling (`26px` for long multi-step expressions, `52px` for standard) with `ConstrainedBox` + `FittedBox` to prevent any text wrap or overflow on 360px width screens at 1.3x text scale.
- [x] **Theme Colors & Icons**:
  - Percentages: Lime (`0xFF65A30D`)
  - Fractions: Rose (`0xFFF43F5E`)
  - Simplification: Indigo (`0xFF4F46E5`)
  - Averages: Deep Orange (`0xFFEA580C`)
  - Missing Number: Slate (`0xFF64748B`)
  - Mixed: Violet (`0xFF8B5CF6`)
- [x] **UI Structure & 14 Topics Support**:
  - Home screen organized into two clean, labelled groups: **"Basics"** (original 9 topics) and **"More topics"** (the 5 new topics).
  - Practice Setup, History, Stats, Mistakes screen, and Report automatically adapt to 14 topics via `Topic.standardTopics`.
- [x] **AI Coach Integration**:
  - `TextNormalizer` & `SlotExtractor` recognize topics and synonyms (`percentages`, `pct`, `%`, `fractions`, `frac`, `simplification`, `bodmas`, `averages`, `mean`, `missing number`, `find x`).
  - `CoachComposer._composeTips` falls back to grounded practice guidance using real user stats (`getPerformanceForTopic`) instead of canned text or "I don't know".
  - `intents.json` expanded with realistic query samples for the 5 new topics.
- [x] **Debug Data & Version Bump**:
  - `debug_sample_data.dart` includes sample mistakes and ratings for all 5 new topics.
  - App version bumped to `1.7.0` across `pubspec.yaml` and `AppConstants.appVersion`.

---

## Canonical Difficulty Ranges (All 14 Topics)

| Topic | Easy | Medium | Hard | Notes |
|---|---|---|---|---|
| Addition | $2\text{D} + 2\text{D}$ ($10\text{--}99$) | $3\text{D} + 3\text{D}$ ($100\text{--}999$) | $3\text{ or } 4$ numbers ($100\text{--}9999$) | Whole sum |
| Subtraction | $2\text{D} - 2\text{D}$ ($10\text{--}99$) | $3\text{D} - 3\text{D}$ ($100\text{--}999$) | $4\text{D} - 4\text{D}$ ($1000\text{--}9999$) | Non-negative result |
| Multiplication | $2\text{D} \times 1\text{D}$ ($11\text{--}99 \times 2\text{--}9$) | $2\text{D} \times 2\text{D}$ ($11\text{--}99 \times 11\text{--}99$) | $3\text{D} \times 2\text{D}$ ($101\text{--}999 \times 11\text{--}99$) | Excludes pure powers of 10 |
| Division | $2\text{D} \div 1\text{D}$ | $3\text{D} \div 1\text{D}$ | $3\text{--}4\text{D} \div 2\text{D}$ | Exact division, no remainder |
| Squares | $11^2\text{--}30^2$ | $31^2\text{--}50^2$ | $51^2\text{--}99^2$ | Excludes multiples of 10 in hard |
| Cubes | $2^3\text{--}12^3$ | $13^3\text{--}20^3$ | $21^3\text{--}30^3$ | Excludes multiples of 10 in hard |
| Square Roots | $\sqrt{121}\text{--}\sqrt{900}$ ($11\text{--}30$) | $\sqrt{961}\text{--}\sqrt{2500}$ ($31\text{--}50$) | $\sqrt{2601}\text{--}\sqrt{9801}$ ($51\text{--}99$) | Perfect squares |
| Cube Roots | $\sqrt[3]{8}\text{--}\sqrt[3]{1728}$ ($2\text{--}12$) | $\sqrt[3]{2197}\text{--}\sqrt[3]{8000}$ ($13\text{--}20$) | $\sqrt[3]{9261}\text{--}\sqrt[3]{27000}$ ($21\text{--}30$) | Perfect cubes |
| Exponents | $2^3\text{--}2^6, 3^2\text{--}3^4, 4^2\text{--}4^3, 5^2\text{--}5^3$ | $2^7\text{--}2^{10}, 3^5, 4^4, 5^4, 6^3\text{--}7^3$ | $2^{11}\text{--}2^{12}, 6^4, 7^4, 8^3\text{--}9^3$ | Integer result $\le 10000$ |
| Percentages | $x\% \text{ of } N$, $x \in \{10, 20, 25, 50\}$, $N \in [20, 400]$ mult. 20 | $x \in [5, 95]$ step 5, $N \in [100, 1000]$ mult. 20 | $x\% \text{ of } A \pm y\% \text{ of } B$, $A, B \in [200, 1500]$ mult. 20 | Positive whole answer |
| Fractions | $\frac{a}{b} \text{ of } N$, $b \in \{2..10\}$, $N \le 200$ mult. $b$ | $b \in [2, 12]$, $N \in [100, 1000]$ mult. $b$ | $\frac{a}{b} \text{ of } N \pm \frac{c}{d} \text{ of } M$ | Positive whole answer |
| Simplification | $a + b \times c$, $a \times b - c$ | $(a + b) \times c - d$, $a \times b + c \times d$ | $A^2 - B / C + D \times E$ | Positive whole answer |
| Averages | Average of 3 $2\text{D}$ numbers | Average of 5 numbers ($2\text{--}3\text{D}$) | Avg of 5 numbers is $A$, 4 given, find 5th | Divisible, whole positive result |
| Missing Number | $? + a = b$, $a \times ? = b$, $b - ? = a$ | $? \times a = b$, $? / a = b$, $a - ? = b$ | $? \times a - b = c$, $(? + a) \times b = c$ | Whole positive result |

---

## New Question Patterns (Phase 7C — 26 Patterns)

### Phase 7D — Bug Fixes, Display Improvements, Custom Toast, Gamified Practice & Exam Content ✅ (Version 1.8.0)

#### Part A: Bug Fixes
- [x] **A1: Practice Launch Lock on Navigation (Root Cause & Fix)**:
  - **Root Cause**: In `PracticeSetupScreen._startPractice()`, the flag `_isLaunching` was set to `true` while awaiting `context.push('/practice/session')`. When the user chose *"End and see results"* > *"Change Setup"*, `ResultsScreen` navigated via `context.go('/practice')`, which dismantled the current navigation route stack without completing the pending `context.push` Future. Consequently, the `finally { _isLaunching = false; }` block was never executed, leaving `_isLaunching = true` indefinitely and silently deadlocking the "Start Practice" button until the app was switched to another tab.
  - **Fix**:
    1. Added `activate()` lifecycle hook to `PracticeSetupScreen` and `MistakesScreen` to immediately reset `_isLaunching = false` whenever the screen becomes active/visible again.
    2. Added a 1.5-second safety auto-release fallback timer in both launch flows.
    3. Invalidated `practiceSessionControllerProvider` in `PracticeSessionScreen.dispose()` ensuring a fresh controller for every new session.
- [x] **A2: Coach Direct Sub-Route Blank Screen (Root Cause & Fix)**:
  - **Root Cause**: `/coach` was placed on `_rootNavigatorKey`, while `/report` and `/stats` were sub-routes nested within `ShellRoute` under `_shellNavigatorKey`. Pushing `/report` or `/stats` from the Coach screen via `context.push` created a navigator stack mismatch resulting in an unrendered blank white container.
  - **Fix**: In `CoachScreen._handleAction`, navigation to `/report` and `/stats` now pushes `ReportScreen` and `StatsScreen` directly onto the root navigator with standard AppBar back navigation leading directly back to Coach.

#### Part B: Measured Question Text Fitting & Word Problems
- [x] **QuestionFontConstants**:
  - Defined canonical font sizes:
    * Expressions: preferred 54sp, min single-line 30sp, two-line max 40sp, two-line min 28sp.
    * Sentences / Word problems: max 34sp, min 22sp, max 4 lines.
- [x] **QuestionTextWidget (`lib/core/widgets/question_text_widget.dart`)**:
  - Uses `LayoutBuilder` + `TextPainter` to dynamically measure expression bounds before rendering.
  - Tries single-line fit from 54sp down to 30sp. If bounds exceed width, automatically performs a balanced two-line split at the top-level operator/comma closest to the center (starting line 2 with the operator), scaling between 40sp and 28sp.
  - Word problem sentences scale between 34sp and 22sp across up to 4 lines.
  - Support for mixed fractions (`3 1/4` or `3_1/4`): whole number followed by stacked vertical fraction with horizontal bar.
- [x] **Padding & Margins**: Question card horizontal margin reduced to 12dp and inner padding to 10dp for maximum typing width.

#### Part C: AppToast Custom Overlay
- [x] **AppToast (`lib/core/widgets/app_toast.dart`)**:
  - Custom overlay-based notification anchored below the status bar (top-of-screen).
  - Dark 85% opacity card with rounded corners, subtle icon, and clear typography.
  - Auto-dismisses in 2.5 seconds (or 4.0 seconds when action button is present). Tap or swipe up immediately dismisses. Non-blocking touch passthrough to rest of screen.
  - Replaced all 7 legacy `SnackBar` and `ScaffoldMessenger` usages across the entire codebase (`SettingsScreen`, `DataCheckScreen`, `MistakesScreen`, `CoachScreen`, `StatsScreen`).

#### Part D: 16 Topics Organized Under 3 Groups
- [x] **Topic Enum & Groups (`lib/core/enums/enums.dart`)**:
  - Added `Topic.numberSeries` (symbol: `...`) and `Topic.approximation` (symbol: `≈`).
  - Added `TopicGroup` enum:
    1. **Arithmetic**: Addition, Subtraction, Multiplication, Division.
    2. **Powers & Roots**: Squares, Cubes, Square Roots, Cube Roots, Exponents.
    3. **Applied Maths**: Percentages, Fractions, Simplification, Averages, Missing Number, Number Series, Approximation.
- [x] **Theme & Styling**:
  - Added `AppTheme.numberSeriesColor` (Teal-Blue `0xFF0284C7`) and `AppTheme.approximationColor` (Amber-Brown `0xFFB45309`).
  - Home screen displays cards cleanly grouped under the 3 group section headings (removed "14 Topics" / "More topics").
  - Practice Setup screen features "All topics" at the top followed by the 3 group subheadings with checkmark-free topic chips.

#### Part E: New & Upgraded Question Generators
- [x] **Number Series (`NumberSeriesGenerator`)**:
  - Generates 5–6 term progressions with one unknown term marked as `?`.
  - 14 distinct patterns across Easy, Medium, and Hard:
    * *Easy*: Constant difference, $\times 2 / \times 3$, consecutive squares, consecutive cubes, odd/even. Missing term at pos 2, 3, or 4.
    * *Medium*: Growing difference, Fibonacci-style, $\times n \pm k$, $n^2 \pm k$, prime numbers. Missing term at pos 3, 4, or 5.
    * *Hard*: Interleaved series (two alternating patterns), growing multipliers, square/cube differences, alternating $\pm$ operations. Missing term anywhere.
  - All positive numbers $< 100,000$.
- [x] **Approximation (`ApproximationGenerator`)**:
  - Generates realistic expressions containing decimal operands ending with `≈ ?`.
  - Calculated using friendly rounded integers, guaranteeing clean positive whole answers.
  - 7 patterns across Easy, Medium, and Hard:
    * *Easy*: Near product ($a \times b$), near two-operation ($a + b \times c$).
    * *Medium*: Near percentage ($x\% \text{ of } N$), near square roots ($\sqrt{N}$ near perfect square), near 3-operation combos.
    * *Hard*: Compound near percentage ($x\% \text{ of } A \pm y\% \text{ of } B$), mixed powers & divisions.
  - Includes practice screen hint: *"Round each number first, then calculate."*
- [x] **Upgraded Averages (`AveragesGenerator`)**:
  - Exam-style word problem scenarios: group sums, consecutive integers/multiples, member joining/leaving group, removed/replaced member with average change, weighted average.
- [x] **Upgraded Fractions (`FractionsGenerator`)**:
  - Mixed fraction expressions (`3 1/4 + 2 1/4`), same-denominator operations, fraction of fraction of $N$, multi-term mixed fraction simplification with brackets.
- [x] **Coach & Debug Integration**:
  - `TextNormalizer` & `SlotExtractor` map synonyms for approximation (`approx`, `estimate`, `estimation`) and series (`sequence`, `progression`, `number pattern`).
  - Added sample mistakes and skill ratings for `numberSeries` and `approximation` in `debug_sample_data.dart`.

#### Part F: Gamified Practice (Calm, Fast, Optional)
- [x] **During Practice**:
  - **Streak Chip**: Flame icon + "$N$ in a row", grows smoothly with `AnimatedScale(200ms)`, resets quietly on wrong or skip (no red, no shake). Hidden at 0 and 1.
  - **Live Points Counter**: Running session score counting up smoothly (`TweenAnimationBuilder`, 250ms).
  - **Speed Tag**: Brief 600ms tag near answer box on correct answers: *"Lightning"* ($\le 50\%$ target time), *"On pace"* ($\le 100\%$ target time), *"Steady"* ($> 100\%$).
  - **Question Mode Progress Bar**: Custom progress bar featuring milestone dots at 25%, 50%, and 75%.
  - **Milestone Toasts**: At streaks of 5, 10, 20, and 30, triggers an `AppToast` banner (*"10 in a row! 🔥"*) for 1.5s with light tactile haptic without blocking input.
- [x] **Results Screen**:
  - **1 to 3 Stars**: 1 star for finishing, 2 stars for $\ge 70\%$ accuracy, 3 stars for $\ge 90\%$ accuracy + average time $\le$ target time (`XpCalculator`).
  - **Score Count-up**: Final score counts up smoothly.
  - **Confetti Burst**: 30-particle lightweight `CustomPainter` burst under 1.2s, triggered only on new best scores or perfect rounds.
  - **XP & Levels Card**: Shows `+N XP`, player level & title, progress bar to next level, and celebration message on level-up.
- [x] **XP & Level Formula**:
  - Total XP = sum of scores across all sessions of all kinds (`SELECT COALESCE(SUM(score), 0) FROM sessions`).
  - Level $L$ threshold = $50 \times (L - 1)^2$ XP.
  - Level titles: Beginner, Quick Thinker, Rapid Solver, Number Ninja, Speedster, Calculator Pro, Mind Racer, Math Wizard, Lightning Mind, Grandmaster.
  - Home screen header features a compact level chip ("Level 4 • Number Ninja" + mini progress bar).
- [x] **Settings**:
  - Added "Game effects" toggle (default ON): *"Streaks, milestones, speed tags and celebrations"*. When OFF: streaks, speed tags, milestone toasts, and confetti are disabled while retaining underlying points and progress tracking.

---

## Canonical Difficulty Ranges (All 16 Topics)

| Topic | Easy | Medium | Hard | Notes |
|---|---|---|---|---|
| Addition | $2\text{D} + 2\text{D}$ ($10\text{--}99$) | $3\text{D} + 3\text{D}$ ($100\text{--}999$) | $3\text{ or } 4$ numbers ($100\text{--}9999$) | Whole sum |
| Subtraction | $2\text{D} - 2\text{D}$ ($10\text{--}99$) | $3\text{D} - 3\text{D}$ ($100\text{--}999$) | $4\text{D} - 4\text{D}$ ($1000\text{--}9999$) | Non-negative result |
| Multiplication | $2\text{D} \times 1\text{D}$ ($11\text{--}99 \times 2\text{--}9$) | $2\text{D} \times 2\text{D}$ ($11\text{--}99 \times 11\text{--}99$) | $3\text{D} \times 2\text{D}$ ($101\text{--}999 \times 11\text{--}99$) | Excludes pure powers of 10 |
| Division | $2\text{D} \div 1\text{D}$ | $3\text{D} \div 1\text{D}$ | $3\text{--}4\text{D} \div 2\text{D}$ | Exact division, no remainder |
| Squares | $11^2\text{--}30^2$ | $31^2\text{--}50^2$ | $51^2\text{--}99^2$ | Excludes multiples of 10 in hard |
| Cubes | $2^3\text{--}12^3$ | $13^3\text{--}20^3$ | $21^3\text{--}30^3$ | Excludes multiples of 10 in hard |
| Square Roots | $\sqrt{121}\text{--}\sqrt{900}$ ($11\text{--}30$) | $\sqrt{961}\text{--}\sqrt{2500}$ ($31\text{--}50$) | $\sqrt{2601}\text{--}\sqrt{9801}$ ($51\text{--}99$) | Perfect squares |
| Cube Roots | $\sqrt[3]{8}\text{--}\sqrt[3]{1728}$ ($2\text{--}12$) | $\sqrt[3]{2197}\text{--}\sqrt[3]{8000}$ ($13\text{--}20$) | $\sqrt[3]{9261}\text{--}\sqrt[3]{27000}$ ($21\text{--}30$) | Perfect cubes |
| Exponents | $2^3\text{--}2^6, 3^2\text{--}3^4, 4^2\text{--}4^3, 5^2\text{--}5^3$ | $2^7\text{--}2^{10}, 3^5, 4^4, 5^4, 6^3\text{--}7^3$ | $2^{11}\text{--}2^{12}, 6^4, 7^4, 8^3\text{--}9^3$ | Integer result $\le 10000$ |
| Percentages | $x\% \text{ of } N$, $x \in \{10, 20, 25, 50\}$, $N \in [20, 400]$ mult. 20 | $x \in [5, 95]$ step 5, $N \in [100, 1000]$ mult. 20 | $x\% \text{ of } A \pm y\% \text{ of } B$, $A, B \in [200, 1500]$ mult. 20 | Positive whole answer |
| Fractions | $\frac{a}{b} \text{ of } N$, $b \in \{2..10\}$, $N \le 200$ mult. $b$ | $b \in [2, 12]$, $N \in [100, 1000]$ mult. $b$ | Mixed fractions, compound sums, brackets | Positive whole answer |
| Simplification | $a + b \times c$, $a \times b - c$ | $(a + b) \times c - d$, $a \times b + c \times d$ | $A^2 - B / C + D \times E$ | Positive whole answer |
| Averages | Average of 3 $2\text{D}$ numbers | Average of 5 numbers ($2\text{--}3\text{D}$) | Word problems: group sums, joined/left, weighted | Divisible, whole positive result |
| Missing Number | $? + a = b$, $a \times ? = b$, $b - ? = a$ | $? \times a = b$, $? / a = b$, $a - ? = b$ | $? \times a - b = c$, $(? + a) \times b = c$ | Whole positive result |
| Number Series | Progressions of 5–6 terms (arithmetic, $\times 2/3$, squares, cubes, odd/even) | Growing diff, Fibonacci, $\times n \pm k$, $n^2 \pm k$, primes | Interleaved, growing multipliers, square/cube diffs | Missing term marked as `?`, whole positive result |
| Approximation | Near product ($a \times b$), near 2-ops ($a + b \times c$) | Near percentage, near square root, near 3-ops | Compound percentage, mixed powers & divisions | Ends with $\approx ?$, positive whole answer |

---

## What to Check by Hand (Phase 7D Checklist)

1. **Bug Fix A1 (Practice Launch Lock)**:
   - Start a practice session $\to$ answer 2 questions $\to$ tap Close $\to$ choose *"End and see results"*.
   - On the Results screen, tap *"Change Setup"*.
   - On the Practice Setup screen, tap *"Start Practice"*. Verify the session launches immediately without sticking.
   - Test the same after Discarding a session and after completing a Mistakes session.

2. **Bug Fix A2 (Coach Screen Navigation)**:
   - Open Coach chat $\to$ tap *"Open Performance Report"* (or ask for report) $\to$ verify the Report screen opens with content (not a blank white screen) and has a back button returning to Coach.
   - Do the same with *"Open Statistics"* action.

3. **AppToast Overlay**:
   - In Settings, tap *"Reset all data"* $\to$ confirm $\to$ verify custom black overlay card slides in at top with checkmark and auto-dismisses smoothly (zero SnackBar).
   - In Mistakes, swipe away a mistake $\to$ verify AppToast displays at the top with "Undo" button.

4. **Home Screen 3 Topic Groups**:
   - Verify Home screen displays 3 sections: **"Arithmetic"** (4 topics), **"Powers & Roots"** (5 topics), and **"Applied Maths"** (7 topics).
   - Verify the Level chip in the gradient header shows your current level, title, XP, and progress bar.

5. **Question Rendering & Mixed Fractions**:
   - Start a Fractions drill $\to$ verify mixed fractions (e.g. $3\frac{1}{4}$) render with the whole number followed by stacked vertical fraction.
   - Start a Simplification or Word problem drill $\to$ verify long expressions split cleanly onto two balanced lines with operator on line 2, never overflowing the card width at 360px.

6. **New Exam Content (Number Series & Approximation)**:
   - Practice Number Series $\to$ verify sequences of 5–6 numbers with one `?`. All answers whole numbers.
   - Practice Approximation $\to$ verify expressions with decimals ending in `≈ ?` and hint line displayed.

7. **Gamified Practice & Game Effects Setting**:
   - Answer 2+ questions correctly in a row $\to$ verify flame streak chip appears and grows slightly.
   - Skips or wrong answers reset streak quietly without color flash, shake or blink.
   - At streaks of 5, 10, 20, 30 $\to$ verify milestone toast appears at top for 1.5s with light haptic.
   - On correct answers $\to$ verify speed tag ("Lightning", "On pace", "Steady") shows for 600ms.
   - In Question mode $\to$ verify top progress bar has milestone dots at 25%, 50%, and 75%.
   - On Results $\to$ verify 1–3 stars, smooth score count-up, XP progress bar, and confetti on new best score / perfect round.
   - In Settings, turn OFF "Game effects" $\to$ verify streaks, speed tags, milestone toasts, and confetti are turned off cleanly.

---

### Phase 7D.1 — Bug Fixes & Refinements ✅ (Version 1.8.1)
- [x] **A1: Questions Show as a Gray Box (Root Cause & Fix)**:
  - *Root Cause*: `QuestionTextWidget._buildExpressionWidget` passed `TextSpan`s containing `WidgetSpan`s (for superscript exponents and stacked fractions) directly into `TextPainter.layout()`. Without providing explicit placeholder dimensions, Flutter threw `AssertionError: !hasInlineWidgets || hasValidPlaceholders`. In release builds, Flutter catches unhandled layout exceptions and renders `ErrorWidget` (plain gray box).
  - *Proper Fix*: Tokenized expressions (`_TextToken`, `_PowerToken`, `_FractionToken`, `_RadicalToken`). Decoupled token width measurement using `TextPainter` strictly on plain text components (0 `WidgetSpan` measured with `TextPainter`). Baseline-aligned rows for math tokens. Wrapped questions in safe fallback `try...catch` logging with `debugPrint` and falling back to clean text (`17^2`) with `BoxFit.scaleDown`.
  - *Custom ErrorWidget.builder*: Configured in `lib/main.dart` to show a neutral slate placeholder instead of Flutter's default gray box.
  - *Question Gallery Screen*: Added in `lib/features/settings/question_gallery_screen.dart` (accessed via Settings > About > Long-press version > Data check > Question Gallery). Visualizes all 16 topics across Easy/Medium/Hard with 320/360/411dp width selectors and 1.0x/1.3x text scale switches, showing "FALLBACK USED" banner if fallback is triggered.
  - *Throwaway Render Check*: Executed widget harness across all 16 topics $\times$ 3 difficulties $\times$ 20 samples $\times$ 3 widths $\times$ 2 text scales = 5,760 renders. Result: 0 failures, 0 fallbacks used. Test harness deleted.
- [x] **A2: Typed Answer Invisibility (Root Cause & Fix)**:
  - *Root Cause*: Cascading layout failure from `QuestionTextWidget`. Because the question and answer box were in the same card container, when `QuestionTextWidget` crashed with `AssertionError`, Flutter replaced the entire card with the gray `ErrorWidget`, obscuring the answer box completely. In addition, the answer box lacked high contrast text, had an empty state showing a faint dash `'—'` instead of a static hint, and lacked `BoxFit.scaleDown` for 5–6 digit numbers.
  - *Fix*: Answer display box redesigned with `minWidth: 200, maxWidth: 280, height: 58`, high contrast bold dark text (`Color(0xFF0F172A)`, `fontSize: 34`, `FontWeight.w900`) wrapped in `FittedBox(fit: BoxFit.scaleDown)` to prevent any clipping on large numbers, and a clear static hint (`"Type your answer"`, `fontSize: 16`, `Color(0xFF94A3B8)`) when empty.
- [x] **A3: "Revise your mistakes" Card Redesign**:
  - Redesigned on Practice screen as a compact warm tinted card (`Color(0xFFFFF7ED)`, border `Color(0xFFFED7AA)`).
  - Circular icon container on left (`Color(0xFFFFEDD5)`), title `"Revise your mistakes"`, subtitle `"X questions waiting"`, small underlined `"See all"` link, and filled pill button `"Practice N"` (`StadiumBorder`, `Color(0xFFEA580C)`).
  - Hidden completely when `_mistakeCount == 0`. Clean layout verified with zero overflow at 360px and 1.3x text scale.
- [x] **A4: "All topics" Chip Toggle & Empty State Handling**:
  - Tapping "All topics" when all topics are selected deselects all topics. Tapping again selects all topics.
  - Deselecting the last individual topic leaves 0 topics selected.
  - When 0 topics are selected, the Start button is disabled (`onPressed: null`), the live summary line reads `"Choose at least one topic"`, and tapping any topic chip selects just that topic.
  - "All topics" chip shows as selected only when every topic is selected.
- [x] **A5: Light Mode Only**:
  - Completely removed dark mode: app forced to `themeMode: ThemeMode.light`.
  - Removed Appearance / Theme selector section from `SettingsScreen`.
  - Migrated `SettingsRepository` to ignore and clear any stale saved dark mode settings (`themeMode` getter always returns `ThemeMode.light`).
  - Removed dark-theme code paths and dark-only colors from `AppTheme`. Status bar icons set to dark (`SystemUiOverlayStyle.dark`).
- [x] **Finish**:
  - Version bumped to `1.8.1+14` in `pubspec.yaml` and `1.8.1` in `AppConstants.appVersion`.
  - `flutter analyze` clean with 0 issues.

---

### Phase 7E — Full Visual Redesign (UI UX Pro Max) ✅ (Version 1.9.0)
- [x] **Skill Ingestion & Design System**:
  - Ingested UI UX Pro Max skill guidelines for: *"a mobile learning app for students preparing for competitive exams, daily speed-calculation practice with game-like feedback and progress tracking, light mode only, bright but calm, motivating, not childish"*.
  - Authored root `DESIGN.md` establishing color tokens, typography scales, card metrics, ambient shadow tokens, and 60fps performance guardrails (zero `BackdropFilter` or blur shaders in scrollable lists).
- [x] **Theme & App Shell Redesign**:
  - `lib/app/theme.dart`: Expressive light theme with Indigo 600 (`#4F46E5`), Slate 900 (`#0F172A`) high-contrast text, ambient soft shadows, and signature topic color system.
  - `lib/app/shell.dart`: Custom `_AnimatedPillBottomNavBar` with active pill container (`#EEF2FF`), 0.96 tap scale, and crisp top border (`#E2E8F0`).
- [x] **Core Reusable Design Components**:
  - `lib/core/widgets/screen_header.dart`: Clean illustrated header with soft gradient background and subtle math geometry painter (`_HeaderGeometryPainter`).
  - `lib/core/widgets/tactile_card.dart`: 20dp/16dp radius card with `#E2E8F0` border, soft ambient elevation, and 0.98 press micro-interaction.
  - `lib/core/widgets/empty_state_view.dart`: Unified empty state with circular tinted icon, bold headline, supportive copy, and primary action button.
- [x] **All Screens Visual Redesign**:
  - **Home**: Header banner with dynamic greeting, level pill with gold progress bar, `TactileCard` for Last Session and Home Report Card, 3 topic category sections with pill count badges and tactile topic tiles.
  - **Practice Setup**: `ScreenHeader`, `TactileCard` for weak areas toggle, animated pill selection for target pills with primary glow, sticky bottom bar.
  - **Practice Session**: Uncluttered focused view, prominent question card, high-contrast answer box with static hint, comfortable keypad, gamified streak chip and speed tag.
  - **Results**: Score hero card with stars and gradient, level/XP progress bar, stats grid, coach insight card, mistake review cards.
  - **Stats**: `ScreenHeader` with History button, `TactileCard` for skill level card and best times, `EmptyStateView` fallback.
  - **History**: Topic filter chips, `TactileCard` for session tiles with accuracy and score badges, `EmptyStateView`.
  - **Session Details**: `ScreenHeader`, `TactileCard` for overview hero, metric grid, and individual attempt tiles with slowest question callout.
  - **Report**: `ScreenHeader`, `TactileCard` for Speed Score hero, Today's Plan block cards, weekly comparison, strong/weak areas, topic breakdown table, and unlock progress empty state.
  - **Coach**: `ScreenHeader`, AI chat bubbles (primary user bubble, white card coach bubble with soft shadow), `TactileCard` starter cards, suggestion pills, modern pill composer.
  - **Mistakes**: `ScreenHeader`, `EmptyStateView`, `TactileCard` for mistake tiles with swipe-to-dismiss, sticky bottom bar with question count selector and practice button.
  - **Settings**: `ScreenHeader`, grouped `TactileCard` sections for keypad preview, practice experience, haptics, volume sliders, data reset, and about card.
  - **Splash**: Brand gradient icon container with glow shadow, Poppins typography, and clean spinner.
  - **AppToast**: Top pill overlay with soft semantic icons and undo action chip.
- [x] **Cleanup & Verification**:
  - Deleted downloaded skill files outside the app directory (`/tmp/ui-ux-pro-max-skill`).
  - Strict terminology guard: zero usage of "bank", "IQ", or exam names in user-facing UI text.
  - Version bumped to `1.9.0+15` in `pubspec.yaml` and `1.9.0` in `AppConstants.appVersion`.
  - `flutter analyze`: clean with 0 issues.

---

## What to Check by Hand (Phase 7E Checklist)

1. **App Shell & Bottom Navigation**:
   - Verify bottom navigation bar features active pill indicators (`#EEF2FF` background with `#4F46E5` icon + text).
   - Switch between Home, Practice, Stats, Report, and Settings tabs: verify smooth transitions and zero overflow.
2. **Home Screen**:
   - Verify the custom illustrated header with dynamic greeting and level chip with gold progress bar.
   - Check the Last Session card or Welcome card (rendered as a `TactileCard` with soft shadow).
   - Check the 3 topic category sections (Foundations, Advanced, Exam-style) with pill badges and tactile cards.
3. **Practice Setup & Session Flow**:
   - Tap any topic to enter Practice Setup: check `ScreenHeader`, `TactileCard` for weak areas toggle, and target pills.
   - Tap "Start Practice": verify uncluttered question card, prominent answer box with hint `"Type your answer"`, and comfortable keypad.
   - Answer questions: verify streak chip increments, speed tags appear on fast answers, and progress bar moves.
4. **Results Screen**:
   - Complete or quit a session: verify score hero card with stars, XP/level progress card, stats grid, and coach insight card.
5. **Stats & History Screens**:
   - Open Stats: verify Skill Level card and Best Times cards. Tap "History" in header: verify chronological sessions rendered in `TactileCard`s.
   - Tap any session: verify Session Details screen with overview card, metric grid, and attempt tiles highlighting the slowest question.
6. **Performance Report & Coach Screens**:
   - Open Report: verify Speed Score hero with ring indicator, Today's Plan block cards with "Start" buttons, weekly comparison, and topic table.
   - Tap "Ask Coach" (or the psychology icon): verify AI chat interface with starter cards, coach bubbles, copy/report actions, and modern pill composer.
7. **My Mistakes Screen**:
   - Go to Practice > "Revise your mistakes" (or Coach > practice mistakes): verify topic filter bar, `TactileCard` mistake tiles, swipe-to-dismiss with Undo toast, and sticky bottom bar.
8. **Settings Screen**:
   - Open Settings: verify grouped sections in clean `TactileCard` containers, keypad live preview, volume sliders, haptic strength selector, and v1.9.0 in About card.
   - Long-press version in About: verify Data Check diagnostics screen opens.

1. **Question Display & Question Gallery (A1)**:
   - Go to Settings > About > Long-press the version number (1.8.1) > tap "Question Gallery".
   - Test topics that previously failed (Squares, Cubes, Exponents, Simplification, Fractions) across all 3 difficulties.
   - Toggle widths (320, 360, 411 dp) and text scales (1.0x, 1.3x). Verify no question shows a gray box and no red "FALLBACK USED" banner appears.
2. **Answer Box Typing & Long Answers (A2)**:
   - Start a practice session on any topic. Verify the empty answer box displays the static hint `"Type your answer"`.
   - Type digits using the keypad (test both Phone dialer and Calculator styles). Verify typed numbers appear large, bold, centered, and dark (`#0F172A`).
   - Test long answers up to 5–6 digits (e.g. on Large Addition or Exponents) and negative sign: verify text scales down smoothly without clipping or overflow.
   - Test with both Auto-submit ON and OFF.
3. **Mistakes Card Redesign (A3)**:
   - With mistakes waiting: verify the card has a warm amber/orange tint with round icon on left, title "Revise your mistakes", subtitle "X questions waiting", underlined "See all" link, and "Practice N" pill button on right.
   - With 0 mistakes: verify the card is completely hidden.
4. **"All topics" Toggle & 0 Topics State (A4)**:
   - On the Practice setup screen with all topics selected, tap "All topics": verify all topics become unselected.
   - Verify the Start button is disabled and the bottom summary says `"Choose at least one topic"`.
   - Tap any topic chip: verify that single topic is selected and Start button enables.
   - Deselect the only remaining topic: verify it transitions back to the 0-topic disabled state.
   - Tap "All topics" again: verify all 16 topics are selected.
5. **Light Mode Only (A5)**:
   - Open Settings: verify the "Appearance" / "Theme" selector row is completely gone.
   - Verify all screens (Home, Practice, Session, Results, Stats, Mistakes, Coach, Settings) render cleanly in light mode with dark status bar icons.
